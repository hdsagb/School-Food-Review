/**
 * 学校选择页
 * - 首次打开应用时由主页引导进入；之后在「我的」页可再次进入修改
 * - 支持中文子串 / 全拼 / 首字母三种检索（拼音由服务端下发，前端本地过滤）
 * - 学校只能从预置名单中选择，不支持自填
 */
import { Api } from '../net/Api';
import { School } from '../model/School';
import { TopBar } from '../components/TopBar';
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct SchoolPickerPage {
  private pathStack: NavPathStack = new NavPathStack();
  @StorageLink('darkMode') darkMode: boolean = false;
  @StorageLink('schoolId') schoolId: string = '';
  @State schools: School[] = [];
  @State undergrads: School[] = [];
  @State colleges: School[] = [];
  @State keyword: string = '';
  @State loading: boolean = true;
  @State error: string = '';
  @State submitting: boolean = false;

  async aboutToAppear(): Promise<void> {
    try {
      this.schools = await Api.getSchools();
      this.applyFilter(this.keyword);
      this.error = '';
    } catch (e) {
      this.error = (e as Error).message || '学校名单加载失败，请检查网络后重试';
    } finally {
      this.loading = false;
    }
  }

  build() {
    NavDestination() {
      Column() {
        TopBar({ title: '选择学校', onBack: (): void => { this.pathStack.pop(); } })

        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Text('🔍')
              .fontSize(14)
            TextInput({ placeholder: '搜索学校，如「复旦」「fudan」「fd」', text: this.keyword })
              .layoutWeight(1)
              .height(38)
              .fontSize($r('app.float.body_text'))
              .fontColor(ThemeUtil.textPrimary(this.darkMode))
              .placeholderColor(ThemeUtil.textHint(this.darkMode))
              .placeholderFont({ size: $r('app.float.caption_text') })
              .backgroundColor(Color.Transparent)
              .padding(0)
              .onChange((v: string): void => {
                this.keyword = v;
                this.applyFilter(v);
              })
          }
          .width('100%')
          .height(42)
          .padding({ left: 12, right: 12 })
          .backgroundColor(ThemeUtil.cardBg(this.darkMode))
          .borderRadius(21)
          .alignItems(VerticalAlign.Center)

          Text('不同学校的数据相互独立；切换后首页内容随之变化，收藏页仅显示当前学校的收藏（切回原校自动恢复）')
            .fontSize(10)
            .fontColor(ThemeUtil.textHint(this.darkMode))
            .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        if (this.loading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color(ThemeUtil.brandPrimaryDark(this.darkMode))
            Text('正在加载学校名单…')
              .fontSize($r('app.float.caption_text'))
              .fontColor(ThemeUtil.textHint(this.darkMode))
              .margin({ top: 10 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.error) {
          Column({ space: 12 }) {
            Text('😥')
              .fontSize(40)
            Text(this.error)
              .fontSize($r('app.float.body_text'))
              .fontColor(ThemeUtil.textSecondary(this.darkMode))
              .textAlign(TextAlign.Center)
              .padding({ left: 24, right: 24 })
            Text('重新加载')
              .fontSize($r('app.float.body_text'))
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .width(140)
              .height(40)
              .borderRadius(20)
              .backgroundColor(ThemeUtil.brandPrimaryDark(this.darkMode))
              .onClick((): void => { this.reload(); })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.undergrads.length === 0 && this.colleges.length === 0) {
          Column({ space: 10 }) {
            Text('🔍')
              .fontSize(40)
            Text('没有匹配的学校，请换个关键词试试')
              .fontSize($r('app.float.body_text'))
              .fontColor(ThemeUtil.textSecondary(this.darkMode))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 8 }) {
            if (this.undergrads.length > 0) {
              ListItem() { this.GroupHeader('本科院校', this.undergrads.length) }
              ForEach(this.undergrads, (s: School) => {
                ListItem() { this.SchoolRow(s) }
              }, (s: School) => s.id)
            }
            if (this.colleges.length > 0) {
              ListItem() { this.GroupHeader('高职（专科）院校', this.colleges.length) }
              ForEach(this.colleges, (s: School) => {
                ListItem() { this.SchoolRow(s) }
              }, (s: School) => s.id)
            }
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .padding({ left: 14, right: 14, bottom: 14 })
        }
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
  }

  @Builder GroupHeader(title: string, count: number) {
    Row() {
      Text(title)
        .fontSize($r('app.float.title_small'))
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeUtil.textPrimary(this.darkMode))
        .layoutWeight(1)
      Text(`${count} 所`)
        .fontSize($r('app.float.caption_text'))
        .fontColor(ThemeUtil.textHint(this.darkMode))
    }
    .width('100%')
    .padding({ left: 4, top: 8, bottom: 4 })
  }

  @Builder SchoolRow(s: School) {
    Row({ space: 8 }) {
      Column({ space: 3 }) {
        Text(s.name)
          .fontSize($r('app.float.body_text'))
          .fontWeight(FontWeight.Medium)
          .fontColor(this.schoolId === s.id ? ThemeUtil.brandDeep(this.darkMode) : ThemeUtil.textPrimary(this.darkMode))
          .width('100%')
        Text(`${s.city} · ${s.level}`)
          .fontSize(10)
          .fontColor(ThemeUtil.textHint(this.darkMode))
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.schoolId === s.id) {
        Text('✓ 当前')
          .fontSize(10)
          .fontColor(ThemeUtil.brandDeep(this.darkMode))
          .backgroundColor(ThemeUtil.tagBg(this.darkMode))
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      }
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .borderRadius($r('app.float.corner_card'))
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .border(this.schoolId === s.id
      ? { width: 1, color: ThemeUtil.brandPrimaryDark(this.darkMode) }
      : { width: 0, color: Color.Transparent })
    .opacity(this.submitting ? 0.7 : 1.0)
    .onClick((): void => { this.selectSchool(s); })
  }

  /** 中文子串 / 全拼 / 首字母 三种方式模糊匹配 */
  private match(s: School, kw: string): boolean {
    const raw = kw.trim();
    if (!raw) return true;
    if (s.name.includes(raw)) return true;
    const lower = raw.toLowerCase();
    if (s.pinyinFull.toLowerCase().includes(lower)) return true;
    if (s.pinyinInitials.toLowerCase().includes(lower)) return true;
    return false;
  }

  private applyFilter(kw: string): void {
    const under: School[] = [];
    const colleges: School[] = [];
    for (const s of this.schools) {
      if (!this.match(s, kw)) continue;
      if (s.level === '专科') {
        colleges.push(s);
      } else {
        under.push(s);
      }
    }
    this.undergrads = under;
    this.colleges = colleges;
  }

  private async reload(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.schools = await Api.getSchools();
      this.applyFilter(this.keyword);
    } catch (e) {
      this.error = (e as Error).message || '学校名单加载失败，请检查网络后重试';
    } finally {
      this.loading = false;
    }
  }

  private selectSchool(s: School): void {
    if (this.submitting) return;
    if (this.schoolId === s.id) {
      this.pathStack.pop();
      return;
    }
    // 已有学校时属于「改校」：明确提示收藏页的变化，避免误操作
    if (this.schoolId) {
      AlertDialog.show({
        title: '切换学校',
        message: `切换到「${s.name}」后，首页的食堂与菜品会随之变化；收藏页中原学校的收藏会暂时隐藏，切回原学校后会自动恢复。确定切换？`,
        autoCancel: true,
        alignment: DialogAlignment.Center,
        primaryButton: {
          value: '取消',
          action: (): void => {}
        },
        secondaryButton: {
          value: '确定切换',
          fontColor: Color.White,
          backgroundColor: $r('app.color.brand_primary_dark'),
          action: (): void => { this.applySchool(s); }
        }
      });
      return;
    }
    this.applySchool(s);
  }

  private async applySchool(s: School): Promise<void> {
    if (this.submitting) return;
    this.submitting = true;
    try {
      await Api.setUserSchool(s.id);
      this.pathStack.pop();
    } catch (e) {
      this.error = (e as Error).message || '保存失败，请重试';
    } finally {
      this.submitting = false;
    }
  }
}