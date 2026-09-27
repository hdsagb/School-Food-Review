/**
 * 鉴权中间件
 * - guestAuth：App 游客登录态（Authorization: Bearer <user-id>）
 * - adminAuth：管理端登录态（Authorization: Bearer <session-token>）
 */
const crypto = require('crypto');
const db = require('./db');

/** 从请求头解析 Bearer Token */
function parseBearer(req) {
  const header = req.headers['authorization'] || '';
  if (header.startsWith('Bearer ')) return header.slice(7).trim();
  return null;
}

/** 生成随机 token */
function genToken() {
  return crypto.randomBytes(16).toString('hex');
}

/** 游客用户鉴权：请求必须携带有效 token */
function guestAuth(req, res, next) {
  const token = parseBearer(req);
  if (!token) {
    return res.status(401).json({ code: 1, message: '未登录' });
  }
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(token);
  if (!user) {
    return res.status(401).json({ code: 1, message: '登录已失效' });
  }
  req.user = user;
  req.userToken = token;
  next();
}

/** 管理员鉴权 */
function adminAuth(req, res, next) {
  const token = parseBearer(req);
  if (!token) {
    return res.status(401).json({ code: 1, message: '未登录' });
  }
  const session = db.prepare('SELECT * FROM admin_sessions WHERE token = ?').get(token);
  if (!session) {
    return res.status(401).json({ code: 1, message: '登录已失效' });
  }
  req.admin = db.prepare('SELECT * FROM admins WHERE id = ?').get(session.admin_id);
  next();
}

/** 任一身份鉴权（游客 或 管理员均可） */
function authAny(req, res, next) {
  const token = parseBearer(req);
  if (!token) return res.status(401).json({ code: 1, message: '未登录' });
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(token);
  if (user) { req.user = user; return next(); }
  const session = db.prepare('SELECT * FROM admin_sessions WHERE token = ?').get(token);
  if (session) {
    req.admin = db.prepare('SELECT * FROM admins WHERE id = ?').get(session.admin_id);
    return next();
  }
  return res.status(401).json({ code: 1, message: '登录已失效' });
}

module.exports = { parseBearer, genToken, guestAuth, adminAuth, authAny };
