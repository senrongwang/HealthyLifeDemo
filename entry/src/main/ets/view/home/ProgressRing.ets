@Component
export struct ProgressRing {
  @Prop progress: number = 0;
  ringSize: number = 100;
  strokeWidth: number = 8;

  build(): void {
    Stack() {
      Progress({ value: this.progress, total: 100, type: ProgressType.Ring })
        .width(this.ringSize)
        .height(this.ringSize)
        .style({
          strokeWidth: this.strokeWidth,
          scaleWidth: 0.9
        })
        .color('#0D59F6')
        .backgroundColor('#E0E0E0')

      Text(`${this.progress}%`)
        .fontSize($r('app.float.default_26'))
        .fontColor('#FF6B00')
        .fontWeight(FontWeight.Bold)
    }
    .width(this.ringSize)
    .height(this.ringSize)
  }
}
