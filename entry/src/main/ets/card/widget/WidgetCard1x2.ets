class CardTaskData {
  type: number;
  done: boolean;
  finNum: number;
  targetValue: number;

  constructor(type: number, done: boolean, finNum: number, targetValue: number) {
    this.type = type;
    this.done = done;
    this.finNum = finNum;
    this.targetValue = targetValue;
  }
}

let storage1x2 = new LocalStorage();

@Entry(storage1x2)
@Component
struct WidgetCard1x2 {
  @LocalStorageProp('taskCount') taskCount: string = '0';
  @LocalStorageProp('hasTasks') hasTasks: string = '0';

  @LocalStorageProp('task0Type') task0Type: string = '0';
  @LocalStorageProp('task0Done') task0Done: string = '0';
  @LocalStorageProp('task0Fin') task0Fin: string = '0';
  @LocalStorageProp('task0Target') task0Target: string = '1';

  @LocalStorageProp('task1Type') task1Type: string = '0';
  @LocalStorageProp('task1Done') task1Done: string = '0';
  @LocalStorageProp('task1Fin') task1Fin: string = '0';
  @LocalStorageProp('task1Target') task1Target: string = '1';

  @LocalStorageProp('task2Type') task2Type: string = '0';
  @LocalStorageProp('task2Done') task2Done: string = '0';
  @LocalStorageProp('task2Fin') task2Fin: string = '0';
  @LocalStorageProp('task2Target') task2Target: string = '1';

  @LocalStorageProp('task3Type') task3Type: string = '0';
  @LocalStorageProp('task3Done') task3Done: string = '0';
  @LocalStorageProp('task3Fin') task3Fin: string = '0';
  @LocalStorageProp('task3Target') task3Target: string = '1';

  @LocalStorageProp('task4Type') task4Type: string = '0';
  @LocalStorageProp('task4Done') task4Done: string = '0';
  @LocalStorageProp('task4Fin') task4Fin: string = '0';
  @LocalStorageProp('task4Target') task4Target: string = '1';

  @LocalStorageProp('task5Type') task5Type: string = '0';
  @LocalStorageProp('task5Done') task5Done: string = '0';
  @LocalStorageProp('task5Fin') task5Fin: string = '0';
  @LocalStorageProp('task5Target') task5Target: string = '1';

  private getCardIcon(type: number): Resource {
    switch (type) {
      case 0:
        return $r('app.media.ic_card_getup');
      case 1:
        return $r('app.media.ic_card_drink');
      case 2:
        return $r('app.media.ic_card_apple');
      case 3:
        return $r('app.media.ic_card_smile');
      case 4:
        return $r('app.media.ic_card_clean');
      case 5:
        return $r('app.media.ic_card_sleep');
      default:
        return $r('app.media.ic_card_getup');
    }
  }

  private getTaskName(type: number): Resource {
    switch (type) {
      case 0:
        return $r('app.string.task_getup');
      case 1:
        return $r('app.string.task_drink');
      case 2:
        return $r('app.string.task_apple');
      case 3:
        return $r('app.string.task_smile');
      case 4:
        return $r('app.string.task_brush');
      case 5:
        return $r('app.string.task_sleep');
      default:
        return $r('app.string.task_getup');
    }
  }

  private buildTaskList(): CardTaskData[] {
    const list: CardTaskData[] = [];
    const count: number = parseInt(this.taskCount, 10);
    if (count >= 1) {
      list.push(new CardTaskData(
        parseInt(this.task0Type, 10), this.task0Done === '1',
        parseInt(this.task0Fin, 10), parseInt(this.task0Target, 10)));
    }
    if (count >= 2) {
      list.push(new CardTaskData(
        parseInt(this.task1Type, 10), this.task1Done === '1',
        parseInt(this.task1Fin, 10), parseInt(this.task1Target, 10)));
    }
    if (count >= 3) {
      list.push(new CardTaskData(
        parseInt(this.task2Type, 10), this.task2Done === '1',
        parseInt(this.task2Fin, 10), parseInt(this.task2Target, 10)));
    }
    if (count >= 4) {
      list.push(new CardTaskData(
        parseInt(this.task3Type, 10), this.task3Done === '1',
        parseInt(this.task3Fin, 10), parseInt(this.task3Target, 10)));
    }
    if (count >= 5) {
      list.push(new CardTaskData(
        parseInt(this.task4Type, 10), this.task4Done === '1',
        parseInt(this.task4Fin, 10), parseInt(this.task4Target, 10)));
    }
    if (count >= 6) {
      list.push(new CardTaskData(
        parseInt(this.task5Type, 10), this.task5Done === '1',
        parseInt(this.task5Fin, 10), parseInt(this.task5Target, 10)));
    }
    return list;
  }

  build(): void {
    Column() {
      if (this.hasTasks === '1') {
        List() {
          ForEach(this.buildTaskList(), (item: CardTaskData) => {
            ListItem() {
              Row() {
                Image(this.getCardIcon(item.type))
                  .width(20)
                  .height(20)

                Text(this.getTaskName(item.type))
                  .fontSize(12)
                  .fontColor('#333333')
                  .margin({ left: 8 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Blank()

                if (item.done) {
                  Text($r('app.string.card_done'))
                    .fontSize(11)
                    .fontColor('#4CAF50')
                } else {
                  Text($r('app.string.card_undone'))
                    .fontSize(11)
                    .fontColor('#999999')
                }
              }
              .width('100%')
              .height(34)
              .padding({ left: 12, right: 12 })
            }
          }, (item: CardTaskData) => {
            return item.type.toString();
          })
        }
        .width('100%')
        .height('100%')
        .padding({ top: 4, bottom: 4 })
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
    .onClick(() => {
      postCardAction(this, {
        'action': 'router',
        'abilityName': 'EntryAbility',
        'params': {}
      });
    })
  }
}
