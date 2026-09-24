# =====================================================================
#  共享库：极简 YAML 子集解析 + 配置访问器
# ---------------------------------------------------------------------
#  真源唯一：本文件是中枢内所有脚本的唯一配置解析实现。
#  严禁在别的脚本里复制一份 —— 这正是本体系要治理的「副本静默分叉」本身。
#  解析器实现沿用 D:\Work\自适应工作流引擎\probes\probe_gpt_mirror.ps1
#  的 Read-Contract 口径（缩进 + 块列表 + 标量 + 行尾注释），保持跨仓一致。
#
#  用法：在调用方脚本顶部
#     . (Join-Path $PSScriptRoot 'lib_contract.ps1')
#
#  支持范围（有意只做子集，写超了会静默丢字段，故列清楚）
#   - 两级以上缩进映射，键须为 [A-Za-z_][\w-]*
#   - 块列表 `- 值`（标量项；不支持列表内嵌映射的消费）
#   - 行尾 ` # ` 注释、整行 `#` 注释、单/双引号自动剥离
#   - 不支持：流式 `{a: 1, b: 2}` 内联映射的字段级展开、多行折叠标量
# =====================================================================

function Read-Contract {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { throw "配置文件不存在：$Path" }

    $flat = @{}
    $stack = New-Object System.Collections.ArrayList
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8

    foreach ($raw in $lines) {
        if ($raw -match '^\s*#') { continue }
        if ($raw.Trim() -eq '') { continue }

        $indent = ($raw.Length - $raw.TrimStart(' ').Length)
        $line = $raw.Trim()

        # 去掉行尾注释（不处理引号内含 # 的情况——配置里没这么写）
        if ($line -match '^(.*?)\s+#\s.*$') { $line = $Matches[1].Trim() }

        while ($stack.Count -gt 0 -and $stack[$stack.Count - 1].indent -ge $indent) {
            $stack.RemoveAt($stack.Count - 1)
        }

        $prefix = ($stack | ForEach-Object { $_.key }) -join '.'

        if ($line -match '^-\s*(.*)$') {
            $parentKey = if ($stack.Count -gt 0) { ($stack | ForEach-Object { $_.key }) -join '.' } else { '' }
            $idxKey = "$parentKey.__count"
            $i = 0
            if ($flat.ContainsKey($idxKey)) { $i = [int]$flat[$idxKey] }
            $flat[$idxKey] = ($i + 1).ToString()
            $val = $Matches[1].Trim()
            $flat["$parentKey.$i"] = $val.Trim('"').Trim("'")
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
    if ($null -eq $v -or $v -eq '') { throw "配置缺少必需字段：$Key" }
    return $v
}
