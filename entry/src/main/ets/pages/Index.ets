import { router } from '@kit.ArkUI';
import { Constants, PrefsHelper, Logger } from 'common';

@Entry
@Component
struct Index {
  @State countdown: number = 3;
  @State showPrivacy: boolean = false;
  private timerId: number = -1;
  private navigated: boolean = false;

  aboutToAppear(): void {
    this.checkFirstLaunch();
    this.startCountdown();
  }

  aboutToDisappear(): void {
    this.clearTimer();
  }

  private async checkFirstLaunch(): Promise<void> {
    try {
      const first: boolean = await PrefsHelper.getInstance().getFirstLaunch();
      this.showPrivacy = first;
    } catch (e) {
      Logger.error('Index checkFirstLaunch failed');
    }
  }

  private startCountdown(): void {
    this.timerId = setInterval(() => {
      if (this.countdown <= 1) {
        this.navigateToMain();
      } else {
        this.countdown--;
      }
    }, 1000);
  }

  private clearTimer(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private navigateToMain(): void {
    if (this.navigated) {
      return;
    }
    this.navigated = true;
    this.clearTimer();
    AppStorage.setOrCreate(Constants.APP_KEY_SPLASH_DONE, true);
    router.replaceUrl({ url: 'pages/MainTab' });
  }

  private async confirmPrivacy(): Promise<void> {
    try {
      await PrefsHelper.getInstance().setFirstLaunch(false);
    } catch (e) {
      Logger.error('Index setFirstLaunch failed');
    }
    this.showPrivacy = false;
  }

  private cancelPrivacy(): void {
    this.showPrivacy = false;
  }

  build(): void {
    Stack() {
      Image($r('app.media.ic_splash_bg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // skip button top-right
      Text($r('app.string.skip_ads', this.countdown))
        .fontSize($r('app.float.default_12'))
        .fontColor('#FFFFFF')
        .backgroundColor('#66000000')
        .borderRadius($r('app.float.default_16'))
        .padding({
          left: $r('app.float.default_10'),
          right: $r('app.float.default_10'),
          top: $r('app.float.default_4'),
          bottom: $r('app.float.default_4')
        })
        .position({ x: '60%', y: $r('app.float.default_20') })
        .onClick(() => {
          this.navigateToMain();
        })

      if (this.showPrivacy) {
        this.PrivacyDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  PrivacyDialog(): void {
    Column() {
      Column() {
        Text($r('app.string.privacy_title'))
          .fontSize($r('app.float.default_18'))
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ bottom: $r('app.float.default_12') })
        Text($r('app.string.privacy_desc'))
          .fontSize($r('app.float.default_14'))
          .fontColor('#666666')
          .lineHeight($r('app.float.default_20'))
          .margin({ bottom: $r('app.float.default_20') })
        Row() {
          Button($r('app.string.cancel'))
            .fontSize($r('app.float.default_14'))
            .fontColor('#666666')
            .backgroundColor('#EEEEEE')
            .layoutWeight(1)
            .height($r('app.float.default_40'))
            .onClick(() => {
              this.cancelPrivacy();
            })
          Button($r('app.string.confirm'))
            .fontSize($r('app.float.default_14'))
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.button_red'))
            .layoutWeight(1)
            .height($r('app.float.default_40'))
            .margin({ left: $r('app.float.default_12') })
            .onClick(() => {
              this.confirmPrivacy();
            })
        }
        .width('100%')
      }
      .width('80%')
      .padding($r('app.float.default_20'))
      .backgroundColor('#FFFFFF')
      .borderRadius($r('app.float.default_12'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#80000000')
  }
}
