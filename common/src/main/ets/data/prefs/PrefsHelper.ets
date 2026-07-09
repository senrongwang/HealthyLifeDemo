import { preferences } from '@kit.ArkData';
import { Constants } from '../../common/Constants';
import { Logger } from '../../common/Logger';

export class PrefsHelper {
  private static instance: PrefsHelper | null = null;
  private pref: preferences.Preferences | null = null;

  public static getInstance(): PrefsHelper {
    if (PrefsHelper.instance === null) {
      PrefsHelper.instance = new PrefsHelper();
    }
    return PrefsHelper.instance;
  }

  public async getStore(context: Context): Promise<preferences.Preferences> {
    if (this.pref !== null) {
      return this.pref;
    }
    this.pref = await preferences.getPreferences(context, Constants.PREF_STORE_NAME);
    Logger.info('PrefsHelper initialized');
    return this.pref;
  }

  public async getStreak(): Promise<number> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return 0;
    }
    const v = await p.get(Constants.PREF_KEY_STREAK, 0);
    if (typeof v === 'number') {
      return v;
    }
    return 0;
  }

  public async setStreak(value: number): Promise<void> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return;
    }
    await p.put(Constants.PREF_KEY_STREAK, value);
    await p.flush();
  }

  public async getLastCompleteDate(): Promise<string> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return '';
    }
    const v = await p.get(Constants.PREF_KEY_LAST_COMPLETE_DATE, '');
    if (typeof v === 'string') {
      return v;
    }
    return '';
  }

  public async setLastCompleteDate(value: string): Promise<void> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return;
    }
    await p.put(Constants.PREF_KEY_LAST_COMPLETE_DATE, value);
    await p.flush();
  }

  public async getTotalDays(): Promise<number> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return 0;
    }
    const v = await p.get(Constants.PREF_KEY_TOTAL_DAYS, 0);
    if (typeof v === 'number') {
      return v;
    }
    return 0;
  }

  public async setTotalDays(value: number): Promise<void> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return;
    }
    await p.put(Constants.PREF_KEY_TOTAL_DAYS, value);
    await p.flush();
  }

  public async getHighestStreak(): Promise<number> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return 0;
    }
    const v = await p.get(Constants.PREF_KEY_HIGHEST_STREAK, 0);
    if (typeof v === 'number') {
      return v;
    }
    return 0;
  }

  public async setHighestStreak(value: number): Promise<void> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return;
    }
    await p.put(Constants.PREF_KEY_HIGHEST_STREAK, value);
    await p.flush();
  }

  public async getAchievements(): Promise<number[]> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return [];
    }
    const v = await p.get(Constants.PREF_KEY_ACHIEVEMENTS, '');
    if (typeof v === 'string') {
      return PrefsHelper.parseAchievements(v);
    }
    return [];
  }

  public async setAchievements(values: number[]): Promise<void> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return;
    }
    await p.put(Constants.PREF_KEY_ACHIEVEMENTS, values.join(','));
    await p.flush();
  }

  public async getFirstLaunch(): Promise<boolean> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return true;
    }
    const v = await p.get(Constants.PREF_KEY_FIRST_LAUNCH, true);
    if (typeof v === 'boolean') {
      return v;
    }
    return true;
  }

  public async setFirstLaunch(value: boolean): Promise<void> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return;
    }
    await p.put(Constants.PREF_KEY_FIRST_LAUNCH, value);
    await p.flush();
  }

  public async getCurrentDate(): Promise<string> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return '';
    }
    const v = await p.get(Constants.PREF_KEY_CURRENT_DATE, '');
    if (typeof v === 'string') {
      return v;
    }
    return '';
  }

  public async setCurrentDate(value: string): Promise<void> {
    const p: preferences.Preferences | null = this.pref;
    if (p === null) {
      return;
    }
    await p.put(Constants.PREF_KEY_CURRENT_DATE, value);
    await p.flush();
  }

  private static parseAchievements(str: string): number[] {
    if (str.length === 0) {
      return [];
    }
    const parts: string[] = str.split(',');
    const result: number[] = [];
    for (let i = 0; i < parts.length; i++) {
      const n: number = parseInt(parts[i], 10);
      if (!isNaN(n)) {
        result.push(n);
      }
    }
    return result;
  }
}
