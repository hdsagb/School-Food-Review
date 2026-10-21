/**
 * 用户协议页：说明服务范围、账号使用、内容规范与责任约定
 */
import { TopBar } from '../components/TopBar';
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct UserAgreementPage {
  private pathStack: NavPathStack = new NavPathStack();
  @StorageLink('darkMode') darkMode: boolean = false;

  build() {
    NavDestination() {
      Column() {
        TopBar({ title: '用户协议', onBack: (): void => { this.pathStack.pop(); } })

        Scroll() {
          Column({ space: 10 }) {
            this.Section('一、服务说明',
              '“校园食评”为校园食堂菜单浏览与菜品评价类应用，提供食堂菜单查询、菜品评价发布与浏览、收藏等功能。你可以“游客”身份浏览内容，注册登录后可发布评价、收藏与点赞。本应用为信息展示与用户交流平台，菜品与评价信息仅供参考。')
            this.Section('二、账号登录与使用',
              '你可以选择「华为账号一键登录」，授权后我们从华为获取你的账号唯一标识（不收集手机号）；也可以注册本应用账号，注册时请提供合法、易记的用户名与密码，并妥善保管账号信息。你应对账号下的全部行为负责，不得将账号转借他人。如发现账号被盗用，请及时联系我们。你可以随时在「我的 → 注销账号」中注销账号，注销后账号信息及华为账号绑定关系将被删除，已发布的评价将匿名化保留。')
            this.Section('三、用户发布内容规范',
              '你发布评价、上传图片时，须保证内容真实、合法，不包含以下内容：\n· 违反法律法规或公序良俗的内容；\n· 广告、营销推广、联系方式等与评价无关的信息；\n· 侵犯他人隐私、名誉、知识产权的内容；\n· 侮辱、谩骂、虚假刷评等扰乱秩序的内容。\n请勿上传非本人拍摄或无权使用的图片，因图片版权引发的纠纷由发布者自行承担。')
            this.Section('四、内容审核与处理',
              '为维护平台秩序，你发布的评价将先进入审核，审核通过后对其他用户可见。我们会对违规内容予以驳回或删除，对严重违规的账号可采取限制措施。其他用户也可对不当评价进行举报，我们会及时核实处理。')
            this.Section('五、知识产权',
              '本应用的界面设计、图标、文案等归我们所有；你发布的评价与图片，你授权我们在本应用范围内展示与使用。如你认为应用内内容侵犯了你的合法权益，可通过第七节的方式联系我们，我们将依法处理。')
            this.Section('六、免责声明',
              '菜品信息与评价内容由用户或学校食堂提供，我们会在合理范围内进行审核，但不保证其完全准确。因使用本应用信息而产生的任何后果，请以现场实际情况为准。本应用不对用户之间的纠纷承担直接责任。')
            this.Section('七、协议变更与联系',
              '本协议可能随功能迭代更新，更新后将在此页面展示。如你不同意变更内容，请停止使用本应用；继续使用即视为接受更新后的协议。如需反馈意见，可通过应用内反馈入口或学校食堂管理渠道联系我们。')
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