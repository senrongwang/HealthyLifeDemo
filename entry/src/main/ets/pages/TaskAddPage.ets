import { display, router } from '@kit.ArkUI';
import { TaskType, TaskInfo, TaskConstants, TaskMeta, Constants } from 'common';

interface TaskTypeItem {
  taskType: TaskType;
  name: Resource;
  icon: Resource;
}

@Entry
@Component
struct TaskAddPage {
  @StorageLink('taskList') taskList: TaskInfo[] = [];
  allTypes: TaskTypeItem[] = [];
  @State topSafeHeight: number = 0;

  aboutToAppear(): void {
    this.calcTopSafeHeight();
    this.allTypes = [];
    const types: TaskType[] = [TaskType.GETUP, TaskType.DRINK, TaskType.APPLE, TaskType.SMILE, TaskType.BRUSH, TaskType.SLEEP];
    for (const t of types) {
      const meta: TaskMeta = TaskConstants.getMeta(t);
      const item: TaskTypeItem = {
        taskType: t,
        name: meta.name,
        icon: meta.taskIcon
      };
      this.allTypes.push(item);
    }
  }

  private calcTopSafeHeight(): void {
    try {
      const d: display.Display = display.getDefaultDisplaySync();
      this.topSafeHeight = Math.floor(d.height * Constants.TOP_SAFE_AREA_RATIO);
    } catch (e) {
      this.topSafeHeight = 40;
    }
  }

  private isTaskAdded(taskType: TaskType): boolean {
    for (const t of this.taskList) {
      if (t.taskType === taskType && t.isOpen) {
        return true;
      }
    }
    return false;
  }

  build(): void {
    Column() {
      Row() {
        Image($r('app.media.ic_right_grey'))
          .width($r('app.float.default_24'))
          .height($r('app.float.default_24'))
          .onClick(() => {
            router.back();
          })

        Text($r('app.string.add_task'))
          .fontSize($r('app.float.default_20'))
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .margin({ left: $r('app.float.default_12') })
      }
      .width('100%')
      .height($r('app.float.default_56'))
      .padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16') })
      .alignItems(VerticalAlign.Center)

      List() {
        ForEach(this.allTypes, (item: TaskTypeItem) => {
          ListItem() {
            Row() {
              Image(item.icon)
                .width($r('app.float.default_40'))
                .height($r('app.float.default_40'))
                .objectFit(ImageFit.Contain)

              Text(item.name)
                .fontSize($r('app.float.default_16'))
                .fontColor(this.isTaskAdded(item.taskType) ? '#CCCCCC' : '#333333')
                .margin({ left: $r('app.float.default_12') })
                .layoutWeight(1)

              if (!this.isTaskAdded(item.taskType)) {
                Image($r('app.media.ic_right_grey'))
                  .width($r('app.float.default_16'))
                  .height($r('app.float.default_16'))
              }
            }
            .width('100%')
            .height($r('app.float.default_56'))
            .padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16') })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              if (!this.isTaskAdded(item.taskType)) {
                router.pushUrl({
                  url: 'pages/TaskEditPage',
                  params: { taskType: item.taskType, isAdd: true }
                });
              }
            })
          }
        }, (item: TaskTypeItem) => {
          return item.taskType.toString();
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F5')
    .padding({ top: this.topSafeHeight })
  }
}
