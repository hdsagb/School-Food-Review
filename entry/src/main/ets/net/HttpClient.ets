import { http } from '@kit.NetworkKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { AppConfig } from '../config/AppConfig';
import { PreferencesUtil } from '../utils/PreferencesUtil';

export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE'
}

export interface ApiResult<T> {
  code: number;
  message: string;
  data: T;
}

/** 图片上传响应 */
export interface UploadResult {
  url: string;
}

export interface RequestOptions {
  url: string;
  method: HttpMethod;
  params?: Record<string, string>;
  body?: Object;
  headers?: Record<string, string>;
}

/**
 * 统一 HTTP 客户端封装
 * - 自动拼接 baseUrl
 * - 自动注入 Token（游客 uuid）
 * - 统一错误处理
 */
export class HttpClient {
  private static instance: HttpClient;

  private constructor() {}

  static getInstance(): HttpClient {
    if (!HttpClient.instance) {
      HttpClient.instance = new HttpClient();
    }
    return HttpClient.instance;
  }

  /** 游客 Token */
  private token: string = '';

  setToken(token: string): void {
    this.token = token;
  }

  /**
   * 发起请求
   * @param options 请求选项
   * @returns 解析后的业务数据
   */
  async request<T>(options: RequestOptions): Promise<T> {
    if (!this.token) {
      this.token = await PreferencesUtil.getString(AppConfig.PREF_KEY_TOKEN);
    }
    const url = this.buildUrl(options.url, options.params);
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (options.headers) {
      const keys: string[] = Object.keys(options.headers);
      for (const k of keys) {
        headers[k] = options.headers[k];
      }
    }
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: this.mapMethod(options.method),
        header: headers,
        extraData: options.body ? JSON.stringify(options.body) : undefined,
        connectTimeout: AppConfig.HTTP_TIMEOUT,
        readTimeout: AppConfig.HTTP_TIMEOUT
      });

      if (response.responseCode >= 200 && response.responseCode < 300) {
        await this.captureToken(response);
        const body = JSON.parse(response.result as string) as ApiResult<T>;
        if (body.code === 0) {
          return body.data;
        }
        throw new Error(body.message || '业务异常');
      }
      // 非 2xx 也优先取响应体里的 message（如超限 429、未登录 401），取不到才退化为状态码
      let msg: string = `HTTP ${response.responseCode}`;
      try {
        const errBody = JSON.parse(response.result as string) as ApiResult<T>;
        if (errBody && errBody.message) {
          msg = errBody.message;
        }
      } catch (e) {
        // 响应体不是 JSON 时沿用状态码
      }
      throw new Error(msg);
    } catch (err) {
      throw (err as Error);
    } finally {
      httpRequest.destroy();
    }
  }

  /** GET 便捷方法 */
  get<T>(url: string, params?: Record<string, string>): Promise<T> {
    return this.request<T>({ url, method: HttpMethod.GET, params });
  }

  /** POST 便捷方法 */
  post<T>(url: string, body?: Object): Promise<T> {
    return this.request<T>({ url, method: HttpMethod.POST, body });
  }

  /**
   * 上传图片（multipart/form-data），返回可访问的图片 URL
   * @param path 本地文件路径（photoUri）
   */
  async uploadImage(path: string, fieldName: string = 'file'): Promise<string> {
    if (!this.token) {
      this.token = await PreferencesUtil.getString(AppConfig.PREF_KEY_TOKEN);
    }
    const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    const stat = fs.statSync(path);
    const buf = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buf);
    fs.closeSync(file);

    const boundary = `----Campus${Date.now().toString(16)}`;
    const fileName = this.extractFileName(path);
    const mime = this.guessMime(fileName);
    const encoder = new util.TextEncoder();
    const head = encoder.encode(
      `--${boundary}\r\nContent-Disposition: form-data; name="${fieldName}"; filename="${fileName}"\r\nContent-Type: ${mime}\r\n\r\n`);
    const tail = encoder.encode(`\r\n--${boundary}--\r\n`);
    const merged = new Uint8Array(head.byteLength + buf.byteLength + tail.byteLength);
    merged.set(head, 0);
    merged.set(new Uint8Array(buf), head.byteLength);
    merged.set(tail, head.byteLength + buf.byteLength);

    const url = `${AppConfig.API_BASE_URL}/upload`;
    const headers: Record<string, string> = { 'Content-Type': `multipart/form-data; boundary=${boundary}` };
    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: merged.buffer,
        connectTimeout: AppConfig.HTTP_TIMEOUT,
        readTimeout: AppConfig.HTTP_TIMEOUT
      });
      await this.captureToken(response);
      if (response.responseCode >= 200 && response.responseCode < 300) {
        const body = JSON.parse(response.result as string) as ApiResult<UploadResult>;
        if (body.code === 0) {
          return body.data.url;
        }
        throw new Error(body.message || '上传失败');
      }
      throw new Error(`HTTP ${response.responseCode}`);
    } finally {
      httpRequest.destroy();
    }
  }

  /** 从响应头捕获后端下发的 X-Auth-Token 并持久化 */
  private async captureToken(response: http.HttpResponse): Promise<void> {
    const headerObj = response.header as Record<string, Object>;
    if (!headerObj) return;
    const keys: string[] = Object.keys(headerObj);
    for (const k of keys) {
      if (k.toLowerCase() === 'x-auth-token') {
        const value = String(headerObj[k]);
        if (value && value !== this.token) {
          this.token = value;
          await PreferencesUtil.putString(AppConfig.PREF_KEY_TOKEN, value);
        }
        break;
      }
    }
  }

  private extractFileName(path: string): string {
    const idx = path.lastIndexOf('/');
    const name = idx >= 0 ? path.substring(idx + 1) : path;
    return name || 'photo.jpg';
  }

  private guessMime(fileName: string): string {
    const lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'application/octet-stream';
  }

  /** 拼接 URL 与查询参数 */
  private buildUrl(path: string, params?: Record<string, string>): string {
    let url = path.startsWith('http') ? path : `${AppConfig.API_BASE_URL}${path}`;
    if (params) {
      const keys: string[] = Object.keys(params);
      if (keys.length > 0) {
        const parts: string[] = [];
        for (const k of keys) {
          parts.push(`${encodeURIComponent(k)}=${encodeURIComponent(params[k])}`);
        }
        const query = parts.join('&');
        url += url.includes('?') ? `&${query}` : `?${query}`;
      }
    }
    return url;
  }

  /** 映射 HTTP 方法 */
  private mapMethod(method: HttpMethod): http.RequestMethod {
    switch (method) {
      case HttpMethod.GET: return http.RequestMethod.GET;
      case HttpMethod.POST: return http.RequestMethod.POST;
      case HttpMethod.PUT: return http.RequestMethod.PUT;
      case HttpMethod.DELETE: return http.RequestMethod.DELETE;
      default: return http.RequestMethod.GET;
    }
  }
}
