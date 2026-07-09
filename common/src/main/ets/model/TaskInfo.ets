import { TaskType, TaskFlag } from './TaskType';

@Observed
export class TaskInfo {
  taskType: TaskType;
  isOpen: boolean;
  targetValue: number;
  flag: TaskFlag;
  reminderEnable: boolean;
  reminderTime: string;

  constructor(taskType: TaskType, flag: TaskFlag) {
    this.taskType = taskType;
    this.flag = flag;
    this.isOpen = false;
    this.targetValue = 1;
    this.reminderEnable = false;
    this.reminderTime = '08:00';
  }
}
