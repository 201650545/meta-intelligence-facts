# =====================================================================
#  P0 技能普查体检器（只读 · 零写入被检对象 · 零打扰）
# ---------------------------------------------------------------------
#  配置真源 : ..\audit.config.yaml         全量普查
#             ..\audit.config.smoke.yaml   小样本冒烟（先跑这个验管道）
#  产物     : ..\runtime\<prefix>.runtime.json   全量事实
#             ..\runtime\<prefix>.drift.json     偏差投影（需人工介入项）
#             ..\runtime\01-census-by-root.csv   普查明细
#             ..\runtime\02-duplicate-divergence.csv  重名与副本分叉
#             ..\runtime\03-link-health.csv      链接层健康
#             ..\runtime\00-summary.md           人读摘要
#  用法     : powershell -ExecutionPolicy Bypass -File audit_skill_census.ps1 [-Config <路径>]
#
#  铁律（照搬 D:\Work\自适应工作流引擎\probes\probe_gpt_mirror.ps1 的范式）
#   1. 只读：只枚举目录与读文件哈希，绝不创建 / 修改 / 删除任何被检对象
#   2. 零字面量：扫描根 / 分类正则 / 阈值 / 哨兵 全部从配置读取，
#      本脚本内不得出现任何硬编码的外部常量
#   3. 产物只由本脚本写，禁止手改
#   4. probe_self_test 每次必记 —— 用于区分「机器真的变了」与「探针自己坏了」
#   5. 校验点不成立时不许产出结论（silent-risk 按 break 处理）
#   6. 不跟随 reparse point（symlink / junction），避免重复计数与环
#
#  退出码：0=无 break（可继续）  2=有 break（需人工介入）
#          3=自检失败（配置缺失 / 判据写坏 / 路径不可达）——本次结果不可采信
# =====================================================================
param(
    [string]$Config,
    [switch]$Verbose2
)

$ErrorActionPreference = 'Stop'

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir    = Split-Path -Parent $ScriptDir
$RuntimeDir = Join-Path $BaseDir 'runtime'
if ([string]::IsNullOrWhiteSpace($Config)) { $Config = Join-Path $BaseDir 'audit.config.yaml' }

$ProbedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')

function Log([string]$m) { Write-Host $m }
function LogV([string]$m) { if ($Verbose2) { Write-Host $m } }

# ---------------------------------------------------------------------
# 一、配置解析与访问器：真源唯一，实现在 lib_contract.ps1（禁止在本文件内复制一份）
# ---------------------------------------------------------------------
. (Join-Path $PSScriptRoot 'lib_contract.ps1')

function Ensure-RuntimeDir {
    if (-not (Test-Path -LiteralPath $RuntimeDir)) {
        New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null
    }
}

# 自检失败也要留证据，但明确标记不可采信
function Write-SelfFail([string]$stage, [string]$errText, [string]$prefix) {
    Ensure-RuntimeDir
    $body = @{
        probed_at       = $ProbedAt
        config          = $Config
        probe_self_test = 'fail'
        stage           = $stage
        error           = $errText
    }
    ($body | ConvertTo-Json -Depth 6) |
        Set-Content -LiteralPath (Join-Path $RuntimeDir "$prefix.runtime.json") -Encoding UTF8
    Write-Host "[SELF-TEST FAIL] stage=$stage  $errText"
}

# ---------------------------------------------------------------------
# 二、读配置（缺任一必需字段 → 自检失败，不产出结论）
# ---------------------------------------------------------------------
$Prefix = 'skill-census'
try { $C = Read-Contract -Path $Config }
catch { Write-SelfFail 'config_parse' $_.Exception.Message $Prefix; exit 3 }

try {
    if (Get-Cfg $C 'output_prefix') { $Prefix = Get-Cfg $C 'output_prefix' }

    $rootsRaw  = Get-CfgList $C 'scan.roots'
    $excludeRe = Get-Required $C 'scan.exclude_path_regex'
    $skillName = Get-Required $C 'scan.skill_file_name'

    $aRe     = Get-Required $C 'classify.a_class_path_regex'
    $cRe     = Get-Required $C 'classify.c_class_path_regex'
    $markers = Get-CfgList $C 'classify.owned_marker_files'
    $bDirs   = Get-CfgList $C 'classify.b_class_known_dirs'
    $trueSrc = Get-CfgList $C 'classify.true_source_dirs'

    $linkHosts = Get-CfgList $C 'link_hosts'

    $stMinTotal  = [int](Get-Required $C 'self_test.min_skill_files_total')
    $stMinA      = [int](Get-Required $C 'self_test.min_a_class')
    $stMinB      = [int](Get-Required $C 'self_test.min_b_class')
    $stMinC      = [int](Get-Required $C 'self_test.min_c_class')
    $stMinDupCls = [int](Get-Required $C 'self_test.min_dup_clusters')
    $stMinHashed = [int](Get-Required $C 'self_test.min_hashed_files')
    $stMaxFmRate = [double](Get-Required $C 'self_test.max_frontmatter_missing_rate')
    $stMinBroken = [int](Get-Required $C 'self_test.min_broken_links')
    $stSentLink  = Get-Required $C 'self_test.sentinel_broken_link'
    $stSentName  = Get-Cfg $C 'self_test.sentinel_dup_name'
    $stSentMin   = 0
    if (Get-Cfg $C 'self_test.sentinel_dup_min_copies') { $stSentMin = [int](Get-Cfg $C 'self_test.sentinel_dup_min_copies') }

    $lvBrokenWarn  = [int](Get-Required $C 'levels.broken_links_warn')
    $lvBrokenBreak = [int](Get-Required $C 'levels.broken_links_break')
    $lvDivWarn     = [int](Get-Required $C 'levels.divergent_clusters_warn')
    $lvDivBreak    = [int](Get-Required $C 'levels.divergent_clusters_break')
    $lvEmptyRoot   = Get-Required $C 'levels.empty_existing_root'
    $lvTrueSrcReq  = Get-Required $C 'levels.true_source_required'
}
catch {
    Write-SelfFail 'config_fields' $_.Exception.Message $Prefix
    exit 3
}

if ($rootsRaw.Count -eq 0) {
    Write-SelfFail 'config_roots' 'scan.roots 为空，无可扫描范围' $Prefix
    exit 3
}

Write-Host "== 技能普查体检器 P0（只读） =="
Write-Host "配置: $Config"
Write-Host "开始: $ProbedAt"

# ---------------------------------------------------------------------
# 三、枚举 SKILL.md（深度优先，剪排除项，不跟随 reparse point）
# ---------------------------------------------------------------------
function Test-ReparseDir([System.IO.DirectoryInfo]$di) {
    try {
        return (($di.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
    } catch { return $false }
}

$skillFiles = New-Object System.Collections.ArrayList
$rootStats  = @()
$dirVisited = 0

foreach ($entry in $rootsRaw) {
    $parts  = $entry -split '\|'
    $root   = $parts[0].Trim()
    $maxDep = 9
    if ($parts.Count -gt 1 -and $parts[1].Trim() -ne '') { $maxDep = [int]$parts[1].Trim() }

    $rootExists = Test-Path -LiteralPath $root
    $foundBefore = $skillFiles.Count

    if (-not $rootExists) {
        $rootStats += [pscustomobject]@{ root = $root; max_depth = $maxDep; exists = $false; count = 0; note = 'root_not_found' }
        continue
    }

    $stack = New-Object System.Collections.Stack
    $rootInfo = $null
    try { $rootInfo = New-Object System.IO.DirectoryInfo($root) } catch { $rootInfo = $null }
    if ($null -eq $rootInfo) {
        $rootStats += [pscustomobject]@{ root = $root; max_depth = $maxDep; exists = $true; count = 0; note = 'root_unreadable' }
        continue
    }
    $stack.Push(@{ di = $rootInfo; d = 0 })

    while ($stack.Count -gt 0) {
        $cur = $stack.Pop()
        $dirVisited++
        if ($cur.d -ge $maxDep) { continue }

        try {
            foreach ($f in $cur.di.GetFiles($skillName)) {
                [void]$skillFiles.Add($f.FullName)
            }
        } catch { LogV "跳过不可读目录: $($cur.di.FullName)" }

        if (($dirVisited % 5000) -eq 0) { LogV "  已访问 $dirVisited 目录，命中 $($skillFiles.Count) 份" }

        try {
            foreach ($sub in $cur.di.EnumerateDirectories()) {
                if ($sub.FullName -match $excludeRe) { continue }
                if (Test-ReparseDir $sub) { continue }
                $stack.Push(@{ di = $sub; d = ($cur.d + 1) })
            }
        } catch { LogV "跳过不可枚举子目录: $($cur.di.FullName)" }
    }

    $cnt = $skillFiles.Count - $foundBefore
    $note = 'ok'
    if ($cnt -eq 0) { $note = 'empty_existing_root' }
    $rootStats += [pscustomobject]@{ root = $root; max_depth = $maxDep; exists = $true; count = $cnt; note = $note }
    Log ("  根 {0} (depth<={1}) 命中 {2} 份" -f $root, $maxDep, $cnt)
}

$total = $skillFiles.Count
Log "扫描完成：共 $total 份 $skillName，访问 $dirVisited 个目录"

# ---------------------------------------------------------------------
# 四、分类 A / B / C 与真源归属
#     技能身份键 = SKILL.md frontmatter 的 name:（取不到才退回目录名）
#     为何不直接用目录名（2026-09-24 首跑实测推翻）：
#       ① 虚增：`...\connectors\<名>\skills\SKILL.md` 这类包装目录会被当成
#          一个叫 "skills" 的技能，实测聚出 193 份 / 167 种内容的假分叉簇；
#          跨产品同名（ts / py / feedback / github 等）同理；
#       ② 漏报：同一技能被改名后不被识别 —— 如 Anthropic `docx` →
#          Loomy `loomy-docx`（同内容不同目录名，目录名键完全看不出）。
# ---------------------------------------------------------------------
function Get-SkillMeta([string]$filePath) {
    $name = ''
    try {
        $head = Get-Content -LiteralPath $filePath -TotalCount 40 -Encoding UTF8
        if ($head.Count -gt 0 -and ($head[0] -match '^---\s*$')) {
            for ($i = 1; $i -lt $head.Count; $i++) {
                if ($head[$i] -match '^---\s*$') { break }
                if ($head[$i] -match '^name\s*:\s*(.+)$') {
                    $name = $Matches[1].Trim().Trim('"').Trim("'"); break
                }
            }
        }
    } catch { $name = '' }
    return $name
}

$rows = New-Object System.Collections.ArrayList
$byId = @{}
$trueSourceHits = 0
$cntA = 0; $cntB = 0; $cntC = 0
$cntOwnedMarker = 0
$noFrontmatter = 0
$dirIdDiffers = 0

foreach ($f in $skillFiles) {
    $fi = New-Object System.IO.FileInfo($f)
    $skillDir = $fi.Directory.FullName
    $dirName = $fi.Directory.Name

    $fmName = Get-SkillMeta $f
    if ($fmName -eq '') { $noFrontmatter++ }
    $id = if ($fmName) { $fmName } else { $dirName }
    if ($fmName -and ($fmName -cne $dirName)) { $dirIdDiffers++ }

    # 分类优先级：所有权标记 > 路径判据 > 已知第三方合集
    # 标记优先的理由：`.loomy-skill.json` 是"该技能归程序所有、更新会覆盖"的直接证据，
    # 而 Loomy 运行时目录（C:\Users\Public\Loomy\...）按路径段判会被误归 B 待判。
    $cls = 'B'; $why = 'default'
    $ownedByMarker = $false
    foreach ($mk in $markers) {
        if ($mk -and (Test-Path -LiteralPath (Join-Path $skillDir $mk))) { $ownedByMarker = $true; break }
    }
    if ($ownedByMarker) { $cls = 'A'; $why = 'owned_marker'; $cntOwnedMarker++ }
    elseif ($f -match $aRe) { $cls = 'A'; $why = 'path' }
    elseif ($f -match $cRe) { $cls = 'C'; $why = 'path' }

    if (-not $ownedByMarker) {
        foreach ($b in $bDirs) { if ($b -and ($f -like "$b*")) { $cls = 'B'; $why = 'known_dir'; break } }
    }

    $isTrueSrc = $false
    foreach ($t in $trueSrc) { if ($t -and ($f -like "$t*")) { $isTrueSrc = $true; break } }
    if ($isTrueSrc) { $trueSourceHits++ }

    switch ($cls) { 'A' { $cntA++ } 'C' { $cntC++ } default { $cntB++ } }

    [void]$rows.Add([pscustomobject]@{
        path      = $f
        skill_id  = $id
        dir_name  = $dirName
        front_ok  = [bool]$fmName
        root_dir  = $skillDir
        class     = $cls
        class_reason = $why
        # 范围判定（project_governance_surface.ps1）要靠所有权标记定位：
        # .loomy-skill.json 在技能目录内，.arkcli-managed-skills.json 在其上几层，
        # 故只需给出技能目录，投影器自行向上找
        skill_dir = $skillDir
        true_src  = $isTrueSrc
    })

    if (-not $byId.ContainsKey($id)) { $byId[$id] = New-Object System.Collections.ArrayList }
    [void]$byId[$id].Add($f)
}

Log "分类：A 程序内置/市场/插件 $($cntA)（其中 $($cntOwnedMarker) 份靠所有权标记判定）／ B 其余待判 $($cntB) ／ C 宿主配置目录内实体副本 $($cntC)"

# ---------------------------------------------------------------------
# 五、重名与副本分叉（.claude\CLAUDE.md 所述「静默分叉」风险的实证检测）
#     只对份数 > 1 的技能名算哈希，省时间
# ---------------------------------------------------------------------
$dupRows = @()
$divergentClusters = 0
$identicalClusters = 0
$hashedFiles = 0
$sentinelCopies = 0
$sentinelVariants = 0

$dupIds = $byId.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | Sort-Object { -$_.Value.Count }
foreach ($e in $dupIds) {
    $nm = $e.Key
    $hashes = @{}
    foreach ($p in $e.Value) {
        try {
            $h = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
            $hashedFiles++
        } catch { $h = 'UNREADABLE' }
        if (-not $hashes.ContainsKey($h)) { $hashes[$h] = New-Object System.Collections.ArrayList }
        [void]$hashes[$h].Add($p)
    }
    $variants = $hashes.Count
    $copies = $e.Value.Count
    if ($variants -gt 1) { $divergentClusters++ } else { $identicalClusters++ }

    if ($nm -eq $stSentName) { $sentinelCopies = $copies; $sentinelVariants = $variants }

    $dupRows += [pscustomobject]@{
        skill_id      = $nm
        copies        = $copies
        hash_variants = $variants
        status        = $(if ($variants -gt 1) { 'DIVERGENT' } else { 'IDENTICAL' })
        roots         = (($e.Value | ForEach-Object { (New-Object System.IO.FileInfo($_)).Directory.FullName } | Sort-Object -Unique) -join ' ; ')
    }
}
Log "重名技能 $((@($dupRows)).Count) 个，其中内容已分叉 $divergentClusters 个"

# ---------------------------------------------------------------------
# 六、链接层健康
#     实测结论（2026-09-24，两条都是踩出来的）：
#     ① 这些条目是 **JUNCTION** 而非 symlink；
#     ② Test-Path 与 [IO.Directory]::Exists 对**断开的 junction 一律返回 True**
#        （它们只查链接自身，不校验目标）→ 用它判活等于恒判健康；
#     ③ Get-ChildItem 对断链只抛**非终止错误**，try/catch 接不住，
#        反而让脚本继续跑出"子项=0"的假结论 —— 典型 silent-risk。
#     故改用「必须穿过链接才能完成」的 .NET 调用作活性探针：
#        [IO.Directory]::GetFiles(dir, 永不匹配的窄模式)
#        目标可打开 → 返回空数组（不读内容，快）；目标缺失 → 抛异常。
# ---------------------------------------------------------------------
function Test-LinkResolves([string]$p) {
    try {
        [void][System.IO.Directory]::GetFiles($p, '~probe~*.no-match-zzz')
        return $true
    } catch { return $false }
}

$linkRows = @()
$brokenList = New-Object System.Collections.ArrayList
$hostSeen = 0

foreach ($h in $linkHosts) {
    if (-not (Test-Path -LiteralPath $h)) {
        $linkRows += [pscustomobject]@{ host = $h; exists = $false; entities = 0; links = 0; broken = 0 }
        continue
    }
    $hostSeen++
    $ent = 0; $lnk = 0; $brk = 0
    try {
        foreach ($fi in (New-Object System.IO.DirectoryInfo($h)).GetFileSystemInfos()) {
            $isLink = (($fi.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
            if ($isLink) {
                $lnk++
                if (-not (Test-LinkResolves $fi.FullName)) {
                    $brk++
                    [void]$brokenList.Add([pscustomobject]@{ link = $fi.FullName; host = $h })
                }
            } else {
                $ent++
            }
        }
    } catch { LogV "宿主目录枚举失败: $h" }
    $linkRows += [pscustomobject]@{ host = $h; exists = $true; entities = $ent; links = $lnk; broken = $brk }
}

$brokenTotal = $brokenList.Count
Log "链接层：受检宿主 $hostSeen 个，断链 $brokenTotal 条"

# ---------------------------------------------------------------------
# 七、自检哨兵 —— 先证明探针没坏，再让它说话
# ---------------------------------------------------------------------
$drift = New-Object System.Collections.ArrayList
function Add-Drift([string]$cond, [string]$level, [string]$obs, [string]$act) {
    [void]$drift.Add([pscustomobject]@{ condition = $cond; level = $level; observed = $obs; action = $act })
}

$failReasons = @()
if ($total -lt $stMinTotal)  { $failReasons += "总数 $total < 下限 $stMinTotal" }
if ($cntA -lt $stMinA)       { $failReasons += "A 类 $cntA < 下限 $stMinA" }
if ($cntB -lt $stMinB)       { $failReasons += "B 类 $cntB < 下限 $stMinB" }
if ($cntC -lt $stMinC)       { $failReasons += "C 类 $cntC < 下限 $stMinC" }
if ((@($dupRows)).Count -lt $stMinDupCls) { $failReasons += "重名簇 $(@($dupRows)).Count < 下限 $stMinDupCls（分组逻辑可能已坏）" }
if ($hashedFiles -lt $stMinHashed)        { $failReasons += "已哈希文件 $hashedFiles < 下限 $stMinHashed（哈希链路可能未执行）" }
# frontmatter 解析率过低 = 身份键静默退化成目录名，结果看着合理但含义已变 → silent-risk
$fmMissingRate = 0
if ($total -gt 0) { $fmMissingRate = [Math]::Round(($noFrontmatter / $total), 4) }
if ($fmMissingRate -gt $stMaxFmRate) { $failReasons += "frontmatter 缺失率 $fmMissingRate > 上限 $stMaxFmRate（技能身份键已静默退化为目录名，结论不可用）" }
if ($brokenTotal -lt $stMinBroken) { $failReasons += "检出断链 $brokenTotal < 下限 $stMinBroken" }

$sentFound = $false
foreach ($b in $brokenList) { if ($b.link -ieq $stSentLink) { $sentFound = $true; break } }
if (-not $sentFound) { $failReasons += "未检出已知断链哨兵 $stSentLink（链接检测逻辑可能已坏）" }

if ($stSentName -and $stSentMin -gt 0) {
    if ($sentinelCopies -lt $stSentMin) { $failReasons += "哨兵技能 $stSentName 仅 $sentinelCopies 份 < $stSentMin（分组逻辑可能已坏）" }
}

$selfTestPass = ($failReasons.Count -eq 0)
if (-not $selfTestPass) {
    Log "[SELF-TEST FAIL] 探针自检不通过，本次结果不可采信："
    foreach ($r in $failReasons) { Log "   - $r" }
    Ensure-RuntimeDir
    @{
        probed_at = $ProbedAt; config = $Config; probe_self_test = 'fail'
        reasons = $failReasons; totals = @{ files = $total; a = $cntA; b = $cntB; c = $cntC; broken = $brokenTotal }
    } | ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath (Join-Path $RuntimeDir "$Prefix.runtime.json") -Encoding UTF8
    exit 3
}
Log "[SELF-TEST PASS] 枚举 / 分类 / 哈希 / 断链 四类判据均命中已知样本"

# ---------------------------------------------------------------------
# 八、级别判定（silent-risk 一律按 break）
# ---------------------------------------------------------------------
$summary = @{ info = 0; warn = 0; break = 0; silent_risk = 0 }
function Bump([string]$k) { $script:summary[$k]++ }

foreach ($rs in $rootStats) {
    if (-not $rs.exists) {
        Add-Drift "root:$($rs.root)" 'break' '根路径不存在' 'circuit_break'
        Bump 'break'
    } elseif ($rs.note -eq 'empty_existing_root') {
        Add-Drift "root:$($rs.root)" $lvEmptyRoot '根存在但命中 0 份 SKILL.md（判据或深度可能写坏）' 'silent_risk_check'
        Bump 'silent_risk'
    }
}

if ($brokenTotal -ge $lvBrokenBreak) {
    Add-Drift 'link_health.broken_total' 'break' "断链 $brokenTotal 条 ≥ 阈值 $lvBrokenBreak" 'circuit_break'
    Bump 'break'
} elseif ($brokenTotal -ge $lvBrokenWarn) {
    Add-Drift 'link_health.broken_total' 'warn' "断链 $brokenTotal 条 ≥ 预警线 $lvBrokenWarn" 'cleanup_needed'
    Bump 'warn'
} else { Bump 'info' }

if ($divergentClusters -ge $lvDivBreak) {
    Add-Drift 'duplicate.divergent_clusters' 'break' "内容已分叉的重名簇 $divergentClusters 个 ≥ 阈值 $lvDivBreak" 'circuit_break'
    Bump 'break'
} elseif ($divergentClusters -ge $lvDivWarn) {
    Add-Drift 'duplicate.divergent_clusters' 'warn' "内容已分叉的重名簇 $divergentClusters 个 ≥ 预警线 $lvDivWarn" 'single_source_consolidation'
    Bump 'warn'
} else { Bump 'info' }

if ($trueSourceHits -eq 0 -and $lvTrueSrcReq -ne 'skip') {
    $lvl = if ($lvTrueSrcReq -eq 'warn') { 'warn' } else { 'break' }
    Add-Drift 'true_source.present' $lvl '扫描范围内未发现真源目录下的 SKILL.md' 'circuit_break'
    Bump $lvl
} elseif ($trueSourceHits -gt 0) {
    Add-Drift 'true_source.present' 'info' "真源目录下 SKILL.md 共 $trueSourceHits 份" 'none'
    Bump 'info'
}

# ---------------------------------------------------------------------
# 九、产物写出（只写 runtime，不碰被检对象）
# ---------------------------------------------------------------------
Ensure-RuntimeDir

$runtime = @{
    probed_at          = $ProbedAt
    config             = $Config
    config_version     = (Get-Cfg $C 'config_version')
    probe_self_test    = 'pass'
    dirs_visited       = $dirVisited
    totals             = @{
        skill_files = $total; a_class = $cntA; b_class = $cntB; c_class = $cntC
        a_class_by_owned_marker = $cntOwnedMarker
        unique_skill_ids = $byId.Count
        duplicated_ids   = (@($dupRows)).Count
        divergent_clusters = $divergentClusters
        identical_clusters = $identicalClusters
        link_hosts_checked = $hostSeen
        broken_links       = $brokenTotal
        true_source_files  = $trueSourceHits
        frontmatter_missing = $noFrontmatter
        frontmatter_missing_rate = $fmMissingRate
        dir_name_differs_from_id = $dirIdDiffers
        hashed_files       = $hashedFiles
    }
    roots              = @($rootStats)
    summary            = $summary
}
($runtime | ConvertTo-Json -Depth 10) |
    Set-Content -LiteralPath (Join-Path $RuntimeDir "$Prefix.runtime.json") -Encoding UTF8

$driftDoc = @{
    probed_at          = $ProbedAt
    config_version     = (Get-Cfg $C 'config_version')
    probe_self_test    = 'pass'
    items              = @($drift)
    summary            = $summary
    broken_link_detail = @($brokenList)
}
($driftDoc | ConvertTo-Json -Depth 10) |
    Set-Content -LiteralPath (Join-Path $RuntimeDir "$Prefix.drift.json") -Encoding UTF8

# 产物文件名一律带 $Prefix —— 冒烟与全量不得互相覆盖。
# （2026-09-24 曾把 CSV 名写死，导致一次冒烟直接毁掉全量三份报表）
$rows | Sort-Object class, root_dir, skill_id |
    Export-Csv -LiteralPath (Join-Path $RuntimeDir "$Prefix-01-census-by-root.csv") -NoTypeInformation -Encoding UTF8

if ((@($dupRows)).Count -gt 0) {
    $dupRows | Export-Csv -LiteralPath (Join-Path $RuntimeDir "$Prefix-02-duplicate-divergence.csv") -NoTypeInformation -Encoding UTF8
} else {
    Set-Content -LiteralPath (Join-Path $RuntimeDir "$Prefix-02-duplicate-divergence.csv") -Value 'skill_id,copies,hash_variants,status,roots' -Encoding UTF8
}

$linkRows | Export-Csv -LiteralPath (Join-Path $RuntimeDir "$Prefix-03-link-health.csv") -NoTypeInformation -Encoding UTF8

$md = @()
$md += "# 技能普查体检摘要（P0 只读）"
$md += ""
$md += "- 探测时间：$ProbedAt"
$md += "- 配置：``$Config``"
$md += "- probe_self_test：**pass**（枚举 / 分类 / 哈希 / 断链 四类判据均命中已知样本）"
$md += "- 访问目录数：$dirVisited"
$md += ""
$md += "## 一、总量与分类"
$md += ""
$md += "| 项 | 值 |"
$md += "|---|---|"
$md += "| SKILL.md 总份数 | **$total** |"
$md += "| A 程序内置／市场／插件目录（只登记不碰） | $cntA（其中 $cntOwnedMarker 份由所有权标记判定） |"
$md += "| B 其余待判（第三方合集＋你的真源） | $cntB |"
$md += "| C 宿主配置目录内的实体副本（重复问题主体） | $cntC |"
$md += "| 唯一技能名（按 frontmatter name） | $($byId.Count) |"
$md += "| 重名技能名 | $(@($dupRows).Count) |"
$md += "| **内容已分叉的重名簇** | **$divergentClusters** |"
$md += "| 副本完全一致的重名簇 | $identicalClusters |"
$md += "| 受检链接层宿主 | $hostSeen |"
$md += "| **断链** | **$brokenTotal** |"
$md += "| 真源目录下 SKILL.md | $trueSourceHits |"
$md += "| 身份键取自 frontmatter 的 name 字段 | $($total - $noFrontmatter) ／ $total（缺失率 $fmMissingRate） |"
$md += "| 目录名与 name 不一致（改名副本） | $dirIdDiffers |"
$md += "| 已计算哈希的文件数 | $hashedFiles |"
$md += ""
$md += "## 二、偏差（drift）"
$md += ""
$md += "| condition | level | observed | action |"
$md += "|---|---|---|---|"
foreach ($d in $drift) { $md += "| $($d.condition) | $($d.level) | $($d.observed) | $($d.action) |" }
$md += ""
$md += "## 三、分叉 TOP20（副本内容已不一致的重名技能）"
$md += ""
$md += "| skill | 份数 | 不同哈希数 | 状态 |"
$md += "|---|---|---|---|"
foreach ($r in ($dupRows | Where-Object { $_.status -eq 'DIVERGENT' } | Select-Object -First 20)) {
    $md += "| ``$($r.skill_id)`` | $($r.copies) | $($r.hash_variants) | DIVERGENT |"
}
$md += ""
$md += "## 四、链接层健康"
$md += ""
$md += "| host | entities（实体） | links_alive（活链接） | broken（断链） |"
$md += "|---|---|---|---|"
foreach ($r in ($linkRows | Sort-Object -Property @{E={$_.broken}; Descending=$true})) {
    $md += "| ``$($r.host)`` | $($r.entities) | $($r.links - $r.broken) | $($r.broken) |"
}
$md += ""
$md += "---"
$md += ""
$md += "**产物由脚本生成，禁止手改。** 退出码：0=无 break ／ 2=有 break（需人工介入）／ 3=自检失败不可采信。"
$md += ""
$md += "本次 summary：info=$($summary.info) warn=$($summary.warn) break=$($summary['break']) silent_risk=$($summary.silent_risk)"

Set-Content -LiteralPath (Join-Path $RuntimeDir "$Prefix-00-summary.md") -Value $md -Encoding UTF8

Log ""
Log "产物已写入 $RuntimeDir"
Log "summary: info=$($summary.info) warn=$($summary.warn) break=$($summary['break']) silent_risk=$($summary.silent_risk)"

if ($summary['break'] -gt 0 -or $summary.silent_risk -gt 0) { exit 2 } else { exit 0 }
