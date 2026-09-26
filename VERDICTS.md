# VERDICTS · 外部裁定原文存档

本文件按轮次**逐字**保存高智力模型的裁定原文，用来复核"这句话到底是谁说的"。`DECISIONS.md` 与 `ISSUES.md` 里的摘要都是对本文的转述，两者冲突时以本文为准；本文与后续轮次冲突时，以最新轮次为准并在此处标注被推翻点。

每份存档的头部记录：送审时对方实际读到的材料、回读凭证输出、当时的题目状态。**正文一字未改**，包括它对本地草案的认错与对我方错误的判定。

---

## 第 1 轮 · 2026-09-25 22:20 · Q1~Q8 + D-003 融合裁定

**送达核对**：回读凭证 `FACTS-DELIVERY-c8613790` 输出正确（该值仅存在于材料包首行，未在提示词中出现）；`ALL_CORE_DOCS.md` 与 `ALL_SPEC_DOCS.md` 均首次即 HTTP 200。注：本轮尚无"双包尾凭证"要求，该要求是本轮裁定 (b) 提出的，已实现。

**题目**：`ISSUES.md` Q1~Q8（其中 Q8 的前提"抓取层不回源"在当天夜里被推翻，见 `CURRENT_STATE.md` §六）。**本地基线**：`LOCAL_DRAFT_FUSION_PLAN.md` v0.1。

**采纳结果**：DEC-08 升 v2、DEC-11、DEC-12、DEC-13、DEC-14、DEC-15；`DEMAND.md` D-003 升 active v1；`LOCAL_DRAFT_FUSION_PLAN.md` 顶部登记三处驳回。

---

### 正文（逐字）

## Q1 · 融合后谁是"当前状态"的唯一真源

**结论：采用"单一 Current State 语义对象 + 多原生事实真源 + 单向生成"的方案。** 不把 `CURRENT_STATE.md` 设为可写真源，也不把记忆库、看板或 drift 文件强行迁成一个数据库。每个 Demand 只有一份规范意义上的 Current State；它由 Demand 当前版本、执行看板、探针/runtime、实验/决策等原生真源生成。`CURRENT_STATE.md` 和 Obsidian 都是这份 State 的视图。元智能规范本身要求每个 Demand 有一份明确 Current State，并把它定义为"现在的最小真实描述"，同时明确禁止把日志和全部历史塞进去。

**有资格进入 State 的信息**：当前 Demand 版本、阶段、正式方案、当前能力、主要问题、活动 Task/Experiment、当前风险、下一步、待人工决定、最近会改变判断的重要变化、更新时间。**必须留在原处的**：完整日志、历史事件、执行证据、探针原始结果、Task/Experiment 完整生命周期、归档材料。

**冲突优先级**：原生机器事实/契约/探针结果 > 经确认的 Decision > 生成的 Current State > Human View。投影与真源冲突时，State 判失效并重新生成，不允许反向修改真源来"配平视图"。

**作废条件**：如果以后出现某类跨系统状态无法从原生真源确定性重建，且它本身具有独立生命周期，才需要重新评估是否给 State 增加独立持久化字段。

这点与本地草案"`CURRENT_STATE.md` 直接由三处真源生成"方向接近，但我不赞成把 Markdown 文件本身叫作唯一状态真源；唯一的是 **State 语义对象**，Markdown 只是投影。

## Q2 · Demand 层放不放在元智能

**结论：放，而且应归元智能层所有，不应放进上游引擎。**

规范明确把 Demand 定义为长期存在、会演进且有稳定 ID、版本、success_state、constraints 的核心对象；系统中心就是 Demand。 这正是三套现有系统缺失的共同上位语义。

因此本地草案中"在上游新增 `demands/<id>.yaml`"这一点我不同意：会让上游子系统变成整个融合系统的概念所有者。更稳妥的是元智能拥有 Demand 真源；上游经验系统、下游契约系统只持 `demand_id`/指针。

**判据**：只有长期目标定义、成功状态、硬约束、偏好、版本及变化原因属于 Demand；任务进度、运行状态、探针数据、经验条目都不进入 Demand 本体。规范也要求 Demand 修改时保留旧版本并重新判断现有 Task/Experiment 是否受影响。

**冲突优先级**：Demand.constraints > 已有实现策略；但已正式确定的人类治理 Decision 若要被新 Demand 推翻，必须显式升版，而不是静默覆盖。

**作废条件**：只有未来证明三套系统实际上不共享任何长期目标、彼此生命周期完全独立，Demand 才没有上位统一价值。

## Q3 · Human View 是否反向治理现有看板

**结论：治理"用户入口"，不治理"执行台账格式"。现有看板不合并、不重写成 Human View，但用户不应再依赖它们才能知道系统状态。**

Human View 的规范定位是"人类认知压缩层"，首页只保留会改变理解、下一步、风险或人工决定的信息，并明确默认隐藏路径、JSON、日志、重试细节等。

所以边界应是：

* 两个技术看板继续承担执行证据与细粒度进度；
* 新的 Human View 从 Current State + 必要原生真源生成；
* 技术看板降为可展开的 L3 证据层，不再承担默认首页职责；
* 不要求旧看板为了"好看"丢失技术精度。

**冲突优先级**：Human View 与技术台账冲突时，以原生台账/State 为事实依据，Human View 必须重生成。

**作废条件**：若未来某看板被正式指定为 Human View 本身，那它才必须全面遵守 Human View 标准。

## Q4 · 自动产出与人审闸门

**结论：自动生成允许，自动进入候选登记允许；任何会改变正式技能库或运行时行为的晋升/安装/启用必须人工批准。**

也就是把"生成"和"生效"彻底分开：自动产物先进入隔离候选区，自动跑身份、撞车、来源、基本验证；通过后进入待审队列；只有人工点头后才成为正式 L3 技能或安装到运行时。这同时保留自动学习，又不破坏既有"五步安装闸门、第 4 步人工点头"的正式决定。

**判据**：只要某一步会改变运行时可调用能力、覆盖已有正式技能、修改共享真源或扩大影响面，就必须进入人工 Gate；纯生成、静态扫描、去重、候选元数据登记可自动完成。

**冲突优先级**：人工批准规则 > 自动学习流水线。

**作废条件**：未来若存在可证明等价于人工审批的机器策略，也应先作为 Experiment 验证，不能直接取消人审。

## Q5 · 判定可信度是否进入 V1 完成条件

**结论：必须进入。**

当前规范的主循环已经要求 Evaluate 后判断"结果可靠吗"，不可靠则升级、建实验或请求高智力模型；模型路由也明确把"Flash 无法可靠验证结果"列为升级条件。 因此把可靠性加入验收并不是改变系统哲学，而是在把已有原则变成机器验收。

最低要求应限定在**会更新 State、触发动作或产出正式结论的判定器**：

1. 至少有已知正/负样本哨兵；
2. 有数值范围和合计不变量；
3. 关键结论至少一种独立交叉验证；
4. self_test 失败必须 fail-closed，不得继续写正式状态；
5. 无法自证时升级，不让快速模型硬猜。

现有实测已经证明 self_test 能发现"结果结构完整但语义错误"的情况。

**冲突优先级**：验证失败 > 正常流程推进；不得用"输出看起来合理"覆盖 self_test 失败。

**作废条件**：如果某输出明确只是草稿、不会进入 State/Decision/执行动作，可降低到非阻断式验证。

## Q6 · 946 条死链清理授权边界

**结论：先生成完整 dry-run 清单 + 回滚清单，人工一次批准这个确定批次，再统一执行；不能直接授权无预览跑完。`lark-*` 已删除项在本次清理中不得顺手重建。**

规范材料已经把 P0.5 定为"清单 + 备份 + 点头"，并要求执行前逐条验证仍是 ReparsePoint 且目标确不可达；946 条已通过两条独立通道交叉验证为同一类 ORPHAN。

这里"一次批准"指批准**清单中明确列出的固定集合**，不是以后所有死链的长期授权。执行时如果实际对象与 dry-run 清单不一致，应停止该项而非扩大删除范围。

**冲突优先级**：人工批准的具体 manifest > 自动发现的新对象；新增对象留到下一批。

**作废条件**：dry-run 到执行之间若数量、路径类型、目标可达性发生变化，原批准自动失效。

## Q7 · 敏感事实长期闸门

**结论：应固化为阻断式 pre-push 闸门，但必须先修掉"整行白名单跳过"这个结构性盲区。**

现有 23 类规则能覆盖已知目标，但材料同时明确记录三个盲区：整行白名单、枚举式规则只能查已知类别、`real_name` 只匹配一个字面量；而且现在掩码仍是一次性人工过程，没有挂到 pre-push。

我的边界是：**公开事实仓内不允许出现任何被定义为"应掩码"的原值。** 原值只允许存在于本地原始真源和本地映射表。对于明确决定保留的类别，例如路径中的用户名、用于发现机制的模式正则，不要靠"整行跳过"，而应采用"类别 + 字段/路径范围"的精确 allowlist。

闸门顺序也应固定为：所有源文件修改完成 → 合并副本重新生成 → 全仓扫描 → 检查扫描器自身 self_test/跳过统计 → 全绿才允许 push。材料已记录过"先扫描、后修改文档"导致 0 命中结论过期的事故。

**冲突优先级**：阻断式掩码 Gate > push。

**作废条件**：若仓库永久转为受控私有且威胁模型正式调整，可重新定义允许范围，但不能静默放宽。

## Q8 · 按本轮新实测重新判定

你本轮给出的四条首次 200，已经直接使治理层中"抓取层不回源、只能缓存命中"的旧因果判定失效。因此 `CURRENT_STATE §六`、README、REPORT §0、ISSUES Q8 的那组因果不能继续作为事实使用；它们现在只能作为历史实验记录。旧材料本身也要求事实变化时更新 State，因此这里应以新实测覆盖旧结论。

### (a) Raw URL 的最低"预热 + 重试"要求

**定为：单份材料最多 3 次，总计；第 1 次同时充当预热/正式读取，失败后间隔 15 秒，再试第 2、3 次。3 次都失败，则该材料本轮判为"未送达"，阻断依赖它的正式作答。**

原因不是认为"15 秒后一定恢复"，而是把它定义成一个廉价、确定的**送达闸门**。你已经观察到同一 URL 可能连续数小时失败后又恢复，所以再把同步流程设计成无限重试没有意义。3 次是本轮同步检查的边界，不是对故障持续时间的因果判断。

如果两个必读包中任一包 3 次都失败，正式评审应只返回"材料未完整送达"，而不是凭旧缓存或上一轮记忆继续作答。

### (b) 只回读交付号是否足够

**不够。**

首行交付号只能证明"至少读到了 CORE 的头部且版本匹配"，不能证明 SPEC 也读到，也不能证明文件尾部/完整交付可达。

最低补强应是：**一个 delivery_id + 每个必读包各一个本轮唯一 tail nonce。** 生成包时：

* CORE 首行写 `delivery_id`；
* CORE 末尾写 `core_tail_nonce`；
* SPEC 末尾写 `spec_tail_nonce`；
* 三者都随本轮生成而变化。

正式回答开头必须原样回读三者。少一个即视为材料不完整。这样同时验证"版本新鲜度 + 两包都能读到 + 至少能触达各包尾部"。

若再加一层而仍保持便宜，可在 CORE 里放 manifest：两包文件数、字节数/行数和 SHA-256；但 **manifest 是辅助完整性证据，不替代双包尾 nonce**。

### (c) URL 反复失败时何时换承载

**判据定为：同一轮 3 次读取失败后，不再继续在同一承载上重试；立即切到一个"独立且能在当前会话完成回读确认"的承载。**

关键是"独立 + 当场通过同一回读闸门"，而不是看到 raw 失败就机械切 Pages、导出仓或分卷。因为当前只知道现象不稳定，并不知道根因；换一个仍依赖同类 GitHub 抓取路径的载体，如果不能当场通过 delivery_id + tail nonce 验证，就不算切换成功。

因此自动换承载的触发不是"累计失败了多久"，而是：

**当前评审材料 3 次失败 → 当前承载本轮失效 → 切换独立承载 → 新承载必须立即通过同一三项回读确认；否则仍然阻断作答。**

长期默认承载则不要因一次故障改写。只有当某替代承载在**连续 3 个独立交付轮次**都通过，而 raw 在其中至少 2 轮触发三连败，才有资格把默认送审承载迁过去。否则保留 raw 为默认、失败时切换。

### Q8 对 DEC-08 的影响

**DEC-08 需要升版，不应删除。** GitHub 仍可作为共享事实的规范发布源；需要删掉的是隐含等式：

`git push 成功 = 高智力模型已同步成功`

改成：

`git push 成功 = 事实已发布；delivery_id + 双包 tail nonce 回读成功 = 本轮评审材料已送达。`

这样既吸收了今天"冷 URL 也能首次 200"的新事实，又不把一次成功反推成新的抓取机制因果。现有 DEC-08 确实只定义了 GitHub 共享事实层，没有定义接收方送达验收。

## 对 LOCAL_DRAFT_FUSION_PLAN 的总评

我认同"**概念取元智能、机制复用下游、经验治理复用上游**"这个映射方向，但不同意"融合只需新建 Demand 一个对象"。

主要有三处需要改：

1. **Demand 归属错位**：不能放在上游，应由元智能层持有，否则上游子系统变成整体语义的所有者。规范明确把 Demand 定为系统中心。
2. **State 不能只等于一份 Markdown 摘要**：仍需要一个规范的单一 Current State 语义对象/生成契约；它可以是投影，但必须具有明确字段、生成规则和失败规则。
3. **"只有第 1 步需要写代码"过于乐观**：要真正达到 V1，还需要生成式 Human View、State 校验、Demand 版本传播、实验生命周期、候选技能闸门、脱敏阻断等自动化。V1 自身完成条件也包含 Task、Experiment、Archive、Human View 和持续运行，而不是只创建 Demand。

草案的观察窗"至少覆盖一次真实需求变更"是**必要但不充分**。最低验收应至少实际走完一次：Demand 版本变化 → 受影响 Task/Experiment 被重新判断 → State 重新生成 → Human View 更新；否则还没有验证融合主循环。

## D-003 · 三套系统融合

**statement**
让一个长期 Demand 在元智能、执行验证引擎与经验沉淀引擎之间长期保持**统一语义、明确归属、可追溯联动且无重复可写真源**，并在任一子系统的契约、职责边界或能力发生变化时自动重新评估三者映射。

**success_state**

任一 active Demand 都能沿一条确定链路回答：当前 Demand 是什么 → 当前 State 是什么 → 哪些 Task/Experiment 正在执行 → 哪个原生系统提供证据 → 哪些结果已沉淀为可复用经验；同一事实不存在两个可独立修改的正式真源；任何视图都能回指原生证据；任一子系统可以被替换而不改变 Demand 的语义。

**constraints**

不新增第五份可写状态真源；保留已验证的下游契约/探针机制与上游人审、经验沉淀机制；元智能只拥有跨系统语义，不吞并各系统的执行真源；用户不需要管理机器层文件结构；新增对象、字段和自动化必须通过"降低认知成本、服务 Demand、降低长期维护成本、有真实证据"等 Gate。

**recheck_on**

任一子系统更换其 SSOT/契约；Demand 模型或稳定 ID 规则变化；State 投影与原生事实出现无法自动消解的不一致；同一事实再次出现双写；新的执行/沉淀系统加入或旧系统退出；Human View 无法从 Current State 确定性生成；一次真实 Demand 变化无法完整传播到 Task/Experiment、State 与 Human View。

这一定义刻意不重复 D-001 的"全机 AI 资产治理"，也不重复 D-002 的"送审链路可用性"；D-003 只负责**三套系统之间的语义融合与职责边界**。

---

### 存档后被本地调整的点

1. 裁定 (b) 要求的三项回读凭证已实现（`build_core_bundle.js` 每轮随机生成，CORE/SPEC 末行各一枚，随机值不入库）。
2. 裁定 (a)(c) 与 DEC-11/12 一致；本地另补一条它未覆盖的情形：**首行 `delivery_id` 命中的是上一轮而尾凭证不符时判为 CDN 滞后读到旧版本**，等 10 分钟重跑同一链接，不重发材料也不换承载。
3. 采纳 Q2→DEC-13、Q4→DEC-14、Q5→DEC-15、Q8→DEC-08 v2/DEC-11/DEC-12；D-003 四段照录入 `DEMAND.md` v1。Q1/Q3/Q6/Q7 的结论暂不入 DECISIONS（属方案层边界，等实施时再定版）。
---

## 第 2 轮 · 2026-09-25 深夜 · 融合后的物理形态（N1~N6）

**送达核对**：三项回读凭证全部正确输出 —— `FACTS-DELIVERY-82b21118 | CORE-TAIL-F99DB63B | SPEC-TAIL-D9BEAB4D`。尾凭证命中说明两个包（46 KB / 200 KB）都是**整包**读到的，这是该机制第一次真正发挥作用。

**提问方式**：本轮起由本地执行模型通过 opencli 直接在镜像站会话里对话（Extended 档位，发问前核对 pill；长中文走 base64 + `insertText` 注入，775 字符零截断）。同一对话窗口、同一标签页续问。

**题目**：`ISSUES.md` 第 2 轮 N1~N6；基线 `LOCAL_DRAFT_ENTRY_LAYOUT.md` v0.1。

### 正文（逐字）

FACTS-DELIVERY-82b21118 | CORE-TAIL-F99DB63B | SPEC-TAIL-D9BEAB4D

N1｜入口与执行层的物理边界

裁定：不并仓、不搬三套执行系统。新建一个真正的“元智能控制项目”，把三套系统注册成它的组件。基线“原地不动”是对的，但把新项目设计成单纯的 需求/状态/证据 Obsidian 入口库是错的。

原因很明确：D-003 已定“元智能只拥有跨系统语义，不吞并各系统执行真源”，并要求任一子系统可以替换而不改变 Demand 语义；规范同时明确目录、模型、Agent、程序都只是可替换实现，用户不负责文件结构。
GitHub
+1

物理结构应改为：

D:\Work\元智能\                    ← 唯一“项目根”，机器控制平面
│
├─ project.yaml                   ← 三组件注册表；机器维护
│
├─ machine\
│  ├─ demands\                    ← Demand 唯一真源
│  │  ├─ D-001.yaml
│  │  ├─ D-002.yaml
│  │  └─ D-003.yaml
│  ├─ schemas\                    ← Demand / State 等 schema
│  ├─ adapters\                   ← 读取三套原生系统
│  └─ generator\                  ← State / Human View 生成器
│
├─ generated\                     ← 全部只读、可删可重建
│  ├─ state\
│  │  ├─ D-001.json
│  │  ├─ D-002.json
│  │  └─ D-003.json
│  ├─ CURRENT_STATE.md
│  ├─ evidence\
│  │  ├─ 自成长.md
│  │  ├─ 工作流.md
│  │  └─ 规范.md
│  └─ human\
│     ├─ 00_首页.md
│     └─ demands\
│
└─ runtime\
   ├─ build-status.json
   └─ source-health.json

三套组件仍在：

D:\Work\AI自成长引擎\
D:\Work\自适应工作流引擎\
D:\meta-intelligence-facts\

project.yaml 注册它们的路径、类型、SSOT 入口和健康探针；它不是内容副本，更不是 junction 树。

所以“一个项目”的含义定死为：一个控制平面、一个 Demand 命名空间、一条生成链、一张 Human View；不是一个 Git 仓、不是一个物理目录树。 如果真把三套仓库搬进一个 monorepo，会为了文件形态统一而破坏“执行真源独立、实现可替换”的既定边界，而且当前机器已经有过大规模链接失效事故。基线也记录了三个执行区目前各有自己的物理位置和 Git。
GitHub

判据： 用户从 D:\Work\元智能\ 进入后，不需要知道另外三个根目录；机器能由 project.yaml 定位全部原生真源；三套系统仍能各自独立运行和替换。

作废条件： 如果未来三个执行系统已经实际共享同一发布周期、同一依赖图、同一权限边界，并且迁为 monorepo 能被实验证明降低长期维护成本且不破坏任何原生 SSOT，再重审。不满足这些条件，不并仓。

N3｜Demand 台账真源放哪里

裁定：Demand 真源放 D:\Work\元智能\machine\demands\。既不放公开事实层，也不把 Obsidian 页面当真源。

这是本轮最需要纠正基线的地方。

当前事实层 README 已明确：公开事实仓是三套本地原始文件的只读投影副本，唯一真源仍在本地。因此把 Demand 真源放 D:\meta-intelligence-facts\ 会与仓库自身契约冲突。
GitHub
 DEC-13 又明确规定 Demand 由元智能层持有、上下游只持 demand_id。
GitHub

因此物理落点就是：

D:\Work\元智能\machine\demands\D-xxx.yaml

数据方向固定为：

machine\demands\        ← 唯一可写真源
       │
       ├──→ generated\human\...          Obsidian 投影
       └──→ meta-intelligence-facts      已掩码共享投影

不采用指针作为 Obsidian Demand 页面。 Obsidian 面向用户的是 Demand Interface，而且规范要求机器原始信息在进入 Obsidian 前压缩、合并、重写；这天然要求“生成投影”，而非把机器真源裸露给人。
GitHub

对基线“不确定点 2”的明确表态

选本地元智能项目真源；公开事实层与 Obsidian 都是生成投影。 基线倾向的“事实层真源”我否决。

判据： 修改一个 Demand，只允许一个写入口；任何一次扫描发现同一 D-xxx 在两个位置都可被独立编辑，即判架构违规。

作废条件： 只有事实层未来不再是公开/掩码投影，而正式升级成本地元智能机器层自己的 canonical repository，且原本地 Demand 存储同时被撤销，才可以迁真源；不能双持。

N4｜生成器契约

裁定：不能直接“若干 Markdown → CURRENT_STATE.md → 首页”。中间必须先生成一个可校验的 Current State 语义对象，Markdown 和 Human View 都从它单向渲染。

这与上一轮 Q1 一致，也符合 State 规范：每个 Demand 必须有一份 Current State，它是“现在的最小真实描述”，并有明确的强制更新事件。
GitHub

输入
输入	权威范围
machine\demands\D-xxx.yaml	Demand 身份、版本、statement、success_state、constraints
两套原生任务/执行记录	Task 生命周期与执行结果
runtime/*.drift.json / 探针	实际运行态、漂移、能力证据
Experiment 原生记录	假设、基线、状态、结果
DECISIONS / VERDICTS	已正式决定的策略与治理结论
component manifest	原生真源位置与可读性

Task 必须关联 Demand；规范的 task schema 本身把 demand_id 列为必需字段。
GitHub

Canonical State 字段

至少固定为：

类别	字段
身份	demand_id, demand_version
当前态	status, phase, strategy, capabilities
问题	main_issue, risks
活动工作	active_tasks, active_experiments
行动	next_step, human_decisions
变化	recent_changes, updated_at
完整性	validity, source_snapshot, input_hash, conflicts

前十一类业务字段来自既有 State Model；现有 schema 已要求 demand_id / updated_at / status / phase / next_step 并定义活动任务、实验、风险和人工决定等结构。
GitHub
+1

确定性要求

同一份输入快照必须生成同一个语义结果。 具体执行规则：

input_hash 由所有实际参与推导的 canonical 输入内容计算；数组固定排序；同字段只有一个预先登记的 owner；不能让 LLM 临场决定“哪份看起来更新”；updated_at 取导致 State 变化的最新权威事件时间，不能用“这次脚本几点运行”破坏确定性。

生成链固定：

原生真源
  ↓ adapters
Typed Facts
  ↓ validate + resolve
Current State JSON
  ↓
  ├─ CURRENT_STATE.md
  ├─ 00_首页.md
  └─ Demand 详情页 / Evidence Index
生成失败时首页显示什么

fail-closed。旧首页不得继续伪装成现状。

生成失败后，机器原子替换首页顶部为：

当前状态：不可确认
原因：状态生成失败 / 原生事实不可读 / 权威事实冲突
最后一次已验证状态：<时间>
本次失败：<时间>
需要你决定：无（除非确实存在人工决策）

旧的最后成功内容可以放在折叠的“上次已验证快照”里，但不得继续显示为“当前状态”。规范本来就禁止保留过期下一步，并要求 Human View 精确呈现状态。
GitHub
+1

“视图与真源冲突”的可执行判据

满足任一项即 validity=invalid：

检查	判定
当前输入重新计算的 input_hash ≠ State 内 input_hash	State 过期
State 的 state_id/input_hash ≠ 首页内嵌值	首页过期
一个字段收到两个不同的同级权威值	原生事实冲突，禁止猜
active Task/Experiment 不存在，或其 demand_id 不一致	State 无效
schema/self-test 失败	State 无效
component 真源不可读	受影响 Demand 状态不可确认

绝不允许“选一个比较像真的值继续展示”。

判据： 任意生成产物都能回答“我由哪一组输入、哪个 Demand 版本生成”；删除整个 generated\ 后能够从真源完整再生。

作废条件： 如果未来 State 不再是派生对象而被正式裁定为独立可写真源，则整套生成契约要重审；在当前 DEC/Q1 下不能这样做。

N5｜谁触发重生成

裁定：唯一正常触发机制是“机器事件触发”，不是人工按钮，也不是定时生成。Agent 每次完成一次会改变权威事实的事务，必须发 state_dirty；探针、Decision、Demand 修改等非 Agent 变化同样由对应写入器发同一个事件。

也就是说，不把“记得跑脚本”交给任何人，也不把“每隔十分钟重做一遍所有东西”当主机制。

现有规范本身已经规定：Demand 修改、Task 终止、Experiment 出结果、策略变化、新重要异常、关键 Decision 等事件之后必须重建 State；主循环最后也是 Update State + Human View。
GitHub
+1

事务完成定义应变成：

写原生真源
→ emit state_dirty(demand_id)
→ 生成 State
→ schema/self_test
→ 渲染 Human View
→ 重新读取产物
→ 核验 input_hash / state_id
→ 才允许本次事务标记 DONE

这解决“脚本成功 ≠ 页面已经新”的问题：成功判据不是 generator exit code 0，而是重新读取落盘页面后，里面的 state_id/input_hash 与刚生成的 State 完全一致。

另设一个 10 分钟 watchdog，只负责发现漏触发，不负责替代事件机制。它比较“原生输入最新 hash”和“最后成功 render hash”。一旦不同超过 10 分钟，立即把首页降级成“状态不可确认”，并向本地执行 Agent 建故障 Task；只有故障涉及架构冲突或连续不能自动恢复时才升级高智力模型。这样与草案提出的“Demand 升版后十分钟内联动完成”可以直接机器化。
GitHub

对基线“不确定点 3”的明确表态

选事件触发，由元智能控制项目负责；不选手动，不选定时作为生成机制。

判据： 用户完全不执行生成命令；任何规定的 State 更新事件发生后，10 分钟内 State 与首页要么更新成功，要么首页明确变成“不可确认”，不存在静默旧页面。

作废条件： 如果所有原生系统未来统一迁入一个支持原子事务/订阅的数据库，可把 state_dirty 改成数据库 CDC 等实现；但“写事实后自动触发、最终回读验证”的责任不作废。

N2｜证据指针的活性

裁定：不要 junction/symlink。证据层改成机器生成的索引页。

这是对基线“不确定点 1”的明确回答：生成索引页，不用文件系统链接，也不复制正文。

当前项目已经实测过链接判活的坑：junction 断掉后，简单 Test-Path 仍可能给出错误存活结果，DEC-06 已要求必须使用真正穿过链接的活性探针。
GitHub
 在这里再造一层 junction，只会重新引入一种没有业务价值的故障模式。

generated\evidence\自成长.md 等页面应从 project.yaml 生成，内容只包括组件身份、职责、当前健康、最后验证时间、关键原生对象索引；L3 才可显示实际路径。Human View 默认本来也禁止展示文件路径。
GitHub

活性责任
项目	裁定
责任主体	元智能项目的 component-health checker
强制检查	每次 State build 前
周期检查	每 10 分钟
判活方式	实际打开组件的已登记 sentinel/SSOT 文件并验证预期结构；不能只判断目录存在
失败记录	runtime/source-health.json
页面响应	受影响 Demand 立即标“状态不可确认”，不继续展示旧现状
报给谁	先自动创建本地故障 Task 给执行 Agent；只有需要人工决策才进首页 Decision Queue

所以即使 Obsidian 完全不跟随 symlink 的搜索、反链和图谱，架构也不受影响——我们根本不依赖它跟随。

判据： 删除或改名任一已注册组件的关键 SSOT，最长 10 分钟内必然出现机器故障状态；用户无需检查链接。

作废条件： 如果未来 Obsidian/文件系统提供经过本机实测、可可靠索引并自动管理生命周期的虚拟挂载，而且它显著降低维护成本，再评估；在当前 946 条死链背景下不采用。

N6｜迁移顺序与红线

第一步最小可逆动作：只创建新的 D:\Work\元智能\ 控制项目和 project.yaml，接入现有系统为只读输入，在 generated-staging\ 做旁路生成。此时不移动、不重命名、不删除任何旧文件，也不切换用户入口。

这是最小风险动作，因为规范也要求先实现最小闭环，并明确“不因一次失败扩大架构”。
GitHub
+1

迁移顺序定为：

阶段	必须完成后才进下一步
1. 注册	project.yaml 能定位三系统，并通过 health check
2. Demand	在 machine\demands\ 建 D-001~D-003 真源；事实仓/Obsidian 只生成
3. 关联	给所有现存 Task/Experiment 补 demand_id
4. 旁路	生成 State + 首页，但旧入口不动
5. 实测	做一次真实 Demand version 变化，完整传播 Task/Experiment → State → Human View
6. 切入口	通过后才让新的 00_首页.md 成为默认入口
7. 去旧写口	最后才停止旧的重复 State/Human View 写入，留下只读兼容期
demand_id：要不要回填

要。

所有非终止 Task、所有正在进行/可继续的 Experiment 在切换入口前必须有 demand_id；否则系统无法满足“Task 必须明确服务于某个 Demand”的规范，也无法实现 D-003 要求的 Demand → State → Task/Experiment 确定链路。
GitHub
+1

历史终止记录也应自动批量回填；不能可靠归属的历史项进入 unresolved-migration 队列，不允许执行模型凭猜测绑定。活动项存在一个无法归属，就阻断正式切换。

绝对不许动

本轮迁移中：现有两个执行引擎根路径不搬；各子库 .git 结构不合并；正式技能库物理位置不搬；下游契约/探针 SSOT 不迁；事实层仓不升格为本地写真源；不批量创建 junction；不让生成器反向修改任何原生执行事实。这与 D-003 的“不吞并执行真源”和草案记载的现状边界一致。
GitHub
+1

直接回滚信号

出现以下任一类即撤掉新入口、回到原有系统继续运行：产生第二份可写 Demand；生成器修改了原生真源；活动 Task/Experiment 无法唯一绑定 Demand；一次真实 Demand 升版超过 10 分钟既没有新页面也没有明确故障页；生成后的首页与 State input_hash/state_id 不一致；接入新项目造成既有 Git/技能解析/探针失效；同一 State 字段存在不可自动消解的同级权威冲突。

回滚简单的前提，就是前五阶段不搬旧目录：撤掉默认入口和新控制项目即可，执行系统本身未被破坏。

对基线三个“不确定点”的最终定案
问题	裁定
指针还是生成索引页	生成索引页；禁止 junction/symlink 作为证据层结构
Demand 台账真源在哪	D:\Work\元智能\machine\demands\；事实层和 Obsidian 均为投影
谁触发生成	元智能事件机制；所有权威写入器发 state_dirty，生成后必须回读校验；10 分钟 watchdog 只负责发现漏触发

因此，这一轮我对 LOCAL_DRAFT_ENTRY_LAYOUT.md 的总裁定是：“三引擎原地不动”保留；“另建统一项目”保留；但这个新项目不能只是 Obsidian 入口壳。它必须升级为整个融合系统的机器控制平面，Human View 只是它的一个 generated 输出。

---

## 第 3 轮 · 2026-09-25 深夜 · 控制平面的第一版范围（a~d）

**读取事故记录（重要）**：本轮提取脚本连续两次报 `LOW_REPLY / 空回复`，我差点按 SOP 上报「实例退化」。真实原因是**长对话里离屏的 assistant 节点被 React 虚拟化清空 innerText** —— 滚到底后同一节点立即读出 1433 字带表格的完整回答。修复落在共享脚本 `ai-hub-memory/scripts/gpt_wait_extract.mjs`（探测与提取前先滚到底，ab446fe），不是手工捞回这一轮数据。

**送达核对**：本轮明确禁止访问链接、只凭对话内已读材料作答，故不再要求回读凭证（三项凭证已在第 2 轮验证过）。

### 正文（逐字）

(a)
第一版必须有：project.yaml、Demand 真源、单一生成脚本、State+首页生成、失败显式失效、生成后回读、确定性输入指纹。可后补：state_dirty、10 分钟 watchdog、独立 schemas/、adapters/。完整 input_hash 规则可缓，先用排序后的输入文件 SHA-256。你提的“Agent 收尾生成+回读”够，前提是所有写真源的程序都执行它；否则立刻补 watchdog。
(b)
YAML
components:
- id: growth
  path: D:\Work\AI自成长引擎
  type: experience
  ssot: docs\01-任务看板.md
  sentinel: {file: docs\01-任务看板.md, open: true, contains: ["类型: 任务看板","# 01 · 任务看板"]}
  owner: growth
  last_verified: null
- id: workflow
  path: D:\Work\自适应工作流引擎
  type: execution
  ssot: contracts\gpt-mirror-extended-review.yaml
  sentinel: {file: contracts\gpt-mirror-extended-review.yaml, open: true, contains: ["workflow_id: gpt-mirror-extended-review","gates:","status: verified"]}
  owner: workflow
  last_verified: null
- id: facts
  path: D:\meta-intelligence-facts
  type: projection
  ssot: null
  sentinel: {file: README.md, open: true, contains: ["# 元智能事实层","只读投影副本"]}
  owner: meta-intelligence
  last_verified: null
判活必须实际 OpenRead 文件并验内容；打开失败、为空、结构不符都判死，禁止用 Test-Path 代替。
(c)
进入生成事务：由本地真源生成事实层投影、生成 CORE/SPEC、跑掩码扫描；扫描失败即阻断。git commit/push 由 Agent 执行，仍保留人工批准发布。首页分开显示“本地状态”和“外部送审状态”：投影旧→外部投影过期；push 失败→外部发布失败；两者都阻断 GPT 正式裁定，但不否定本地 State。
(d)
文件	真源位置	谁写	是否投影
CURRENT_STATE.md	无独立真源；由 generated/state/*.json 生成	生成脚本	是
DECISIONS.md	D:\Work\元智能\machine\DECISIONS.md	Agent 按已确认裁定追加	是
ISSUES.md	D:\Work\元智能\machine\ISSUES.md	Agent 维护	是
CHANGELOG.md	D:\Work\元智能\machine\CHANGELOG.md	Agent 在验证成功后追加	是

---

## 第 4 轮 · 2026-09-26 · 阶段 3 归属规则（D-004 / local scope / 控制平面 Task 台账）

**读取事故（第二次，仍是读取侧）**：脚本报 `EMPTY_REPLY`，但截图显示回答完整在屏。真因是**镜像站在对话末尾留了一个空的 assistant 占位节点**，而脚本只取最后一个节点。已改为「取最后一个非空节点」（`66ef5f1`），修完同一脚本立刻读出 2049 字全文。这与上一条虚拟化缺陷是两个独立问题。

**送达核对**：本轮禁止访问链接、凭对话内已读材料作答，故不要求回读凭证。

### 正文（逐字）

1. 类型 A：新增 D-004，不并入 D-001

裁定：新增 D-004「经验资产的质量与可复用性」。 D-001 管“资产是否可控、可追踪、不分叉”；D-004 管“经验是否提取得准、分层正确、值得复用、何时衰减”。把 A 类塞进 D-001 会把“治理”与“质量”混成垃圾桶。

D-004

statement
建立经验资产从原始想法、策略抽象、实施骨架到真实复用与衰减退出的闭环，使沉淀结果可追溯、分层正确、质量可验证，并能在后续真实任务中产生可证明的复用价值。

success_state
一条经验能完整经历：来源保留 → 候选抽取 → L2/L3 判层 → 生成/登记 → 真实任务复用 → 结果反馈 → 衰减/保留/淘汰；错误抽取、错层、无效复用都可被发现，且不会静默污染正式经验资产。

constraints
原始想法不得因抽象而丢失；不得凭模型臆测补经验；正式晋升继续遵守既有人审/验证闸门；D-004 不负责资产身份、权限、真源与分叉治理，那些仍归 D-001；不把“系统融合”问题吸进来，那些仍归 D-003。

recheck_on
L2/L3 定义变化；抽取/复用误判明显增加；衰减规则改变；经验资产格式或承载方式改变；上游引擎被替换；真实复用结果持续证明现有质量判据失效。

判据： 成功标准若在问“这条经验是否正确、有用、可复用”，归 D-004；若在问“这条资产是否唯一、可控、可追踪、权限正确”，归 D-001。

作废条件： 只有 D-001 被正式升版，明确把“经验质量与复用效果”纳入自己的独立 success_state，而且 D-004 不再有独立生命周期和指标时，才合并。

2. 类型 B：不允许伪造 demand_id: local:*，但也不强制硬挂全局 Demand

裁定：修正规则。 demand_id 只允许真实 Demand ID。系统内部建设任务改成：

YAML
scope: local
system_id: ai-growth
demand_id: null

全局任务才是：

YAML
scope: global
demand_id: D-00x

这不是折中，而是修正“所有 Task 必须挂 Demand”这个过强约束。

局部 Task 不进入任何 Demand 的 active_tasks。 单独进入 local_tasks/“系统局部建设”视图。只有它实际阻塞某个 Demand 时，才以 blocking_dependency 出现在该 Demand State 中，仍不能冒充该 Demand 的 active task。

判据： 如果任务完成与否只影响一个系统自身的结构、schema、交互流程或内部建设，而不改变任何全局 Demand 的 success_state，它就是 local。

作废条件： 一旦该任务开始改变跨系统契约、用户级能力或某个 Demand 的成功条件，就必须转为 global，并绑定真实 Demand。

3. 类型 C + 控制平面阶段任务

类型 C：不能归 local，也不能塞 D-003。 T15/T16 是“机制外扩”，已经改变适用范围。没有新的全局 Demand 前，继续留在 unresolved-migration，并暂停为 active。只有你明确决定“机制外扩本身是要实现的长期目标”时，才新建对应 Demand。

控制平面阶段 3~7：控制平面自持 Task 真源。 建：

D:\Work\元智能\machine\TASKS.yaml

只记录元智能控制平面自己执行的任务，例如阶段 3~7，全部绑定 D-003。不要塞进下游看板。

这不违反“不新增第五份可写状态真源”：它不是第二份 Current State，也不是复制其他系统 Task；它只是控制平面自己的原生执行台账。真正违规的是把下游 Task 抄一份进来形成双写。

判据： 谁实际拥有执行和完成判定，谁持有该 Task 的原生记录。控制平面改自己的 Demand/投影/迁移/生成链，就由控制平面持有。

作废条件： 未来若正式建立一个全系统唯一 Task 服务，并完成迁移、旧台账退役，则控制平面 TASKS 可并入；在那之前不跨系统借看板。

关于 13 条 unresolved 的顺序

“先不切入口，先消除 unresolved”这个顺序对。

但应用本轮裁定后，不应继续把 13 条全留 unresolved：

A 类 9 条 → 绑定 D-004

B 类 4 条 → 改为 local scope

C 类 T15/T16 → 继续 unresolved / blocked

控制平面阶段 3~7 → 写入控制平面 TASKS.yaml，绑定 D-003

最终只要仍有活动且应该属于全局目标、但无法确定 Demand 的任务，入口切换就继续阻断。

---

## 第 5 轮 · 2026-09-26 · 阶段 6~7 收口（P1~P5）

**送达核对（本文件是 `delivery_readback` 闸门的第一次真实判定）**：`verify_delivery.mjs` 对本轮回答判 **pass**，三项凭证齐 —— `FACTS-DELIVERY-d37c770b | CORE-TAIL-A223C18B | SPEC-TAIL-EB683A9C`。高智力模型在 P5 中据此认可该闸门首次真实通过。

**读取侧第三次缺陷（本轮实际踩到，值得留档）**：提取脚本连续把**上一轮**的回答当成本轮读出来（"取最长非空节点"的旧修法在新一轮更短时会抓错），随后又出现最新消息节点读到 0 字 —— 因为滚动只滚了容器、没把最新消息滚进视口。两处都已修（`66ef5f1` 之后再次修改）：改为"从末尾取第一个非空节点"，并把滚动改成"最后一条 assistant 消息 scrollIntoView + 点页面自带的跳到最新按钮"。**校验器在这两次误读中都判了 fail 并拒绝采信**，这正是它存在的意义：错的是我读，不是它答。

### 正文（逐字）

FACTS-DELIVERY-d37c770b | CORE-TAIL-A223C18B | SPEC-TAIL-EB683A9C

P1｜切默认入口

结论：现在还不能直接切；CT-05 必须补完，但不需要“跑几天”。T15/T16 不必解决业务方向，只需退出 active blocker。

切换前同时满足：

CT-05 事件覆盖通过：至少验证一次普通 Task/Decision 变化 → State → Human View；Demand 升版链路已由 CT-06 覆盖。两类都必须生成成功、回读成功、source fingerprint 一致。规范要求 Task、Demand、Decision 等关键变化后刷新 State/Human View。
GitHub
+1

T15/T16 明确冻结：继续留 unresolved-migration，但必须是非 active 状态，不得进入 D-003 active_tasks。此前 DEC-20 已规定不能伪造 Demand 归属。
GitHub

已知 State 缺口消失：尤其 P4 的真实 Experiment 已存在时，active_experiments 不能继续靠 null 冒充“没有实验”。

新首页生成、回读、旧入口兼容、回滚脚本四项全部实测通过。

切换方法：不要移动或删除旧路径。 保留现有 Home.md 路径，把它改成生成的兼容入口，内容只指向/嵌入新的 元智能/00_首页.md；Obsidian 默认打开文件改成新首页。所有现在指向 Home.md 的链接因此继续有效，旧子库页面暂时也原地保留。规范只要求 Obsidian 有一个默认 Human View，并未要求物理移动旧页面。
GitHub

切换前保存：

runtime/cutover/<build_id>/
  Home.md
  obsidian-startup-config
  cutover.json

实现一个：

cutover.ps1 -Apply
cutover.ps1 -Rollback <build_id>

-Rollback 一次恢复旧 Home.md 和默认打开配置；控制平面、State、生成物全部不删。

判据： 用户沿任何旧入口都不会遇到断链；新入口显示的 build_id/source_fingerprint 与刚回读的 State 相同；T15/T16 不再是 active blocker。

作废条件： 切换后出现旧链接失效、首页比 State 旧、生成失败仍展示正常状态，或任何 active 全局 Task 无可靠归属，立即一键 rollback。

P2｜去旧写口的顺序

顺序定为：CHANGELOG → DEMAND → DECISIONS → ISSUES。ISSUES 最后。

原因：CHANGELOG 是已发生事项的记录，迁移错误即时影响最小；DEMAND/DECISIONS 是长期语义和治理约束；ISSUES 是当前送给高智力模型的实时问题输入，如果生成时机错一轮，会直接让外部模型回答旧问题，所以必须等整条发布 freshness gate 已经实测后再撤掉它的旧写口。控制平面作为这些文件的 machine 真源、公开仓仅作投影已经由 DEC-16 定案。
GitHub

生成频率不是“每天”或“push 前二选一”，而是两层：

每次 Agent 收尾
→ refresh machine state
→ 重生成四份投影

每次准备送审
→ 无条件再生成一次
→ CORE/SPEC
→ 掩码扫描
→ freshness 校验
→ 才允许 commit/push

发布前必须重新计算当前 machine 输入指纹，并要求：

projection.source_fingerprint == current_machine_fingerprint
bundle.build_id == projection.build_id

任一不等即阻断。这样不存在“本轮 machine 已改，但拿昨天投影生成送审包”的窗口。DEC-17 已规定生成事务到 CORE/SPEC + 扫描为止，扫描失败必须阻断。
GitHub

判据： 每撤掉一个旧写口，生成器必须能从 machine 原件独立重建该文件，并通过 P3 的精确校验；否则不迁下一份。

作废条件： 某文件存在 machine 原件没有承载、而公开旧文件独有的有效事实，立即停止迁移；先把事实迁回 machine 真源，不能靠继续双写解决。

P3｜迁移期双写的机器判据

结论：machine 永远胜；公开事实层绝不反向合并。每个投影执行“源哈希 + 重渲染字节比对”。

给每个投影登记：

YAML
source: machine/ISSUES.md
source_sha256: ...
projection_sha256: ...
generator_version: ...
build_id: ...

每次 Agent 收尾以及每次 pre-push都执行：

1. 读 machine 原件，算 source_sha256
2. 在临时目录重新 render
3. 算 expected_projection_sha256
4. 读取事实层现有文件，算 actual_projection_sha256
5. 要求：
   manifest.source_sha256 == 当前源 hash
   expected_projection_sha256 == actual_projection_sha256

两个条件任一失败即 exit != 0，禁止打包和 push。

这还能区分两类错误：

source hash 已变、投影没变 → 投影陈旧

source hash 没变、实际投影 ≠ 重新 render → 事实层被手改

发现不一致时：先把事实层异常版本复制到本地 runtime/divergence/<timestamp>/ 留证，然后用 machine 真源重新生成覆盖；禁止把差异 merge 回 machine。DEC-16 已明确 machine 是语义真源、公开仓是生成投影。
GitHub

多久检查：不按时间。 每次 machine 写事务收尾一次 + 每次 pre-push 强制一次。只要发现第一个能够写真源却绕过收尾流程的程序，按 DEC-18 立即补 10 分钟 watchdog。
GitHub

判据： 四个公开文件全部能由 machine 原件重新渲染成完全相同结果；任意手改一字符，下一次检查必须稳定失败。

作废条件： 若公开仓未来被正式升格为 canonical 真源并同时撤销 machine 对应原件，才允许反转权威方向；当前架构下绝不双向同步。

P5｜送达闸门要不要现在加 manifest

结论：现在不加；等第一次出现“本轮三项凭证全部正确，但包内内容仍被证明不完整/错误”时再加。

本轮三项凭证已经实际证明：CORE 首部、CORE 尾部、SPEC 尾部都来自当前交付，因此 CT-11 的 delivery_readback 可以把本轮登记为首次真实通过。现有规则也明确三项凭证是当前正式送达判据。
GitHub
+1

现在增加“文件数 + 字节数 + SHA-256”只能覆盖一个尚未出现过的中段损坏故障模式，而第一版原则要求不因假设性风险增加维护复杂度。
GitHub

加 manifest 的触发判据： 发生一次可复现案例——三项本轮 nonce 全匹配，但模型读到的中间内容缺失、串包或与本地 bundle 不一致。届时加独立 manifest，记录两个 bundle 的字节数、SHA-256、源文件清单/数量；仍不替代三个 nonce。

作废条件： 如果发布/抓取通道以后直接提供经过验证的端到端内容哈希，并能在接收侧核验，则无需自建 manifest。

P4｜active_experiments 字段缺口

结论：现在就把 EXPERIMENTS 纳入生成输入。不是继续承认派生不出来。

理由不是“规范里有这个字段”这么简单，而是今天已经真的产生两份 Experiment。规范把 Experiment 定义为 V1 一等对象，State 明确包含“当前实验”，而现有 experiment schema 已经定义了足够的机器字段。
GitHub
+1

不要新造总表。把每份 Experiment 按已有 schema 补成可解析结构，至少：

YAML
id:
demand_id:
hypothesis:
baseline:
candidate:
status: planned|running|completed|cancelled

这些正是现有 schema 的 required 字段。
GitHub

生成规则：

status = planned / running
→ 进入该 Demand.active_experiments

status = completed / cancelled
→ 不进入 active_experiments
→ 结果可进入 recent_changes / Archive

因此没有活动实验时输出：

JSON
"active_experiments": []

而不是 null。null 表示“生成器不知道”，[] 才表示“机器确认目前没有活动实验”。

判据： 只要存在一个非终止 Experiment，或者 Experiment 的结果会改变 strategy / next_step / Decision，就必须成为结构化 State 输入。当前已经满足。

作废条件： 如果将来 Experiment 不再是一等运行对象，且其生命周期被另一正式对象完全取代，才移出 State 输入；在当前 V1 规范下不能省略。
