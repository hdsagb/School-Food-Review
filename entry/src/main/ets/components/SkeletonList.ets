/**
 * 菜单加载骨架屏：模拟 DishCard 布局的占位卡片，带呼吸闪烁动画
 */
import { ThemeUtil } from '../utils/ThemeUtil';

@Component
export struct SkeletonList {
  count: number = 4;
  @State pulse: boolean = false;
  @StorageLink('darkMode') darkMode: boolean = false;

  private indices(): number[] {
    const arr: number[] = [];
    for (let i = 0; i < this.count; i++) {
      arr.push(i);
    }
    return arr;
  }

  build() {
    Column({ space: 10 }) {
      ForEach(this.indices(), (i: number) => {
        this.SkeletonCard()
      }, (i: number) => `skeleton_${i}`)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 14, right: 14, top: 10, bottom: 14 })
    .onAppear((): void => { this.pulse = true; })
  }

  /** 骨架占位块，统一呼吸动画 */
  @Builder Block(w: Length, h: number, radius: number) {
    Column()
      .width(w)
      .height(h)
      .borderRadius(radius)
      .backgroundColor(ThemeUtil.skeletonBg(this.darkMode))
      .opacity(this.pulse ? 0.5 : 0.95)
      .animation({
        duration: 900,
        iterations: -1,
        playMode: PlayMode.Alternate,
        curve: Curve.EaseInOut
      })
  }

  @Builder SkeletonCard() {
    Row({ space: 12 }) {
      this.Block(92, 92, 14)

      Column({ space: 12 }) {
        Row() {
          this.Block('58%', 16, 6)
          this.Block(38, 14, 6)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        this.Block('46%', 12, 6)

        Row({ space: 6 }) {
          this.Block(34, 14, 6)
          this.Block(34, 14, 6)
        }
        .width('100%')

        Row() {
          this.Block('40%', 12, 6)
          this.Block(46, 16, 6)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .layoutWeight(1)
      .height(92)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(ThemeUtil.cardBg(this.darkMode))
    .borderRadius($r('app.float.corner_card'))
    .shadow({ radius: 10, color: 'rgba(28,59,48,0.06)', offsetX: 0, offsetY: 3 })
  }
}
