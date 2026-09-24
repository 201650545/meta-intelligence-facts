# P0.5 死链清单（只读枚举，未删除任何东西）

- 生成时间：2026-09-24T11:16:33+08:00 ｜ 共 **946** 条 ｜ probe_self_test：**pass**（与普查器逐宿主一致）
- 明细：`skill-census-07-broken-links.csv`

## 一、为什么必须先分性，再谈清理

| 类型 | 条数 | 含义 | 正确处置 |
|---|---|---|---|
| ORPHAN 源已删 | **946** | 目标父目录仍在，只是那个技能目录本身被删了 | 可清 —— 链接已无意义 |
| UNREACHABLE 路径不可达 | **0** | 连目标父目录都不在（盘符变了／用户目录搬走／在别的机器） | **不能清** —— 清了就把「源在别处」这个事实也抹掉了 |
| SUSPECT 探针矛盾 | 0 | 活性探针说断但目标存在 | 逐条人工看 |

> 这两类**处置方向相反**，所以不能用一句「删掉所有断链」解决。

## 一点五、死链指向哪儿（决定根因）

| 目标父目录 | 条数 | 该目录现在存在吗 |
|---|---|---|
| `C:\Users\郭永涛\.agents\skills` | 946 | 存在（源目录还在，只是里面的技能被删了） |

**根因判读**：全部死链的目标父目录只有 1 个，且该目录本身仍存在 —— 说明不是盘符迁移、也不是整片路径失效，而是**从这一个 hub 里删掉了 149 个技能目录，但散在 9 个宿主里的 946 条链接没有回收**。清理因此是单一动作，不需要逐宿主分别判断。

被删技能按家族归类（按技能名去重，共 149 个）：

| 家族 | 被删技能数 |
|---|---|
| 其他（Anthropic 系／社区合集技能名） | 132 |
| lark-*（飞书公有云） | 17 |

## 二、逐宿主

| host | 链接数 | 断链 | 普查对照 | 备注 |
|---|---|---|---|---|
| `C:\Users\郭永涛\.qoder\skills` | 187 | 149 | 149 | ok |
| `C:\Users\郭永涛\.kiro\skills` | 190 | 149 | 149 | ok |
| `C:\Users\郭永涛\.qwen\skills` | 190 | 149 | 149 | ok |
| `C:\Users\郭永涛\.trae\skills` | 190 | 149 | 149 | ok |
| `C:\Users\郭永涛\.iflow\skills` | 186 | 148 | 148 | ok |
| `C:\Users\郭永涛\.codebuddy\skills` | 186 | 148 | 148 | ok |
| `C:\Users\郭永涛\.trae-cn\skills` | 36 | 19 | 19 | ok |
| `C:\Users\郭永涛\.qoder-cn\skills` | 28 | 18 | 18 | ok |
| `C:\Users\郭永涛\.claude\skills` | 31 | 17 | 17 | ok |
| `C:\Users\郭永涛\.cc-switch\skills` | 0 | 0 | 0 | ok |
| `C:\Users\郭永涛\.workbuddy\skills` | 0 | 0 | 0 | ok |
| `C:\Users\郭永涛\.workbuddy-ai\skills` | 0 | 0 | 0 | ok |
| `C:\Users\郭永涛\.config\agents\skills` | 0 | 0 | 0 | ok |
| `C:\Users\郭永涛\.config\opencode\skills` | 0 | 0 | 0 | ok |
| `C:\Users\郭永涛\.qoderworkcn\skills` | 0 | 0 | 0 | ok |
| `C:\Users\郭永涛\.trae-local\skills` | 0 | 0 | 0 | host_not_found |
| `C:\Users\郭永涛\.codex\skills` | 0 | 0 | 0 | ok |
| `C:\Users\郭永涛\.agents\skills` | 0 | 0 | 0 | ok |
| `C:\Users\郭永涛\.box-agent\skills` | 0 | 0 | 0 | ok |

## 三、清理动作的安全要求（执行前必读）

1. **禁止** `Remove-Item -Recurse`：可能顺着链接删进目标内容。
2. 只允许 `cmd /c rmdir <link>`（不带 /s）语义 —— 删链接本身，不碰目标。
3. 删除前逐条再验一次：该路径确实具 ReparsePoint 属性、且目标确实不可达。
4. 先备份清单（本 CSV 即清单），并留一份删除前各宿主目录快照；回滚 = 按清单重建链接，而不是恢复目标。
5. 只对 ORPHAN 类动手；UNREACHABLE 类先查清源在哪儿。

## 四、待你拍板

- 是否先把 UNREACHABLE 的 0 条查清来源（可能是某次盘迁移遗留，见记忆里的目录搬迁线索）
- 还是先只对 ORPHAN 的 946 条出 dry-run 删除脚本
