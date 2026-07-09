import { DayProgress, TaskRepository, DateUtils, Logger } from 'common';

export class HistoryViewModel {
  public weekProgress: DayProgress[] = [];

  public async loadWeekProgress(): Promise<DayProgress[]> {
    this.weekProgress = await TaskRepository.getInstance().getWeekProgress();
    Logger.info('HistoryViewModel loadWeekProgress done');
    return this.weekProgress;
  }

  public async loadWeekProgressByOffset(weekOffset: number): Promise<DayProgress[]> {
    const dates: string[] = DateUtils.getWeekDatesByOffset(weekOffset);
    const list: DayProgress[] = [];
    const repo: TaskRepository = TaskRepository.getInstance();
    for (const d of dates) {
      list.push(await repo.getDayProgress(d));
    }
    this.weekProgress = list;
    Logger.info('HistoryViewModel loadWeekProgressByOffset done');
    return this.weekProgress;
  }
}
