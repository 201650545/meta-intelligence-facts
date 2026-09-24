# 元智能事实层 · meta-intelligence-facts

> 本仓是**本地执行模型与高智力模型之间的共享事实层**。
> 目标：另一个模型刚加入，只读少量核心文件，就能明白"这个需求是什么、系统做到哪、发生了什么、还有什么问题、下一步该讨论什么"。
> **不要靠 git commit 历史推测系统变化** —— commit 是执行历史，`CURRENT_STATE.md` 与 `REPORT_TO_STRATEGIST.md` 才是事实入口。

## 分工约定

| 位置 | 职责 |
|---|---|
| 本地文件系统 | 执行。结构由执行模型自管，不为可读性设计 |
| **本仓（GitHub）** | **同步事实**。AI 与 AI 之间的共享层 |
| 高智力模型 | 复杂判断、架构、策略 |
| Obsidian | 面向人的 Human View |

协作链路固定：需求变化 → 本地执行 → 验证 → 更新本仓 → 高智力模型读本仓 → 给判断 → 落实到本地 → 再验证 → 再更新本仓。

## 抓取失败的备用入口（重要）

若你的网页抓取通道对本仓返回 `Cache miss`、读不到目录，或**无法处理中文路径**，请只读下面两个文件。它们是根级、纯 ASCII 文件名的合并副本，两个加起来覆盖全部阅读清单，无需再导航目录树：

| 文件 | 内容 | 大小 |
|---|---|---|
| `ALL_CORE_DOCS.md` | 治理层 7 个文件（README / REPORT / DEMAND / CURRENT_STATE / DECISIONS / ISSUES / LOCAL_DRAFT_FUSION_PLAN）+ 作答要求 | 约 40 KB |
| `ALL_SPEC_DOCS.md` | 规范层 55 个文件（`30_元智能/` 整包 43 个 + 下游契约与方案 + 上游 SOP/技能库/中枢配置/实测结论 + REDACTION） | 约 200 KB |

> 大小只写约数：`ALL_CORE_DOCS.md` 内嵌了本文件，写死字节数会自指（改数字 → 副本变大 → 数字又不对）。
> 两个副本由脚本从本仓**已掩码**文件拼接生成，改任一源文件后必须重新生成。

raw 直链（把 `<F>` 换成上面任一文件名）：

```
https://raw.githubusercontent.com/201650545/meta-intelligence-facts/main/<F>
```

也可用会 302 跳转到 raw 的等价形式：`https://github.com/201650545/meta-intelligence-facts/raw/main/<F>`

> 本仓元数据在删仓重建后会短暂显示 `size=0`，那是 GitHub 统计滞后，**不代表仓库为空**：匿名 `contents` 与 `git/trees` 接口均正常返回，`git/trees/main?recursive=1` 报 97 个 blob、`truncated=false`。判断本仓是否为空请看 tree 接口，不要看 `size`。


## 阅读顺序（给高智力模型）

1. **`REPORT_TO_STRATEGIST.md`** ← 本轮要你看的那份，先读它
2. `DEMAND.md` — 长期需求与最近变化
3. `CURRENT_STATE.md` — 三套系统现在各自到哪
4. `ISSUES.md` — 需要你判断的问题（带编号，回复编号即可）
5. `DECISIONS.md` — 已定事项，**不必重新讨论**
6. `CHANGELOG.md` — 本阶段实际改了什么、为什么、结果如何

## 被融合的三套系统在哪

| 目录 | 是什么 | 状态 |
|---|---|---|
| `10_AI自成长引擎/` | 上游：经验分层沉淀 L1/L2/L3、技能库、五步安装闸门、快照与周报 | 在跑 |
| `20_自适应工作流引擎/` | 下游：契约（声明态真源）+ 只读探针 + drift 投影 + 自愈分级 | A1 收口，A2 待办 |
| `30_元智能/` | 新到的规范包：以 Demand 为中心的元智能 V1 实施规范，**尚未落地** | 待评审 |

## 本轮请求

**请给出把这三套融合成一个系统的方案。** 具体要回答的问题在 `ISSUES.md`，背景与已定约束在 `DECISIONS.md`。

## 两点知情

- **本仓内容已做类型化掩码**：内部服务域名、账号卡标识、本机 profile 令牌、本地端口被替换为 `<MIRROR_HOST>`、`CARD-nn`、`LOCAL_BROWSER_PROFILE` 等占位符。同一原值在全仓恒映射到同一占位符，跨文档可对照；**映射表只在本地，不在本仓**。详见 `REDACTION.md`。
- **原始文件未被修改**。本仓是三套系统的**只读投影副本**，唯一真源仍在本地。改动请勿直接写在这里。
