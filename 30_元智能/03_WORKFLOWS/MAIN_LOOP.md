# 主循环

```mermaid
flowchart TD
    A[Observe 观察] --> B{有重要变化吗?}
    B -- 否 --> A
    B -- 是 --> C[Understand 理解]
    C --> D{需要行动吗?}
    D -- 否 --> E[Update State]
    D -- 是 --> F[Decide 决策]
    F --> G[Act 执行]
    G --> H[Evaluate 验证]
    H --> I{结果可靠吗?}
    I -- 否 --> J[升级 / 建实验 / 请求高智力]
    J --> F
    I -- 是 --> E
    E --> K[Archive 已结束内容]
    K --> A
```

## Observe

观察来源：

- 当前系统运行结果；
- 错误和异常；
- 人新增需求；
- 任务结果；
- 实验结果；
- 外部技术变化。

## Understand

只理解对当前 Demand 有关的变化。

## Decide

选择：忽略、记录、创建 Task、创建 Experiment、升级高智力模型、请求人工决定。

## Act

由最低必要智力执行。

## Evaluate

验证结果是否真的改善需求，而不仅仅是“执行成功”。

## Update

刷新 Current State 和 Human View。
