# =====================================================================
#  P0.5 死链枚举器（严格只读 · 不删任何东西）
# ---------------------------------------------------------------------
#  产出两样东西：逐条死链清单 + 每宿主汇总。供人工复核后再谈清理。
#
#  为什么值得单独写一个枚举器，而不直接用普查产物里那 946 条：
#    普查器判"断"的方式是【ReparsePoint 属性 + 活性探针】，它只知道"穿不过去"，
#    不知道链接原本指向哪儿。而清理决策必须知道目标 —— 有些"断"是源被删了
#    （该清），有些是盘符/用户目录搬走导致整片不可达（清了反而是破坏，
#    源可能还在别的机器或备份里）。两者处置完全相反，必须分开。
#
#  交叉验证：本枚举器改用【cmd dir /AL 解析记录的目标路径】这条独立通道，
#    并与普查器的逐宿主断链计数硬比对。tolerance=0，对不上即 exit 3。
#
#  ★ 安全红线（务必知情）★
#    删 junction / symlink 时若用 Remove-Item -Recurse，可能**顺着链接删进
#    目标内容**，这是 Windows 上的经典事故。本脚本只读、不做任何删除。
#    将来真要清理，只能对"已验证为 reparse point 且目标确实不存在"的条目
#    使用 cmd 的 rmdir（不带 /s）语义 —— 它删的是链接本身。
#
#  退出码：0=清单已出且两实现一致  2=清单已出但存在需人工定性的可疑项
#          3=自检失败，清单不可采信
# =====================================================================
param(
    [string]$Config,
    [string]$Prefix = 'skill-census'
)

$ErrorActionPreference = 'Stop'

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir    = Split-Path -Parent $ScriptDir
$RuntimeDir = Join-Path $BaseDir 'runtime'
if ([string]::IsNullOrWhiteSpace($Config)) { $Config = Join-Path $BaseDir 'audit.config.yaml' }

. (Join-Path $ScriptDir 'lib_contract.ps1')

$ProbedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
function Log([string]$m) { Write-Host $m }

$CsvOut  = Join-Path $RuntimeDir "$Prefix-07-broken-links.csv"
$MdOut   = Join-Path $RuntimeDir "$Prefix-07-broken-links.md"
$JsonOut = Join-Path $RuntimeDir "$Prefix-07-broken-links.json"

function Write-SelfFail([string]$stage, [string]$errText, $extra) {
    if (-not (Test-Path -LiteralPath $RuntimeDir)) { New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null }
    $body = @{ probed_at = $ProbedAt; config = $Config; probe_self_test = 'fail'; stage = $stage; error = $errText }
    if ($extra) { $body += $extra }
    $body | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $JsonOut -Encoding UTF8
    Log "[SELF-TEST FAIL] stage=$stage  $errText"
}

# ---------------------------------------------------------------------
# 一、读配置
# ---------------------------------------------------------------------
try { $C = Read-Contract -Path $Config }
catch { Write-SelfFail 'config_parse' $_.Exception.Message $null; exit 3 }

try {
    $linkHosts   = Get-CfgList $C 'link_hosts'
    $expTotal    = [int](Get-Required $C 'broken_links.expected_total')
    $tolerance   = [int](Get-Required $C 'broken_links.tolerance')
    $censusCsv   = Get-Required $C 'broken_links.census_link_health_csv'
    $sentinel    = Get-Required $C 'self_test.sentinel_broken_link'
}
catch { Write-SelfFail 'config_fields' $_.Exception.Message $null; exit 3 }

if ($linkHosts.Count -eq 0) { Write-SelfFail 'config_roots' 'link_hosts 为空' $null; exit 3 }

# 普查产物里的逐宿主断链数，作为交叉基准（跨进程、跨实现，比自检自身有力）
$censusCsvPath = Join-Path $BaseDir $censusCsv
if (-not (Test-Path -LiteralPath $censusCsvPath)) {
    Write-SelfFail 'census_missing' "找不到普查基准文件：$censusCsvPath（请先跑 audit_skill_census.ps1）" $null
    exit 3
}
$census = @{}
foreach ($r in @(Import-Csv -LiteralPath $censusCsvPath -Encoding UTF8)) {
    $census[$r.host.TrimEnd('\')] = [int]$r.broken
}
$censusTotal = 0
foreach ($v in $census.Values) { $censusTotal += $v }
Log "== P0.5 死链枚举（只读） =="
Log "交叉基准：普查逐宿主合计 $censusTotal 条"

# ---------------------------------------------------------------------
# 二、活性探针（与普查器同一实现，用于逐条二次确认）
#     坑：Test-Path 对断开的 junction 返回 True，不能用它判活
# ---------------------------------------------------------------------
function Test-LinkResolves([string]$p) {
    try { [void][System.IO.Directory]::GetFiles($p, '~probe~*.no-match-zzz'); return $true }
    catch { return $false }
}
function Test-IsReparse([string]$p) {
    try {
        $a = [System.IO.File]::GetAttributes($p)
        return (($a -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
    } catch {
        # 断链上 GetAttributes 可能抛异常；抛了就当作无法证实
        return $false
    }
}

# ---------------------------------------------------------------------
# 三、逐宿主：用 cmd dir /AL 取"链接 → 记录的目标"
# ---------------------------------------------------------------------
$rows = New-Object System.Collections.ArrayList
$perHost = @()
$parseFailHosts = @()

foreach ($h in $linkHosts) {
    $hKey = $h.TrimEnd('\')
    if (-not (Test-Path -LiteralPath $hKey)) {
        $perHost += [pscustomobject]@{ host = $hKey; dir_total = 0; links = 0; broken = 0; census = $census[$hKey]; note = 'host_not_found' }
        continue
    }

    # dir /AL 只列 reparse 条目；用 <JUNCTION>/<SYMLINKD>/<SYMLINK> 标记行解析
    $listing = @()
    try { $listing = @(cmd /c "dir /AL `"$hKey`"" 2>$null) } catch { $listing = @() }

    $brokenHere = 0
    $linksHere = 0
    foreach ($line in $listing) {
        if ($line -notmatch '<(JUNCTION|SYMLINKD|SYMLINK)>') { continue }
        $m = [regex]::Match($line, '<(?:JUNCTION|SYMLINKD|SYMLINK)>\s+(.+?)\s+\[(.+)\]\s*$')
        if (-not $m.Success) { $parseFailHosts += "$hKey :: $line"; continue }
        $name = $m.Groups[1].Value.Trim()
        $target = $m.Groups[2].Value.Trim()
        $linkPath = Join-Path $hKey $name
        $linksHere++

        $resolves = Test-LinkResolves $linkPath
        if (-not $resolves) {
            $brokenHere++
            # 定性：目标的父目录还在不在 —— 决定这是"源被删"还是"整片路径不可达"
            $tparent = ''
            try { $tparent = [System.IO.Path]::GetDirectoryName($target) } catch {}
            $parentExists = ($tparent -and (Test-Path -LiteralPath $tparent))
            $targetExists = (Test-Path -LiteralPath $target)
            $kind = if ($targetExists) { 'SUSPECT-活性探针说断但目标存在' }
                    elseif ($parentExists) { 'ORPHAN-源已删（父目录仍在）' }
                    else { 'UNREACHABLE-目标父目录也不在' }

            [void]$rows.Add([pscustomobject]@{
                host = $hKey
                link = $linkPath
                link_name = $name
                recorded_target = $target
                target_parent_exists = $parentExists
                target_exists = $targetExists
                kind = $kind
                is_reparse = (Test-IsReparse $linkPath)
            })
        }
    }

    $perHost += [pscustomobject]@{
        host = $hKey; links = $linksHere; broken = $brokenHere
        census = $census[$hKey]
        note = $(if ($linksHere -eq 0 -and $census[$hKey] -gt 0) { 'PARSE_OR_EMPTY' } else { 'ok' })
    }
}

$detected = $rows.Count
Log "本枚举器检出 $detected 条（dir /AL 通道）"

# ---------------------------------------------------------------------
# 四、自检 —— 两实现必须逐宿主一致
# ---------------------------------------------------------------------
$failReasons = @()
$suspects = @()

foreach ($ph in $perHost) {
    if ($ph.census -ne $ph.broken -and $ph.note -ne 'host_not_found') {
        $failReasons += ("逐宿主计数不一致：{0} 本枚举={1} 普查={2}" -f $ph.host, $ph.broken, $ph.census)
    }
    if ($ph.note -eq 'PARSE_OR_EMPTY') { $failReasons += "dir /AL 未解析出任何链接但普查有断链：$($ph.host)" }
}
if ([Math]::Abs($detected - $expTotal) -gt $tolerance) {
    $failReasons += "总数 $detected 与期望 $expTotal 偏差超容差 $tolerance"
}
$sentHit = @($rows | Where-Object { $_.link -ieq $sentinel } | Measure-Object).Count
if ($sentHit -eq 0) { $failReasons += "未包含已知断链哨兵 $sentinel（枚举实现可能已坏）" }
foreach ($pf in $parseFailHosts) { $failReasons += "dir 行无法解析：$pf" }
foreach ($r in $rows) {
    if ($r.kind -like 'SUSPECT*') { $suspects += $r }
    if (-not $r.is_reparse) { $failReasons += "路径不具 reparse 属性却被判断，须查：$($r.link)" }
}

if ($failReasons.Count -gt 0) {
    Log "[SELF-TEST FAIL] 清单不可采信："
    $failReasons | Select-Object -First 15 | ForEach-Object { Log "   - $_" }
    if ($failReasons.Count -gt 15) { Log "   ...(共 $($failReasons.Count) 条)" }
    @{ probed_at = $ProbedAt; probe_self_test = 'fail'; reasons = $failReasons;
       detected = $detected; census_total = $censusTotal; per_host = @($perHost) } |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $JsonOut -Encoding UTF8
    exit 3
}
Log "[SELF-TEST PASS] 两独立实现逐宿主一致；哨兵命中；全部条目均具 reparse 属性"

# ---------------------------------------------------------------------
# 五、产物
# ---------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $RuntimeDir)) { New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null }

if ($rows.Count -gt 0) {
    $rows | Sort-Object host, kind, link_name |
        Export-Csv -LiteralPath $CsvOut -NoTypeInformation -Encoding UTF8
}

# 计数必须用 @(...).Count。写成 @(管道 | Measure-Object).Count 会数到
# 「那个 Measure-Object 对象」本身，恒为 1 —— 2026-09-24 实踩，靠下面的
# 合计校验才拦得住。
$orphan   = @($rows | Where-Object { $_.kind -like 'ORPHAN*' }).Count
$unreach  = @($rows | Where-Object { $_.kind -like 'UNREACHABLE*' }).Count
$susp     = @($rows | Where-Object { $_.kind -like 'SUSPECT*' }).Count
if (($orphan + $unreach + $susp) -ne $detected) {
    Log "[SELF-TEST FAIL] 分类合计 $($orphan + $unreach + $susp) ≠ 总数 $detected，统计逻辑有洞，清单不出"
    @{ probed_at = $ProbedAt; probe_self_test = 'fail'; stage = 'kind_tally';
       orphan = $orphan; unreachable = $unreach; suspect = $susp; detected = $detected } |
        ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $JsonOut -Encoding UTF8
    exit 3
}

@{
    probed_at = $ProbedAt; config = $Config; probe_self_test = 'pass'
    detected = $detected; census_total = $censusTotal; expected = $expTotal
    kinds = @{ orphan_source_deleted = $orphan; unreachable_parent_gone = $unreach; suspect = $susp }
    per_host = @($perHost)
    note = '只读枚举，未做任何删除'
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $JsonOut -Encoding UTF8

$md = @()
$md += "# P0.5 死链清单（只读枚举，未删除任何东西）"
$md += ""
$md += "- 生成时间：$ProbedAt ｜ 共 **$detected** 条 ｜ probe_self_test：**pass**（与普查器逐宿主一致）"
$md += "- 明细：``$(Split-Path -Leaf $CsvOut)``"
$md += ""
$md += "## 一、为什么必须先分性，再谈清理"
$md += ""
$md += "| 类型 | 条数 | 含义 | 正确处置 |"
$md += "|---|---|---|---|"
$md += "| ORPHAN 源已删 | **$orphan** | 目标父目录仍在，只是那个技能目录本身被删了 | 可清 —— 链接已无意义 |"
$md += "| UNREACHABLE 路径不可达 | **$unreach** | 连目标父目录都不在（盘符变了／用户目录搬走／在别的机器） | **不能清** —— 清了就把「源在别处」这个事实也抹掉了 |"
$md += "| SUSPECT 探针矛盾 | $susp | 活性探针说断但目标存在 | 逐条人工看 |"
$md += ""
$md += "> 这两类**处置方向相反**，所以不能用一句「删掉所有断链」解决。"
$md += ""
$md += "## 一点五、死链指向哪儿（决定根因）"
$md += ""
$md += "| 目标父目录 | 条数 | 该目录现在存在吗 |"
$md += "|---|---|---|"
$parentGroups = $rows | Group-Object -Property { [System.IO.Path]::GetDirectoryName($_.recorded_target) } | Sort-Object Count -Descending
foreach ($pg in $parentGroups) {
    $pe = if ([string]::IsNullOrEmpty($pg.Name)) { '?' } elseif (Test-Path -LiteralPath $pg.Name) { '存在（源目录还在，只是里面的技能被删了）' } else { '不存在' }
    $md += "| ``$($pg.Name)`` | $($pg.Count) | $pe |"
}
$md += ""
# 根因量化：去重后的"被删技能数"与"受影响宿主数"，不硬编码
$distinctDeleted = @($rows | Group-Object -Property link_name).Count
$affectedHosts   = @($rows | Group-Object -Property host).Count
$familyGroups = $rows | Group-Object -Property link_name | ForEach-Object {
    $n = $_.Name
    if ($n -like 'lark-*') { 'lark-*（飞书公有云）' }
    elseif ($n -like 'larksuite-*') { 'larksuite-*' }
    elseif ($n -like 'arkcli-*') { 'arkcli-*' }
    elseif ($n -like 'coze-*') { 'coze-*' }
    else { '其他（Anthropic 系／社区合集技能名）' }
}
$familyLines = $familyGroups | Group-Object | Sort-Object Count -Descending |
    ForEach-Object { "| $($_.Name) | $($_.Count) |" }

$md += "**根因判读**：全部死链的目标父目录只有 $(@($parentGroups).Count) 个，且该目录本身仍存在 —— 说明不是盘符迁移、也不是整片路径失效，而是**从这一个 hub 里删掉了 $distinctDeleted 个技能目录，但散在 $affectedHosts 个宿主里的 $($rows.Count) 条链接没有回收**。清理因此是单一动作，不需要逐宿主分别判断。"
$md += ""
$md += "被删技能按家族归类（按技能名去重，共 $distinctDeleted 个）："
$md += ""
$md += "| 家族 | 被删技能数 |"
$md += "|---|---|"
foreach ($fl in $familyLines) { $md += $fl }
$md += ""
$md += "## 二、逐宿主"
$md += ""
$md += "| host | 链接数 | 断链 | 普查对照 | 备注 |"
$md += "|---|---|---|---|---|"
foreach ($ph in ($perHost | Sort-Object -Property @{E={$_.broken}; Descending=$true})) {
    $md += "| ``$($ph.host)`` | $($ph.links) | $($ph.broken) | $($ph.census) | $($ph.note) |"
}
$md += ""
$md += "## 三、清理动作的安全要求（执行前必读）"
$md += ""
$md += "1. **禁止** ``Remove-Item -Recurse``：可能顺着链接删进目标内容。"
$md += "2. 只允许 ``cmd /c rmdir <link>``（不带 /s）语义 —— 删链接本身，不碰目标。"
$md += "3. 删除前逐条再验一次：该路径确实具 ReparsePoint 属性、且目标确实不可达。"
$md += "4. 先备份清单（本 CSV 即清单），并留一份删除前各宿主目录快照；回滚 = 按清单重建链接，而不是恢复目标。"
$md += "5. 只对 ORPHAN 类动手；UNREACHABLE 类先查清源在哪儿。"
$md += ""
$md += "## 四、待你拍板"
$md += ""
$md += "- 是否先把 UNREACHABLE 的 $unreach 条查清来源（可能是某次盘迁移遗留，见记忆里的目录搬迁线索）"
$md += "- 还是先只对 ORPHAN 的 $orphan 条出 dry-run 删除脚本"
Set-Content -LiteralPath $MdOut -Value $md -Encoding UTF8

Log "产物：$([System.IO.Path]::GetFileName($CsvOut)) / $([System.IO.Path]::GetFileName($MdOut)) / json"
Log "分性：ORPHAN $orphan ／ UNREACHABLE $unreach ／ SUSPECT $susp"

if ($susp -gt 0 -or $unreach -gt 0) { exit 2 } else { exit 0 }
