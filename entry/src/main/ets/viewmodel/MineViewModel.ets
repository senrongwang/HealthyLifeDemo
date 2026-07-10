import { Logger, Constants, PrefsHelper } from 'common';
import { router } from '@kit.ArkUI';

export class MineViewModel {
  public getUserName(): Resource {
    return $r('app.string.user_name');
  }

  public getUserLevel(): Resource {
    return $r('app.string.user_level');
  }

  public getUserSignature(): Resource {
    return $r('app.string.user_signature');
  }

  public getAvatar(): Resource {
    return $r('app.media.ic_user');
  }

  public getMenuCount(): number {
    return 3;
  }

  public getMenuTitle(index: number): Resource {
    switch (index) {
      case 0:
        return $r('app.string.mine_personal_data');
      case 1:
        return $r('app.string.mine_check_updates');
      case 2:
        return $r('app.string.mine_achievement');
      default:
        return $r('app.string.mine_personal_data');
    }
  }

  public async loadProfile(): Promise<void> {
    try {
      const pref: PrefsHelper = PrefsHelper.getInstance();
      const nickname: string = await pref.getNickname();
      const gender: number = await pref.getGender();
      const birthday: string = await pref.getBirthday();
      const height: number = await pref.getHeight();
      const weight: number = await pref.getWeight();
      const avatarPath: string = await pref.getAvatarPath();
      AppStorage.setOrCreate(Constants.APP_KEY_NICKNAME, nickname);
      AppStorage.setOrCreate(Constants.APP_KEY_GENDER, gender);
      AppStorage.setOrCreate(Constants.APP_KEY_BIRTHDAY, birthday);
      AppStorage.setOrCreate(Constants.APP_KEY_HEIGHT, height);
      AppStorage.setOrCreate(Constants.APP_KEY_WEIGHT, weight);
      AppStorage.setOrCreate(Constants.APP_KEY_AVATAR_PATH, avatarPath);
    } catch (e) {
      Logger.error('MineViewModel loadProfile failed');
    }
  }

  public getGenderText(gender: number): Resource {
    switch (gender) {
      case 1:
        return $r('app.string.gender_male');
      case 2:
        return $r('app.string.gender_female');
      default:
        return $r('app.string.gender_secret');
    }
  }

  public async navigate(index: number): Promise<void> {
    switch (index) {
      case 0:
        await router.pushUrl({ url: 'pages/ProfileEditPage' });
        break;
      case 2:
        await router.pushUrl({ url: 'pages/AchievementPage' });
        break;
      default:
        Logger.info(`MineViewModel navigate index=${index}`);
        break;
    }
  }
}
