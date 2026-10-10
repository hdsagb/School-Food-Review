/**
 * SQLite 数据备份脚本
 *
 * 库运行在 WAL 模式下，直接复制 data.db 会漏掉还留在 data.db-wal 里的最新写入，
 * 拿到的可能是过期甚至无法打开的文件。这里用 VACUUM INTO 在单条语句内生成
 * 一致性快照：源库不被修改，也能与正在写入的服务端共存。
 *
 * 用法：node backup.js
 * 环境变量：
 *   BACKUP_DIR   备份目录，默认 server/backups
 *   BACKUP_KEEP  保留份数，默认 14
 */
const { DatabaseSync } = require('node:sqlite');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, 'data.db');
const BACKUP_DIR = process.env.BACKUP_DIR || path.join(__dirname, 'backups');
const KEEP = Math.max(1, Number(process.env.BACKUP_KEEP) || 14);

/** 本地时间 YYYYMMDD_HHMMSS，文件名按字典序排序即为时间顺序 */
function stamp(d) {
  const p = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}_${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

function makeBackup() {
  if (!fs.existsSync(DB_PATH)) throw new Error(`数据库不存在: ${DB_PATH}`);
  fs.mkdirSync(BACKUP_DIR, { recursive: true });

  const target = path.join(BACKUP_DIR, `data_${stamp(new Date())}.db`);
  if (fs.existsSync(target)) throw new Error(`备份文件已存在: ${target}`);

  const db = new DatabaseSync(DB_PATH);
  try {
    // 服务端可能正在写入，等待锁而不是直接失败
    db.exec('PRAGMA busy_timeout = 10000');
    // 路径内的单引号需转义，否则会拼出非法 SQL
    db.exec(`VACUUM INTO '${target.replace(/'/g, "''")}'`);
  } finally {
    db.close();
  }

  // 校验产物：必须能打开、结构完整、关键表行数可读
  const check = new DatabaseSync(target, { readOnly: true });
  let integrity;
  let counts;
  try {
    integrity = check.prepare('PRAGMA integrity_check').get().integrity_check;
    counts = check.prepare(
      `SELECT (SELECT COUNT(*) FROM canteens) AS canteens,
              (SELECT COUNT(*) FROM dishes)   AS dishes,
              (SELECT COUNT(*) FROM reviews)  AS reviews,
              (SELECT COUNT(*) FROM users)    AS users`
    ).get();
  } finally {
    check.close();
  }
  if (integrity !== 'ok') throw new Error(`备份校验失败 integrity_check=${integrity}`);

  const sizeKb = (fs.statSync(target).size / 1024).toFixed(1);
  console.log(
    `[backup] ${new Date().toISOString()} 生成 ${target} (${sizeKb} KB) integrity=ok ` +
    `canteens=${counts.canteens} dishes=${counts.dishes} reviews=${counts.reviews} users=${counts.users}`
  );

  // 保留策略：按文件名（即时间）倒序，只留最近的 KEEP 份
  const files = fs.readdirSync(BACKUP_DIR)
    .filter((f) => /^data_\d{8}_\d{6}\.db$/.test(f))
    .sort()
    .reverse();
  const stale = files.slice(KEEP);
  for (const f of stale) {
    fs.unlinkSync(path.join(BACKUP_DIR, f));
    console.log(`[backup] 清理旧备份 ${f}`);
  }
  console.log(`[backup] 当前保留 ${files.length - stale.length} 份（上限 ${KEEP}）`);
}

try {
  makeBackup();
} catch (e) {
  console.error(`[backup] 失败: ${e.message}`);
  process.exit(1);
}