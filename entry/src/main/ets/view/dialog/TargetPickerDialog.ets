@Component
export struct TargetPickerDialog {
  isTimeMode: boolean = false;
  initialValue1: number = 0;
  initialValue2: number = 0;
  maxRange: number = 99;
  onConfirm: (value1: number, value2: number) => void = (_v1: number, _v2: number) => {};
  onCancel: () => void = () => {};

  private initIdx1: number = 0;
  private initIdx2: number = 0;
  private currentIdx1: number = 0;
  private currentIdx2: number = 0;
  private range1: string[] = [];
  private range2: string[] = [];

  aboutToAppear(): void {
    this.initIdx1 = this.initialValue1;
    this.initIdx2 = this.initialValue2;
    this.currentIdx1 = this.initialValue1;
    this.currentIdx2 = this.initialValue2;

    if (this.isTimeMode) {
      this.range1 = [];
      for (let i = 0; i <= 23; i++) {
        this.range1.push(i < 10 ? '0' + i : '' + i);
      }
      this.range2 = [];
      for (let i = 0; i <= 59; i++) {
        this.range2.push(i < 10 ? '0' + i : '' + i);
      }
    } else {
      this.range1 = [];
      for (let i = 1; i <= this.maxRange; i++) {
        this.range1.push('' + i);
      }
    }
  }

  build(): void {
    Column() {
      Text($r('app.string.target_setting'))
        .fontSize($r('app.float.default_18'))
        .fontColor('#333333')
        .fontWeight(FontWeight.Bold)
        .margin({ top: $r('app.float.default_24'), bottom: $r('app.float.default_8') })

      if (this.isTimeMode) {
        Row() {
          TextPicker({ range: this.range1, selected: this.initIdx1 })
            .onChange((value: string | string[], index: number | number[]) => {
              if (typeof index === 'number') {
                this.currentIdx1 = index;
              }
            })
            .canLoop(false)
            .width('50%')
            .height(200)
            .selectedTextStyle({ color: '#2563EB', font: { size: 20, weight: FontWeight.Bold } })
            .textStyle({ color: '#333333', font: { size: 16 } })
            .disappearTextStyle({ color: '#CCCCCC', font: { size: 14 } })

          TextPicker({ range: this.range2, selected: this.initIdx2 })
            .onChange((value: string | string[], index: number | number[]) => {
              if (typeof index === 'number') {
                this.currentIdx2 = index;
              }
            })
            .canLoop(false)
            .width('50%')
            .height(200)
            .selectedTextStyle({ color: '#2563EB', font: { size: 20, weight: FontWeight.Bold } })
            .textStyle({ color: '#333333', font: { size: 16 } })
            .disappearTextStyle({ color: '#CCCCCC', font: { size: 14 } })
        }
        .width('100%')
      } else {
        TextPicker({ range: this.range1, selected: this.initIdx1 })
          .onChange((value: string | string[], index: number | number[]) => {
            if (typeof index === 'number') {
              this.currentIdx1 = index;
            }
          })
          .canLoop(false)
          .width('100%')
          .height(200)
          .selectedTextStyle({ color: '#2563EB', font: { size: 20, weight: FontWeight.Bold } })
          .textStyle({ color: '#333333', font: { size: 16 } })
          .disappearTextStyle({ color: '#CCCCCC', font: { size: 14 } })
      }

      Divider()
        .strokeWidth(0.5)
        .color('#F0F0F0')
        .width('100%')
        .margin({ top: $r('app.float.default_4') })

      Row() {
        Text($r('app.string.cancel'))
          .fontSize($r('app.float.default_16'))
          .fontColor('#2563EB')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .height($r('app.float.default_48'))
          .onClick(() => {
            this.onCancel();
          })

        Text($r('app.string.confirm'))
          .fontSize($r('app.float.default_16'))
          .fontColor('#2563EB')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .height($r('app.float.default_48'))
          .onClick(() => {
            this.onConfirm(this.currentIdx1, this.currentIdx2);
          })
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
