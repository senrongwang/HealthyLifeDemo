import { DayProgress, TaskRepository, Logger } from 'common';

export class HistoryViewModel {
  public weekProgress: DayProgress[] = [];

  public async loadWeekProgress(): Promise<DayProgress[]> {
    this.weekProgress = await TaskRepository.getInstance().getWeekProgress();
    Logger.info('HistoryViewModel loadWeekProgress done');
    return this.weekProgress;
  }
}
