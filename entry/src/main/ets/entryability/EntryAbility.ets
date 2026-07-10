import { AbilityConstant, ConfigurationConstant, UIAbility, Want, common } from '@kit.AbilityKit';
import { window, display } from '@kit.ArkUI';
import { calendarManager } from '@kit.CalendarKit';
import { Constants, DateUtils, TaskRepository, Logger } from 'common';

export let calendarMgr: calendarManager.CalendarManager | null = null;
export let appContext: common.UIAbilityContext | null = null;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (e) {
      Logger.error('EntryAbility setColorMode failed');
    }
    calendarMgr = calendarManager.getCalendarManager(this.context);
    appContext = this.context;
    Logger.info('EntryAbility onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info('EntryAbility onNewWant from card router event');
  }

  onDestroy(): void {
    Logger.info('EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info('EntryAbility onWindowStageCreate');
    this.initializeAppStorage();
    this.configureWindow(windowStage);
    this.initAndLoad(windowStage);
  }

  onWindowStageDestroy(): void {
    Logger.info('EntryAbility onWindowStageDestroy');
  }

  onForeground(): void {
    Logger.info('EntryAbility onForeground');
  }

  onBackground(): void {
    Logger.info('EntryAbility onBackground');
  }

  private initializeAppStorage(): void {
    AppStorage.setOrCreate(Constants.APP_KEY_CURRENT_DATE, DateUtils.today());
    AppStorage.setOrCreate(Constants.APP_KEY_STREAK, 0);
    AppStorage.setOrCreate(Constants.APP_KEY_TODAY_ALL_DONE, false);
    AppStorage.setOrCreate(Constants.APP_KEY_SPLASH_DONE, false);
  }

  private async configureWindow(windowStage: window.WindowStage): Promise<void> {
    try {
      const win: window.Window = await windowStage.getMainWindow();
      win.setWindowBackgroundColor('#F2F3F5');
      await win.setWindowLayoutFullScreen(true);
      await win.setWindowSystemBarProperties({
        statusBarContentColor: '#000000'
      });
      const avoidArea: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const displayInfo: display.Display = display.getDefaultDisplaySync();
      const density: number = displayInfo.densityPixels;
      const statusBarHeightVp: number = avoidArea.topRect.height / density;
      AppStorage.setOrCreate('statusBarHeight', statusBarHeightVp);
    } catch (e) {
      Logger.error('EntryAbility configureWindow failed');
    }
  }

  private async initAndLoad(windowStage: window.WindowStage): Promise<void> {
    try {
      await TaskRepository.getInstance().init(this.context);
      Logger.info('EntryAbility TaskRepository init done');
    } catch (e) {
      Logger.error('EntryAbility TaskRepository init failed');
    }
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Logger.error('EntryAbility loadContent failed code=' + err.code);
        return;
      }
      Logger.info('EntryAbility loadContent Index success');
    });
  }
}
