# Kimi WebBridge 在 Windows 上的守护进程生命周期与小红书点点输入注入

- **类型**：workaround / pitfall
- **触发信号**：
  1. Windows 下使用 `kimi-webbridge` 控制浏览器时，执行 `kimi-webbridge.exe start` 提示成功但在随后状态检查中报 stale PID 或连接拒绝（127.0.0.1:10086 无法连接）；
  2. 在小红书点点 AI 网页版（`https://www.xiaohongshu.com/ai_chat`）自动化填充提问并提交无反应；
  3. 安卓/小米澎湃 OS (HyperOS) 通过 ADB `input text` 输入外链或英文时被输入法拦截成拼音候选条。
- **结论与正解**：
  1. **Kimi WebBridge 守护进程**：在 Windows 脚本中管理守护进程时，若常规后台启动因父进程退出而消亡，应使用 `kimi-webbridge.exe start --foreground` 配合受控后台任务运行，即可持久监听 10086 端口；首次安装或环境不完整时，必须执行官方安装脚本 `irm https://cdn.kimi.com/webbridge/install.ps1 | iex`。
  2. **点点网页版自动化**：小红书点点网页端为 Vue 3 构建，对 `<textarea>` 需使用 `fill` 接口或原生属性 setter 触发 `input` 与 `change` 事件；提交触发可派发 `Enter` 键 `KeyboardEvent`（`keyCode: 13, bubbles: true`）并触发 `.bottom-box-right-submit-button` 的点击事件。
  3. **外链解析能力**：点点 AI 网页版传入带 `xsec_token` 的小红书笔记链接（`https://www.xiaohongshu.com/explore/...`）可被服务端深度理解并生成四步拆解。
  4. **安卓输入法避坑**：向手机通过 ADB 自动化发送长链接或中文时，严禁依赖系统原生拼音输入法处理 `adb shell input text`，必须安装免界面的 `ADBKeyBoard` 或走剪贴板注入。
- **错误样本/反面例子**：
  - `& kimi-webbridge.exe start` 后立即关闭调用它的 PowerShell 进程导致 daemon 秒退。
  - 直接对点点页面的 textarea 赋值 `ta.value = "..."` 而未派发 Vue 事件，导致提交按钮保持禁用状态。
  - 在 HyperOS 上未切换英文输入法即执行 `adb shell input text hello`，被搜狗/百度输入法识别为 `eh'llo` 并停留在候选词框。
- **适用范围**：小红书点赞分析子项目 / Kimi WebBridge 浏览器自动化 / 全局 Windows
- **记录时间**：2026-09-23
