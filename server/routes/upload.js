/**
 * 图片上传接口（评价图片 / 菜品图片）
 * POST /api/upload  字段名 file，返回 { url }
 */
const express = require('express');
const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const { authAny } = require('../auth');

const router = express.Router();

const UPLOAD_DIR = path.join(__dirname, '..', 'uploads');
const storage = multer.diskStorage({
  destination: UPLOAD_DIR,
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase() || '.png';
    cb(null, Date.now() + '-' + crypto.randomBytes(4).toString('hex') + ext);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (/^image\//.test(file.mimetype)) cb(null, true);
    else cb(new Error('仅支持图片文件'));
  }
});

// 游客写评价与管理端管理菜品均需登录后才能上传
router.post('/', authAny, upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ code: 1, message: '未收到文件' });
  const host = `${req.protocol}://${req.get('host')}`;
  res.json({ code: 0, message: 'ok', data: { url: `${host}/uploads/${req.file.filename}` } });
});

module.exports = router;
