import { HomeViewModel } from '../../viewmodel/HomeViewModel';
import { TaskInfo, TaskRecord, Logger } from 'common';

@Component
export struct HomeTab {
  @Provide('homeVM') homeVM: HomeViewModel = new HomeViewModel();
  @StorageLink('taskList') taskList: TaskInfo[] = [];
  @StorageLink('todayRecords') todayRecords: TaskRecord[] = [];
  @StorageLink('streakDays') streakDays: number = 0;
  @StorageLink('todayAllDone') todayAllDone: boolean = false;

  aboutToAppear(): void {
    this.loadData();
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
            .fontSize($r('app.float.default_22'))
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
          Progress({ value: this.getProgress(), total: 100, type: ProgressType.Ring })
            .width($r('app.float.default_100'))
            .height($r('app.float.default_100'))
            .color('#FF6B00')
            .margin({ top: $r('app.float.default_10') })
          Text(this.streakDays.toString())
            .fontSize($r('app.float.default_16'))
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .margin({ top: $r('app.float.default_4') })
          Text($r('app.string.target_progress'))
            .fontSize($r('app.float.default_12'))
            .fontColor('#CCFFFFFF')
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
