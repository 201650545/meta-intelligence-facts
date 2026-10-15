---
name: gpt-mirror-extended-review
origin: flow   # flow=按既有流程手工固化｜learned=闭环自产｜adopted=从第一层收编（见 技能库/naming.yaml）
display_name: GPT 镜像站深度送审（Chat 标签 / ChatGPT 6 Sol / 顶档 High · 自适应版）
description: 通过 AI <POOL_NAME_CN>账号池 / GPT 镜像站（<POOL_NAME> → <CARD-XX.MIRROR_HOST>）以**默认 ChatGPT 6 Sol + 顶档 High**送审方案、问架构、请强模型评审。2026-10-11 郭老师明令：**默认必须用 ChatGPT 6 Sol**（镜像站 Chat 里显示为 `6`、默认即选中）+ 档位推顶 `High`；Work 标签接 Codex、本账号不可用。触发词：镜像站、送审、问一下 GPT、AI <POOL_NAME_CN>、<POOL_NAME>、GPT-6 Sol、Chat 标签、High 档、开放大模型评审、让强模型看方案、镜像站生图。执行前必须先跑前置探针核对契约，闸门不过不得发送。
---

> ## ★★★ 本 skill 是「活文档」—— 任何 Agent 都有权、也有义务**就地修改**
>
> 郭老师 2026-10-15 定的规矩：**用这个 skill 时如果遇到困难、发现它写错了 / 过时了 / 不管用，
> 不要绕过去，也不要只在对话里抱怨 —— 直接改这个文件，并留下修改记录。**
> 理由：本 skill 的坑几乎全是「站点改版 / Windows 传参 / 标签抢占」这类**环境性问题**，
> 只有真正跑过一遍的人才看得见；写下来，后面每个人就不必重新踩一遍。
>
> ### 怎么做（四步 · 缺一不可）
>
> 1. **先读 `CHANGELOG.md`** —— 你要踩的坑，前面大概率有人踩过，照它的修法走。
> 2. **就地改代码或本文档** —— 不新开副本（本目录是唯一真源，见下方「不安装、不复制」裁定）。
> 3. **往 `CHANGELOG.md` 追加一条**，照抄已有条目的六段式：
>    `现象（可复现的证据）` / `原因` / `修法` / `影响面` / **`怎么发现是否又坏了`** / `回滚方式`。
>    ⚠️ **「怎么发现是否又坏了」是必填** —— 否则下一个人无法判断这个修法还在不在生效。
> 4. **在 `CHANGELOG.md` 的「待验证 / 未解决」补一笔**你这次没能确认的东西
>    （例：「只在 CARD-21 这一个实例上验过」），方便别人继续。
>
> ### 改的时候守三条
>
> - **只追加，不删别人的修正**；确要推翻，写清「为什么推翻 + 证据」。
> - **实测与推测分开写**（哪个是量出来的、哪个是猜的）。
> - **涉及 secret 的观察不入档、不回显**（`authToken` 等，见禁止事项 `secret_guard`）。
>
> ### 如果 Skill 本身要修改的话
>
> | 你想改什么 | 改哪里 | 注意 |
> | :--- | :--- | :--- |
> | 站点选择器 / 菜单文案 / 档位名变了 | 先改**契约** `contracts/gpt-mirror-extended-review.yaml`，再改 `scripts/`；本文档只写方法 | 禁止在脚本里硬编码文案 |
> | 某个坑有更稳的做法 | 改 `scripts/` 里对应脚本 + 追加 CHANGELOG | 保留旧做法作降级路径，别直接删 |
> | 流程纪律（发问次数、刷新、轮数） | 改本文档对应章节 + 追加 CHANGELOG | 注明「谁定的规」（郭老师/实测） |
> | 本文档说法与实际不符 | **直接更正本文档并标注日期**，同时在 CHANGELOG 记「观测更正」 | 不要为了迁就文档去改实测行为 |
>
> **判断标准**：改完之后，一个从没跑过这个流程的 Agent，**只读 SKILL.md + CHANGELOG.md 就能一次跑通**。达不到就是没改好。


>
> ## ★★ 2026-10-15 实测修正 7 条（**发问前必读，否则会白烧轮次**）
>
> 完整证据、影响面与回滚方式见同目录 **`CHANGELOG.md`**。摘要：
>
> 1. **同一会话只能发一次**（郭老师定规）：连发两条 → 第一条变 `Validation failed, please refresh and try again`，URL 跳回 `/?prompt=`，档位重置回 `Instant`。**发一条必须等它答完或判失败，再发第二条。**
> 2. **出现 `Connection interrupted. Waiting for the complete answer` → 直接 `location.reload()`**（郭老师定规）：服务端已生成完，刷新即得全文（实测 55 字占位 → 7838 字）。**不要等、不要重发。** 已固化进 `wait_and_fetch.py`。
> 3. **会话页 `/c/…` 上 `ok:false` 是正常历史遗留 → 已修**：`Chat|Work` radio 在会话页不存在，旧判定恒 `false`。会话页现按 `modelOk && pill==='High'` 放行（`jump_and_ready.js` 新增 `onConversationPage` / `chatOk`）。
> 4. **`backend-api` 在本实例取不到**：会话 ID 形如 `WEB:<uuid>`，`/backend-api/conversation/WEB:xxx` → **400**，去前缀 → **404**。`wait_and_fetch.py` 已加 **DOM 直读兜底**（刷新后取 `[data-message-author-role="assistant"]` 的 `innerText`），并标注 `[SUCCESS·DOM]` 以免被误当零损通道。**故铁律三"绝不用 DOM"在本实例不成立。**
> 5. **`wait_and_fetch.py` 首拍假完成**：刚发送就跑会返回 `总耗时: 0.0s`（此刻 stop 按钮还没出现）。已加守卫：assistant 正文为空时不认为完成。
> 6. **⚠️ §五.1 关于 `--tab` 的说法在本版本不成立**：`opencli` v1.8.8 的 **`eval` 不接受 `--tab`**（实测返回的是活跃标签的 URL）。要定向请用 **`tab select <pageId>`**，或接受"eval 打活跃标签"。⇒ **这意味着 `send_turn.py` / `wait_and_fetch.py` 会打在用户正在看的页面上**，使用前必须确认活跃标签是自己开的。
> 7. **单次 `eval` 有 ~115s CDP 硬超时**：`CDP command Runtime.evaluate timed out after 115s`。§跳转加速的"页内自旋"方向对，但**单次 eval 内等待必须 <110s**；等答案要**切成分片**（每片 ~80s）由外部循环串起来。


> ## ★ 现行生产版 · 元智能唯一真源（按需直读）
>
> - **存放位置**：`D:\Work\元智能\10_AI自成长引擎\技能库\gpt-mirror-extended-review\`（全盘唯一真源，无前缀）。
> - **郭老师 2026-10-12 明确裁定**：**不安装、不复制到任何具体 Agent 私有目录**。任何 Agent 收到送审/问诊指令时，按微内核路由直接寻址读取本文件与 `scripts/` 执行，杜绝双真源与多副本腐烂。
> - 契约**已落盘并验证**：`D:\Work\元智能\20_自适应工作流引擎\contracts\gpt-mirror-extended-review.yaml`（**v5 / 9 conditions / 13 gates**，status = `verified`）。
> - **三层探针全绿（2026-10-12 实测通过）**：
>   * ① **P1 网络探针** `probes\probe_gpt_mirror.ps1`（自检 pass，网络可达，会员剩余 17 天）；
>   * ② **P2 UI 探针** `probes\probe_gpt_mirror_ui.js`（只读 DOM 探测三闸 Chat / 模型 6 / High，临时标签自销毁）；
>   * ③ **P2 额度探针** `probes\probe_gpt_mirror_limits.js`（只读检查账号池 17 卡额度，实测排除 FREE 见底卡 CARD-27，直连卡 CARD-22 额度充足健康）。
> - **已知失效**：`docs\runbooks\scripts\evalB_ext.js`（改于 2026-09-06）的三处硬编码断言在 2026-09-15 菜单文案改版后全部断裂，会返回假信号，勿直接照抄其 `=== 'Extended'` 判定。**2026-10-10 新版 UI 后升级为「整段作废」**——`Thinking• Extended` 结构整体消失，连 `ext_menu_open.js` / `ext_menu_pick.js` 一并失效，替代路径见 §执行步骤 4
> - **★★ 2026-10-11 模型纪律（郭老师明令）**：**默认必须用 `ChatGPT 6 Sol` + 顶档 `High`**。镜像站 Chat 里 `ChatGPT 6 Sol` 显示为 **`6`** 且**默认即选中** —— **保持不动**，不许改成 `GPT-5.6 Sol` / `GPT-5.5`。`mode_gate` 已升**三闸**（Chat / 模型 `6` / pill `High`）。
> - **⭐ 2026-10-11 目标改回 `Chat`（背景）**：实测 **`Work` 标签不可用**（接 Codex、本账号无权限）—— Work + `GPT-6 Astra` + `Max` 下连「1+1」「你好」都被 OpenAI 式安全拒绝挡回（`This content can't be shown for safety reasons`），切回 `Chat` 同题正常。⚠️ 2026-10-10 的「一律走 Work」裁定**作废**。
> - **2026-10-10 站点大改版（背景）**：镜像站换 **新版 ChatGPT UI**，旧文案 `Auto / Thinking• Extended / GPT-5.6 Luna` **一个字都不剩**，改为 **顶部 `Chat | Work` 标签 + 模型 pill 里的 "Power" 滑杆**，默认 `Instant`。详见 §执行步骤 4 与 §站点改版适配。

## 适用场景

- 需要把方案 / 架构 / 教学设计送到 GPT 镜像站做深度评审（**2026-10-10 改版后 = Work 标签 + `GPT-6 Astra Max`**；旧文案 Extended / Thinking 已作废）
- 需要用镜像站 chat 生图（图像模型可直接渲染中文，旧规「中文必糊」已作废）
- 需要把镜像站当生成器产出长文稿，再下载自存
- 遇到本机判断不了的难题，按「少问用户、多问镜像」原则先问 GPT，再自行综合落地
- 不适用：需要读长上下文的场景（应先把上下文 push 到 GitHub 让 GPT 强读，不在窗口贴长文）

## 前置探针（★ 本项目特有 · 不跑探针不许开工）

**P1 网络探针（必跑，零打扰，不碰浏览器）**

```powershell
powershell -ExecutionPolicy Bypass -File "D:\Work\元智能\20_自适应工作流引擎\probes\probe_gpt_mirror.ps1"
# 产物（只读，禁止手改）：
#   D:\Work\元智能\20_自适应工作流引擎\runtime\gpt-mirror.runtime.json
#   D:\Work\元智能\20_自适应工作流引擎\runtime\gpt-mirror.drift.json
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

## 执行步骤（2026-10-08 用户裁定优化版）

> 所有域名 / 选择器 / 菜单文案 **一律从契约 `conditions.*` 读取**。实战严守**六大铁律**：
> 1. **★ 记住网址（最省时间的一招）**：**第一次**走账号池进入镜像站后，**立刻把当前镜像网址抄下来存档**（`runtime/gpt_mirror_active_url.txt`）。**第二次、第三次打开时直接导航到这个网址** —— **跳过账号池、跳过取号**（热路径 2 次调用 ≈19s；走池页 3 次调用 ≈23s，还多等一整轮）。网址丢了 / 标签被关，也用它秒级恢复。
> 2. **高频心跳判定完成**（毫秒级捕获 stop 消失，严禁粗粒度盲等）；
> 3. **backend-api 零损提取直接落盘**（绝不用脆弱 DOM 滚动）；
> 4. **原窗口无缝续问**（同窗口保留全部历史上下文）；
> 5. **★ 轮数纪律**：**每次任务 ≤3 轮**、**每个聊天框 ≤24 轮**（GPT 反问算同窗口；达到 24 轮 = **先要总结 → 带总结新开**，不是直接新开）。详见闸门 `turn_budget`。
> 6. **★★ 模型纪律（郭老师 2026-10-11 明令）**：**默认必须用 `ChatGPT 6 Sol` + 顶档 `High`** —— 在镜像站 Chat「Select model」里它就是**默认选中**的那一项（显示名 `6`），**保持不动**；❌ **不许**改成 `GPT-5.6 Sol` / `GPT-5.5`。详见闸门 `mode_gate`（**三闸**）。

1. **★ 记住网址 + 复用优先（铁律一 · 最快路径）**：
   - **第一次**（走账号池）进入镜像后，**立刻把网址抄下来**存到 `runtime/gpt_mirror_active_url.txt`（格式 `https://<CARD-XX.MIRROR_HOST>/...`）—— **这是全流程最省时间的一招**。
   - **之后每次**先做两件事：① `opencli browser $S state` 若已显示 `<MIRROR_HOST>` → **直接跳到第 4 步**（复用，0 跳转）；② 否则**先直连那个存档网址**（`eval "location.href='<存档网址>'"`）；只有它失效（`jump_and_ready` 返回 `still-on-pool` / `no-pill`）才走第 2 步的账号池。
   - 网址丢了 / 标签被误关 → 也用存档网址秒级恢复，**绝不重跑池页**。
2. **开池取号：读 localStorage，不点 DOM（★ 2026-10-11 重写）**：
   - **先用 `eval` 导航**（⛔ 禁止 `open`，见 §跳转加速）：`opencli browser $S eval "location.href='https://<POOL_HOST>/?utm_source=hidden-ncn';'go'"`。
   - 就绪后**一条 eval 跑 `scripts/fast_jump.js`**：读 `localStorage.panelAccountList`（`carID` / `badge` / `isHealthy`）+ `authToken`，直接拼 `plus-login` URL 导航。
   - ⛔ **不再用**「扫卡片 → 合成指针序列点 span → 劫持 `window.open`」——慢，且依赖 `.n-card` 文案漂移。
3. **等镜像页就绪：页内自旋，不用固定 sleep**：
   - ⛔ 禁止 `sleep 6` 这类盲等；**这一步已合并进第 4 步的 eval**（内部自旋等 `button.__composer-pill`，实测仅需 ~1.5–2.8s）。
4. **三闸校验 + 切档位（一条 eval 干完 · `scripts/jump_and_ready.js`）**：
   - 一条 eval 依次：①页内自旋等镜像页就绪（若还停在池页 → 返回 `still-on-pool`，调用方改走第 2 步）；②**闸门 A**：`Chat` 标签 `data-state == "on"`；③开 pill 菜单 → 进「Select model」高级视图，读 `aria-checked=true` 的 `[role=menuitemradio]` ⇒ **闸门 B：必须是 `6`（= `ChatGPT 6 Sol`）**；④推 `[role=slider]` 到顶（Chat `0..2` → `2`）⇒ **闸门 C：pill 闭态 == `High`**；⑤关菜单（**Escape + document pointerdown 都发**，见 §站点改版适配 五.3）。
   - **返回 `{ok:true, chatState, modelChecked, pill, ...}` 才可进入第 5 步**；`ok:false` 一律熔断（`silent-risk`）。实测：`{chatState:"on", modelChecked:"6", modelOk:true, slider:"0/2→2/2", pill:"High", ok:true}`，页内 ~3.5s。
   - **★★ 模型必须是 `ChatGPT 6 Sol`**：Chat 的「Select model」里它显示为 `6` 且**默认即选中** —— **保持不动**，❌ **不许**改成 `GPT-5.6 Sol` / `GPT-5.5`（郭老师 2026-10-11 明令）。
   - ❌ **不要切 `Work` 标签** —— 该标签接 Codex、本账号不可用，问了必被安全拒绝挡回（详见 §站点改版适配 四）。
5. **注入 + 发送**：使用 `scripts/send_turn.py`。大段中文通过 base64 解码后注入可见的 contenteditable，点击 send-button，确认进入 streaming 态。
6. **高频心跳监听完成（★ 铁律二）**：
   - 使用 `scripts/wait_and_fetch.py` 以 2~2.5 秒心跳检测 `[data-testid="stop-button"]` 与 `.result-streaming`。
   - 一旦两者消失，立即判定回答完成，**反应时间 ≤ 2.5 秒**，严禁使用 15 秒大轮询导致“它早就回答完了你还在傻等”。
7. **backend-api 零损拉取与即时落盘（★ 铁律三）**：
   - 捕获完成信号后，直接在页面上下文中 `fetch('/backend-api/conversation/' + convId)` 拉取完整 JSON；
   - 提取最新 assistant 的完整 Markdown，直接写入业务目标文件（如 `D:\Work\English-Content-Factory\...\GPT方案.md`）；
   - 彻底规避 DOM 虚拟滚动截断、富文本解析丢字、多段内容截流三大缺陷。
8. **同窗口快速多轮续问（★ 铁律四）**：
   - 保留当前绑定 tab 与 opencli 会话不动；
   - 下一轮提问直接调用 `scripts/send_turn.py <新提示词>`，在原页面输入框继续发问；
   - 每任务 ≤3 轮、每窗口 ≤24 轮，充分利用已有上下文，无需重复交代背景。

## 跳转加速（2026-10-11 实测 · 硬性要求）

> **实测对比**：旧流程（`open` 池页 → 点卡片 → `sleep 6` → 切档）**≈40s+**；优化后 **复用 tab ≤8s / 热启动 ≤20s / 冷启动 ≤28s**（2026-10-11 实测：**4.5s / 18.8s / 22.7s**）。

**先记住两条根因**
1. **`opencli` 每次调用有 ~3.5s 纯 node 启动 + 1–6s 桥往返**（实测 `opencli --version` 单独就 3.53s）⇒ **调用次数是最大杠杆**，能一条 eval 干完的绝不拆两条。
2. **`open` 命令等 network-idle**，而镜像站 / 账号池都是长轮询 SPA ⇒ **永远不 idle**，实测 **18–21s** 才返回（纯白等）。

**六条硬性要求**
| # | 要求 | 反例（禁止） |
|---|---|---|
| R1 | **复用优先**：先看已绑定 tab 能否直接用（`state` 里是 `<MIRROR_HOST>` 就直接切档） | 每次都重跑账号池 |
| R2 | **导航一律 `eval "location.href=..."`** | ⛔ `opencli browser $S open <url>`（18–21s） |
| R3 | **禁固定 `sleep`**，用页内自旋等元素（或 `wait selector`，元素出现即返回） | ⛔ `sleep 6` / `sleep 10` |
| R4 | **合并 eval**：等就绪 + 切档 + 断言写进同一条 eval（`jump_and_ready.js`） | 拆成 wait + gate + verify 三条 |
| R5 | **★ 记住网址**：**第一次**进入后抄下镜像 URL；**第二次起直接直连它**（`runtime/gpt_mirror_active_url.txt`），跳过池页 | 会话还活着也绕池页 |
| R6 | **池页取号读 localStorage**（`fast_jump.js`） | ⛔ 等卡片渲染 + 点 DOM + 劫持 `window.open` |

**性能预算（超了要报人）**
| 场景 | 调用数 | 预算 |
|---|---|---|
| 复用已绑定 tab（同窗口续问） | 1 | ≤8s |
| 热启动（缓存镜像 URL 且会话有效） | 2 | ≤20s |
| 冷启动（会话失效，需走池页取号） | 3 | ≤28s |

**标准调用序列（照抄）**
```bash
S=$(opencli profile list | grep -oE '[a-z0-9]{8} default' | awk '{print $1}')
# ① 试缓存镜像 URL（热路径；失败会自动返回 still-on-pool/no-pill）
opencli browser $S eval "location.href='<缓存的 https://<CARD-XX.MIRROR_HOST>/>';'go'"
R=$(opencli browser $S eval "eval(decodeURIComponent(escape(atob('$(base64 -w0 < scripts/jump_and_ready.js)'))))")
# ② 只有 ① 返回 still-on-pool / no-pill 时，才走池页（冷路径）
if echo "$R" | grep -qE 'still-on-pool|no-pill'; then
  opencli browser $S eval "location.href='https://<POOL_HOST>/?utm_source=hidden-ncn';'go'"
  opencli browser $S eval "eval(decodeURIComponent(escape(atob('$(base64 -w0 < scripts/fast_jump.js)'))))"
  R=$(opencli browser $S eval "eval(decodeURIComponent(escape(atob('$(base64 -w0 < scripts/jump_and_ready.js)'))))")
fi
echo "$R"   # 必须 ok:true 才可发问
```

**★ 缓存约定（郭老师 2026-10-11 明确要求）**：**第一次**打开账号、进入 ChatGPT 镜像版后，**立刻把镜像版网址复制并存档**到 `runtime/gpt_mirror_active_url.txt`；**第二次、第三次打开时直接复制 / 导航那个网址**，跳过账号池取号 —— **这就是最省时间的一招**。`jump_and_ready` 返回 `still-on-pool` / `no-pill` 时才回退走池页。
**⚠️ `fast_jump.js` 会读 `authToken`（敏感值）—— 只在 eval 内使用，不落盘、不入仓、不回显**（见禁止事项 `secret_guard`）。

## 站点改版适配（2026-10-11 实测 · 郭老师裁定改回 Chat 标签 + 顶档 High）

> 实测人：WorkBuddy（opencli `LOCAL_BROWSER_PROFILE`）｜证据截图：`D:\临时文件夹\_mirror_{shot1,work,workmenu,astra_max,adv,v31_models}.png`
> **➡️ 模型清单 / 档位 / 额度机制 / 账号分配建议**：见 `D:\Work\元智能\20_自适应工作流引擎\docs\runbooks\GPT镜像站Work模式模型与额度指南.md`（**注意 Work 标签现不可用，该指南的 Work 档位部分仅作参考**；额度三层：会员制 / 账号级 limits_progress / 档位越快越费；PROLITE = 底层 ChatGPT Pro 账号）
> **➡️ 2026-10-11 关键更正**：见本节 **四、`Work` 标签不可用**。

### 一、账号池页（`https://<POOL_HOST>/?utm_source=hidden-ncn`）

1. 已从「单一 ChatGPT Plus 账号池」升级为**多模型聚合门户**：顶部多出 `ChatGPT Plus镜像`（下拉）/ `Claude 镜像站` / `DeepSeek R1` / `Gemini Pro镜像` / `Grok 镜像站`。**送审仍点 ChatGPT 那一栏下的账号卡。**
2. 卡片仍是 `.n-card`，span 顺序 = `["Plus","GPT-5 ⑪"]`（徽章在前、标签在后）；**老脚本按 `/^GPT-5/` 找 span 仍然命中**。
3. 实测 17 张卡**全部 `isHealthy=true`**（无受限卡可跳）；badge 新增 **`PROLITE`** 档（CARD-31/27/32/30），其余为 `PLUS`。
4. 跳转法**未变**：劫持 `window.open` 存 `__openUrl` → 点 `GPT-5` span → `location.href=__openUrl`，实测跳到 `CARD-11.<MIRROR_HOST>/api/v2/plus-login`。
5. 会员有效期页面显示 **2026-10-29**（契约 `membership_expiry` 原写 2026-10-28，已同步修正）。

### 二、镜像实例（`<CARD-XX.MIRROR_HOST>`）—— 新版 ChatGPT UI

1. **顶部中央新增 `Chat | Work` 单选组**：`button[role=radio]`，文案 `Chat` / `Work`，选中态看 `data-state`（`on` / `off`）。⚠️ **该开关只在首页新对话页有；进入某个对话（`/c/…`）后消失**（实测 `radios: []`）。
   - `Chat`：标题 `Ready when you are.`，composer 占位 `Ask ChatGPT`，**3 档**（`Instant` / `Medium` / `High`）。← **现行目标，顶档 = `High`**。
   - `Work`：标题 `What should we work on?`，composer 占位 `Work on anything`，多一行 `Plugins`，**5 档 effort**。❌ **2026-10-11 起不可用（接 Codex、本账号无权限）**，见本节 四。
2. **模型 pill 语义变了**：`button.__composer-pill`
   - **Chat 标签**：关闭态文本 = **档位名**（`Instant` / `Medium` / `High`）；展开态 = `Thinking effort`。← 现行
   - **Work 标签**：关闭态文本 = **「模型名 + 档位」两段无空格拼接**（如 `GPT-6 AstraMax`）；展开态 = `Select model`。⚠️ 实测 DOM 文本**无空格**（`GPT-6 AstraMax`），契约若写带空格的 `GPT-6 Astra Max` **严格比对会不匹配**。
   - **hydration 占位坑仍在**：pill 未就绪时点它必扑空，先等文本变成可操作值。
3. **菜单结构**（`[role=menu]`，`data-testid=composer-intelligence-picker-content`）：
   | 元素 | 说明 |
   |---|---|
   | `[role=menuitem][aria-label="Select model"]` | 顶部行，含 `.d1BZWq_ViewToggleModelLabel`（模型名）+ `.d1BZWq_ViewToggleEffortLabel`（档位）；点它展开高级视图 |
   | `[role=menuitem][aria-label="Power"]` | 内含 **`[role=slider]`**（`aria-valuenow` / `aria-valuemax`） |
   | `[role=menuitemradio]` | 高级视图模型清单。**Chat 实测（2026-10-11）**：`6`（**★★ 默认项 = `ChatGPT 6 Sol`**，`aria-checked=true`；郭老师 2026-10-11 明令**默认必须用它**）/ `GPT-5.6 Sol` / `GPT-5.5 Leaving on October 14`（后两者**不是目标**）。**Work 实测（2026-10-10，已不可用）**：`Default(Recommended set of models)` / `GPT-6.1 Sol` / `GPT-6 Astra` / `GPT-6 Sol` / `GPT-6 Luna` / `GPT-5.6 Sol` / `GPT-5.6 Terra` / `GPT-5.6 Luna` / `GPT-5.5` |
4. **档位阶梯（关键）**：
   - **Chat（现行）**：滑杆 `aria-valuemin=0 / aria-valuemax=2`，**3 档 `0=Instant · 1=Medium · 2=High`**；推到顶 = `2` ⇒ pill 闭态 = **`High`**。✅ **目标档 = `Chat` + `High`**。模型保持默认项 `6` 即可。
   - **Work（❌ 2026-10-11 起不可用，仅作历史）**：不选模型直接推滑杆 = **预设阶梯**（每格连模型一起换），顶端只到 `GPT-6 Astra / Medium`；**先显式选 `GPT-6 Astra`** 才变纯 effort 五档 `Light/Medium/High/Extra High/Max`，顶端 = `Max`。
5. 侧栏 `Recents` 标题带账号号前缀（⑫⑬㉓⑪）；右上 `切换账号` / `AI<POOL_NAME_CN>`；左下账号卡 `郭老师 / Plus`。
6. composer 仍是**可见 `[contenteditable=true]` + 隐藏 `textarea[name=prompt-textarea]`（`w=0 h=0`）** —— 老的 0×0 陷阱不变。

### 三、可照抄的新版两段法（JS 一律走 base64 传参）

```bash
S=$(opencli profile list | grep -oE '[a-z0-9]{8} default' | awk '{print $1}')   # 现取，2026-10-11 实测 = LOCAL_BROWSER_PROFILE
# A：账号池 → 劫持 window.open → 跳 vip-XX（脚本未变，照旧）
#    ⚠️ 池页要用 open <url> 打开（tab new 建的标签 opencli 不跟踪，eval 会打到 about:blank）
opencli browser $S eval "eval(decodeURIComponent(escape(atob('$(base64 -w0 < _evalA_jump.js)'))))"
# B：确认 Chat 标签 + 推滑杆到顶 High（整段 base64 后再 eval，规避 < > & 换行四坑）
opencli browser $S eval "eval(decodeURIComponent(escape(atob('$(base64 -w0 < to_chat_high.js)'))))"
```

`to_chat_high.js` 要点（按此顺序）：① 确认 `button[role=radio]` 里 `Chat` 的 `data-state === 'on'`（默认即是，不用切）；② 合成指针序列 + 原生 click 点 pill 开菜单；③ `[role=slider]`.focus() 后连发 `ArrowRight` 到 `aria-valuenow === aria-valuemax`（= 2）；④ **document 级 pointerdown 关菜单**（合成 pointerdown / Escape / 原生 click 都关不掉）；⑤ 回读 pill 闭态文本断言 `High`。

### 四、⭐ `Work` 标签不可用（2026-10-11 实测 · 郭老师确认）

郭老师反馈「Work 模式是连接着 Codex 使用的，我用不了」→ 实测坐实：

| 模式 | 问题 | 返回 |
|---|---|---|
| **Work**（`GPT-6 Astra` + `Max`，pill 闭态 `GPT-6 AstraMax`） | 「只回答一个数字：1+1 等于几？」 | ❌ `This content can't be shown for safety reasons`（OpenAI 式拒绝） |
| **Work**（同窗口续问） | 「你好，请只回复两个字：收到」 | ❌ 同上 |
| **Chat**（pill 闭态 `High`） | 同上「你好」问题 | ✅ 正常返回 **「收到」** |

**判据**：Work 连「你好」都被拒、Chat 同题正常 ⇒ Work 路由（接 Codex、本账号无权限）返回占位式 refusal，**不是提问方式问题**。
**处置**：一律留在 `Chat` 标签、顶档 `High`；**不要**为了「更深的档」去切 Work。

### 五、实测踩坑（2026-10-11）

1. **`eval` 默认打「活跃标签」**，不是你以为的那个 ⇒ 多标签时必须用 **`--tab <pageId>`** 定向（`tab new <url>` 会返回 `{page:"<id>"}`）。
   ⚠️ **2026-10-11 修正**：早先记的「`tab new` 建的标签不被跟踪」**不准确** —— 标签其实建出来了，只是**不带 `--tab` 的 eval 打到了活跃标签**（当时恰好是 `about:blank` 或用户的别的页面）。
   ⇒ 想**不打扰用户**，就 **`tab new` 开自己的标签 + 全程 `--tab` 定向**（2026-10-11 实测可行，`tab list` 也能看到它）。⛔ 导航别用 `open`（等 network-idle，见 §跳转加速）。
2. **对话页 `/c/…` 里没有 `Chat/Work` radio**（`radios: []`）—— 切档必须在**首页新对话页**做。
3. **关 Radix 菜单要分两种视图**（2026-10-11 实测）：
   - **普通视图**（刚点开 pill）：**document 级 pointerdown** 有效 ——
     ```js
     document.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,cancelable:true,composed:true,pointerId:99,pointerType:'mouse',isPrimary:true,button:0,buttons:1,clientX:5,clientY:5}))
     ```
   - **「Select model」高级视图**：上面的 pointerdown **失效**（菜单卡在 `data-state=open`，pill 一直显示展开态 `Thinking effort`）⇒ **只有合成 Escape 有效**：
     ```js
     ['keydown','keyup'].forEach(n=>document.dispatchEvent(new KeyboardEvent(n,{key:'Escape',code:'Escape',keyCode:27,which:27,bubbles:true,cancelable:true,composed:true})))
     ```
   - ⇒ 脚本里**两个都发**（`jump_and_ready.js` 的 `closeMenu()` 就是这么做的）。判据：pill 回到档位名（`High`）且 `[role=menu]` 的 `data-state == closed`。
4. **关键路径内部打点**（不含页面加载）：开菜单 ≈1.0s → 推滑杆到顶 ≈2.0s → 关菜单+确认 ≈1.5s。
5. **历史侧栏会折叠**：折叠时 `a[href^="/c/"]` 全部消失（`links:0`）→ 点 `[data-testid="open-sidebar-button"]` 展开（**注意它是 `data-testid`，不是 class**）。
6. **⚠️ `[role=alertdialog]` / `[role=dialog]` 在镜像站命中的是「侧栏容器」**，不是确认框 —— 用它定位会报 `no-confirm-button`。删除确认框的真正按钮 = **`[data-testid="delete-conversation-confirm-button"]`**（文案 `Delete`）；历史行的选项按钮 = **`button[data-testid="history-item-<N>-options"]`**（比 aria-label 稳）。
7. **eval 跟随活跃标签 ⇒ 长循环会被「抢占」打断**：批量任务跑到一半，活跃标签可能被别的会话/用户切走（实测被切到 `127.0.0.1:8088`），此后所有 DOM 查询都打在错页面上，表现为 CDP `Runtime.evaluate timed out`。⇒ 批量脚本**每轮必须校验 `location.host` 还在 `<MIRROR_HOST>`**，否则立即停并如实报告（**不抢回**，见工具记忆「被抢占的红线」）。

## 自动化脚本工具套件（`scripts/` 目录）

> **公共配置**：`_mirror_common.py`（2026-10-11 新增）—— 三个 Python 脚本统一从这里取
> **opencli 会话码**（`OPENCLI_SESSION` 环境变量 → `opencli profile list` **现取** → 兜底 `LOCAL_BROWSER_PROFILE`）
> 与**本项目 runtime 路径**（`D:\Work\元智能\20_自适应工作流引擎\runtime\`）。
> ⚠️ **修前**那三个脚本把会话名**写死成 `'chat'`**、且指向旧的 `D:\Work\元智能\runtime\` ⇒ **三个全部失效**（2026-10-11 审计发现并修复）。

**JS（页内 eval，base64 传入）**
- **`fast_jump.js`**：账号池 → 镜像的**快速跳转**（读 `localStorage`，不点 DOM、不劫持 `window.open`）。必须在池页 origin 上跑。
- **`jump_and_ready.js`**：**一条 eval** 完成「页内自旋等镜像页就绪 → **三闸校验**（`Chat` 标签 / 模型 `6` = ChatGPT 6 Sol / pill `High`）→ 推滑杆到顶 → 关菜单」。返回 `{ok, chatState, modelChecked, pill, ...}`；**`ok:true` 才可发问**。
- **`to_chat_high.js`**：⚠️ **降级备选**（只做 Chat + High、**不校验模型**）；正常一律用 `jump_and_ready.js`。
- **`prune_history.js`**：聊天记录清理（契约 `history_budget` 的可执行体）。**默认 dry-run 只列清单**；置 `window.__PRUNE_APPLY=true` 才真删。保留最近 10 条、从**最旧**删起。
  - 用法（dry-run）：`opencli browser $S eval "window.__PRUNE_APPLY=false;eval(decodeURIComponent(escape(atob('$(base64 -w0 < scripts/prune_history.js)'))))"`
  - ⚠️ **删除不可逆**：先看 dry-run 的 `wouldDelete` 清单、确认后再跑 apply（见禁止事项 ⑤ 的 UTF-8 解码要求）。

**Python（注入 / 等待 / 抓取 / 保活）**
- **`ensure_and_backup_session.py`**：会话保活与真源 URL 备份/自愈恢复。
- **`send_turn.py`**：无损多轮注入与发送。**发送前先跑 `jump_and_ready.js` 的三闸，不过就拒发**。
  - 用法：`python scripts/send_turn.py <提示词文本或文件路径>`
- **`wait_and_fetch.py`**：高频心跳监听（2.5s）+ backend-api 抓取全文落盘。
  - 用法：`python scripts/wait_and_fetch.py <目标Markdown路径>`

**★ 缓存文件（= 郭老师说的「记住网址」）**：`D:\Work\元智能\20_自适应工作流引擎\runtime\gpt_mirror_active_url.txt`
> ⚠️ 别再写到 `D:\Work\元智能\runtime\` —— 那是旧的通用 runtime 目录，本项目不用它。

## 闸门清单（★ 本项目特有 · 每次发问前逐条过）

| 闸门 | 断言 | 违反时 |
|---|---|---|
| `mode_gate`（优先级最高 · **三闸**） | ①顶部 `Chat` radio 的 `data-state == "on"`（默认即 Chat）；②**模型 = `ChatGPT 6 Sol`**（Chat「Select model」里显示为 `6`、**默认即选中**；❌ 不许改成 `GPT-5.6 Sol` / `GPT-5.5`）；③pill 闭态 == 契约 `resolved_label`（**2026-10-11 基准 = `High`**） | `silent-risk` → 熔断。**发问前的最后一个动作必须是这个断言通过**；刷新 / 回历史 / 换窗口都会重置回 `Chat` + `Instant`，**没有"刚才切过"这种想当然** |
| `turn_budget` | **一个窗口 ≤24 轮**（2026-09-18 用户修订 12→24；⚠️ 2026-10-11 删掉旧「≤40 轮」——它与 24 冲突且手册 §9.3 全篇无 40）；**每 3 轮必须彻底解决一个任务**（GPT 反问算同窗口）。达到 24 轮 = **先要总结 → 带总结新开**，不是直接新开。但 24 轮不是免死金牌：GPT 一旦出现遗忘 / 混淆早期约定 / 答非所问，不等满轮次，立即走同一条路 | `break`，换新窗口 |
| `history_budget` | 聊天历史 **≤10 条**（2026-09-04 用户从「每 30 删一半」收紧为「保留最近 10 条、删最旧」） | `info`：**Delete 真删**（不可逆，不用 Archive）；列表**顶部=最近、底部=最旧**，**从末尾往上删**到剩 10；批量走脚本循环（逐条手点太慢）；每条定位 `button[data-testid="history-item-<N>-options"]` → 菜单 Delete → 确认框 `[data-testid="delete-conversation-confirm-button"]`。**可执行体 = `scripts/prune_history.js`（默认 dry-run）** |
| `foreground_supervision` | 回复由**主会话前台**监督 | `break`。禁止后台 Bash 任务（`run_in_background`）轮询镜像站 |
| `no_fork` | 不用 fork 子 Agent | `break` |
| `context_pushed` | 上下文已 push GitHub、提示词已列文件路径清单 | `warn` |
| `delivery_readback`（★ 收到回答后的第一个动作） | 三项回读凭证齐：`delivery_id`（CORE 首行）+ `core_tail`（CORE 末行）+ `spec_tail`（SPEC 末行）；判定用 `D:\Work\元智能\runners\verify_delivery.mjs --answer <回答文件>`，凭证存 `D:\Work\元智能\runtime\delivery_nonces.json` | `break`。缺任一项判"材料未完整送达"，本轮结论不采信，也不得据此改代码 |
| `fetch_retry_budget` | 每条链接最多 3 次、间隔 ≥15 秒；若首行交付号命中的是上一轮而尾凭证不符，判为 CDN 滞后读到旧版本，等 10 分钟重跑同一链接 | `warn`；三连败即阻断作答，不换承载、不凭上一轮记忆续答 |
| `shared_tab` | 用自己的 `tab create`，不占他人标签页 | `break` |
| `secret_guard` | 任何 secret / 凭证值不回显、不入仓、不进输出；`financial-security-plan` 永不公开 | `break` |
| `review_gate` | 评审未过 → **零代码改动**；方案拍板后才动仓库 | `break` |

## 禁止事项

- 禁止在 **`Instant` / `Medium` 等非顶档**下提问（横竖白烧一轮）；禁止省略 `mode_gate`
- ❌ **禁止切 `Work` 标签**（接 Codex、本账号不可用，问了必被安全拒绝挡回）；一律留在 `Chat` 标签（郭老师 2026-10-11 裁定）
- ❌ **禁止改模型**：**默认必须 `ChatGPT 6 Sol`**（Chat「Select model」里显示为 `6`、默认即选中）—— 不许改成 `GPT-5.6 Sol` / `GPT-5.5`（郭老师 2026-10-11 明令）
- 禁止用后台任务轮询镜像站状态（看不见的黑箱，必留残次品）
- 禁止 fork 子 Agent 跑镜像站流程（无实时指令流会靠猜，曾编造「用户指示」）
- 禁止复探 DOM / 重编选择器（提速最大杠杆就是"选择器固化 + 照抄"，从打开到发送应在 1 分钟内到位）
- 禁止在执行体里硬编码域名 / 选择器 / 菜单文案 / 到期日 —— 一律读契约
- 禁止在校验点不成立时产出结论（`silent-risk` 比崩溃更危险）
- 禁止 `close` 他人标签页；禁止占用别人的标签（日常 Chrome 是共享的）
- 禁止一次窗口超 24 轮（2026-09-18 用户修订，原 12 轮）或超 3 轮还没解决一个任务
- 禁止**只测首行就宣称整包读到**：200 KB 那个包必须靠尾凭证证明触达末尾，首行只证明摸到了头部
- 禁止在凭证缺失时把对方回答当已送达结论使用（缺项即 `break`，重发或改承载，不许"先按它说的做"）
- 禁止判对方实例退化前不先自证读取侧：长对话离屏节点会被虚拟化清空、末尾还有空占位节点，两类都会把完整回答读成 0 字（先滚到底、再截图）
- 禁止整段拼接 base64 取大文件（必报 `Incorrect padding`）
- **Windows 传参五坑**：`opencli.cmd` 是批处理 → ①多行 JS 传参会炸，必须压成单行或走临时文件；②JS 字符串带 `&` 会被 cmd 当命令分隔，URL 先 base64 再在 JS 内 `atob`+`decodeURIComponent(escape())` 还原，Python 侧用 `subprocess.run(..., shell=False)`；③大文件按 30000 字节分块取回；④**JS 里的 `<` / `>` 也会被 cmd 当重定向**（`for(let i=0;i<n;i++)` 直接 `SyntaxError: Unexpected end of input`）——**最稳解法：整段 JS 先 base64，再 `opencli browser <S> eval "eval(decodeURIComponent(escape(atob('<b64>'))))"` 传入**，一次性规避 `<` `>` `&` 与换行四个坑；⑤**base64 解码必须 UTF-8 安全**：`eval(atob(b64))` 把字节按 **Latin-1** 解，**脚本里的中文字符串字面量会全变乱码**（2026-10-11 实测：`'dry-run：未做任何删除'` → `'dry-runï¼æªå...'`）→ **一律用 `decodeURIComponent(escape(atob(b64)))`**，它不含 `<` `>`，可安全内联

## 验证方式（怎么知道这个 skill 没坏）

1. **跳转性能**（2026-10-11 新基线，取代旧 9.6s/14.4s 口径）：**复用 tab ≤8s / 热启动 ≤20s / 冷启动 ≤28s**（对应调用数 1/2/3；2026-10-11 实测 **4.5s / 18.8s / 22.7s**）。**超预算即 `warn` 并报人**（说明又退回了 `open` / 固定 sleep / 拆 eval 的老路）。
   - 旧基线（9.6s × 1.5 = 14.4s）是**旧 UI（Auto→Extended 两步）**测的，且没算 opencli 每次 ~3.5s 的 node 启动开销，**已作废**；`D:\Work\元智能\20_自适应工作流引擎\docs\runbooks\测试任务-镜像零到Extended计时.md` 仅作历史参考。
2. **闸门有效性**：故意在 `Instant` 档（或切到 `Work` 标签）下走到发送前一步，skill 必须**拒绝发送**并报 `silent-risk`
3. **契约一致性**：`drift.json` 的 `probe_self_test` 必须为 `pass`（用于区分「站点变了」和「探针自己坏了」）
4. **dry-run**：`probe_gpt_mirror_ui.js` 跑完不得留下任何点击 / 输入痕迹（只读指纹）
5. **不打扰验证**：P1 探针运行全程**不启动浏览器**

## 来源

- 契约（**已落盘 · v4 / 9 conditions / 13 gates / status=verified**）：`D:\Work\元智能\20_自适应工作流引擎\contracts\gpt-mirror-extended-review.yaml`
- 操作真源手册：`D:\Work\元智能\20_自适应工作流引擎\docs\runbooks\GPT镜像站送审流程.md`（v1，2026-09-03）
- 交接文档：`D:\Work\元智能\20_自适应工作流引擎\docs\runbooks\GPT镜像站一键交接文档（给执行Agent）.md`
- 固化脚本（**`evalA_jump.js` 仍有效；`evalB_ext.js` 2026-10-10 起整段作废**）：同目录 `scripts\evalA_jump.js` / `evalB_ext.js`
- 记忆条目（`D:\记忆\调度大脑记忆\`）：`流程\workflow_ai_<POOL_NAME>_open.md`、`流程\workflow_gpt_repo_sync.md`、`反馈\feedback_gpt_mirror_account_switch.md`、`反馈\feedback_gpt_mirror_subagent_flow.md`、`反馈\feedback_gpt_rounds_discipline.md`、`反馈\feedback_mirror_send_speed.md`、`反馈\feedback_mirror_chat_history.md`、`反馈\feedback_mirror_extend_for_architecture.md`、`反馈\feedback_mirror_as_generator_download.md`、`反馈\feedback_mirror_image_gen_slow_works.md`、`反馈\feedback_mirror_image_renders_chinese.md`、`反馈\feedback_gpt_context_github.md`、`反馈\feedback_fork_forbidden.md`、`反馈\feedback_ask_user_only_urgent.md`、`教训\error_lessons.md`（教训①②③④⑤⑦）
- 完整盘点与失效证据：`D:\Work\元智能\20_自适应工作流引擎\docs\02-镜像站试点盘点.md`
- **2026-10-10 站点改版实测**：证据截图 `D:\临时文件夹\_mirror_{shot1,work,workmenu,astra_max,adv,v31_models}.png`；观察流水见 `D:\临时文件夹\.workbuddy-ai\memory\2026-10-10.md`；契约已同步（`reasoning_mode` / `work_mode` / `mode_toggle`）
- **模型与额度使用指南**：`D:\Work\元智能\20_自适应工作流引擎\docs\runbooks\GPT镜像站Work模式模型与额度指南.md`（2026-10-10 实测）
