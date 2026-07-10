@Component
export struct AchievementDialog {
  @StorageLink('achDialogIcon') achIcon: Resource = $r('app.media.ic_badge_3_on');
  @StorageLink('achDialogDays') achDays: number = 0;
  @State scaleValue: number = 0.3;
  @State opacityValue: number = 0;

  aboutToAppear(): void {
    animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
      this.scaleValue = 1.0;
      this.opacityValue = 1.0;
    });
  }

  build(): void {
    Column() {
      Column() {
        Image(this.achIcon)
          .width(80)
          .height(80)
          .objectFit(ImageFit.Contain)
          .scale({ x: this.scaleValue, y: this.scaleValue })
          .opacity(this.opacityValue)

        Text($r('app.string.achievement_level', this.achDays.toString()))
          .fontSize($r('app.float.default_18'))
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .margin({ top: $r('app.float.default_12') })

        Text($r('app.string.got_it'))
          .fontSize($r('app.float.default_14'))
          .fontColor('#FF6B00')
          .margin({ top: $r('app.float.default_20') })
          .onClick(() => {
            AppStorage.set('achDialogShow', false);
          })
      }
      .width(280)
      .padding({ top: 32, bottom: 24 })
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
