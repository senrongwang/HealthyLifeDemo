import { display, router } from '@kit.ArkUI';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { calendarManager } from '@kit.CalendarKit';
import { abilityAccessCtrl, Permissions, PermissionRequestResult } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TaskType, TaskFlag, TaskInfo, TaskConstants, TaskMeta, TaskRepository, Logger, Constants } from 'common';
import { calendarMgr, appContext } from '../entryability/EntryAbility';
import { TargetPickerDialog } from '../view/dialog/TargetPickerDialog';

interface RouteParams {
  taskType: number;
  isAdd: boolean;
}

interface ReminderText {
  title: string;
  content: string;
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
      await this.syncReminder();
      Logger.info(`TaskEditPage save taskType=${this.task.taskType}`);
      router.back();
    } catch (e) {
      Logger.error('TaskEditPage save failed');
    }
  }

  private isAlarmType(): boolean {
    return this.task.taskType === TaskType.GETUP || this.task.taskType === TaskType.SLEEP;
  }

  private async syncReminder(): Promise<void> {
    if (this.isAlarmType()) {
      await this.syncSystemReminder();
    } else {
      await this.syncCalendarEvent();
    }
  }

  private async syncSystemReminder(): Promise<void> {
    if (!this.isAlarmType()) {
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
    const text: ReminderText = this.getReminderText();

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
      title: text.title,
      content: text.content,
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

  private async syncCalendarEvent(): Promise<void> {
    if (this.isAlarmType()) {
      return;
    }

    const taskType: TaskType = this.task.taskType;
    const eventIdKey: string = `calendarEventId_${taskType}`;
    const existingId: number | undefined = AppStorage.get<number>(eventIdKey);
    if (existingId !== undefined && existingId >= 0) {
      const calOld: calendarManager.Calendar | null = await this.getCalendar();
      if (calOld !== null) {
        try {
          await calOld.deleteEvent(existingId);
        } catch (e) {
          Logger.error('TaskEditPage delete calendar event failed');
        }
      }
    }
    AppStorage.setOrCreate<number>(eventIdKey, -1);

    if (!this.task.reminderEnable) {
      return;
    }

    if (!await this.ensureCalendarPermission()) {
      Logger.error('TaskEditPage calendar permission denied');
      return;
    }

    const cal: calendarManager.Calendar | null = await this.getCalendar();
    if (cal === null) {
      return;
    }

    const parts: string[] = this.task.reminderTime.split(':');
    const hour: number = parts.length >= 1 ? parseInt(parts[0], 10) : 8;
    const minute: number = parts.length >= 2 ? parseInt(parts[1], 10) : 0;
    const now: Date = new Date();
    const start: number = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour, minute, 0).getTime();
    const end: number = start + 60 * 60 * 1000;
    const text: ReminderText = this.getReminderText();

    const event: calendarManager.Event = {
      type: calendarManager.EventType.NORMAL,
      title: text.title,
      description: text.content,
      startTime: start,
      endTime: end,
      reminderTime: [0],
      recurrenceRule: {
        recurrenceFrequency: calendarManager.RecurrenceFrequency.DAILY,
        interval: 1
      }
    };

    try {
      const id: number = await cal.addEvent(event);
      AppStorage.setOrCreate<number>(eventIdKey, id);
      Logger.info(`TaskEditPage publish calendar event taskType=${taskType} time=${this.task.reminderTime} id=${id}`);
    } catch (e) {
      Logger.error('TaskEditPage publish calendar event failed');
    }
  }

  private getCalendar(): Promise<calendarManager.Calendar | null> {
    return new Promise<calendarManager.Calendar | null>((resolve: (c: calendarManager.Calendar | null) => void): void => {
      if (calendarMgr === null) {
        resolve(null);
        return;
      }
      calendarMgr.getCalendar((err: BusinessError, data: calendarManager.Calendar): void => {
        if (err) {
          Logger.error('TaskEditPage getCalendar failed');
          resolve(null);
        } else {
          resolve(data);
        }
      });
    });
  }

  private async ensureCalendarPermission(): Promise<boolean> {
    if (appContext === null) {
      return false;
    }
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const perms: Array<Permissions> = ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'];
    try {
      const result: PermissionRequestResult = await atManager.requestPermissionsFromUser(appContext, perms);
      for (const r of result.authResults) {
        if (r !== 0) {
          return false;
        }
      }
      return true;
    } catch (e) {
      Logger.error('TaskEditPage request calendar permission failed');
      return false;
    }
  }

  private getReminderText(): ReminderText {
    switch (this.task.taskType) {
      case TaskType.GETUP:
        return { title: '早起提醒', content: '该起床啦，开启美好的一天' };
      case TaskType.SLEEP:
        return { title: '早睡提醒', content: '该睡觉啦，注意休息' };
      case TaskType.DRINK:
        return { title: '喝水提醒', content: '该喝水啦，记得补充水分' };
      case TaskType.APPLE:
        return { title: '吃苹果提醒', content: '一天一苹果，医生远离我' };
      case TaskType.SMILE:
        return { title: '每日微笑提醒', content: '笑一笑，十年少' };
      case TaskType.BRUSH:
        return { title: '刷牙提醒', content: '该刷牙啦，保持口腔清洁' };
      default:
        return { title: '健康提醒', content: '该打卡啦' };
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
    return true;
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
                this.syncReminder();
              })
          }
        }
        .width('100%')
        .height($r('app.float.default_56'))
        .padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16') })
        .alignItems(VerticalAlign.Center)

        if (this.isReminderType()) {
          Row() {
            Text('提醒时间')
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
            this.syncReminder();
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
