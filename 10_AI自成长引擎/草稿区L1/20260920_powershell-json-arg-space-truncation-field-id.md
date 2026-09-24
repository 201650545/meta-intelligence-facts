# PowerShell 5.1 向原生 CLI 传 JSON 时字段名含空格会截断参数，应改用字段 ID 作键

- **类型**：pitfall
- **触发信号**：`lark-cli base +record-upsert` 报 `positional arguments are not supported (got [...])`，且收到的片段恰好从某字段名的空格处断开；或该次调用 stdout 为空（更新实际未生效）
- **结论与正解**：双保险——① JSON 先 `$json.Replace('"','\"')` 再传给 `--json`；② 键一律用字段 ID（`+field-list` 获取）而非含空格（如「除一科一辅作业本 小计」）或竖线（「已|未收费」）的字段名；写后必须 `+record-get` 复核是否真的写入
- **错误样本**：`--json '{"年级":"三年级",...,"除一科一辅作业本 小计":226,...}'`（未转义引号 + 字段名含空格）→ CLI 实际收到 `小计\":226,...}` 碎片并报 positional arguments 错误
- **适用范围**：全局 Windows（PowerShell 5.1 + lark-cli base 写操作）
- **记录时间**：2026-09-20

---

> **relates_to（撞车检查补记，2026-09-21）**：既有真源 `context/feishu-bitable-field-id.md`（Loomy memory）记的就是本条核心结论「含空格字段名截断 JSON → 改用字段 ID」。
> 本条的**增量**是：① 引号转义 `$json.Replace('"','\"')` 双保险；② **竖线**字段名（如「已|未收费」）同样会出事，不只空格；③ 写后必须 `+record-get` 复核是否真的写入；④ 报错特征 `positional arguments are not supported`，且可能 **stdout 为空但更新未生效**（静默失败）。
> **处置**：走**增补**——提纯时并入既有真源，**不要与本条平行长期并存**（否则同一知识两份、检索分裂）。本标注依据 `docs\03-方案构想.md` §2.2 撞车检查条。
