export class RdbTables {
  public static readonly TASK_TABLE: string = 'task';
  public static readonly TASK_RECORD_TABLE: string = 'task_record';

  public static readonly TASK_TASK_TYPE: string = 'taskType';
  public static readonly TASK_IS_OPEN: string = 'isOpen';
  public static readonly TASK_TARGET_VALUE: string = 'targetValue';
  public static readonly TASK_FLAG: string = 'flag';
  public static readonly TASK_REMINDER_ENABLE: string = 'reminderEnable';
  public static readonly TASK_REMINDER_TIME: string = 'reminderTime';

  public static readonly RECORD_ID: string = 'id';
  public static readonly RECORD_DATE: string = 'date';
  public static readonly RECORD_TASK_TYPE: string = 'taskType';
  public static readonly RECORD_FIN_NUM: string = 'finNum';
  public static readonly RECORD_TARGET_VALUE: string = 'targetValue';

  public static readonly CREATE_TASK_SQL: string =
    'CREATE TABLE IF NOT EXISTS task (' +
    'taskType INTEGER PRIMARY KEY, ' +
    'isOpen INTEGER NOT NULL DEFAULT 0, ' +
    'targetValue INTEGER NOT NULL DEFAULT 1, ' +
    'flag INTEGER NOT NULL, ' +
    'reminderEnable INTEGER NOT NULL DEFAULT 0, ' +
    'reminderTime TEXT)';

  public static readonly CREATE_TASK_RECORD_SQL: string =
    'CREATE TABLE IF NOT EXISTS task_record (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'date TEXT NOT NULL, ' +
    'taskType INTEGER NOT NULL, ' +
    'finNum INTEGER NOT NULL DEFAULT 0, ' +
    'targetValue INTEGER NOT NULL)';

  public static readonly CREATE_INDEX_SQL: string =
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_date_task ON task_record(date, taskType)';

  public static readonly SEED_TASKS_SQL: string =
    'INSERT OR IGNORE INTO task(taskType, flag) VALUES ' +
    '(0, 0), (1, 1), (2, 1), (3, 1), (4, 1), (5, 0)';
}
