/**
 * 注销账号页
 * - 明示注销后果（评价匿名化保留、账号信息删除、不可恢复）
 * - 需输入登录密码二次确认，成功后回到游客模式
 */
import { TopBar } from '../components/TopBar';
import { ThemeUtil } from '../utils/ThemeUtil';
import { Api } from '../net/Api';

@Component
export struct DeleteAccountPage {
  private pathStack: NavPathStack = new NavPathStack();
  @StorageLink('darkMode') darkMode: boolean = false;
  @State password: string = '';
  @State error: string = '';
  @State submitting: boolean = false;

  build() {
    NavDestination() {
      Column() {
        TopBar({ title: '注销账号', onBack: (): void => { this.pathStack.pop(); } })

        Scroll() {
          Column({ space: 12 }) {
            // 风险说明
            Column({ space: 8 }) {
              Text('⚠️ 注销后将发生以下变化')
                .fontSize($r('app.float.title_small'))
                .fontWeight(FontWeight.Medium)
                .fontColor('#E06C5A')
                .width('100%')
              Text('· 你的账号信息（用户名、登录凭据）将被永久删除，无法恢复')
                .fontSize($r('app.float.body_text'))
                .fontColor(ThemeUtil.textSecondary(this.darkMode))
                .lineHeight(20)
                .width('100%')
              Text('· 你已发布的评价将匿名化保留（作者显示为「已注销用户」），以维护菜品评分的连续性')
                .fontSize($r('app.float.body_text'))
                .fontColor(ThemeUtil.textSecondary(this.darkMode))
                .lineHeight(20)
                .width('100%')
              Text('· 你的收藏、点赞与举报记录将被清除')
                .fontSize($r('app.float.body_text'))
                .fontColor(ThemeUtil.textSecondary(this.darkMode))
                .lineHeight(20)
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(ThemeUtil.cardBg(this.darkMode))
            .borderRadius($r('app.float.corner_card'))
            .shadow({ radius: 8, color: 'rgba(28,59,48,0.05)', offsetX: 0, offsetY: 2 })

            TextInput({ placeholder: '请输入登录密码以确认注销', text: this.password })
              .width('100%')
              .height(44)
              .fontSize($r('app.float.body_text'))
              .fontColor(ThemeUtil.textPrimary(this.darkMode))
              .placeholderColor(ThemeUtil.textHint(this.darkMode))
              .placeholderFont({ size: $r('app.float.caption_text') })
              .backgroundColor(ThemeUtil.cardBg(this.darkMode))
              .borderRadius(12)
              .type(InputType.Password)
              .onChange((v: string): void => { this.password = v; })

            if (this.error) {
              Text(this.error)
                .fontSize($r('app.float.caption_text'))
                .fontColor('#E06C5A')
                .width('100%')
            }

            Text(this.submitting ? '正在注销…' : '确认注销账号')
              .fontSize($r('app.float.body_text'))
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .width('100%')
              .height(44)
              .borderRadius(22)
              .backgroundColor('#E06C5A')
              .opacity(this.submitting ? 0.6 : 1.0)
              .onClick((): void => { this.submit(); })

            Text('注销后如需继续使用，可重新注册新账号。')
              .fontSize($r('app.float.caption_text'))
              .fontColor(ThemeUtil.textHint(this.darkMode))
              .width('100%')
          }
          .width('100%')
          .padding(14)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
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

  private async submit(): Promise<void> {
    if (this.submitting) return;
    if (!this.password) {
      this.error = '请输入登录密码';
      return;
    }
    this.submitting = true;
    this.error = '';
    try {
      await Api.deleteAccount(this.password);
      this.pathStack.pop();
    } catch (e) {
      this.error = (e as Error).message || '注销失败，请重试';
    } finally {
      this.submitting = false;
    }
  }
}