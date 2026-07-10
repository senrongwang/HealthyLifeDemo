import { relationalStore } from '@kit.ArkData';
import { RdbHelper } from '../db/RdbHelper';
import { RdbTables } from '../db/RdbTables';
import { PrefsHelper } from '../prefs/PrefsHelper';
import { Constants } from '../../common/Constants';
import { Logger } from '../../common/Logger';
import { DateUtils } from '../../common/DateUtils';
import { TaskType, TaskFlag, ACHIEVEMENT_THRESHOLDS } from '../../model/TaskType';
import { TaskInfo } from '../../model/TaskInfo';
import { TaskRecord } from '../../model/TaskRecord';
import { DayProgress } from '../../model/DayProgress';

export class TaskRepository {
  private static instance: TaskRepository | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private pref: PrefsHelper = PrefsHelper.getInstance();

  public static getInstance(): TaskRepository {
    if (TaskRepository.instance === null) {
      TaskRepository.instance = new TaskRepository();
    }
    return TaskRepository.instance;
  }

  public async init(context: Context): Promise<void> {
    this.rdbStore = await RdbHelper.getInstance().getStore(context);
    await this.pref.getStore(context);
    const cur: string = await this.pref.getCurrentDate();
    if (cur.length === 0) {
      await this.pref.setCurrentDate(DateUtils.today());
    }
    await this.seedHistoryComplete();
    Logger.info('TaskRepository initialized');
  }

  public async getTasks(): Promise<TaskInfo[]> {
    const store: relationalStore.RdbStore | null = this.rdbStore;
    if (store === null) {
      return [];
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(RdbTables.TASK_TABLE);
    const rs: relationalStore.ResultSet = await store.query(predicates);
    const tasks: TaskInfo[] = [];
    while (rs.goToNextRow()) {
      const taskType: TaskType = TaskRepository.toTaskType(rs.getLong(rs.getColumnIndex(RdbTables.TASK_TASK_TYPE)));
      const flag: TaskFlag = TaskRepository.toTaskFlag(rs.getLong(rs.getColumnIndex(RdbTables.TASK_FLAG)));
      const info: TaskInfo = new TaskInfo(taskType, flag);
      info.isOpen = rs.getLong(rs.getColumnIndex(RdbTables.TASK_IS_OPEN)) !== 0;
      info.targetValue = rs.getLong(rs.getColumnIndex(RdbTables.TASK_TARGET_VALUE));
      info.reminderEnable = rs.getLong(rs.getColumnIndex(RdbTables.TASK_REMINDER_ENABLE)) !== 0;
      const rtIdx: number = rs.getColumnIndex(RdbTables.TASK_REMINDER_TIME);
      info.reminderTime = rs.isColumnNull(rtIdx) ? Constants.DEFAULT_REMINDER_TIME : rs.getString(rtIdx);
      tasks.push(info);
    }
    rs.close();
    return tasks;
  }

  public async upsertTask(task: TaskInfo): Promise<void> {
    const store: relationalStore.RdbStore | null = this.rdbStore;
    if (store === null) {
      return;
    }
    const tt: number = task.taskType;
    const fl: number = task.flag;
    const isOpen: number = task.isOpen ? 1 : 0;
    const reminderEnable: number = task.reminderEnable ? 1 : 0;
    const sql: string =
      'INSERT INTO task(taskType, isOpen, targetValue, flag, reminderEnable, reminderTime) ' +
      `VALUES(${tt}, ${isOpen}, ${task.targetValue}, ${fl}, ${reminderEnable}, '${task.reminderTime}') ` +
      'ON CONFLICT(taskType) DO UPDATE SET isOpen=excluded.isOpen, targetValue=excluded.targetValue, ' +
      'reminderEnable=excluded.reminderEnable, reminderTime=excluded.reminderTime';
    await store.executeSql(sql);
  }

  public async deleteTask(taskType: TaskType): Promise<void> {
    const store: relationalStore.RdbStore | null = this.rdbStore;
    if (store === null) {
      return;
    }
    const tt: number = taskType;
    const today: string = DateUtils.today();
    await store.executeSql(`DELETE FROM task_record WHERE taskType=${tt} AND date >= '${today}'`);
    await store.executeSql(`DELETE FROM task WHERE taskType=${tt}`);
    Logger.info(`deleteTask taskType=${tt} (today/future records cleared, history kept)`);
  }

  public async getTodayRecords(): Promise<TaskRecord[]> {
    const store: relationalStore.RdbStore | null = this.rdbStore;
    if (store === null) {
      return [];
    }
    const today: string = DateUtils.today();
    const tasks: TaskInfo[] = await this.getTasks();
    for (const t of tasks) {
      if (t.isOpen) {
        await this.ensureRecord(today, t.taskType, t.targetValue);
      }
    }
    const all: TaskRecord[] = await this.queryRecordsByDate(today);
    const result: TaskRecord[] = [];
    for (const r of all) {
      for (const t of tasks) {
        if (t.isOpen && t.taskType === r.taskType) {
          result.push(r);
          break;
        }
      }
    }
    return result;
  }

  public async clockIn(taskType: TaskType): Promise<TaskRecord | null> {
    const store: relationalStore.RdbStore | null = this.rdbStore;
    if (store === null) {
      return null;
    }
    const today: string = DateUtils.today();
    const tasks: TaskInfo[] = await this.getTasks();
    let taskTarget: number = 1;
    for (const t of tasks) {
      if (t.taskType === taskType) {
        taskTarget = t.targetValue;
        break;
      }
    }
    await this.ensureRecord(today, taskType, taskTarget);
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(RdbTables.TASK_RECORD_TABLE);
    predicates.equalTo(RdbTables.RECORD_DATE, today);
    predicates.equalTo(RdbTables.RECORD_TASK_TYPE, taskType);
    const rs: relationalStore.ResultSet = await store.query(predicates);
    let finNum: number = 0;
    let targetValue: number = 1;
    if (rs.goToFirstRow()) {
      finNum = rs.getLong(rs.getColumnIndex(RdbTables.RECORD_FIN_NUM));
      targetValue = rs.getLong(rs.getColumnIndex(RdbTables.RECORD_TARGET_VALUE));
    }
    rs.close();
    const newFin: number = Math.min(finNum + 1, targetValue);
    const tt: number = taskType;
    const sql: string =
      `UPDATE task_record SET finNum=${newFin} ` +
      `WHERE date='${today}' AND taskType=${tt}`;
    await store.executeSql(sql);
    const rec: TaskRecord = new TaskRecord(today, taskType, targetValue);
    rec.finNum = newFin;
    Logger.info(`clockIn taskType=${tt} finNum=${newFin}/${targetValue}`);
    return rec;
  }

  public async isAllDoneToday(): Promise<boolean> {
    const tasks: TaskInfo[] = await this.getTasks();
    const records: TaskRecord[] = await this.getTodayRecords();
    let openCount: number = 0;
    for (const t of tasks) {
      if (t.isOpen) {
        openCount++;
        let done: boolean = false;
        for (const r of records) {
          if (r.taskType === t.taskType) {
            done = r.isDone;
            break;
          }
        }
        if (!done) {
          return false;
        }
      }
    }
    return openCount > 0;
  }

  public async getDayProgress(date: string): Promise<DayProgress> {
    const dp: DayProgress = new DayProgress(date, DateUtils.getWeekIndexByStr(date));
    const store: relationalStore.RdbStore | null = this.rdbStore;
    if (store === null) {
      return dp;
    }
    const records: TaskRecord[] = await this.queryRecordsByDate(date);
    const today: string = DateUtils.today();
    if (DateUtils.compareDate(date, today) < 0) {
      dp.totalCount = records.length;
      let donePast: number = 0;
      for (const r of records) {
        if (r.isDone) {
          donePast++;
        }
      }
      dp.doneCount = donePast;
      dp.isAllDone = records.length > 0 && donePast >= records.length;
      return dp;
    }
    const tasks: TaskInfo[] = await this.getTasks();
    let total: number = 0;
    for (const t of tasks) {
      if (t.isOpen) {
        total++;
      }
    }
    dp.totalCount = total;
    let done: number = 0;
    for (const t of tasks) {
      if (t.isOpen) {
        for (const r of records) {
          if (r.taskType === t.taskType && r.isDone) {
            done++;
            break;
          }
        }
      }
    }
    dp.doneCount = done;
    dp.isAllDone = total > 0 && done >= total;
    return dp;
  }

  public async getWeekProgress(): Promise<DayProgress[]> {
    const dates: string[] = DateUtils.getWeekDates();
    const list: DayProgress[] = [];
    for (const d of dates) {
      list.push(await this.getDayProgress(d));
    }
    return list;
  }

  public async getStreak(): Promise<number> {
    return await this.pref.getStreak();
  }

  public async getUnlockedAchievements(): Promise<number[]> {
    return await this.pref.getAchievements();
  }

  public async onAllDone(): Promise<void> {
    const today: string = DateUtils.today();
    const last: string = await this.pref.getLastCompleteDate();
    if (last === today) {
      return;
    }
    let streak: number = await this.pref.getStreak();
    const yesterday: string = DateUtils.addDays(today, -1);
    if (last === yesterday) {
      streak = streak + 1;
    } else {
      streak = 1;
    }
    await this.pref.setStreak(streak);
    await this.pref.setLastCompleteDate(today);
    const total: number = await this.pref.getTotalDays();
    await this.pref.setTotalDays(total + 1);
    const highest: number = await this.pref.getHighestStreak();
    if (streak > highest) {
      await this.pref.setHighestStreak(streak);
    }
    Logger.info(`onAllDone streak=${streak}`);
  }

  public async checkAchievements(): Promise<number> {
    const streak: number = await this.pref.getStreak();
    const unlocked: number[] = await this.pref.getAchievements();
    for (const threshold of ACHIEVEMENT_THRESHOLDS) {
      if (streak >= threshold && unlocked.indexOf(threshold) < 0) {
        unlocked.push(threshold);
        await this.pref.setAchievements(unlocked);
        Logger.info(`achievement unlocked: ${threshold}`);
        return threshold;
      }
    }
    return 0;
  }

  public async maybeRollOverDate(): Promise<void> {
    const today: string = DateUtils.today();
    const cur: string = await this.pref.getCurrentDate();
    if (cur !== today) {
      await this.pref.setCurrentDate(today);
      Logger.info(`date rolled over to ${today}`);
    }
  }

  public async seedHistoryComplete(): Promise<void> {
    const store: relationalStore.RdbStore | null = this.rdbStore;
    if (store === null) {
      return;
    }
    const seeded: boolean = await this.pref.getHistorySeeded();
    if (seeded) {
      return;
    }
    const today: string = DateUtils.today();
    const date1: string = DateUtils.addDays(today, -2);
    const date2: string = DateUtils.addDays(today, -1);
    const tasks: TaskInfo[] = await this.getTasks();
    for (const t of tasks) {
      const tt: number = t.taskType;
      const tv: number = t.targetValue;
      await store.executeSql(`UPDATE task SET isOpen=1 WHERE taskType=${tt}`);
      const sql1: string =
        'INSERT INTO task_record(date, taskType, finNum, targetValue) ' +
        `VALUES('${date1}', ${tt}, ${tv}, ${tv}) ` +
        'ON CONFLICT(date, taskType) DO UPDATE SET finNum=excluded.finNum, targetValue=excluded.targetValue';
      await store.executeSql(sql1);
      const sql2: string =
        'INSERT INTO task_record(date, taskType, finNum, targetValue) ' +
        `VALUES('${date2}', ${tt}, ${tv}, ${tv}) ` +
        'ON CONFLICT(date, taskType) DO UPDATE SET finNum=excluded.finNum, targetValue=excluded.targetValue';
      await store.executeSql(sql2);
    }
    await this.pref.setStreak(2);
    await this.pref.setLastCompleteDate(date2);
    await this.pref.setTotalDays(2);
    await this.pref.setHighestStreak(2);
    await this.pref.setHistorySeeded(true);
    Logger.info(`seedHistoryComplete: ${date1}, ${date2}`);
  }

  private async ensureRecord(date: string, taskType: TaskType, targetValue: number): Promise<void> {
    const store: relationalStore.RdbStore | null = this.rdbStore;
    if (store === null) {
      return;
    }
    const tt: number = taskType;
    const sql: string =
      'INSERT INTO task_record(date, taskType, finNum, targetValue) ' +
      `VALUES('${date}', ${tt}, 0, ${targetValue}) ` +
      'ON CONFLICT(date, taskType) DO UPDATE SET targetValue=excluded.targetValue';
    await store.executeSql(sql);
  }

  public async getRecordsByDate(date: string): Promise<TaskRecord[]> {
    return await this.queryRecordsByDate(date);
  }

  private async queryRecordsByDate(date: string): Promise<TaskRecord[]> {
    const store: relationalStore.RdbStore | null = this.rdbStore;
    if (store === null) {
      return [];
    }
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(RdbTables.TASK_RECORD_TABLE);
    predicates.equalTo(RdbTables.RECORD_DATE, date);
    const rs: relationalStore.ResultSet = await store.query(predicates);
    const records: TaskRecord[] = [];
    while (rs.goToNextRow()) {
      const taskType: TaskType = TaskRepository.toTaskType(rs.getLong(rs.getColumnIndex(RdbTables.RECORD_TASK_TYPE)));
      const targetValue: number = rs.getLong(rs.getColumnIndex(RdbTables.RECORD_TARGET_VALUE));
      const rec: TaskRecord = new TaskRecord(date, taskType, targetValue);
      rec.finNum = rs.getLong(rs.getColumnIndex(RdbTables.RECORD_FIN_NUM));
      records.push(rec);
    }
    rs.close();
    return records;
  }

  private static toTaskType(n: number): TaskType {
    switch (n) {
      case 0:
        return TaskType.GETUP;
      case 1:
        return TaskType.DRINK;
      case 2:
        return TaskType.APPLE;
      case 3:
        return TaskType.SMILE;
      case 4:
        return TaskType.BRUSH;
      case 5:
        return TaskType.SLEEP;
      default:
        return TaskType.GETUP;
    }
  }

  private static toTaskFlag(n: number): TaskFlag {
    switch (n) {
      case 0:
        return TaskFlag.SINGLE;
      case 1:
        return TaskFlag.MULTI;
      default:
        return TaskFlag.SINGLE;
    }
  }
}
