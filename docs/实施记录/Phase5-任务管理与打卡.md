# Phase 5：任务管理与打卡

## 阶段目标

实现添加/编辑任务独立页、任务列表项组件、打卡弹窗、每日打卡与进度刷新、周历组件、进度环组件，覆盖功能 F1（添加/编辑任务）、F2（打卡与进度）、F6（任务列表交互）。

依据 `docs/实施计划/00-主干实施方案.md` Phase 5 章节与 `docs/实施计划/待完成功能列表.md` Phase 5 任务清单。

---

## 任务执行清单

| 编号 | 任务 | 产出文件 | 结果 |
|---|---|---|---|
| P5-1 | TaskListItem 组件 | `view/home/TaskListItem.ets` | 已完成 |
| P5-2 | 多次任务状态显示 | 同 P5-1 | 已完成 |
| P5-3 | TaskAddPage 独立页 | `pages/TaskAddPage.ets` | 已完成 |
| P5-4 | TaskEditPage 独立页 | `pages/TaskEditPage.ets` | 已完成 |
| P5-5 | HomeTab 悬浮加号路由 | 更新 `view/home/HomeTab.ets` | 已完成 |
| P5-6 | HomeTab 空态 | 同 P5-5 | 已完成 |
| P5-7 | HomeViewModel.clockIn 接线 | 更新 `viewmodel/HomeViewModel.ets` | 已完成 |
| P5-8 | ProgressRing 组件 | `view/home/ProgressRing.ets` | 已完成 |
| P5-9 | WeekCalendar 组件 | `view/home/WeekCalendar.ets` | 已完成 |
| P5-10 | ClockInDialog 打卡弹窗 | `view/home/ClockInDialog.ets` | 已完成 |
| P5-11 | 全部完成态头部切换 | 更新 `view/home/HomeTab.ets` | 已完成 |

---

## 关键技术决策与修正

### 1. 打卡弹窗实现方式：bindContentCover vs @CustomDialog

- **决策**：HomeTab 使用 `bindContentCover` + `@Builder` 内联实现打卡弹窗，而非直接使用 `ClockInDialog.ets` 的 `@CustomDialog`。
- **原因**：`bindContentCover` 更灵活，可直接访问 HomeTab 的 `@State` 和 `@Provide` 上下文，无需额外参数传递。`ClockInDialog.ets` 保留为 `@CustomDialog` 备用组件。

### 2. 资源缺失修复：default_60

- **报错**：`Unknown resource name 'default_60'`（HomeTab.ets:142）
- **原因**：`float.json` 中无 `default_60` 定义。
- **修正**：在 `common/src/main/resources/base/element/float.json` 中新增 `default_60`（60vp）。

### 3. 双 margin 调用合并

- **问题**：HomeTab 中 Cancel 文本连续调用两次 `.margin()`，后者覆盖前者。
- **修正**：合并为单次 `.margin({ top: ..., bottom: ... })`。

### 4. TaskEditPage 路由参数

- **实现**：通过 `router.getParams()` 获取 `taskType` 和 `isAdd` 参数，区分添加/编辑模式。
- **注意**：`router.getParams()` 已 deprecated，但当前可用，Phase 10 集成验证时可考虑迁移到 `router.params`。

### 5. TaskAddPage 已添加任务判断

- **实现**：遍历 `@StorageLink('taskList')` 判断 `isOpen` 状态，已添加任务灰色显示且隐藏右箭头，不可重复点击。

---

## 最终产物结构

### 新增文件

```
entry/src/main/ets/
├── pages/
│   ├── TaskAddPage.ets        # 添加任务页（6 任务选择列表）
│   └── TaskEditPage.ets       # 编辑任务页（Toggle/TimePicker/目标设置）
└── view/home/
    ├── TaskListItem.ets       # 任务列表项组件
    ├── ProgressRing.ets       # 环形进度组件
    ├── WeekCalendar.ets       # 周历组件
    └── ClockInDialog.ets      # 打卡弹窗组件（@CustomDialog）
```

### 修改文件

```
entry/src/main/ets/view/home/HomeTab.ets       # 悬浮加号+空态+打卡弹窗+全完成态
entry/src/main/ets/viewmodel/HomeViewModel.ets  # clockIn 接线+onAllDone
entry/src/main/resources/base/profile/main_pages.json  # 已含 TaskAddPage/TaskEditPage
common/src/main/resources/base/element/float.json       # 新增 default_60
```

---

## 构建验证记录

| 次序 | 命令 | 结果 | 备注 |
|---|---|---|---|
| 1 | `devecocli build` | ERROR | `Unknown resource name 'default_60'` |
| 2 | 补 float.json `default_60` + 合并双 margin | — | 修正后重编 |
| 3 | `devecocli build` | **BUILD SUCCESSFUL** (6.3s) | CompileArkTS 2.9s，0 ERROR，73 WARN（均为预存 deprecated/throw 警告） |

---

## 遗留与衔接

- **deprecated API 警告**：`router.pushUrl`/`router.back`/`router.getParams`/`router.replaceUrl` 均已 deprecated，当前功能正常，Phase 10 集成验证时可统一迁移到新 API。
- **运行时验证**：构建通过但未在模拟器/真机运行验证，留待 Phase 10 集成验证。
- **Phase 6 衔接**：Phase 5 的 `onAllDone` 已触发 streak 递增和成就检查（`checkAchievements`），但成就弹窗仅为 log 占位（`showAchievementDialog`），Phase 6 需实现 `AchievementDialog` 动画弹窗。
