# Obsidian UI 安装说明（由本地执行模型完成）

本目录提供 V1 的基础视觉资产。

本地执行模型负责：

1. 将 `meta-intelligence.css` 放入目标 Vault 的 `.obsidian/snippets/`。
2. 在 Obsidian 中启用该 CSS snippet；如果无法自动启用，只把这一项作为一次性人工操作告诉用户。
3. Human View 页面可使用以下 CSS class：
   - `meta-dashboard`
   - `meta-kpi-grid`
   - `meta-kpi`
   - `meta-now-next`
   - `meta-muted`
4. 不为了视觉效果引入大量第三方插件。
5. Mermaid 与 Markdown 表格优先使用 Obsidian 原生能力。
6. 只有明确能降低认知成本时，才评估 Dataview、Buttons 等附加插件。

视觉层失败时，不影响机器层运行。
