import { promptAction } from '@kit.ArkUI';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { AchievementViewModel } from '../../viewmodel/AchievementViewModel';
import { TaskInfo, TaskRecord, TaskType, TaskConstants, DateUtils, AchievementInfo, Logger } from 'common';
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

  aboutToAppear(): void {
    AppStorage.setOrCreate('achDialogShow', false);
    AppStorage.setOrCreate('achDialogScale', 0.3);
    AppStorage.setOrCreate('achDialogOpacity', 0);
    this.loadData();
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

  private getOpenTasks(): TaskInfo[] {
    const openTasks: TaskInfo[] = [];
    for (const t of this.taskList) {
      if (t.isOpen) {
        openTasks.push(t);
      }
    }
    return openTasks;
  }

  build(): void {
    Stack() {
      Column() {
        Stack() {
          Image(this.todayAllDone ? $r('app.media.ic_home_all_done') : $r('app.media.ic_home_bg'))
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
            Text(this.streakDays.toString())
              .fontSize($r('app.float.default_20'))
              .fontColor('#000000')
              .fontWeight(FontWeight.Bold)
              .margin({ top: $r('app.float.default_4') })
            Text($r('app.string.target_progress'))
              .fontSize($r('app.float.default_12'))
              .fontColor('#666666')
              .margin({ top: $r('app.float.default_2') })
          }
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .height($r('app.float.default_220'))

        WeekCalendar({ selectedDate: $calSelectedDate })

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
                    record: this.findRecord(task.taskType),
                    onItemClick: (t: TaskInfo) => {
                      this.clockInTaskType = t.taskType;
                      this.showClockInDialog = true;
                    }
                  })
                }
              }, (task: TaskInfo) => {
                return task.taskType.toString();
              })
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ top: $r('app.float.default_8'), bottom: $r('app.float.default_60') })
          }
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')

      Button() {
        Image($r('app.media.ic_home_add'))
          .width($r('app.float.default_24'))
          .height($r('app.float.default_24'))
      }
      .width($r('app.float.default_56'))
      .height($r('app.float.default_56'))
      .borderRadius($r('app.float.default_28'))
      .backgroundColor('#FF6B00')
      .position({ x: '80%', y: '85%' })
      .shadow({
        radius: 8,
        color: '#33000000',
        offsetX: 0,
        offsetY: 2
      })
      .onClick(() => {
        router.pushUrl({ url: 'pages/TaskAddPage' });
      })
    }
    .width('100%')
    .height('100%')
    .bindContentCover($$this.showClockInDialog, this.clockInDialogBuilder())
  }

  @Builder
  clockInDialogBuilder(): void {
    Column() {
      Column() {
        Image(TaskConstants.getMeta(this.clockInTaskType).dialogIcon)
          .width($r('app.float.default_120'))
          .height($r('app.float.default_120'))
          .objectFit(ImageFit.Contain)
          .margin({ top: $r('app.float.default_24') })

        Text(TaskConstants.getMeta(this.clockInTaskType).name)
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
          .onClick(async () => {
            this.showClockInDialog = false;
            try {
              await this.homeVM.clockIn(this.clockInTaskType);
            } catch (e) {
              Logger.error('HomeTab clockIn failed');
            }
          })

        Text($r('app.string.cancel'))
          .fontSize($r('app.float.default_14'))
          .fontColor('#999999')
          .margin({ top: $r('app.float.default_16'), bottom: $r('app.float.default_24') })
          .onClick(() => {
            this.showClockInDialog = false;
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
