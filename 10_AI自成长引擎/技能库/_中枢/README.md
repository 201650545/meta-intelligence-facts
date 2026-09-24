---
类型: 工具说明 / 中枢入口
tags:
  - AI自成长引擎
  - 技能库
  - 技能治理
更新时间: 2026-09-24
状态: P0 已实现 · 只读 · 无任何写操作能力
---

# 技能中枢 · P0 只读体检器

> **一句话**：回答"这台机器上到底有哪些 skill、哪些是我的、哪些已经悄悄分叉、哪些链接是死的"——**只读，不改任何东西**。
>
> 上位方案：[[../../docs/04-方案_技能统一治理与浏览器能力域_20260924|04-方案 技能统一治理与浏览器能力域]]
> 本目录位置**待裁定**（方案 §六 决策 **S1**，推荐 B＝留在 `技能库\_中枢\`）。若改判独立成仓，整目录原样搬走即可，产物无状态。

## 一、这个目录放什么

| 文件 | 作用 | 谁能改 |
|---|---|---|
| `audit.config.yaml` | **声明态真源**：扫描根、A/B/C 分类判据、链接层宿主清单、自检哨兵、阈值、可治理面口径 | 人工改（改前读 §四） |
| `audit.config.smoke.yaml` | 冒烟配置：只验管道，不出结论 | 人工改 |
| `scripts\lib_contract.ps1` | **配置解析器与访问器的唯一实现**，两个脚本 dot-source 共用 | 人工改 |
| `scripts\audit_skill_census.ps1` | 体检器本体：枚举 → 分类 → 哈希 → 断链（PowerShell 5.1） | 人工改 |
| `scripts\project_governance_surface.ps1` | 投影器：按 `scope` 判范围 → 切「范围内可治理清单」，不重新扫盘 | 人工改 |
| `scripts\enumerate_broken_links.ps1` | **P0.5 死链枚举（只读）**：走 `dir /AL` 这条独立通道取回链接目标，并与普查器逐宿主硬比对 | 人工改 |
| `runtime\` | **产物，只由脚本写，禁止手改**；文件名一律带 `$Prefix` | 脚本 |

> **为什么有 `lib_contract.ps1`**：本体系的全部目的就是消灭"两份全文副本各自漂移"。若两个脚本各存一份 YAML 解析器，工具本身就成了它要治理的对象。改解析行为只改这一处。
>
> 命名 `_中枢` 前缀下划线，表示**它不是 skill**（与 `草稿区\_快照\` 同口径）。`技能库\README.md` §三 约定该目录下同级只放 `<skill-id>\`，本目录属例外，裁定权在方案 S1。

## 二、用法（顺序不能反）

```powershell
# 1) 冒烟：证明探针本身没坏，期望 EXIT=0
powershell -ExecutionPolicy Bypass -File scripts\audit_skill_census.ps1 `
  -Config audit.config.smoke.yaml

# 2) 全量：出报表，当前规模下期望 EXIT=2（断链与分叉必然越线）
powershell -ExecutionPolicy Bypass -File scripts\audit_skill_census.ps1

# 3) 投影：切可治理面（读第 2 步的 CSV，几秒完成）
powershell -ExecutionPolicy Bypass -File scripts\project_governance_surface.ps1 -Prefix skill-census

# 4) P0.5 死链枚举（只读，出清单与根因，不删任何东西）
powershell -ExecutionPolicy Bypass -File scripts\enumerate_broken_links.ps1 -Prefix skill-census
```

> 退出码含义：`0` 无 break ／ `2` 有 break 需人工介入 ／ `3` **自检失败，结果不可采信**。
> 第 4 步的 2 表示存在"须先定性再清理"的条目，不是出错。

产物（均带 `$Prefix`，冒烟与全量互不覆盖）：

| 文件 | 内容 |
|---|---|
| `<p>.runtime.json` | 全量事实：总数、A/B/C、身份键解析率、各根命中 |
| `<p>.drift.json` | 需人工介入项 + 断链逐条明细 |
| `<p>-00-summary.md` | 人读摘要 |
| `<p>-01-census-by-root.csv` | 每份 SKILL.md 一行：路径／技能 id／目录名／类／是否真源 |
| `<p>-02-duplicate-divergence.csv` | 每个重名簇：份数、内容变体数、DIVERGENT／IDENTICAL |
| `<p>-03-link-health.csv` | 每宿主：实体数、活链接、断链 |
| `<p>-04-governance-surface.{csv,json,md}` | **可治理清单**（第 3 步产物） |

## 三、铁律与退出码

照搬 `D:\Work\自适应工作流引擎\probes\probe_gpt_mirror.ps1` 的同一套纪律，不另起：

1. **只读** —— 只枚举目录、只读文件哈希。脚本无任何写/删/移动被检对象的能力，产物只落在 `runtime\`
2. **零字面量** —— 扫描根、正则、阈值、哨兵全从配置读；脚本内不得出现硬编码外部常量
3. **产物只由脚本写**，禁止手改
4. **`probe_self_test` 每次必记** —— 区分"机器真变了"与"探针自己坏了"
5. **silent-risk 一律按 break**，校验点不成立就不许产出结论

退出码：`0`=无 break ／ `2`=有 break（需人工介入）／ `3`=**自检失败，本次结果不可采信**（不要当事实用）。

## 四、改配置前必须知道的三条实测坑

都是 2026-09-24 首跑当场踩出、并被自检抓到的（这正是 self_test 存在的意义）：

1. **`Test-Path` 对断开的 junction 返回 `True`**。各宿主的 `skills\<name>` 实测是 **JUNCTION 而非 symlink**，而 `Test-Path` 和 `[IO.Directory]::Exists` 都只查链接自身、不校验目标 → 拿它判活会**恒判健康**，断链数报 0。现改用「必须穿过链接才能完成」的活性探针 `[IO.Directory]::GetFiles(dir, 永不匹配的窄模式)`：目标可打开就返回空数组（不读内容，快），目标缺失则抛异常。
2. **`Get-ChildItem` 对断链只抛非终止错误**，`try/catch` 接不住，脚本会继续往下跑并产出一个"子项=0"的假结论。凡是要靠异常判定的地方，一律用 .NET 方法或显式 `-ErrorAction Stop`。
3. **扫描不跟随 reparse point**（脚本铁律 6）。所以经 junction 才能到达的 skill **不计入普查总数**，这一点与 `find` 默认行为一致，可与首轮 bash 数据对账（实测差 12/8582 = 0.14%，来自深度与排除规则细节，不影响结论）。
4. **技能身份键必须取 frontmatter 的 `name:`，不能用目录名**。目录名会同时犯两类错：把 `...\connectors\<名字>\skills\` 这类**包装目录**虚增成假簇（首轮实测聚出"`skills` 193 份／167 种内容"），又**认不出改名副本**（Anthropic `docx` → Loomy `loomy-docx` 同内容不同名）。脚本另带 `self_test.max_frontmatter_missing_rate`：一旦解析大面积失败、身份键静默退回目录名，结果看着照样合理但含义已变 → exit 3。实测缺失率 1.34%。
5. **原始分叉数会严重误导，看投影器那份**。907 个分叉簇里 76.3% 是各产品自带的版本差异（产品更新自管），`project_governance_surface.ps1` 切出的 **215** 才是可治理面。引用"分叉多少"时必须说清是哪个口径。
6. **冒烟与全量曾共用固定 CSV 名，一次冒烟直接毁掉全量三份报表**。现所有产物名一律带 `$Prefix`。改脚本时不要再写死文件名。
7. **PowerShell 计数陷阱**：`@(管道 | Measure-Object).Count` 数的是那个 Measure-Object 对象本身，**恒为 1**。要写 `@(管道).Count`。2026-09-24 死链枚举器首跑就报出"ORPHAN 1／UNREACHABLE 1／SUSPECT 1"而总数 946 —— 因为这三个数都是 1。现已在脚本里加合计校验（三者之和 ≠ 总数即 exit 3），这类统计错以后会被自己拦住。

## 五、哨兵会腐化

`self_test.sentinel_broken_link` 写的是某个**当前已知断开**的链接。一旦你按报表把断链清理掉，该哨兵会失效 → 体检器将 exit 3 报"探针坏了"，而实际是**环境变好了**。

处理方式：**清理断链后同步更换哨兵路径**，或临时把 `min_broken_links` 与哨兵一并下调。哨兵旁已标 `sentinel_source` 记录取证日期与方法。

## 六、与既有闸门的关系

- 本工具属于方案 §八 的 **P0**，验收口径是"只读 + 数字可复现 + 零写入被检对象"，因此**不需要安装点头**
- P1（registry）、P2（清断链与分发器）、P3（浏览器能力域）均**尚未实现**，且各自要求逐次授权
- 报表结论若要转成动作，走 `技能库\README.md` §四 五步闸门，不绕开
