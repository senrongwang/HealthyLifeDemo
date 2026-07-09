import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Constants, DateUtils, TaskRepository, Logger } from 'common';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (e) {
      Logger.error('EntryAbility setColorMode failed');
    }
    Logger.info('EntryAbility onCreate');
  }

  onDestroy(): void {
    Logger.info('EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info('EntryAbility onWindowStageCreate');
    this.initializeAppStorage();
    this.setWindowBackground(windowStage);
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

  private async setWindowBackground(windowStage: window.WindowStage): Promise<void> {
    try {
      const win: window.Window = await windowStage.getMainWindow();
      win.setWindowBackgroundColor('#F2F3F5');
    } catch (e) {
      Logger.error('EntryAbility setWindowBackground failed');
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
