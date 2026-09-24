/**
 * 隐私声明页：说明数据收集与使用方式（Demo 版）
 */
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct PrivacyPage {
  private pathStack: NavPathStack = new NavPathStack();
  @StorageLink('darkMode') darkMode: boolean = false;

  build() {
    NavDestination() {
      Column() {
        this.TopBar()

        Scroll() {
          Column({ space: 10 }) {
            this.Section('1. 我们收集的信息',
              '“今日校园”为校园餐饮信息展示类应用。当前版本（演示版）仅在本地设备存储你主动产生的数据：昵称、收藏的菜品、发表的评价及上传的评价图片，不上传任何服务器。')
            this.Section('2. 信息的使用',
              '上述数据仅用于：展示你的个人收藏与评价记录、在本地恢复你的历史操作。App 不会将你的数据用于广告、分析或向任何第三方提供。')
            this.Section('3. 权限说明',
              'App 仅申请网络权限（ohos.permission.INTERNET），用于获取食堂菜单信息；选择评价图片时使用系统安全组件，无需额外相册权限。')
            this.Section('4. 信息存储与删除',
              '数据保存在本机应用沙箱内。你可通过“我的 - 清除缓存”删除菜单缓存，卸载应用即可清除全部本地数据。')
            this.Section('5. 未成年人保护',
              '本应用适合校园用户使用，我们建议未成年人在监护人指导下使用，并妥善保管个人设备。')
            this.Section('6. 声明更新与联系',
              '本声明可能随功能迭代更新，更新后会在此页面展示。如需反馈意见，请通过学校食堂管理渠道联系我们。')
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

  @Builder TopBar() {
    Row() {
      Text('←')
        .fontSize(24)
        .padding(8)
        .onClick((): void => { this.pathStack.pop(); })
      Text('隐私声明')
        .fontSize($r('app.float.title_medium'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('').width(40)
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
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
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
  }
}
