---
类型: 技能库索引 / MOC
tags:
  - AI自成长引擎
  - 技能库
  - 技能治理
更新时间: 2026-10-15
---

# 技能库 · 个人自制 Skill 统一真源母仓

> **定位（2026-10-08 郭老师裁定）**：**这里只放我自制的 Skill，其他程序自带、自己下载的统统不管。**
> 
> 本目录（`D:\Work\元智能\10_AI自成长引擎\技能库\`）是**所有个人自产 Skill 的唯一真源母仓（Single Source of Truth）**。
> 目的：杜绝自制资产散落在各项目与宿主藏角，实现个人核心资产集中管理、井井有条、一览无余；外部宿主（如 Trae / Loomy）通过符号链接（Junction）或标准分发读取，改动永远只改本库真源。

---

## 一、两个界面的分工（★ 别搞混）

| 界面 | 是什么 | 谁管 | 会不会真生效 |
|---|---|---|---|
| **各程序自带/运行时目录**（如 `Loomy/opencode/skills/`、`~/.workbuddy/` 等） | 各软件自带的第三方插件、市场下载包 | **完全不管**（任其自生自灭，不碰不删） | 程序自管 |
| **`D:\Work\元智能\10_AI自成长引擎\技能库\`（本页）** | **郭老师自己亲手造、踩坑提炼出的核心技能资产** | **唯一自管真源** | 通过软链/安装投影生效 |

> **安全与备份**：本目录存放在 `D:\Work`，绝不随任何 IDE / 软件卸载重装而丢失；每晚 23:30 由 `scripts\快照草稿区.ps1` 自动执行增量 zip 快照兜底（保留最近 14 份）。

---

## 一之二、命名与映射原则

- **真源不带任何前缀**（2026-09-28 郭老师裁定）：目录名与 front-matter 的 `name` 就是 `<slug>`，全小写 kebab，不带宿主程序名、不带版本号。
- **宿主形态（如 `loomy-learned-`）仅为写权限映射**：安装或软链到特定宿主时按 `naming.yaml` 换算，不作为真源目录名。
- **外部项目引用走 Junction**：项目专属业务技能（如小红书管线）本体归入本库，原项目内通过 Windows Junction 目录链接直通本库，保持脚本路径与自动化无缝衔接。

---

## 二、自制技能全景清单 (Master Inventory)

### 1. 业务自动化管线类 (Business Pipelines)
生产环境真正在跑、带状态机与自动化调度的全流程业务技能：

| skill 名 (Slug) | 用途一句话 | 来源项目 | 状态 | 当前生效位置 |
|---|---|---|---|---|
| **`xhs-like-daily`** | 小红书点赞每日管线（A取消旧赞/B新笔记v3深度分析/C旧信息联网复核） | [[../../小红书点赞分析/README\|小红书点赞分析]] | **生产运行中** | `小红书/.trae/skills/` (Junction) + 计划任务 10:17 |
| **`multi-store-sync-delete`** | 多数据源同步真删 SOP（dry-run 校验、分批删云端行、删本地文件与 JSON 键、双向孤儿终检） | [[../../小红书点赞分析/README\|小红书点赞分析]] | **生产就绪** | `小红书/.trae/skills/` (Junction) |

---

### 2. 系统架构与路由协议类 (Architecture & Protocols)
跨项目、跨 Agent 的基础设施与治理协议：

| skill 名 (Slug) | 用途一句话 | 来源项目 | 状态 | 当前生效位置 |
|---|---|---|---|---|
| **`memory-router`** | 多 Agent 多项目共享记忆路由协议（Routing before Retrieval，先定项目再读记忆，fail-closed） | [[../../AI平台/Home\|AI平台]] | **现行规范** | `AI平台/agent/memory/protocol/` |
| **`gpt-mirror-extended-review`** | 走 AI <POOL_NAME_CN>账号池 / GPT 镜像站（**Chat 标签 + ChatGPT 6 Sol + 顶档 High**）送审方案；含 13 条自愈闸门（`mode_gate` 为**三闸**：Chat / 模型 `6` / pill `High`） | [[../../20_自适应工作流引擎/README\|自适应工作流引擎]] | **草稿 · 未安装**（P1 探针已跑通；P2 UI 探针待建） | 真源在 `技能库\`，契约已挂接巡检每日调度 |

---

### 3. 踩坑自沉淀工具类 (Self-Learned L3 Skills)
从真实工程排障与开发报错中提炼出的硬核防护技能（2026-10-08 统一由草稿区晋升归口）：

| skill 名 (Slug) | 用途一句话 | 提炼来源 (L1) | 状态 |
|---|---|---|---|
| **`lark-cli-home-redirect-not-configured`** | 解决 Windows 环境下用户家目录重定向导致 lark-cli 读不到用户配置的问题 | `20260920_lark-cli-home-redirect...` | 待按需分发 |
| **`node-exit-drops-piped-stdout`** | 防止 Node.js 在 process.exit 退出前写管道截断输出，避免下游工具拿到假数据 | `20260928_node-exit-drops-piped...` | 待按需分发 |
| **`obsidian-canvas-board`** | 规范用户语境下的可视化看板/可画特指 Obsidian Canvas (.canvas) 原生画布文件 | `20260920_obsidian-canvas-board...` | 待按需分发 |
| **`powershell-json-arg-space-truncation-field-id`** | 防御 PowerShell 5.1 传参时含空格 JSON 字符串被截断，强制使用字段 ID | `20260920_powershell-json-arg...` | 待按需分发 |
| **`snapshot-membership-loop-drops-new-inputs`** | 防止批处理遍历上一轮快照成员集时静默丢失新写入的数据条目 | `20260928_snapshot-membership-loop...` | 待按需分发 |
| **`split-parallel-walk-for-mass-fs-scan`** | 百万级海量目录遍历的分片并行扫描与进度心跳规范，防假死与卡顿 | `20260928_split-parallel-walk...` | 待按需分发 |
| **`zero-hit-census-is-scanner-failure-not-absence`** | 普查扫描零命中强制判定为扫描器自身故障，防止把脚本失效伪装为“无数据” | `20260928_zero-hit-census-is-scanner...` | 待按需分发 |

---

### 4. 伴跑自学生效资产收存类 (Session Learned Assets)
* **目录**：[`_收存_宿主自产/`](file:///D:/Work/元智能/10_AI自成长引擎/技能库/_收存_宿主自产/)
* **收存数量**：20 份 `SKILL.md`（2026-09-29 郭老师裁定确认为个人资产收存，包括 `opencli-browser-stable-roundtrip`、`feishu-base-batch-record-migration`、`agent-role-handover-doc` 等；2026-10-15 补收宿主新学的 `clash-direct-rule-fix`）。
* **性质**：只读收存，与运行时 20/20 SHA256 逐条相符，供后续体系深度整合时按需调用。
* **清单口径**（2026-10-15 郭老师裁定）：`清单.tsv` **只登记本人资产**（收存 / 漂移 / 无顶层 SKILL.md）。宿主程序自带、非本人资产的「非宿主形态（不收）」不落清单，只在采集脚本的终端统计里报告。

---

### 4.5 工作流 SOP 类 (Workflow SOPs)
多步骤固定操作流程的标准作业程序（不装进任何宿主，按需查阅）：

| skill 名 (Slug) | 用途一句话 | 来源项目 | 状态 |
|---|---|---|---|
| **`统编版语文教材篇目核对与同步`** | 教材篇目核对铁律（教师为唯一真源 / 先查替换时间表 / 只碰标题层）+ 五步同步流程 + 双验证门禁，防止照抄旧版目录与破坏 lessonId 资产对接键 | [[../../AI精听训练器/README\|AI精听训练器]]（`D:\listenloop` 句读/ListenLoop） | **待安装确认**（2026-10-15 定稿） |

---

### 5. 能力型工具类 (Capability Tools)
把**已存在的系统能力**封装成「按需调用、无常驻进程」的 skill —— 不改能力本身，只换承载形态：

| skill 名 (Slug) | 用途一句话 | 来源 | 状态 | 当前生效位置 |
|---|---|---|---|---|
| **`ai-search-pool`** | 多引擎 AI 搜索聚合：并发问秘塔 / Perplexity / 元宝 / Grok 等 8 个已登录的 AI 搜索网页端，交叉验证后出带引用来源的 HTML 报告。把原 `:3000` 搜索网关的逻辑改为 skill 形态，**无进程 / 无端口 / 无开机自启** | `D:\项目\ai-hub\search_gateway\`（`engines.py` + `content_pool.py`） | **可用**（2026-10-11 实测 52.2s 出报告；网关对照 63.4s，产出等价） | `~/.workbuddy-ai/skills/` (Junction) |

> **为什么不做成常驻网关**：`:3000` 只是把 `content_pool.run_search()` 包了一层 HTTP，而该函数**本就带 CLI**。
> 反例即证据 —— 该网关 2026-09-25 → 10-11 **静默死掉 6 周无人发现**（日志停 09-25、健康记录停 09-28）。
> 详见 `D:\记忆\调度大脑记忆\参考\reference_skill_ai_search_pool.md`。

---

### 6. 定时任务与巡检类 (Scheduled Ops & Patrol)
让「已经跑起来的自动化」**不会静默过期**：契约声明期望 → 只读探针核对 → drift 分级报人。**只读，绝不执行被监对象。**

| skill 名 (Slug) | 用途一句话 | 来源 | 状态 | 当前生效位置 |
|---|---|---|---|---|
| **`ops-task-fleet-watch`** | 本机定时任务舰队巡检：只读核对 38 个运维计划任务还在不在、有没有被停用、退出码对不对、有没有过期没跑 | [[../../20_自适应工作流引擎/README\|自适应工作流引擎]] | **已登记**（2026-10-15 首跑即报出 3 条真故障） | 真源在 `技能库\`，**不装宿主**（按需查阅）；巡检由计划任务 `MetaIntelligence_Workflow_Patrol` 每天 08:35 自动跑 |

> **它为什么不归「能力型工具类」**：能力型工具是「把某个能力换个承载形态、无进程无端口」；
> 本类恰恰相反 —— 它**监护的正是那些常驻/定时跑的东西**，且自带每日调度。
> 分类按「管什么」切，不按「怎么实现」切：本类管的是**自动化的健康**。
> 后续凡「让某条定时自动化不会悄悄停摆」的 skill 都归本类（例：渠道刷新、备份、看门狗）。

---

## 三、目录组织规范

```
D:\Work\元智能\10_AI自成长引擎\技能库\
├── README.md                                  # [本页] 全局唯一技能资产大台账
├── naming.yaml                                # 宿主名称转换规则映射
├── _中枢\                                     # 技能体检器、普查与治理脚本
├── _收存_宿主自产\                             # 伴跑自学 20 份资产只读收存
│
├── <业务与协议类>/
│   ├── xhs-like-daily\                        # 小红书每日管线真源
│   ├── multi-store-sync-delete\               # 多端真删真源
│   ├── memory-router\                         # 记忆路由真源
│   └── gpt-mirror-extended-review\            # 镜像站送审真源
│
└── <自沉淀工具类>/
    ├── lark-cli-home-redirect-not-configured\ # 7 个成熟 L3 技能包
    ├── node-exit-drops-piped-stdout\
    ├── ...
    └── zero-hit-census-is-scanner-failure-not-absence\
│
└── <工作流 SOP 类>/
    └── 统编版语文教材篇目核对与同步\        # 教材篇目核对与同步 SOP（2026-10-15 晋升归口）

└── <能力型工具类>/
    └── ai-search-pool\                        # 多引擎 AI 搜索聚合真源（2026-10-11 入）
│
└── <定时任务与巡检类>/
    └── ops-task-fleet-watch\                  # 定时任务舰队巡检真源（2026-10-15 入）
```

> **宿主投影**：`ai-search-pool` 在 `<HOME>\.workbuddy-ai\skills\ai-search-pool` 处为 **Junction**，
> 直通本库真源（`LinkType=Junction`，已实测透过链接可正常运行）。**改动永远只改本库真源。**

---

## 四、自制 Skill 维护守则

1. **改动只改真源**：任何自己造的 Skill 逻辑演进或修改，一律在 `D:\Work\元智能\10_AI自成长引擎\技能库\<skill-id>\` 下进行。
2. **草稿归口流转**：新提炼的 L3 技能写完并通过验证后，从 `草稿区\L3_Skill\` **移动**至本目录，并在本 README 清单登记一行。
3. **程序按需分发**：外部程序若需调用，通过 Junction 软链接或安装命令单向投影过去，绝不反向在外部散落修改。
4. **调用后记台账（2026-10-15 补，落实 docs/03 §五 的"反馈"端）**：skill 被真正调用并完成一次任务后，按 R3 Q6 口径记一条 `kind=skill` 运行事件 ——
   `node runners/run-event.mjs --record '<json>'`，必带 `skill_id`／`skill_version_sha`／`trigger_matched`／`invoked`；
   `outcome=success` 还必须有**非自报**的 `acceptance_source` ＋ `acceptance_ref`（自报／退出码／模型自称一律不算）。
   **为什么**：docs/03 §五 的「命中 +1／被推翻 ≥2 降级／90 天未命中标 stale」全部靠这条台账算，**没有记录就等于衰减规则无从计算**。
   **算账入口（只读）**：`node runners/skill-decay-report.mjs --skills-dir 10_AI自成长引擎/技能库`，加 `--apply` 才落 `runtime/skill-decay-report.{md,json}`；
   它把「命中 TOP5／被推翻清单／stale 清单／零记录 skill」摆出来，**降级与删除仍由人执行**（本件不删不改任何 skill）。
