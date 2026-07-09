import { DayProgress, DateUtils, Logger } from 'common';
import { HistoryViewModel } from '../../viewmodel/HistoryViewModel';

@Component
export struct WeekCalendar {
  @Link selectedDate: string;
  @State weekOffset: number = 0;
  @State weekDates: string[] = [];
  @State weekProgress: DayProgress[] = [];
  private historyVM: HistoryViewModel = new HistoryViewModel();
  private weekLabels: string[] = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  aboutToAppear(): void {
    this.weekDates = DateUtils.getWeekDatesByOffset(this.weekOffset);
    if (this.selectedDate.length === 0) {
      this.selectedDate = DateUtils.today();
    }
    this.loadData();
  }

  private async loadData(): Promise<void> {
    try {
      this.weekProgress = await this.historyVM.loadWeekProgressByOffset(this.weekOffset);
    } catch (e) {
      Logger.error('WeekCalendar loadData failed');
    }
  }

  private prevWeek(): void {
    this.weekOffset = this.weekOffset - 1;
    this.weekDates = DateUtils.getWeekDatesByOffset(this.weekOffset);
    this.selectedDate = this.weekDates[0];
    this.loadData();
  }

  private nextWeek(): void {
    if (this.weekOffset >= 0) {
      return;
    }
    this.weekOffset = this.weekOffset + 1;
    this.weekDates = DateUtils.getWeekDatesByOffset(this.weekOffset);
    this.selectedDate = this.weekDates[0];
    this.loadData();
  }

  private findProgress(date: string): DayProgress | null {
    for (const dp of this.weekProgress) {
      if (dp.date === date) {
        return dp;
      }
    }
    return null;
  }

  private isAllDone(date: string): boolean {
    const dp: DayProgress | null = this.findProgress(date);
    if (dp === null) {
      return false;
    }
    return dp.isAllDone;
  }

  build(): void {
    Column() {
      Row() {
        Image($r('app.media.ic_right_grey'))
          .width($r('app.float.default_20'))
          .height($r('app.float.default_20'))
          .rotate({ angle: 180 })
          .onClick(() => {
            this.prevWeek();
          })

        Text(DateUtils.getWeekRangeString(this.weekDates))
          .fontSize($r('app.float.default_14'))
          .fontColor('#333333')
          .margin({ left: $r('app.float.default_8'), right: $r('app.float.default_8') })

        Image($r('app.media.ic_right_grey'))
          .width($r('app.float.default_20'))
          .height($r('app.float.default_20'))
          .opacity(this.weekOffset >= 0 ? 0.3 : 1.0)
          .onClick(() => {
            this.nextWeek();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      Row() {
        ForEach(this.weekLabels, (label: string, idx: number): void => {
          Text(label)
            .fontSize($r('app.float.default_10'))
            .fontColor('#999999')
            .width(0)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }, (_label: string, idx: number): string => idx.toString())
      }
      .width('100%')
      .margin({ top: $r('app.float.default_4') })

      Row() {
        ForEach(this.weekDates, (date: string, idx: number): void => {
          this.dayBadge(date, idx)
        }, (date: string, _idx: number): string => date)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ top: $r('app.float.default_4') })
    }
    .width('100%')
    .padding({
      left: $r('app.float.default_16'),
      right: $r('app.float.default_16'),
      top: $r('app.float.default_8'),
      bottom: $r('app.float.default_4')
    })
  }

  @Builder
  dayBadge(date: string, _idx: number): void {
    Stack() {
      if (this.findProgress(date) !== null) {
        Image(this.isAllDone(date)
          ? $r('app.media.ic_home_all_done')
          : $r('app.media.ic_home_undone'))
          .width($r('app.float.default_36'))
          .height($r('app.float.default_36'))
          .objectFit(ImageFit.Contain)
      } else {
        Column()
          .width($r('app.float.default_36'))
          .height($r('app.float.default_36'))
          .borderRadius($r('app.float.default_18'))
          .backgroundColor('#F0F0F0')
      }

      Text(DateUtils.getWeekDayLabel(date))
        .fontSize(this.selectedDate === date ? $r('app.float.default_14') : $r('app.float.default_12'))
        .fontWeight(this.selectedDate === date ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.selectedDate === date ? '#FF6B00' : '#666666')
    }
    .width($r('app.float.default_40'))
    .height($r('app.float.default_40'))
    .borderRadius($r('app.float.default_20'))
    .border(this.selectedDate === date
      ? { width: 2, color: '#FF6B00' }
      : { width: 0, color: '#00000000' })
    .opacity(DateUtils.compareDate(date, DateUtils.today()) > 0 ? 0.4 : 1.0)
    .onClick(() => {
      this.selectedDate = date;
    })
  }
}
