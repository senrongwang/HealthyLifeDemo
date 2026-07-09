# Phase 0：工程重构 实施记录

> 阶段：Phase 0 工程重构
> 执行日期：2026-07-09
> 状态：✅ 已完成（10/10 任务）
> 构建结果：BUILD SUCCESSFUL（clean 全量 + 增量均通过，无资源冲突警告）

---

## 1. 阶段目标

将原单一 `common`（type=entry）模块拆分为 **`common`（HAR 静态共享库）+ `entry`（HAP 入口模块）** 双模块结构，打通依赖链与构建配置，为后续 Phase 1~10 业务实现奠定工程骨架。

依据：
- `docs/设计文档.md` §3 目录结构、§14 权限与配置改动
- `docs/实施计划/00-主干实施方案.md` Phase 0
- `docs/实施计划/待完成功能列表.md` P0-1 ~ P0-10

---

## 2. 任务执行清单

| 编号 | 任务 | 产出 | 结果 |
|---|---|---|---|
| P0-1 | 新建 entry 模块目录骨架 | 16 目录：ets/{entryability,entrybackupability,pages,view,viewmodel,card/form,card/widget,service} + resources/base/{element,profile,media} | ✅ |
| P0-2 | common 转为 HAR | hvigorfile.ts hapTasks→harTasks；oh-package.json5 main→Index.ets；build-profile.json5 移除 ohosTest target；module.json5 改 type=har 最小化 | ✅ |
| P0-3 | 新建 common/Index.ets 统一导出接口 | 占位导出 COMMON_LIB_NAME（后续 P1-7/P2-10 扩充） | ✅ |
| P0-4 | entry/oh-package.json5 声明依赖 common | dependencies: { "common": "file:../common" } | ✅ |
| P0-5 | 根 build-profile.json5 modules 增加 entry | modules 新增 entry@default | ✅ |
| P0-6 | 迁移 Ability 到 entry | EntryAbility/EntryBackupAbility 迁入 entry/src/main/ets/{entryability,entrybackupability}，从 common 删除 | ✅ |
| P0-7 | entry/module.json5 配置 | EntryAbility(home skills) + EntryBackupAbility(backup) + requestPermissions:[] | ✅ |
| P0-8 | entry 资源迁移与 profile 创建 | string(base+zh_CN)/color(base+dark)/main_pages/form_config(空)/backup_config + startIcon；common 去重 | ✅ |
| P0-9 | entry/pages/Index.ets 占位 | 占位页 import {COMMON_LIB_NAME} from 'common' 验证依赖链 | ✅ |
| P0-10 | 全量构建验证 | clean 全量 + 增量构建均 BUILD SUCCESSFUL | ✅ |

---

## 3. 关键技术决策与修正

### 3.1 HAR 模块必须保留 module.json5（重要修正）

**初始误判**：以为 HAR 模块不需要 module.json5，将 common/src/main/module.json5 删除。

**构建报错**：
```
hvigor ERROR: 00304064 Not Found
Error Message: module.json5 file not found.
At file: common\src\main\module.json5
```
且 `clean` 命令同样失败，排除缓存问题。

**知识库查证**（arkts_knowledge_search）：
> "每个模块下必须包括一个 module.json5 配置文件"
> type 字段支持：entry / feature / **har** / shared / skill

**修正**：为 common 重建 HAR 专属 module.json5，`type:"har"`，仅保留必填字段（name/type/deviceTypes），无 abilities/extensionAbilities/pages。与设计文档 §14.1 "common 转为 HAR 后不再保留 module.json5 的 abilities/extensionAbilities" 一致（保留文件，仅移除 abilities）。

```json5
{
  "module": {
    "name": "common",
    "type": "har",
    "deviceTypes": ["phone"]
  }
}
```

### 3.2 模块间资源重复触发冲突警告

**现象**：构建 SUCCESS 但出现 Warning：
```
Warning: 'module_desc' conflict, first declared.
  at entry\src\main\resources\base\element\string.json
  but declared again.
  at common\src\main\resources\base\element\string.json
```
涉及 module_desc / EntryAbility_desc / EntryAbility_label / start_window_background。

**分析**：
- AppScope-vs-module 资源同名**不警告**（模块覆盖 AppScope，原工程即如此）
- **module-vs-module（entry-HAP vs common-HAR）同名会警告**（HAP 优先，HAR 被遮蔽）

**修正**：按设计 §3 资源策略（"entry 自身仅保留 module.json5 配置引用所需的少量资源"），从 common 移除 entry 已持有的重复资源：
- string.json（base/zh_CN/en_US）删除 module_desc、EntryAbility_desc、EntryAbility_label
- color.json（base）删除 start_window_background
- 删除 common/dark/element/color.json（删后空数组非法：`The array or object node 'color' cannot be empty`，改为直接删文件）
- 删除 common/media/startIcon.png

### 3.3 form_config.json 暂置空

P0-8 要求新建 form_config.json，但 FormAbility 及卡片页（Phase 8）尚未实现。若立即声明卡片并指向不存在的 src，存在构建风险。故 Phase 0 创建 `"forms": []` 空文件占位，P8-1 再填充两张卡片声明。

### 3.4 requestPermissions 暂置空数组

P0-7 要求配置 requestPermissions，但 PUBLISH_AGENT_REMINDER 权限属 Phase 9（P9-2）。Phase 0 以 `"requestPermissions": []` 占位结构，后续阶段填充。

### 3.5 common 测试目录清理

common 原 src 下有 ohosTest / mock / test 目录（基于旧 entry 结构，type=feature 测试模块）。转为 HAR 后移除 ohosTest target 并删除这三个目录，保持 HAR 简洁。根 oh-package.json5 的 hypium/hamock devDependencies 保留（无害）。

---

## 4. 最终工程结构

```
HealthyLifeDemo/
├── AppScope/
│   └── resources/base/{element,media}        # app_name + layered_image/background/foreground
├── common/                                    # HAR 静态共享库
│   ├── Index.ets                              # 统一导出接口（占位）
│   ├── build-profile.json5                    # targets: [default]
│   ├── hvigorfile.ts                          # harTasks
│   ├── oh-package.json5                       # name:common, main:Index.ets
│   └── src/main/
│       ├── module.json5                       # type:har（最小化）
│       ├── ets/                               # 空，待 Phase 1/2 填充 model/data/common
│       └── resources/                         # 共享 UI 资源（media/string/color/float）
├── entry/                                     # HAP 入口模块
│   ├── build-profile.json5                    # targets: [default]
│   ├── hvigorfile.ts                          # hapTasks
│   ├── oh-package.json5                       # dependencies: { common: file:../common }
│   ├── obfuscation-rules.txt
│   └── src/main/
│       ├── module.json5                       # EntryAbility + EntryBackupAbility + requestPermissions:[]
│       ├── ets/
│       │   ├── entryability/EntryAbility.ets
│       │   ├── entrybackupability/EntryBackupAbility.ets
│       │   ├── pages/Index.ets                # 占位页（import common 验证依赖）
│       │   ├── view/                          # 待 Phase 4/5
│       │   ├── viewmodel/                     # 待 Phase 3
│       │   ├── card/{form,widget}/            # 待 Phase 8
│       │   └── service/                       # 待 Phase 9
│       └── resources/base/
│           ├── element/{string,color}.json    # module_desc/EntryAbility_*/start_window_background
│           ├── profile/{main_pages,form_config,backup_config}.json
│           └── media/startIcon.png
├── build-profile.json5                        # modules: [common, entry]
└── oh-package.json5                           # 根 devDeps: hypium/hamock
```

### 资源归属最终划分

| 资源 | 归属 | 说明 |
|---|---|---|
| app_name | AppScope | 应用名 |
| layered_image / background / foreground | AppScope | 应用图标（module.json5 icon 引用） |
| startIcon | entry | 启动窗图标（module.json5 startWindowIcon） |
| start_window_background | entry | 启动窗底色（base #FFFFFF / dark #000000） |
| module_desc / EntryAbility_desc / EntryAbility_label | entry | module.json5 描述/标签 |
| 其余 string/color/float/media | common | 共享 UI 资源，经 $r 引用 |

---

## 5. 构建验证记录

### 5.1 首次构建（误删 module.json5 后）
```
hvigor ERROR: 00304064 Not Found
module.json5 file not found. At: common\src\main\module.json5
BUILD FAILED
```
→ 触发 3.1 修正

### 5.2 重建 HAR module.json5 后 clean 全量构建
```
hvigor BUILD SUCCESSFUL in 41 s 838 ms
```
但有资源冲突 Warning（module_desc / start_window_background 等）→ 触发 3.2 去重

### 5.3 去重后增量构建（entry@default）
```
hvigor Finished :entry:default@CompileResource... after 518 ms
hvigor Finished :entry:default@CompileArkTS... after 9 s 183 ms
hvigor Finished :entry:default@PackageHap... after 1 s 135 ms
hvigor BUILD SUCCESSFUL in 23 s 145 ms
```
无资源冲突警告，仅签名配置提示（debug 构建正常）。

### 5.4 依赖链验证
entry/pages/Index.ets 中 `import { COMMON_LIB_NAME } from 'common'` 编译通过（CompileArkTS SUCCESS），证明 `entry → common` HAR 依赖链打通，符合 P0 验证标准 "entry 可 import 'common'"。

---

## 6. 遗留与衔接

| 项 | 说明 |
|---|---|
| DEVECO_HOME | 已 setx 持久化（E:\Huawei\DevEco Studio），arkts_check 需重启会话生效；当前以 build_project 兜底校验 |
| form_config.json | 空 forms 数组，P8-1 填充两张卡片 |
| requestPermissions | 空数组，P9-2 增加 PUBLISH_AGENT_REMINDER |
| common/Index.ets | 仅占位导出，P1-7/P2-10 扩充 model/data 导出 |
| common/src/main/ets | 空目录，Phase 1/2 填充 model/data/common |

**下一阶段**：Phase 1 Model 层（P1-1 ~ P1-7），在 common/src/main/ets/model/ 实现枚举与实体类。
