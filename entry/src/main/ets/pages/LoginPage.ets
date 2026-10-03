import { Api } from '../net/Api';
import { ThemeUtil } from '../utils/ThemeUtil';

/**
 * 登录 / 注册页
 * - 双页签切换；注册含可选昵称
 * - 成功后经 X-Auth-Token 自动换发 token，返回来源页
 */
@Component
export struct LoginPage {
  private pathStack: NavPathStack = new NavPathStack();
  @StorageLink('darkMode') darkMode: boolean = false;
  @State isRegister: boolean = false;
  @State username: string = '';
  @State password: string = '';
  @State nickname: string = '';
  @State error: string = '';
  @State submitting: boolean = false;

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('←')
            .fontSize(24)
            .padding(8)
            .onClick((): void => { this.pathStack.pop(); })
          Text(this.isRegister ? '注册账号' : '登录')
            .fontSize($r('app.float.title_medium'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
          Text('').width(40)
        }
        .width('100%')
        .height(48)

        Column({ space: 16 }) {
          // 页签切换
          Row() {
            Text('登录')
              .fontSize($r('app.float.body_text'))
              .fontWeight(!this.isRegister ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(!this.isRegister ? Color.White : ThemeUtil.textSecondary(this.darkMode))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(36)
              .borderRadius(18)
              .linearGradient(!this.isRegister ? {
                angle: 135,
                colors: [
                  [$r('app.color.brand_gradient_start'), 0.0],
                  [$r('app.color.brand_gradient_end'), 1.0]
                ]
              } : {
                angle: 135,
                colors: [[Color.Transparent, 0.0], [Color.Transparent, 1.0]]
              })
              .onClick((): void => { this.switchMode(false); })

            Text('注册')
              .fontSize($r('app.float.body_text'))
              .fontWeight(this.isRegister ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.isRegister ? Color.White : ThemeUtil.textSecondary(this.darkMode))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(36)
              .borderRadius(18)
              .linearGradient(this.isRegister ? {
                angle: 135,
                colors: [
                  [$r('app.color.brand_gradient_start'), 0.0],
                  [$r('app.color.brand_gradient_end'), 1.0]
                ]
              } : {
                angle: 135,
                colors: [[Color.Transparent, 0.0], [Color.Transparent, 1.0]]
              })
              .onClick((): void => { this.switchMode(true); })
          }
          .width('100%')
          .padding(3)
          .backgroundColor(ThemeUtil.tagBg(this.darkMode))
          .borderRadius(20)

          TextInput({ placeholder: this.isRegister ? '设置用户名（3-20 位字母/数字/下划线）' : '用户名', text: this.username })
            .width('100%')
            .height(44)
            .fontSize($r('app.float.body_text'))
            .fontColor(ThemeUtil.textPrimary(this.darkMode))
            .placeholderColor(ThemeUtil.textHint(this.darkMode))
            .placeholderFont({ size: $r('app.float.caption_text') })
            .backgroundColor(ThemeUtil.cardBg(this.darkMode))
            .borderRadius(12)
            .onChange((v: string): void => { this.username = v; })

          TextInput({ placeholder: '密码（至少 6 位）', text: this.password })
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

          if (this.isRegister) {
            TextInput({ placeholder: '昵称（选填，不填自动生成）', text: this.nickname })
              .width('100%')
              .height(44)
              .fontSize($r('app.float.body_text'))
              .fontColor(ThemeUtil.textPrimary(this.darkMode))
              .placeholderColor(ThemeUtil.textHint(this.darkMode))
              .placeholderFont({ size: $r('app.float.caption_text') })
              .backgroundColor(ThemeUtil.cardBg(this.darkMode))
              .borderRadius(12)
              .onChange((v: string): void => { this.nickname = v; })
          }

          if (this.error) {
            Text(this.error)
              .fontSize($r('app.float.caption_text'))
              .fontColor('#E06C5A')
              .width('100%')
          }

          Text(this.submitting ? '请稍候…' : (this.isRegister ? '注册并登录' : '登录'))
            .fontSize($r('app.float.body_text'))
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(44)
            .borderRadius(22)
            .opacity(this.submitting ? 0.6 : 1.0)
            .linearGradient({
              angle: 135,
              colors: [
                [$r('app.color.brand_gradient_start'), 0.0],
                [$r('app.color.brand_gradient_end'), 1.0]
              ]
            })
            .onClick((): void => { this.submit(); })

          Text('游客可以浏览菜单与评价，收藏、点赞、发布评价需要登录后使用')
            .fontSize($r('app.float.caption_text'))
            .fontColor(ThemeUtil.textHint(this.darkMode))
            .width('100%')
        }
        .width('100%')
        .padding(20)
        .margin({ top: 10 })
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

  private switchMode(toRegister: boolean): void {
    if (this.isRegister === toRegister) return;
    this.isRegister = toRegister;
    this.error = '';
  }

  private async submit(): Promise<void> {
    if (this.submitting) return;
    const uname = this.username.trim();
    const pwd = this.password;
    const nick = this.nickname.trim();
    if (!/^[a-zA-Z0-9_]{3,20}$/.test(uname)) {
      this.error = '用户名需为 3-20 位字母、数字或下划线';
      return;
    }
    if (pwd.length < 6 || pwd.length > 64) {
      this.error = '密码长度需为 6-64 位';
      return;
    }
    if (this.isRegister && nick.length > 20) {
      this.error = '昵称最长 20 字';
      return;
    }
    this.submitting = true;
    this.error = '';
    try {
      if (this.isRegister) {
        await Api.register(uname, pwd, nick);
      } else {
        await Api.login(uname, pwd);
      }
      this.pathStack.pop();
    } catch (e) {
      this.error = (e as Error).message || '操作失败，请重试';
    } finally {
      this.submitting = false;
    }
  }
}
