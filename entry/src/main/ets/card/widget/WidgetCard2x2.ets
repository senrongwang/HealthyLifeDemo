let storage2x2 = new LocalStorage();

@Entry(storage2x2)
@Component
struct WidgetCard2x2 {
  @LocalStorageProp('progress') progress: string = '0';
  @LocalStorageProp('doneCount') doneCount: string = '0';
  @LocalStorageProp('totalCount') totalCount: string = '0';
  @LocalStorageProp('hasTasks') hasTasks: string = '0';

  build(): void {
    Column() {
      if (this.hasTasks === '1') {
        Stack() {
          Progress({ value: parseInt(this.progress, 10), total: 100, type: ProgressType.Ring })
            .width(80)
            .height(80)
            .style({ strokeWidth: 6, scaleWidth: 0.9 })
            .color('#0D59F6')
            .backgroundColor('#E0E0E0')

          Text(`${this.progress}%`)
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(FontWeight.Bold)
        }

        Text($r('app.string.target_progress'))
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 8 })

        Text(`${this.doneCount} / ${this.totalCount}`)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 4 })
      } else {
        Column() {
          Text($r('app.string.card_no_task'))
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      postCardAction(this, {
        'action': 'router',
        'abilityName': 'EntryAbility',
        'params': {}
      });
    })
  }
}
