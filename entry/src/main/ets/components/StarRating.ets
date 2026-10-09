import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct StarRating {
  @Prop rating: number = 0;
  @Prop readonly: boolean = true;
  @Prop starSize: number = 16;
  @StorageLink('darkMode') darkMode: boolean = false;
  doStarChange: (value: number) => void = (_v: number) => {};

  build() {
    Row({ space: 2 }) {
      ForEach([0, 1, 2, 3, 4], (idx: number) => {
        this.StarIcon(idx)
      }, (idx: number) => idx.toString())
    }
  }

  @Builder StarIcon(idx: number) {
    // 用文字星符：实心★表示点亮、空心☆表示未点亮；文字可直接着色（Image+fillColor 对位图无效）
    Text(this.rating - idx >= 0.5 ? '★' : '☆')
      .fontSize(this.starSize)
      .fontColor(this.getStarColor(idx))
      .onClick((): void => {
        if (!this.readonly) {
          this.doStarChange(idx + 1);
        }
      })
  }

  private getStarColor(idx: number): ResourceStr {
    const v = this.rating - idx;
    if (v >= 0.5) return $r('app.color.star_active');
    return ThemeUtil.starInactive(this.darkMode);
  }
}
