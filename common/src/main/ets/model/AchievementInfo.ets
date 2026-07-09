export class AchievementInfo {
  level: number;
  days: number;
  unlocked: boolean;
  iconOn: Resource;
  iconOff: Resource;

  constructor(level: number, days: number, iconOn: Resource, iconOff: Resource) {
    this.level = level;
    this.days = days;
    this.iconOn = iconOn;
    this.iconOff = iconOff;
    this.unlocked = false;
  }
}
