import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct TopBar {
  @Prop title: string = '';
  @Prop leftText: string = '←';
  onBack: () => void = () => {};
  @StorageLink('darkMode') darkMode: boolean = false;

  build() {
    Row() {
      if (this.leftText === '←') {
        Text('←')
          .fontSize(24)
          .padding(8)
          .onClick((): void => { this.onBack(); })
      } else {
        Text(this.leftText)
          .fontSize($r('app.float.body_text'))
          .fontColor(ThemeUtil.textSecondary(this.darkMode))
          .padding(8)
          .onClick((): void => { this.onBack(); })
      }
      Text(this.title)
        .fontSize($r('app.float.title_medium'))
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('').width(this.leftText === '←' ? 40 : 48)
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 8 })
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
  }
}
