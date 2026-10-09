/**
 * 应用全局配置
 */
export class AppConfig {
  /**
   * 后端 API 基础地址
   * - 测试环境：阿里云轻量服务器公网 IP + 3000 端口（需在控制台防火墙放行 3000）
   * - 本地联调：改用电脑局域网 IP（ipconfig 查询，如 http://192.168.1.4:3000/api）
   * - 注意：末尾必须保留 /api 路径前缀
   */
  static readonly API_BASE_URL: string = 'http://47.117.188.9:3000/api';

  /** 是否使用 Mock 数据（接入后端后为 false） */
  static readonly USE_MOCK: boolean = false;

  /** 网络超时时间（毫秒） */
  static readonly HTTP_TIMEOUT: number = 10000;

  /** 菜单缓存有效期（毫秒），5 分钟 */
  static readonly MENU_CACHE_DURATION: number = 5 * 60 * 1000;

  /** 评价图片最大数量 */
  static readonly MAX_REVIEW_IMAGES: number = 9;

  /** 评价文字最小字数 */
  static readonly MIN_REVIEW_LENGTH: number = 10;

  /** 评价文字最大字数 */
  static readonly MAX_REVIEW_LENGTH: number = 500;

  /** 每页加载评价数量 */
  static readonly REVIEW_PAGE_SIZE: number = 8;

  /** 搜索历史最大条数 */
  static readonly SEARCH_HISTORY_MAX: number = 8;

  /** 本地存储键名 */
  static readonly PREF_KEY_USER = 'local_user';
  static readonly PREF_KEY_FAVORITES = 'favorites';
  static readonly PREF_KEY_MENU_CACHE = 'menu_cache';
  static readonly PREF_KEY_SEARCH_HISTORY = 'search_history';
  static readonly PREF_KEY_LIKED_REVIEWS = 'liked_reviews';
  static readonly PREF_KEY_MY_REVIEWS = 'my_reviews';
  static readonly PREF_KEY_DARK_MODE = 'dark_mode';
  static readonly PREF_KEY_TOKEN = 'auth_token';
  static readonly PREF_KEY_PRIVACY_AGREED = 'privacy_agreed';
}
