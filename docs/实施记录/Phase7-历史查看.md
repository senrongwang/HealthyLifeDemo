# Phase 7 — 历史查看（F5）

> 日期：2026-07-09
> 目标：首页 WeekCalendar 日期切换时加载对应日期/周的完成情况（历史查看）。

---

## 阶段目标

首页周历集成历史查看功能：左右箭头切换周 → 加载对应周 7 天的 DayProgress → 按完成状态渲染徽章（全勤金色/未完灰色）。无独立 HistoryPage，历史查看集成在首页周历的日期切换中。

---

## 任务执行清单

| 编号 | 任务 | 产出文件 | 结果 |
|---|---|---|---|
| P7-1 | WeekCalendar 日期切换接线：左右箭头切换日期 → 加载对应 DayProgress | `view/home/WeekCalendar.ets`（新建） | 完成 |
| P7-2 | HistoryViewModel.loadWeekProgress 接线：供周历按周加载 7 天进度 | 更新 `HistoryViewModel.ets` + `DateUtils.ets` | 完成 |
| P7-3 | 周历徽章按 DayProgress 渲染：全勤金色 / 部分灰色 | 更新 WeekCalendar | 完成 |

---

## 关键技术决策与修正

### 1. WeekCalendar 组件结构设计

- **决策**：WeekCalendar 作为独立 @Component，通过 @Link 双向绑定 selectedDate 与父组件 HomeTab 通信。
- **理由**：组件自包含周偏移和进度数据管理（@State weekOffset / weekProgress），仅选中日期需与父组件同步。
- **替代方案**：通过 @Consume 取 HomeVM → 增加耦合，不采用。

### 2. 避免 ArkTS strict 的 `as` 类型断言

- **问题**：初始实现中 `findProgress(date)` 返回 `DayProgress | null`，在 @Builder 内用 `(result as DayProgress).isAllDone` 访问属性。
- **修正**：抽取 `isAllDone(date: string): boolean` 辅助方法，内部用 `=== null` 守卫后直接访问属性，完全避免 `as`。

### 3. 徽章视觉方案

- **全勤**：`ic_home_all_done`（金色）
- **未完**：`ic_home_undone`（灰色）
- **无数据（未来日期）**：灰色圆形背景 `#F0F0F0` + 0.4 透明度
- **选中日期**：橙色边框（`#FF6B00`, 2vp）+ 加粗日期文字

### 4. DateUtils 扩展

- `getWeekDatesByOffset(weekOffset)`：基于当前周偏移计算 7 天日期数组。`getWeekDates()` 重构为 `getWeekDatesByOffset(0)` 调用，保持向后兼容。
- `getWeekDayLabel(dateStr)`：从日期字符串提取日号（"dd"）。
- `getWeekRangeString(dates)`：生成 "MM/dd - MM/dd" 周范围显示文本。

### 5. 右箭头导航限制

- 当 `weekOffset >= 0`（当前周或未来周）时，右箭头禁用（opacity 0.3 + 点击不生效），防止查看未来无数据周。

---

## 最终产物结构

```
新增：
  entry/src/main/ets/view/home/WeekCalendar.ets   # 周历组件（徽章式）

修改：
  common/src/main/ets/common/DateUtils.ets          # +getWeekDatesByOffset/getWeekDayLabel/getWeekRangeString
  entry/src/main/ets/viewmodel/HistoryViewModel.ets  # +loadWeekProgressByOffset
  entry/src/main/ets/view/home/HomeTab.ets           # +WeekCalendar 集成 + @State calSelectedDate
```

---

## 构建验证记录

| 步骤 | 命令 | 结果 |
|---|---|---|
| arkts_check | 4 文件 | 0 ERROR，1 Warning（unused `idx` in ForEach key gen） |
| devecocli build | 增量构建 | BUILD SUCCESSFUL in 17s 467ms，CompileArkTS 11s，仅 async throw + deprecated WARN |

---

## 遗留与衔接

- **WeekCalendar 选中日期联动**：当前 selectedDate 变化仅更新 UI 高亮，未联动 HomeTab 任务列表过滤（可作为后续增强）。
- **Phase 5 依赖**：WeekCalendar 组件在 Phase 7 中创建（含完整数据联动），Phase 5 P5-9 的静态骨架版本已被本实现覆盖。
- **下一阶段**：Phase 8 服务卡片（FormAbility + WidgetCard）。
