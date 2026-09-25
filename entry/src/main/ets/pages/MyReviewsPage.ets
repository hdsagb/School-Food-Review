import { Api } from '../net/Api';
import { MyReviewItem } from '../model/Review';
import { StarRating } from '../components/StarRating';
import { StateView } from '../components/StateView';
import { TopBar } from '../components/TopBar';
import { formatRelativeTime } from '../utils/CommonUtil';
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct MyReviewsPage {
  private pathStack: NavPathStack = new NavPathStack();
  @StorageLink('myReviews') items: MyReviewItem[] = [];
  @StorageLink('darkMode') darkMode: boolean = false;
  @State loaded: boolean = false;
  @State refreshing: boolean = false;
  @State previewVisible: boolean = false;
  @State previewImages: string[] = [];
  @State previewIndex: number = 0;

  /** 触发数据同步：MockData 会写入 AppStorage，items 由 @StorageLink 自动刷新 */
  private async loadData(): Promise<void> {
    try {
      await Api.getMyReviews();
    } catch (e) {
      console.error('getMyReviews error: ' + (e as Error).message);
    } finally {
      this.loaded = true;
    }
  }

  private async onPullRefresh(): Promise<void> {
    await this.loadData();
    this.refreshing = false;
  }

  build() {
    NavDestination() {
      Column() {
        TopBar({ title: '我的评价', onBack: (): void => { this.pathStack.pop(); } })

        if (!this.loaded) {
          Column() { StateView({ state: 'loading' }) }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
        } else if (this.items.length === 0) {
          Column() { StateView({ state: 'empty', message: '还没有评价，去写下第一条吧' }) }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
        } else {
          Refresh({ refreshing: $$this.refreshing }) {
            List({ space: 10 }) {
              ForEach(this.items, (item: MyReviewItem) => {
                ListItem() {
                  this.ReviewCard(item)
                }
              }, (item: MyReviewItem) => item.review.id)
            }
            .width('100%')
            .height('100%')
            .padding({ left: 14, right: 14, top: 10, bottom: 14 })
          }
          .onRefreshing((): void => { this.onPullRefresh(); })
          .width('100%')
          .height('100%')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeUtil.pageBg(this.darkMode))
      .bindContentCover($$this.previewVisible, this.ImagePreview(), {
        modalTransition: ModalTransition.DEFAULT
      })
    }
    .hideTitleBar(true)
    .backgroundColor(ThemeUtil.pageBg(this.darkMode))
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
      this.loadData();
    })
    .onShown((): void => { this.loadData(); })
  }

  @Builder ReviewCard(item: MyReviewItem) {
    Column({ space: 6 }) {
      Row() {
        Text(item.dishName)
          .fontSize($r('app.float.body_text'))
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeUtil.brandDeep(this.darkMode))
          .layoutWeight(1)
        Text(formatRelativeTime(item.review.createTime))
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textHint(this.darkMode))
      }
      .width('100%')

      StarRating({ rating: item.review.rating, starSize: 12 })

      Text(item.review.content)
        .fontSize($r('app.float.body_text'))
        .fontColor(ThemeUtil.textSecondary(this.darkMode))
        .width('100%')

      if (item.review.images.length > 0) {
        Row({ space: 6 }) {
          ForEach(item.review.images, (img: string, idx: number) => {
            Image(img)
              .width(56)
              .height(56)
              .borderRadius(6)
              .objectFit(ImageFit.Cover)
              .onClick((): void => {
                this.previewImages = item.review.images;
                this.previewIndex = idx;
                this.previewVisible = true;
              })
          }, (img: string, idx: number) => `${item.review.id}_img_${idx}`)
        }
        .width('100%')
      }

      Text(`👍 ${item.review.likes}`)
        .fontSize($r('app.float.caption_text'))
        .fontColor(ThemeUtil.textHint(this.darkMode))
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
    .shadow({ radius: 8, color: 'rgba(28,59,48,0.05)', offsetX: 0, offsetY: 2 })
    .onClick((): void => { this.pathStack.pushPathByName('DishDetail', item.review.dishId); })
  }

  /** 全屏大图预览 */
  @Builder ImagePreview() {
    Column() {
      Row() {
        Text(`${this.previewIndex + 1} / ${this.previewImages.length}`)
          .fontSize(14)
          .fontColor(Color.White)
          .layoutWeight(1)
        Text('✕')
          .fontSize(20)
          .fontColor(Color.White)
          .padding(8)
          .onClick((): void => { this.previewVisible = false; })
      }
      .width('100%')
      .padding({ left: 16, right: 8, top: 12 })

      Swiper() {
        ForEach(this.previewImages, (img: string) => {
          Image(img)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
        }, (img: string, idx: number) => `preview_${idx}_${img}`)
      }
      .index($$this.previewIndex)
      .indicator(false)
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
