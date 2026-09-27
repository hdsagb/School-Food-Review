/**
 * 隐私声明页：说明数据收集与使用方式（Demo 版）
 */
import { TopBar } from '../components/TopBar';
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct PrivacyPage {
  private pathStack: NavPathStack = new NavPathStack();
  @StorageLink('darkMode') darkMode: boolean = false;

  build() {
    NavDestination() {
      Column() {
        TopBar({ title: '隐私声明', onBack: (): void => { this.pathStack.pop(); } })

        Scroll() {
          Column({ space: 10 }) {
            this.Section('1. 我们收集的信息',
              '“校园食评”为校园餐饮信息展示类应用。为提供菜品评价功能，我们收集：① 自动生成的游客标识与昵称（用于区分用户，无需注册手机号）；② 你主动产生的收藏、评价（文字、星级、维度评分）及选择上传的评价图片；③ 你对他人评价的点赞记录（仅保存在本机）。')
            this.Section('2. 信息的使用与公开范围',
              '你的评价与收藏会同步至应用服务器，仅用于实现菜单浏览、评价展示、收藏同步等核心功能。你发表的评价对其他用户可见：勾选“匿名”时以“匿名同学”展示，未勾选时展示你的昵称。我们不会将你的数据用于广告、分析或提供给任何第三方。')
            this.Section('3. 权限说明',
              'App 仅申请网络权限（ohos.permission.INTERNET），用于访问应用服务器获取菜单数据并同步评价；选择评价图片时使用系统安全控件，无需额外相册或存储权限。')
            this.Section('4. 信息存储与删除',
              '游客标识与点赞记录保存在本机应用沙箱内，卸载应用即清除；评价与收藏保存在应用服务器。如需删除服务器上的评价、收藏或游客账号，可通过学校食堂管理渠道联系管理员处理。')
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
