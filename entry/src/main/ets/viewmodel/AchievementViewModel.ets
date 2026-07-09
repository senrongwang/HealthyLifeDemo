import { AchievementInfo, ACHIEVEMENT_THRESHOLDS, TaskRepository, Constants, Logger } from 'common';

export class AchievementViewModel {
  public achievementList: AchievementInfo[] = [];

  public async loadAchievements(): Promise<AchievementInfo[]> {
    const unlocked: number[] = await TaskRepository.getInstance().getUnlockedAchievements();
    const list: AchievementInfo[] = [];
    for (let i = 0; i < ACHIEVEMENT_THRESHOLDS.length; i++) {
      const days: number = ACHIEVEMENT_THRESHOLDS[i];
      const info: AchievementInfo = new AchievementInfo(i, days, this.badgeIcon(days, true), this.badgeIcon(days, false));
      info.unlocked = unlocked.indexOf(days) >= 0;
      list.push(info);
    }
    this.achievementList = list;
    AppStorage.setOrCreate(Constants.APP_KEY_ACHIEVEMENT_LIST, list);
    Logger.info('AchievementViewModel loadAchievements done');
    return list;
  }

  private badgeIcon(days: number, on: boolean): Resource {
    switch (days) {
      case 3:
        return on ? $r('app.media.ic_badge_3_on') : $r('app.media.ic_badge_3_off');
      case 7:
        return on ? $r('app.media.ic_badge_7_on') : $r('app.media.ic_badge_7_off');
      case 30:
        return on ? $r('app.media.ic_badge_30_on') : $r('app.media.ic_badge_30_off');
      case 50:
        return on ? $r('app.media.ic_badge_50_on') : $r('app.media.ic_badge_50_off');
      case 73:
        return on ? $r('app.media.ic_badge_73_on') : $r('app.media.ic_badge_73_off');
      case 99:
        return on ? $r('app.media.ic_badge_99_on') : $r('app.media.ic_badge_99_off');
      default:
        return $r('app.media.ic_badge_3_off');
    }
  }
}
