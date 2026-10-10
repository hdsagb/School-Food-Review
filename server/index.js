/**
 * 校园食评演示后端入口
 * 启动：node index.js  （默认端口 3000）
 */
const express = require('express');
const path = require('path');
const fs = require('fs');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

const UPLOAD_DIR = path.join(__dirname, 'uploads');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

app.use(express.json({ limit: '2mb' }));

// 上传文件静态访问
app.use('/uploads', express.static(UPLOAD_DIR));

// 业务路由
app.use('/api', require('./routes/client'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/upload', require('./routes/upload'));

// 管理端静态页
app.use(express.static(path.join(__dirname, 'public')));

// 统一错误兜底
app.use((err, req, res, next) => {
  console.error('[server]', err.message);
  res.status(500).json({ code: 1, message: err.message || '服务器内部错误' });
});

app.listen(PORT, () => {
  console.log(`[server] 校园食评演示后端已启动: http://localhost:${PORT}`);
  console.log(`[server] 管理端: http://localhost:${PORT}/`);
});

module.exports = app;
