/**
 * 华为账号（Account Kit）服务端校验
 * 客户端拿到 authorizationCode 后，服务端用 code 换取 id_token，取 sub 作为账号唯一标识。
 * 凭据由 AGC「OAuth 2.0 客户端 ID（凭据）」提供，通过环境变量注入：
 *   HUAWEI_CLIENT_ID / HUAWEI_CLIENT_SECRET
 */
const TOKEN_URL = 'https://oauth-login.cloud.huawei.com/oauth2/v3/token';

/** 解析 JWT 载荷（id_token 由华为 token 接口经 HTTPS 直接返回，无需再验签） */
function decodeJwtPayload(jwt) {
  const parts = String(jwt).split('.');
  if (parts.length < 2) return {};
  try {
    return JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
  } catch (e) {
    return {};
  }
}

/** 用授权码换取华为账号标识；失败时抛出带 code 的 Error */
async function exchangeCode(code) {
  const clientId = process.env.HUAWEI_CLIENT_ID || '';
  const clientSecret = process.env.HUAWEI_CLIENT_SECRET || '';
  if (!clientId || !clientSecret) {
    const e = new Error('服务端未配置华为账号登录凭据，请联系管理员');
    e.code = 'NOT_CONFIGURED';
    throw e;
  }

  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    client_id: clientId,
    client_secret: clientSecret
  });

  let resp;
  try {
    resp = await fetch(TOKEN_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
      signal: AbortSignal.timeout(10000)
    });
  } catch (e) {
    const err = new Error('连接华为账号服务器失败，请稍后重试');
    err.code = 'UPSTREAM';
    throw err;
  }

  const data = await resp.json().catch(() => ({}));
  if (!resp.ok || !data.id_token) {
    const err = new Error('华为账号校验失败，请重新登录');
    err.code = 'UPSTREAM';
    err.detail = data;
    throw err;
  }

  const payload = decodeJwtPayload(data.id_token);
  // sub：同一开发者账号下所有应用一致，可稳定标识用户
  if (!payload.sub) {
    const err = new Error('华为账号返回的标识无效，请重新登录');
    err.code = 'UPSTREAM';
    throw err;
  }
  return { uid: String(payload.sub) };
}

module.exports = { exchangeCode };
