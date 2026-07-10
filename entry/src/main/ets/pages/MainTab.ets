import { HomeTab } from '../view/home/HomeTab';
import { MineTab } from '../view/mine/MineTab';

@Entry
@Component
struct MainTab {
  @State currentIndex: number = 0;

  @Builder
  tabBuilder(title: Resource, targetIndex: number, normalImg: Resource, selImg: Resource): void {
    Column() {
      Image(this.currentIndex === targetIndex ? selImg : normalImg)
        .width($r('app.float.default_24'))
        .height($r('app.float.default_24'))
      Text(title)
        .fontSize($r('app.float.default_10'))
        .fontColor(this.currentIndex === targetIndex ? '#0A58F6' : '#999999')
        .margin({ top: $r('app.float.default_2') })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build(): void {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      TabContent() {
        HomeTab()
      }
      .tabBar(this.tabBuilder($r('app.string.tab_home'), 0, $r('app.media.ic_tabs_home_normal'), $r('app.media.ic_tabs_home_sel')))

      TabContent() {
        MineTab()
      }
      .tabBar(this.tabBuilder($r('app.string.tab_mine'), 1, $r('app.media.ic_tabs_mine_normal'), $r('app.media.ic_tabs_mine_sel')))
    }
    .barHeight($r('app.float.default_56'))
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F5')
  }
}
