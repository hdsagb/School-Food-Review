/**
 * 数据库初始化与种子数据
 * 使用 Node.js 内置 node:sqlite（Node >= 22.5），无需原生编译
 */
const { DatabaseSync } = require('node:sqlite');
const path = require('path');
const bcrypt = require('bcryptjs');

const DB_PATH = path.join(__dirname, 'data.db');

const db = new DatabaseSync(DB_PATH);

db.exec(`
PRAGMA journal_mode = WAL;

CREATE TABLE IF NOT EXISTS canteens (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT DEFAULT '',
  open_hours TEXT DEFAULT '',
  floors INTEGER DEFAULT 1,
  image TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS stalls (
  id TEXT PRIMARY KEY,
  canteen_id TEXT NOT NULL,
  name TEXT NOT NULL,
  floor INTEGER DEFAULT 1,
  cuisine TEXT DEFAULT '',
  image TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS dishes (
  id TEXT PRIMARY KEY,
  stall_id TEXT NOT NULL,
  canteen_id TEXT NOT NULL,
  name TEXT NOT NULL,
  price REAL NOT NULL DEFAULT 0,
  image TEXT DEFAULT '',
  tags TEXT DEFAULT '[]',
  rating REAL DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  is_signature INTEGER DEFAULT 0,
  sold_out INTEGER DEFAULT 0,
  calories INTEGER DEFAULT 0,
  is_vegetarian INTEGER DEFAULT 0,
  allergens TEXT DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  nickname TEXT NOT NULL,
  avatar TEXT DEFAULT '',
  username TEXT DEFAULT '',
  password_hash TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS user_favorites (
  user_id TEXT NOT NULL,
  dish_id TEXT NOT NULL,
  rowid INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS reviews (
  id TEXT PRIMARY KEY,
  dish_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  rating INTEGER NOT NULL,
  taste INTEGER NOT NULL,
  portion INTEGER NOT NULL,
  value INTEGER NOT NULL,
  content TEXT DEFAULT '',
  images TEXT DEFAULT '[]',
  likes INTEGER DEFAULT 0,
  is_anonymous INTEGER DEFAULT 0,
  status TEXT DEFAULT 'approved',
  create_time TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS review_likes (
  review_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  PRIMARY KEY (review_id, user_id)
);

CREATE TABLE IF NOT EXISTS admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS admin_sessions (
  token TEXT PRIMARY KEY,
  admin_id INTEGER NOT NULL
);
`);

// ---------- 旧库迁移：users 表补 username / password_hash 列（已存在则忽略报错） ----------
try { db.exec(`ALTER TABLE users ADD COLUMN username TEXT DEFAULT ''`); } catch (e) { /* 列已存在 */ }
try { db.exec(`ALTER TABLE users ADD COLUMN password_hash TEXT DEFAULT ''`); } catch (e) { /* 列已存在 */ }
// 注册用户名唯一（游客 username 为空串，不参与唯一约束）
db.exec(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(username) WHERE username <> ''`);

/** 判断是否需要播种（以 dishes 表为空为准） */
function needSeed() {
  const row = db.prepare('SELECT COUNT(*) AS n FROM dishes').get();
  return row.n === 0;
}

/** 播种演示数据（与 App 端 MockData 对齐） */
function seed() {
  const insCanteen = db.prepare(
    'INSERT INTO canteens (id, name, location, open_hours, floors, image) VALUES (?, ?, ?, ?, ?, ?)');
  const insStall = db.prepare(
    'INSERT INTO stalls (id, canteen_id, name, floor, cuisine, image) VALUES (?, ?, ?, ?, ?, ?)');
  const insDish = db.prepare(`
    INSERT INTO dishes (id, stall_id, canteen_id, name, price, image, tags, rating, review_count,
                        is_signature, sold_out, calories, is_vegetarian, allergens)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`);
  const insReview = db.prepare(`
    INSERT INTO reviews (id, dish_id, user_id, rating, taste, portion, value, content, images,
                         likes, is_anonymous, status, create_time)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`);

  // 食堂
  insCanteen.run('c1', '第一食堂', '校园东区', '06:30-21:00', 3, '');
  insCanteen.run('c2', '第二食堂', '校园西区', '06:30-21:00', 2, '');
  insCanteen.run('c3', '清真食堂', '校园北区', '06:30-20:00', 1, '');

  // 档口
  insStall.run('s1', 'c1', '川菜窗口', 2, '川菜', '');
  insStall.run('s2', 'c1', '面食窗口', 1, '面食', '');
  insStall.run('s3', 'c1', '盖浇饭窗口', 2, '快餐', '');
  insStall.run('s4', 'c2', '川菜窗口', 2, '川菜', '');
  insStall.run('s5', 'c2', '面食窗口', 1, '面食', '');
  insStall.run('s6', 'c3', '清真窗口', 1, '清真', '');

  // 菜品（image 用 rawfile 本地资源名，与 App 内置图片一致）
  insDish.run('d1', 's1', 'c1', '宫保鸡丁', 12.5, 'dish_1.png', '["招牌","辣","荤"]', 4.6, 128, 1, 0, 520, 0, '["花生"]');
  insDish.run('d2', 's1', 'c1', '麻婆豆腐', 9.0, 'dish_2.png', '["辣","素"]', 4.3, 86, 0, 0, 380, 1, '[]');
  insDish.run('d3', 's2', 'c1', '兰州牛肉面', 15.0, 'dish_3.png', '["招牌","清真"]', 4.8, 256, 1, 0, 620, 0, '["麸质"]');
  insDish.run('d4', 's3', 'c1', '番茄炒蛋盖饭', 11.0, 'dish_4.png', '["家常"]', 4.1, 64, 0, 1, 560, 0, '[]');
  insDish.run('d5', 's4', 'c2', '回锅肉', 14.0, 'dish_5.png', '["荤","辣"]', 4.5, 102, 1, 0, 600, 0, '[]');
  insDish.run('d6', 's5', 'c2', '阳春面', 8.0, 'dish_6.png', '["素","清淡"]', 4.0, 48, 0, 0, 420, 1, '["麸质"]');

  // 评价（d1 的 17 条 + d3 的 r3，与 MockData 一致）
  const rs = [
    ['r1', 'd1', 'u1', 5, 5, 4, 5, '味道很正宗，花生酥脆，鸡肉嫩滑，性价比高！', 12, 0, '2026-09-23T12:30:00'],
    ['r2', 'd1', 'u2', 4, 4, 5, 4, '分量很足，口味偏辣，配米饭很合适。', 5, 1, '2026-09-22T18:10:00'],
    ['r4', 'd1', 'u4', 5, 5, 5, 5, '每周必点！辣度刚好，下饭神器。', 21, 0, '2026-09-21T12:05:00'],
    ['r5', 'd1', 'u5', 3, 3, 4, 3, '今天花生有点少，味道还行吧。', 3, 1, '2026-09-20T18:40:00'],
    ['r6', 'd1', 'u6', 4, 4, 4, 4, '训练完来一份，很顶饱，就是排队有点久。', 9, 0, '2026-09-19T12:20:00'],
    ['r7', 'd1', 'u7', 2, 2, 3, 2, '感觉不如上学期好吃，鸡肉有点柴。', 1, 0, '2026-09-18T18:30:00'],
    ['r8', 'd1', 'u8', 4, 4, 5, 3, '性价比可以，能再多点鸡肉就更好了。', 6, 1, '2026-09-17T12:15:00'],
    ['r9', 'd1', 'u9', 5, 5, 5, 4, '阿姨手不抖，花生米超香，回购第三次了！', 15, 0, '2026-09-16T11:50:00'],
    ['r10', 'd1', 'u10', 3, 3, 3, 4, '中规中矩，适合不知道吃什么的时候选。', 2, 0, '2026-09-15T18:25:00'],
    ['r11', 'd1', 'u11', 4, 4, 4, 4, '复习间隙来一份，熟悉的味道，稳定发挥。', 11, 0, '2026-09-14T12:10:00'],
    ['r12', 'd1', 'u12', 5, 5, 5, 5, '新品辣度升级版绝了，越吃越上头！', 8, 1, '2026-09-13T18:20:00'],
    ['r13', 'd1', 'u13', 3, 3, 4, 3, '第一次吃，稍微有点咸，总体还可以。', 4, 0, '2026-09-12T12:00:00'],
    ['r14', 'd1', 'u14', 4, 4, 5, 3, '打完球吃这个很舒服，建议加个卤蛋。', 7, 0, '2026-09-11T18:35:00'],
    ['r15', 'd1', 'u15', 2, 2, 2, 3, '那天可能是快打烊了，菜是凉的，体验不好。', 2, 1, '2026-09-10T12:25:00'],
    ['r16', 'd1', 'u16', 5, 5, 5, 5, '吃了大半年，从没失望过，陪着我和研友上岸！', 18, 0, '2026-09-09T11:55:00'],
    ['r17', 'd1', 'u17', 4, 4, 4, 4, '帮全寝室带过好几次，出餐快，不易洒。', 5, 0, '2026-09-08T18:15:00'],
    ['r18', 'd1', 'u18', 3, 3, 3, 3, '中规中矩的家常味，胜在分量足。', 3, 0, '2026-09-07T12:40:00'],
    ['r3', 'd3', 'u3', 5, 5, 5, 5, '牛肉给得很足，汤头浓郁，强烈推荐！', 28, 0, '2026-09-24T11:45:00']
  ];
  for (const r of rs) {
    insReview.run(r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], '[]', r[8], r[9], 'approved', r[10]);
  }

  // 默认管理员 admin / admin123
  const hasAdmin = db.prepare('SELECT COUNT(*) AS n FROM admins').get().n > 0;
  if (!hasAdmin) {
    db.prepare('INSERT INTO admins (username, password_hash) VALUES (?, ?)')
      .run('admin', bcrypt.hashSync('admin123', 10));
  }

  // 种子评价对应的用户（用于联表取昵称）
  const users = [
    ['u1', '小张'], ['u2', '匿名同学'], ['u3', '面食爱好者'], ['u4', '干饭第一名'],
    ['u5', '匿名同学'], ['u6', '体育部的浩哥'], ['u7', '爱吃辣的小王'], ['u8', '匿名同学'],
    ['u9', '奶茶续命中'], ['u10', '深夜学习人'], ['u11', '图书馆常驻民'], ['u12', '匿名同学'],
    ['u13', '大一萌新'], ['u14', '篮球场常客'], ['u15', '匿名同学'], ['u16', '考研上岸人'],
    ['u17', '寝室长本长'], ['u18', '干饭小分队']
  ];
  const insUser = db.prepare('INSERT INTO users (id, nickname, avatar) VALUES (?, ?, ?)');
  for (const u of users) insUser.run(u[0], u[1], '');
}

if (needSeed()) {
  seed();
  console.log('[db] 种子数据已写入', DB_PATH);
}

module.exports = db;
