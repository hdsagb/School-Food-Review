import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct LoadMoreFooter {
  @Prop loading: boolean = false;
  @Prop hasMore: boolean = false;
  onLoadMore: () => void = () => {};
  @StorageLink('darkMode') darkMode: boolean = false;

  build() {
    Column() {
      if (this.hasMore) {
        Button(this.loading ? '加载中…' : '加载更多评价')
          .type(ButtonType.Capsule)
          .width('100%')
          .height(34)
          .fontSize($r('app.float.caption_text'))
          .backgroundColor(ThemeUtil.tagBg(this.darkMode))
          .fontColor(ThemeUtil.brandDeep(this.darkMode))
          .enabled(!this.loading)
          .margin({ top: 8 })
          .onClick((): void => { this.onLoadMore(); })
      } else {
        Text('— 没有更多了 —')
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textHint(this.darkMode))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8 })
      }
    }
    .width('100%')
  }
}
