import { Api } from '../net/Api';
import { Dish } from '../model/Dish';
import { Review, ReviewPage, ReviewSortType } from '../model/Review';
import { StarRating } from '../components/StarRating';
import { StateView } from '../components/StateView';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { formatRelativeTime, dishImageSource } from '../utils/CommonUtil';
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct DishDetailPage {
  private pathStack: NavPathStack = new NavPathStack();
  @State dish: Dish | null = null;
  @State reviews: Review[] = [];
  @State page: number = 1;
  @State sort: ReviewSortType = ReviewSortType.LATEST;
  @State hasMore: boolean = false;
  @State loading: boolean = true;
  @State loadingMore: boolean = false;
  @StorageLink('favorites') favorites: string[] = [];
  @StorageLink('darkMode') darkMode: boolean = false;
  @State likedIds: string[] = [];
  @State previewVisible: boolean = false;
  @State previewImages: string[] = [];
  @State previewIndex: number = 0;
  private dishId: string = '';

  private async initPage(dishId: string): Promise<void> {
    this.dishId = dishId;
    await this.loadDish();
    await this.loadReviews(true);
    await Api.getFavorites();
    this.likedIds = await PreferencesUtil.getLikedReviews();
  }

  async loadDish(): Promise<void> {
    try {
      this.dish = await Api.getDishDetail(this.dishId);
    } catch (e) {
      console.error('loadDish error: ' + (e as Error).message);
    }
  }

  async loadReviews(reset: boolean): Promise<void> {
    if (reset) {
      this.loading = true;
    } else {
      if (this.loadingMore) return;
      this.loadingMore = true;
    }
    try {
      const p: number = reset ? 1 : this.page;
      const result: ReviewPage = await Api.getReviews(this.dishId, p, this.sort);
      this.reviews = reset ? result.list : this.reviews.concat(result.list);
      this.page = result.page + 1;
      this.hasMore = result.hasMore;
    } finally {
      this.loading = false;
      this.loadingMore = false;
    }
  }

  /** 点赞/取消点赞某条评价 */
  private async toggleLike(reviewId: string): Promise<void> {
    const liked = this.likedIds.includes(reviewId);
    const next: string[] = this.likedIds.slice();
    if (liked) {
      const i = next.indexOf(reviewId);
      if (i >= 0) next.splice(i, 1);
    } else {
      next.push(reviewId);
    }
    this.likedIds = next;

    const count = await Api.likeReview(reviewId);
    const idx = this.reviews.findIndex((r: Review): boolean => r.id === reviewId);
    if (idx >= 0) {
      const updated = this.reviews[idx];
      updated.likes = count;
      this.reviews.splice(idx, 1, updated);
    }
    await PreferencesUtil.saveLikedReviews(this.likedIds);
  }

  build() {
    NavDestination() {
      Column() {
        this.TopBar()

      if (!this.dish) {
        StateView({ state: 'loading' }).layoutWeight(1)
      } else {
        Column() {
          Scroll() {
            Column() {
              this.DishHeader(this.dish!)
              this.NutritionCard(this.dish!)
              this.ReviewSection()
            }
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)

          this.BottomActionBar()
        }
        .layoutWeight(1)
        .bindContentCover($$this.previewVisible, this.ImagePreview(), {
          modalTransition: ModalTransition.DEFAULT
        })
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
      const p = ctx.pathInfo.param as string;
      this.initPage(p ?? '');
    })
  }

  @Builder TopBar() {
    Row() {
      Text('←')
        .fontSize(24)
        .padding(8)
        .onClick((): void => { this.pathStack.pop(); })
      Text($r('app.string.dish_detail'))
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

  @Builder DishHeader(d: Dish) {
    Column({ space: 8 }) {
      Image(dishImageSource(d.image))
        .width('100%')
        .height(200)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)

      Text(d.name)
        .fontSize($r('app.float.title_large'))
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeUtil.textPrimary(this.darkMode))

      Row({ space: 8 }) {
        StarRating({ rating: d.rating, starSize: 16 })
        Text(d.rating.toFixed(1))
          .fontSize($r('app.float.body_text'))
          .fontColor(ThemeUtil.textSecondary(this.darkMode))
        Text(`${d.reviewCount} 条评价`)
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textHint(this.darkMode))
      }

      Text(`¥${d.price.toFixed(1)}`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeUtil.textPrice(this.darkMode))

      Text(`${d.canteenName} · ${d.stallName} · ${d.floor}楼`)
        .fontSize($r('app.float.caption_text'))
        .fontColor(ThemeUtil.textHint(this.darkMode))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
  }

  @Builder NutritionCard(d: Dish) {
    Column({ space: 8 }) {
      Text('营养信息').fontSize($r('app.float.title_small')).fontWeight(FontWeight.Medium)
      Row({ space: 12 }) {
        this.NutritionItem('热量', `${d.nutrition.calories} kcal`)
        this.NutritionItem('类型', d.nutrition.isVegetarian ? '素菜' : '荤菜')
        this.NutritionItem('过敏原', d.nutrition.allergens.length > 0 ? d.nutrition.allergens.join('、') : '无')
      }
    }
    .width('100%')
    .padding(16)
    .margin({ top: 8 })
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
  }

  @Builder NutritionItem(label: string, value: string) {
    Column({ space: 4 }) {
      Text(label).fontSize($r('app.float.caption_text')).fontColor(ThemeUtil.textHint(this.darkMode))
      Text(value).fontSize($r('app.float.body_text')).fontColor(ThemeUtil.textPrimary(this.darkMode))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder ReviewSection() {
    Column({ space: 8 }) {
      Row() {
        Text('用户评价').fontSize($r('app.float.title_small')).fontWeight(FontWeight.Medium).layoutWeight(1)
        Row({ space: 8 }) {
          Text('最新').fontSize(12).fontColor(this.sort === ReviewSortType.LATEST ? ThemeUtil.brandPrimary(this.darkMode) : ThemeUtil.textHint(this.darkMode))
            .onClick((): void => { this.sort = ReviewSortType.LATEST; this.loadReviews(true); })
          Text('最热').fontSize(12).fontColor(this.sort === ReviewSortType.HOTTEST ? ThemeUtil.brandPrimary(this.darkMode) : ThemeUtil.textHint(this.darkMode))
            .onClick((): void => { this.sort = ReviewSortType.HOTTEST; this.loadReviews(true); })
        }
      }
      .width('100%')

      if (this.reviews.length === 0 && !this.loading) {
        StateView({ state: 'empty' })
      } else {
        ForEach(this.reviews, (r: Review) => {
          this.ReviewItem(r)
        }, (r: Review) => `${r.id}_${r.likes}`)
        if (this.hasMore) {
          Button(this.loadingMore ? '加载中...' : '加载更多评价')
            .type(ButtonType.Capsule)
            .width('100%')
            .height(34)
            .fontSize($r('app.float.caption_text'))
            .backgroundColor(ThemeUtil.tagBg(this.darkMode))
            .fontColor(ThemeUtil.brandDeep(this.darkMode))
            .enabled(!this.loadingMore)
            .margin({ top: 8 })
            .onClick((): void => { this.loadReviews(false); })
        } else if (this.reviews.length > 0) {
          Text('— 没有更多了 —')
            .fontSize($r('app.float.caption_text'))
            .fontColor(ThemeUtil.textHint(this.darkMode))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 8 })
        }
      }
    }
    .width('100%')
    .padding(16)
    .margin({ top: 8 })
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
  }

  @Builder ReviewItem(r: Review) {
    Column({ space: 6 }) {
      Row() {
        Text(r.isAnonymous ? '匿名同学' : r.userNickname)
          .fontSize($r('app.float.body_text'))
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeUtil.textPrimary(this.darkMode))
          .layoutWeight(1)
        Text(formatRelativeTime(r.createTime))
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textHint(this.darkMode))
      }
      StarRating({ rating: r.rating, starSize: 12 })
      Text(r.content)
        .fontSize($r('app.float.body_text'))
        .fontColor(ThemeUtil.textSecondary(this.darkMode))
        .width('100%')
      if (r.images.length > 0) {
        Row({ space: 8 }) {
          ForEach(r.images, (img: string, idx: number) => {
            Image(img)
              .width(72)
              .height(72)
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
              .onClick((): void => {
                this.previewImages = r.images;
                this.previewIndex = idx;
                this.previewVisible = true;
              })
          }, (img: string, idx: number) => `${r.id}_img_${idx}`)
        }
        .width('100%')
      }
      Row() {
        Row({ space: 4 }) {
          Text('👍')
            .fontSize(12)
            .opacity(this.likedIds.includes(r.id) ? 1.0 : 0.6)
          Text(`${r.likes}`)
            .fontSize($r('app.float.caption_text'))
            .fontWeight(this.likedIds.includes(r.id) ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.likedIds.includes(r.id) ? ThemeUtil.brandDeep(this.darkMode) : ThemeUtil.textHint(this.darkMode))
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(12)
        .backgroundColor(this.likedIds.includes(r.id) ? ThemeUtil.tagBg(this.darkMode) : ThemeUtil.pageBg(this.darkMode))
        .onClick((): void => { this.toggleLike(r.id); })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: 0.5 }, color: ThemeUtil.divider(this.darkMode) })
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

  @Builder BottomActionBar() {
    Row({ space: 12 }) {
      Button(this.isFavoriteDish() ? '❤️ 已收藏' : $r('app.string.favorite'))
        .type(ButtonType.Capsule)
        .height(40)
        .backgroundColor(ThemeUtil.tagBg(this.darkMode))
        .fontColor(ThemeUtil.brandDeep(this.darkMode))
        .layoutWeight(1)
        .onClick((): void => { this.toggleFavorite(); })
      Button($r('app.string.write_review'))
        .type(ButtonType.Capsule)
        .height(40)
        .fontColor(Color.White)
        .layoutWeight(1)
        .linearGradient({
          angle: 135,
          colors: [
            [$r('app.color.brand_gradient_start'), 0.0],
            [$r('app.color.brand_primary_dark'), 1.0]
          ]
        })
        .shadow({ radius: 8, color: 'rgba(18,169,150,0.3)', offsetX: 0, offsetY: 3 })
        .onClick((): void => { this.goWriteReview(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .border({ width: { top: 0.5 }, color: ThemeUtil.divider(this.darkMode) })
  }

  private async toggleFavorite(): Promise<void> {
    const favs: string[] = await Api.toggleFavorite(this.dishId);
    this.favorites = favs;
    await PreferencesUtil.saveFavorites(favs);
  }

  /** 是否已收藏（从 AppStorage 共享状态派生，与首页实时同步） */
  private isFavoriteDish(): boolean {
    return this.favorites.includes(this.dishId);
  }

  private goWriteReview(): void {
    this.pathStack.pushPathByName('WriteReview', this.dishId);
  }
}
