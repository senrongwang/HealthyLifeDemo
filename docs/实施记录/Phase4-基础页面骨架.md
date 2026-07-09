# Phase 4：基础页面骨架 实施记录

> 阶段：Phase 4 基础页面骨架
> 执行日期：2026-07-09
> 状态：✅ 已完成（7/7 任务，build SUCCESS）
> 构建结果：BUILD SUCCESSFUL（CompileArkTS 8.2s，0 ERROR；首次构建失败 7 ERROR 修复后通过）

---

## 1. 阶段目标

搭建应用导航骨架：SplashPage 启动页 + MainTab（2 Tab：首页/我的）容器 + HomeTab/MineTab 占位 + AchievementPage 独立页占位 + 路由注册 + EntryAbility 注入 AppStorage 并初始化数据层。

依据：
- `docs/设计文档.md` §6 状态管理、§7 页面 View 设计（7.1~7.4/7.6/7.8）、§9 骨架
- `docs/实施计划/00-主干实施方案.md` Phase 4
- `docs/实施计划/待完成功能列表.md` P4-1 ~ P4-7

**验证标准**（实施方案）：`build_project` 成功；`start_app` 能从 Splash 跳到 MainTab 并切换两 Tab；"我的"菜单"成就"可跳转 AchievementPage。

---

## 2. 任务执行清单

| 编号 | 任务 | 产出文件 | 结果 |
|---|---|---|---|
| P4-1 | SplashPage | `entry/.../pages/Index.ets` | ✅ |
| P4-2 | MainTab | `entry/.../pages/MainTab.ets` | ✅ |
| P4-3 | HomeTab 骨架 | `entry/.../view/home/HomeTab.ets` | ✅ |
| P4-4 | AchievementPage 骨架 | `entry/.../pages/AchievementPage.ets` | ✅ |
| P4-5 | MineTab 骨架 | `entry/.../view/mine/MineTab.ets` | ✅ |
| P4-6 | main_pages.json | `entry/.../profile/main_pages.json` | ✅ |
| P4-7 | EntryAbility | `entry/.../entryability/EntryAbility.ets` | ✅ |

---

## 3. 关键技术决策与修正

### 3.1 ViewModel 在 entry 模块，跨文件用相对路径导入（非 common）

**报错**：`Module "common" has no exported member 'HomeViewModel'` / `'AchievementViewModel'`，以及 `Cannot find module '../viewmodel/MineViewModel'`。

**根因**：Phase 3 的 5 个 ViewModel 位于 `entry/src/main/ets/viewmodel/`（entry 模块），**不在 common(HAR)**。误用 `from 'common'` 导入，且 MineTab 的相对路径层级算错（`../viewmodel` 少一层）。

**修正**：
- HomeTab（`view/home/`）→ `import { HomeViewModel } from '../../viewmodel/HomeViewModel'`
- MineTab（`view/mine/`）→ `import { MineViewModel } from '../../viewmodel/MineViewModel'`
- AchievementPage（`pages/`）→ `import { AchievementViewModel } from '../viewmodel/AchievementViewModel'`

仅 Model/工具类（TaskInfo/TaskRecord/AchievementInfo/Logger 等）从 'common' 导入。ViewModel 是 entry 专属（可引用 router/AppStorage 等 app 能力），不可下沉 common。

### 3.2 Row.alignItems 取 VerticalAlign，非 FlexAlign（ArkUI 类型严格）

**报错**：`Argument of type 'FlexAlign' is not assignable to parameter of type 'VerticalAlign'`（MineTab:46/62、AchievementPage:44）。

**根因**：ArkUI 中 `.alignItems()` 参数类型随容器而异：
- **Column**.alignItems(value: **HorizontalAlign**)
- **Row**.alignItems(value: **VerticalAlign**)
- **Flex**.alignItems(value: **FlexAlign**)

误在 Row 上传 `FlexAlign.Center`。`.justifyContent()` 则三者均取 FlexAlign（SpaceBetween/Center 等不变）。

**修正**：3 处 Row 的 `.alignItems(FlexAlign.Center)` → `.alignItems(VerticalAlign.Center)`。Column 上的 `.alignItems(HorizontalAlign.Center/Start)` 不受影响。

### 3.3 自定义组件跨文件需 `@Component export struct`

知识库查证：跨 .ets 文件引用自定义组件，被引用方须 `@Component export struct Foo {}`（export 在 @Component 之后、struct 之前）。故 HomeTab/MineTab 声明为 `@Component export struct`，由 MainTab `import { HomeTab } from '../view/home/HomeTab'` 引入。@Entry 页面（Index/MainTab/AchievementPage）作为 router 目标由框架按 main_pages.json 路径加载，无需 export。

### 3.4 @StorageLink key 用字符串字面量（规避常量键风险）

ArkUI 状态装饰器 `@StorageLink(key)` 的 key 参数对非常量引用的支持不确定，为保编译稳妥统一用**字符串字面量**（`'taskList'`/`'streakDays'` 等，值与 `Constants.APP_KEY_*` 一致）；ViewModel/EntryAbility 内 `AppStorage.setOrCreate` 是普通函数调用，继续用 `Constants.APP_KEY_*` 常量。两侧字符串值一致即同步。

### 3.5 Splash 倒计时 + 首启权限弹窗

- `setInterval` 全局可用（返回 number），倒计时 3s；到点 `router.replaceUrl({ url: 'pages/MainTab' })`，`navigated` 标志防重入，`aboutToDisappear` 清 timer。
- 首启：`aboutToAppear` 异步读 `PrefsHelper.getFirstLaunch()`（init 已在 EntryAbility.initAndLoad 内 await 完成，pref 就绪）；为 true 则 `@State showPrivacy=true` 渲染 `@Builder PrivacyDialog`（半透明遮罩 #80000000 + 白卡）。
- confirm → `setFirstLaunch(false)` + 关闭；cancel → 仅关闭（首启标志未置 false，下次仍弹）。cancel 的"退出应用"语义留待 Phase 10（需 UIAbilityContext.terminateSelf，骨架阶段从简）。

### 3.6 HomeTab 进度/空态用 getter 从 @StorageLink 实时算（非 VM 字段）

DayProgress 非 @Observed，VM 的 todayProgress 字段变化不触发 UI。改在 HomeTab 用 `getOpenTaskCount()`/`getProgress()` getter 直接遍历 `@StorageLink` 的 taskList/todayRecords（TaskInfo/TaskRecord 均 @Observed，数组整体替换时 @StorageLink 同步→build 重算）。种子任务 isOpen 全为 0 → 空态 `ic_no_data`+`no_task` 正常显示，符合"未添加任务"语义。

### 3.7 EntryAbility 先 init 后 loadContent

`onWindowStageCreate` 调 `initAndLoad`（async）：先 `await TaskRepository.getInstance().init(this.context)`（建库+Prefs 就绪），再 `windowStage.loadContent('pages/Index')`。确保 Splash 的首启检查读到真实 prefs，而非默认值。AppStorage 仅注入 4 个标量键（数组键由 ViewModel load 后写入，@StorageLink 本地默认 [] 兜底）。

### 3.8 router API deprecated（非致命）

`router.replaceUrl`/`router.pushUrl`/`router.back` 在当前 SDK 标记 deprecated（推荐 Navigation 组件），但仅 WARN 不阻断构建。设计 §7 采用 router 导航模型，Phase 4 沿用；如后续迁移 Navigation，统一在 Phase 10 评估。

---

## 4. 最终产物结构

```
entry/src/main/ets/
├── pages/
│   ├── Index.ets            # @Entry Splash：ic_splash_bg + 倒计时 + 首启隐私弹窗 + replaceUrl MainTab
│   ├── MainTab.ets          # @Entry Tabs(End) + 2 TabContent + @Builder tabBar
│   └── AchievementPage.ets  # @Entry 黑底 + 装饰 + Grid 2列6徽章 + 返回箭头
├── view/
│   ├── home/HomeTab.ets     # @Component export：@Provide homeVM + @StorageLink + Progress Ring 占位 + 空态
│   └── mine/MineTab.ets     # @Component export：头像+用户信息+List 3 菜单
├── viewmodel/               # (Phase 3 产物，本阶段被页面引用)
└── entryability/EntryAbility.ets  # 注入 AppStorage + init DB + loadContent Index
entry/.../profile/main_pages.json  # src: Index, MainTab, AchievementPage
```

### AppStorage 同步点（EntryAbility 注入 + 页面绑定）

| 键 | 注入方 | 绑定组件 |
|---|---|---|
| currentDate / streakDays / todayAllDone / splashDone | EntryAbility.initializeAppStorage | HomeTab(@StorageLink streakDays/todayAllDone)；Index(splashDone) |
| taskList / todayRecords | HomeViewModel.loadTodayTasks | HomeTab(@StorageLink) |
| achievementList | AchievementViewModel.loadAchievements | AchievementPage(@StorageLink) |

---

## 5. 构建验证记录

### 5.1 首次 build_project（增量，entry@default，debug）—— FAIL
```
7 ERROR：
  HomeTab: Module 'common' has no exported member 'HomeViewModel'
  MineTab: Cannot find module '../viewmodel/MineViewModel'
  MineTab:46/62 FlexAlign 不可赋给 VerticalAlign
  AchievementPage: Module 'common' has no exported member 'AchievementViewModel'
  AchievementPage:44 FlexAlign 不可赋给 VerticalAlign
  Rollup: Could not resolve '../viewmodel/MineViewModel'
```

### 5.2 修复后 build_project（增量）—— SUCCESS
```
> hvigor Finished :entry:default@CompileArkTS... after 8 s 192 ms
> hvigor BUILD SUCCESSFUL in 17 s 963 ms
```
- 0 ERROR（grep `ERROR:|Error Message` 命中 0）。
- 剩余 WARN：router API deprecated（replaceUrl/pushUrl/back）+ 异步调用 throw 提示（Index:54、MineViewModel:41）+ Phase 2 遗留 Repository 异步 WARN，均非致命。
- grep `alignItems\(FlexAlign` 全 entry 范围命中 0，确认无遗漏。

### 5.3 验证标准核对
- ✅ build_project 成功
- ⚠️ start_app 运行时验证（Splash→MainTab→Tab 切换→成就页跳转）**未执行**：当前无连接设备，且 HAP 未签名（build-profile 无 signingConfigs，构建提示 skip sign）。记入阻塞表，留待 Phase 10 配置签名 + 真机后补做。

---

## 6. 遗留与衔接

| 项 | 说明 | 衔接阶段 |
|---|---|---|
| start_app 运行时验证 | 无设备+未签名，Splash→MainTab 流程未实跑 | Phase 10（配置 signingConfigs + 真机） |
| Splash cancel 退出语义 | 当前仅关闭弹窗，未 terminateSelf | Phase 10 |
| HomeTab ProgressRing | 用内置 Progress(Ring) 占位 | Phase 5 P5-8 自定义 ProgressRing 组件替换 |
| HomeTab 任务列表 | 仅空态占位（openCount=0） | Phase 5 P5-1 TaskListItem + P5-5 悬浮加号路由 |
| HomeTab 周历 | 未实现 | Phase 5 P5-9 WeekCalendar |
| AchievementPage 徽章文案 | 占位 `Nd days` 纯文本 | Phase 6 P6-5 用 achievement_level 资源串+%s 格式化 |
| AchievementPage 网格 | 2 列 6 徽章已布 | Phase 6 P6-5 接 unlocked 状态 + 文案 |
| router API deprecated | replaceUrl/pushUrl/back 仅 WARN | Phase 10 评估是否迁 Navigation |

**下一阶段**：Phase 5 任务管理与打卡（P5-1 ~ P5-11）—— TaskListItem / TaskAddPage / TaskEditPage / ClockInDialog / ProgressRing / WeekCalendar + HomeViewModel.clockIn 接线 + 全部完成态。

🔔 **界面提醒**：Phase 4 页面骨架已就位且 build 通过，但因无设备+未签名**尚未实机查看**。Phase 5 完成打卡主流程后，建议配置签名在真机/模拟器上首次查看 Splash→MainTab→打卡 全流程。
