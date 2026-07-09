# Phase 2：Data 层 实施记录

> 阶段：Phase 2 Data 层
> 执行日期：2026-07-09
> 状态：✅ 已完成（10/10 任务）
> 构建结果：BUILD SUCCESSFUL（16s；修复 2 类编译错误后通过；剩余非致命警告）

---

## 1. 阶段目标

实现 RDB 持久化、首选项存储、Repository 数据门面与 DateUtils/Constants/Logger 工具类，对 ViewModel/FormAbility 暴露统一数据接口。

依据：
- `docs/设计文档.md` §5 数据存储设计（5.1 RDB / 5.2 Prefs / 5.3 TaskRepository）
- `docs/实施计划/00-主干实施方案.md` Phase 2
- `docs/实施计划/待完成功能列表.md` P2-1 ~ P2-10

**验证标准**（实施方案）：`arkts_check` 通过；`build_project` 成功；Repository 方法签名与设计文档 §5.3 一致。

---

## 2. 任务执行清单

| 编号 | 任务 | 产出文件 | 结果 |
|---|---|---|---|
| P2-1 | RdbHelper 单例 | `data/db/RdbHelper.ets` | ✅ |
| P2-2 | RdbTables 常量 | `data/db/RdbTables.ets` | ✅ |
| P2-3 | PrefsHelper 单例 | `data/prefs/PrefsHelper.ets` | ✅ |
| P2-4 | DateUtils | `common/DateUtils.ets` | ✅ |
| P2-5 | Constants | `common/Constants.ets` | ✅ |
| P2-6 | Logger | `common/Logger.ets` | ✅ |
| P2-7 | TaskRepository（init/getTasks/upsertTask/getTodayRecords/clockIn） | `data/repository/TaskRepository.ets` | ✅ |
| P2-8 | TaskRepository 续（isAllDoneToday/getDayProgress/getWeekProgress/getStreak） | 同上 | ✅ |
| P2-9 | TaskRepository 续（onAllDone/checkAchievements/maybeRollOverDate） | 同上 | ✅ |
| P2-10 | common/Index.ets 导出 data+common | 更新 Index | ✅ |

---

## 3. 关键技术决策与修正

### 3.1 ResultSet 无 getInt，整数列用 getLong（编译错误修正）

**报错**：`Property 'getInt' does not exist on type 'ResultSet'`（TaskRepository 9 处）。

**查证**：当前 `@kit.ArkData` relationalStore 的 `ResultSet` 不提供 `getInt`；SQLite INTEGER 列经 `getLong(columnIndex): number` 读取（64 位）。`getString` / `isColumnNull` / `getColumnIndex` / `goToNextRow` / `goToFirstRow` / `close` 均存在（未报错）。

**修正**：全部 `rs.getInt(...)` → `rs.getLong(...)`（replaceAll）。reminderTime 用 `isColumnNull` 守卫后 `getString`。一次修复消除全部 TaskRepository 错误。

### 3.2 preferences.get 非泛型，返回 ValueType 联合——用 typeof 守卫收窄（编译错误修正）

**报错**：`Type 'ValueType' is not assignable to type 'number'/'string'/'boolean'`（PrefsHelper 7 处 getter）。

**查证**（arkts_knowledge_search）：`preferences.get(key, defValue): ValueType`（Cangjie 文档亦确认 `get(key, defValue: PreferencesValueType): PreferencesValueType`），**非泛型 `get<T>`**——defValue 的类型不会传导到返回类型；返回 `ValueType`（number|string|boolean|数组|Uint8Array|null 联合）。早期网上示例的 `get(key, def:string): string` wrapper 在 ArkTS strict 下同样不合规。

**决策**：禁用 `as` 强转的前提下，唯一合规收窄手段是 `typeof` 类型守卫（ArkTS 允许 `typeof v === 'number'` 原始类型收窄）：
```typescript
const v = await p.get(Constants.PREF_KEY_STREAK, 0);   // v: ValueType
if (typeof v === 'number') { return v; }                // 收窄为 number
return 0;
```
7 个 getter（getStreak/getLastCompleteDate/getTotalDays/getHighestStreak/getAchievements/getFirstLaunch/getCurrentDate）统一采用 typeof 守卫；setter 的 `put(key, value)` 接受 ValueType 入参，number/string/boolean 本身即其成员，无需处理。achievements 逗号串经 `parseAchievements` 转 `number[]`。

### 3.3 写操作用 executeSql 字符串拼接，规避 ValuesBucket 类型坑

ArkTS strict 下 `relationalStore.ValuesBucket`（含 index 签名的联合）对象字面量易触发 `arkts-no-untyped-obj-literals`。且本应用所有写入值均受控（枚举 number、布尔→0/1、reminderTime 固定 "HH:MM"），无注入风险。

**决策**：upsertTask / clockIn 的 UPDATE / ensureRecord 的 INSERT 一律用 `store.executeSql(sql)` + 模板字符串拼接（枚举先赋给 `number` 局部变量再插值，规避枚举直接入模板的歧义）；读操作用 `RdbPredicates` + `store.query` + `ResultSet` 遍历。全程不构造 ValuesBucket。

### 3.4 number→enum 转换用 switch，规避 `as` 与 number→enum 直赋

ArkTS 对 number→enum 直赋可能按名义类型拒绝。`toTaskType(n)` / `toTaskFlag(n)` 用 switch 显式映射 0..5 → TaskType、0/1 → TaskFlag，返回合法枚举值，无 `as`、无直赋。default 兜底 GETUP/SINGLE。

### 3.5 onCreate 概念以幂等 SQL 实现

`relationalStore.StoreConfig` 无 `onCreate` 回调字段。设计 §5.1 "onCreate 建表 + 预置 6 行" 以**首次 getStore 后顺序执行** `CREATE TABLE IF NOT EXISTS` ×2 + `CREATE UNIQUE INDEX IF NOT EXISTS` + `INSERT OR IGNORE`（6 行）实现——全部幂等，DB 已存在时为 no-op；store 实例缓存，建表/预置每进程仅执行一次。

### 3.6 Repository 方法 async 化（签名适配）

设计 §5.3 列同步签名，但 RDB/Prefs 均 async。Repository 12 方法全部 `async` 返回 `Promise<T>`（clockIn 返回 `Promise<TaskRecord | null>`）。方法名/语义与 §5.3 一致；ViewModel（Phase 3）将 await。Repository 不触碰 AppStorage（§6.4 卡片经 Repository 直读、不依赖 ViewModel），streak/achievements 等状态写 Prefs，由 ViewModel 同步至 AppStorage。

### 3.7 PrefsHelper/RdbStore 空安全用局部变量收窄

字段 `pref: Preferences | null` / `rdbStore: RdbStore | null`。每个访问器将字段赋给局部 `const p = this.pref;` 后 null 判断收窄——局部变量收窄在 ArkTS 最可靠（`this.field` 跨语句收窄不一定成立）。未初始化时 getter 返回类型默认值（0/''/true/[]），保证 pre-init 调用安全。

---

## 4. 最终产物结构

```
common/src/main/ets/
├── common/
│   ├── Constants.ets     # DB_NAME/PREF_STORE_NAME/7 PREF_KEY_*/7 APP_KEY_*/DEFAULT_REMINDER_TIME
│   ├── Logger.ets        # 静态 info/warn/error/debug（hilog domain 0xFF00 tag HealthyLife）
│   └── DateUtils.ets     # today/formatDate/parseDate/getWeekIndex(0=Mon)/getWeekIndexByStr/compareDate/addDays/getWeekDates
├── data/
│   ├── db/
│   │   ├── RdbTables.ets        # 表名/列名/CREATE_TASK/CREATE_TASK_RECORD/CREATE_INDEX/SEED_TASKS SQL
│   │   └── RdbHelper.ets        # 单例 getStore(context)：建表+索引+预置 6 行；缓存 store
│   ├── prefs/
│   │   └── PrefsHelper.ets      # 单例 7 键 typed getter/setter（typeof 守卫收窄 ValueType）
│   └── repository/
│       └── TaskRepository.ets   # 单例 12 方法数据门面
└── (model/ — Phase 1)
common/Index.ets                  # re-export model + common + data 全部符号
```

### TaskRepository 方法一览（§5.3 对齐）

| 方法 | 返回 | 要点 |
|---|---|---|
| init(context) | Promise<void> | 建 store+prefs；首次写 current_date |
| getTasks() | Promise<TaskInfo[]> | 全表查 6 行映射 |
| upsertTask(task) | Promise<void> | INSERT ON CONFLICT DO UPDATE |
| getTodayRecords() | Promise<TaskRecord[]> | 为 open 任务 ensureRecord(INSERT OR IGNORE) 后查 |
| clockIn(taskType) | Promise<TaskRecord\|null> | finNum+1 封顶 targetValue，UPDATE 回写 |
| isAllDoneToday() | Promise<boolean> | 遍历 open 任务查 record.isDone |
| getDayProgress(date) | Promise<DayProgress> | done/total/progress/weekIndex |
| getWeekProgress() | Promise<DayProgress[]> | 本周 7 天复用 getDayProgress |
| getStreak() | Promise<number> | 读 pref streak_days |
| onAllDone() | Promise<void> | 昨天→+1/今天→幂等/否则→1；total++/highest 更新 |
| checkAchievements() | Promise<number> | 比对 ACHIEVEMENT_THRESHOLDS 返回新解锁(0 无) |
| maybeRollOverDate() | Promise<void> | current_date≠today 时更新 |

---

## 5. 构建验证记录

### 5.1 首次构建（ getInt 误用 + ValueType 直赋）
```
ERROR:18  Property 'getInt' does not exist on type 'ResultSet'（TaskRepository 9+ 处）
BUILD FAILED in 15s
```
→ 触发 3.1 修正（getInt→getLong）

### 5.2 第二次构建（ ValueType 未收窄）
```
ERROR:8  Type 'ValueType' is not assignable to type 'number'/'string'/'boolean'（PrefsHelper 7 getter）
BUILD FAILED in 14s
```
TaskRepository 已清零；→ 触发 3.2 修正（typeof 守卫）

### 5.3 第三次构建（修正后）
```
> hvigor Finished :entry:default@CompileArkTS...
> hvigor Finished :entry:default@PackageHap... after 699 ms
> hvigor BUILD SUCCESSFUL in 15 s 982 ms
```
- 全部 ERROR 清零；CompileArkTS 通过。
- 剩余 ~60 条 WARN：`Function may throw exceptions. Special handling is required.`——针对 getRdbStore/executeSql/query/put/flush/get 等可能抛 BusinessError 的异步 API 的提示性警告，非致命。设计未要求全量 try-catch；按规则忽略 WARN。
- 依赖链 entry→common 有效；common/Index.ets 导出 data+common 编译通过。

---

## 6. 遗留与衔接

| 项 | 说明 |
|---|---|
| 异步 API throw 警告 | RDB/Prefs 异步调用可能抛 BusinessError，当前未 try-catch（仅 WARN 不阻断构建）；如需零警告可后续统一包裹 |
| Repository 未连 AppStorage | streak/achievements 写 Prefs；Phase 3 ViewModel 负责读 Repository 并同步 AppStorage（currentDate/streakDays/todayAllDone/taskList/todayRecords/achievementList） |
| EntryAbility 未调 init | Phase 4 P4-7 在 EntryAbility 注入 AppStorage 初始值 + 调 TaskRepository.getInstance().init(this.context) |
| 卡片直读路径 | Phase 8 FormAbility 将调 TaskRepository.getTasks/getDayProgress（不经 ViewModel），§6.4 隔离已由模块边界保证 |

**下一阶段**：Phase 3 ViewModel 层（P3-1 ~ P3-5），实现 Home/Task/Achievement/Mine/History 五个 ViewModel，封装页面状态与业务逻辑，接线 Repository 与 AppStorage。

**界面可查看提醒**：Phase 2 为纯数据层，无可视界面。界面自 **Phase 4（基础页面骨架）** 起可查看——届时 SplashPage/MainTab/HomeTab/MineTab/AchievementPage 骨架可在 `start_app` 拉起，届时会主动提醒。
