/**
 * 管理端接口（网页管理后台使用）
 * 管理员账号：admin / admin123
 */
const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db');
const { genToken, adminAuth } = require('../auth');

const router = express.Router();

function ok(res, data) {
  res.json({ code: 0, message: 'ok', data });
}

function fail(res, status, message) {
  res.status(status).json({ code: 1, message });
}

// ---------- 登录 ----------

// POST /api/admin/login { username, password }
router.post('/login', (req, res) => {
  const { username, password } = req.body || {};
  const admin = db.prepare('SELECT * FROM admins WHERE username = ?').get(username || '');
  if (!admin || !bcrypt.compareSync(password || '', admin.password_hash)) {
    return fail(res, 401, '账号或密码错误');
  }
  const token = genToken();
  db.prepare('INSERT INTO admin_sessions (token, admin_id) VALUES (?, ?)').run(token, admin.id);
  ok(res, { token, username: admin.username });
});

// 以下接口需管理员登录
router.use(adminAuth);

// ---------- 学校 ----------

// GET /api/admin/schools 学校列表（附食堂 / 菜品 / 用户数，供判断能否直接删除）
router.get('/schools', (req, res) => {
  const rows = db.prepare(`
    SELECT s.*,
      (SELECT COUNT(*) FROM canteens c WHERE c.school_id = s.id) AS canteen_count,
      (SELECT COUNT(*) FROM dishes d JOIN canteens c ON d.canteen_id = c.id WHERE c.school_id = s.id) AS dish_count,
      (SELECT COUNT(*) FROM users u WHERE u.school_id = s.id) AS user_count
    FROM schools s
    ORDER BY s.create_time, s.id
  `).all();
  ok(res, rows.map((s) => ({
    id: s.id, name: s.name, level: s.level, city: s.city,
    pinyinFull: s.pinyin_full, pinyinInitials: s.pinyin_initials, createTime: s.create_time,
    canteenCount: s.canteen_count, dishCount: s.dish_count, userCount: s.user_count
  })));
});

// POST /api/admin/schools { name, level, city, pinyinFull, pinyinInitials }
router.post('/schools', (req, res) => {
  const { name, level, city, pinyinFull, pinyinInitials } = req.body || {};
  const nm = String(name || '').trim();
  if (!nm) return fail(res, 400, '学校名称不能为空');
  if (db.prepare('SELECT id FROM schools WHERE name = ?').get(nm)) return fail(res, 400, '该学校已存在');
  const id = 'sch' + Date.now();
  db.prepare(`
    INSERT INTO schools (id, name, level, city, pinyin_full, pinyin_initials, create_time)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(id, nm, level === '专科' ? '专科' : '本科', String(city || '上海').trim() || '上海',
    String(pinyinFull || '').trim(), String(pinyinInitials || '').trim(), new Date().toISOString());
  ok(res, { id });
});

// PUT /api/admin/schools/:id 局部更新
router.put('/schools/:id', (req, res) => {
  const cur = db.prepare('SELECT * FROM schools WHERE id = ?').get(req.params.id);
  if (!cur) return fail(res, 404, '学校不存在');
  const b = req.body || {};
  const name = b.name !== undefined ? String(b.name).trim() : cur.name;
  if (!name) return fail(res, 400, '学校名称不能为空');
  const dup = db.prepare('SELECT id FROM schools WHERE name = ? AND id <> ?').get(name, req.params.id);
  if (dup) return fail(res, 400, '已存在同名学校');
  db.prepare(`
    UPDATE schools SET name = ?, level = ?, city = ?, pinyin_full = ?, pinyin_initials = ? WHERE id = ?
  `).run(
    name,
    (b.level !== undefined ? (b.level === '专科' ? '专科' : '本科') : cur.level),
    (b.city !== undefined ? String(b.city).trim() : cur.city),
    (b.pinyinFull !== undefined ? String(b.pinyinFull).trim() : cur.pinyin_full),
    (b.pinyinInitials !== undefined ? String(b.pinyinInitials).trim() : cur.pinyin_initials),
    req.params.id
  );
  ok(res, { id: req.params.id });
});

// DELETE /api/admin/schools/:id
// 默认拒绝删除仍有食堂或用户的学校（避免误删导致数据孤立）；?force=1 时级联删除该校食堂及其菜品/评价，
// 并把该校用户置为「未选校」以便重新选择。
router.delete('/schools/:id', (req, res) => {
  const id = req.params.id;
  const school = db.prepare('SELECT id, name FROM schools WHERE id = ?').get(id);
  if (!school) return fail(res, 404, '学校不存在');
  const canteenCount = db.prepare('SELECT COUNT(*) AS n FROM canteens WHERE school_id = ?').get(id).n;
  const userCount = db.prepare('SELECT COUNT(*) AS n FROM users WHERE school_id = ?').get(id).n;
  const force = req.query.force === '1';

  if (!force && (canteenCount > 0 || userCount > 0)) {
    return fail(res, 400, `该校仍有 ${canteenCount} 个食堂、${userCount} 名用户，请先转移或删除后再操作`);
  }

  db.exec('BEGIN');
  try {
    // 级联删除：收藏 → 评价 → 菜品 → 档口 → 食堂
    db.prepare('DELETE FROM user_favorites WHERE dish_id IN (SELECT d.id FROM dishes d JOIN canteens c ON d.canteen_id = c.id WHERE c.school_id = ?)').run(id);
    db.prepare('DELETE FROM reviews WHERE dish_id IN (SELECT d.id FROM dishes d JOIN canteens c ON d.canteen_id = c.id WHERE c.school_id = ?)').run(id);
    db.prepare('DELETE FROM dishes WHERE canteen_id IN (SELECT id FROM canteens WHERE school_id = ?)').run(id);
    db.prepare('DELETE FROM stalls WHERE canteen_id IN (SELECT id FROM canteens WHERE school_id = ?)').run(id);
    db.prepare('DELETE FROM canteens WHERE school_id = ?').run(id);
    // 用户不删除，置为未选校（下次打开应用会引导重新选校）
    db.prepare("UPDATE users SET school_id = '' WHERE school_id = ?").run(id);
    db.prepare('DELETE FROM schools WHERE id = ?').run(id);
    db.exec('COMMIT');
  } catch (e) {
    db.exec('ROLLBACK');
    return fail(res, 500, '删除失败');
  }
  ok(res, { id, canteenCount, userCount });
});

// ---------- 食堂 ----------

router.get('/canteens', (req, res) => {
  const rows = db.prepare(`
    SELECT c.*, s.name AS school_name
    FROM canteens c LEFT JOIN schools s ON c.school_id = s.id
    ORDER BY c.school_id, c.id
  `).all();
  ok(res, rows);
});

router.post('/canteens', (req, res) => {
  const { name, location, openHours, floors, image, schoolId } = req.body || {};
  if (!name) return fail(res, 400, '食堂名称不能为空');
  if (!schoolId) return fail(res, 400, '请选择所属学校');
  const id = 'c' + Date.now();
  db.prepare('INSERT INTO canteens (id, name, location, open_hours, floors, image, school_id) VALUES (?, ?, ?, ?, ?, ?, ?)')
    .run(id, name, location || '', openHours || '', floors || 1, image || '', schoolId);
  ok(res, db.prepare('SELECT * FROM canteens WHERE id = ?').get(id));
});

router.put('/canteens/:id', (req, res) => {
  const { name, location, openHours, floors, image, schoolId } = req.body || {};
  const exists = db.prepare('SELECT id FROM canteens WHERE id = ?').get(req.params.id);
  if (!exists) return fail(res, 404, '食堂不存在');
  if (!schoolId) return fail(res, 400, '请选择所属学校');
  db.prepare('UPDATE canteens SET name = ?, location = ?, open_hours = ?, floors = ?, image = ?, school_id = ? WHERE id = ?')
    .run(name, location || '', openHours || '', floors || 1, image || '', schoolId, req.params.id);
  ok(res, db.prepare('SELECT * FROM canteens WHERE id = ?').get(req.params.id));
});

router.delete('/canteens/:id', (req, res) => {
  const id = req.params.id;
  db.prepare('DELETE FROM user_favorites WHERE dish_id IN (SELECT id FROM dishes WHERE canteen_id = ?)').run(id);
  db.prepare('DELETE FROM reviews WHERE dish_id IN (SELECT id FROM dishes WHERE canteen_id = ?)').run(id);
  db.prepare('DELETE FROM dishes WHERE canteen_id = ?').run(id);
  db.prepare('DELETE FROM stalls WHERE canteen_id = ?').run(id);
  db.prepare('DELETE FROM canteens WHERE id = ?').run(id);
  ok(res, { id });
});

// ---------- 档口 ----------

router.get('/stalls', (req, res) => {
  const { canteenId, schoolId, page, pageSize } = req.query;
  const conds = [];
  const params = [];
  if (canteenId) { conds.push('s.canteen_id = ?'); params.push(canteenId); }
  if (schoolId) { conds.push('c.school_id = ?'); params.push(schoolId); }
  const where = conds.length ? 'WHERE ' + conds.join(' AND ') : '';
  const total = db.prepare(`
    SELECT COUNT(*) AS n FROM stalls s LEFT JOIN canteens c ON s.canteen_id = c.id ${where}
  `).get(...params).n;
  const p = Math.max(1, parseInt(page || '1', 10) || 1);
  const ps = Math.min(200, Math.max(1, parseInt(pageSize || '20', 10) || 20));
  const list = db.prepare(`
    SELECT s.*, c.school_id AS school_id, sch.name AS school_name
    FROM stalls s
    LEFT JOIN canteens c ON s.canteen_id = c.id
    LEFT JOIN schools sch ON c.school_id = sch.id
    ${where}
    ORDER BY c.school_id, s.id
    LIMIT ? OFFSET ?
  `).all(...params, ps, (p - 1) * ps);
  ok(res, { list, total, page: p, pageSize: ps, hasMore: p * ps < total });
});

router.post('/stalls', (req, res) => {
  const { canteenId, name, floor, cuisine, image } = req.body || {};
  if (!canteenId || !name) return fail(res, 400, '食堂与档口名称不能为空');
  const id = 's' + Date.now();
  db.prepare('INSERT INTO stalls (id, canteen_id, name, floor, cuisine, image) VALUES (?, ?, ?, ?, ?, ?)')
    .run(id, canteenId, name, floor || 1, cuisine || '', image || '');
  ok(res, db.prepare('SELECT * FROM stalls WHERE id = ?').get(id));
});

router.put('/stalls/:id', (req, res) => {
  const { canteenId, name, floor, cuisine, image } = req.body || {};
  db.prepare('UPDATE stalls SET canteen_id = ?, name = ?, floor = ?, cuisine = ?, image = ? WHERE id = ?')
    .run(canteenId, name, floor || 1, cuisine || '', image || '', req.params.id);
  ok(res, db.prepare('SELECT * FROM stalls WHERE id = ?').get(req.params.id));
});

router.delete('/stalls/:id', (req, res) => {
  const id = req.params.id;
  db.prepare('DELETE FROM user_favorites WHERE dish_id IN (SELECT id FROM dishes WHERE stall_id = ?)').run(id);
  db.prepare('DELETE FROM reviews WHERE dish_id IN (SELECT id FROM dishes WHERE stall_id = ?)').run(id);
  db.prepare('DELETE FROM dishes WHERE stall_id = ?').run(id);
  db.prepare('DELETE FROM stalls WHERE id = ?').run(id);
  ok(res, { id });
});

// ---------- 菜品 ----------

router.get('/dishes', (req, res) => {
  const { schoolId, page, pageSize } = req.query;
  const conds = [];
  const params = [];
  if (schoolId) { conds.push('c.school_id = ?'); params.push(schoolId); }
  const where = conds.length ? 'WHERE ' + conds.join(' AND ') : '';
  const total = db.prepare(`
    SELECT COUNT(*) AS n FROM dishes d JOIN canteens c ON d.canteen_id = c.id ${where}
  `).get(...params).n;
  const p = Math.max(1, parseInt(page || '1', 10) || 1);
  const ps = Math.min(200, Math.max(1, parseInt(pageSize || '20', 10) || 20));
  const rows = db.prepare(`
    SELECT d.*, s.name AS stall_name, c.name AS canteen_name, sch.name AS school_name
    FROM dishes d
    JOIN stalls s ON d.stall_id = s.id
    JOIN canteens c ON d.canteen_id = c.id
    LEFT JOIN schools sch ON c.school_id = sch.id
    ${where}
    ORDER BY c.school_id, d.id
    LIMIT ? OFFSET ?
  `).all(...params, ps, (p - 1) * ps);
  ok(res, {
    list: rows.map((d) => ({
      id: d.id, stallId: d.stall_id, canteenId: d.canteen_id, name: d.name, price: d.price,
      image: d.image, tags: JSON.parse(d.tags || '[]'), stallName: d.stall_name, canteenName: d.canteen_name,
      schoolName: d.school_name || '', rating: d.rating, reviewCount: d.review_count,
      isSignature: !!d.is_signature, soldOut: !!d.sold_out, calories: d.calories,
      isVegetarian: !!d.is_vegetarian, allergens: JSON.parse(d.allergens || '[]')
    })),
    total, page: p, pageSize: ps, hasMore: p * ps < total
  });
});

router.post('/dishes', (req, res) => {
  const { stallId, canteenId, name, price, image, tags, calories, isVegetarian, allergens, isSignature, soldOut } = req.body || {};
  if (!stallId || !canteenId || !name) return fail(res, 400, '档口/食堂/名称不能为空');
  const id = 'd' + Date.now() + Math.floor(Math.random() * 1000);
  db.prepare(`
    INSERT INTO dishes (id, stall_id, canteen_id, name, price, image, tags, rating, review_count,
                        is_signature, sold_out, calories, is_vegetarian, allergens)
    VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, ?, ?, ?, ?, ?)
  `).run(id, stallId, canteenId, name, price || 0, image || '', JSON.stringify(tags || []),
    isSignature ? 1 : 0, soldOut ? 1 : 0, calories || 0, isVegetarian ? 1 : 0, JSON.stringify(allergens || []));
  ok(res, { id });
});

// 支持局部更新（售罄开关等）
router.put('/dishes/:id', (req, res) => {
  const id = req.params.id;
  const exists = db.prepare('SELECT id FROM dishes WHERE id = ?').get(id);
  if (!exists) return fail(res, 404, '菜品不存在');
  const cur = db.prepare('SELECT * FROM dishes WHERE id = ?').get(id);
  const b = req.body || {};
  const name = b.name !== undefined ? b.name : cur.name;
  const stallId = b.stallId !== undefined ? b.stallId : cur.stall_id;
  const canteenId = b.canteenId !== undefined ? b.canteenId : cur.canteen_id;
  const price = b.price !== undefined ? b.price : cur.price;
  const image = b.image !== undefined ? b.image : cur.image;
  const tags = b.tags !== undefined ? JSON.stringify(b.tags) : cur.tags;
  const isSignature = b.isSignature !== undefined ? (b.isSignature ? 1 : 0) : cur.is_signature;
  const soldOut = b.soldOut !== undefined ? (b.soldOut ? 1 : 0) : cur.sold_out;
  const calories = b.calories !== undefined ? b.calories : cur.calories;
  const isVegetarian = b.isVegetarian !== undefined ? (b.isVegetarian ? 1 : 0) : cur.is_vegetarian;
  const allergens = b.allergens !== undefined ? JSON.stringify(b.allergens) : cur.allergens;
  db.prepare(`
    UPDATE dishes SET stall_id = ?, canteen_id = ?, name = ?, price = ?, image = ?, tags = ?,
                      is_signature = ?, sold_out = ?, calories = ?, is_vegetarian = ?, allergens = ?
    WHERE id = ?
  `).run(stallId, canteenId, name, price, image, tags, isSignature, soldOut, calories, isVegetarian, allergens, id);
  ok(res, { id });
});

router.delete('/dishes/:id', (req, res) => {
  const id = req.params.id;
  db.prepare('DELETE FROM user_favorites WHERE dish_id = ?').run(id);
  db.prepare('DELETE FROM reviews WHERE dish_id = ?').run(id);
  db.prepare('DELETE FROM dishes WHERE id = ?').run(id);
  ok(res, { id });
});

// ---------- 评价审核 ----------

router.get('/reviews', (req, res) => {
  const { status, schoolId, keyword, page, pageSize } = req.query;
  const conds = [];
  const params = [];
  if (status) { conds.push('r.status = ?'); params.push(status); }
  if (schoolId) { conds.push('c.school_id = ?'); params.push(schoolId); }
  const kw = String(keyword || '').trim();
  if (kw) { conds.push('(r.content LIKE ? OR d.name LIKE ?)'); params.push('%' + kw + '%', '%' + kw + '%'); }
  const where = conds.length ? 'WHERE ' + conds.join(' AND ') : '';
  const total = db.prepare(`
    SELECT COUNT(*) AS n FROM reviews r JOIN dishes d ON r.dish_id = d.id
    LEFT JOIN canteens c ON d.canteen_id = c.id ${where}
  `).get(...params).n;
  const p = Math.max(1, parseInt(page || '1', 10) || 1);
  const ps = Math.min(200, Math.max(1, parseInt(pageSize || '20', 10) || 20));
  const rows = db.prepare(`
    SELECT r.*, d.name AS dish_name, c.school_id AS school_id, s.name AS school_name
    FROM reviews r
    JOIN dishes d ON r.dish_id = d.id
    LEFT JOIN canteens c ON d.canteen_id = c.id
    LEFT JOIN schools s ON c.school_id = s.id
    ${where}
    ORDER BY r.create_time DESC LIMIT ? OFFSET ?
  `).all(...params, ps, (p - 1) * ps);
  ok(res, {
    list: rows.map((r) => ({
      id: r.id, dishId: r.dish_id, dishName: r.dish_name, rating: r.rating,
      content: r.content, images: JSON.parse(r.images || '[]'), likes: r.likes,
      isAnonymous: !!r.is_anonymous, status: r.status,
      rejectReason: r.reject_reason || '', moderationRule: r.moderation_rule || '',
      schoolId: r.school_id || '', schoolName: r.school_name || '',
      createTime: r.create_time
    })),
    total, page: p, pageSize: ps, hasMore: p * ps < total
  });
});

// DELETE /api/admin/reviews/:id 直接删除单条评价（违规内容即时下架，并重算菜品统计）
// 关联的举报记录保留，作为处理留痕（举报列表会显示「评价已删除」）
router.delete('/reviews/:id', (req, res) => {
  const r = db.prepare('SELECT id, dish_id FROM reviews WHERE id = ?').get(req.params.id);
  if (!r) return fail(res, 404, '评价不存在');
  db.prepare('DELETE FROM review_likes WHERE review_id = ?').run(req.params.id);
  db.prepare('DELETE FROM reviews WHERE id = ?').run(req.params.id);
  db.recalcDishStats(r.dish_id);
  ok(res, { id: req.params.id });
});

// POST /api/admin/reviews/batch-status { ids: string[], status, rejectReason? } 批量审核
router.post('/reviews/batch-status', (req, res) => {
  const { ids, status, rejectReason } = req.body || {};
  if (!Array.isArray(ids) || ids.length === 0) return fail(res, 400, '请先勾选要操作的评价');
  if (status !== 'approved' && status !== 'rejected' && status !== 'pending') return fail(res, 400, '状态非法');
  const reason = status === 'rejected' ? String(rejectReason || '未通过审核') : '';

  const sel = db.prepare('SELECT id, dish_id FROM reviews WHERE id = ?');
  const upd = db.prepare('UPDATE reviews SET status = ?, reject_reason = ? WHERE id = ?');
  const dishes = new Set();
  let updated = 0;
  db.exec('BEGIN');
  try {
    for (const raw of ids) {
      const row = sel.get(String(raw));
      if (!row) continue;
      upd.run(status, reason, row.id);
      dishes.add(row.dish_id);
      updated++;
    }
    db.exec('COMMIT');
  } catch (e) {
    db.exec('ROLLBACK');
    return fail(res, 500, '批量操作失败');
  }
  // 状态流转影响「已通过」集合，逐个重算受影响菜品
  for (const dishId of dishes) db.recalcDishStats(dishId);
  ok(res, { updated, status });
});

// PUT /api/admin/reviews/:id/status { status: 'approved' | 'rejected' | 'pending', rejectReason? }
router.put('/reviews/:id/status', (req, res) => {
  const { status, rejectReason } = req.body || {};
  if (status !== 'approved' && status !== 'rejected' && status !== 'pending') {
    return fail(res, 400, '状态非法');
  }
  const r = db.prepare('SELECT id, dish_id FROM reviews WHERE id = ?').get(req.params.id);
  if (!r) return fail(res, 404, '评价不存在');

  // 驳回时记录原因，供 App 端「我的评价」展示
  const reason = status === 'rejected' ? String(rejectReason || '未通过审核') : '';
  db.prepare('UPDATE reviews SET status = ?, reject_reason = ? WHERE id = ?')
    .run(status, reason, req.params.id);

  // 状态流转会改变「已通过」集合，必须重算菜品评分与评价数，否则统计失真
  db.recalcDishStats(r.dish_id);
  ok(res, { id: req.params.id, status, rejectReason: reason });
});

// ---------- 评价上限设置 ----------

function readLimitSettings() {
  const rows = db.prepare(
    "SELECT key, value FROM settings WHERE key IN ('daily_review_limit', 'monthly_review_limit')"
  ).all();
  const map = {};
  for (const r of rows) map[r.key] = Number(r.value);
  return {
    dailyReviewLimit: Number.isFinite(map.daily_review_limit) ? map.daily_review_limit : 50,
    monthlyReviewLimit: Number.isFinite(map.monthly_review_limit) ? map.monthly_review_limit : 400
  };
}

router.get('/settings', (req, res) => {
  ok(res, readLimitSettings());
});

// PUT /api/admin/settings { dailyReviewLimit, monthlyReviewLimit } 每个账号的评价频率上限
router.put('/settings', (req, res) => {
  const { dailyReviewLimit, monthlyReviewLimit } = req.body || {};
  const daily = Number(dailyReviewLimit);
  const monthly = Number(monthlyReviewLimit);
  if (!Number.isInteger(daily) || daily < 1) return fail(res, 400, '每日上限必须是大于 0 的整数');
  if (!Number.isInteger(monthly) || monthly < 1) return fail(res, 400, '每月上限必须是大于 0 的整数');

  const upsert = db.prepare(`
    INSERT INTO settings (key, value) VALUES (?, ?)
    ON CONFLICT(key) DO UPDATE SET value = excluded.value
  `);
  upsert.run('daily_review_limit', String(daily));
  upsert.run('monthly_review_limit', String(monthly));
  ok(res, readLimitSettings());
});

// ---------- 举报处理 ----------

// GET /api/admin/reports?status=pending&schoolId=xxx&page=1&pageSize=20
router.get('/reports', (req, res) => {
  const { status, schoolId, page, pageSize } = req.query;
  const conds = [];
  const params = [];
  if (status) { conds.push('p.status = ?'); params.push(status); }
  if (schoolId) { conds.push('c.school_id = ?'); params.push(schoolId); }
  const where = conds.length ? 'WHERE ' + conds.join(' AND ') : '';
  const joins = `
    FROM review_reports p
    LEFT JOIN reviews r ON p.review_id = r.id
    LEFT JOIN dishes d ON r.dish_id = d.id
    LEFT JOIN canteens c ON d.canteen_id = c.id
    LEFT JOIN schools s ON c.school_id = s.id
  `;
  const total = db.prepare(`SELECT COUNT(*) AS n ${joins} ${where}`).get(...params).n;
  const p = Math.max(1, parseInt(page || '1', 10) || 1);
  const ps = Math.min(200, Math.max(1, parseInt(pageSize || '20', 10) || 20));
  const rows = db.prepare(`
    SELECT p.*, r.content AS review_content, r.status AS review_status, d.name AS dish_name,
           s.name AS school_name
    ${joins}
    ${where}
    ORDER BY p.create_time DESC LIMIT ? OFFSET ?
  `).all(...params, ps, (p - 1) * ps);
  ok(res, {
    list: rows.map((p2) => ({
      id: p2.id,
      reviewId: p2.review_id,
      reviewContent: p2.review_content || '（评价已删除）',
      reviewStatus: p2.review_status || '',
      dishName: p2.dish_name || '',
      schoolName: p2.school_name || '',
      reason: p2.reason,
      detail: p2.detail,
      status: p2.status,
      createTime: p2.create_time
    })),
    total, page: p, pageSize: ps, hasMore: p * ps < total
  });
});

// PUT /api/admin/reports/:id { status: 'handled' | 'ignored', reviewStatus?: 'approved' | 'rejected' }
// 处理举报时可选一并裁决被举报的评价
router.put('/reports/:id', (req, res) => {
  const { status, reviewStatus } = req.body || {};
  if (status !== 'handled' && status !== 'ignored') return fail(res, 400, '状态非法');
  const p = db.prepare('SELECT id, review_id FROM review_reports WHERE id = ?').get(req.params.id);
  if (!p) return fail(res, 404, '举报不存在');

  db.prepare('UPDATE review_reports SET status = ? WHERE id = ?').run(status, req.params.id);

  if (reviewStatus === 'approved' || reviewStatus === 'rejected') {
    const r = db.prepare('SELECT dish_id FROM reviews WHERE id = ?').get(p.review_id);
    if (r) {
      const reason = reviewStatus === 'rejected' ? '举报核实，内容违规' : '';
      db.prepare('UPDATE reviews SET status = ?, reject_reason = ? WHERE id = ?')
        .run(reviewStatus, reason, p.review_id);
      db.recalcDishStats(r.dish_id);
    }
  }
  ok(res, { id: req.params.id, status });
});

// ---------- 敏感词库 ----------

router.get('/banned-words', (req, res) => {
  ok(res, db.prepare('SELECT word FROM banned_words ORDER BY word').all().map((x) => x.word));
});

// PUT /api/admin/banned-words { words: string[] } 覆盖式保存词库
router.put('/banned-words', (req, res) => {
  const { words } = req.body || {};
  if (!Array.isArray(words)) return fail(res, 400, 'words 必须是数组');
  const list = Array.from(new Set(words.map((w) => String(w).trim()).filter((w) => w.length > 0)));

  db.exec('BEGIN');
  try {
    db.prepare('DELETE FROM banned_words').run();
    const ins = db.prepare('INSERT OR IGNORE INTO banned_words (word, create_time) VALUES (?, ?)');
    const t = new Date().toISOString();
    for (const w of list) ins.run(w, t);
    db.exec('COMMIT');
  } catch (e) {
    db.exec('ROLLBACK');
    return fail(res, 500, '保存失败');
  }
  ok(res, list);
});

module.exports = router;
