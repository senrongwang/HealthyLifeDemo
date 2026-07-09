# 健康生活 HealthyLife

一款帮助用户养成每日健康习惯的 HarmonyOS 应用。创建健康任务、每日打卡、追踪连续天数并解锁成就。

## 功能

- **任务管理** — 最多 6 个健康任务（早起、喝水、吃苹果、每日微笑、刷牙、早睡），支持定量多次打卡
- **每日打卡** — 主页一键打卡，实时显示当日完成进度
- **连续天数** — 全部打卡完成后连续天数 +1
- **成就系统** — 连续 3/7/30/50/73/99 天解锁成就，动画弹窗提示
- **历史查看** — 周历视图查看往日完成情况

## 技术栈

| 项目 | 说明 |
|------|------|
| 平台 | HarmonyOS 6.1.1 (API 24) |
| 语言 | ArkTS / ArkUI 声明式 UI |
| 架构 | MVVM（Model–View–ViewModel） |
| 存储 | 关系型数据库 (RDB) + 首选项 (Preferences) |
| 状态管理 | AppStorage + @Observed/@ObjectLink + @Provide/@Consume |

## 工程结构

```
HealthyLifeDemo/
├── entry/                    # 主入口模块
│   └── src/main/ets/
│       ├── pages/            # 页面（Index 启动页、MainTab、TaskAddPage、TaskEditPage、AchievementPage）
│       ├── view/             # 视图组件（HomeTab、WeekCalendar、TaskListItem、ProgressRing 等）
│       └── viewmodel/        # ViewModel 层（HomeViewModel、TaskViewModel 等）
├── common/                   # 共享 HAR 库
│   └── src/main/ets/
│       ├── model/            # 数据模型（TaskInfo、TaskRecord、AchievementInfo 等）
│       ├── data/             # 数据层（RdbHelper 数据库、TaskRepository 仓库、PrefsHelper 首选项）
│       └── common/           # 工具类（Constants、DateUtils、Logger）
├── docs/                     # 设计文档与实施记录
└── screenshots/              # 参考截图
```

## 构建

使用 DevEco Studio 打开项目，连接 HarmonyOS 设备或模拟器后运行 `entry` 模块即可。
