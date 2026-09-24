# =====================================================================
#  P1 网络探针（只读 HTTP · 不开浏览器 · 零打扰）
# ---------------------------------------------------------------------
#  契约真源 : D:\Work\自适应工作流引擎\contracts\gpt-mirror-extended-review.yaml
#  产物     : ..\runtime\gpt-mirror.runtime.json （全量事实）
#             ..\runtime\gpt-mirror.drift.json   （偏差投影）
#  用法     : powershell -ExecutionPolicy Bypass -File probe_gpt_mirror.ps1
#             可选 -Contract <路径>  -Verbose
#
#  铁律（照搬 ai-platform 三件套 + 本仓 docs\00-项目总览.md §二）
#   1. 只读：全程只用 GET，不点击、不登录、不提交、不修改被测站点任何状态
#   2. 零字面量：域名 / 卡号 / 正则 / 阈值 / 代理全部从契约读取；
#      本脚本内**不得**出现任何硬编码的外部常量（违者即退化为 evalB_ext.js）
#   3. 产物只由本脚本写，禁止手改
#   4. probe_self_test 每次必记 —— 用于区分「站点变了」与「探针自己坏了／本机没网」
#   5. 校验点不成立时**不许产出结论**（silent-risk 按 break 处理）
#
#  退出码：0=无 break（可继续）  2=有 break（熔断，勿执行送审）
#          3=自检失败（契约缺失/本机无网）——本次结果不可采信，不要当 drift 用
# =====================================================================
param(
    [string]$Contract = 'D:\Work\自适应工作流引擎\contracts\gpt-mirror-extended-review.yaml',
    [switch]$Verbose2
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RuntimeDir = Join-Path (Split-Path -Parent $ScriptDir) 'runtime'
$NewLine = [Environment]::NewLine

function Log([string]$m) { Write-Host $m; if ($Verbose2) { Write-Verbose $m } }

# ---------------------------------------------------------------------
# 一、契约读取：极简 YAML 子集解析（缩进 + 列表 + 标量），失败即自检失败
# ---------------------------------------------------------------------
function Read-Contract {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { throw "契约文件不存在：$Path" }

    $flat = @{}
    $stack = New-Object System.Collections.ArrayList   # 每项 = @{ indent; key }
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8

    foreach ($raw in $lines) {
        if ($raw -match '^\s*#') { continue }
        if ($raw.Trim() -eq '') { continue }

        $indent = ($raw.Length - $raw.TrimStart(' ').Length)
        $line = $raw.Trim()

        # 去掉行尾注释（不处理引号内含 # 的情况——契约里没这么写）
        if ($line -match '^(.*?)\s+#\s.*$') { $line = $Matches[1].Trim() }

        # 弹出比当前缩进更深或相同的层级
        while ($stack.Count -gt 0 -and $stack[$stack.Count - 1].indent -ge $indent) {
            $stack.RemoveAt($stack.Count - 1)
        }

        $prefix = ($stack | ForEach-Object { $_.key }) -join '.'

        if ($line -match '^-\s*(.*)$') {
            # 列表项：挂到父键下，索引自增
            $parentKey = if ($stack.Count -gt 0) { ($stack | ForEach-Object { $_.key }) -join '.' } else { '' }
            $idxKey = "$parentKey.__count"
            $i = 0
            if ($flat.ContainsKey($idxKey)) { $i = [int]$flat[$idxKey] }
            $flat[$idxKey] = ($i + 1).ToString()
            $val = $Matches[1].Trim()
            if ($val -match '^(.*?):\s*(.+)$') {
                # 形如 - {label: "x", weight: 100} 或 - label: x，本探针不消费，跳过内联展开
                $flat["$parentKey.$i"] = $val.Trim('"').Trim("'")
            } elseif ($val -match '^\[(.*)\]$') {
                $flat["$parentKey.$i"] = $val
            } else {
                $flat["$parentKey.$i"] = $val.Trim('"').Trim("'")
            }
            continue
        }

        if ($line -match '^([A-Za-z_][\w\-]*)\s*:\s*(.*)$') {
            $k = $Matches[1]; $v = $Matches[2].Trim()
            [void]$stack.Add(@{ indent = $indent; key = $k })
            $full = if ($prefix) { "$prefix.$k" } else { $k }
            $flat[$full] = $v.Trim('"').Trim("'")
        }
    }
    return $flat
}

function Get-Cfg {
    param($Flat, [string]$Key)
    if ($Flat.ContainsKey($Key)) { return $Flat[$Key] } else { return $null }
}

function Get-CfgList {
    param($Flat, [string]$Key)
    $out = @()
    $i = 0
    while ($true) {
        $v = Get-Cfg $Flat "$Key.$i"
        if ($null -eq $v) { break }
        $out += $v; $i++
    }
    return $out
}

function Get-Required {
    param($Flat, [string]$Key)
    $v = Get-Cfg $Flat $Key
    if ($null -eq $v -or $v -eq '') { throw "契约缺少必需字段：$Key" }
    return $v
}

# ---------------------------------------------------------------------
# 二、只读 HTTP GET：先按契约代理，失败再直连，记录哪条通
# ---------------------------------------------------------------------
function Invoke-Readonly {
    param([string]$Url, [string]$Proxy, [int]$TimeoutSec = 20)

    $attempts = @()
    $result = $null

    $tries = @()
    if ($Proxy) { $tries += @{ via = 'proxy'; p = $Proxy } }
    $tries += @{ via = 'direct'; p = $null }

    foreach ($t in $tries) {
        $rec = @{ via = $t.via; proxy = $t.p; ok = $false; status = $null; length = 0; error = $null; kind = $null }
        try {
            $params = @{ Uri = $Url; UseBasicParsing = $true; TimeoutSec = $TimeoutSec; Method = 'Get' }
            if ($t.p) { $params['Proxy'] = $t.p }
            $r = Invoke-WebRequest @params
            $rec.ok = $true
            $rec.status = [int]$r.StatusCode
            $body = $r.Content
            if ($null -eq $body) { $body = '' }
            $rec.length = $body.Length
            $result = @{ ok = $true; status = $rec.status; body = $body; via = $t.via; attempts = ($attempts + $rec) }
            $attempts += $rec
            break
        } catch [System.Net.WebException] {
            $resp = $_.Exception.Response
            if ($resp) {
                $rec.status = [int]$resp.StatusCode
                $rec.kind = 'http_error'      # 站点给了应答 → 属真实站点信号
                try {
                    $sr = New-Object IO.StreamReader($resp.GetResponseStream())
                    $b = $sr.ReadToEnd(); $rec.length = $b.Length
                    $rec.ok = $true
                    $result = @{ ok = $true; status = $rec.status; body = $b; via = $t.via; attempts = ($attempts + $rec) }
                    $attempts += $rec
                    break
                } catch { $rec.error = $_.Exception.Message }
            } else {
                $rec.kind = 'network_error'   # 连不上 → 本机/代理问题，不是站点变了
                $rec.error = $_.Exception.Message
            }
        } catch {
            $rec.kind = 'network_error'
            $rec.error = $_.Exception.Message
        }
        $attempts += $rec
    }

    if ($null -eq $result) {
        $kind = ($attempts | Where-Object { $_.kind } | Select-Object -First 1).kind
        if (-not $kind) { $kind = 'network_error' }
        return @{ ok = $false; status = $null; body = ''; via = 'none'; attempts = $attempts; kind = $kind }
    }
    $result['kind'] = if ($result.status -ge 200 -and $result.status -lt 300) { 'ok' } else { 'http_error' }
    return $result
}

# ---------------------------------------------------------------------
# 三、微型断言求值器：只认契约里用得到的形态，认不出就报错（不静默放行）
# ---------------------------------------------------------------------
function Test-Assertion {
    param([string]$Expr, $Obj)
    if ($Expr -match '^\s*([A-Za-z_][\w\.]*)\s*(==|!=)\s*(.+?)\s*$') {
        $field = $Matches[1]; $op = $Matches[2]; $wantRaw = $Matches[3].Trim().Trim('"').Trim("'")
        $actual = $Obj          # ★ 初值必须是根对象；曾误写 $null 导致首段字段永远取不到（2026-09-24 修复）
        foreach ($seg in $field.Split('.')) {
            if ($actual -is [System.Management.Automation.PSCustomObject] -or $actual -is [hashtable]) {
                $actual = $actual.$seg
            } else { $actual = $null; break }
        }
        $want = switch ($wantRaw.ToLower()) { 'true' { $true } 'false' { $false } 'null' { $null } default { $wantRaw } }
        if ($actual -is [string]) {
            if ($want -is [bool]) { $actual = ($actual.ToLower() -eq 'true') }
        }
        if ($op -eq '==') { return ($actual -eq $want) } else { return ($actual -ne $want) }
    }
    throw "无法解析契约断言（拒绝静默放行）：$Expr"
}

# =====================================================================
#  主流程
# =====================================================================
$sw = [Diagnostics.Stopwatch]::StartNew()
$probedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
$drift = @()
$selfTest = @{ contract_ok = $false; required_fields_ok = $false; network_reachable = $false; notes = @() }
$exitCode = 0

Log "[P1] 契约：$Contract"

# ---- 3.1 读契约 ----
try {
    $C = Read-Contract $Contract
    $selfTest.contract_ok = $true
    Log "[P1] 契约解析成功，扁平键 $($C.Count) 个"
} catch {
    Write-Host "[SELF-TEST FAIL] 契约不可读：$($_.Exception.Message)"
    $drift += @{ condition = 'contract'; level = 'break'; note = $_.Exception.Message; action = 'circuit_break' }
    $body = @{ probed_at = $probedAt; contract = $Contract; probe_self_test = 'fail'; stage = 'contract_parse'; error = $_.Exception.Message }
    if (-not (Test-Path $RuntimeDir)) { New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null }
    ($body | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath (Join-Path $RuntimeDir 'gpt-mirror.runtime.json') -Encoding UTF8
    exit 3
}

# ---- 3.2 取契约字段（缺任一必需字段 → 自检失败，不产出 drift 结论）----
try {
    $poolUrls   = Get-CfgList $C 'conditions.account_pool.urls'
    $poolProxy  = Get-Cfg $C 'conditions.account_pool.proxy'
    $poolHealth = Get-Required $C 'conditions.account_pool.health_regex'
    $poolFail   = Get-Cfg $C 'conditions.account_pool.on_fail'

    $cardEndpoint   = Get-Required $C 'conditions.active_card.endpoint'
    $cardExpect     = Get-Required $C 'conditions.active_card.expect'
    $cardMinActive  = [int](Get-Required $C 'conditions.active_card.min_active')
    $cardFail       = Get-Cfg $C 'conditions.active_card.on_fail'
    $discPatterns   = Get-CfgList $C 'conditions.active_card.card_id_discovery.primary.patterns'
    $fbPrefix       = Get-Cfg $C 'conditions.active_card.card_id_discovery.fallback.prefix'
    $fbRange        = Get-Cfg $C 'conditions.active_card.card_id_discovery.fallback.range'
    $fbMax          = Get-Cfg $C 'conditions.active_card.card_id_discovery.fallback.max_probes'
    $discFailLevel  = Get-Cfg $C 'conditions.active_card.card_id_discovery.on_discovery_fail'

    $expValue   = Get-Required $C 'conditions.membership_expiry.value'
    $expWarn    = [int](Get-Required $C 'conditions.membership_expiry.warn_before_days')
    $expFail    = Get-Cfg $C 'conditions.membership_expiry.on_fail'

    if ($poolUrls.Count -eq 0) { throw '契约 conditions.account_pool.urls 为空列表' }
    $selfTest.required_fields_ok = $true
    Log "[P1] 必需字段齐全（pool=$($poolUrls.Count) 个URL，patterns=$($discPatterns.Count) 条）"
} catch {
    Write-Host "[SELF-TEST FAIL] 契约字段不全：$($_.Exception.Message)"
    $selfTest.notes += $_.Exception.Message
    $drift += @{ condition = 'contract_schema'; level = 'break'; note = $_.Exception.Message; action = 'circuit_break' }
    $summary = @{ info = 0; warn = 0; break = 1; silent_risk = 0 }
    if (-not (Test-Path $RuntimeDir)) { New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null }
    @{ probed_at = $probedAt; contract = $Contract; probe_self_test = 'fail'; fields = $null; drift = $drift; summary = $summary } |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $RuntimeDir 'gpt-mirror.runtime.json') -Encoding UTF8
    @{ probed_at = $probedAt; contract_version = (Get-Cfg $C 'contract_version'); probe_self_test = 'fail'; items = $drift; summary = $summary } |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $RuntimeDir 'gpt-mirror.drift.json') -Encoding UTF8
    exit 3
}

# ---- 3.3 探账号池（只读 GET）----
$poolResults = @()
$poolHtml = ''
foreach ($u in $poolUrls) {
    Log "[P1] GET 账号池：$u"
    $r = Invoke-Readonly -Url $u -Proxy $poolProxy
    $matched = $false
    if ($r.ok -and $r.body) {
        try { $matched = [bool]([regex]::IsMatch($r.body, $poolHealth)) } catch { $selfTest.notes += "health_regex 非法：$($_.Exception.Message)" }
        if ($r.status -ge 200 -and $r.status -lt 300) { $poolHtml = $r.body; $selfTest.network_reachable = $true }
    } elseif ($r.kind -eq 'http_error') {
        $selfTest.network_reachable = $true   # 站点有应答，说明网络通，是站点侧信号
    }

    $item = [ordered]@{
        url = $u; ok = $r.ok; status = $r.status; via = $r.via; kind = $r.kind
        bytes = $r.length; health_regex_matched = $matched
        attempts = @($r.attempts | ForEach-Object { [ordered]@{ via = $_.via; ok = $_.ok; status = $_.status; kind = $_.kind; error = $_.error } })
    }
    $poolResults += $item

    if ($r.ok -and $r.status -ge 200 -and $r.status -lt 300 -and $matched) {
        $drift += [ordered]@{ condition = 'account_pool'; level = 'info'; expected = "2xx 且匹配 $poolHealth"; actual = "$($r.status) matched=$matched"; action = 'none' }
    } elseif ($r.ok -and $r.status -ge 200 -and $r.status -lt 300 -and -not $matched) {
        $drift += [ordered]@{ condition = 'account_pool'; level = 'warn'
            note = "页面可达但未匹配健康特征 $poolHealth —— 前端可能已改版（2026-08-27 曾整体迁移过）"
            actual = "status=$($r.status) bytes=$($r.length)"; action = 'verify_ui_and_update_contract' }
    } elseif (-not $r.ok) {
        if ($r.kind -eq 'network_error') {
            $drift += [ordered]@{ condition = 'account_pool'; level = 'break'
                note = "本机连不上（代理 $poolProxy 与直连均失败）—— 归类为本机/代理问题，**不代表站点挂了**"
                error = ($r.attempts | ForEach-Object { $_.error }) -join ' | '; action = 'check_local_network_then_reprobe' }
        } else {
            $drift += [ordered]@{ condition = 'account_pool'; level = $poolFail
                note = "站点返回 HTTP $($r.status)"; actual = "status=$($r.status)"; action = 'circuit_break' }
        }
    }
}

# ---- 3.4 发现 carid（先从 HTML 提取，提不到再有限枚举）----
$carIds = @()
$discMethod = 'none'
foreach ($p in $discPatterns) {
    if (-not $poolHtml) { break }
    try {
        $ms = [regex]::Matches($poolHtml, $p)
        foreach ($m in $ms) {
            $v = if ($m.Groups.Count -gt 1 -and $m.Groups[1].Value) { $m.Groups[1].Value } else { $m.Value }
            if ($v -and ($carIds -notcontains $v)) { $carIds += $v }
        }
        if ($carIds.Count -gt 0) { $discMethod = "html_regex:$p"; break }
    } catch { $selfTest.notes += "pattern 非法 `"$p`"：$($_.Exception.Message)" }
}

# ---- 3.4b explicit_list：契约内历史活跃卡号，优先于盲枚举验证 ----
$explicitRaw = Get-Cfg $C 'conditions.active_card.card_id_discovery.explicit_list.cards'
if ($explicitRaw) {
    $expl = $explicitRaw.Trim('[', ']') -split ',' | ForEach-Object { $_.Trim().Trim('"').Trim("'") } | Where-Object { $_ }
    foreach ($cid in $expl) { if ($carIds -notcontains $cid) { $carIds += $cid } }
    if ($expl.Count -gt 0) {
        $discMethod = if ($discMethod -eq 'none') { 'explicit_list' } else { "$discMethod+explicit_list" }
        Log "[P1] explicit_list 追加 $($expl.Count) 个候选（source 见契约）"
    }
}

if ($carIds.Count -eq 0 -and $fbPrefix -and $fbRange -and $fbMax) {
    $rng = $fbRange.Trim('[', ']') -split ','
    if ($rng.Count -eq 2) {
        $lo = [int]$rng[0].Trim(); $hi = [int]$rng[1].Trim(); $maxP = [int]$fbMax
        $n = 0
        for ($i = $lo; $i -le $hi -and $n -lt $maxP; $i++) { $carIds += "$fbPrefix$i"; $n++ }
        $discMethod = "enumerate:$fbPrefix$lo..($fbPrefix$hi,max=$maxP)"
    }
}

Log "[P1] carid 发现方式：$discMethod（候选 $($carIds.Count) 个）"

if ($carIds.Count -eq 0) {
    $lvl = if ($discFailLevel) { $discFailLevel } else { 'warn' }
    $drift += [ordered]@{ condition = 'active_card.discovery'; level = $lvl
        note = '两条发现路径都没拿到 carid（页面提不到且无枚举兜底）—— 可能是前端改版，也可能是本机无网；请配合 account_pool 项判断'
        action = 'manual_inspect_then_extend_contract_patterns' }
}

# ---- 3.5 探健康徽章（只读 GET，逐个）----
$cardResults = @()
$activeCount = 0
foreach ($cid in $carIds) {
    $ep = $cardEndpoint.Replace('{card_id}', $cid)
    $r = Invoke-Readonly -Url $ep -Proxy $poolProxy -TimeoutSec 15
    $obj = $null; $healthy = $false; $label = $null; $parseErr = $null
    if ($r.ok -and $r.body) {
        try {
            $obj = $r.body | ConvertFrom-Json
            $healthy = Test-Assertion -Expr $cardExpect -Obj $obj
            if ($obj.PSObject.Properties.Name -contains 'label') { $label = $obj.label }
        } catch { $parseErr = $_.Exception.Message }
    }
    if ($healthy) { $activeCount++ }
    $cardResults += [ordered]@{
        card_id = $cid; reachable = $r.ok; status = $r.status; kind = $r.kind; via = $r.via
        healthy = $healthy; label = $label; raw = if ($r.body.Length -gt 300) { $r.body.Substring(0, 300) + '…' } else { $r.body }
        parse_error = $parseErr
    }
}

if ($carIds.Count -gt 0) {
    $anyReachable = ($cardResults | Where-Object { $_.reachable }).Count
    if ($anyReachable -eq 0) {
        $drift += [ordered]@{ condition = 'active_card'; level = 'break'
            note = "健康徽章端点全部不可达（探了 $anyReachable/$($carIds.Count)）—— 若 account_pool 同样连不上，则属本机网络问题而非站点问题"
            action = 'distinguish_local_network_vs_site' }
    } elseif ($activeCount -lt $cardMinActive) {
        $drift += [ordered]@{ condition = 'active_card'; level = $cardFail
            expected = "min_active=$cardMinActive"; actual = "active=$activeCount / probed=$($carIds.Count)"
            note = '活跃卡不足：账号可能受限或会员到期 —— 熔断，不启动浏览器，不烧轮次'
            action = 'circuit_break_and_switch_account' }
    } else {
        $drift += [ordered]@{ condition = 'active_card'; level = 'info'
            expected = "min_active=$cardMinActive"; actual = "active=$activeCount / probed=$($carIds.Count)"
            labels = (($cardResults | Where-Object { $_.healthy } | ForEach-Object { $_.label }) -join ', '); action = 'none' }
    }
}

# ---- 3.6 会员余日（纯本地计算，无需联网）----
$expDate = $null
try { $expDate = [datetime]::ParseExact($expValue, 'yyyy-MM-dd', $null) } catch { $selfTest.notes += "membership_expiry.value 非法日期：$expValue" }
if ($expDate) {
    $days = [math]::Floor(($expDate - (Get-Date)).TotalDays)
    if ($days -lt 0) {
        # X1：插值子表达式内的一元负号会触发 PS 解析歧义（Missing type name after '['），先算成标量再插值
        $abs = [math]::Abs($days)
        $drift += [ordered]@{ condition = 'membership_expiry'; level = $expFail
            expected = ">= 0 天"; actual = "$days 天（已过期 $abs 天）"
            note = "会员已于 $expValue 到期 —— 账号池预计全红，整条送审链路应熔断"
            action = 'circuit_break_and_notify_user' }
    } elseif ($days -le $expWarn) {
        $drift += [ordered]@{ condition = 'membership_expiry'; level = 'warn'
            expected = "> $expWarn 天"; actual = "$days 天"; expiry = $expValue
            note = "会员 $days 天后到期（阈值 $expWarn 天）—— 已有 Loomy 提醒任务，此处同步升 warn"
            action = 'report_and_prepare_fallback_channel' }
    } else {
        $drift += [ordered]@{ condition = 'membership_expiry'; level = 'info'
            expected = "> $expWarn 天"; actual = "$days 天"; expiry = $expValue
            note = '未进入预警窗口，仅记录倒计时'; action = 'none' }
    }
} else {
    $drift += [ordered]@{ condition = 'membership_expiry'; level = 'break'
        note = "契约里 expiry 值无法解析为日期，无法判断余日 —— 拒绝给出结论（silent-risk）"
        actual = $expValue; action = 'fix_contract' }
}

# ---- 3.7 自检判定 ----
$selfTestPass = ($selfTest.contract_ok -and $selfTest.required_fields_ok -and ($selfTest.network_reachable -or ($drift | Where-Object { $_.level -eq 'info' }).Count -gt 0))
$selfTestVerdict = if ($selfTestPass) { 'pass' } else { 'fail' }
if (-not $selfTest.network_reachable) {
    $selfTest.notes += '本机未成功访问任何被测地址（代理与直连均失败）——本次 drift 中的站点类判断不可采信'
}

# ---- 3.8 汇总与落盘 ----
$summary = [ordered]@{
    info = @($drift | Where-Object { $_.level -eq 'info' }).Count
    warn = @($drift | Where-Object { $_.level -eq 'warn' }).Count
    break = @($drift | Where-Object { $_.level -eq 'break' }).Count
    silent_risk = @($drift | Where-Object { $_.level -eq 'silent-risk' }).Count
}
$sw.Stop()

$runtime = [ordered]@{
    probed_at = $probedAt
    contract = $Contract
    contract_version = (Get-Cfg $C 'contract_version')
    workflow_id = (Get-Cfg $C 'workflow_id')
    probe = 'P1_http_only'
    browser_opened = $false
    readonly = $true
    elapsed_ms = [int]$sw.ElapsedMilliseconds
    probe_self_test = $selfTestVerdict
    self_test_detail = $selfTest
    carid_discovery = [ordered]@{ method = $discMethod; candidates = $carIds; active = $activeCount }
    account_pool = $poolResults
    active_card = $cardResults
}

$driftDoc = [ordered]@{
    probed_at = $probedAt
    contract_version = (Get-Cfg $C 'contract_version')
    probe_self_test = $selfTestVerdict
    self_test_notes = $selfTest.notes
    browser_opened = $false
    items = $drift
    summary = $summary
}

if (-not (Test-Path $RuntimeDir)) { New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null }
($runtime | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $RuntimeDir 'gpt-mirror.runtime.json') -Encoding UTF8
($driftDoc | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath (Join-Path $RuntimeDir 'gpt-mirror.drift.json') -Encoding UTF8

Log ""
Log ("[P1] 自检={0}  info={1} warn={2} break={3} silent-risk={4}  耗时 {5}ms" -f $selfTestVerdict, $summary.info, $summary.warn, $summary['break'], $summary.silent_risk, $runtime.elapsed_ms)
foreach ($d in $drift) { Log ("  - [{0}] {1}: {2}" -f $d.level, $d.condition, $(if ($d.note) { $d.note } else { "$($d.expected) → $($d.actual)" })) }
Log "[P1] 产物：$RuntimeDir\gpt-mirror.runtime.json / gpt-mirror.drift.json"

if (-not $selfTestPass) { exit 3 }
if ($summary['break'] -gt 0 -or $summary.silent_risk -gt 0) { exit 2 } else { exit 0 }
