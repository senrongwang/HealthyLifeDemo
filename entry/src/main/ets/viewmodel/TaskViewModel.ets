import { TaskInfo, TaskType, TaskFlag, TaskConstants, TaskMeta, TaskRepository, Constants, Logger } from 'common';

export class TaskViewModel {
  private draft: TaskInfo | null = null;

  public openAddDialog(taskType: TaskType): TaskInfo {
    const meta: TaskMeta = TaskConstants.getMeta(taskType);
    const info: TaskInfo = new TaskInfo(taskType, meta.flag);
    info.isOpen = true;
    this.draft = info;
    return info;
  }

  public openEditDialog(task: TaskInfo): TaskInfo {
    const meta: TaskMeta = TaskConstants.getMeta(task.taskType);
    const info: TaskInfo = new TaskInfo(task.taskType, meta.flag);
    info.isOpen = task.isOpen;
    info.targetValue = task.targetValue;
    info.reminderEnable = task.reminderEnable;
    info.reminderTime = task.reminderTime;
    this.draft = info;
    return info;
  }

  public getDraft(): TaskInfo | null {
    return this.draft;
  }

  public async save(task: TaskInfo): Promise<void> {
    await TaskRepository.getInstance().upsertTask(task);
    this.draft = null;
    Logger.info(`TaskViewModel save taskType=${task.taskType}`);
  }

  public validateTarget(value: number): boolean {
    return value >= 1 && value <= 99;
  }

  public isReminderType(taskType: TaskType): boolean {
    return taskType === TaskType.GETUP || taskType === TaskType.SLEEP;
  }

  public isMultiType(flag: TaskFlag): boolean {
    return flag === TaskFlag.MULTI;
  }

  public formatReminderTime(hour: number, minute: number): string {
    const hh: string = hour < 10 ? '0' + hour : '' + hour;
    const mm: string = minute < 10 ? '0' + minute : '' + minute;
    return `${hh}:${mm}`;
  }
}
