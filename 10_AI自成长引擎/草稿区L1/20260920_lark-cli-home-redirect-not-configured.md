# Loomy shell 的 HOME/APPDATA 重定向会让 lark-cli 读不到用户配置，调用前须临时切换

- **类型**：workaround
- **触发信号**：lark-cli 报 "not configured" / `config init --new` 反复生成新 user_code 且轮询超时，但用户确认本机 CLI 早已配置好；或 npm 全局包装到了 `D:\xunfei\Loomy\resources\node-runtime`、`C:\Users\Public\Loomy\...\AppData\Roaming\npm` 等沙箱前缀
- **结论与正解**：Agent shell 的 HOME/USERPROFILE/APPDATA 被重定向到 `C:\Users\Public\Loomy\<session>\`。调用前在同一命令内临时设 `$env:HOME`/`$env:USERPROFILE`（涉及 npm 时还有 `$env:APPDATA`）为真实用户目录 `C:\Users\郭永涛`，用完在 finally 恢复。用户有效配置在 `C:\Users\郭永涛\.lark-cli\config.json`（app cli_a933ead8cdf85ccc）；首选 CLI 为 npm 版 `C:\Users\郭永涛\AppData\Roaming\npm\lark-cli.cmd`；升级该 CLI 必须显式 `--prefix "C:\Users\郭永涛\AppData\Roaming\npm"`，否则会装进沙箱前缀
- **错误样本**：直接 `lark-cli config init --new` → 反复超时（配置其实一直存在，只是读不到）；`npm install -g @larksuite/cli@1.0.96` 未指定 --prefix → 装进 Loomy node-runtime 前缀，用户目录版本纹丝不动
- **适用范围**：全局 Windows（Loomy/Raccoon 环境）
- **记录时间**：2026-09-20

---

> **relates_to（撞车检查补记，2026-09-21）**：既有真源 `context/lark-cli-home-redirect.md`（Loomy memory）已覆盖同一现象（多套 lark-cli、HOME/APPDATA 被重定向、npm 前缀歪）。
> 本条的**增量**是：① 有效配置具体路径 `C:\Users\郭永涛\.lark-cli\config.json`（app `cli_a933ead8cdf85ccc`）；② 首选 CLI 完整路径 `…\AppData\Roaming\npm\lark-cli.cmd`；③ 升级必须显式 `--prefix "C:\Users\郭永涛\AppData\Roaming\npm"`，否则装进沙箱前缀而用户目录版本纹丝不动；④ 误报特征 `config init --new` 反复生成新 user_code 并轮询超时（配置其实一直在，只是读不到）。
> **处置**：走**增补**——提纯时并入既有真源，不与本条平行并存。依据 `docs\03-方案构想.md` §2.2 撞车检查条。
