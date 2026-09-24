# Experiment 生命周期

Experiment 用于验证改变。

## 最小结构

- hypothesis：为什么可能更好；
- baseline：当前正式方案；
- candidate：实验方案；
- metric：怎么判断；
- observation_window：观察条件/周期；
- risk：风险；
- result：结果；
- decision：adopt / reject / continue。

## 原则

- 先比较，再晋升。
- 不用一次成功替代长期证据。
- 没有可比较基线时，先建立基线。
- 实验失败也要归档，因为它能防止未来重复踩坑。
