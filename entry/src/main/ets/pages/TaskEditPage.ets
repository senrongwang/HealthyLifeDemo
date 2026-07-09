import { router } from '@kit.ArkUI';
import { TaskType, TaskFlag, TaskInfo, TaskConstants, TaskMeta, TaskRepository, isReminderSupported, Logger } from 'common';

interface RouteParams {
  taskType: number;
  isAdd: boolean;
}

@Entry
@Component
struct TaskEditPage {
  @StorageLink('taskList') taskList: TaskInfo[] = [];
  @State task: TaskInfo = new TaskInfo(TaskType.GETUP, TaskFlag.SINGLE);
  @State isAddMode: boolean = true;
  @State showTimePicker: boolean = false;
  @State tempHour: number = 8;
  @State tempMinute: number = 0;
  @State showTargetDialog: boolean = false;
  @State tempTarget: string = '1';

  aboutToAppear(): void {
    const params: RouteParams = router.getParams() as RouteParams;
    if (params === undefined || params === null) {
      return;
    }
    const taskType: TaskType = params.taskType as TaskType;
    this.isAddMode = params.isAdd;

    if (this.isAddMode) {
      const meta: TaskMeta = TaskConstants.getMeta(taskType);
      this.task = new TaskInfo(taskType, meta.flag);
      this.task.isOpen = true;
    } else {
      for (const t of this.taskList) {
        if (t.taskType === taskType) {
          this.task = new TaskInfo(t.taskType, t.flag);
          this.task.isOpen = t.isOpen;
          this.task.targetValue = t.targetValue;
          this.task.reminderEnable = t.reminderEnable;
          this.task.reminderTime = t.reminderTime;
          break;
        }
      }
    }

    const timeParts: string[] = this.task.reminderTime.split(':');
    if (timeParts.length >= 2) {
      this.tempHour = parseInt(timeParts[0], 10);
      this.tempMinute = parseInt(timeParts[1], 10);
    }
  }

  private async saveTask(): Promise<void> {
    try {
      await TaskRepository.getInstance().upsertTask(this.task);
      const repo: TaskRepository = TaskRepository.getInstance();
      const tasks: TaskInfo[] = await repo.getTasks();
      AppStorage.setOrCreate('taskList', tasks);
      Logger.info(`TaskEditPage save taskType=${this.task.taskType}`);
      router.back();
    } catch (e) {
      Logger.error('TaskEditPage save failed');
    }
  }

  private isReminderType(): boolean {
    return isReminderSupported(this.task.taskType);
  }

  private isMultiType(): boolean {
    return this.task.flag === TaskFlag.MULTI;
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

        Text($r('app.string.edit_task'))
          .fontSize($r('app.float.default_20'))
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .margin({ left: $r('app.float.default_12') })
      }
      .width('100%')
      .height($r('app.float.default_56'))
      .padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16') })
      .alignItems(VerticalAlign.Center)

      Column() {
        Row() {
          Image(TaskConstants.getMeta(this.task.taskType).taskIcon)
            .width($r('app.float.default_40'))
            .height($r('app.float.default_40'))
            .objectFit(ImageFit.Contain)

          Text(TaskConstants.getMeta(this.task.taskType).name)
            .fontSize($r('app.float.default_18'))
            .fontColor('#333333')
            .fontWeight(FontWeight.Bold)
            .margin({ left: $r('app.float.default_12') })
            .layoutWeight(1)

          if (this.isReminderType()) {
            Toggle({ type: ToggleType.Switch, isOn: this.task.reminderEnable })
              .onChange((isOn: boolean) => {
                this.task.reminderEnable = isOn;
              })
          }
        }
        .width('100%')
        .height($r('app.float.default_56'))
        .padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16') })
        .alignItems(VerticalAlign.Center)

        if (this.isReminderType()) {
          Row() {
            Text($r('app.string.target_setting'))
              .fontSize($r('app.float.default_16'))
              .fontColor('#333333')
              .layoutWeight(1)

            Text(this.task.reminderTime)
              .fontSize($r('app.float.default_16'))
              .fontColor('#FF6B00')

            Image($r('app.media.ic_right_grey'))
              .width($r('app.float.default_16'))
              .height($r('app.float.default_16'))
              .margin({ left: $r('app.float.default_8') })
          }
          .width('100%')
          .height($r('app.float.default_48'))
          .padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16') })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            const timeParts: string[] = this.task.reminderTime.split(':');
            if (timeParts.length >= 2) {
              this.tempHour = parseInt(timeParts[0], 10);
              this.tempMinute = parseInt(timeParts[1], 10);
            }
            this.showTimePicker = true;
          })
        }

        if (this.isMultiType()) {
          Row() {
            Text($r('app.string.target_setting'))
              .fontSize($r('app.float.default_16'))
              .fontColor('#333333')
              .layoutWeight(1)

            Row() {
              Text(this.task.targetValue.toString())
                .fontSize($r('app.float.default_16'))
                .fontColor('#FF6B00')
              Text($r('app.string.unit_pre_day'))
                .fontSize($r('app.float.default_16'))
                .fontColor('#FF6B00')
            }

            Image($r('app.media.ic_right_grey'))
              .width($r('app.float.default_16'))
              .height($r('app.float.default_16'))
              .margin({ left: $r('app.float.default_8') })
          }
          .width('100%')
          .height($r('app.float.default_48'))
          .padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16') })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.tempTarget = this.task.targetValue.toString();
            this.showTargetDialog = true;
          })
        }
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius($r('app.float.default_12'))
      .margin({ left: $r('app.float.default_16'), right: $r('app.float.default_16'), top: $r('app.float.default_8') })

      Blank()

      Button($r('app.string.complete'))
        .fontSize($r('app.float.default_16'))
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6B00')
        .borderRadius($r('app.float.default_24'))
        .width('80%')
        .height($r('app.float.default_48'))
        .margin({ bottom: $r('app.float.default_32') })
        .onClick(() => {
          this.saveTask();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F5')
    .bindSheet($$this.showTimePicker, this.timePickerBuilder(), {
      height: 300,
      dragBar: true
    })
    .bindSheet($$this.showTargetDialog, this.targetDialogBuilder(), {
      height: 300,
      dragBar: true
    })
  }

  @Builder
  timePickerBuilder(): void {
    Column() {
      TimePicker({
        selected: new Date(2026, 0, 1, this.tempHour, this.tempMinute)
      })
        .onChange((value: TimePickerResult) => {
          this.tempHour = value.hour;
          this.tempMinute = value.minute;
        })

      Button($r('app.string.confirm'))
        .fontSize($r('app.float.default_16'))
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6B00')
        .borderRadius($r('app.float.default_24'))
        .width($r('app.float.default_132'))
        .height($r('app.float.default_40'))
        .margin({ top: $r('app.float.default_16') })
        .onClick(() => {
          const hh: string = this.tempHour < 10 ? '0' + this.tempHour : '' + this.tempHour;
          const mm: string = this.tempMinute < 10 ? '0' + this.tempMinute : '' + this.tempMinute;
          this.task.reminderTime = `${hh}:${mm}`;
          this.showTimePicker = false;
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  targetDialogBuilder(): void {
    Column() {
      Text($r('app.string.target_setting'))
        .fontSize($r('app.float.default_18'))
        .fontColor('#333333')
        .fontWeight(FontWeight.Bold)
        .margin({ top: $r('app.float.default_24') })

      TextInput({ text: this.tempTarget, placeholder: '1-99' })
        .type(InputType.Number)
        .width('60%')
        .height($r('app.float.default_40'))
        .margin({ top: $r('app.float.default_16') })
        .onChange((value: string) => {
          this.tempTarget = value;
        })

      Button($r('app.string.confirm'))
        .fontSize($r('app.float.default_16'))
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6B00')
        .borderRadius($r('app.float.default_24'))
        .width($r('app.float.default_132'))
        .height($r('app.float.default_40'))
        .margin({ top: $r('app.float.default_16') })
        .onClick(() => {
          const val: number = parseInt(this.tempTarget, 10);
          if (val >= 1 && val <= 99) {
            this.task.targetValue = val;
            this.showTargetDialog = false;
          }
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
