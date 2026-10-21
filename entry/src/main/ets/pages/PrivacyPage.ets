/**
 * 隐私声明页：说明个人信息的收集、使用、存储与删除方式
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
              '“校园食评”为校园食堂菜单浏览与菜品评价类应用。为提供浏览与评价服务，我们会收集以下信息：\n① 账号标识：你可以“游客”身份直接使用，此时由我们自动生成一个昵称用于区分用户，无需提供手机号；若你注册自定义账号，则需提供用户名、密码（经加密后存储）与昵称，头像为可选；若你选择华为账号一键登录，我们仅从华为获取你的账号唯一标识（用于识别账号），不会获取或保存你的手机号、昵称与头像。\n② 你主动产生的内容：收藏、评价（星级与文字）以及你选择上传的评价图片。\n③ 你对他人评价的点赞记录（与你的账号关联并保存在服务器）。\n我们不会收集你的手机号、通讯录、精确定位、设备唯一标识等信息，也不会读取与上述功能无关的内容。')
            this.Section('2. 信息的使用与公开范围',
              '你的评价、收藏与点赞会同步至应用服务器，仅用于实现菜单浏览、评价展示、收藏与点赞同步等核心功能。你发表的评价经审核通过后对其他用户可见：勾选“匿名”时以“匿名同学”展示，未勾选时展示你的昵称。我们不会将你的数据用于广告投放或用户画像分析，也不会出售或提供给任何第三方。')
            this.Section('3. 权限说明',
              'App 仅申请网络权限（ohos.permission.INTERNET），用于访问应用服务器获取菜单数据并同步评价；选择评价图片时使用系统安全控件，无需额外相册或存储权限。')
            this.Section('4. 信息存储与删除',
              '你的评价、收藏、点赞等数据保存在应用服务器（服务器位于中国大陆境内）；本机仅保存登录凭据、收藏与点赞的本地记录、离线菜单缓存及搜索历史。卸载应用会清除本机数据，但服务器上已保存的内容不会随卸载而删除。\n删除方式：注册用户可在「我的 → 注销账号」中自助注销，注销后账号信息将被删除，已发布的评价将匿名化保留，关联的收藏、点赞与举报记录会被清除；你也可以在「我的 → 我的评价」中随时删除自己发布的单条评价。以游客身份使用时，如需删除服务器上的数据，可通过第 6 节的方式联系我们。')
            this.Section('5. 未成年人保护',
              '本应用适合校园用户使用，我们建议未成年人在监护人指导下使用，并妥善保管个人设备。')
            this.Section('6. 声明更新与联系',
              '本声明可能随功能迭代更新，更新后会在此页面展示。如需就个人信息处理相关问题进行咨询、反馈或行使你的权利，可通过应用内反馈入口或学校食堂管理渠道联系我们。')
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