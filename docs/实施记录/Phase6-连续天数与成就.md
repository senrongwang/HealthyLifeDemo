# Phase 6：连续天数与成就 实施记录

> 阶段：Phase 6 连续天数与成就（F3/F4）
> 执行日期：2026-07-09
> 状态：✅ 已完成（6/6 任务，build SUCCESS）
> 构建结果：BUILD SUCCESSFUL（4.9s，0 ERROR；首次构建失败 2 ERROR 修复后通过）

---

## 1. 阶段目标

全勤触发 streak+1，命中阈值弹成就动画弹窗，成就页展示 6 枚徽章（2×3 网格）+ "连续X天达成"文案。

依据：
- `docs/设计文档.md` §5.3 Repository（onAllDone/checkAchievements）、§7.5 AchievementPage、§8 成就弹窗
- `docs/实施计划/00-主干实施方案.md` Phase 6
- `docs/实施计划/待完成功能列表.md` P6-1 ~ P6-6

**验证标准**（实施方案）：`build_project` 成功；全勤后 streak 递增；命中阈值弹窗；成就页可见徽章。

---

## 2. 任务执行清单

| 编号 | 任务 | 产出文件 | 结果 |
|---|---|---|---|
| P6-1 | TaskRepository.onAllDone streak 判定 | `common/.../data/repository/TaskRepository.ets` | ✅ |
| P6-2 | TaskRepository.checkAchievements 阈值比对 | 同上 | ✅ |
| P6-3 | HomeViewModel.checkAllDoneAndUnlock 接线 | `entry/.../viewmodel/HomeViewModel.ets` + `entry/.../view/home/HomeTab.ets` | ✅ |
| P6-4 | AchievementDialog（animateTo 缩放/透明度） | `entry/.../view/dialog/AchievementDialog.ets` | ✅ |
| P6-5 | AchievementPage 2×3 网格 + "连续X天达成" | `entry/.../pages/AchievementPage.ets` | ✅ |
| P6-6 | AppStorage.achievementList 同步 + 解锁写 prefs | `entry/.../viewmodel/AchievementViewModel.ets` | ✅ |

---

## 3. 关键技术决策与修正

### 3.1 P6-1/P6-2 已在 Phase 2 (P2-9) 实现

TaskRepository.onAllDone 和 checkAchievements 在 Phase 2 Data 层阶段已实现：
- `onAllDone`：读 last_complete_date，today→幂等返回，yesterday→streak+1，否则→streak=1；更新 totalDays/highestStreak
- `checkAchievements`：遍历 ACHIEVEMENT_THRESHOLDS，首个 streak>=threshold 且未解锁→push+写 prefs+返回 threshold

本阶段验证逻辑正确，无需修改。

### 3.2 P6-3 HomeViewModel 接线已在 Phase 3 (P3-1) 实现

HomeViewModel.onAllDone 方法已实现：
1. 调 `repo.onAllDone()` → streak 递增
2. 读 `repo.getStreak()` → `AppStorage.setOrCreate(APP_KEY_STREAK, streak)`
3. 调 `repo.checkAchievements()` → 返回值 >0 则调 `showAchievementDialog(days)`
4. `showAchievementDialog` 设置 `achDialogDays` + `achDialogShow=true` 到 AppStorage

**编译错误修正**：HomeTab 中 `promptAction.CustomDialogController` 类型不存在，`promptAction.openCustomDialog` 参数数量错误。

**报错原文**：
```
ERROR 1: 'promptAction' has no exported member named 'CustomDialogController'. Did you mean 'DialogController'?
ERROR 2: Expected 1 arguments, but got 2.
```

**修正**：
- `promptAction.openCustomDialog` 在 API 24 中接受单个 `CustomDialogOptions` 对象参数（builder/autoCancel/alignment），返回 `Promise<number>`（dialogId）
- 关闭用 `promptAction.closeCustomDialog(dialogId)`
- 移除 `CustomDialogController` 类型引用，改用 `achDialogId: number`

### 3.3 P6-4 AchievementDialog 从 @Builder 改为 @Component

**原始问题**：原 @Builder 函数使用 `AppStorage.get<>()` 读取 icon/scale/opacity，但 `AppStorage.get()` 在 @Builder 中不创建响应式订阅，UI 不会随 AppStorage 变化而重渲染。

**修正**：将 AchievementDialog 改为 `@Component` + `@StorageLink`，实现真正的响应式：
- `@StorageLink('achDialogIcon') achIcon: Resource`
- `@StorageLink('achDialogDays') achDays: number`
- `@StorageLink('achDialogScale') achScale: number`
- `@StorageLink('achDialogOpacity') achOpacity: number`

HomeTab 中用 @Builder 方法包装 `AchievementDialog()` 组件传给 `openCustomDialog`：
```typescript
@Builder
achievementDialogBuilder(): void {
  AchievementDialog()
}
```

**动画**：`animateTo({ duration: 300, curve: Curve.EaseOut })` 修改 AppStorage 中的 scale/opacity，@StorageLink 驱动 @Component 重渲染。

**文案**：使用 `$r('app.string.achievement_level', days.toString())` 国际化，zh_CN 显示"连续X天达成"。

### 3.4 P6-5 AchievementPage 文案国际化

原代码硬编码 `info.days.toString() + ' days'`，改为 `$r('app.string.achievement_level', info.days.toString())`，利用已有的 string 资源：
- base/en_US: `"Achieved for %s consecutive day"`
- zh_CN: `"连续%s天达成"`

### 3.5 P6-6 AppStorage 同步 + prefs 持久化

数据流：
1. **解锁写 prefs**：`Repository.checkAchievements()` → `PrefsHelper.setAchievements(unlocked)` 持久化
2. **AppStorage 同步**：`AchievementVM.loadAchievements()` → `AppStorage.setOrCreate(APP_KEY_ACHIEVEMENT_LIST, list)` 供 AchievementPage `@StorageLink` 绑定
3. **弹窗后刷新**：HomeTab `onAchDialogShow` 关闭分支 → `setTimeout(() => achVM.loadAchievements(), 100)` 延迟刷新成就列表

---

## 4. 最终产物结构

```
entry/src/main/ets/
├── view/dialog/AchievementDialog.ets   ← @Component + @StorageLink 响应式弹窗
├── view/home/HomeTab.ets               ← 修复 dialog API + @Builder 包装
├── pages/AchievementPage.ets           ← 文案国际化
├── viewmodel/HomeViewModel.ets         ← 无修改（P3-1 已实现）
└── viewmodel/AchievementViewModel.ets  ← 无修改（P3-3 已实现）

common/src/main/ets/data/repository/TaskRepository.ets  ← 无修改（P2-9 已实现）
```

---

## 5. 构建验证记录

| 次序 | 命令 | 耗时 | 结果 |
|---|---|---|---|
| 1 | `devecocli build`（增量） | — | FAIL（2 ERROR：CustomDialogController 不存在 + openCustomDialog 参数数量） |
| 2 | 修复 dialog API + AchievementDialog @Component | — | — |
| 3 | `devecocli build`（增量） | 4.9s | ✅ BUILD SUCCESSFUL（0 ERROR，70 WARN 均为 deprecated API 非致命） |

---

## 6. 遗留与衔接

- **运行时验证**：成就弹窗动画效果、成就页徽章显示需真机/模拟器验证，留待 Phase 10 集成验证。
- **deprecated WARN**：`openCustomDialog`/`closeCustomDialog`/`animateTo`/`router.back`/`pushUrl`/`replaceUrl` 均为 deprecated 警告，功能正常，不影响构建。后续可迁移到 UIContext 新 API。
- **Phase 7 衔接**：WeekCalendar 日期切换需加载历史 DayProgress，依赖 Repository.getDayProgress（P2-8 已实现）。
