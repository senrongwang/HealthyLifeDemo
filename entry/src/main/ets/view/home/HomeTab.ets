import { promptAction } from '@kit.ArkUI';
import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { AchievementViewModel } from '../../viewmodel/AchievementViewModel';
import { TaskInfo, TaskRecord, AchievementInfo, Logger } from 'common';
import { AchievementDialog } from '../dialog/AchievementDialog';

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

  build(): void {
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
          Progress({ value: this.getProgress(), total: 100, type: ProgressType.Ring })
            .width($r('app.float.default_100'))
            .height($r('app.float.default_100'))
            .color('#FF6B00')
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
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height($r('app.float.default_220'))

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
        }
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
