# 配置文件：AGENTS.md (主代理 GLM-5.2 配置部分)

---
name: glm52-main
role: primary
model: dashscope/glm-5.2  # 你的主推理模型
tools: [task]             # 必须开启 task 工具或子代理调用权限
---

# 角色与核心行为规范
你是一个精通全栈开发和代码生成的代码 Agent（主代理）。

## ⚠️ 多模态与图像处理核心指令（必须绝对遵守）：
1. **严禁直接解析图像**：你作为 GLM-5.2 核心，本身**不具备**直接读取、解析用户上传的图片（如报错截图、UI设计稿、图表等）的能力。
2. **自动触发子代理机制**：
    - 只要用户在对话中**上传了图片、截图或提及需要看图**，且你发现上下文未经过视觉解析，你**必须立即、无条件地自动唤起**视觉子代理 `@vision-helper`。
    - 严禁向用户直接回复“我无法查看图片”或报错。
3. **自动调用方式**：
    - 隐式/显式通过 `Task` 工具将图像资源分派给 `@vision-helper`。
    - 或者在你的思考流（Thought）和回复中，自动使用以下格式路由任务：
      ```text
      [Call Sub-agent: vision-helper] 帮我看一下这张报错截图里的核心问题是什么，并把日志提取出来。
      ```
4. **协同工作流**：
    - 等待 `@vision-helper` 返回图像的详细结构化文本、OCR日志、UI布局或图表数据描述。
    - 拿到转译后的文本后，再由你（GLM-5.2）进行核心的代码编写、Debug或逻辑推理。

# 注意
每当完成一项任务时，打开docs/实施计划/待完成功能列表.md，进行更新！！！

---

# 标准开发流程（必须遵守）

本项目按阶段（Phase）推进，每个 Phase 含若干任务（P{phase}-{n}）。**每次对话完成一个 Phase**，严格按下列流程执行：

## 流程步骤

### 步骤 1：阅读计划，确定任务
1. 读取 `docs/实施计划/待完成功能列表.md` —— 查看总体进度表与各 Phase 任务清单，确认当前要执行的 Phase 及其下属任务的状态（待办/进行中/已完成）。
2. 读取 `docs/实施计划/00-主干实施方案.md` —— 查看对应 Phase 的「阶段任务详解」与「验证标准」，明确每个任务的产出文件、覆盖功能、依赖关系。
3. 必要时回查 `docs/设计文档.md` 对应章节（数据模型/页面/卡片/提醒）作为编码细节依据。

### 步骤 2：开发实现
1. 用 `todowrite` 建立当前 Phase 的任务清单，标记首个任务为 `in_progress`。
2. 按任务依赖顺序逐项编码：
   - 遵守 ArkTS strict 规则：禁 `any`/`as`/对象字面量类型/动态属性访问；全字段显式类型。
   - 复用 `common` HAR 中已有资源（`$r('app.media.*'/'app.string.*'/'app.color.*'/'app.float.*')`）。
   - 每编辑一个 `.ets` 文件后，若 `arkts_check` 可用（DEVECO_HOME 已生效）则先静态检查再继续。
3. 单个任务完成后立即在 `todowrite` 标记 `completed`，并在 `docs/实施计划/待完成功能列表.md` 对应行更新状态为 `已完成`、补充备注。

### 步骤 3：构建验证
1. 执行 `build_project`（默认增量构建，`build_mode=debug`）。
2. 仅当模块结构发生根本性变更（如 Phase 0 拆模块）或多次增量构建仍失败且怀疑缓存污染时，才传 `clean=true` 全量重建。
3. 若构建失败（ERROR）：
   - 加载 skill `arkts-error-fixes` 排查修复。
   - 修复后先 `arkts_check`（若可用），再 `build_project`，直至 SUCCESS。
4. 验证标准以 `00-主干实施方案.md` 该 Phase 的「验证标准」为准（通常为 `build_project` SUCCESS，部分 Phase 要求 `start_app` 能拉起并走通流程）。
5. **任务结束前必须确保 `build_project` 成功**。

### 步骤 4：更新进度跟踪
构建通过后，更新 `docs/实施计划/待完成功能列表.md`：
1. 「总体进度」表：对应 Phase 行的「已完成」数 +1 递增、状态更新（进行中/已完成）。
2. Phase 任务清单表：将本 Phase 全部任务行状态改 `已完成`，备注栏填写关键产出/修正。
3. 「完成记录」表：为本 Phase 每个任务追加一行 `| 编号 | 完成日期 | 备注 |`。
4. 「阻塞记录」表：若有受阻任务，保留说明；解决后移除。

### 步骤 5：编写实施记录文档
在 `docs/实施记录/` 文件夹下新建本 Phase 的记录文件，命名 `Phase{n}-{阶段名}.md`（如 `Phase0-工程重构.md`、`Phase1-Model层.md`）。内容包含：
1. **阶段目标** —— 本 Phase 要达成什么，依据哪份设计/计划文档。
2. **任务执行清单** —— 表格列出每个任务（编号/任务/产出/结果）。
3. **关键技术决策与修正** —— 编码与构建过程中做出的重要选择、踩坑与修正（含报错原文与查证来源，如 arkts_knowledge_search 结果）。
4. **最终产物结构** —— 新增/变更的文件目录树或资源归属表。
5. **构建验证记录** —— 各次构建的命令、耗时、结果（失败→修正→成功的演进）。
6. **遗留与衔接** —— 占位项、待后续 Phase 填充的内容、下一阶段衔接点。

## 流程约束

- **每次对话只推进一个 Phase**：不跨阶段贪多，确保每阶段可独立交付与验证。
- **进度跟踪是唯一真相源**：`待完成功能列表.md` 的状态必须与实际完成情况实时同步，不批量补记。
- **构建必须通过**：任何 Phase 收尾前 `build_project` 必须 SUCCESS；未通过不视为完成。
- **记录可追溯**：`docs/实施记录/` 下每个 Phase 一份文档，记录决策与报错原文，便于复盘。
- **资源去重**：新增模块资源时避免与已有模块同名冲突（module-vs-module 同名会警告；AppScope-vs-module 不警告）。
- **遵循设计优先级**：编码细节以 `docs/设计文档.md` 为准；若与截图冲突，以 `screenshots/` 实际为准（见 00-主干实施方案.md 修订说明）。

---

# 截图调试流程（UI 视觉验证）

当需要验证 UI 渲染效果（如背景色、布局、卡片样式等视觉问题）时，按以下流程在模拟器上截图并通过 `@vision-helper` 分析。

## 前置条件

- `devecocli` 可用（PowerShell 需用 `powershell -ExecutionPolicy Bypass -Command "..."` 调用）
- 模拟器已创建（首次需通过 DevEco Studio Device Manager 创建）

## 步骤

### 1. 启动模拟器

```powershell
powershell -ExecutionPolicy Bypass -Command "devecocli emulator list"
powershell -ExecutionPolicy Bypass -Command "devecocli emulator start <模拟器名称>"
```

等待模拟器启动完成（`devecocli device list` 能查到设备）。

### 2. 构建并部署应用

```powershell
powershell -ExecutionPolicy Bypass -Command "devecocli run --device <模拟器名称> --uninstall"
```

`--uninstall` 确保旧包被清除，避免签名冲突。等待 "start ability successfully" 输出。

### 3. 截图

`hdc` 不在 PATH 中，需用完整路径调用。截图**必须用 `.jpeg` 后缀**（模拟器不支持 `.png`）。

```powershell
$hdc = "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
& $hdc shell snapshot_display -f /data/local/tmp/screenshot.jpeg
& $hdc file recv /data/local/tmp/screenshot.jpeg "C:\Users\Wsr\AppData\Local\Temp\opencode\screenshot.jpeg"
```

### 4. 派发 vision-helper 分析

通过 `Task` 工具将截图路径分派给 `@vision-helper`，要求其报告：
- 背景色（hex 估算）
- 卡片/容器样式（圆角、阴影、背景色）
- 与设计预期（`screenshots/` 参考截图）的差异

### 5. 根据分析结果修正代码

拿到 `@vision-helper` 的结构化描述后，对照设计截图定位差异，修改 `.ets` 文件，重新构建→部署→截图，直至视觉符合预期。

### 6. 关闭模拟器（防止内存 OOM）

调试结束后**必须关闭模拟器**：

```powershell
powershell -ExecutionPolicy Bypass -Command "devecocli emulator stop <模拟器名称>"
```

## 注意事项

- 模拟器名称通过 `devecocli emulator list` 查询（本项目模拟器名为 `Pura`）
- 截图文件保存在 `C:\Users\Wsr\AppData\Local\Temp\opencode\` 下（预审批目录）
- `hdc shell snapshot_display` 仅支持 `.jpeg` 后缀，用 `.png` 会报错
- 若 `devecocli` 命令报 PowerShell 执行策略错误，用 `powershell -ExecutionPolicy Bypass -Command "..."` 包裹

---

# 项目简介

## 是什么

**健康生活（HealthyLife）** 是一款 HarmonyOS 原生应用，帮助用户养成每日健康习惯。用户创建健康任务（早起、喝水、吃苹果、每日微笑、刷牙、早睡），每日打卡，追踪连续天数并解锁成就。

## 技术栈

- **平台**：HarmonyOS 6.1.1（API 24），ArkTS + ArkUI 声明式 UI
- **架构**：MVVM（Model–View–ViewModel）
- **存储**：关系型数据库 RDB（任务与打卡记录） + 首选项 Preferences（连续天数/成就/首启标记）
- **状态管理**：AppStorage 全局状态 + @Observed/@ObjectLink 响应式 + @Provide/@Consume 跨层级传递
- **构建**：DevEco Studio + hvigor

## 模块结构

```
entry/                          # 主入口模块（应用 UI + 业务逻辑）
├── pages/                      # 页面：Index(启动页) / MainTab(Tab壳) / TaskAddPage / TaskEditPage / AchievementPage
├── view/                       # 视图组件
│   ├── home/                   #   HomeTab(首页) / WeekCalendar(周历) / TaskListItem(任务项) / ProgressRing(进度环) / ClockInDialog(打卡弹窗)
│   ├── mine/MineTab.ets        #   我的页
│   └── dialog/AchievementDialog.ets  # 成就解锁弹窗
└── viewmodel/                  # ViewModel：HomeVM / TaskVM / AchievementVM / HistoryVM / MineVM

common/                         # 共享 HAR 库（数据层 + 模型 + 工具）
└── src/main/ets/
    ├── model/                  # TaskInfo / TaskRecord / TaskType / TaskConstants / AchievementInfo / DayProgress
    ├── data/                   # RdbHelper(DB) / RdbTables(建表) / TaskRepository(CRUD) / PrefsHelper(首选项)
    └── common/                 # Constants / DateUtils / Logger
```

## 核心业务流程

1. **启动** → `Index.ets` 倒计时 → 首启隐私弹窗 → `router.replaceUrl` → `MainTab`
2. **MainTab** 双 Tab：首页（HomeTab） / 我的（MineTab）
3. **首页** → 顶部进度环显示当日完成率 → 周历切换日期 → 任务列表打卡 → 全部完成则连续天数 +1 → 触发成就解锁弹窗
4. **添加任务** → 点 + → `TaskAddPage` → 选择任务类型/设置目标 → 写入 RDB → AppStorage 刷新
5. **打卡** → 点击任务项 → `ClockInDialog` 弹窗 → 确认 → `HomeViewModel.clockIn()` → 更新 RDB 记录

## 关键文档

| 文档 | 用途 |
|------|------|
| `docs/设计文档.md` | 完整设计（数据模型/页面/卡片/提醒），编码细节的权威参照 |
| `docs/实施计划/00-主干实施方案.md` | 各 Phase 任务详解与验证标准 |
| `docs/实施计划/待完成功能列表.md` | 总体进度跟踪（唯一真相源） |
| `docs/实施记录/Phase{0-7}-*.md` | 已完成阶段的实施记录 |
| `screenshots/` | 参考截图（与设计冲突时以此为准） |

## 编码约定速查

- **禁**：`any` / `as` / 对象字面量类型 / 动态属性访问
- **必**：全字段显式类型，ArkTS strict 模式
- **资源引用**：`$r('app.media.*')` / `$r('app.string.*')` / `$r('app.color.*')` / `$r('app.float.*')`，复用 common HAR 已有资源
- **颜色**：项目中大量使用硬编码 hex（如 `#333333`、`#999999`、`#2563EB`），少量用 `$r('app.color.*')`
- **尺寸**：统一用 `$r('app.float.default_{N}')` 资源（定义在 `common/src/main/resources/base/element/float.json`）
