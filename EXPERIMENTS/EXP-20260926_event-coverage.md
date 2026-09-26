# EXP-20260926_event-coverage

exp_id: EXP-20260926_event-coverage
demand_id: D-003
status: completed

- **hypothesis**：State 不只是"重算一遍"，而是能回答**这次是哪一类输入变了**；若归因精确，则 DEC-22 要求的"普通 Task 与 Decision 变化也要传播"才算成立。
- **baseline**：CT-06 只验证过 Demand 升版这一类事件；此前 State 里没有任何字段记录"变化来自哪里"，重生成后首页与上一版的差异只能靠人眼比对。
- **candidate**：State 新增 `input_snapshot`（每个输入文件的哈希）、`changed_inputs`（与上一份快照比对后变化的输入名）、`change_kind`（归类为 demand / task / decision / change_log / experiment / component_health）。
- **metric**：① 只改 `machine/TASKS.yaml` → `changed_inputs` 必须恰好等于 `["tasks/TASKS.yaml"]`、`change_kind == ["task"]`，且活动任务数与 `next_step` 随之变化；② 只改事实层 `DECISIONS.md` → `changed_inputs == ["facts/DECISIONS.md"]`、`kind == ["decision"]`，且新决策出现在 `recent_changes`；③ 两次都必须 `readback_ok=true`；④ 归因不得出现"多报"（把没改的文件也算进去）。
- **observation_window**：两类事件各一次即刻可判；跨事件的复合变化（同一次改多个文件）留待 CT-13 与真实运行中观察。
- **risk**：`input_snapshot` 让 State 文件变大；哈希比对依赖文件字节稳定，CRLF/LF 漂移会造成假变化。回滚：删除 `changed_inputs` 相关字段即可，不影响原有生成链。
- **result**：两项判据全中，且**没有出现多报**。
  - 测试 1（只改 TASKS.yaml）：`changed_inputs = ["tasks/TASKS.yaml"]`、`change_kind = ["task"]`，D-003 活动任务 5 → 4，`next_step` 自动换成"阶段 4 旁路生成 State 与首页并稳定运行"（CT-05）。全局 input_hash `1115155958fc272d → 22f44822b6a3fcd0`。
  - 测试 2（只改 DECISIONS.md，新增 DEC-27）：`changed_inputs = ["facts/DECISIONS.md"]`、`kind = ["decision"]`，DEC-27 出现在 D-003 的 `recent_changes` 中。input_hash `→ 8eaa8462b83a1da2`。
  - 两次 `readback_ok` 均为 true；首页新增"本轮变化来源"行，四处 Demand 全部渲染。
- **decision**：**adopt**。归因能力成为 State 的固定字段（已登记 DEC-27）。CT-12 判完成；DEC-22 的"两类事件都要过"这一前置条件已满足，剩余前置为 CT-13（cutover 脚本实测）与 T15/T16 冻结确认。
