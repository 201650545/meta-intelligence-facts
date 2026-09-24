# 技能普查体检摘要（P0 只读）

- 探测时间：2026-09-24T10:29:41+08:00
- 配置：`D:\Work\AI自成长引擎\技能库\_中枢\audit.config.yaml`
- probe_self_test：**pass**（枚举 / 分类 / 哈希 / 断链 四类判据均命中已知样本）
- 访问目录数：211954

## 一、总量与分类

| 项 | 值 |
|---|---|
| SKILL.md 总份数 | **8663** |
| A 程序内置／市场／插件目录（只登记不碰） | 6127（其中 77 份由所有权标记判定） |
| B 其余待判（第三方合集＋你的真源） | 638 |
| C 宿主配置目录内的实体副本（重复问题主体） | 1898 |
| 唯一技能名（按 frontmatter name） | 2853 |
| 重名技能名 | 1660 |
| **内容已分叉的重名簇** | **907** |
| 副本完全一致的重名簇 | 753 |
| 受检链接层宿主 | 18 |
| **断链** | **946** |
| 真源目录下 SKILL.md | 1 |
| 身份键取自 frontmatter 的 name 字段 | 8548 ／ 8663（缺失率 0.0133） |
| 目录名与 name 不一致（改名副本） | 951 |
| 已计算哈希的文件数 | 7470 |

## 二、偏差（drift）

| condition | level | observed | action |
|---|---|---|---|
| link_health.broken_total | break | 断链 946 条 ≥ 阈值 200 | circuit_break |
| duplicate.divergent_clusters | break | 内容已分叉的重名簇 907 个 ≥ 阈值 150 | circuit_break |
| true_source.present | info | 真源目录下 SKILL.md 共 1 份 | none |

## 三、分叉 TOP20（副本内容已不一致的重名技能）

| skill | 份数 | 不同哈希数 | 状态 |
|---|---|---|---|
| `skill-creator` | 76 | 25 | DIVERGENT |
| `pdf` | 52 | 22 | DIVERGENT |
| `docx` | 51 | 27 | DIVERGENT |
| `pptx` | 48 | 22 | DIVERGENT |
| `xlsx` | 47 | 19 | DIVERGENT |
| `frontend-design` | 33 | 12 | DIVERGENT |
| `ui-ux-pro-max` | 31 | 10 | DIVERGENT |
| `cloudbase-agent` | 30 | 10 | DIVERGENT |
| `TRAE-computer-use-ptc` | 25 | 7 | DIVERGENT |
| `agent-browser` | 22 | 7 | DIVERGENT |
| `find-skills` | 21 | 7 | DIVERGENT |
| `canvas-design` | 20 | 7 | DIVERGENT |
| `wechat-article-search` | 19 | 5 | DIVERGENT |
| `cloudbase-agent-python` | 19 | 5 | DIVERGENT |
| `lucide-icons` | 17 | 2 | DIVERGENT |
| `brand-guidelines` | 17 | 7 | DIVERGENT |
| `neodata-financial-search` | 16 | 10 | DIVERGENT |
| `doc-writing-guide` | 14 | 3 | DIVERGENT |
| `lark-drive` | 14 | 10 | DIVERGENT |
| `lark-base` | 14 | 11 | DIVERGENT |

## 四、链接层健康

| host | entities（实体） | links_alive（活链接） | broken（断链） |
|---|---|---|---|
| `C:\Users\郭永涛\.qoder\skills` | 25 | 38 | 149 |
| `C:\Users\郭永涛\.kiro\skills` | 25 | 41 | 149 |
| `C:\Users\郭永涛\.qwen\skills` | 25 | 41 | 149 |
| `C:\Users\郭永涛\.trae\skills` | 25 | 41 | 149 |
| `C:\Users\郭永涛\.iflow\skills` | 25 | 38 | 148 |
| `C:\Users\郭永涛\.codebuddy\skills` | 26 | 38 | 148 |
| `C:\Users\郭永涛\.trae-cn\skills` | 39 | 17 | 19 |
| `C:\Users\郭永涛\.qoder-cn\skills` | 0 | 10 | 18 |
| `C:\Users\郭永涛\.claude\skills` | 6 | 14 | 17 |
| `C:\Users\郭永涛\.cc-switch\skills` | 20 | 0 | 0 |
| `C:\Users\郭永涛\.workbuddy\skills` | 55 | 0 | 0 |
| `C:\Users\郭永涛\.workbuddy-ai\skills` | 26 | 0 | 0 |
| `C:\Users\郭永涛\.config\agents\skills` | 26 | 0 | 0 |
| `C:\Users\郭永涛\.config\opencode\skills` | 25 | 0 | 0 |
| `C:\Users\郭永涛\.qoderworkcn\skills` | 46 | 0 | 0 |
| `C:\Users\郭永涛\.trae-local\skills` | 0 | 0 | 0 |
| `C:\Users\郭永涛\.codex\skills` | 2 | 0 | 0 |
| `C:\Users\郭永涛\.agents\skills` | 79 | 0 | 0 |
| `C:\Users\郭永涛\.box-agent\skills` | 28 | 0 | 0 |

---

**产物由脚本生成，禁止手改。** 退出码：0=无 break ／ 2=有 break（需人工介入）／ 3=自检失败不可采信。

本次 summary：info=1 warn=0 break=2 silent_risk=0
