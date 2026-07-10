# Phase 8 — 服务卡片（F7 / F8 / F9 / F10）

> 日期：2026-07-10
> 目标：桌面 1x2 任务列表卡片 + 2x2 进度卡片，点击拉起主页，定时次日重置。

---

## 阶段目标

实现 ArkTS 动态服务卡片，包含两张桌面卡片：
1. **1x2 任务列表卡片**（card_1x2）：纵向 List 显示已添加任务，每行 ic_card 图标 + 名称 + 完成状态。
2. **2x2 进度卡片**（card_2x2）：环形进度条 + 百分比 + target_progress 文案 + doneCount/totalCount 计数。

卡片由 `FormAbility`（FormExtensionAbility）管理生命周期，通过 `TaskRepository` 直读 RDB 数据（不读 AppStorage），经 `formProvider.updateForm` 推送 JSON 到卡片 UI。卡片 UI 通过 `@LocalStorageProp` 接收数据。点击卡片经 `postCardAction` router 事件拉起 EntryAbility。定时刷新（scheduledUpdateTime=00:00）触发 `onUpdateForm` 调用 `maybeRollOverDate` 实现次日重置。

---

## 任务执行清单

| 编号 | 任务 | 产出文件 | 结果 |
|---|---|---|---|
| P8-1 | form_config.json 声明两张卡片 | `resources/base/profile/form_config.json` | 完成 |
| P8-2 | FormAbility 生命周期：onAddForm/onUpdateForm/onCastToNormalForm | `card/form/FormAbility.ets` | 完成 |
| P8-3 | FormAbility 调 Repository 直读 + formProvider.updateForm 推 JSON | 同上 | 完成 |
| P8-4 | WidgetCard1x2（List 纵向任务 + ic_card 图标 + 状态） | `card/widget/WidgetCard1x2.ets` | 完成 |
| P8-5 | WidgetCard2x2（ProgressRing + 百分比 + target_progress） | `card/widget/WidgetCard2x2.ets` | 完成 |
| P8-6 | 卡片点击 action 拉起 EntryAbility → MainTab | 更新 FormAbility + EntryAbility | 完成 |
| P8-7 | onUpdateForm 调 maybeRollOverDate 次日重置 | 更新 FormAbility | 完成 |
| P8-8 | module.json5 extensionAbilities 声明 FormAbility | 更新 entry/module.json5 | 完成 |
| P8-9 | main_pages.json 追加卡片页路径 | 更新 main_pages.json | 完成 |

---

## 关键技术决策与修正

### 1. 卡片数据传递策略：扁平字段 vs JSON 数组

- **决策**：FormAbility 推送扁平 `Record<string, string>` 字段（task0Type/task0Done/task0Fin/task0Target × 6 + taskCount/progress/doneCount/totalCount/hasTasks），而非 JSON 数组。
- **理由**：ArkTS 文档明确"卡片数据会被转换成 string 类型"，`@LocalStorageProp` 接收值为 string。JSON.parse 返回 Object 无法在 strict 模式下安全解构（禁 as/any）。扁平字段方案完全避免解析，直接 `parseInt(task0Type, 10)` 即可。
- **代价**：24 + 5 = 29 个 @LocalStorageProp 字段，buildTaskList() 方法较长但逻辑清晰。

### 2. form_config.json 更新策略

- **scheduledUpdateTime=00:00 + updateDuration=0**：设计文档原文写 updateDuration=1440（30 天），但这会让定时刷新优先级高于定点刷新（文档："两者同时配置时，定时刷新优先生效"），导致定点刷新 00:00 不生效。改为 updateDuration=0（不生效）让 scheduledUpdateTime=00:00 生效，实现每日午夜刷新。
- **isDynamic=true**：声明为动态卡片，支持 postCardAction 交互（router 事件拉起 EntryAbility）。

### 3. FormAbility 初始化时机

- **问题**：FormExtensionAbility 运行在独立进程（form 进程），TaskRepository 可能在 EntryAbility 中已初始化，但 form 进程的 Repository 实例 rdbStore 为 null。
- **方案**：ensureInit() 方法检查 `initialized` 标志，首次调用时 `TaskRepository.getInstance().init(this.context)`，用 try/catch 包裹（禁 as，仅日志错误）。onAddForm 返回空数据后异步 ensureInit → updateFormById。

### 4. extractFormId 的 typeof 守卫

- **问题**：`want.parameters[formInfo.FormParam.IDENTITY_KEY]` 返回 Object，官方示例用 `as string` 转换，但项目禁 as。
- **方案**：`const val: Object = want.parameters[formInfo.FormParam.IDENTITY_KEY]; if (typeof val === 'string') return val;` —— 与 PrefsHelper 的 typeof 守卫模式一致。
- **踩坑**：初次使用 `formInfo.FormParam.ID_KEY` 报 "Property 'ID_KEY' does not exist"，查 formInfo API 文档确认正确属性名为 `IDENTITY_KEY`。

### 5. @Entry LocalStorage 参数

- **问题**：arkts_check 报 `@Entry should have a parameter, like '@Entry(storage)'`。
- **方案**：每张卡片创建独立 `let storage1x2/storage2x2 = new LocalStorage()` 并传入 `@Entry(storage1x2)`，系统将 formBindingData 注入此 LocalStorage。
- **踩坑**：两文件同用 `let cardStorage` 变量名导致"Cannot redeclare block-scoped variable"编译错误 → 改为不同变量名。

### 6. main_pages.json 卡片路径

- **踩坑**：设计文档 §13.1 示例路径为 `ets/card/widget/WidgetCard1x2`，但 main_pages.json 的 src 路径是相对于 `src/main/ets/` 的，不需要 `ets/` 前缀。初版用 `ets/card/widget/...` 导致路径拼接为 `src/main/ets/ets/card/widget/...`（双重 ets）→ 报 "Page does not exist"。
- **修正**：路径改为 `card/widget/WidgetCard1x2`（相对于 `src/main/ets/`）。

### 7. 卡片 UI 资源引用

- 卡片 UI 通过 `getCardIcon(type)` / `getTaskName(type)` switch 语句返回 `$r('app.media.ic_card_*')` / `$r('app.string.task_*')`，与 TaskConstants.getMeta 同模式（HAR ResManager）。
- 卡片不 import TaskConstants（避免卡片场景对 common HAR 的深度依赖），而是自行实现 switch 映射。

---

## 最终产物结构

```
新增：
  entry/src/main/ets/card/form/FormAbility.ets         # FormExtensionAbility 生命周期 + 数据构建
  entry/src/main/ets/card/widget/WidgetCard1x2.ets     # 1x2 任务列表卡片 UI
  entry/src/main/ets/card/widget/WidgetCard2x2.ets     # 2x2 进度卡片 UI

修改：
  entry/src/main/resources/base/profile/form_config.json   # 空 forms[] → 2 张卡片声明
  entry/src/main/resources/base/profile/main_pages.json   # +2 卡片页路径
  entry/src/main/module.json5                              # extensionAbilities +FormAbility
  entry/src/main/ets/entryability/EntryAbility.ets         # +onNewWant 处理卡片 router 事件
  common/src/main/resources/base/element/string.json      # +7 卡片相关 string
  common/src/main/resources/en_US/element/string.json     # +7 卡片相关 string
  common/src/main/resources/zh_CN/element/string.json     # +7 卡片相关 string
```

### 新增 string 资源

| key | base/en_US | zh_CN |
|---|---|---|
| card_1x2_display_name | Task list | 任务列表 |
| card_1x2_desc | Show added tasks | 显示已添加任务 |
| card_2x2_display_name | Task progress | 任务进度 |
| card_2x2_desc | Show task completion progress | 显示任务完成进度 |
| card_no_task | No tasks | 暂无任务 |
| card_done | Done | 已完成 |
| card_undone | Undone | 未完成 |

---

## 构建验证记录

| 步骤 | 命令 | 结果 |
|---|---|---|
| arkts_check | FormAbility.ets | 0 ERROR（修复 ID_KEY→IDENTITY_KEY 后无诊断） |
| arkts_check | WidgetCard1x2.ets + WidgetCard2x2.ets | 0 ERROR（修复 @Entry(storage) 后无诊断） |
| devecocli build（第1次） | 增量构建 | FAILED：main_pages.json 路径双重 ets/ets/ + 两卡片 cardStorage 同名冲突 |
| devecocli build（第2次） | 增量构建 | BUILD SUCCESSFUL in 7s 306ms，CompileArkTS 5.4s，仅预存 WARN（async throw + deprecated API），无新增 ERROR |

---

## 遗留与衔接

- **运行时验证**：构建已 SUCCESS，但桌面添加卡片、点击拉起、次日重置等运行时行为需在真机/模拟器验证（留待 Phase 10 集成验证）。
- **数据刷新时机**：当前 onAddForm 返回空数据后异步更新（首次添加卡片可能闪一下空白）。可优化为 onAddForm 同步返回缓存数据（如有），但需 Repository 已初始化。
- **formConfigAbility**：配置为 `ability://EntryAbility`，桌面长按卡片"编辑"选项将拉起 EntryAbility。
- **下一阶段**：Phase 9 通知提醒（ReminderHelper + reminderAgentManager）。
