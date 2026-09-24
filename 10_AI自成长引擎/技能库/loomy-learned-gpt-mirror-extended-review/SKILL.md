---
name: loomy-learned-gpt-mirror-extended-review
display_name: GPT 镜像站 Extended 送审（自适应版）
description: 通过 AI <POOL_NAME_CN>账号池 / GPT 镜像站（<POOL_NAME> → <CARD-XX.MIRROR_HOST>）以 Extended/Thinking 深度模式送审方案、问架构、请强模型评审。触发词：镜像站、送审、问一下 GPT、AI <POOL_NAME_CN>、<POOL_NAME>、切 Extended、开放大模型评审、让强模型看方案、镜像站生图。执行前必须先跑前置探针核对契约，闸门不过不得发送。
---

> ## ⚠️ 本文件是**草稿，未安装、不生效**
>
> - **当前存放位置**：`D:\Work\AI自成长引擎\技能库\loomy-learned-gpt-mirror-extended-review\`（项目产出的 skill 统一存这里，**不进** `D:\记忆\_Skills\`，见 `技能库\README.md` §一）
> - **本位置不会自动加载、不会触发**。要生效需单独一步"安装"= 复制整个文件夹到 `D:\记忆\_Skills\`，且必须郭老师点头（**D3 已定：等 A2 探针跑通再装**）
> - 契约**已落盘**：`D:\Work\自适应工作流引擎\contracts\gpt-mirror-extended-review.yaml`（8 conditions / 11 gates，status = `draft_pending_first_run`）
> - 探针**尚未创建**：`probes\probe_gpt_mirror.ps1`（P1，T6 待首跑）、`probes\probe_gpt_mirror_ui.js`（P2，T10）。**在探针就位前，本文「前置探针」一节无法执行**，请以人工核对 pill 实际文案替代 `mode_gate`
> - 在安装前，操作真源仍是：`D:\Work\AI平台\docs\runbooks\GPT镜像站送审流程.md`
> - **已知失效**：`docs\runbooks\scripts\evalB_ext.js`（改于 2026-09-06）的三处硬编码断言在 2026-09-15 菜单文案改版后全部断裂，会返回假信号，勿直接照抄其 `=== 'Extended'` 判定

## 适用场景

- 需要把方案 / 架构 / 教学设计送到 GPT 镜像站做深度评审（Extended / Thinking 档）
- 需要用镜像站 chat 生图（图像模型可直接渲染中文，旧规「中文必糊」已作废）
- 需要把镜像站当生成器产出长文稿，再下载自存
- 遇到本机判断不了的难题，按「少问用户、多问镜像」原则先问 GPT，再自行综合落地
- 不适用：需要读长上下文的场景（应先把上下文 push 到 GitHub 让 GPT 强读，不在窗口贴长文）

## 前置探针（★ 本项目特有 · 不跑探针不许开工）

**P1 网络探针（必跑，零打扰，不碰浏览器）**

```powershell
powershell -ExecutionPolicy Bypass -File "D:\Work\自适应工作流引擎\probes\probe_gpt_mirror.ps1"
# 产物（只读，禁止手改）：
#   D:\Work\自适应工作流引擎\runtime\gpt-mirror.runtime.json
#   D:\Work\自适应工作流引擎\runtime\gpt-mirror.drift.json
```

读 `drift.json` 的 `summary`，按级别决定能不能往下走：

| drift 级别 | 含义 | 动作 |
|---|---|---|
| `break > 0` | 前置条件不成立（池不可达 / 活跃卡 0 / 会员已到期 / opencli 会话死） | **立即停**，不启动浏览器，报人并附探针原因 |
| `silent_risk > 0` | 校验点不成立（如档位未真正确认） | **视为 break**，绝不产出结论 |
| `warn > 0` | 契约候选集未覆盖，探针给了高置信替代 | 停下，把 `dry_run` 草稿报人，等点头 |
| 只有 `info` | 候选集内自动换了一项（如卡号轮换、菜单文案在候选集内） | 可继续，但**执行体必须读契约回填值，不许用自己记的字面量** |

**P2 UI 指纹探针（仅当要真发送时跑，且仅在 P1 通过后）**

只读 DOM 文本指纹：pill 文案集合、`[role=menuitemradio]` 菜单项文案集合、composer 类型（`textarea` vs `contenteditable`）、关键选择器存活性。**只 `querySelector` + 读文本，不点击、不发送、不切模式**；用独立 tab；跑完 **不 close 任何标签页**（日常 Chrome 是共享的）。

## 执行步骤

> 所有域名 / 选择器 / 菜单文案 **一律从契约 `conditions.*` 读取**，本 skill 正文与执行体内不得出现字面量。下列步骤编号对应手册「固定 4 步」。

1. **复用优先**：先 `opencli browser <profile> tab list`。已有镜像站标签页 → `tab select` 复用，**在原会话里继续**；只有确实没有才新开。返回 `[]` 但用户浏览器里明明开着 → 请用户把该页切前台再 `bind`，**不要 tab new**。
   - **校验点**：`tab list` 显示的 URL 确实是镜像站域（读契约 `conditions.account_pool.urls` / `active_card` 解析出的实例域）
2. **开池 + 一眼定位活跃账号**：打开账号池页，先扫**绿色圆点=活跃**的 Plus 卡，受限（灰/红）**直接跳过不点**。也可先走 P1 探针的健康徽章端点拿活跃卡清单（后端不随前端改版迁移，更稳）。
   - **校验点**：至少 1 张活跃卡（契约 `active_card.min_active`）；否则 `break`
3. **点击 + 秒跳镜像**：劫持 `window.open = function(u){window.__openUrl=u;return null;}` → 点 innerText 以卡文本前缀（契约 `active_card.card_text_prefix`）开头的第一个 `.n-card span`（**不是 Plus 徽章按钮**，那只会刷新账号池列表）→ 本标签 `location.href = window.__openUrl`。
   - **校验点**：`location.host` 落到镜像实例域；**失败回退**：`__openUrl` 为空说明点中了徽章 → 重取 span 再点
4. **扫聊天记录定窗口**：同一评审主题之前聊过 → **复用原窗口**（保上下文、省 Extended 预热）；全新主题 → **立即新开 tab 不犹豫**。顺带核对历史条数（契约 `gates.history_budget`，>10 条即清理末尾至剩 10）。
5. **切深度档（hydration 闸门是关键）**：等 `location.host` 就位 → **等 pill 文本从占位值变成可操作值**（占位态下点击必扑空，这是跨实例最大坑；可操作值集合读契约 `reasoning_mode.pill_ready_regex`）→ **合成完整指针事件序列**点开菜单（`pointerover→pointermove→pointerdown→mousedown→pointerup→mouseup→click`，带 `pointerId/pointerType`，坐标取 `getBoundingClientRect` 中心；**原生 click 与键盘 ArrowDown 打不开 Radix 菜单**）→ 在 `[role=menuitemradio]` 里按契约 `candidates` 的 weight 择优选中 → 自旋重试 ≤3 次。
   - **校验点**：pill 文本 == 契约 `reasoning_mode.resolved_label`（**不是**硬编码的 `'Extended'`；2026-09-15 后成功切换的文本是 `Thinking`）
   - **失败回退**：候选集全不匹配 → 出 warn 草稿报人，**不要在 Auto/默认档下提问**
6. **发问前置**：上下文先 push 到目标 GitHub 仓（`git -c http.proxy=http://127.0.0.1:7890 push`），提示词写「请先读 <repo>/<path> 后再…」并**精确列出文件路径清单**。提示词要精简（长提示词响应慢且易中断）。
7. **注入 + 发送**：composer 优先 `opencli browser <s> fill`；**大段多段中文 `fill` 只进第一段**（实测 814 字符只进 112）→ 必须 base64 + `atob` + `execCommand('insertText')`（历史对话页是 `contenteditable`；新对话页是 `textarea`，用原生 value setter + input 事件）。发送点 `[data-testid=send-button]`（**有文本才渲染**）。**合成 Enter 不提交**。多标签操作必先 `tab select` 钉死。
   - **校验点**：发送按钮点击后进入流式态
8. **主会话前台监督**：**每 15s 查一把**；深度问题总时长可达 15 分钟，`streaming:true len:0` 属正常，**出了流式字就别喊停**。页面 DOM **不会自动更新**，需要真实状态时刷新页面（每分钟一次），但**刷新会重置档位 → 刷新后必须回到步骤 5 重切**。取回复用 `[data-message-author-role=assistant]` 最后一条，但**该计数在镜像站不可信**（不渲染该节点，图片类任务 `asstN` 常为 0 只出图不出字，属正常）。
   - **校验点**：拿到非空产物，或明确判定为「只出图不出字」的正常态
9. **取产物**：长文按步骤 8 读取；图片走页面内 `fetch → dataURL → 按 30000 字节分块`取回逐段 `b64decode` 落盘（**整段拼接 base64 必报 `Incorrect padding`**；30000 是 3 的倍数，规避跨块填充）。或点 `Download this image` → Chrome 落 Downloads 为 `.tmp`，**实为完整 PNG，复制改名即可**。
10. **收尾**：**保留绑定 tab 与 opencli 会话不动**，下一个任务在同一聊天框继续；**绝不因拉新子 Agent 重跑全流程**；上一轮没结束**绝不发下一轮**（会打断）。

## 闸门清单（★ 本项目特有 · 每次发问前逐条过）

| 闸门 | 断言 | 违反时 |
|---|---|---|
| `mode_gate`（优先级最高） | pill 文本 == 契约 `resolved_label` | `silent-risk` → 熔断。**发问前的最后一个动作必须是这个断言通过**；刷新 / 回历史 / 换窗口都会重置，**没有"刚才切过"这种想当然** |
| `turn_budget` | 同一对话 ≤40 轮不新开；**一窗 ≤24 轮**（2026-09-18 用户修订 12→24）；**每 3 轮必须彻底解决一个任务**（GPT 反问算同窗口）。但 24 轮不是免死金牌：GPT 一旦出现遗忘 / 混淆早期约定 / 答非所问，不等满轮次，立即「要总结 → 带总结新开」 | `break`，换新窗口 |
| `history_budget` | 聊天历史 ≤10 条 | `info`，自动清理末尾至剩 10 |
| `foreground_supervision` | 回复由**主会话前台**监督 | `break`。禁止后台 Bash 任务（`run_in_background`）轮询镜像站 |
| `no_fork` | 不用 fork 子 Agent | `break` |
| `context_pushed` | 上下文已 push GitHub、提示词已列文件路径清单 | `warn` |
| `shared_tab` | 用自己的 `tab create`，不占他人标签页 | `break` |
| `secret_guard` | 任何 secret / 凭证值不回显、不入仓、不进输出；`financial-security-plan` 永不公开 | `break` |
| `review_gate` | 评审未过 → **零代码改动**；方案拍板后才动仓库 | `break` |

## 禁止事项

- 禁止在 **Auto / 默认档**下提问（横竖白烧一轮）；禁止省略 `mode_gate`
- 禁止用后台任务轮询镜像站状态（看不见的黑箱，必留残次品）
- 禁止 fork 子 Agent 跑镜像站流程（无实时指令流会靠猜，曾编造「用户指示」）
- 禁止复探 DOM / 重编选择器（提速最大杠杆就是"选择器固化 + 照抄"，从打开到发送应在 1 分钟内到位）
- 禁止在执行体里硬编码域名 / 选择器 / 菜单文案 / 到期日 —— 一律读契约
- 禁止在校验点不成立时产出结论（`silent-risk` 比崩溃更危险）
- 禁止 `close` 他人标签页；禁止占用别人的标签（日常 Chrome 是共享的）
- 禁止一次窗口超 24 轮（2026-09-18 用户修订，原 12 轮）或超 3 轮还没解决一个任务
- 禁止整段拼接 base64 取大文件（必报 `Incorrect padding`）
- **Windows 传参三坑**：`opencli.cmd` 是批处理 → ①多行 JS 传参会炸，必须压成单行或走临时文件；②JS 字符串带 `&` 会被 cmd 当命令分隔，URL 先 base64 再在 JS 内 `atob`+`decodeURIComponent(escape())` 还原，Python 侧用 `subprocess.run(..., shell=False)`；③大文件按 30000 字节分块取回

## 验证方式（怎么知道这个 skill 没坏）

1. **回归基线**：零 → 可发问耗时 **≤ 14.4s**（基线 9.6s × 1.5 容差；历史实测 T1 13.9s / T2 9.6s / T3 14s）。显著劣化即 `warn`（说明自愈把性能搞坏了）
   - 基线参考：`D:\Work\AI平台\docs\runbooks\测试任务-镜像零到Extended计时.md`
2. **闸门有效性**：故意在 Auto/Standard 档下走到发送前一步，skill 必须**拒绝发送**并报 `silent-risk`
3. **契约一致性**：`drift.json` 的 `probe_self_test` 必须为 `pass`（用于区分「站点变了」和「探针自己坏了」）
4. **dry-run**：`probe_gpt_mirror_ui.js` 跑完不得留下任何点击 / 输入痕迹（只读指纹）
5. **不打扰验证**：P1 探针运行全程**不启动浏览器**

## 来源

- 契约（待创建）：`D:\Work\自适应工作流引擎\contracts\gpt-mirror-extended-review.yaml`
- 操作真源手册：`D:\Work\AI平台\docs\runbooks\GPT镜像站送审流程.md`（v1，2026-09-03）
- 交接文档：`D:\Work\AI平台\docs\runbooks\GPT镜像站一键交接文档（给执行Agent）.md`
- 固化脚本（**已部分失效**）：同目录 `scripts\evalA_jump.js` / `evalB_ext.js`
- 记忆条目（`D:\记忆\调度大脑记忆\`）：`流程\workflow_ai_<POOL_NAME>_open.md`、`流程\workflow_gpt_repo_sync.md`、`反馈\feedback_gpt_mirror_account_switch.md`、`反馈\feedback_gpt_mirror_subagent_flow.md`、`反馈\feedback_gpt_rounds_discipline.md`、`反馈\feedback_mirror_send_speed.md`、`反馈\feedback_mirror_chat_history.md`、`反馈\feedback_mirror_extend_for_architecture.md`、`反馈\feedback_mirror_as_generator_download.md`、`反馈\feedback_mirror_image_gen_slow_works.md`、`反馈\feedback_mirror_image_renders_chinese.md`、`反馈\feedback_gpt_context_github.md`、`反馈\feedback_fork_forbidden.md`、`反馈\feedback_ask_user_only_urgent.md`、`教训\error_lessons.md`（教训①②③④⑤⑦）
- 完整盘点与失效证据：`D:\Work\自适应工作流引擎\docs\02-镜像站试点盘点.md`
