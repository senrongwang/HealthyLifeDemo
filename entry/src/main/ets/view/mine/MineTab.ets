import { MineViewModel } from '../../viewmodel/MineViewModel';

@Component
export struct MineTab {
  private mineVM: MineViewModel = new MineViewModel();
  @State menuItems: number[] = [0, 1, 2];

  build(): void {
    Column() {
      Row() {
        Image(this.mineVM.getAvatar())
          .width($r('app.float.default_66'))
          .height($r('app.float.default_66'))
          .borderRadius($r('app.float.default_32'))
        Column() {
          Text(this.mineVM.getUserName())
            .fontSize($r('app.float.default_18'))
            .fontColor($r('app.color.mine_font_color'))
            .fontWeight(FontWeight.Bold)
          Text(this.mineVM.getUserLevel())
            .fontSize($r('app.float.default_12'))
            .fontColor($r('app.color.user_level_font_color'))
            .backgroundColor($r('app.color.user_level_bg_color'))
            .borderRadius($r('app.float.default_4'))
            .padding({
              left: $r('app.float.default_6'),
              right: $r('app.float.default_6'),
              top: $r('app.float.default_2'),
              bottom: $r('app.float.default_2')
            })
            .margin({ top: $r('app.float.default_4') })
          Text(this.mineVM.getUserSignature())
            .fontSize($r('app.float.default_14'))
            .fontColor($r('app.color.mine_font_color'))
            .margin({ top: $r('app.float.default_4') })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: $r('app.float.default_12') })
      }
      .width('100%')
      .padding({
        left: $r('app.float.default_20'),
        right: $r('app.float.default_20'),
        top: $r('app.float.default_20')
      })
      .alignItems(VerticalAlign.Center)

      List() {
        ForEach(this.menuItems, (item: number) => {
          ListItem() {
            Row() {
              Text(this.mineVM.getMenuTitle(item))
                .fontSize($r('app.float.default_16'))
                .fontColor($r('app.color.mine_font_color'))
              Image($r('app.media.ic_right_grey'))
                .width($r('app.float.default_12'))
                .height($r('app.float.default_12'))
            }
            .width('100%')
            .height($r('app.float.default_56'))
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .padding({
              left: $r('app.float.default_20'),
              right: $r('app.float.default_20')
            })
            .onClick(() => {
              this.mineVM.navigate(item);
            })
          }
        }, (item: number) => item.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .margin({ top: $r('app.float.default_10') })
    }
    .width('100%')
    .height('100%')
  }
}
