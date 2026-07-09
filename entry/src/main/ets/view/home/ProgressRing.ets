@Component
export struct ProgressRing {
  progress: number = 0;
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
        .color('#FF6B00')
        .backgroundColor('#E0E0E0')

      Text(`${this.progress}%`)
        .fontSize($r('app.float.default_18'))
        .fontColor('#FF6B00')
        .fontWeight(FontWeight.Bold)
    }
    .width(this.ringSize)
    .height(this.ringSize)
  }
}
