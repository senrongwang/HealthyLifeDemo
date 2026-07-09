import { DateUtils, DayProgress } from 'common';

@Component
export struct WeekCalendar {
  weekDates: string[] = [];
  weekProgress: DayProgress[] = [];
  weekOffset: number = 0;

  aboutToAppear(): void {
    this.loadWeekDates();
  }

  private loadWeekDates(): void {
    const today: Date = new Date();
    const idx: number = DateUtils.getWeekIndex(today);
    const monday: Date = new Date(today.getTime());
    monday.setDate(today.getDate() - idx + this.weekOffset * 7);
    const dates: string[] = [];
    for (let i = 0; i < 7; i++) {
      const d: Date = new Date(monday.getTime());
      d.setDate(monday.getDate() + i);
      dates.push(DateUtils.formatDate(d));
    }
    this.weekDates = dates;
  }

  private getWeekRangeText(): string {
    if (this.weekDates.length < 7) {
      return '';
    }
    return `${this.weekDates[0]} ~ ${this.weekDates[6]}`;
  }

  private getWeekDayLabel(index: number): string {
    const labels: string[] = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '';
  }

  private getDayNumber(dateStr: string): string {
    const parts: string[] = dateStr.split('-');
    if (parts.length >= 3) {
      return parts[2];
    }
    return '';
  }

  private isToday(dateStr: string): boolean {
    return dateStr === DateUtils.today();
  }

  private isDayAllDone(dateStr: string): boolean {
    for (const dp of this.weekProgress) {
      if (dp.date === dateStr) {
        return dp.isAllDone;
      }
    }
    return false;
  }

  build(): void {
    Column() {
      Row() {
        Text('<')
          .fontSize($r('app.float.default_18'))
          .fontColor('#666666')
          .onClick(() => {
            this.weekOffset = this.weekOffset - 1;
            this.loadWeekDates();
          })

        Text(this.getWeekRangeText())
          .fontSize($r('app.float.default_14'))
          .fontColor('#333333')
          .margin({ left: $r('app.float.default_12'), right: $r('app.float.default_12') })

        Text('>')
          .fontSize($r('app.float.default_18'))
          .fontColor('#666666')
          .onClick(() => {
            if (this.weekOffset < 0) {
              this.weekOffset = this.weekOffset + 1;
              this.loadWeekDates();
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .height($r('app.float.default_36'))

      Row() {
        ForEach(this.weekDates, (dateStr: string, index: number) => {
          Column() {
            Text(this.getWeekDayLabel(index))
              .fontSize($r('app.float.default_10'))
              .fontColor('#999999')

            Stack() {
              Circle()
                .width($r('app.float.default_32'))
                .height($r('app.float.default_32'))
                .fill(this.isDayAllDone(dateStr) ? '#FFD700' : '#E0E0E0')

              Text(this.getDayNumber(dateStr))
                .fontSize($r('app.float.default_12'))
                .fontColor(this.isToday(dateStr) ? '#FF6B00' : '#333333')
                .fontWeight(this.isToday(dateStr) ? FontWeight.Bold : FontWeight.Normal)
            }
            .width($r('app.float.default_32'))
            .height($r('app.float.default_32'))
            .margin({ top: $r('app.float.default_4') })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }, (dateStr: string) => dateStr)
      }
      .width('100%')
      .padding({ top: $r('app.float.default_4'), bottom: $r('app.float.default_8') })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius($r('app.float.default_12'))
    .margin({ left: $r('app.float.default_16'), right: $r('app.float.default_16'), top: $r('app.float.default_8') })
  }
}
