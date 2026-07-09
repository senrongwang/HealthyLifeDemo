import { TaskType } from './TaskType';

@Observed
export class TaskRecord {
  date: string;
  taskType: TaskType;
  finNum: number;
  targetValue: number;

  constructor(date: string, taskType: TaskType, targetValue: number) {
    this.date = date;
    this.taskType = taskType;
    this.targetValue = targetValue;
    this.finNum = 0;
  }

  get isDone(): boolean {
    return this.finNum >= this.targetValue;
  }
}
