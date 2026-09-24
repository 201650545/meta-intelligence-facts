# Demand 模型

## Demand 是什么

Demand 不是一次性请求。它描述一个希望长期成立、且会随时间变化的状态。

推荐格式：

> 让 ______ 长期保持 ______，并在 ______ 变化时自动重新评估。

## Demand 属性

- `id`：稳定 ID。
- `name`：人类短名称。
- `statement`：当前需求定义。
- `why`：为什么长期存在。
- `success_state`：当前怎样算“足够好”。
- `constraints`：不能违反的边界。
- `preferences`：非硬性偏好。
- `status`：active / paused / retired。
- `version`：需求定义版本。
- `changed_at`：最近变化时间。

## 需求会演进

需求变化时：

1. 不覆盖旧定义。
2. 创建新版本。
3. 记录变化原因。
4. 判断现有任务、实验、策略是否受影响。
5. 更新 Human View。

## 需求不是任务

Demand：
> 长期获得高质量低噪音的信息。

Task：
> 测试一个新的网页正文抽取器。

前者持续；后者必须结束。
