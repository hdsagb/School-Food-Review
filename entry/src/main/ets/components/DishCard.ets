import { Dish } from '../model/Dish';
import { StarRating } from './StarRating';
import { dishImageSource } from '../utils/CommonUtil';
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct DishCard {
  @Prop dishData: Dish = new Dish();
  @Prop isFavorite: boolean = false;
  @StorageLink('darkMode') darkMode: boolean = false;
  doTap: () => void = () => {};
  doFavorite: () => void = () => {};

  private tagBg(tag: string): ResourceStr {
    return (tag === '辣' || tag === '荤') ? ThemeUtil.tagWarmBg(this.darkMode) : ThemeUtil.tagBg(this.darkMode);
  }

  private tagText(tag: string): ResourceStr {
    return (tag === '辣' || tag === '荤') ? ThemeUtil.tagWarmText(this.darkMode) : ThemeUtil.tagText(this.darkMode);
  }

  /** 卡片点击：售罄时提示，不进入详情 */
  private handleTap(): void {
    if (this.dishData.soldOut) {
      this.getUIContext().getPromptAction().showToast({ message: '该菜品已售罄，先看看别的吧' });
      return;
    }
    this.doTap();
  }

  build() {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(dishImageSource(this.dishData.image))
          .width(92)
          .height(92)
          .borderRadius(14)
          .objectFit(ImageFit.Cover)

        if (this.dishData.soldOut) {
          Text($r('app.string.sold_out'))
            .fontSize(10)
            .fontColor(ThemeUtil.soldOutText(this.darkMode))
            .backgroundColor('rgba(255,255,255,0.92)')
            .borderRadius(6)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .position({ x: 4, y: 4 })
        }

        // 收藏爱心：与图片同级覆盖，点击不会误触进详情
        Text(this.isFavorite ? '❤️' : '🤍')
          .fontSize(13)
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .backgroundColor('rgba(255,255,255,0.88)')
          .borderRadius(12)
          .margin({ top: 4, right: 4 })
          .shadow({ radius: 4, color: 'rgba(28,59,48,0.15)', offsetX: 0, offsetY: 1 })
          .onClick((): void => { this.doFavorite(); })
      }
      .width(92)
      .height(92)

      Column({ space: 5 }) {
        Row({ space: 6 }) {
          Text(this.dishData.name)
            .fontSize($r('app.float.title_medium'))
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeUtil.textPrimary(this.darkMode))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.dishData.isSignature) {
            Text($r('app.string.signature'))
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeUtil.accentGoldText(this.darkMode))
              .backgroundColor(ThemeUtil.accentGoldBg(this.darkMode))
              .borderRadius(6)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
        }
        .width('100%')

        Row({ space: 4 }) {
          StarRating({ rating: this.dishData.rating, starSize: 12 })
          Text(this.dishData.rating.toFixed(1))
            .fontSize($r('app.float.caption_text'))
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeUtil.brandDeep(this.darkMode))
          Text(`(${this.dishData.reviewCount}条)`)
            .fontSize($r('app.float.caption_text'))
            .fontColor(ThemeUtil.textHint(this.darkMode))
        }
        .width('100%')

        Row({ space: 4 }) {
          ForEach(this.dishData.tags.slice(0, 3), (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor(this.tagText(tag))
              .backgroundColor(this.tagBg(tag))
              .borderRadius(6)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }, (tag: string) => tag)
        }
        .width('100%')

        Row() {
          Text(`${this.dishData.stallName} · ${this.dishData.floor}楼`)
            .fontSize($r('app.float.caption_text'))
            .fontColor(ThemeUtil.textHint(this.darkMode))
            .layoutWeight(1)

          Row({ space: 1 }) {
            Text('¥')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeUtil.textPrice(this.darkMode))
            Text(this.dishData.price.toFixed(1))
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeUtil.textPrice(this.darkMode))
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
      }
      .layoutWeight(1)
      .height(92)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .opacity(this.dishData.soldOut ? 0.6 : 1.0)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
    .shadow({ radius: 10, color: 'rgba(28,59,48,0.06)', offsetX: 0, offsetY: 3 })
    .onClick((): void => { this.handleTap(); })
  }
}
