import { display, router } from '@kit.ArkUI';
import { AchievementViewModel } from '../viewmodel/AchievementViewModel';
import { AchievementInfo, Logger, Constants } from 'common';

@Entry
@Component
struct AchievementPage {
  private vm: AchievementViewModel = new AchievementViewModel();
  @StorageLink('achievementList') achievementList: AchievementInfo[] = [];
  @State topSafeHeight: number = 0;

  aboutToAppear(): void {
    this.calcTopSafeHeight();
    this.loadData();
  }

  private calcTopSafeHeight(): void {
    try {
      const d: display.Display = display.getDefaultDisplaySync();
      this.topSafeHeight = Math.floor(d.height * Constants.TOP_SAFE_AREA_RATIO);
    } catch (e) {
      this.topSafeHeight = 40;
    }
  }

  private async loadData(): Promise<void> {
    try {
      await this.vm.loadAchievements();
    } catch (e) {
      Logger.error('AchievementPage loadAchievements failed');
    }
  }

  build(): void {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.ic_right_grey'))
            .width($r('app.float.default_16'))
            .height($r('app.float.default_16'))
            .rotate({ angle: 180 })
            .fillColor('#FFFFFF')
        }
        .width($r('app.float.default_36'))
        .height($r('app.float.default_36'))
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#2A2A2A')
        .borderRadius($r('app.float.default_18'))
        .onClick(() => {
          router.back();
        })
        Text($r('app.string.my_achievement'))
          .fontSize($r('app.float.default_20'))
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .margin({ left: $r('app.float.default_12') })
      }
      .width('100%')
      .height($r('app.float.default_56'))
      .padding({
        left: $r('app.float.default_16'),
        right: $r('app.float.default_16')
      })
      .alignItems(VerticalAlign.Center)

      Grid() {
        ForEach(this.achievementList, (info: AchievementInfo, idx: number) => {
          GridItem() {
            Column() {
              Image(info.unlocked ? info.iconOn : info.iconOff)
                .width($r('app.float.default_80'))
                .height($r('app.float.default_80'))
              Text('连续' + info.days.toString() + '天达成')
                .fontSize($r('app.float.default_14'))
                .fontColor('#FFFFFF')
                .margin({ top: $r('app.float.default_12') })
            }
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Center)
            .width('100%')
          }
        }, (info: AchievementInfo, idx: number) => idx.toString())
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap($r('app.float.default_20'))
      .rowsGap($r('app.float.default_24'))
      .padding({
        left: $r('app.float.default_24'),
        right: $r('app.float.default_24'),
        top: $r('app.float.default_24')
      })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .padding({ top: this.topSafeHeight })
  }
}
