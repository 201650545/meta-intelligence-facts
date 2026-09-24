# =====================================================================
#  治理范围投影器（只读 · 消费普查产物，不重新扫描磁盘）
# ---------------------------------------------------------------------
#  政策依据（2026-09-24 用户裁定）：
#    只治理**用户侧资产** —— 自己写的、主动装的、下载的、工具代装的；
#    **程序出厂自带的整体退出范围**，只登记不治理。
#
#  为什么放在这一层而不是普查脚本里：
#    范围是**政策叠加**，会随你的判断反复调。普查一轮 6 分钟，
#    投影几秒。塞进普查会让"改一条政策"变成"重扫一次全盘"。
#    同理，普查脚本只记事实，不记立场。
#
#  输入  : runtime\<prefix>-01-census-by-root.csv
#  配置  : ..\audit.config.yaml 的 scope 段与 governance 段
#  产物  : runtime\<prefix>-05-scope-decisions.csv    每条 in/out 及其判据（供你复核）
#          runtime\<prefix>-06-governance-surface.csv 范围内可治理清单
#          runtime\<prefix>-06-governance-surface.md  人读摘要
#          runtime\<prefix>-06-governance-surface.json 机器态
#  铁律  : 只读、零字面量（判据全来自配置）、产物只由脚本写、
#          self_test 必记、校验点不成立不许产出结论
#  退出码: 0=正常  2=可治理面超阈值需排期  3=自检失败，结果不可采信
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

$JsonOut = Join-Path $RuntimeDir "$Prefix-06-governance-surface.json"
function Write-SelfFail([string]$stage, [string]$errText, $extra) {
    if (-not (Test-Path -LiteralPath $RuntimeDir)) { New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null }
    $body = @{ probed_at = $ProbedAt; config = $Config; probe_self_test = 'fail'; stage = $stage; error = $errText }
    if ($extra) { $body += $extra }
    $body | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $JsonOut -Encoding UTF8
    Log "[SELF-TEST FAIL] stage=$stage  $errText"
}

# ---------------------------------------------------------------------
# 一、读政策配置
# ---------------------------------------------------------------------
try { $C = Read-Contract -Path $Config }
catch { Write-SelfFail 'config_parse' $_.Exception.Message $null; exit 3 }

try {
    $defaultScope   = Get-Required $C 'scope.default'
    $bundledFiles   = Get-CfgList $C 'scope.bundled_marker_files'
    $bundledVals    = Get-CfgList $C 'scope.bundled_marker_values'
    $ownedVals      = Get-CfgList $C 'scope.owned_marker_values'
    $selfPrefixes   = Get-CfgList $C 'scope.self_produced_prefixes'
    $toolMarkers    = Get-CfgList $C 'scope.managed_tool_markers'
    $markerDepth    = [int](Get-Required $C 'scope.marker_search_depth')
    $inRoots        = Get-CfgList $C 'scope.in_roots'
    $minIn          = [int](Get-Required $C 'scope.self_test_min_in')
    $minOut         = [int](Get-Required $C 'scope.self_test_min_out')
    $sentOut        = Get-Required $C 'scope.sentinel_out_path'
    $sentIn         = Get-Required $C 'scope.sentinel_in_path'
    $sentIn2        = Get-Required $C 'scope.sentinel_in_path2'
    $minAct         = [int](Get-Required $C 'governance.min_actionable_clusters')
    $brkAct         = [int](Get-Required $C 'governance.actionable_break')
    $sentActId      = Get-Required $C 'governance.sentinel_actionable_id'
}
catch { Write-SelfFail 'config_fields' $_.Exception.Message $null; exit 3 }

if ($inRoots.Count -eq 0) { Write-SelfFail 'config_roots' 'scope.in_roots 为空，范围无法判定' $null; exit 3 }

$csv = Join-Path $RuntimeDir "$Prefix-01-census-by-root.csv"
if (-not (Test-Path -LiteralPath $csv)) {
    Write-SelfFail 'input_missing' "找不到普查产物：$csv（请先跑 audit_skill_census.ps1）" $null
    exit 3
}

$rows = @(Import-Csv -LiteralPath $csv -Encoding UTF8)
Log "== 治理范围投影（只读） =="
Log "输入: $csv（$($rows.Count) 条）"
Log ("在范围根 {0} 个 ／ 出厂标记 {1} 个 ／ 工具代装标记 {2} 个" -f $inRoots.Count, $bundledFiles.Count, $toolMarkers.Count)

# ---------------------------------------------------------------------
# 二、判定函数：优先级 出厂标记 > 自产前缀 > 工具代装 > 声明根 > 默认
#     带缓存：同一技能目录只判一次（8663 条里约 8 千次命中同一目录）
# ---------------------------------------------------------------------
$scopeCache  = @{}
$markerCache = @{}

function Norm([string]$p) { if ($p) { return $p.TrimEnd('\') } else { return '' } }
function ParentPath([string]$p) {
    # Split-Path -Parent 在盘根（C:\）会抛异常；GetDirectoryName 返回空串，安全
    if ([string]::IsNullOrWhiteSpace($p)) { return '' }
    try { return [System.IO.Path]::GetDirectoryName($p) } catch { return '' }
}

function Get-ScopeDecision([string]$skillDir, [string]$filePath) {
    $key = Norm $skillDir
    if ($scopeCache.ContainsKey($key)) { return $scopeCache[$key] }

    $dirName = Split-Path -Leaf $key
    $r = $null

    # 1) 出厂标记（硬下限，先判）
    foreach ($mf in $bundledFiles) {
        $mp = Join-Path $key $mf
        if (Test-Path -LiteralPath $mp -PathType Leaf) {
            $st = ''
            try { $txt = [System.IO.File]::ReadAllText($mp); if ($txt -match '"sourceType"\s*:\s*"([^"]+)"') { $st = $Matches[1] } } catch {}
            if ($st -and ($bundledVals -contains $st)) { $r = @{ scope='out'; reason="出厂自带(${mf}:$st)"; evidence=$mp }; break }
            if ($st -and ($ownedVals  -contains $st)) { $r = @{ scope='in';  reason="用户侧(${mf}:$st)";   evidence=$mp }; break }
        }
    }

    # 2) 自产前缀兜底
    if (-not $r) {
        foreach ($pfx in $selfPrefixes) {
            if ($pfx -and $dirName.StartsWith($pfx, [StringComparison]::OrdinalIgnoreCase)) {
                $r = @{ scope='in'; reason="自产前缀($pfx)"; evidence='目录名' }; break
            }
        }
    }

    # 3) 工具代装：从技能目录向上找托管清单，命中其登记名才算
    if (-not $r) {
        $cur = Norm (ParentPath $key)
        for ($i = 0; $i -lt $markerDepth -and $cur; $i++) {
            foreach ($tf in $toolMarkers) {
                $tp = Join-Path $cur $tf
                if (Test-Path -LiteralPath $tp -PathType Leaf) {
                    if (-not $markerCache.ContainsKey($tp)) {
                        $names = @()
                        try {
                            $j = (Get-Content -LiteralPath $tp -Raw -Encoding UTF8 | ConvertFrom-Json)
                            if ($j.skills) { $names = @($j.skills.PSObject.Properties.Name) }
                        } catch { $names = @() }
                        $markerCache[$tp] = $names
                    }
                    if ($markerCache[$tp] -contains $dirName) {
                        $r = @{ scope='in'; reason="工具代装($tf)"; evidence=$tp }; break
                    }
                }
            }
            if ($r) { break }
            $parent = Norm (ParentPath $cur)
            if (-not $parent -or $parent -eq $cur) { break }
            $cur = $parent
        }
    }

    # 4) 声明根
    if (-not $r) {
        foreach ($ir in $inRoots) {
            if ($ir -and $filePath.StartsWith((Norm $ir), [StringComparison]::OrdinalIgnoreCase)) {
                $r = @{ scope='in'; reason='声明的在范围根'; evidence=$ir }; break
            }
        }
    }

    # 5) 默认：未声明，不猜
    if (-not $r) { $r = @{ scope=$defaultScope; reason='未声明(默认)'; evidence='-' } }

    $scopeCache[$key] = $r
    return $r
}

# ---------------------------------------------------------------------
# 三、逐条判定
# ---------------------------------------------------------------------
$decisions = New-Object System.Collections.ArrayList
$inN = 0; $outN = 0
$reasonTally = @{}
$containerTally = @{}   # 容器目录 -> @{in=;out=;id=判据}
$byIdAll = @{}

foreach ($row in $rows) {
    $sd = $row.skill_dir
    if (-not $sd) { $sd = Split-Path -Parent $row.path }   # 兼容旧版 CSV 无该列
    $d = Get-ScopeDecision $sd $row.path
    $sc = $d.scope
    if ($sc -eq 'in') { $inN++ } else { $outN++ }

    $reasonTally[$d.reason] = 1 + [int]$reasonTally[$d.reason]

    $container = Norm (Split-Path -Parent $sd)
    if (-not $containerTally.ContainsKey($container)) {
        $containerTally[$container] = @{ in = 0; out = 0; reason = $d.reason }
    }
    $containerTally[$container][$sc]++

    [void]$decisions.Add([pscustomobject]@{
        path = $row.path; skill_id = $row.skill_id; scope = $sc; reason = $d.reason; evidence = $d.evidence
    })

    if ($sc -eq 'in') {
        $id = $row.skill_id
        if (-not $byIdAll.ContainsKey($id)) { $byIdAll[$id] = New-Object System.Collections.ArrayList }
        [void]$byIdAll[$id].Add($row.path)
    }
}

Log "范围判定：在范围内 $inN 份 ／ 退出范围（程序自带或未声明）$outN 份"

# ---------------------------------------------------------------------
# 四、范围内重复与分叉（口径：只看 in-scope 副本）
# ---------------------------------------------------------------------
$hashCache = @{}
function Get-HashCached([string]$p) {
    if ($hashCache.ContainsKey($p)) { return $hashCache[$p] }
    $h = 'UNREADABLE'
    try { $h = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash } catch {}
    $hashCache[$p] = $h
    return $h
}

# 全机各 id 的总份数预先统计一次，避免在簇循环里做 O(n²) 线性扫
$countById = @{}
foreach ($row in $rows) { $countById[$row.skill_id] = 1 + [int]$countById[$row.skill_id] }

$surface = @()
$dupClusters = 0; $divClusters = 0; $hashedInScope = 0
foreach ($e in $byIdAll.GetEnumerator()) {
    $paths = @($e.Value)
    if ($paths.Count -lt 2) { continue }
    $dupClusters++
    $hs = @{}
    foreach ($p in $paths) { $h = Get-HashCached $p; if ($h -ne 'UNREADABLE') { $hashedInScope++ }; $hs[$h] = 1 }
    $v = $hs.Count
    if ($v -gt 1) {
        $divClusters++
        $surface += [pscustomobject]@{
            skill_id = $e.Key; in_copies = $paths.Count; in_variants = $v
            total_copies_on_machine = [int]$countById[$e.Key]
            sample_paths = (($paths | Select-Object -First 8) -join ' ; ')
        }
    }
}
Log "范围内同名多份簇 $dupClusters 个，其中内容已分叉 $divClusters 个"

# ---------------------------------------------------------------------
# 五、自检 —— 三条判定路径各有哨兵，加区间检查
# ---------------------------------------------------------------------
$failReasons = @()
if ($inN -lt $minIn)   { $failReasons += "在范围内 $inN < 下限 $minIn（声明根或标记判据可能失效）" }
if ($outN -lt $minOut) { $failReasons += "退出范围 $outN < 下限 $minOut（出厂标记判据可能失效）" }
if ($hashedInScope -lt 50) { $failReasons += "范围内已哈希 $hashedInScope < 50，哈希链路未执行" }
if ($rows.Count -lt 3000)  { $failReasons += "输入仅 $($rows.Count) 条，疑似误用冒烟产物" }

function Test-Sentinel([string]$skillDirPath, [string]$wantScope, [string]$label) {
    $k = Norm $skillDirPath
    if (-not $scopeCache.ContainsKey($k)) { return "$label 未在数据中出现：$k" }
    $got = $scopeCache[$k].scope
    if ($got -ne $wantScope) { return "$label 判定为 $got，期望 $wantScope（$($scopeCache[$k].reason)）" }
    return $null
}
foreach ($chk in @(
    (Test-Sentinel $sentOut 'out' '出厂哨兵'),
    (Test-Sentinel $sentIn  'in'  '自产哨兵'),
    (Test-Sentinel $sentIn2 'in'  '声明根哨兵')
)) { if ($chk) { $failReasons += $chk } }

if ($divClusters -lt $minAct) { $failReasons += "范围内分叉簇 $divClusters < 下限 $minAct（投影或分组逻辑可能已坏）" }
if (-not (($surface | ForEach-Object { $_.skill_id }) -contains $sentActId)) {
    $failReasons += "哨兵技能 $sentActId 不在范围内分叉清单中（判据或分组可能已坏）"
}

if ($failReasons.Count -gt 0) {
    Log "[SELF-TEST FAIL] 投影结果不可采信："
    foreach ($x in $failReasons) { Log "   - $x" }
    @{ probed_at = $ProbedAt; config = $Config; probe_self_test = 'fail'; reasons = $failReasons;
       input = $csv; input_rows = $rows.Count; in_scope = $inN; out_scope = $outN } |
        ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $JsonOut -Encoding UTF8
    exit 3
}
Log "[SELF-TEST PASS] 三条判定路径各有哨兵命中；区间检查通过"

# ---------------------------------------------------------------------
# 六、产物写出
# ---------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $RuntimeDir)) { New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null }

$decisions | Export-Csv -LiteralPath (Join-Path $RuntimeDir "$Prefix-05-scope-decisions.csv") -NoTypeInformation -Encoding UTF8

if (@($surface).Count -gt 0) {
    $surface | Sort-Object -Property @{E={ $_.in_variants }; Descending=$true}, @{E={ $_.in_copies }; Descending=$true} |
        Export-Csv -LiteralPath (Join-Path $RuntimeDir "$Prefix-06-governance-surface.csv") -NoTypeInformation -Encoding UTF8
} else {
    Set-Content -LiteralPath (Join-Path $RuntimeDir "$Prefix-06-governance-surface.csv") -Value 'skill_id,in_copies,in_variants,total_copies_on_machine,sample_paths' -Encoding UTF8
}

# 判定分布：便于你复核"线画在哪"
$reasonRows = $reasonTally.GetEnumerator() | Sort-Object -Property @{E={ $_.Value }; Descending=$true} |
    ForEach-Object { [pscustomobject]@{ reason = $_.Key; files = $_.Value } }
$reasonRows | Export-Csv -LiteralPath (Join-Path $RuntimeDir "$Prefix-05b-scope-by-reason.csv") -NoTypeInformation -Encoding UTF8

$contRows = $containerTally.GetEnumerator() | Sort-Object -Property @{E={ ($_.Value.in + $_.Value.out) }; Descending=$true} |
    ForEach-Object { [pscustomobject]@{ container = $_.Key; in_scope = $_.Value.in; out_of_scope = $_.Value.out; first_reason = $_.Value.reason } }
$contRows | Export-Csv -LiteralPath (Join-Path $RuntimeDir "$Prefix-05c-scope-by-container.csv") -NoTypeInformation -Encoding UTF8

@{
    probed_at = $ProbedAt; config = $Config; input = $csv; probe_self_test = 'pass'
    input_rows = $rows.Count; in_scope = $inN; out_of_scope = $outN
    in_scope_pct = [Math]::Round(($inN / [Math]::Max(1, $rows.Count)) * 100, 2)
    in_scope_unique_ids = $byIdAll.Count
    in_dup_clusters = $dupClusters; in_divergent_clusters = $divClusters
    hashed_in_scope = $hashedInScope
    reason_breakdown = $reasonTally
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $JsonOut -Encoding UTF8

$md = @()
$md += "# 治理范围与可治理清单（按 2026-09-24 政策：只管用户侧）"
$md += ""
$md += "- 生成时间：$ProbedAt ｜ 输入 $($rows.Count) 条 ｜ probe_self_test：**pass**"
$md += ""
$md += "| 项 | 值 |"
$md += "|---|---|"
$md += "| 在范围内（用户侧） | **$inN**（$([Math]::Round(($inN / [Math]::Max(1,$rows.Count)) * 100, 2))%） |"
$md += "| 退出范围（程序自带／未声明） | $outN |"
$md += "| 范围内唯一技能 id | $($byIdAll.Count) |"
$md += "| 范围内同名多份簇 | $dupClusters |"
$md += "| **范围内内容已分叉** | **$divClusters** |"
$md += ""
$md += "## 判据分布（复核用）"
$md += ""
$md += "| 判据 | 文件数 |"
$md += "|---|---|"
foreach ($rr in $reasonRows) { $md += "| $($rr.reason) | $($rr.files) |" }
$md += ""
$md += "## 范围边界：按容器目录（复核线画在哪）"
$md += ""
$md += "| 容器目录 | 在范围 | 退出范围 | 首个判据 |"
$md += "|---|---|---|---|"
foreach ($cr in ($contRows | Select-Object -First 30)) { $md += "| ``$($cr.container)`` | $($cr.in_scope) | $($cr.out_of_scope) | $($cr.first_reason) |" }
$md += ""
$md += "## 可治理清单 TOP30（范围内、同名多份且内容不一致）"
$md += ""
$md += "| skill_id | 范围内份数 | 范围内变体 | 全机总份数 |"
$md += "|---|---|---|---|"
foreach ($s in ($surface | Sort-Object -Property @{E={ $_.in_variants }; Descending=$true}, @{E={ $_.in_copies }; Descending=$true} | Select-Object -First 30)) {
    $md += "| ``$($s.skill_id)`` | $($s.in_copies) | $($s.in_variants) | $($s.total_copies_on_machine) |" }
$md += ""
$md += "> 全量口径的 907 分叉簇含各产品自带版本差异；本表只列范围内的。逐条判据见 ``$Prefix-05-scope-decisions.csv``。"
Set-Content -LiteralPath (Join-Path $RuntimeDir "$Prefix-06-governance-surface.md") -Value $md -Encoding UTF8

Log "产物已写入 $RuntimeDir"
if ($divClusters -gt $brkAct) { exit 2 } else { exit 0 }
