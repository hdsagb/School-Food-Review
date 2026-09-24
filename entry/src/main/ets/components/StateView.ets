import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct StateView {
  @Prop state: string = 'empty';
  @Prop message: string = '';
  @StorageLink('darkMode') darkMode: boolean = false;
  doRetry: () => void = () => {};

  private stateEmoji(): string {
    if (this.state === 'error') return '😿';
    if (this.state === 'loading') return '⏳';
    return '🍃';
  }

  private stateText(): string {
    if (this.message) return this.message;
    if (this.state === 'error') return '加载失败啦，再试一次吧';
    if (this.state === 'loading') return '加载中...';
    return '菜单还在准备中～';
  }

  build() {
    Column({ space: 10 }) {
      if (this.state === 'loading') {
        Text(this.stateEmoji())
          .fontSize(40)
        LoadingProgress()
          .width(26)
          .height(26)
          .color(ThemeUtil.brandPrimary(this.darkMode))
      } else {
        Text(this.stateEmoji())
          .fontSize(44)
      }

      Text(this.stateText())
        .fontSize($r('app.float.body_text'))
        .fontColor(ThemeUtil.textHint(this.darkMode))

      if (this.state === 'error') {
        Button('再试一次')
          .type(ButtonType.Capsule)
          .height(34)
          .fontSize($r('app.float.body_text'))
          .fontColor(Color.White)
          .padding({ left: 20, right: 20 })
          .linearGradient({
            angle: 135,
            colors: [
              [$r('app.color.brand_gradient_start'), 0.0],
              [$r('app.color.brand_primary_dark'), 1.0]
            ]
          })
          .shadow({ radius: 8, color: 'rgba(18,169,150,0.3)', offsetX: 0, offsetY: 3 })
          .onClick((): void => { this.doRetry(); })
      }
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .justifyContent(FlexAlign.Center)
  }
}
