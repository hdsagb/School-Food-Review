import { Api } from '../net/Api';
import { Canteen, Stall } from '../model/Canteen';
import { Dish, MealType } from '../model/Dish';
import { DishCard } from '../components/DishCard';
import { SkeletonList } from '../components/SkeletonList';
import { StateView } from '../components/StateView';
import { getCurrentMealType } from '../utils/CommonUtil';
import { ThemeUtil } from '../utils/ThemeUtil';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { AppConfig } from '../config/AppConfig';
import { common } from '@kit.AbilityKit';
import { DishDetailPage } from './DishDetailPage';
import { WriteReviewPage } from './WriteReviewPage';
import { ProfilePage } from './ProfilePage';
import { MyReviewsPage } from './MyReviewsPage';
import { FavoritesPage } from './FavoritesPage';
import { PrivacyPage } from './PrivacyPage';
import { UserAgreementPage } from './UserAgreementPage';
import { AboutPage } from './AboutPage';
import { LoginPage } from './LoginPage';
import { DeleteAccountPage } from './DeleteAccountPage';
import { SchoolPickerPage } from './SchoolPickerPage';

/** 菜单缓存结构（离线兜底） */
interface MenuCache {
  canteenId: string;
  mealType: string;
  dishes: Dish[];
  saveTime: number;
}

@Entry
@Component
struct Index {
  private pathStack: NavPathStack = new NavPathStack();
  @State canteens: Canteen[] = [];
  @State currentCanteenIdx: number = 0;
  @State currentMealIdx: number = getCurrentMealType();
  @State dishes: Dish[] = [];
  @State loading: boolean = true;
  @State error: string = '';
  @State showPrivacySheet: boolean = false;
  @StorageLink('favorites') favorites: string[] = [];
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('isGuest') isGuest: boolean = true;
  // 学校维度：schoolId 为空即「未选校」，主页只展示引导态；变更时（首次选校/后续改校）自动重载数据
  @StorageLink('schoolId') @Watch('onSchoolChanged') schoolId: string = '';
  @StorageLink('schoolName') schoolName: string = '';
  @State searchKeyword: string = '';
  @State searchHistory: string[] = [];
  @State stalls: Stall[] = [];
  @State currentStallId: string = '';
  /** 已加载内容的学校 id，避免 @Watch 与 loadAll 重复请求同一所学校 */
  private loadedSchoolId: string = '';

  private meals: MealType[] = [MealType.BREAKFAST, MealType.LUNCH, MealType.DINNER];
  private mealLabels: string[] = ['早餐', '午餐', '晚餐'];
  private mealEmojis: string[] = ['🌅', '🍜', '🌙'];
  private mealGreetings: string[] = [
    '早安！一日之计在于晨',
    '中午好！干饭时间到',
    '晚上好！犒劳一下自己'
  ];
  private searchTimer: number = -1;

  async aboutToAppear(): Promise<void> {
    // 隐私门控：未同意《隐私声明》前不加载任何数据、不发起网络请求
    const agreed: string = await PreferencesUtil.getString(AppConfig.PREF_KEY_PRIVACY_AGREED, 'false');
    if (agreed !== 'true') {
      this.loading = false;
      this.showPrivacySheet = true;
      return;
    }
    await this.loadAll();
  }

  /** 加载首页数据：先取用户资料（含学校），未选校时主页只保留引导态，不加载任何内容 */
  private async loadAll(): Promise<void> {
    // 初始化用户态（isGuest/localUser/schoolId/schoolName 经 AppStorage 响应式共享）
    try {
      await Api.getLocalUser();
    } catch (e) {
      // 资料拉取失败时不伪装成「未选校」引导态，显式展示错误态与重试
      this.error = (e as Error).message || '网络请求失败，请检查网络后重试';
      this.loading = false;
      return;
    }
    if (!this.schoolId) {
      this.loading = false;
      return;
    }
    await this.loadSchoolContent();
  }

  /** 加载当前所选学校的内容（食堂 / 档口 / 菜品 / 收藏 / 搜索历史） */
  private async loadSchoolContent(): Promise<void> {
    if (!this.schoolId || this.loadedSchoolId === this.schoolId) return;
    this.loadedSchoolId = this.schoolId;
    this.error = '';
    this.loading = true;
    this.canteens = [];
    this.stalls = [];
    this.dishes = [];
    await this.loadCanteens();
    await this.loadStalls();
    await this.loadMenu();
    this.favorites = await Api.getFavorites();
    this.searchHistory = await PreferencesUtil.getSearchHistory();
  }

  /** 学校变更（首次选校 / 后续改校）后重载该校数据；清空选择时回到引导态 */
  onSchoolChanged(): void {
    if (this.loadedSchoolId === this.schoolId) return;
    this.currentCanteenIdx = 0;
    this.currentStallId = '';
    this.searchKeyword = '';
    this.stalls = [];
    if (!this.schoolId) {
      this.canteens = [];
      this.dishes = [];
      this.loadedSchoolId = '';
      this.loading = false;
      return;
    }
    // 切校后旧收藏可能不属于新校，先清空再由接口回填（切回原校时会重新显示）
    this.favorites = [];
    this.loadSchoolContent();
  }

  /** 拦截返回键：隐私弹窗展示期间必须显式选择 */
  onBackPress(): boolean {
    return this.showPrivacySheet;
  }

  /** 同意隐私声明并进入应用 */
  private async agreePrivacy(): Promise<void> {
    await PreferencesUtil.putString(AppConfig.PREF_KEY_PRIVACY_AGREED, 'true');
    this.showPrivacySheet = false;
    await this.loadAll();
  }

  /** 不同意则退出应用 */
  private declinePrivacy(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      ctx.terminateSelf();
    } catch (e) {
      console.warn('terminateSelf failed (maybe in previewer): ' + (e as Error).message);
    }
  }

  /** 页面重新显示时刷新收藏，保证从详情页返回后红心同步 */
  async onPageShow(): Promise<void> {
    // 隐私未同意、或尚未选校时不发起内容请求
    if (this.showPrivacySheet || !this.schoolId) return;
    // 从选校页返回时学校可能已变化，重载该校内容；否则只同步收藏红心
    if (this.loadedSchoolId !== this.schoolId) {
      await this.loadSchoolContent();
      return;
    }
    this.favorites = await Api.getFavorites();
  }

  async loadCanteens(): Promise<void> {
    try {
      this.canteens = await Api.getCanteenList();
    } catch (e) {
      // 兜底文案：避免异常 message 为空串时被当作"无错误"，从而误显示成空态
      this.error = (e as Error).message || '网络请求失败，请检查网络后重试';
    }
  }

  async loadMenu(): Promise<void> {
    if (this.canteens.length === 0) {
      // 本校暂无食堂：不是故障，交给「建设中」空态展示；
      // 但若食堂列表本身加载失败（this.error 已有值），保留错误态，不被空态掩盖
      this.dishes = [];
      this.loading = false;
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      const canteenId = this.canteens[this.currentCanteenIdx].id;
      const mealType = this.meals[this.currentMealIdx];
      let list: Dish[];
      if (this.searchKeyword) {
        list = await Api.searchDishes(this.searchKeyword);
        this.recordSearchHistory(this.searchKeyword);
      } else {
        list = await Api.getTodayMenu(canteenId, mealType);
        await this.saveMenuCache(list);
      }
      this.dishes = this.filterByStall(list);
    } catch (e) {
      const cached = await this.loadMenuCache();
      if (cached !== null && cached.length > 0) {
        this.dishes = this.filterByStall(cached);
      } else {
        this.error = (e as Error).message;
      }
    } finally {
      this.loading = false;
    }
  }

  /** 搜索输入防抖：500ms 后触发 */
  private onSearchChange(value: string): void {
    this.searchKeyword = value;
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
    }
    this.searchTimer = setTimeout((): void => {
      this.searchTimer = -1;
      this.loadMenu();
    }, 500);
  }

  /** 记录搜索历史（去重、限量） */
  private recordSearchHistory(keyword: string): void {
    const kw = keyword.trim();
    if (!kw) return;
    const next: string[] = [kw, ...this.searchHistory.filter((k: string): boolean => k !== kw)]
      .slice(0, AppConfig.SEARCH_HISTORY_MAX);
    this.searchHistory = next;
    PreferencesUtil.saveSearchHistory(next);
  }

  private async clearSearchHistory(): Promise<void> {
    this.searchHistory = [];
    await PreferencesUtil.saveSearchHistory([]);
  }

  /** 成功加载菜单后写入离线缓存（保存未筛选的完整列表） */
  private async saveMenuCache(list: Dish[]): Promise<void> {
    if (list.length === 0) return;
    const cache: MenuCache = {
      canteenId: this.canteens[this.currentCanteenIdx].id,
      mealType: this.meals[this.currentMealIdx],
      dishes: list,
      saveTime: Date.now()
    };
    await PreferencesUtil.putObject(AppConfig.PREF_KEY_MENU_CACHE, cache);
  }

  /** 网络失败时读取匹配当前选择的离线缓存 */
  private async loadMenuCache(): Promise<Dish[] | null> {
    const cache = await PreferencesUtil.getObject<MenuCache>(AppConfig.PREF_KEY_MENU_CACHE);
    if (!cache) return null;
    const cid = this.canteens.length > 0 ? this.canteens[this.currentCanteenIdx].id : '';
    if (cache.canteenId === cid && cache.mealType === this.meals[this.currentMealIdx]) {
      return cache.dishes;
    }
    return null;
  }

  /** 加载当前食堂的档口列表 */
  private async loadStalls(): Promise<void> {
    if (this.canteens.length === 0) return;
    try {
      this.stalls = await Api.getStallList(this.canteens[this.currentCanteenIdx].id);
    } catch (e) {
      console.error('loadStalls error: ' + (e as Error).message);
      this.stalls = [];
    }
  }

  /** 按选中档口筛选菜品（空 = 全部） */
  private filterByStall(list: Dish[]): Dish[] {
    if (!this.currentStallId) return list;
    return list.filter((d: Dish): boolean => d.stallId === this.currentStallId);
  }

  private onRefreshTap(): void {
    this.loadMenu();
  }

  /** 加载失败后的整页重试：重新拉取食堂/档口/菜品，避免只重试菜单却仍无食堂数据 */
  private retryAll(): void {
    this.error = '';
    this.loading = true;
    // 清空已加载标记，绕过 loadSchoolContent 的去重，强制重新请求
    this.loadedSchoolId = '';
    this.loadAll();
  }

  private getDateLabel(): string {
    const now = new Date();
    return `${now.getMonth() + 1}月${now.getDate()}日`;
  }

  build() {
    Navigation(this.pathStack) {
      Stack() {
        Column() {
          this.HeaderBar()

          if (this.schoolId) {
            // 本校没有食堂时不渲染食堂/餐段/档口/搜索历史等控件，只保留空态提示
            if (this.canteens.length > 0) {
              this.CanteenChips()
              this.MealChips()
              this.StallChips()
              this.SearchHistory()
            }

            if (this.loading) {
              SkeletonList({ count: 4 })
                .layoutWeight(1)
            } else if (this.error) {
              Column() {
                StateView({ state: 'error', message: this.error, doRetry: (): void => { this.retryAll(); } })
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            } else if (this.dishes.length === 0) {
              Column() {
                StateView({
                  state: 'empty',
                  message: this.canteens.length === 0 ? '该校食堂数据正在建设中，敬请期待' : ''
                })
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            } else {
              Refresh({ refreshing: $$this.loading }) {
                List({ space: 10 }) {
                  ForEach(this.dishes, (d: Dish) => {
                    ListItem() {
                      DishCard({
                        dishData: d,
                        isFavorite: this.favorites.includes(d.id),
                        doTap: (): void => { this.goDetail(d.id); },
                        doFavorite: (): void => { this.toggleFavorite(d.id); }
                      })
                    }
                  }, (d: Dish) => d.id)
                }
                .width('100%')
                .height('100%')
                .padding({ left: 14, right: 14, top: 10, bottom: 14 })
              }
              .onRefreshing((): void => { this.loadMenu(); })
              .layoutWeight(1)
            }
          } else if (this.error) {
            // 用户资料拉取失败：显式错误态 + 重试，不伪装成「未选校」引导
            Column() {
              StateView({ state: 'error', message: this.error, doRetry: (): void => { this.retryAll(); } })
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            this.NoSchoolGuide()
          }

          this.BottomBar()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeUtil.pageBg(this.darkMode))

        // 隐私同意遮罩：用页面内层叠实现，不依赖半模态 API，确保任何设备/模拟器上都能显示
        if (this.showPrivacySheet) {
          this.PrivacyOverlay()
        }
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .navDestination(this.PagesMap)
  }

  /** 未选校引导态：主页不展示任何食堂 / 菜品内容，只能先去选择学校 */
  @Builder NoSchoolGuide() {
    Column({ space: 10 }) {
      Text('🏫')
        .fontSize(56)
      Text('你还没有选择学校')
        .fontSize($r('app.float.title_medium'))
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeUtil.textPrimary(this.darkMode))
      Text('选择所在学校后，即可查看该校的食堂与菜品评价')
        .fontSize($r('app.float.body_text'))
        .fontColor(ThemeUtil.textSecondary(this.darkMode))
        .textAlign(TextAlign.Center)
        .padding({ left: 36, right: 36 })
      Row({ space: 2 }) {
        Text('去选择学校')
          .fontSize($r('app.float.body_text'))
          .fontColor(ThemeUtil.brandDeep(this.darkMode))
          .decoration({ type: TextDecorationType.Underline, color: ThemeUtil.brandDeep(this.darkMode) })
        Text('>')
          .fontSize($r('app.float.body_text'))
          .fontColor(ThemeUtil.brandDeep(this.darkMode))
      }
      .margin({ top: 8 })
      .onClick((): void => { this.goSchoolPicker(); })

      Text('不同学校的食堂与菜品数据相互独立')
        .fontSize(10)
        .fontColor(ThemeUtil.textHint(this.darkMode))
        .margin({ top: 4 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder PrivacyOverlay() {
    Column() {
      this.PrivacyCard()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.55)')
    .onClick((): void => {})
  }

  @Builder PrivacyCard() {
    Column({ space: 14 }) {
      Text('🛡️ 欢迎使用校园食评')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeUtil.textPrimary(this.darkMode))
        .width('100%')

      Text('在你使用前，请阅读并同意《用户协议》与《隐私声明》：')
        .fontSize($r('app.float.body_text'))
        .fontColor(ThemeUtil.textSecondary(this.darkMode))
        .width('100%')

      Column({ space: 8 }) {
        Text('· 仅收集昵称、评价内容、图片与点赞等必要信息，用于提供菜单浏览与评价服务')
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textSecondary(this.darkMode))
        Text('· 评价经审核通过后公开显示，昵称可选择匿名')
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textSecondary(this.darkMode))
        Text('· 选择评价图片时使用系统安全控件，无需额外相册权限')
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textSecondary(this.darkMode))
        Text('· 可随时删除自己发布的评价，或注销账号')
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textSecondary(this.darkMode))
      }
      .width('100%')
      .padding(12)
      .borderRadius(12)
      .backgroundColor(ThemeUtil.tagBg(this.darkMode))

      Row({ space: 16 }) {
        Text('查看《用户协议》 >')
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.brandDeep(this.darkMode))
          .onClick((): void => { this.pathStack.pushPathByName('Agreement', ''); })
        Text('查看《隐私声明》 >')
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.brandDeep(this.darkMode))
          .onClick((): void => { this.pathStack.pushPathByName('Privacy', ''); })
      }
      .width('100%')

      Row({ space: 12 }) {
        Text('不同意并退出')
          .fontSize($r('app.float.body_text'))
          .fontColor(ThemeUtil.textHint(this.darkMode))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(42)
          .borderRadius(21)
          .border({ width: 1, color: ThemeUtil.divider(this.darkMode) })
          .onClick((): void => { this.declinePrivacy(); })

        Text('同意并继续')
          .fontSize($r('app.float.body_text'))
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(42)
          .borderRadius(21)
          .linearGradient({
            angle: 135,
            colors: [
              [$r('app.color.brand_gradient_start'), 0.0],
              [$r('app.color.brand_gradient_end'), 1.0]
            ]
          })
          .onClick((): void => { this.agreePrivacy(); })
      }
      .width('100%')
    }
    .width('88%')
    .padding({ left: 20, right: 20, top: 22, bottom: 24 })
    .alignItems(HorizontalAlign.Start)
    .borderRadius(20)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .shadow({ radius: 24, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 8 })
  }

  @Builder PagesMap(name: string) {
    if (name === 'DishDetail') {
      DishDetailPage()
    } else if (name === 'WriteReview') {
      WriteReviewPage()
    } else if (name === 'Profile') {
      ProfilePage()
    } else if (name === 'MyReviews') {
      MyReviewsPage()
    } else if (name === 'Favorites') {
      FavoritesPage()
    } else if (name === 'Privacy') {
      PrivacyPage()
    } else if (name === 'Agreement') {
      UserAgreementPage()
    } else if (name === 'About') {
      AboutPage()
    } else if (name === 'Login') {
      LoginPage()
    } else if (name === 'DeleteAccount') {
      DeleteAccountPage()
    } else if (name === 'SchoolPicker') {
      SchoolPickerPage()
    }
  }

  @Builder HeaderBar() {
    Stack() {
      // 装饰性半透明气泡，增加青春氛围
      Circle({ width: 130, height: 130 })
        .fill('rgba(255,255,255,0.14)')
        .position({ x: '72%', y: -46 })
      Circle({ width: 64, height: 64 })
        .fill('rgba(255,255,255,0.12)')
        .position({ x: '60%', y: 54 })
      Circle({ width: 40, height: 40 })
        .fill('rgba(255,255,255,0.18)')
        .position({ x: -12, y: 20 })

      Column({ space: 10 }) {
        Row({ space: 8 }) {
          Text('🌿')
            .fontSize(24)
          Text('校园食评')
            .fontSize($r('app.float.title_large'))
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
          Text(`${this.getDateLabel()} · ${this.mealLabels[this.currentMealIdx]}`)
            .fontSize(11)
            .fontColor('rgba(255,255,255,0.9)')
            .backgroundColor('rgba(255,255,255,0.22)')
            .borderRadius(12)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        }
        .width('100%')

        // 学校信息：点击可进入选校页修改（未选校时提示去选择）
        Row() {
          Row({ space: 6 }) {
            Text('📍')
              .fontSize(12)
            Text(this.schoolName || '还未选择学校')
              .fontSize($r('app.float.caption_text'))
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: 170 })
            Text(this.schoolName ? '切换 ▾' : '去选择 >')
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.85)')
          }
          .backgroundColor('rgba(255,255,255,0.22)')
          .borderRadius(14)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .onClick((): void => { this.goSchoolPicker(); })
        }
        .width('100%')

        Text(`${this.mealGreetings[this.currentMealIdx]}，今天想吃点啥？`)
          .fontSize($r('app.float.body_text'))
          .fontColor('rgba(255,255,255,0.92)')
          .width('100%')

        if (this.schoolId) {
          Row({ space: 6 }) {
            Text('🔍')
              .fontSize(14)
            TextInput({ placeholder: '搜索菜品，比如「牛肉面」' })
              .layoutWeight(1)
              .height(36)
              .fontSize($r('app.float.caption_text'))
              .fontColor('#1C3B30')
              .placeholderColor('#8FA69B')
              .placeholderFont({ size: $r('app.float.caption_text') })
              .backgroundColor(Color.Transparent)
              .padding(0)
              .onChange((v: string): void => { this.onSearchChange(v); })
              .onSubmit((): void => {
                if (this.searchTimer !== -1) {
                  clearTimeout(this.searchTimer);
                  this.searchTimer = -1;
                }
                this.loadMenu();
              })
          }
          .width('100%')
          .height(40)
          .padding({ left: 12, right: 12 })
          .backgroundColor('rgba(255,255,255,0.95)')
          .borderRadius(20)
          .alignItems(VerticalAlign.Center)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 16 })
    }
    .width('100%')
    .linearGradient({
      angle: 160,
      colors: [
        [$r('app.color.brand_gradient_start'), 0.0],
        [$r('app.color.brand_gradient_end'), 1.0]
      ]
    })
    .borderRadius({ bottomLeft: 22, bottomRight: 22 })
  }

  @Builder StallChips() {
    if (this.stalls.length > 0) {
      Column({ space: 4 }) {
        Row() {
          Text(`📍 ${this.canteens[this.currentCanteenIdx].name} 档口`)
            .fontSize($r('app.float.caption_text'))
            .fontColor(ThemeUtil.textHint(this.darkMode))
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        Scroll() {
          Row({ space: 8 }) {
            this.StallChip('全部', '')
            ForEach(this.stalls, (s: Stall) => {
              this.StallChip(s.name, s.id)
            }, (s: Stall) => s.id)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%')
      .margin({ top: 8 })
    }
  }

  @Builder StallChip(label: string, stallId: string) {
    Text(label)
      .fontSize($r('app.float.caption_text'))
      .fontColor(this.currentStallId === stallId ? Color.White : ThemeUtil.textSecondary(this.darkMode))
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(15)
      .backgroundColor(this.currentStallId === stallId ? Color.Transparent : ThemeUtil.cardBg(this.darkMode))
      .linearGradient(this.currentStallId === stallId ? {
        angle: 135,
        colors: [
          [$r('app.color.brand_gradient_start'), 0.0],
          [ThemeUtil.brandPrimaryDark(this.darkMode), 1.0]
        ]
      } : {
        angle: 135,
        colors: [
          [ThemeUtil.cardBg(this.darkMode), 0.0],
          [ThemeUtil.cardBg(this.darkMode), 1.0]
        ]
      })
      .shadow(this.currentStallId === stallId ? {
        radius: 8, color: 'rgba(18,169,150,0.3)', offsetX: 0, offsetY: 2
      } : {
        radius: 6, color: 'rgba(28,59,48,0.05)', offsetX: 0, offsetY: 2
      })
      .onClick((): void => {
        this.currentStallId = stallId;
        this.loadMenu();
      })
  }

  @Builder SearchHistory() {
    if (this.searchKeyword === '' && this.searchHistory.length > 0) {
      Column({ space: 6 }) {
        Row() {
          Text('🕘 最近搜索')
            .fontSize($r('app.float.caption_text'))
            .fontColor(ThemeUtil.textHint(this.darkMode))
            .layoutWeight(1)
          Text('清除')
            .fontSize($r('app.float.caption_text'))
            .fontColor(ThemeUtil.textHint(this.darkMode))
            .onClick((): void => { this.clearSearchHistory(); })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.searchHistory, (kw: string) => {
              Text(`# ${kw}`)
                .fontSize($r('app.float.caption_text'))
                .fontColor(ThemeUtil.brandDeep(this.darkMode))
                .backgroundColor(ThemeUtil.tagBg(this.darkMode))
                .borderRadius(14)
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .onClick((): void => {
                  this.searchKeyword = kw;
                  this.loadMenu();
                })
            }, (kw: string) => kw)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
      .width('100%')
    }
  }

  @Builder CanteenChips() {
    Scroll() {
      Row({ space: 10 }) {
        ForEach(this.canteens, (c: Canteen, idx: number) => {
          Column({ space: 3 }) {
            Row({ space: 4 }) {
              Text('📍')
                .fontSize(12)
              Text(c.name)
                .fontSize($r('app.float.body_text'))
                .fontWeight(FontWeight.Medium)
            }
            Text(`${c.location} · ${c.openHours}`)
              .fontSize(10)
              .fontColor(this.currentCanteenIdx === idx ? 'rgba(255,255,255,0.85)' : ThemeUtil.textHint(this.darkMode))
          }
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .borderRadius(14)
          .backgroundColor(this.currentCanteenIdx === idx ? Color.Transparent : ThemeUtil.cardBg(this.darkMode))
          .linearGradient(this.currentCanteenIdx === idx ? {
            angle: 135,
            colors: [
              [$r('app.color.brand_gradient_start'), 0.0],
              [ThemeUtil.brandPrimaryDark(this.darkMode), 1.0]
            ]
          } : {
            angle: 135,
            colors: [
              [ThemeUtil.cardBg(this.darkMode), 0.0],
              [ThemeUtil.cardBg(this.darkMode), 1.0]
            ]
          })
          .shadow(this.currentCanteenIdx === idx ? {
            radius: 10, color: 'rgba(18,169,150,0.35)', offsetX: 0, offsetY: 3
          } : {
            radius: 6, color: 'rgba(28,59,48,0.05)', offsetX: 0, offsetY: 2
          })
          .onClick((): void => {
            this.currentCanteenIdx = idx;
            this.currentStallId = '';
            this.loadStalls();
            this.loadMenu();
          })
        }, (c: Canteen) => c.id)
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .height(64)
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder MealChips() {
    Row({ space: 0 }) {
      ForEach(this.mealLabels, (label: string, idx: number) => {
        Row({ space: 4 }) {
          Text(this.mealEmojis[idx])
            .fontSize(14)
            .opacity(this.currentMealIdx === idx ? 1.0 : 0.6)
          Text(label)
            .fontSize($r('app.float.body_text'))
            .fontWeight(this.currentMealIdx === idx ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentMealIdx === idx ? Color.White : ThemeUtil.textSecondary(this.darkMode))
        }
        .layoutWeight(1)
        .height(34)
        .justifyContent(FlexAlign.Center)
        .borderRadius(17)
        .linearGradient(this.currentMealIdx === idx ? {
          angle: 135,
          colors: [
            [$r('app.color.brand_gradient_start'), 0.0],
            [ThemeUtil.brandPrimaryDark(this.darkMode), 1.0]
          ]
        } : {
          angle: 135,
          colors: [
            [Color.Transparent, 0.0],
            [Color.Transparent, 1.0]
          ]
        })
        .onClick((): void => {
          this.currentMealIdx = idx;
          this.loadMenu();
        })
      }, (label: string) => label)
    }
    .width('100%')
    .height(40)
    .margin({ left: 14, right: 14, top: 10, bottom: 4 })
    .padding(3)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius(20)
    .shadow({ radius: 8, color: 'rgba(28,59,48,0.06)', offsetX: 0, offsetY: 2 })
  }

  @Builder BottomBar() {
    Row() {
      this.TabItem('🍽️', '今日菜单', true, (): void => {})
      this.TabItem('🧑‍🎓', '我的', false, (): void => { this.goProfile(); })
    }
    .width('100%')
    .height(58)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .shadow({ radius: 12, color: 'rgba(28,59,48,0.08)', offsetX: 0, offsetY: -3 })
    .padding({ top: 6, bottom: 6 })
  }

  @Builder TabItem(emoji: string, label: string, active: boolean, onTap: () => void) {
    Column({ space: 2 }) {
      Text(emoji)
        .fontSize(20)
        .opacity(active ? 1.0 : 0.55)
      Text(label)
        .fontSize(10)
        .fontWeight(active ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(active ? ThemeUtil.brandPrimaryDark(this.darkMode) : ThemeUtil.textHint(this.darkMode))
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick((): void => { onTap(); })
  }

  private async toggleFavorite(dishId: string): Promise<void> {
    if (this.isGuest) {
      this.promptLogin('收藏菜品需要登录');
      return;
    }
    this.favorites = await Api.toggleFavorite(dishId);
    await PreferencesUtil.saveFavorites(this.favorites);
  }

  /** 游客写操作拦截：确认后前往登录页 */
  private promptLogin(message: string): void {
    AlertDialog.show({
      message: message,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '暂不',
        action: (): void => {}
      },
      secondaryButton: {
        value: '去登录',
        fontColor: Color.White,
        backgroundColor: $r('app.color.brand_primary_dark'),
        action: (): void => { this.pathStack.pushPathByName('Login', ''); }
      }
    });
  }

  private goDetail(dishId: string): void {
    this.pathStack.pushPathByName('DishDetail', dishId);
  }

  private goProfile(): void {
    this.pathStack.pushPathByName('Profile', '');
  }

  /** 进入学校选择页（首次选校引导 / 点击主页学校名改校共用） */
  private goSchoolPicker(): void {
    this.pathStack.pushPathByName('SchoolPicker', '');
  }
}
