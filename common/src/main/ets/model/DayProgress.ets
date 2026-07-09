export class DayProgress {
  date: string;
  weekIndex: number;
  doneCount: number;
  totalCount: number;
  isAllDone: boolean;

  constructor(date: string, weekIndex: number) {
    this.date = date;
    this.weekIndex = weekIndex;
    this.doneCount = 0;
    this.totalCount = 0;
    this.isAllDone = false;
  }

  get progress(): number {
    return this.totalCount === 0 ? 0 : Math.floor(this.doneCount * 100 / this.totalCount);
  }
}
