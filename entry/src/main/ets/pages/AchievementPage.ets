import { router } from '@kit.ArkUI';
import { AchievementViewModel } from '../viewmodel/AchievementViewModel';
import { AchievementInfo, Logger } from 'common';

@Entry
@Component
struct AchievementPage {
  private vm: AchievementViewModel = new AchievementViewModel();
  @StorageLink('achievementList') achievementList: AchievementInfo[] = [];

  aboutToAppear(): void {
    this.loadData();
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
        Image($r('app.media.ic_right_grey'))
          .width($r('app.float.default_16'))
          .height($r('app.float.default_16'))
          .rotate({ angle: 180 })
          .onClick(() => {
            router.back();
          })
        Text($r('app.string.my_achievement'))
          .fontSize($r('app.float.default_18'))
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

      Stack() {
        Image($r('app.media.ach_back'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        Column() {
          Image($r('app.media.star_trophy'))
            .width($r('app.float.default_120'))
            .height($r('app.float.default_120'))
            .objectFit(ImageFit.Contain)
            .margin({ top: $r('app.float.default_20') })

          Grid() {
            ForEach(this.achievementList, (info: AchievementInfo, idx: number) => {
              GridItem() {
                Column() {
                  Image(info.unlocked ? info.iconOn : info.iconOff)
                    .width($r('app.float.default_72'))
                    .height($r('app.float.default_72'))
                  Text(info.unlocked ? $r('app.string.achievement_level', info.days.toString()) : '???')
                    .fontSize($r('app.float.default_12'))
                    .fontColor(info.unlocked ? '#FFFFFF' : '#666666')
                    .margin({ top: $r('app.float.default_4') })
                }
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .width('100%')
                .height('100%')
              }
            }, (info: AchievementInfo, idx: number) => idx.toString())
          }
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr')
          .columnsGap($r('app.float.default_16'))
          .rowsGap($r('app.float.default_16'))
          .padding({
            left: $r('app.float.default_24'),
            right: $r('app.float.default_24'),
            top: $r('app.float.default_16'),
            bottom: $r('app.float.default_20')
          })
          .layoutWeight(1)
          .width('100%')
        }
        .width('100%')
        .height('100%')
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.ach_bg_color'))
  }
}
