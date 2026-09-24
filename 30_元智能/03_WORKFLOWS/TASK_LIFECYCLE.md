# Task 生命周期

## Task 必须有限

状态：

- queued
- active
- blocked
- completed
- failed
- cancelled
- superseded

## 创建条件

Task 必须明确服务于某个 Demand，并至少包含：

- 为什么要做；
- 预期结果；
- 完成条件；
- 验证方法；
- 影响范围。

## 结束规则

每个 Task 最终进入终止状态。

长期存在的是 Demand/Responsibility，不是 Task。

## 结束后

- 更新 State；
- 将重要结果写入 Human View；
- 产物进入 Archive；
- 未解决问题生成新的 Task，而不是让旧 Task 永久悬挂。
