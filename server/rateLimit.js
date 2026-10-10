/**
 * 极简内存限流中间件
 *
 * 单进程部署下够用；将来若扩到多进程/多实例，需换成 Redis 之类的共享计数。
 *
 * 关于按 IP 计数：当前 Node 直接监听 3000 端口，req.ip 是真实客户端 IP。
 * 将来若挪到 Nginx 后面，必须 app.set('trust proxy', ...)，否则所有请求会
 * 共用代理 IP 的计数桶，一限流就全站生效。
 *
 * 另外校园网普遍是全校共用一个 NAT 出口 IP，按 IP 的阈值必须放宽，
 * 否则一个学校的人会互相挤占额度；对登录这类可定位到账号的接口，
 * 用 keyOf 按账号计数更准，也不受 NAT 影响。
 */
const buckets = new Map();

/** 清理已过期计数桶，避免 Map 无限增长 */
function sweep(now) {
  for (const [key, rec] of buckets) {
    if (rec.resetAt <= now) buckets.delete(key);
  }
}

/**
 * @param {object} opt
 * @param {number} opt.windowMs  统计窗口（毫秒）
 * @param {number} opt.max       窗口内允许的最大次数
 * @param {string} opt.scope     计数命名空间，不同接口互不影响
 * @param {string} [opt.message] 超限时的提示语
 * @param {(req) => string} [opt.keyOf] 自定义计数主体，默认按 IP
 */
function rateLimit({ windowMs, max, scope, message, keyOf }) {
  return (req, res, next) => {
    const now = Date.now();
    // 攒到一定规模才整体清理，避免每个请求都遍历一遍
    if (buckets.size > 5000) sweep(now);

    const subject = keyOf ? keyOf(req) : (req.ip || '');
    // 取不到主体时不拦截，交给后面的鉴权去判断
    if (!subject) return next();

    const key = `${scope}:${subject}`;
    let rec = buckets.get(key);
    if (!rec || rec.resetAt <= now) {
      rec = { count: 0, resetAt: now + windowMs };
      buckets.set(key, rec);
    }
    rec.count += 1;

    if (rec.count > max) {
      const retryAfter = Math.max(1, Math.ceil((rec.resetAt - now) / 1000));
      res.setHeader('Retry-After', String(retryAfter));
      res.status(429).json({
        code: 429,
        message: message || `操作过于频繁，请 ${retryAfter} 秒后再试`
      });
      return;
    }
    next();
  };
}

module.exports = { rateLimit };