import { promptAction, display } from '@kit.ArkUI';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { AchievementViewModel } from '../../viewmodel/AchievementViewModel';
import { TaskInfo, TaskRecord, TaskType, TaskConstants, DateUtils, AchievementInfo, Logger, Constants } from 'common';
import { AchievementDialog } from '../dialog/AchievementDialog';
import { TaskListItem } from './TaskListItem';
import { ProgressRing } from './ProgressRing';
import { WeekCalendar } from './WeekCalendar';
import { router } from '@kit.ArkUI';

@Component
export struct HomeTab {
  @Provide('homeVM') homeVM: HomeViewModel = new HomeViewModel();
  @StorageLink('taskList') taskList: TaskInfo[] = [];
  @StorageLink('todayRecords') todayRecords: TaskRecord[] = [];
  @StorageLink('streakDays') streakDays: number = 0;
  @StorageLink('todayAllDone') todayAllDone: boolean = false;
  @Watch('onAchDialogShow') @StorageLink('achDialogShow') achDialogShow: boolean = false;
  @StorageLink('achDialogDays') achDialogDays: number = 0;
  @State achDialogCounter: number = 0;
  private achDialogId: number = -1;
  @State showClockInDialog: boolean = false;
  @State clockInTaskType: TaskType = TaskType.GETUP;
  @State calSelectedDate: string = DateUtils.today();
  @State showTaskActionSheet: boolean = false;
  @State actionSheetTaskType: TaskType = TaskType.GETUP;
  @StorageLink('statusBarHeight') statusBarHeight: number = 0;
  @State topSafeHeight: number = 0;

  aboutToAppear(): void {
    AppStorage.setOrCreate('achDialogShow', false);
    AppStorage.setOrCreate('achDialogScale', 0.3);
    AppStorage.setOrCreate('achDialogOpacity', 0);
    this.calcTopSafeHeight();
    this.loadData();
  }

  private calcTopSafeHeight(): void {
    try {
      const d: display.Display = display.getDefaultDisplaySync();
      this.topSafeHeight = Math.floor(d.height * Constants.TOP_SAFE_AREA_RATIO);
    } catch (e) {
      this.topSafeHeight = 40;
    }
  }

  onAchDialogShow(): void {
    if (this.achDialogShow) {
      const list: AchievementInfo[] = AppStorage.get<AchievementInfo[]>('achievementList') || [];
      let icon: Resource = $r('app.media.ic_badge_3_on');
      for (const info of list) {
        if (info.days === this.achDialogDays) {
          icon = info.iconOn;
          break;
        }
      }
      AppStorage.set('achDialogIcon', icon);
      AppStorage.set('achDialogScale', 0.3);
      AppStorage.set('achDialogOpacity', 0);
      this.achDialogCounter++;
      promptAction.openCustomDialog({
        builder: this.achievementDialogBuilder(),
        autoCancel: false,
        alignment: DialogAlignment.Center
      }).then((dialogId: number) => {
        this.achDialogId = dialogId;
        animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
          AppStorage.set('achDialogScale', 1.0);
          AppStorage.set('achDialogOpacity', 1.0);
        });
      });
    } else {
      if (this.achDialogId >= 0) {
        promptAction.closeCustomDialog(this.achDialogId);
        this.achDialogId = -1;
      }
      const achVM: AchievementViewModel = new AchievementViewModel();
      setTimeout(() => {
        achVM.loadAchievements();
      }, 100);
    }
  }

  @Builder
  achievementDialogBuilder(): void {
    AchievementDialog()
  }

  private async loadData(): Promise<void> {
    try {
      await this.homeVM.loadTodayTasks();
    } catch (e) {
      Logger.error('HomeTab loadTodayTasks failed');
    }
  }

  private getOpenTaskCount(): number {
    let count: number = 0;
    for (const t of this.taskList) {
      if (t.isOpen) {
        count++;
      }
    }
    return count;
  }

  private getProgress(): number {
    const total: number = this.getOpenTaskCount();
    if (total === 0) {
      return 0;
    }
    let done: number = 0;
    for (const r of this.todayRecords) {
      if (r.isDone) {
        done++;
      }
    }
    return Math.floor(done * 100 / total);
  }

  private findRecord(taskType: TaskType): TaskRecord | null {
    for (const r of this.todayRecords) {
      if (r.taskType === taskType) {
        return r;
      }
    }
    return null;
  }

  private recordIsDone(taskType: TaskType): boolean {
    const r: TaskRecord | null = this.findRecord(taskType);
    return r !== null && r.isDone;
  }

  private recordFinNum(taskType: TaskType): number {
    const r: TaskRecord | null = this.findRecord(taskType);
    return r !== null ? r.finNum : 0;
  }

  private recordTargetValue(taskType: TaskType): number {
    const r: TaskRecord | null = this.findRecord(taskType);
    return r !== null ? r.targetValue : 1;
  }

  private hasRecord(taskType: TaskType): boolean {
    return this.findRecord(taskType) !== null;
  }

  private getOpenTasks(): TaskInfo[] {
    const openTasks: TaskInfo[] = [];
    for (const t of this.taskList) {
      if (t.isOpen) {
        openTasks.push(t);
      }
    }
    return openTasks;
  }

  private openTaskActionSheet(task: TaskInfo): void {
    this.actionSheetTaskType = task.taskType;
    this.showTaskActionSheet = true;
  }

  private confirmDeleteTask(taskType: TaskType): void {
    AlertDialog.show({
      title: '删除任务',
      message: '确定要删除该任务吗？历史打卡记录将保留。',
      autoCancel: true,
      confirm: {
        value: '确认',
        action: async () => {
          try {
            await this.homeVM.deleteTask(taskType);
          } catch (e) {
            Logger.error('HomeTab deleteTask failed');
          }
        }
      }
    });
  }

  build(): void {
    Stack() {
      Column() {
        Stack() {
          Image($r('app.media.ic_home_bg'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
          Column() {
            Text($r('app.string.healthy_life'))
              .fontSize($r('app.float.default_26'))
              .fontColor('#000000')
              .fontWeight(FontWeight.Bold)
            ProgressRing({ progress: this.getProgress() })
              .margin({ top: $r('app.float.default_10') })
            Text($r('app.string.target_progress'))
              .fontSize($r('app.float.default_16'))
              .fontColor('#000000')
              .margin({ top: $r('app.float.default_2') })
          }
          .width('100%')
          .height('100%')
          .padding({ top: this.topSafeHeight })
        }
        .width('100%')
        .height($r('app.float.default_220'))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

        Column() {
          WeekCalendar({ selectedDate: $calSelectedDate })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius($r('app.float.default_12'))
        .margin({ left: $r('app.float.default_12'), right: $r('app.float.default_12'), top: $r('app.float.default_12') })
        .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })

        Text($r('app.string.task_list'))
          .fontSize($r('app.float.default_20'))
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .margin({
            left: $r('app.float.default_16'),
            right: $r('app.float.default_16'),
            top: $r('app.float.default_8'),
            bottom: $r('app.float.default_4')
          })

        Column() {
          if (this.getOpenTaskCount() === 0) {
            Column() {
              Image($r('app.media.ic_no_data'))
                .width($r('app.float.default_88'))
                .height($r('app.float.default_88'))
              Text($r('app.string.no_task'))
                .fontSize($r('app.float.default_14'))
                .fontColor('#999999')
                .margin({ top: $r('app.float.default_8') })
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .layoutWeight(1)
          } else {
            List() {
              ForEach(this.getOpenTasks(), (task: TaskInfo) => {
                ListItem() {
                  TaskListItem({
                    task: task,
                    hasRecord: this.hasRecord(task.taskType),
                    isDone: this.recordIsDone(task.taskType),
                    finNum: this.recordFinNum(task.taskType),
                    targetValue: this.recordTargetValue(task.taskType),
                    onItemClick: (t: TaskInfo) => {
                      this.clockInTaskType = t.taskType;
                      this.showClockInDialog = true;
                    },
                    onItemLongPress: (t: TaskInfo) => {
                      this.openTaskActionSheet(t);
                    }
                  })
                }
              }, (task: TaskInfo) => {
                return task.taskType.toString();
              })
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('#00000000')
            .padding({ top: $r('app.float.default_8'), bottom: $r('app.float.default_60') })
          }
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F2F3F5')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F2F3F5')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      Stack() {
        Text('+')
          .fontSize($r('app.float.default_28'))
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
      }
      .width($r('app.float.default_56'))
      .height($r('app.float.default_56'))
      .borderRadius($r('app.float.default_28'))
      .backgroundColor('#2563EB')
      .markAnchor({ x: '50%', y: '0%' })
      .position({ x: '50%', y: '90%' })
      .shadow({
        radius: 8,
        color: '#332563EB',
        offsetX: 0,
        offsetY: 2
      })
      .onClick(() => {
        router.pushUrl({ url: 'pages/TaskAddPage' });
      })
      .bindContentCover($$this.showTaskActionSheet, this.taskActionSheetBuilder())
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F5')
    .bindContentCover($$this.showClockInDialog, this.clockInDialogBuilder())
  }

  @Builder
  clockInDialogBuilder(): void {
    Column() {
      Stack() {
        Image(TaskConstants.getMeta(this.clockInTaskType).dialogIcon)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius($r('app.float.default_16'))

        Column() {
          Blank()
            .layoutWeight(1)

          Text(TaskConstants.getMeta(this.clockInTaskType).name)
            .fontSize($r('app.float.default_20'))
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
            .margin({ left: $r('app.float.default_40') })
            .margin({ bottom: $r('app.float.default_24') })

          Button($r('app.string.clock_in'))
            .fontSize($r('app.float.default_16'))
            .fontColor('#FFFFFF')
            .backgroundColor('#4DFFFFFF')
            .borderRadius($r('app.float.default_20'))
            .width('70%')
            .height($r('app.float.default_44'))
            .margin({ bottom: $r('app.float.default_24') })
            .onClick(async () => {
              this.showClockInDialog = false;
              try {
                await this.homeVM.clockIn(this.clockInTaskType);
              } catch (e) {
                Logger.error('HomeTab clockIn failed');
              }
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

  @Builder
  taskActionSheetBuilder(): void {
    Column() {
      Column() {
        Image(TaskConstants.getMeta(this.actionSheetTaskType).taskIcon)
          .width($r('app.float.default_40'))
          .height($r('app.float.default_40'))
          .objectFit(ImageFit.Contain)
          .margin({ top: $r('app.float.default_24') })

        Text(TaskConstants.getMeta(this.actionSheetTaskType).name)
          .fontSize($r('app.float.default_20'))
          .fontColor('#333333')
          .fontWeight(FontWeight.Bold)
          .margin({ top: $r('app.float.default_12') })

        Row() {
          Button('删除')
            .fontSize($r('app.float.default_16'))
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .height($r('app.float.default_40'))
            .borderRadius($r('app.float.default_20'))
            .backgroundColor('#F5F5F5')
            .layoutWeight(1)
            .onClick(() => {
              this.showTaskActionSheet = false;
              this.confirmDeleteTask(this.actionSheetTaskType);
            })

          Button('编辑')
            .fontSize($r('app.float.default_16'))
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .height($r('app.float.default_40'))
            .borderRadius($r('app.float.default_20'))
            .backgroundColor('#F5F5F5')
            .layoutWeight(1)
            .margin({ left: $r('app.float.default_12') })
            .onClick(() => {
              this.showTaskActionSheet = false;
              router.pushUrl({
                url: 'pages/TaskEditPage',
                params: { taskType: this.actionSheetTaskType, isAdd: false }
              });
            })

          Button('取消')
            .fontSize($r('app.float.default_16'))
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .height($r('app.float.default_40'))
            .borderRadius($r('app.float.default_20'))
            .backgroundColor('#F5F5F5')
            .layoutWeight(1)
            .margin({ left: $r('app.float.default_12') })
            .onClick(() => {
              this.showTaskActionSheet = false;
            })
        }
        .width('100%')
        .margin({ top: $r('app.float.default_24') })
        .padding({ left: $r('app.float.default_16'), right: $r('app.float.default_16'), bottom: $r('app.float.default_24') })
      }
      .width('80%')
      .backgroundColor('#FFFFFF')
      .borderRadius($r('app.float.default_16'))
      .alignItems(HorizontalAlign.Center)
      .hitTestBehavior(HitTestMode.Default)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.showTaskActionSheet = false;
    })
  }
}
