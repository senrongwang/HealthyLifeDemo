import { TaskInfo, TaskFlag, TaskConstants } from 'common';

@Component
export struct TaskListItem {
  @ObjectLink task: TaskInfo;
  @Prop isDone: boolean = false;
  @Prop finNum: number = 0;
  onItemClick: (task: TaskInfo) => void = () => {};
  onItemLongPress: (task: TaskInfo) => void = () => {};

  private currentCount(): string {
    return this.finNum > 0 ? this.finNum.toString() : '--';
  }

  build(): void {
    Row() {
      Image(TaskConstants.getMeta(this.task.taskType).taskIcon)
        .width($r('app.float.default_40'))
        .height($r('app.float.default_40'))
        .objectFit(ImageFit.Contain)

      Text(TaskConstants.getMeta(this.task.taskType).name)
        .fontSize($r('app.float.default_16'))
        .fontColor('#333333')
        .margin({ left: $r('app.float.default_12') })
        .layoutWeight(1)

      if (this.isDone) {
        Text($r('app.string.was_done'))
          .fontSize($r('app.float.default_14'))
          .fontColor('#999999')
          .margin({ right: '5%' })
      } else if (this.task.flag === TaskFlag.MULTI) {
        Row() {
          Text(`${this.currentCount()} / ${this.task.targetValue} `)
            .fontSize($r('app.float.default_14'))
            .fontColor('#999999')
          if (TaskConstants.getMeta(this.task.taskType).unit !== undefined) {
            Text(TaskConstants.getMeta(this.task.taskType).unit)
              .fontSize($r('app.float.default_14'))
              .fontColor('#999999')
          }
        }
        .margin({ right: '5%' })
      } else {
        Text($r('app.string.task_opened'))
          .fontSize($r('app.float.default_14'))
          .fontColor('#999999')
          .margin({ right: '5%' })
      }
    }
    .width('100%')
    .height($r('app.float.default_56'))
    .padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16') })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius($r('app.float.default_8'))
    .shadow({ radius: 4, color: '#1A000000', offsetX: 0, offsetY: 1 })
    .margin({ left: $r('app.float.default_16'), right: $r('app.float.default_16'), top: $r('app.float.default_4'), bottom: $r('app.float.default_4') })
    .gesture(
      GestureGroup(
        GestureMode.Exclusive,
        TapGesture()
          .onAction(() => {
            this.onItemClick(this.task);
          }),
        LongPressGesture({ repeat: false, duration: 500 })
          .onAction(() => {
            this.onItemLongPress(this.task);
          })
      )
    )
  }
}
