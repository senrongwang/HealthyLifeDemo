export class DateUtils {
  public static today(): string {
    return DateUtils.formatDate(new Date());
  }

  public static formatDate(date: Date): string {
    const y: number = date.getFullYear();
    const m: number = date.getMonth() + 1;
    const d: number = date.getDate();
    const mm: string = m < 10 ? '0' + m : '' + m;
    const dd: string = d < 10 ? '0' + d : '' + d;
    return `${y}-${mm}-${dd}`;
  }

  public static parseDate(dateStr: string): Date {
    const parts: string[] = dateStr.split('-');
    const y: number = parseInt(parts[0], 10);
    const m: number = parseInt(parts[1], 10) - 1;
    const d: number = parseInt(parts[2], 10);
    return new Date(y, m, d);
  }

  public static getWeekIndex(date: Date): number {
    return (date.getDay() + 6) % 7;
  }

  public static getWeekIndexByStr(dateStr: string): number {
    return DateUtils.getWeekIndex(DateUtils.parseDate(dateStr));
  }

  public static compareDate(a: string, b: string): number {
    if (a < b) {
      return -1;
    }
    if (a > b) {
      return 1;
    }
    return 0;
  }

  public static addDays(dateStr: string, days: number): string {
    const date: Date = DateUtils.parseDate(dateStr);
    date.setDate(date.getDate() + days);
    return DateUtils.formatDate(date);
  }

  public static getWeekDates(): string[] {
    return DateUtils.getWeekDatesByOffset(0);
  }

  public static getWeekDatesByOffset(weekOffset: number): string[] {
    const today: Date = new Date();
    const idx: number = DateUtils.getWeekIndex(today);
    const monday: Date = new Date(today.getTime());
    monday.setDate(today.getDate() - idx + weekOffset * 7);
    const dates: string[] = [];
    for (let i = 0; i < 7; i++) {
      const d: Date = new Date(monday.getTime());
      d.setDate(monday.getDate() + i);
      dates.push(DateUtils.formatDate(d));
    }
    return dates;
  }

  public static getWeekDayLabel(dateStr: string): string {
    const d: number = parseInt(dateStr.substring(8, 10), 10);
    return d.toString();
  }

  public static getWeekRangeString(dates: string[]): string {
    if (dates.length < 7) {
      return '';
    }
    const first: string = dates[0];
    const last: string = dates[6];
    const fm: string = first.substring(5, 7);
    const fd: string = first.substring(8, 10);
    const lm: string = last.substring(5, 7);
    const ld: string = last.substring(8, 10);
    return `${fm}/${fd} - ${lm}/${ld}`;
  }
}
