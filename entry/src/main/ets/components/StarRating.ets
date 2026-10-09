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
    // 图标仍用应用图标位图；位图无法用 fillColor 着色（原「1 星与 5 星相同」的根因），
    // 改用 opacity 区分点亮(1.0)与未点亮(0.25)，保证 1~5 星可分辨
    Image($r('app.media.startIcon'))
      .width(this.starSize)
      .height(this.starSize)
      .objectFit(ImageFit.Contain)
      .opacity(this.rating - idx >= 0.5 ? 1 : 0.25)
      .onClick((): void => {
        if (!this.readonly) {
          this.doStarChange(idx + 1);
        }
      })
  }
}
