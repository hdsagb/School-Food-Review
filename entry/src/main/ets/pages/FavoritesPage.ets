import { Api } from '../net/Api';
import { Dish } from '../model/Dish';
import { StarRating } from '../components/StarRating';
import { StateView } from '../components/StateView';
import { TopBar } from '../components/TopBar';
import { dishImageSource } from '../utils/CommonUtil';
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct FavoritesPage {
  private pathStack: NavPathStack = new NavPathStack();
  @State dishes: Dish[] = [];
  @State loaded: boolean = false;
  @State refreshing: boolean = false;
  @StorageLink('darkMode') darkMode: boolean = false;

  private async loadData(): Promise<void> {
    try {
      this.dishes = await Api.getFavoriteDishes();
    } catch (e) {
      console.error('getFavoriteDishes error: ' + (e as Error).message);
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
        TopBar({ title: '我的收藏', onBack: (): void => { this.pathStack.pop(); } })

        if (!this.loaded) {
          Column() { StateView({ state: 'loading' }) }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
        } else if (this.dishes.length === 0) {
          Column() { StateView({ state: 'empty', message: '还没有收藏，去食堂逛逛吧' }) }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
        } else {
          Refresh({ refreshing: $$this.refreshing }) {
            List({ space: 10 }) {
              ForEach(this.dishes, (d: Dish) => {
                ListItem() {
                  this.FavoriteCard(d)
                }
              }, (d: Dish) => d.id)
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
    }
    .hideTitleBar(true)
    .backgroundColor(ThemeUtil.pageBg(this.darkMode))
    .onReady((ctx: NavDestinationContext) => {
      this.pathStack = ctx.pathStack;
      this.loadData();
    })
    .onShown((): void => { this.loadData(); })
  }

  @Builder FavoriteCard(d: Dish) {
    Row({ space: 12 }) {
      Image(dishImageSource(d.image))
        .width(72)
        .height(72)
        .borderRadius(12)
        .objectFit(ImageFit.Cover)

      Column({ space: 6 }) {
        Row() {
          Text(d.name)
            .fontSize($r('app.float.body_text'))
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeUtil.textPrimary(this.darkMode))
            .layoutWeight(1)
          Text(`¥${d.price.toFixed(1)}`)
            .fontSize($r('app.float.body_text'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.textPrice(this.darkMode))
        }
        .width('100%')

        Row({ space: 6 }) {
          StarRating({ rating: d.rating, starSize: 12 })
          Text(d.rating.toFixed(1))
            .fontSize($r('app.float.caption_text'))
            .fontColor(ThemeUtil.textHint(this.darkMode))
        }

        Text(`${d.canteenName} · ${d.stallName}`)
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textHint(this.darkMode))
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
    .shadow({ radius: 8, color: 'rgba(28,59,48,0.05)', offsetX: 0, offsetY: 2 })
    .onClick((): void => { this.pathStack.pushPathByName('DishDetail', d.id); })
  }
}
