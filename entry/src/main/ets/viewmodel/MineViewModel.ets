import { Logger } from 'common';
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

  public async navigate(index: number): Promise<void> {
    switch (index) {
      case 2:
        await router.pushUrl({ url: 'pages/AchievementPage' });
        break;
      default:
        Logger.info(`MineViewModel navigate index=${index}`);
        break;
    }
  }
}
