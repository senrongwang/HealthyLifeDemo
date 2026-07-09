# Phase 3：ViewModel 层 实施记录

> 阶段：Phase 3 ViewModel 层
> 执行日期：2026-07-09
> 状态：✅ 已完成（5/5 任务）
> 构建结果：BUILD SUCCESSFUL（CompileArkTS 7.3s，0 ERROR）

---

## 1. 阶段目标

实现 5 个 ViewModel，封装页面状态与业务逻辑，接线 Repository（数据）与 AppStorage（全局共享态），不持有 UI 组件引用。

依据：
- `docs/设计文档.md` §8 ViewModel 职责、§9.1 骨架、§6 状态管理
- `docs/实施计划/00-主干实施方案.md` Phase 3
- `docs/实施计划/待完成功能列表.md` P3-1 ~ P3-5

**验证标准**（实施方案）：`arkts_check` 通过；`build_project` 成功；ViewModel 不持有 UI 引用。

---

## 2. 任务执行清单

| 编号 | 任务 | 产出文件 | 结果 |
|---|---|---|---|
| P3-1 | HomeViewModel | `entry/.../viewmodel/HomeViewModel.ets` | ✅ |
| P3-2 | TaskViewModel | `entry/.../viewmodel/TaskViewModel.ets` | ✅ |
| P3-3 | AchievementViewModel | `entry/.../viewmodel/AchievementViewModel.ets` | ✅ |
| P3-4 | MineViewModel | `entry/.../viewmodel/MineViewModel.ets` | ✅ |
| P3-5 | HistoryViewModel | `entry/.../viewmodel/HistoryViewModel.ets` | ✅ |
| 附 | Repository 补 `getUnlockedAchievements()` 只读访问器 | 更新 TaskRepository | ✅ |

---

## 3. 关键技术决策与修正

### 3.1 ViewModel 为普通类（非 @State/@Observed）

设计 §8.1 称 ViewModel "持有 @State"，但 `@State` 是组件级装饰器，不能用于普通类。按 §9.1 骨架，5 个 ViewModel 均为**普通 class**，字段为普通引用；状态响应式由 Phase 4 组件侧承担（`@StorageLink` 绑 AppStorage 键 / `@State` 持有 ViewModel + `@ObjectLink` 子组件接收 @Observed 的 TaskInfo/TaskRecord）。ViewModel 仅负责逻辑与 AppStorage 同步。

### 3.2 clockIn 用 Repository.isAllDoneToday 权威判定触发 onAllDone（对骨架的修正）

设计 §9.1 骨架在 `clockIn` 末依 `this.todayProgress.isAllDone`（refreshProgress 算出的近似值）触发 `onAllDone()`——streak 增量关乎正确性，近似值不可靠（已关闭任务的残留 record 可能干扰 doneCount）。

**修正**：新增 `refreshAllDone()` 调 `await TaskRepository.getInstance().isAllDoneToday()`（Phase 2 已实现的 open 任务精确判定）写回 `todayProgress.isAllDone` 与 AppStorage；`clockIn`/`loadTodayTasks` 均调之。`refreshProgress()` 仅算进度环显示用的 totalCount/doneCount（近似，不影响逻辑）。

### 3.3 Repository 补 getUnlockedAchievements 只读访问器

`AchievementViewModel.loadAchievements` 需读 `achievements_unlocked` 标记 unlocked，但 Repository 仅有 `checkAchievements()`（**有副作用**：会写入新解锁）。读列表不能调它。故在 Repository 增 `getUnlockedAchievements(): Promise<number[]>`，直接转调 `PrefsHelper.getAchievements()`（无副作用）。属 Phase 2 数据门面的合理扩展，方法语义与 §5.3 风格一致。

### 3.4 $r 在普通类方法体可用（entry 模块同样成立）

`AchievementViewModel.badgeIcon(days, on)` 与 `MineViewModel` 的用户信息/菜单 getter 均在**普通类方法体**内调 `$r('app.media.*'/'app.string.*')`。延续 Phase 1 确立的 ResManager 模式（$r 在方法体内调用，非模块顶层常量）。构建通过，证实 entry 模块普通类同样适用。

**资源可见性**：MineViewModel/AchievementViewModel 引用的 `user_name`/`mine_*`/`ic_user`/`ic_badge_*` 等资源位于 common(HAR)，HAR 资源在构建期合并入 HAP 资源索引，entry 经 `$r` 可直接命中（Phase 0 已验证 module-vs-module 仅同名告警、HAR 资源对 HAP 可见）。

### 3.5 数组遍历用显式 for 循环 / slice，规避箭头回调风险

`refreshProgress`/`replaceRecord` 用 `for (const x of arr)` 与索引 `for` 循环替代骨架的 `filter`/`findIndex` 箭头回调（与 Phase 2 Repository 风格一致，降低 ArkTS 回调限制风险）。`replaceRecord` 用 `todayRecords.slice()` 整体替换数组引用（满足 ArkUI 数组刷新需整体赋值的约束，§6.2）。

### 3.6 AppStorage.setOrCreate 省略显式类型参数

骨架用 `AppStorage.setOrCreate<TaskInfo[]>(...)`。`setOrCreate` 实参传 `TaskInfo[]`/`boolean`/`string`/`number` 时由入参隐式确定类型，省略 `<T>` 避免泛型签名不确定的编译风险。构建通过。

### 3.7 MineViewModel.navigate 用 router.pushUrl（导航非 UI 引用）

设计 §8.4 明确 MineViewModel 承担菜单跳转路由。`navigate(index)` 对成就项(index 2) 调 `router.pushUrl({ url: 'pages/AchievementPage' })`（`router` 自 `@kit.ArkUI` 导入，RouterOptions 字面量由参数类型上下文约束）；其余菜单项 `Logger.info` 占位。`router` 为导航 API 而非 UI 组件引用，符合 "ViewModel 不持有 UI 引用" 约束。AchievementPage 路径 Phase 4 P4-6 注册到 main_pages.json 后运行期生效（当前编译期字符串无害）。

### 3.8 TaskViewModel 辅助方法预置

除设计点名的 openAdd/openEdit/save/validateTarget，预置 `isReminderType`/`isMultiType`/`formatReminderTime` 三个辅助方法，供 Phase 5 TaskEditPage（TimePicker/Toggle/目标设置行）直接复用，避免届时回改 ViewModel。ReminderHelper 联动为 Phase 9 P9-3 在 `save` 内补充。

---

## 4. 最终产物结构

```
entry/src/main/ets/viewmodel/
├── HomeViewModel.ets        # taskList/todayRecords/todayProgress + loadTodayTasks/clockIn/refreshProgress/onAllDone/showAchievementDialog(stub)/replaceRecord
├── TaskViewModel.ets        # draft + openAddDialog/openEditDialog/getDraft/save/validateTarget + isReminderType/isMultiType/formatReminderTime
├── AchievementViewModel.ets # achievementList + loadAchievements + badgeIcon(switch $r)
├── MineViewModel.ets        # 用户信息 getter + 3 菜单 getTitle + navigate(router)
└── HistoryViewModel.ets     # weekProgress + loadWeekProgress
common/.../repository/TaskRepository.ets  # +getUnlockedAchievements()（只读）
```

### AppStorage 同步点（Phase 4 组件将 @StorageLink 绑定）

| ViewModel | 写入 AppStorage 键 |
|---|---|
| HomeViewModel | taskList / todayRecords / currentDate / todayAllDone / streakDays |
| AchievementViewModel | achievementList |

---

## 5. 构建验证记录

### 5.1 build_project（增量，entry@default，debug）
```
> hvigor Finished :entry:default@CompileArkTS... after 7 s 327 ms
> hvigor Finished :entry:default@PackageHap... after 758 ms
> hvigor BUILD SUCCESSFUL in 19 s 447 ms
```
- 0 ERROR（日志 grep `ERROR:|Error Message` 命中 0）。
- 仅剩 Phase 2 遗留的「Function may throw exceptions」WARN（Repository 异步 DB/Prefs 调用），ViewModel 文件无新增警告。
- AppStorage / `$r`(普通类方法) / `router.pushUrl`(RouterOptions 字面量) / for-of / slice 全部编译通过。

### 5.2 验证标准核对
- ✅ build_project 成功
- ✅ ViewModel 不持有 UI 组件引用（仅 AppStorage/router 导航 API/$r Resource）
- ⚠️ arkts_check 不可用（DEVECO_HOME 待重启会话），以 build 兜底

---

## 6. 遗留与衔接

| 项 | 说明 |
|---|---|
| HomeViewModel.showAchievementDialog | 当前仅 Logger 占位；Phase 6 P6-4 实装 openCustomDialog + animateTo 动画弹窗 |
| TaskViewModel.save 的 ReminderHelper 联动 | Phase 9 P9-3 在 save 内补 getup/sleep reminderEnable 变更同步 |
| MineViewModel.navigate(0)/(1) | personal_data/check_updates 无目标页，log 占位；本应用不实装 |
| ViewModel↔组件接线 | Phase 4：HomeTab `@Provide('homeVM')` + `@State`/`@StorageLink` 绑 AppStorage 键；TaskListItem `@ObjectLink`+`@Consume` |
| todayProgress 响应式 | DayProgress 非 @Observed；Phase 4 组件需整体重赋 todayProgress 引用或改 @Observed（届时定） |

**下一阶段**：Phase 4 基础页面骨架（P4-1 ~ P4-7）——SplashPage / MainTab(2 Tab) / HomeTab / MineTab / AchievementPage 骨架 + 导航 + EntryAbility 注入 AppStorage 并调 Repository.init。

🔔 **界面可查看提醒**：Phase 4 完成后即可 `start_app` 拉起，届时 Splash→MainTab 流程、两 Tab 切换、"我的"→成就页跳转均可可视化查看。届时会再次提醒。
