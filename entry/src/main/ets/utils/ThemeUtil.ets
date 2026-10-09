/**
 * 主题配色工具（深色/浅色条件配色）
 *
 * 背景：Previewer 沙箱中 setColorMode 与 dark 资源目录均不生效，
 * 因此页面颜色统一按 @StorageLink('darkMode') 传入的 isDark 参数，
 * 深色返回字面量十六进制，浅色返回 $r('app.color.*') 资源引用。
 * 真机运行时浅色分支仍走资源目录，行为与当前保持一致。
 */
export class ThemeUtil {
  /** 页面背景 */
  static pageBg(isDark: boolean): ResourceStr {
    return isDark ? '#0F1A14' : $r('app.color.bg_page');
  }

  /** 卡片背景 */
  static cardBg(isDark: boolean): ResourceStr {
    return isDark ? '#1A2820' : $r('app.color.bg_card');
  }

  /** 主文字 */
  static textPrimary(isDark: boolean): ResourceStr {
    return isDark ? '#E4F0E9' : $r('app.color.text_primary');
  }

  /** 次级文字 */
  static textSecondary(isDark: boolean): ResourceStr {
    return isDark ? '#A9BFB3' : $r('app.color.text_secondary');
  }

  /** 弱提示文字 */
  static textHint(isDark: boolean): ResourceStr {
    return isDark ? '#71877B' : $r('app.color.text_hint');
  }

  /** 价格文字 */
  static textPrice(isDark: boolean): ResourceStr {
    return isDark ? '#FF8A73' : $r('app.color.text_price');
  }

  /** 品牌主色 */
  static brandPrimary(isDark: boolean): ResourceStr {
    return isDark ? '#2BD9A0' : $r('app.color.brand_primary');
  }

  /** 品牌深色 */
  static brandPrimaryDark(isDark: boolean): ResourceStr {
    return isDark ? '#17BE8A' : $r('app.color.brand_primary_dark');
  }

  /** 品牌强调（标签/已点赞等） */
  static brandDeep(isDark: boolean): ResourceStr {
    return isDark ? '#7BE8C0' : $r('app.color.brand_deep');
  }

  /** 分割线 */
  static divider(isDark: boolean): ResourceStr {
    return isDark ? '#24352C' : $r('app.color.divider');
  }

  /** 常规标签底色 */
  static tagBg(isDark: boolean): ResourceStr {
    return isDark ? '#1F3A2D' : $r('app.color.tag_bg');
  }

  /** 常规标签文字 */
  static tagText(isDark: boolean): ResourceStr {
    return isDark ? '#6FE3AE' : $r('app.color.tag_text');
  }

  /** 暖色标签底色（辣/荤） */
  static tagWarmBg(isDark: boolean): ResourceStr {
    return isDark ? '#3A2A1E' : $r('app.color.tag_warm_bg');
  }

  /** 暖色标签文字（辣/荤） */
  static tagWarmText(isDark: boolean): ResourceStr {
    return isDark ? '#FFA06B' : $r('app.color.tag_warm_text');
  }

  /** 招牌金标底色 */
  static accentGoldBg(isDark: boolean): ResourceStr {
    return isDark ? '#3A301B' : $r('app.color.accent_gold_bg');
  }

  /** 招牌金标文字 */
  static accentGoldText(isDark: boolean): ResourceStr {
    return isDark ? '#FFC94D' : $r('app.color.accent_gold_text');
  }

  /** 售罄角标文字 */
  static soldOutText(isDark: boolean): ResourceStr {
    return isDark ? '#8FA69B' : $r('app.color.sold_out_text');
  }

  /** 审核未通过徽标底色 */
  static rejectBg(isDark: boolean): ResourceStr {
    return isDark ? '#3A2220' : '#FBECEC';
  }

  /** 审核未通过徽标文字 */
  static rejectText(isDark: boolean): ResourceStr {
    return isDark ? '#FF9B8A' : '#C0392B';
  }

  /** 空星颜色 */
  static starInactive(isDark: boolean): ResourceStr {
    return isDark ? '#3A4A41' : $r('app.color.star_inactive');
  }

  /** 骨架屏占位色 */
  static skeletonBg(isDark: boolean): ResourceStr {
    return isDark ? '#223329' : $r('app.color.skeleton_bg');
  }
}
