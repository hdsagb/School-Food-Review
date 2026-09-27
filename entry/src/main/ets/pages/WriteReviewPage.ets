import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { Api } from '../net/Api';
import { ReviewDimensions, WriteReviewParam } from '../model/Review';
import { AppConfig } from '../config/AppConfig';
import { StarRating } from '../components/StarRating';
import { TopBar } from '../components/TopBar';
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct WriteReviewPage {
  private pathStack: NavPathStack = new NavPathStack();
  @State dishId: string = '';
  @State rating: number = 5;
  @State tasteScore: number = 5;
  @State portionScore: number = 5;
  @State valueScore: number = 5;
  @State content: string = '';
  @State images: string[] = [];
  @State isAnonymous: boolean = false;
  @State submitting: boolean = false;
  @StorageLink('darkMode') darkMode: boolean = false;

  build() {
    NavDestination() {
      Column() {
        TopBar({ title: '写评价', leftText: '取消', onBack: (): void => { this.pathStack.pop(); } })

      Scroll() {
        Column({ space: 16 }) {
          this.OverallRating()
          this.DimensionRating('口味', this.tasteScore, (v: number): void => { this.tasteScore = v; })
          this.DimensionRating('分量', this.portionScore, (v: number): void => { this.portionScore = v; })
          this.DimensionRating('性价比', this.valueScore, (v: number): void => { this.valueScore = v; })
          this.ContentInput()
          this.ImagePicker()
          this.AnonymousSwitch()
        }
        .padding(16)
      }
      .layoutWeight(1)

      this.SubmitBar()
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
      this.dishId = p ?? '';
    })
  }

  @Builder OverallRating() {
    Column({ space: 8 }) {
      Text('总体评分')
        .fontSize($r('app.float.title_small'))
        .fontWeight(FontWeight.Medium)
      Row({ space: 8 }) {
        StarRating({
          rating: this.rating,
          readonly: false,
          starSize: 32,
          doStarChange: (v: number): void => { this.rating = v; }
        })
        Text(`${this.rating}.0`)
          .fontSize($r('app.float.title_medium'))
          .fontColor(ThemeUtil.brandPrimary(this.darkMode))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
  }

  @Builder DimensionRating(label: string, score: number, onChange: (v: number) => void) {
    Row() {
      Text(label).fontSize($r('app.float.body_text')).layoutWeight(1)
      StarRating({
        rating: score,
        readonly: false,
        starSize: 20,
        doStarChange: onChange
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
  }

  @Builder ContentInput() {
    Column({ space: 8 }) {
      Text('评价内容')
        .fontSize($r('app.float.title_small'))
        .fontWeight(FontWeight.Medium)
      TextArea({ placeholder: '说说你的真实体验（10-500字）' })
        .width('100%')
        .height(120)
        .fontSize($r('app.float.body_text'))
        .borderRadius($r('app.float.corner_card'))
        .backgroundColor(ThemeUtil.pageBg(this.darkMode))
        .padding(12)
        .maxLength(AppConfig.MAX_REVIEW_LENGTH)
        .onChange((v: string): void => { this.content = v; })
      Row() {
        Text(`${this.content.length}/${AppConfig.MAX_REVIEW_LENGTH}`)
          .fontSize($r('app.float.caption_text'))
          .fontColor(ThemeUtil.textHint(this.darkMode))
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
  }

  @Builder ImagePicker() {
    Column({ space: 8 }) {
      Text('添加图片（可选）')
        .fontSize($r('app.float.title_small'))
        .fontWeight(FontWeight.Medium)
      Grid() {
        ForEach(this.images, (img: string, idx: number) => {
          GridItem() {
            Stack() {
              Image(img).width(72).height(72).borderRadius(8).objectFit(ImageFit.Cover)
              Text('×')
                .fontSize(16)
                .fontColor(Color.White)
                .backgroundColor(Color.Black)
                .width(20).height(20)
                .borderRadius(10)
                .position({ x: 60, y: -8 })
                .onClick((): void => { this.removeImage(idx); })
            }
          }
        }, (img: string, idx: number) => `${img}_${idx}`)
        if (this.images.length < AppConfig.MAX_REVIEW_IMAGES) {
          GridItem() {
            Column({ space: 4 }) {
              Text('+').fontSize(28).fontColor(ThemeUtil.textHint(this.darkMode))
              Text('添加图片').fontSize(10).fontColor(ThemeUtil.textHint(this.darkMode))
            }
            .width(72).height(72)
            .borderRadius(8)
            .backgroundColor(ThemeUtil.pageBg(this.darkMode))
            .justifyContent(FlexAlign.Center)
            .onClick((): void => { this.pickImage(); })
          }
        }
      }
      .columnsTemplate(`repeat(${Math.min(AppConfig.MAX_REVIEW_IMAGES, 4)}, 1fr)`)
      .rowsGap(8)
      .columnsGap(8)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
  }

  @Builder AnonymousSwitch() {
    Row() {
      Text('匿名发布').fontSize($r('app.float.body_text')).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: $$this.isAnonymous })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
  }

  @Builder SubmitBar() {
    Button($r('app.string.submit'))
      .width('90%')
      .height(44)
      .margin({ top: 8, bottom: 16 })
      .fontColor(Color.White)
      .borderRadius($r('app.float.corner_button'))
      .linearGradient({
        angle: 135,
        colors: [
          [$r('app.color.brand_gradient_start'), 0.0],
          [$r('app.color.brand_primary_dark'), 1.0]
        ]
      })
      .shadow({ radius: 8, color: 'rgba(18,169,150,0.3)', offsetX: 0, offsetY: 3 })
      .enabled(!this.submitting)
      .onClick((): void => { this.submit(); })
  }

  private async pickImage(): Promise<void> {
    if (this.images.length >= AppConfig.MAX_REVIEW_IMAGES) {
      this.getUIContext().getPromptAction().showToast({ message: `最多选 ${AppConfig.MAX_REVIEW_IMAGES} 张图片哦` });
      return;
    }
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const option: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: AppConfig.MAX_REVIEW_IMAGES - this.images.length
      };
      const result: photoAccessHelper.PhotoSelectResult = await picker.select(option);
      if (result.photoUris.length > 0) {
        this.images = this.images.concat(result.photoUris);
      }
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '图片选择失败：' + (e as Error).message });
    }
  }

  private removeImage(idx: number): void {
    this.images.splice(idx, 1);
  }

  private async submit(): Promise<void> {
    if (this.content.trim().length < AppConfig.MIN_REVIEW_LENGTH) {
      this.getUIContext().getPromptAction().showToast({ message: `评价至少 ${AppConfig.MIN_REVIEW_LENGTH} 字` });
      return;
    }
    this.submitting = true;
    try {
      // 先上传图片拿到真实 URL，再提交评价
      const urls: string[] = [];
      for (const img of this.images) {
        const url = await Api.uploadReviewImage(img);
        urls.push(url);
      }
      const dims: ReviewDimensions = new ReviewDimensions(this.tasteScore, this.portionScore, this.valueScore);
      const req: WriteReviewParam = {
        dishId: this.dishId,
        rating: this.rating,
        dimensions: dims,
        content: this.content,
        images: urls,
        isAnonymous: this.isAnonymous
      };
      await Api.submitReview(req);
      this.getUIContext().getPromptAction().showToast({ message: '评价已发布' });
      this.pathStack.pop();
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '提交失败：' + (e as Error).message });
    } finally {
      this.submitting = false;
    }
  }
}
