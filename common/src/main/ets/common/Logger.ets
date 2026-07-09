import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0xFF00;
const TAG: string = 'HealthyLife';

export class Logger {
  public static info(msg: string): void {
    hilog.info(DOMAIN, TAG, '%{public}s', msg);
  }

  public static warn(msg: string): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', msg);
  }

  public static error(msg: string): void {
    hilog.error(DOMAIN, TAG, '%{public}s', msg);
  }

  public static debug(msg: string): void {
    hilog.debug(DOMAIN, TAG, '%{public}s', msg);
  }
}
