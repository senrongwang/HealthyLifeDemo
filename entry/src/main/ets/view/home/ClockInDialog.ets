import { TaskType, TaskConstants } from 'common';

@CustomDialog
export struct ClockInDialog {
  controller: CustomDialogController;
  taskType: TaskType = TaskType.GETUP;
  onClockIn: (type: TaskType) => void = () => {};

  build(): void {
    Column() {
      Stack() {
        Image(TaskConstants.getMeta(this.taskType).dialogIcon)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius($r('app.float.default_16'))

        Column() {
          Blank()
            .layoutWeight(1)

          Text(TaskConstants.getMeta(this.taskType).name)
            .fontSize($r('app.float.default_20'))
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
            .margin({ left: $r('app.float.default_32') })
            .margin({ bottom: $r('app.float.default_24') })

          Button($r('app.string.clock_in'))
            .fontSize($r('app.float.default_16'))
            .fontColor('#FFFFFF')
            .backgroundColor('#4DFFFFFF')
            .borderRadius($r('app.float.default_20'))
            .width('70%')
            .height($r('app.float.default_44'))
            .margin({ bottom: $r('app.float.default_24') })
            .onClick(() => {
              this.onClockIn(this.taskType);
              this.controller.close();
            })
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('80%')
      .height($r('app.float.default_360'))
      .borderRadius($r('app.float.default_16'))
      .clip(true)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
