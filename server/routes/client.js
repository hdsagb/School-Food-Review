/**
 * App 端接口（严格对齐 entry/src/main/ets/net/Api.ets 的路径与字段契约）
 * 统一响应包裹：{ code: 0, message: 'ok', data }
 */
const express = require('express');
const db = require('../db');
const { parseBearer, genToken, guestAuth, registeredAuth, optionalGuest, hashPassword, verifyPassword } = require('../auth');
const { rateLimit } = require('../rateLimit');
const { auditReview } = require('../moderation');

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

/** 菜品查询公共 SQL（联表取档口/食堂名、楼层与所属学校，供按校隔离校验） */
const DISH_SELECT = `
  SELECT d.*, s.name AS stall_name, s.floor AS floor, c.name AS canteen_name, c.school_id AS school_id
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
  // user_id 为 'deleted' 表示作者已注销账号，评价按匿名化保留
  const gone = r.user_id === 'deleted';
  return {
    id: r.id,
    dishId: r.dish_id,
    userId: r.user_id,
    userNickname: gone ? '已注销用户' : (anon ? '匿名同学' : (r.user_nickname || '同学')),
    userAvatar: (anon || gone) ? '' : (r.user_avatar || ''),
    rating: r.rating,
    dimensions: { taste: r.taste, portion: r.portion, value: r.value },
    content: r.content,
    images: JSON.parse(r.images || '[]'),
    likes: r.likes,
    isAnonymous: anon,
    status: r.status,
    rejectReason: r.reject_reason || '',
    createTime: r.create_time
  };
}

/**
 * 某用户的收藏菜品 id 列表
 * 传入 schoolId 时只返回「该学校」的收藏：切换学校后其他学校的收藏被隐藏（记录仍保留），切回原校时重新出现
 */
function favoritesOf(userId, schoolId) {
  if (schoolId === undefined) {
    return db.prepare('SELECT dish_id FROM user_favorites WHERE user_id = ? ORDER BY rowid')
      .all(userId).map((x) => x.dish_id);
  }
  return db.prepare(`
    SELECT f.dish_id FROM user_favorites f
    JOIN dishes d ON d.id = f.dish_id
    JOIN canteens c ON c.id = d.canteen_id
    WHERE f.user_id = ? AND c.school_id = ?
    ORDER BY f.rowid
  `).all(userId, schoolId).map((x) => x.dish_id);
}

// ---------- 学校隔离 ----------

/** 当前请求者所在学校 id（无 token / 未选校返回空串） */
function schoolOf(req) {
  return (req.user && req.user.school_id) || '';
}

/** 内容是否属于请求者所在学校：未选校时一律不可见，避免跨校串数据 */
function isOwnSchool(req, schoolId) {
  const sid = schoolOf(req);
  return !!sid && sid === schoolId;
}

/** 取菜品所属学校 id（不存在返回 undefined） */
function dishSchoolId(dishId) {
  const row = db.prepare(
    'SELECT c.school_id AS school_id FROM dishes d JOIN canteens c ON d.canteen_id = c.id WHERE d.id = ?'
  ).get(dishId);
  return row ? row.school_id : undefined;
}

/** 取食堂所属学校 id（不存在返回 undefined） */
function canteenSchoolId(canteenId) {
  const row = db.prepare('SELECT school_id FROM canteens WHERE id = ?').get(canteenId);
  return row ? row.school_id : undefined;
}

// ---------- 公共数据 ----------

/** 学校查询与映射（App 端按中文/全拼/首字母本地检索，服务端只负责下发全量名单） */
function schoolRowToModel(s) {
  return {
    id: s.id,
    name: s.name,
    level: s.level || '本科',
    city: s.city || '上海',
    pinyinFull: s.pinyin_full || '',
    pinyinInitials: s.pinyin_initials || ''
  };
}

/** 按 id 取学校名（用于个人资料回显），不存在返回空串 */
function schoolNameOf(schoolId) {
  if (!schoolId) return '';
  const row = db.prepare('SELECT name FROM schools WHERE id = ?').get(schoolId);
  return row ? row.name : '';
}

// GET /api/schools 学校名单（本科在前，同层次按 id 稳定排序；含临时测试学校供联调，上线前删除）
router.get('/schools', (req, res) => {
  const rows = db.prepare(
    "SELECT * FROM schools ORDER BY CASE level WHEN '本科' THEN 0 ELSE 1 END, id"
  ).all();
  ok(res, rows.map(schoolRowToModel));
});

// GET /api/canteens 当前用户所在学校的食堂（未选校返回空列表）
router.get('/canteens', optionalGuest, (req, res) => {
  const sid = schoolOf(req);
  if (!sid) return ok(res, []);
  const rows = db.prepare('SELECT * FROM canteens WHERE school_id = ? ORDER BY id').all(sid);
  ok(res, rows.map((c) => ({
    id: c.id, name: c.name, location: c.location,
    openHours: c.open_hours, floors: c.floors, image: c.image
  })));
});

// GET /api/canteens/:canteenId/stalls 仅限本校食堂
router.get('/canteens/:canteenId/stalls', optionalGuest, (req, res) => {
  if (!isOwnSchool(req, canteenSchoolId(req.params.canteenId))) {
    return fail(res, 404, '食堂不存在');
  }
  const rows = db.prepare('SELECT * FROM stalls WHERE canteen_id = ? ORDER BY id').all(req.params.canteenId);
  ok(res, rows.map((s) => ({
    id: s.id, canteenId: s.canteen_id, name: s.name,
    floor: s.floor, cuisine: s.cuisine, image: s.image
  })));
});

// GET /api/menu/today?canteenId=&mealType= 仅限本校食堂
router.get('/menu/today', optionalGuest, (req, res) => {
  const canteenId = req.query.canteenId || '';
  if (!isOwnSchool(req, canteenSchoolId(canteenId))) return ok(res, []);
  let rows = db.prepare(`${DISH_SELECT} WHERE d.canteen_id = ? ORDER BY d.id`).all(canteenId);
  if (req.query.mealType === 'breakfast') rows = rows.slice(0, 2);
  ok(res, rows.map(dishRowToModel));
});

// GET /api/dishes/search?keyword= 仅在本校菜品内检索
router.get('/dishes/search', optionalGuest, (req, res) => {
  const sid = schoolOf(req);
  if (!sid) return ok(res, []);
  const kw = (req.query.keyword || '').trim();
  let rows;
  if (!kw) {
    rows = db.prepare(`${DISH_SELECT} WHERE c.school_id = ? ORDER BY d.id`).all(sid);
  } else {
    const like = `%${kw}%`;
    rows = db.prepare(`${DISH_SELECT} WHERE c.school_id = ? AND (d.name LIKE ? OR d.tags LIKE ?) ORDER BY d.id`)
      .all(sid, like, like);
  }
  ok(res, rows.map(dishRowToModel));
});

// GET /api/dishes/:dishId 仅限本校菜品
router.get('/dishes/:dishId', optionalGuest, (req, res) => {
  const d = db.prepare(`${DISH_SELECT} WHERE d.id = ?`).get(req.params.dishId);
  if (!d || !isOwnSchool(req, d.school_id)) return fail(res, 404, '菜品不存在');
  ok(res, dishRowToModel(d));
});

// GET /api/dishes/:dishId/reviews?page=&pageSize=&sort= 仅限本校菜品
router.get('/dishes/:dishId/reviews', optionalGuest, (req, res) => {
  if (!isOwnSchool(req, dishSchoolId(req.params.dishId))) return fail(res, 404, '菜品不存在');
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
router.post('/reviews', registeredAuth, rateLimit({ windowMs: 10 * 60 * 1000, max: 10, scope: 'review', keyOf: (req) => req.user.id }), (req, res) => {
  const { dishId, rating, dimensions, content, images, isAnonymous } = req.body || {};
  if (!dishId || typeof rating !== 'number' || !content) return fail(res, 400, '参数不完整');
  // 只能评价本校菜品，防止跨校提交
  if (!isOwnSchool(req, dishSchoolId(dishId))) return fail(res, 404, '菜品不存在');

  // 每个账号的评价频率限制（每日 / 每月上限由管理后台配置）
  const limits = reviewLimits();
  if (countReviewsSince(req.user.id, dayStartIso()) >= limits.daily) {
    return fail(res, 429, `今日评价已达上限（${limits.daily} 条），明天再来吧`);
  }
  if (countReviewsSince(req.user.id, monthStartIso()) >= limits.monthly) {
    return fail(res, 429, `本月评价已达上限（${limits.monthly} 条），下个月再来吧`);
  }

  // L1 自动审核：命中规则直接驳回并返回原因，其余进入待审核；审核通过后才对外可见
  const verdict = auditReview({ userId: req.user.id, dishId, content });
  const status = verdict.reject ? 'rejected' : 'pending';
  const rejectReason = verdict.reason;
  // 记录命中的规则名，管理后台据此区分「自动驳回 / 人工驳回」
  const moderationRule = verdict.rule;

  const id = 'r' + Date.now() + Math.floor(Math.random() * 1000);
  const createTime = new Date().toISOString();
  const dim = dimensions || {};
  db.prepare(`
    INSERT INTO reviews (id, dish_id, user_id, rating, taste, portion, value, content, images,
                         likes, is_anonymous, status, reject_reason, moderation_rule, create_time)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?)
  `).run(
    id, dishId, req.user.id, rating,
    dim.taste || rating, dim.portion || rating, dim.value || rating,
    content, JSON.stringify(images || []), isAnonymous ? 1 : 0, status, rejectReason, moderationRule, createTime
  );

  // 待审/驳回的评价不计入菜品统计，重算后数值保持不变
  db.recalcDishStats(dishId);

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

// POST /api/reviews/:reviewId/report { reason, detail } 举报评价（仅注册用户）
router.post('/reviews/:reviewId/report', registeredAuth, rateLimit({ windowMs: 60 * 60 * 1000, max: 20, scope: 'report', keyOf: (req) => req.user.id }), (req, res) => {
  const { reason, detail } = req.body || {};
  const reviewId = req.params.reviewId;
  const r = db.prepare('SELECT id, dish_id, status FROM reviews WHERE id = ?').get(reviewId);
  if (!r) return fail(res, 404, '评价不存在');

  // 同一用户对同一条评价的重复举报不再累加
  const dup = db.prepare(
    "SELECT id FROM review_reports WHERE review_id = ? AND user_id = ? AND status = 'pending'"
  ).get(reviewId, req.user.id);
  if (dup) return ok(res, { reported: true });

  const id = 'p' + Date.now() + Math.floor(Math.random() * 1000);
  db.prepare(`
    INSERT INTO review_reports (id, review_id, user_id, reason, detail, status, create_time)
    VALUES (?, ?, ?, ?, ?, 'pending', ?)
  `).run(id, reviewId, req.user.id, String(reason || ''), String(detail || ''), new Date().toISOString());

  // 已通过的评价被举报后立即下架，转待审等人工复核
  if (r.status === 'approved') {
    db.prepare("UPDATE reviews SET status = 'pending', reject_reason = '' WHERE id = ?").run(reviewId);
    db.recalcDishStats(r.dish_id);
  }
  ok(res, { reported: true });
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
    schoolId: user.school_id || '',
    schoolName: schoolNameOf(user.school_id),
    favorites: favoritesOf(user.id, user.school_id || '')
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

// GET /api/user/favorites 当前学校的收藏菜品 id（用于红心状态，切换学校后隐藏他校收藏）
router.get('/user/favorites', guestAuth, (req, res) => {
  ok(res, favoritesOf(req.user.id, req.user.school_id || ''));
});

// GET /api/user/favorites/dishes 仅返回「当前学校」的收藏菜品
// 切校后其他学校的收藏被隐藏（记录仍保留），切回原校时重新出现
router.get('/user/favorites/dishes', guestAuth, (req, res) => {
  const sid = req.user.school_id || '';
  if (!sid) return ok(res, []);
  const rows = db.prepare(
    `${DISH_SELECT} JOIN user_favorites f ON d.id = f.dish_id WHERE f.user_id = ? AND c.school_id = ? ORDER BY f.rowid`
  ).all(req.user.id, sid);
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
  ok(res, favoritesOf(req.user.id, req.user.school_id || ''));
});

// PUT /api/user/school { schoolId } 选择 / 切换学校
// 游客也可设置：学校在注册前（首次打开应用）收集，因此不能要求已注册
router.put('/user/school', guestAuth, (req, res) => {
  const { schoolId } = req.body || {};
  const sid = String(schoolId || '').trim();
  if (!sid) return fail(res, 400, '请选择学校');
  if (!db.prepare('SELECT id FROM schools WHERE id = ?').get(sid)) return fail(res, 404, '学校不存在');
  db.prepare('UPDATE users SET school_id = ? WHERE id = ?').run(sid, req.user.id);
  ok(res, userPayload(db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id)));
});

// POST /api/user/delete { password } 注销账号（仅注册用户）
router.post('/user/delete', registeredAuth, (req, res) => {
  const { password } = req.body || {};
  if (!password) return fail(res, 400, '请输入登录密码以确认注销');
  if (!verifyPassword(String(password), req.user.password_hash)) {
    return fail(res, 403, '密码不正确');
  }

  const uid = req.user.id;
  try {
    db.exec('BEGIN');
    // 评价匿名化保留：作者改挂到 'deleted' 标识，社区内容与菜品评分不受影响
    db.prepare("UPDATE reviews SET user_id = 'deleted' WHERE user_id = ?").run(uid);
    // 点赞记录删除前先回减对应评价的点赞数，避免计数漂移
    const likedRows = db.prepare('SELECT review_id FROM review_likes WHERE user_id = ?').all(uid);
    for (const row of likedRows) {
      db.prepare('UPDATE reviews SET likes = MAX(0, likes - 1) WHERE id = ?').run(row.review_id);
    }
    db.prepare('DELETE FROM user_favorites WHERE user_id = ?').run(uid);
    db.prepare('DELETE FROM review_likes WHERE user_id = ?').run(uid);
    db.prepare('DELETE FROM review_reports WHERE user_id = ?').run(uid);
    db.prepare('DELETE FROM users WHERE id = ?').run(uid);
    db.exec('COMMIT');
  } catch (e) {
    db.exec('ROLLBACK');
    return fail(res, 500, '注销失败，请稍后重试');
  }
  ok(res, { deleted: true });
});

// ---------- 注册 / 登录 ----------

function userPayload(user) {
  return {
    id: user.id,
    nickname: user.nickname,
    avatar: user.avatar || '',
    username: user.username || '',
    schoolId: user.school_id || '',
    schoolName: schoolNameOf(user.school_id),
    favorites: favoritesOf(user.id, user.school_id || '')
  };
}

// POST /api/auth/register { username, password, nickname? }
router.post('/auth/register', rateLimit({ windowMs: 60 * 60 * 1000, max: 30, scope: 'register', message: '注册过于频繁，请稍后再试' }), (req, res) => {
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
// 双维度限流：先按账号防暴力破解（不受校园网 NAT 影响），再按 IP 兜底防批量尝试
router.post('/auth/login',
  rateLimit({
    windowMs: 15 * 60 * 1000, max: 10, scope: 'login-user',
    keyOf: (req) => String((req.body || {}).username || '').trim().toLowerCase()
  }),
  rateLimit({ windowMs: 15 * 60 * 1000, max: 100, scope: 'login-ip' }),
  (req, res) => {
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
