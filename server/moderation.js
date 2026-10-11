/**
 * L1 自动审核规则引擎
 *
 * 定位：在「先审后发」前提下做机器初筛，只负责「自动驳回明显违规内容」，
 * 未命中任何规则的干净内容仍然进入 pending，由管理后台人工审核后才会公开。
 * 不提供自动通过（自动发布）。
 *
 * 规则（按优先级顺序求值，命中即返回）：
 *   1. banned_word  敏感词命中（词库由管理后台维护）
 *   2. ad_contact   广告 / 联系方式（手机号、微信、QQ、外部链接）
 *   3. flood        灌水无意义（内容过短、纯符号/表情、连续重复字符）
 *   4. duplicate    重复刷屏（同一账号短时间提交相同内容）
 *
 * 返回：{ reject: boolean, rule: string, reason: string }
 *   reject=false 时 rule/reason 为空串，调用方落库为 pending
 */
const db = require('./db');

/** 内容过短阈值：去空白后少于该字数视为灌水 */
const MIN_CONTENT_LEN = 3;
/** 重复刷屏检测窗口 */
const DUPLICATE_WINDOW_MS = 10 * 60 * 1000;
/** 重复刷屏最小长度：过短的大众化好评（如「好吃」）不参与查重，避免误伤 */
const DUPLICATE_MIN_LEN = 4;

/** 广告 / 联系方式特征 */
const AD_MOBILE = /(?<!\d)1[3-9]\d{9}(?!\d)/;
const AD_WECHAT = /微信|weixin|wechat|vx|v信|加我|加群|扫码|二维码/i;
const AD_QQ = /[Qq]{2}\s*[:：]?\s*\d{4,}|[Qq]{2}群/;
const AD_URL = /(https?:\/\/|www\.)/i;
const AD_DOMAIN = /\b[\w-]+\.(com|cn|net|org|top|xyz|vip|cc|me|io)\b/i;

/** 纯符号 / 纯表情（不含任何文字、字母、数字） */
const ONLY_SYMBOLS = /^[\p{P}\p{S}\s]+$/u;
/** 同一字符连续重复 6 次以上 */
const REPEAT_CHARS = /([\s\S])\1{5,}/u;

/** 归一化文本用于查重：去空白 + 转小写 */
function normalize(text) {
  return String(text || '').replace(/\s+/g, '').toLowerCase();
}

/** 命中敏感词则返回第一个命中的词，未命中返回空串 */
function firstBannedWord(text) {
  const src = String(text || '');
  if (!src) return '';
  const rows = db.prepare('SELECT word FROM banned_words').all();
  for (const r of rows) {
    if (r.word && src.includes(r.word)) return r.word;
  }
  return '';
}

/** 命中广告 / 联系方式则返回特征名，未命中返回空串 */
function matchAd(text) {
  const src = String(text || '');
  if (AD_MOBILE.test(src)) return '手机号';
  if (AD_WECHAT.test(src)) return '微信';
  if (AD_QQ.test(src)) return 'QQ';
  if (AD_URL.test(src) || AD_DOMAIN.test(src)) return '外部链接';
  return '';
}

/** 命中灌水特征则返回驳回理由，未命中返回空串 */
function matchFlood(bare) {
  if (ONLY_SYMBOLS.test(bare)) return '评价内容不能只有符号或表情，请补充真实用餐感受';
  if (REPEAT_CHARS.test(bare)) return '评价内容存在大量重复字符，请补充真实用餐感受';
  return '';
}

/** 同一账号在时间窗内是否已提交过相同内容 */
function isDuplicate(userId, content) {
  const norm = normalize(content);
  if (norm.length < DUPLICATE_MIN_LEN) return false;
  const since = new Date(Date.now() - DUPLICATE_WINDOW_MS).toISOString();
  const rows = db.prepare(
    'SELECT content FROM reviews WHERE user_id = ? AND create_time >= ?'
  ).all(userId, since);
  for (const r of rows) {
    if (normalize(r.content) === norm) return true;
  }
  return false;
}

/**
 * 对一条待提交的评价执行 L1 规则审核
 * @param {Object} input { userId, dishId, content }
 * @returns {{reject: boolean, rule: string, reason: string}}
 */
function auditReview(input) {
  const userId = input.userId;
  const content = String((input && input.content) || '');
  const bare = content.trim();

  const word = firstBannedWord(content);
  if (word) {
    return { reject: true, rule: 'banned_word', reason: `包含敏感词「${word}」` };
  }

  const ad = matchAd(content);
  if (ad) {
    return { reject: true, rule: 'ad_contact', reason: `疑似广告或联系方式（${ad}），评价中请勿留联系方式` };
  }

  if (bare.length < MIN_CONTENT_LEN) {
    return { reject: true, rule: 'flood', reason: '评价内容过短，请补充真实用餐感受' };
  }

  const flood = matchFlood(bare);
  if (flood) {
    return { reject: true, rule: 'flood', reason: flood };
  }

  if (isDuplicate(userId, content)) {
    return { reject: true, rule: 'duplicate', reason: '请勿在短时间内重复提交相同内容' };
  }

  return { reject: false, rule: '', reason: '' };
}

module.exports = { auditReview };