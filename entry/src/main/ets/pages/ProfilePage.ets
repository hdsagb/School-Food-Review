import { User } from '../model/User';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { generateUuid } from '../utils/CommonUtil';
import { ThemeUtil } from '../utils/ThemeUtil';
import { Api } from '../net/Api';
import { ConfigurationConstant } from '@kit.AbilityKit';

@Component
export struct ProfilePage {
  private pathStack: NavPathStack = new NavPathStack();
  @State user: User | null = null;
  @State nickname: string = '';
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('myReviewCount') myReviewCount: number = 0;
  @StorageLink('favorites') favorites: string[] = [];

  async aboutToAppear(): Promise<void> {
    this.user = await PreferencesUtil.getUser();
    if (!this.user) {
      this.user = new User(
        generateUuid(),
        '同学' + Math.floor(Math.random() * 1000),
        '',
        []
      );
      await PreferencesUtil.saveUser(this.user);
    }
    this.nickname = this.user.nickname;
    this.darkMode = await PreferencesUtil.getDarkMode();
    this.refreshCounts();
  }

  /** 触发评价同步；计数/列表经 AppStorage 自动刷新 */
  private async refreshCounts(): Promise<void> {
    try {
      await Api.getMyReviews();
    } catch (e) {
      console.error('loadProfileCounts error: ' + (e as Error).message);
    }
  }

  build() {
    NavDestination() {
      Column({ space: 10 }) {
        Row() {
          Text('←')
            .fontSize(24)
            .padding(8)
            .onClick((): void => { this.pathStack.pop(); })
        Text($r('app.string.profile'))
          .fontSize($r('app.float.title_medium'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text('').width(40)
      }
      .width('100%')
      .height(48)

      Row({ space: 16 }) {
        Stack() {
          Circle({ width: 72, height: 72 })
            .fill(Color.Transparent)
            .stroke($r('app.color.brand_gradient_start'))
            .strokeWidth(2)
          Image(this.user?.avatar || $r('app.media.startIcon'))
            .width(60)
            .height(60)
            .borderRadius(30)
            .objectFit(ImageFit.Cover)
        }
        Column({ space: 4 }) {
          TextInput({ text: this.nickname })
            .width('100%')
            .fontSize($r('app.float.title_medium'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor(Color.Transparent)
            .padding(0)
            .onChange((v: string): void => { this.nickname = v; })
          Text('🌱 游客模式 · 仅本地保存')
            .fontSize($r('app.float.caption_text'))
            .fontColor(ThemeUtil.textHint(this.darkMode))
        }
        .layoutWeight(1)
        Text('保存')
          .fontSize($r('app.float.body_text'))
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeUtil.brandPrimaryDark(this.darkMode))
          .padding(8)
          .onClick((): void => { this.saveNickname(); })
      }
      .width('100%')
      .padding(16)
      .margin({ left: 12, right: 12 })
      .backgroundColor(ThemeUtil.cardBg(this.darkMode))
      .borderRadius($r('app.float.corner_card'))
      .shadow({ radius: 10, color: 'rgba(28,59,48,0.06)', offsetX: 0, offsetY: 3 })

      this.MenuItem('📝 我的评价', `${this.myReviewCount} 条`, (): void => { this.goMyReviews(); })
      this.MenuItem('⭐ 我的收藏', `${this.favorites.length} 道`, (): void => { this.goFavorites(); })
      this.MenuItem('🧹 清除缓存', '', (): void => { this.clearCache(); })
      this.DarkModeRow()
      this.MenuItem('📋 隐私声明', '', (): void => { this.goPrivacy(); })
      this.MenuItem('🌿 关于今日校园', 'v1.0.0', (): void => {})
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeUtil.pageBg(this.darkMode))
    }
    .hideTitleBar(true)
    .backgroundColor(ThemeUtil.pageBg(this.darkMode))
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
    })
    .onShown((): void => { this.refreshCounts(); })
  }

  @Builder MenuItem(label: string, value: string, onTap: () => void) {
    Row() {
      Text(label)
        .fontSize($r('app.float.body_text'))
        .fontColor(ThemeUtil.textPrimary(this.darkMode))
        .layoutWeight(1)
      Text(value)
        .fontSize($r('app.float.caption_text'))
        .fontColor(ThemeUtil.textHint(this.darkMode))
      Text('›')
        .fontSize(20)
        .fontColor(ThemeUtil.textHint(this.darkMode))
        .margin({ left: 4 })
    }
    .width('100%')
    .padding(16)
    .margin({ left: 12, right: 12 })
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
    .shadow({ radius: 8, color: 'rgba(28,59,48,0.05)', offsetX: 0, offsetY: 2 })
    .onClick(onTap)
  }

  @Builder DarkModeRow() {
    Row() {
      Text('🌗 深色模式')
        .fontSize($r('app.float.body_text'))
        .fontColor(ThemeUtil.textPrimary(this.darkMode))
        .layoutWeight(1)
      Text(this.darkMode ? '开' : '关')
        .fontSize($r('app.float.body_text'))
        .fontWeight(this.darkMode ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.darkMode ? ThemeUtil.brandPrimary(this.darkMode) : ThemeUtil.textHint(this.darkMode))
        .padding({ left: 14, right: 14, top: 6, bottom: 6 })
        .borderRadius(15)
        .backgroundColor(this.darkMode ? ThemeUtil.tagBg(this.darkMode) : Color.Transparent)
    }
    .width('100%')
    .padding(16)
    .margin({ left: 12, right: 12 })
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
    .shadow({ radius: 8, color: 'rgba(28,59,48,0.05)', offsetX: 0, offsetY: 2 })
    .onClick((): void => { this.applyDarkMode(!this.darkMode); })
  }

  private applyDarkMode(enabled: boolean): void {
    this.darkMode = enabled;
    AppStorage.setOrCreate<boolean>('darkMode', enabled);
    PreferencesUtil.saveDarkMode(enabled);
    const mode: ConfigurationConstant.ColorMode = enabled
      ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      : ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    const appCtx = this.getUIContext().getHostContext()?.getApplicationContext();
    if (appCtx) {
      appCtx.setColorMode(mode);
    }
  }

  private goPrivacy(): void {
    this.pathStack.pushPathByName('Privacy', '');
  }

  private goFavorites(): void {
    this.pathStack.pushPathByName('Favorites', '');
  }

  private goMyReviews(): void {
    this.pathStack.pushPathByName('MyReviews', '');
  }

  private async saveNickname(): Promise<void> {
    if (!this.user) return;
    this.user.nickname = this.nickname.trim() || this.user.nickname;
    await PreferencesUtil.saveUser(this.user);
  }

  private async clearCache(): Promise<void> {
    await PreferencesUtil.remove('menu_cache');
    this.pathStack.pop();
  }
}
