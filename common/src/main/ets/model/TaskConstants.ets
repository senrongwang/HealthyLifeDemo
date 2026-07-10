import { TaskType, TaskFlag } from './TaskType';

export interface TaskMeta {
  name: Resource;
  taskIcon: Resource;
  dialogIcon: Resource;
  cardIcon: Resource;
  unit?: Resource;
  flag: TaskFlag;
}

export class TaskConstants {
  public static getMeta(type: TaskType): TaskMeta {
    switch (type) {
      case TaskType.GETUP:
        return {
          name: $r('app.string.task_getup'),
          taskIcon: $r('app.media.ic_task_getup'),
          dialogIcon: $r('app.media.ic_dialog_getup'),
          cardIcon: $r('app.media.ic_card_getup'),
          flag: TaskFlag.SINGLE
        };
      case TaskType.DRINK:
        return {
          name: $r('app.string.task_drink'),
          taskIcon: $r('app.media.ic_task_drink'),
          dialogIcon: $r('app.media.ic_dialog_drink'),
          cardIcon: $r('app.media.ic_card_drink'),
          unit: $r('app.string.unit_liter'),
          flag: TaskFlag.MULTI
        };
      case TaskType.APPLE:
        return {
          name: $r('app.string.task_apple'),
          taskIcon: $r('app.media.ic_task_apple'),
          dialogIcon: $r('app.media.ic_dialog_apple'),
          cardIcon: $r('app.media.ic_card_apple'),
          unit: $r('app.string.unit_number'),
          flag: TaskFlag.MULTI
        };
      case TaskType.SMILE:
        return {
          name: $r('app.string.task_smile'),
          taskIcon: $r('app.media.ic_task_smile'),
          dialogIcon: $r('app.media.ic_dialog_smile'),
          cardIcon: $r('app.media.ic_card_smile'),
          flag: TaskFlag.SINGLE
        };
      case TaskType.BRUSH:
        return {
          name: $r('app.string.task_brush'),
          taskIcon: $r('app.media.ic_task_brush'),
          dialogIcon: $r('app.media.ic_dialog_brush'),
          cardIcon: $r('app.media.ic_card_clean'),
          flag: TaskFlag.SINGLE
        };
      case TaskType.SLEEP:
        return {
          name: $r('app.string.task_sleep'),
          taskIcon: $r('app.media.ic_task_sleep'),
          dialogIcon: $r('app.media.ic_dialog_sleep'),
          cardIcon: $r('app.media.ic_card_sleep'),
          flag: TaskFlag.SINGLE
        };
      default:
        throw new Error('Unknown TaskType');
    }
  }
}
