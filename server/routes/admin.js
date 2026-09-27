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

// ---------- 食堂 ----------

router.get('/canteens', (req, res) => {
  ok(res, db.prepare('SELECT * FROM canteens ORDER BY id').all());
});

router.post('/canteens', (req, res) => {
  const { name, location, openHours, floors, image } = req.body || {};
  if (!name) return fail(res, 400, '食堂名称不能为空');
  const id = 'c' + Date.now();
  db.prepare('INSERT INTO canteens (id, name, location, open_hours, floors, image) VALUES (?, ?, ?, ?, ?, ?)')
    .run(id, name, location || '', openHours || '', floors || 1, image || '');
  ok(res, db.prepare('SELECT * FROM canteens WHERE id = ?').get(id));
});

router.put('/canteens/:id', (req, res) => {
  const { name, location, openHours, floors, image } = req.body || {};
  db.prepare('UPDATE canteens SET name = ?, location = ?, open_hours = ?, floors = ?, image = ? WHERE id = ?')
    .run(name, location || '', openHours || '', floors || 1, image || '', req.params.id);
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
  const { canteenId } = req.query;
  const rows = canteenId
    ? db.prepare('SELECT * FROM stalls WHERE canteen_id = ? ORDER BY id').all(canteenId)
    : db.prepare('SELECT * FROM stalls ORDER BY id').all();
  ok(res, rows);
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
  const rows = db.prepare(`
    SELECT d.*, s.name AS stall_name, c.name AS canteen_name
    FROM dishes d
    JOIN stalls s ON d.stall_id = s.id
    JOIN canteens c ON d.canteen_id = c.id
    ORDER BY d.id
  `).all();
  ok(res, rows.map((d) => ({
    id: d.id, stallId: d.stall_id, canteenId: d.canteen_id, name: d.name, price: d.price,
    image: d.image, tags: JSON.parse(d.tags || '[]'), stallName: d.stall_name, canteenName: d.canteen_name,
    rating: d.rating, reviewCount: d.review_count, isSignature: !!d.is_signature, soldOut: !!d.sold_out,
    calories: d.calories, isVegetarian: !!d.is_vegetarian, allergens: JSON.parse(d.allergens || '[]')
  })));
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
  const { status } = req.query;
  const where = status ? 'WHERE r.status = ?' : '';
  const rows = db.prepare(`
    SELECT r.*, d.name AS dish_name
    FROM reviews r JOIN dishes d ON r.dish_id = d.id ${where}
    ORDER BY r.create_time DESC LIMIT 200
  `).all(...(status ? [status] : []));
  ok(res, rows.map((r) => ({
    id: r.id, dishId: r.dish_id, dishName: r.dish_name, rating: r.rating,
    content: r.content, images: JSON.parse(r.images || '[]'), likes: r.likes,
    isAnonymous: !!r.is_anonymous, status: r.status, createTime: r.create_time
  })));
});

// PUT /api/admin/reviews/:id/status { status: 'approved' | 'rejected' }
router.put('/reviews/:id/status', (req, res) => {
  const { status } = req.body || {};
  if (status !== 'approved' && status !== 'rejected') return fail(res, 400, '状态非法');
  const r = db.prepare('SELECT id FROM reviews WHERE id = ?').get(req.params.id);
  if (!r) return fail(res, 404, '评价不存在');
  db.prepare('UPDATE reviews SET status = ? WHERE id = ?').run(status, req.params.id);
  ok(res, { id: req.params.id, status });
});

module.exports = router;
