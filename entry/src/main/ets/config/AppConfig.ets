/**
 * 应用全局配置
 */
export class AppConfig {
  /**
   * 后端 API 基础地址
   * - 模拟器访问宿主机：http://10.0.2.2:3000/api
   * - 真机（同一局域网）需改为电脑局域网 IP，如 http://192.168.x.x:3000/api
   */
  static readonly API_BASE_URL: string = 'http://10.0.2.2:3000/api';

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
}
