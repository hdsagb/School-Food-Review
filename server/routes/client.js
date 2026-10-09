/**
 * App 端接口（严格对齐 entry/src/main/ets/net/Api.ets 的路径与字段契约）
 * 统一响应包裹：{ code: 0, message: 'ok', data }
 */
const express = require('express');
const db = require('../db');
const { parseBearer, genToken, guestAuth, registeredAuth, hashPassword, verifyPassword } = require('../auth');

const router = express.Router();

function ok(res, data) {
  res.json({ code: 0, message: 'ok', data });
}

function fail(res, status, message) {
  res.status(status).json({ code: 1, message });
}

/** 读取可配置的评价上限（管理后台可改；读不到时用默认值兜底） */
function reviewLimits() {
  const rows = db.prepare(
    "SELECT key, value FROM settings WHERE key IN ('daily_review_limit', 'monthly_review_limit')"
  ).all();
  const map = {};
  for (const r of rows) map[r.key] = Number(r.value);
  return {
    daily: Number.isFinite(map.daily_review_limit) ? map.daily_review_limit : 50,
    monthly: Number.isFinite(map.monthly_review_limit) ? map.monthly_review_limit : 400
  };
}

/** 本地时区的「今天 0 点」和「本月 1 号 0 点」，转成与 create_time 同格式的 ISO 串 */
function dayStartIso() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d.toISOString();
}

function monthStartIso() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  d.setDate(1);
  return d.toISOString();
}

/** 某用户在指定起始时间之后已提交的评价条数 */
function countReviewsSince(userId, sinceIso) {
  return db.prepare('SELECT COUNT(*) AS n FROM reviews WHERE user_id = ? AND create_time >= ?')
    .get(userId, sinceIso).n;
}

/** 菜品查询公共 SQL（联表取档口/食堂名与楼层） */
const DISH_SELECT = `
  SELECT d.*, s.name AS stall_name, s.floor AS floor, c.name AS canteen_name
  FROM dishes d
  JOIN stalls s ON d.stall_id = s.id
  JOIN canteens c ON d.canteen_id = c.id
`;

/** 评价查询公共 SQL（联表取用户昵称） */
const REVIEW_SELECT = `
  SELECT r.*, u.nickname AS user_nickname, u.avatar AS user_avatar
  FROM reviews r
  LEFT JOIN users u ON r.user_id = u.id
`;

function dishRowToModel(d) {
  return {
    id: d.id,
    stallId: d.stall_id,
    canteenId: d.canteen_id,
    name: d.name,
    price: d.price,
    image: d.image,
    tags: JSON.parse(d.tags || '[]'),
    stallName: d.stall_name,
    canteenName: d.canteen_name,
    floor: d.floor,
    rating: d.rating,
    reviewCount: d.review_count,
    isSignature: !!d.is_signature,
    soldOut: !!d.sold_out,
    nutrition: {
      calories: d.calories,
      isVegetarian: !!d.is_vegetarian,
      allergens: JSON.parse(d.allergens || '[]')
    }
  };
}

function reviewRowToModel(r) {
  const anon = !!r.is_anonymous;
  return {
    id: r.id,
    dishId: r.dish_id,
    userId: r.user_id,
    userNickname: anon ? '匿名同学' : (r.user_nickname || '同学'),
    userAvatar: anon ? '' : (r.user_avatar || ''),
    rating: r.rating,
    dimensions: { taste: r.taste, portion: r.portion, value: r.value },
    content: r.content,
    images: JSON.parse(r.images || '[]'),
    likes: r.likes,
    isAnonymous: anon,
    status: r.status,
    createTime: r.create_time
  };
}

function favoritesOf(userId) {
  return db.prepare('SELECT dish_id FROM user_favorites WHERE user_id = ? ORDER BY rowid')
    .all(userId).map((x) => x.dish_id);
}

// ---------- 公共数据 ----------

// GET /api/canteens
router.get('/canteens', (req, res) => {
  const rows = db.prepare('SELECT * FROM canteens ORDER BY id').all();
  ok(res, rows.map((c) => ({
    id: c.id, name: c.name, location: c.location,
    openHours: c.open_hours, floors: c.floors, image: c.image
  })));
});

// GET /api/canteens/:canteenId/stalls
router.get('/canteens/:canteenId/stalls', (req, res) => {
  const rows = db.prepare('SELECT * FROM stalls WHERE canteen_id = ? ORDER BY id').all(req.params.canteenId);
  ok(res, rows.map((s) => ({
    id: s.id, canteenId: s.canteen_id, name: s.name,
    floor: s.floor, cuisine: s.cuisine, image: s.image
  })));
});

// GET /api/menu/today?canteenId=&mealType=
router.get('/menu/today', (req, res) => {
  let rows = db.prepare(`${DISH_SELECT} WHERE d.canteen_id = ? ORDER BY d.id`).all(req.query.canteenId || '');
  if (req.query.mealType === 'breakfast') rows = rows.slice(0, 2);
  ok(res, rows.map(dishRowToModel));
});

// GET /api/dishes/search?keyword=
router.get('/dishes/search', (req, res) => {
  const kw = (req.query.keyword || '').trim();
  let rows;
  if (!kw) {
    rows = db.prepare(`${DISH_SELECT} ORDER BY d.id`).all();
  } else {
    const like = `%${kw}%`;
    rows = db.prepare(`${DISH_SELECT} WHERE d.name LIKE ? OR d.tags LIKE ? ORDER BY d.id`).all(like, like);
  }
  ok(res, rows.map(dishRowToModel));
});

// GET /api/dishes/:dishId
router.get('/dishes/:dishId', (req, res) => {
  const d = db.prepare(`${DISH_SELECT} WHERE d.id = ?`).get(req.params.dishId);
  if (!d) return fail(res, 404, '菜品不存在');
  ok(res, dishRowToModel(d));
});

// GET /api/dishes/:dishId/reviews?page=&pageSize=&sort=
router.get('/dishes/:dishId/reviews', (req, res) => {
  const page = Math.max(1, parseInt(req.query.page || '1', 10));
  const pageSize = Math.max(1, parseInt(req.query.pageSize || '8', 10));
  const sort = req.query.sort === 'hottest' ? 'hottest' : 'latest';
  const order = sort === 'hottest' ? 'r.likes DESC, r.create_time DESC' : 'r.create_time DESC';
  const total = db.prepare('SELECT COUNT(*) AS n FROM reviews WHERE dish_id = ? AND status = ?')
    .get(req.params.dishId, 'approved').n;
  const rows = db.prepare(`${REVIEW_SELECT} WHERE r.dish_id = ? AND r.status = 'approved' ORDER BY ${order} LIMIT ? OFFSET ?`)
    .all(req.params.dishId, pageSize, (page - 1) * pageSize);
  ok(res, { list: rows.map(reviewRowToModel), total, page, pageSize, hasMore: page * pageSize < total });
});

// POST /api/reviews 提交评价（仅注册用户）
router.post('/reviews', registeredAuth, (req, res) => {
  const { dishId, rating, dimensions, content, images, isAnonymous } = req.body || {};
  if (!dishId || typeof rating !== 'number' || !content) return fail(res, 400, '参数不完整');
  if (!db.prepare('SELECT id FROM dishes WHERE id = ?').get(dishId)) return fail(res, 404, '菜品不存在');

  // 每个账号的评价频率限制（每日 / 每月上限由管理后台配置）
  const limits = reviewLimits();
  if (countReviewsSince(req.user.id, dayStartIso()) >= limits.daily) {
    return fail(res, 429, `今日评价已达上限（${limits.daily} 条），明天再来吧`);
  }
  if (countReviewsSince(req.user.id, monthStartIso()) >= limits.monthly) {
    return fail(res, 429, `本月评价已达上限（${limits.monthly} 条），下个月再来吧`);
  }

  const id = 'r' + Date.now() + Math.floor(Math.random() * 1000);
  const createTime = new Date().toISOString();
  const dim = dimensions || {};
  db.prepare(`
    INSERT INTO reviews (id, dish_id, user_id, rating, taste, portion, value, content, images,
                         likes, is_anonymous, status, create_time)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, 'approved', ?)
  `).run(
    id, dishId, req.user.id, rating,
    dim.taste || rating, dim.portion || rating, dim.value || rating,
    content, JSON.stringify(images || []), isAnonymous ? 1 : 0, createTime
  );

  const stat = db.prepare("SELECT COUNT(*) AS n, AVG(rating) AS avg FROM reviews WHERE dish_id = ? AND status = 'approved'")
    .get(dishId);
  db.prepare('UPDATE dishes SET review_count = ?, rating = ? WHERE id = ?')
    .run(stat.n, Math.round(stat.avg * 10) / 10, dishId);

  ok(res, reviewRowToModel(db.prepare(`${REVIEW_SELECT} WHERE r.id = ?`).get(id)));
});

// POST /api/reviews/:reviewId/like 点赞/取消，返回最新点赞数（仅注册用户）
router.post('/reviews/:reviewId/like', registeredAuth, (req, res) => {
  const reviewId = req.params.reviewId;
  const r = db.prepare('SELECT id, likes FROM reviews WHERE id = ?').get(reviewId);
  if (!r) return fail(res, 404, '评价不存在');
  const liked = db.prepare('SELECT 1 AS x FROM review_likes WHERE review_id = ? AND user_id = ?').get(reviewId, req.user.id);
  if (liked) {
    db.prepare('DELETE FROM review_likes WHERE review_id = ? AND user_id = ?').run(reviewId, req.user.id);
    db.prepare('UPDATE reviews SET likes = MAX(0, likes - 1) WHERE id = ?').run(reviewId);
    ok(res, Math.max(0, r.likes - 1));
  } else {
    db.prepare('INSERT INTO review_likes (review_id, user_id) VALUES (?, ?)').run(reviewId, req.user.id);
    db.prepare('UPDATE reviews SET likes = likes + 1 WHERE id = ?').run(reviewId);
    ok(res, r.likes + 1);
  }
});

// ---------- 用户相关 ----------

// GET /api/user/profile 游客引导：无 token 自动建号并下发 X-Auth-Token
router.get('/user/profile', (req, res) => {
  const token = parseBearer(req);
  let user = token ? db.prepare('SELECT * FROM users WHERE id = ?').get(token) : null;
  if (!user) {
    const id = genToken();
    const nickname = '同学' + Math.floor(Math.random() * 1000);
    db.prepare('INSERT INTO users (id, nickname, avatar) VALUES (?, ?, ?)').run(id, nickname, '');
    user = { id, nickname, avatar: '' };
  }
  res.set('X-Auth-Token', user.id);
  ok(res, {
    id: user.id,
    nickname: user.nickname,
    avatar: user.avatar || '',
    username: user.username || '',
    favorites: favoritesOf(user.id)
  });
});

// GET /api/user/reviews 我的评价
router.get('/user/reviews', guestAuth, (req, res) => {
  const rows = db.prepare(`
    SELECT r.*, u.nickname AS user_nickname, u.avatar AS user_avatar, d.name AS dish_name
    FROM reviews r
    LEFT JOIN users u ON r.user_id = u.id
    JOIN dishes d ON r.dish_id = d.id
    WHERE r.user_id = ? ORDER BY r.create_time DESC
  `).all(req.user.id);
  ok(res, rows.map((r) => ({ review: reviewRowToModel(r), dishName: r.dish_name || '未知菜品' })));
});

// GET /api/user/favorites
router.get('/user/favorites', guestAuth, (req, res) => {
  ok(res, favoritesOf(req.user.id));
});

// GET /api/user/favorites/dishes
router.get('/user/favorites/dishes', guestAuth, (req, res) => {
  const rows = db.prepare(`${DISH_SELECT} JOIN user_favorites f ON d.id = f.dish_id WHERE f.user_id = ? ORDER BY f.rowid`)
    .all(req.user.id);
  ok(res, rows.map(dishRowToModel));
});

// POST /api/user/favorites { dishId }（仅注册用户）
router.post('/user/favorites', registeredAuth, (req, res) => {
  const { dishId } = req.body || {};
  if (!dishId) return fail(res, 400, '参数不完整');
  const exists = db.prepare('SELECT 1 AS x FROM user_favorites WHERE user_id = ? AND dish_id = ?').get(req.user.id, dishId);
  if (exists) {
    db.prepare('DELETE FROM user_favorites WHERE user_id = ? AND dish_id = ?').run(req.user.id, dishId);
  } else {
    db.prepare('INSERT INTO user_favorites (user_id, dish_id) VALUES (?, ?)').run(req.user.id, dishId);
  }
  ok(res, favoritesOf(req.user.id));
});

// ---------- 注册 / 登录 ----------

function userPayload(user) {
  return {
    id: user.id,
    nickname: user.nickname,
    avatar: user.avatar || '',
    username: user.username || '',
    favorites: favoritesOf(user.id)
  };
}

// POST /api/auth/register { username, password, nickname? }
router.post('/auth/register', (req, res) => {
  const { username, password, nickname } = req.body || {};
  const uname = String(username || '').trim();
  const pwd = String(password || '');
  const nick = String(nickname || '').trim();
  if (!/^[a-zA-Z0-9_]{3,20}$/.test(uname)) {
    return res.json({ code: 1, message: '用户名需为 3-20 位字母、数字或下划线' });
  }
  if (pwd.length < 6 || pwd.length > 64) {
    return res.json({ code: 1, message: '密码长度需为 6-64 位' });
  }
  if (nick.length > 20) {
    return res.json({ code: 1, message: '昵称最长 20 字' });
  }
  if (db.prepare('SELECT id FROM users WHERE username = ?').get(uname)) {
    return res.json({ code: 1, message: '用户名已被注册' });
  }
  const id = genToken();
  const finalNick = nick || ('同学' + Math.floor(Math.random() * 1000));
  db.prepare('INSERT INTO users (id, nickname, avatar, username, password_hash) VALUES (?, ?, ?, ?, ?)')
    .run(id, finalNick, '', uname, hashPassword(pwd));
  res.set('X-Auth-Token', id);
  ok(res, { token: id, user: userPayload(db.prepare('SELECT * FROM users WHERE id = ?').get(id)) });
});

// POST /api/auth/login { username, password }
router.post('/auth/login', (req, res) => {
  const { username, password } = req.body || {};
  const uname = String(username || '').trim();
  const pwd = String(password || '');
  const user = db.prepare('SELECT * FROM users WHERE username = ?').get(uname);
  if (!user || !verifyPassword(pwd, user.password_hash)) {
    return res.json({ code: 1, message: '用户名或密码错误' });
  }
  res.set('X-Auth-Token', user.id);
  ok(res, { token: user.id, user: userPayload(user) });
});

module.exports = router;
