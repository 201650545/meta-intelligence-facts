# 热索引规则

每个归档对象应有一个轻量索引记录。

最小索引：

- `id`
- `type`
- `name`
- `date`
- `one_line_summary`
- `result`
- `superseded_by`
- `reopen_when`
- `keywords`

目标：先让模型判断“值不值得打开”，再加载内容。
