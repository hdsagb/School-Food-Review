/**
 * 关于页：展示应用名称、版本号、App 备案号与第三方开源许可声明
 */
import { TopBar } from '../components/TopBar';
import { ThemeUtil } from '../utils/ThemeUtil';
import { AppConfig } from '../config/AppConfig';

@Component
export struct AboutPage {
  private pathStack: NavPathStack = new NavPathStack();
  @StorageLink('darkMode') darkMode: boolean = false;

  build() {
    NavDestination() {
      Column() {
        TopBar({ title: '关于校园食评', onBack: (): void => { this.pathStack.pop(); } })

        Scroll() {
          Column({ space: 10 }) {
            // 应用标识
            Column({ space: 8 }) {
              Image($r('app.media.startIcon'))
                .width(64)
                .height(64)
                .borderRadius(16)
              Text($r('app.string.app_name'))
                .fontSize($r('app.float.title_medium'))
                .fontWeight(FontWeight.Medium)
                .fontColor(ThemeUtil.textPrimary(this.darkMode))
              Text(`v${AppConfig.APP_VERSION}`)
                .fontSize($r('app.float.caption_text'))
                .fontColor(ThemeUtil.textHint(this.darkMode))
            }
            .width('100%')
            .padding(20)
            .backgroundColor(ThemeUtil.cardBg(this.darkMode))
            .borderRadius($r('app.float.corner_card'))
            .shadow({ radius: 10, color: 'rgba(28,59,48,0.06)', offsetX: 0, offsetY: 3 })

            this.InfoRow('应用备案号', AppConfig.APP_FILING_NO)
            this.InfoRow('版本号', `v${AppConfig.APP_VERSION}`)

            this.Section('第三方开源许可声明',
              '本应用未引入任何第三方开源库，全部功能基于 HarmonyOS SDK 提供的系统能力（ArkTS 语言、ArkUI 声明式 UI、网络与本地存储接口）实现。\n仅开发阶段使用 @ohos/hypium 与 @ohos/hamock（Apache-2.0）作为测试框架，二者均不随应用包发布。')
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

  @Builder InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize($r('app.float.body_text'))
        .fontColor(ThemeUtil.textSecondary(this.darkMode))
        .layoutWeight(1)
      Text(value)
        .fontSize($r('app.float.body_text'))
        .fontColor(ThemeUtil.textPrimary(this.darkMode))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
    .shadow({ radius: 8, color: 'rgba(28,59,48,0.05)', offsetX: 0, offsetY: 2 })
  }

  @Builder Section(title: string, content: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize($r('app.float.title_small'))
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeUtil.textPrimary(this.darkMode))
        .width('100%')
      Text(content)
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
  }
}