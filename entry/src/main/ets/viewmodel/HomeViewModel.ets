import { TaskInfo, TaskRecord, DayProgress, TaskType, TaskRepository, Constants, DateUtils, Logger } from 'common';

export class HomeViewModel {
  public taskList: TaskInfo[] = [];
  public todayRecords: TaskRecord[] = [];
  public todayProgress: DayProgress = new DayProgress('', 0);

  public async loadTodayTasks(): Promise<void> {
    const repo: TaskRepository = TaskRepository.getInstance();
    this.taskList = await repo.getTasks();
    this.todayRecords = await repo.getTodayRecords();
    const today: string = DateUtils.today();
    this.todayProgress = new DayProgress(today, DateUtils.getWeekIndexByStr(today));
    this.refreshProgress();
    await this.refreshAllDone();
    AppStorage.setOrCreate(Constants.APP_KEY_TASK_LIST, this.taskList);
    AppStorage.setOrCreate(Constants.APP_KEY_TODAY_RECORDS, this.todayRecords);
    AppStorage.setOrCreate(Constants.APP_KEY_CURRENT_DATE, today);
    Logger.info('HomeViewModel loadTodayTasks done');
  }

  public async clockIn(taskType: TaskType): Promise<void> {
    const repo: TaskRepository = TaskRepository.getInstance();
    const rec: TaskRecord | null = await repo.clockIn(taskType);
    if (rec === null) {
      return;
    }
    this.todayRecords = this.replaceRecord(rec);
    this.refreshProgress();
    await this.refreshAllDone();
    AppStorage.setOrCreate(Constants.APP_KEY_TODAY_RECORDS, this.todayRecords);
    if (this.todayProgress.isAllDone) {
      await this.onAllDone();
    }
  }

  public refreshProgress(): void {
    let openCount: number = 0;
    for (const t of this.taskList) {
      if (t.isOpen) {
        openCount++;
      }
    }
    let doneCount: number = 0;
    for (const r of this.todayRecords) {
      if (r.isDone) {
        doneCount++;
      }
    }
    this.todayProgress.totalCount = openCount;
    this.todayProgress.doneCount = doneCount;
  }

  private async refreshAllDone(): Promise<void> {
    const allDone: boolean = await TaskRepository.getInstance().isAllDoneToday();
    this.todayProgress.isAllDone = allDone;
    AppStorage.setOrCreate(Constants.APP_KEY_TODAY_ALL_DONE, allDone);
  }

  private async onAllDone(): Promise<void> {
    const repo: TaskRepository = TaskRepository.getInstance();
    await repo.onAllDone();
    const streak: number = await repo.getStreak();
    AppStorage.setOrCreate(Constants.APP_KEY_STREAK, streak);
    const newDays: number = await repo.checkAchievements();
    if (newDays > 0) {
      this.showAchievementDialog(newDays);
    }
  }

  private showAchievementDialog(days: number): void {
    Logger.info(`achievement unlocked, show dialog: ${days} days`);
  }

  private replaceRecord(rec: TaskRecord): TaskRecord[] {
    const arr: TaskRecord[] = this.todayRecords.slice();
    let idx: number = -1;
    for (let i = 0; i < arr.length; i++) {
      if (arr[i].taskType === rec.taskType) {
        idx = i;
        break;
      }
    }
    if (idx >= 0) {
      arr[idx] = rec;
    } else {
      arr.push(rec);
    }
    return arr;
  }
}
