# 健康生活 HealthyLife

## 项目简介

**健康生活（HealthyLife）** 是一款 HarmonyOS 原生应用，帮助用户养成每日健康习惯。用户可创建最多 6 个健康任务（早起、喝水、吃苹果、每日微笑、刷牙、早睡）并设置目标，每日打卡完成，追踪连续天数并解锁成就。应用还提供桌面服务卡片（1x2 任务列表 / 2x2 进度）与早起/早睡通知提醒。

### 主要功能

- **任务管理** — 最多 6 个健康任务，支持定量多次打卡（喝水、吃苹果按目标量多次打卡；其余单次打卡即完成）
- **每日打卡** — 点击任务卡片弹出全屏插画打卡弹窗，一键打卡，实时显示当日完成进度
- **连续天数** — 当天所有任务都打卡完成后，连续打卡天数 +1
- **成就系统** — 连续 3/7/30/50/73/99 天解锁成就，动画弹窗提示，可在成就页查看
- **历史查看** — 周历视图查看往日完成情况
- **服务卡片** — 桌面 1x2 卡片显示已添加任务，2x2 卡片显示任务完成进度
- **通知提醒** — 仅限早起、早睡任务，可设置提醒时间

## 使用说明

### 启动应用

1. 打开应用，显示启动页（Splash），倒计时结束后进入主页面
2. 首次启动会弹出隐私权限说明弹窗，点击"同意"后继续使用

### 添加任务

1. 在主页面点击悬浮的"+"按钮
2. 选择任务类型（早起、喝水、吃苹果、每日微笑、刷牙、早睡）
3. 设置任务目标（喝水/吃苹果可设置目标量；其余任务固定为 1 次）
4. 早起/早睡任务可开启提醒并设置提醒时间
5. 点击"完成"保存任务

### 每日打卡

1. 在首页任务列表中，点击任务项或打卡按钮
2. 弹出打卡弹窗，点击"打卡"按钮完成打卡
3. 多次任务（喝水、吃苹果）需多次打卡达到目标量
4. 当天所有任务都完成后，进度显示 100%，连续天数 +1

### 查看成就

1. 点击底部"成就"Tab 进入成就页
2. 查看已解锁/未解锁的成就徽章
3. 连续打卡达到 3/7/30/50/73/99 天时自动解锁对应成就

### 服务卡片

1. 应用退出到后台，长按应用图标
2. 点击"服务卡片"，选择 1x2 或 2x2 卡片
3. 添加到桌面后，可直接在桌面查看任务列表或完成进度
4. 点击卡片可拉起应用主页面

## 工程目录

```
HealthyLifeDemo/
├── entry/                              # 主入口模块（HAP）
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/           # EntryAbility 应用入口
│       │   ├── entrybackupability/     # EntryBackupAbility 备份能力
│       │   ├── pages/                  # 页面
│       │   │   ├── Index.ets           #   启动页（Splash）
│       │   │   ├── MainTab.ets         #   主 Tab 页（首页/成就/我的）
│       │   │   ├── TaskAddPage.ets     #   添加任务页
│       │   │   ├── TaskEditPage.ets    #   编辑任务页
│       │   │   └── AchievementPage.ets #   成就页
│       │   ├── view/                   # 视图组件
│       │   │   ├── home/               #   首页组件
│       │   │   │   ├── HomeTab.ets         # 首页 Tab
│       │   │   │   ├── WeekCalendar.ets    # 周历组件
│       │   │   │   ├── TaskListItem.ets    # 任务列表项
│       │   │   │   ├── ProgressRing.ets    # 进度环
│       │   │   │   └── ClockInDialog.ets   # 打卡弹窗
│       │   │   ├── mine/               #   我的页
│       │   │   │   └── MineTab.ets
│       │   │   └── dialog/             #   弹窗组件
│       │   │       ├── AchievementDialog.ets    # 成就解锁弹窗
│       │   │       └── TargetPickerDialog.ets   # 目标设置弹窗
│       │   ├── viewmodel/              # ViewModel 层
│       │   │   ├── HomeViewModel.ets       # 首页 ViewModel
│       │   │   ├── TaskViewModel.ets       # 任务 ViewModel
│       │   │   ├── AchievementViewModel.ets # 成就 ViewModel
│       │   │   ├── HistoryViewModel.ets    # 历史 ViewModel
│       │   │   └── MineViewModel.ets       # 我的 ViewModel
│       │   └── card/                   # 服务卡片
│       │       ├── form/
│       │       │   └── FormAbility.ets     # 卡片能力
│       │       └── widget/
│       │           ├── WidgetCard1x2.ets   # 1x2 任务列表卡片
│       │           └── WidgetCard2x2.ets   # 2x2 进度卡片
│       ├── resources/                  # 资源文件
│       └── module.json5                # 模块配置
├── common/                             # 共享 HAR 库
│   └── src/main/
│       ├── ets/
│       │   ├── model/                  # 数据模型
│       │   │   ├── TaskType.ets            # 任务类型枚举
│       │   │   ├── TaskInfo.ets            # 任务信息
│       │   │   ├── TaskRecord.ets          # 打卡记录
│       │   │   ├── TaskConstants.ets       # 任务常量
│       │   │   ├── AchievementInfo.ets     # 成就信息
│       │   │   └── DayProgress.ets         # 每日进度
│       │   ├── data/                   # 数据层
│       │   │   ├── db/
│       │   │   │   ├── RdbHelper.ets       # 数据库帮助类
│       │   │   │   └── RdbTables.ets       # 数据库表定义
│       │   │   ├── prefs/
│       │   │   │   └── PrefsHelper.ets     # 首选项帮助类
│       │   │   └── repository/
│       │   │       └── TaskRepository.ets  # 数据仓库
│       │   └── common/                 # 工具类
│       │       ├── Constants.ets           # 常量定义
│       │       ├── DateUtils.ets           # 日期工具
│       │       └── Logger.ets              # 日志工具
│       └── resources/                  # 共享资源
├── docs/                               # 文档
│   ├── 设计文档.md
│   ├── 任务说明.md
│   ├── 实施计划/
│   └── 实施记录/
└── screenshots/                        # 参考截图
```

## 具体实现

### 技术栈

| 项目 | 说明 |
|------|------|
| 平台 | HarmonyOS 6.1.1 (API 24) |
| 语言 | ArkTS / ArkUI 声明式 UI |
| 架构 | MVVM（Model–View–ViewModel） |
| 存储 | 关系型数据库 (RDB) + 首选项 (Preferences) |
| 状态管理 | AppStorage + @Observed/@ObjectLink + @Provide/@Consume |

### 架构分层

```
┌─────────────────────────────────────────────────────────┐
│  View（视图层）   pages/ + view/                         │
│  纯渲染 + 用户事件回调；通过 @State/@ObjectLink/@Consume │
│  绑定 ViewModel 状态                                     │
├─────────────────────────────────────────────────────────┤
│  ViewModel（视图模型层） viewmodel/                      │
│  页面级状态与业务逻辑；持有 @State 字段并写入 AppStorage │
│  调用 Repository 完成数据读写                            │
├─────────────────────────────────────────────────────────┤
│  Model（模型层） model/ + data/                          │
│  实体类（@Observed）+ 数据访问（RDB/Prefs/Repository）   │
└─────────────────────────────────────────────────────────┘
```

### 数据存储

**关系型数据库（RDB）**

- 数据库名：`HealthyLife.db`
- `task` 表：存储任务定义（最多 6 行），包含任务类型、是否开启、目标量、提醒设置等
- `task_record` 表：存储每日打卡记录，包含日期、任务类型、已完成次数、目标量

**首选项（Preferences）**

- Store 名：`healthy_life_prefs`
- 存储连续打卡天数、上次完成日期、累计全勤天数、历史最高连续天数、已解锁成就、是否首次启动等

### 状态管理

- **AppStorage**：应用级单例中央状态存储，存放 currentDate、streakDays、todayAllDone、taskList、todayRecords 等全局状态
- **@Observed + @ObjectLink**：TaskInfo、TaskRecord 标注 @Observed，子组件通过 @ObjectLink 接收，属性变化自动刷新
- **@Provide + @Consume**：HomeTab 作为数据提供方下发 homeVM 与 todayProgress，子组件通过 @Consume 取用

### 核心业务流程

1. **启动** → Index.ets 倒计时 → 首启隐私弹窗 → router.replaceUrl → MainTab
2. **MainTab** 双 Tab：首页（HomeTab）/ 我的（MineTab）
3. **首页** → 顶部进度环显示当日完成率 → 周历切换日期 → 任务列表打卡 → 全部完成则连续天数 +1 → 触发成就解锁弹窗
4. **添加任务** → 点 + → TaskAddPage → 选择任务类型/设置目标 → 写入 RDB → AppStorage 刷新
5. **打卡** → 点击任务项 → ClockInDialog 弹窗 → 确认 → HomeViewModel.clockIn() → 更新 RDB 记录

## 相关权限

| 权限 | 说明 | 使用场景 |
|------|------|----------|
| `ohos.permission.PUBLISH_AGENT_REMINDER` | 后台代理提醒权限 | 早起/早睡任务的定时提醒功能 |
| `ohos.permission.READ_CALENDAR` | 读取日历权限 | 日历相关功能（如需要） |
| `ohos.permission.WRITE_CALENDAR` | 写入日历权限 | 日历相关功能（如需要） |

权限配置位于 `entry/src/main/module.json5` 的 `requestPermissions` 字段。

## 约束与限制

### 功能约束

- **任务数量**：最多支持 6 个健康任务（早起、喝水、吃苹果、每日微笑、刷牙、早睡）
- **打卡规则**：
  - 早起、每日微笑、刷牙、早睡：单次打卡即完成
  - 喝水、吃苹果：按目标量多次打卡完成
- **成就阈值**：连续 3/7/30/50/73/99 天解锁成就
- **提醒支持**：仅早起、早睡任务支持提醒功能

### 技术约束

- **ArkTS strict 模式**：禁止使用 `any`、`as`、对象字面量类型、动态属性访问；全字段显式类型
- **卡片上下文隔离**：服务卡片运行于独立上下文，不能直接访问主页 AppStorage，需通过 TaskRepository 直读数据
- **RDB 异步操作**：数据库操作一律使用 async/await，禁止同步阻塞
- **@Observed 数组刷新**：新增/删除需整体替换数组引用；元素属性变更经 @ObjectLink 触发

### 平台限制

- **最低系统版本**：HarmonyOS 6.1.1 (API 24)
- **设备类型**：仅支持 phone（手机）
- **卡片更新**：卡片定时更新由系统调度，更新间隔受系统限制

### 已知限制

- 服务卡片 1x2 仅显示任务列表，不显示进度
- 服务卡片 2x2 仅显示进度，不显示任务详情
- 历史查看仅支持本周 7 天，不支持更早历史
- 成就解锁后不可重置

## 构建与运行

使用 DevEco Studio 打开项目，连接 HarmonyOS 设备或模拟器后运行 `entry` 模块即可。

## 更新日志

- **2026-07-10** 打卡弹窗 UI 升级：任务插画铺满整个弹窗卡片，移除取消按钮，打卡按钮改为半透明胶囊样式
