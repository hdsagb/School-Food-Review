import { preferences } from '@kit.ArkData';
import { AppConfig } from '../config/AppConfig';
import { User } from '../model/User';

/**
 * 轻量级本地存储工具
 * 用于：本地用户信息、收藏列表、菜单缓存
 */
export class PreferencesUtil {
  private static store: preferences.Preferences | null = null;

  /** 初始化（在 Ability 启动时调用，Previewer 沙箱中可能失败，已容错） */
  static async init(context: Context): Promise<void> {
    try {
      PreferencesUtil.store = await preferences.getPreferences(context, 'campus_today_prefs');
    } catch (e) {
      console.warn('PreferencesUtil.init failed (maybe in previewer): ' + (e as Error).message);
    }
  }

  /** 读取字符串 */
  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!PreferencesUtil.store) return defaultValue;
    try {
      return (await PreferencesUtil.store.get(key, defaultValue)) as string;
    } catch (e) {
      return defaultValue;
    }
  }

  /** 写入字符串 */
  static async putString(key: string, value: string): Promise<void> {
    if (!PreferencesUtil.store) return;
    try {
      await PreferencesUtil.store.put(key, value);
      await PreferencesUtil.store.flush();
    } catch (e) {
      console.warn('PreferencesUtil.putString failed: ' + (e as Error).message);
    }
  }

  /** 读取并反序列化为对象 */
  static async getObject<T>(key: string): Promise<T | null> {
    const raw = await PreferencesUtil.getString(key);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as T;
    } catch (e) {
      return null;
    }
  }

  /** 序列化对象并写入 */
  static async putObject(key: string, value: Object): Promise<void> {
    await PreferencesUtil.putString(key, JSON.stringify(value));
  }

  // ============ 业务快捷方法 ============

  /** 读取本地用户 */
  static async getUser(): Promise<User | null> {
    return PreferencesUtil.getObject<User>(AppConfig.PREF_KEY_USER);
  }

  /** 保存本地用户 */
  static async saveUser(user: User): Promise<void> {
    await PreferencesUtil.putObject(AppConfig.PREF_KEY_USER, user);
  }

  /** 读取收藏列表 */
  static async getFavorites(): Promise<string[]> {
    return (await PreferencesUtil.getObject<string[]>(AppConfig.PREF_KEY_FAVORITES)) ?? [];
  }

  /** 保存收藏列表 */
  static async saveFavorites(ids: string[]): Promise<void> {
    await PreferencesUtil.putObject(AppConfig.PREF_KEY_FAVORITES, ids);
  }

  /** 读取搜索历史 */
  static async getSearchHistory(): Promise<string[]> {
    return (await PreferencesUtil.getObject<string[]>(AppConfig.PREF_KEY_SEARCH_HISTORY)) ?? [];
  }

  /** 保存搜索历史 */
  static async saveSearchHistory(keywords: string[]): Promise<void> {
    await PreferencesUtil.putObject(AppConfig.PREF_KEY_SEARCH_HISTORY, keywords);
  }

  /** 读取已点赞评价 id 列表 */
  static async getLikedReviews(): Promise<string[]> {
    return (await PreferencesUtil.getObject<string[]>(AppConfig.PREF_KEY_LIKED_REVIEWS)) ?? [];
  }

  /** 保存已点赞评价 id 列表 */
  static async saveLikedReviews(ids: string[]): Promise<void> {
    await PreferencesUtil.putObject(AppConfig.PREF_KEY_LIKED_REVIEWS, ids);
  }

  /** 读取深色模式开关 */
  static async getDarkMode(): Promise<boolean> {
    return await PreferencesUtil.getString(AppConfig.PREF_KEY_DARK_MODE, 'false') === 'true';
  }

  /** 保存深色模式开关 */
  static async saveDarkMode(enabled: boolean): Promise<void> {
    await PreferencesUtil.putString(AppConfig.PREF_KEY_DARK_MODE, enabled ? 'true' : 'false');
  }

  /** 删除指定 key */
  static async remove(key: string): Promise<void> {
    if (!PreferencesUtil.store) return;
    try {
      await PreferencesUtil.store.delete(key);
      await PreferencesUtil.store.flush();
    } catch (e) {
      console.warn('PreferencesUtil.remove failed: ' + (e as Error).message);
    }
  }
}
