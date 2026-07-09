# Phase 1：Model 层 实施记录

> 阶段：Phase 1 Model 层
> 执行日期：2026-07-09
> 状态：✅ 已完成（7/7 任务）
> 构建结果：BUILD SUCCESSFUL（CompileArkTS 7.6s，无错误、无资源冲突警告）

---

## 1. 阶段目标

在 `common/src/main/ets/model/` 实现全部数据模型（枚举/常量/实体类/资源映射表），供 Phase 2 Data 层与 Phase 3 ViewModel 复用。

依据：
- `docs/设计文档.md` §4 数据模型（4.1 枚举与常量 / 4.2 实体类 / 4.3 静态映射表）
- `docs/实施计划/00-主干实施方案.md` Phase 1
- `docs/实施计划/待完成功能列表.md` P1-1 ~ P1-7

**验证标准**（实施方案）：`arkts_check` 全部 model 文件通过；`build_project` 成功。

---

## 2. 任务执行清单

| 编号 | 任务 | 产出文件 | 结果 |
|---|---|---|---|
| P1-1 | TaskType 枚举 + TaskFlag 枚举 + ACHIEVEMENT_THRESHOLDS + isReminderSupported | `model/TaskType.ets` | ✅ |
| P1-2 | TaskInfo 实体（@Observed） | `model/TaskInfo.ets` | ✅ |
| P1-3 | TaskRecord 实体（@Observed，isDone getter） | `model/TaskRecord.ets` | ✅ |
| P1-4 | AchievementInfo 实体 | `model/AchievementInfo.ets` | ✅ |
| P1-5 | DayProgress 实体（progress getter） | `model/DayProgress.ets` | ✅ |
| P1-6 | 任务→资源映射表（名称/图标/单位/flag） | `model/TaskConstants.ets` | ✅ |
| P1-7 | common/Index.ets 导出全部 model | 更新 Index.ets | ✅ |

---

## 3. 关键技术决策与修正

### 3.1 HAR 资源引用采用 ResManager 静态方法模式（关键决策）

**问题**：`TaskConstants` 与 `AchievementInfo` 需引用 `Resource`（图标/名称/单位）。`$r('app.media.*'/'app.string.*')` 在 HAR 模块的 model 层（非 @Component）能否使用、能否在模块顶层常量初始化时调用，存在不确定性。

**知识库查证**（arkts_knowledge_search「$r in HAR module non-UI code」）：
> HAR 包资源导出引用的官方推荐模式——导出 `ResManager` 类，以 **static 方法返回 `$r(...)`**：
> ```typescript
> export class ResManager {
>   static getPic(): Resource { return $r('app.media.11'); }
> }
> ```
> 引用方 `import { ResManager } from 'har'` 后调用。`$r` 在普通类方法体中可用，非必须位于 `build()`。

**决策**：`TaskConstants` 不用模块顶层 `const MAP = new Map(...)` 预填 `$r`，而是采用 `class TaskConstants` + `static getMeta(type): TaskMeta`，内部 `switch` 每分支 `return { ... $r(...) }`。`$r` 调用位于方法体内，符合 HAR ResManager 模式，规避模块加载期 `$r` 的潜在风险。构建验证 CompileArkTS 通过，证实此模式在 HAR model 层可用。

### 3.2 TaskMeta.unit 设为可选 Resource

**问题**：设计 §4.3 映射表中单次任务（GETUP/SMILE/BRUSH/SLEEP）单位列为"—"（无单位），仅多次任务（DRINK/APPLE）有单位。若 `unit: Resource` 必填，单次任务无合适占位资源（无"空字符串"资源）。

**决策**：`TaskMeta.unit` 设为可选 `unit?: Resource`。单次任务的对象字面量省略 `unit` 字段；多次任务设置 `unit: $r('app.string.unit_times')`（DRINK）/ `unit: $r('app.string.unit_number')`（APPLE）。View 层按 `flag === MULTI` 决定显示 "finNum/targetValue 单位" 或 "Was done"，仅 MULTI 时取 `meta.unit`。对象字面量在有返回类型上下文（`getMeta(): TaskMeta`）下省略可选字段，ArkTS 允许。

### 3.3 资源命名核对：BRUSH 卡片图标为 ic_card_clean

设计 §4.3 映射表 BRUSH 行卡片图标列为 `ic_card_clean`（非 `ic_card_brush`）。核对 `common/src/main/resources/base/media/` 实际资源：存在 `ic_card_clean.png`，无 `ic_card_brush`。`TaskConstants` BRUSH 分支 `cardIcon: $r('app.media.ic_card_clean')`，与实际资源一致。

### 3.4 TaskInfo.targetValue 构造默认统一为 1

设计 §4.2 原文 `this.targetValue = flag === TaskFlag.SINGLE ? 1 : 1;`（两分支均为 1）。保持设计原样，统一默认 1；多次任务的真实目标量由 Phase 2 RDB 预置行或用户编辑页设置，构造默认值仅用于内存占位。

### 3.5 单位映射依设计 §4.3 表（DRINK=unit_times / APPLE=unit_number）

P5-2 任务描述提及 "L/个/次" 三种单位，与 §4.3 表（DRINK→unit_times、APPLE→unit_number，仅 2 个多次任务）存在数量不一致。按 AGENTS.md「编码细节以 `设计文档.md` 为准」，遵循 §4.3 表。`unit_liter`（L）暂未引用；若 Phase 5 截图核对显示饮水应为 L，仅需改 `TaskConstants` DRINK 分支一行。

---

## 4. 最终产物结构

```
common/
├── Index.ets                              # re-export 全部 model 符号 + TaskMeta + COMMON_LIB_NAME
└── src/main/ets/model/
    ├── TaskType.ets                       # enum TaskType(0..5) / enum TaskFlag(0,1) / ACHIEVEMENT_THRESHOLDS / isReminderSupported
    ├── TaskInfo.ets                       # @Observed class（taskType/isOpen/targetValue/flag/reminderEnable/reminderTime）
    ├── TaskRecord.ets                     # @Observed class（date/taskType/finNum/targetValue + isDone getter）
    ├── AchievementInfo.ets                # class（level/days/unlocked/iconOn/iconOff:Resource）
    ├── DayProgress.ets                    # class（date/weekIndex/doneCount/totalCount/isAllDone + progress getter）
    └── TaskConstants.ets                  # interface TaskMeta + class TaskConstants.getMeta(type):TaskMeta（switch + $r）
```

### 实体字段一览

| 类 | 字段 | 类型 | 默认/计算 |
|---|---|---|---|
| TaskInfo | taskType | TaskType | 构造入参 |
| | isOpen | boolean | false |
| | targetValue | number | 1 |
| | flag | TaskFlag | 构造入参 |
| | reminderEnable | boolean | false |
| | reminderTime | string | '08:00' |
| TaskRecord | date | string | 构造入参 |
| | taskType | TaskType | 构造入参 |
| | finNum | number | 0 |
| | targetValue | number | 构造入参 |
| | isDone | boolean | getter: finNum>=targetValue |
| AchievementInfo | level/days | number | 构造入参 |
| | unlocked | boolean | false |
| | iconOn/iconOff | Resource | 构造入参 |
| DayProgress | date | string | 构造入参 |
| | weekIndex | number | 构造入参 |
| | doneCount/totalCount | number | 0 |
| | isAllDone | boolean | false |
| | progress | number | getter: total=0?0:floor(done*100/total) |

### TaskConstants 映射表（核对媒体资源后）

| TaskType | name | taskIcon | dialogIcon | cardIcon | unit | flag |
|---|---|---|---|---|---|---|
| GETUP | task_getup | ic_task_getup | ic_dialog_getup | ic_card_getup | — | SINGLE |
| DRINK | task_drink | ic_task_drink | ic_dialog_drink | ic_card_drink | unit_times | MULTI |
| APPLE | task_apple | ic_task_apple | ic_dialog_apple | ic_card_apple | unit_number | MULTI |
| SMILE | task_smile | ic_task_smile | ic_dialog_smile | ic_card_smile | — | SINGLE |
| BRUSH | task_brush | ic_task_brush | ic_dialog_brush | **ic_card_clean** | — | SINGLE |
| SLEEP | task_sleep | ic_task_sleep | ic_dialog_sleep | ic_card_sleep | — | SINGLE |

---

## 5. 构建验证记录

### 5.1 arkts_check
不可用（DEVECO_HOME 已 setx 持久化但当前会话未继承，需重启 CLI 会话）。以 `build_project` 兜底校验。

### 5.2 build_project（增量，entry@default，debug）
```
> hvigor Finished :common:default@... 
> hvigor Finished :entry:default@BuildJS... after 6 ms
> hvigor Finished :entry:default@CompileArkTS... after 7 s 667 ms
> hvigor Finished :entry:default@PackageHap... after 788 ms
> hvigor BUILD SUCCESSFUL in 18 s 901 ms
```
- CompileArkTS 通过：`TaskConstants`（$r 静态方法模式）、`@Observed` 装饰器、getter、可选字段对象字面量、Index.ets re-export 全部编译无误。
- 无资源冲突警告（仅 debug 签名提示，正常）。
- 依赖链 `entry → common` 保持有效（entry/pages/Index.ets 仍 import common）。

---

## 6. 遗留与衔接

| 项 | 说明 |
|---|---|
| TaskInfo.targetValue 默认 1 | 多次任务真实目标量由 Phase 2 RDB 预置行 / Phase 5 编辑页设置 |
| AchievementInfo 实例化 | iconOn/iconOff 的 `$r` 实参由 Phase 2（Repository/常量构建）注入，Phase 1 仅定义类 |
| TaskConstants 单位映射 | 依 §4.3 表；Phase 5 截图核对若饮水应显示 L 则改 DRINK 分支一行 |
| Index.ets 导出 | 当前仅 model 层；Phase 2 P2-10 将追加 data + common 工具类导出 |

**下一阶段**：Phase 2 Data 层（P2-1 ~ P2-10），实现 RdbHelper / PrefsHelper / TaskRepository 数据门面与 DateUtils/Constants/Logger 工具类。
