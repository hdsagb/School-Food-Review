/**
 * 工具函数集合
 */

/**
 * 根据当前小时判断餐次
 * - 5-10 早餐
 * - 10-14 午餐
 * - 其他晚餐
 */
export function getCurrentMealType(): number {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 10) return 0; // 早餐
  if (hour >= 10 && hour < 14) return 1; // 午餐
  return 2; // 晚餐
}

/**
 * 生成简易 UUID（用于本地游客 ID）
 */
export function generateUuid(): string {
  const s4 = (): string => {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
  };
  return `${s4()}${s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;
}

/**
 * 格式化时间戳为相对时间文案
 * @param iso ISO 字符串
 */
export function formatRelativeTime(iso: string): string {
  const date = new Date(iso);
  const diff = Date.now() - date.getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return '刚刚';
  if (minutes < 60) return `${minutes}分钟前`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}小时前`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}天前`;
  return `${date.getMonth() + 1}-${date.getDate()}`;
}

/**
 * 星级评分转文案
 */
export function ratingToText(rating: number): string {
  if (rating >= 4.5) return '非常好';
  if (rating >= 3.5) return '还不错';
  if (rating >= 2.5) return '一般';
  if (rating >= 1.5) return '较差';
  return '很差';
}

/**
 * 生成 1-5 星数组（用于渲染星星）
 */
export function ratingToStars(rating: number): number[] {
  const full = Math.floor(rating);
  const hasHalf = rating - full >= 0.5;
  const arr: number[] = new Array(5).fill(0);
  for (let i = 0; i < full; i++) arr[i] = 2;
  if (hasHalf) arr[full] = 1;
  return arr;
}

/**
 * 菜品图片数据源转换
 * - 空字符串 → 默认占位图
 * - http/https 开头 → 网络图片
 * - 其他 → rawfile 本地文件名（如 'dish_1.png'）
 */
export function dishImageSource(image: string): ResourceStr {
  if (!image) return $r('app.media.startIcon');
  if (image.startsWith('http')) return image;
  return $rawfile(image);
}
