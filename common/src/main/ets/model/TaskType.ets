export enum TaskType {
  GETUP = 0,
  DRINK = 1,
  APPLE = 2,
  SMILE = 3,
  BRUSH = 4,
  SLEEP = 5
}

export enum TaskFlag {
  SINGLE = 0,
  MULTI = 1
}

export const ACHIEVEMENT_THRESHOLDS: number[] = [3, 7, 30, 50, 73, 99];

export function isReminderSupported(type: TaskType): boolean {
  return type === TaskType.GETUP || type === TaskType.SLEEP;
}
