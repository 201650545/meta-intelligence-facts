# 治理范围与可治理清单（按 2026-09-24 政策：只管用户侧）

- 生成时间：2026-09-24T10:42:28+08:00 ｜ 输入 8663 条 ｜ probe_self_test：**pass**

| 项 | 值 |
|---|---|
| 在范围内（用户侧） | **832**（9.6%） |
| 退出范围（程序自带／未声明） | 7831 |
| 范围内唯一技能 id | 535 |
| 范围内同名多份簇 | 71 |
| **范围内内容已分叉** | **31** |

## 判据分布（复核用）

| 判据 | 文件数 |
|---|---|
| 未声明(默认) | 7762 |
| 声明的在范围根 | 580 |
| 工具代装(.arkcli-managed-skills.json) | 240 |
| 出厂自带(.loomy-skill.json:bundled) | 69 |
| 用户侧(.loomy-skill.json:learned) | 7 |
| 自产前缀(loomy-learned-) | 4 |
| 用户侧(.loomy-skill.json:package) | 1 |

## 范围边界：按容器目录（复核线画在哪）

| 容器目录 | 在范围 | 退出范围 | 首个判据 |
|---|---|---|---|
| `C:\Users\郭永涛\.codebuddy\skills-marketplace\skills` | 0 | 295 | 未声明(默认) |
| `D:\OfficeAce\office-claw-skills` | 277 | 0 | 声明的在范围根 |
| `C:\Users\郭永涛\.workbuddy-ai\skills-marketplace\skills` | 0 | 268 | 未声明(默认) |
| `C:\Users\郭永涛\.workbuddy\skills-marketplace\skills` | 0 | 268 | 未声明(默认) |
| `D:\Open Design\resources\open-design\plugins\_official\examples` | 0 | 182 | 未声明(默认) |
| `D:\Open Design\resources\open-design\skills` | 0 | 155 | 未声明(默认) |
| `C:\Users\郭永涛\.workbuddy\plugins\marketplaces\codebuddy-plugins-official\external_plugins\scientific-skills` | 0 | 138 | 未声明(默认) |
| `C:\Users\郭永涛\.workbuddy-ai\plugins\marketplaces\codebuddy-plugins-official\external_plugins\scientific-skills` | 0 | 138 | 未声明(默认) |
| `C:\Users\郭永涛\.codebuddy\plugins\marketplaces\codebuddy-plugins-official\external_plugins\scientific-skills` | 0 | 138 | 未声明(默认) |
| `D:\Open Design\resources\open-design\design-templates` | 0 | 109 | 未声明(默认) |
| `C:\Users\郭永涛\.qclaw\skills` | 0 | 107 | 未声明(默认) |
| `C:\Users\郭永涛\.openclaw-autoclaw\skills\autoclaw-design-capability\审美相关skill\skills` | 0 | 106 | 未声明(默认) |
| `C:\Users\郭永涛\.openclaw-autoclaw\skills\autoclaw-design-capability_noqa\审美相关skill\skills` | 0 | 106 | 未声明(默认) |
| `C:\Users\郭永涛\.openclaw-autoclaw\agents\auto-designer\workspace\审美相关skill\skills` | 0 | 106 | 未声明(默认) |
| `C:\Users\郭永涛\.openclaw-autoclaw\skills` | 0 | 106 | 未声明(默认) |
| `C:\Users\郭永涛\.openclaw-autoclaw\skills\autoclaw-design-capability\审美相关skill\design-skeletons` | 0 | 84 | 未声明(默认) |
| `C:\Users\郭永涛\.openclaw-autoclaw\skills\autoclaw-design-capability_noqa\审美相关skill\design-skeletons` | 0 | 84 | 未声明(默认) |
| `C:\Users\郭永涛\.openclaw-autoclaw\agents\auto-designer\workspace\审美相关skill\design-skeletons` | 0 | 84 | 未声明(默认) |
| `C:\Users\Public\Loomy\c3773183a592\opencode\skills` | 11 | 69 | 出厂自带(.loomy-skill.json:bundled) |
| `C:\Users\郭永涛\.config\alma\skills` | 0 | 73 | 未声明(默认) |
| `C:\Users\郭永涛\.agents\skills` | 69 | 0 | 声明的在范围根 |
| `D:\xunfei\Loomy\resources\opencode-home-template\skills` | 0 | 69 | 未声明(默认) |
| `C:\Users\郭永涛\.workbuddy\connectors-marketplace\connectors\linkfox\skills` | 0 | 66 | 未声明(默认) |
| `C:\Users\郭永涛\.workbuddy-ai\connectors-marketplace\connectors\linkfox-product-selection\skills` | 0 | 66 | 未声明(默认) |
| `C:\Users\郭永涛\skills` | 65 | 0 | 声明的在范围根 |
| `D:\02-AI工具\autoclaw\resources\skills` | 0 | 62 | 未声明(默认) |
| `D:\02-AI工具\autoclaw\resources\gateway\openclaw\skills` | 0 | 52 | 未声明(默认) |
| `D:\qclaw\v0.2.37.630\resources\openclaw\config\skills` | 0 | 50 | 未声明(默认) |
| `C:\Users\郭永涛\.workbuddy\skills` | 0 | 50 | 未声明(默认) |
| `C:\Users\郭永涛\.openclaw-autoclaw\agents\auto-legal\workspace\.openclaw\template-backups\v30\skills` | 0 | 48 | 未声明(默认) |

## 可治理清单 TOP30（范围内、同名多份且内容不一致）

| skill_id | 范围内份数 | 范围内变体 | 全机总份数 |
|---|---|---|---|
| `skill-creator` | 4 | 3 | 76 |
| `Copywriting` | 3 | 3 | 12 |
| `arkcli-shared` | 11 | 2 | 11 |
| `arkcli-deploy` | 11 | 2 | 11 |
| `arkcli-doctor` | 11 | 2 | 11 |
| `arkcli-connect` | 11 | 2 | 11 |
| `arkcli-helper` | 11 | 2 | 11 |
| `arkcli-gen` | 11 | 2 | 11 |
| `arkcli-plans` | 11 | 2 | 11 |
| `arkcli-config` | 11 | 2 | 11 |
| `khazix-writer` | 4 | 2 | 13 |
| `frontend-design` | 3 | 2 | 33 |
| `apple-notes` | 3 | 2 | 10 |
| `apple-reminders` | 3 | 2 | 10 |
| `agentmail` | 3 | 2 | 9 |
| `summarize` | 2 | 2 | 9 |
| `aihot` | 2 | 2 | 12 |
| `inference-sh-cli` | 2 | 2 | 2 |
| `kdocs` | 2 | 2 | 12 |
| `gog` | 2 | 2 | 9 |
| `nano-banana-pro` | 2 | 2 | 9 |
| `model-usage` | 2 | 2 | 6 |
| `humanizer` | 2 | 2 | 10 |
| `macos-computer-use` | 2 | 2 | 2 |
| `obsidian` | 2 | 2 | 9 |
| `blackbox` | 2 | 2 | 2 |
| `social-content` | 2 | 2 | 7 |
| `multi-search-engine` | 2 | 2 | 5 |
| `skill-vetter` | 2 | 2 | 11 |
| `frontend-dev` | 2 | 2 | 11 |

> 全量口径的 907 分叉簇含各产品自带版本差异；本表只列范围内的。逐条判据见 `skill-census-05-scope-decisions.csv`。
