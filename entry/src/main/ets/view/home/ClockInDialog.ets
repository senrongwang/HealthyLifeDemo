import { TaskType, TaskConstants } from 'common';

@CustomDialog
export struct ClockInDialog {
  controller: CustomDialogController;
  taskType: TaskType = TaskType.GETUP;
  onClockIn: (type: TaskType) => void = () => {};

  build(): void {
    Column() {
      Column() {
        Image(TaskConstants.getMeta(this.taskType).dialogIcon)
          .width($r('app.float.default_120'))
          .height($r('app.float.default_120'))
          .objectFit(ImageFit.Contain)
          .margin({ top: $r('app.float.default_24') })

        Text(TaskConstants.getMeta(this.taskType).name)
          .fontSize($r('app.float.default_20'))
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .margin({ top: $r('app.float.default_16') })

        Button($r('app.string.clock_in'))
          .fontSize($r('app.float.default_16'))
          .fontColor('#FFFFFF')
          .backgroundColor('#FF6B00')
          .borderRadius($r('app.float.default_24'))
          .width($r('app.float.default_132'))
          .height($r('app.float.default_40'))
          .margin({ top: $r('app.float.default_24') })
          .onClick(() => {
            this.onClockIn(this.taskType);
            this.controller.close();
          })

        Text($r('app.string.cancel'))
          .fontSize($r('app.float.default_14'))
          .fontColor('#999999')
          .margin({ top: $r('app.float.default_16') })
          .margin({ bottom: $r('app.float.default_24') })
          .onClick(() => {
            this.controller.close();
          })
      }
      .width('80%')
      .backgroundColor('#FFFFFF')
      .borderRadius($r('app.float.default_16'))
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
