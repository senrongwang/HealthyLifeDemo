import { display, router } from '@kit.ArkUI';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { TaskType, TaskFlag, TaskInfo, TaskConstants, TaskMeta, TaskRepository, isReminderSupported, Logger, Constants } from 'common';
import { TargetPickerDialog } from '../view/dialog/TargetPickerDialog';

interface RouteParams {
  taskType: number;
  isAdd: boolean;
}

@Preview
@Entry
@Component
struct TaskEditPage {
  @StorageLink('taskList') taskList: TaskInfo[] = [];
  @State task: TaskInfo = new TaskInfo(TaskType.GETUP, TaskFlag.SINGLE);
  @State isAddMode: boolean = true;
  @State showPicker: boolean = false;
  @State pickerIsTimeMode: boolean = false;
  @State pickerInitVal1: number = 0;
  @State pickerInitVal2: number = 0;
  @State topSafeHeight: number = 0;

  aboutToAppear(): void {
    this.calcTopSafeHeight();
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
      this.pickerInitVal1 = parseInt(timeParts[0], 10);
      this.pickerInitVal2 = parseInt(timeParts[1], 10);
    }
  }

  private async saveTask(): Promise<void> {
    try {
      await TaskRepository.getInstance().upsertTask(this.task);
      const repo: TaskRepository = TaskRepository.getInstance();
      const tasks: TaskInfo[] = await repo.getTasks();
      AppStorage.setOrCreate('taskList', tasks);
      await this.syncSystemReminder();
      Logger.info(`TaskEditPage save taskType=${this.task.taskType}`);
      router.back();
    } catch (e) {
      Logger.error('TaskEditPage save failed');
    }
  }

  private async syncSystemReminder(): Promise<void> {
    if (!this.isReminderType()) {
      return;
    }

    const taskType: TaskType = this.task.taskType;
    const reminderIdKey: string = `reminderId_${taskType}`;
    const existingId: number | undefined = AppStorage.get<number>(reminderIdKey);
    if (existingId !== undefined) {
      try {
        await reminderAgentManager.cancelReminder(existingId);
      } catch (e) {
        Logger.error('TaskEditPage cancel reminder failed');
      }
    }

    if (!this.task.reminderEnable) {
      return;
    }

    const parts: string[] = this.task.reminderTime.split(':');
    const hour: number = parts.length >= 1 ? parseInt(parts[0], 10) : 8;
    const minute: number = parts.length >= 2 ? parseInt(parts[1], 10) : 0;
    const now: Date = new Date();

    let title: string = '健康提醒';
    let content: string = '该打卡啦';
    if (taskType === TaskType.GETUP) {
      title = '早起提醒';
      content = '该起床啦，开启美好的一天';
    } else if (taskType === TaskType.SLEEP) {
      title = '早睡提醒';
      content = '该睡觉啦，注意休息';
    }

    const reminder: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: now.getFullYear(),
        month: now.getMonth() + 1,
        day: now.getDate(),
        hour: hour,
        minute: minute,
        second: 0
      },
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      title: title,
      content: content,
      notificationId: taskType + 1,
      slotType: notificationManager.SlotType.SERVICE_INFORMATION
    };

    try {
      const newId: number = await reminderAgentManager.publishReminder(reminder);
      AppStorage.setOrCreate<number>(reminderIdKey, newId);
      Logger.info(`TaskEditPage publish reminder taskType=${taskType} time=${this.task.reminderTime} id=${newId}`);
    } catch (e) {
      Logger.error('TaskEditPage publish reminder failed');
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
                this.syncSystemReminder();
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
              this.pickerInitVal1 = parseInt(timeParts[0], 10);
              this.pickerInitVal2 = parseInt(timeParts[1], 10);
            }
            this.pickerIsTimeMode = true;
            this.showPicker = true;
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
            this.pickerInitVal1 = this.task.targetValue - 1;
            this.pickerIsTimeMode = false;
            this.showPicker = true;
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
        .backgroundColor('#0D59F6')
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
    .padding({ top: this.topSafeHeight })
    .bindSheet($$this.showPicker, this.pickerBuilder(), {
      height: 340,
      dragBar: true
    })
  }

  @Builder
  pickerBuilder(): void {
    TargetPickerDialog({
      isTimeMode: this.pickerIsTimeMode,
      initialValue1: this.pickerInitVal1,
      initialValue2: this.pickerInitVal2,
      onConfirm: (value1: number, value2: number) => {
        if (this.pickerIsTimeMode) {
          const hh: string = value1 < 10 ? '0' + value1 : '' + value1;
          const mm: string = value2 < 10 ? '0' + value2 : '' + value2;
          this.task.reminderTime = `${hh}:${mm}`;
          if (this.task.reminderEnable) {
            this.syncSystemReminder();
          }
        } else {
          this.task.targetValue = value1 + 1;
        }
        this.showPicker = false;
      },
      onCancel: () => {
        this.showPicker = false;
      }
    })
  }
}
