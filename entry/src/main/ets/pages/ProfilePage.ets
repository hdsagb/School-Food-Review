import { User } from '../model/User';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { generateUuid } from '../utils/CommonUtil';
import { ThemeUtil } from '../utils/ThemeUtil';
import { Api } from '../net/Api';
import { AppConfig } from '../config/AppConfig';
import { ConfigurationConstant } from '@kit.AbilityKit';

@Component
export struct ProfilePage {
  private pathStack: NavPathStack = new NavPathStack();
  @State user: User | null = null;
  @State nickname: string = '';
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('myReviewCount') myReviewCount: number = 0;
  @StorageLink('favorites') favorites: string[] = [];
  @StorageLink('isGuest') isGuest: boolean = true;

  async aboutToAppear(): Promise<void> {
    if (AppConfig.USE_MOCK) {
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
    } else {
      // 真实后端：首次访问由服务端建号并下发 X-Auth-Token
      try {
        this.user = await Api.getLocalUser();
        await PreferencesUtil.saveUser(this.user);
      } catch (e) {
        console.error('getLocalUser error: ' + (e as Error).message);
      }
    }
    this.nickname = this.user ? this.user.nickname : '';
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
          Text(this.isGuest ? '🌱 游客模式 · 登录后可收藏评价' : `👤 ${this.user?.username ?? ''} · 已登录`)
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

      if (this.isGuest) {
        this.MenuItem('🔐 登录 / 注册', '', (): void => { this.goLogin(); })
      } else {
        this.MenuItem('🚪 退出登录', '', (): void => { this.confirmLogout(); })
      }
      this.MenuItem('📝 我的评价', `${this.myReviewCount} 条`, (): void => { this.goMyReviews(); })
      this.MenuItem('⭐ 我的收藏', `${this.favorites.length} 道`, (): void => { this.goFavorites(); })
      this.MenuItem('🧹 清除缓存', '', (): void => { this.clearCache(); })
      this.DarkModeRow()
      this.MenuItem('📋 隐私声明', '', (): void => { this.goPrivacy(); })
      this.MenuItem('🌿 关于校园食评', `v${AppConfig.APP_VERSION}`, (): void => { this.goAbout(); })
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
    .onShown((): void => {
      // 登录/注册/退出返回后同步最新用户态（Api 层已写入 AppStorage）
      const cached: Object | undefined = AppStorage.get<Object>('localUser');
      if (cached) {
        this.user = cached as User;
        this.nickname = this.user.nickname;
      }
      this.refreshCounts();
    })
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

  private goAbout(): void {
    this.pathStack.pushPathByName('About', '');
  }

  private goLogin(): void {
    this.pathStack.pushPathByName('Login', '');
  }

  private confirmLogout(): void {
    AlertDialog.show({
      message: '确定退出登录？退出后将回到游客模式',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: (): void => {}
      },
      secondaryButton: {
        value: '退出',
        fontColor: Color.White,
        backgroundColor: $r('app.color.brand_primary_dark'),
        action: (): void => { this.doLogout(); }
      }
    });
  }

  /** 退出登录：清除 token 回到游客模式（isGuest 经 AppStorage 自动刷新） */
  private async doLogout(): Promise<void> {
    try {
      this.user = await Api.logout();
      this.nickname = this.user.nickname;
      await PreferencesUtil.saveFavorites([]);
      AppStorage.setOrCreate<string[]>('favorites', []);
    } catch (e) {
      console.error('logout error: ' + (e as Error).message);
    }
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
