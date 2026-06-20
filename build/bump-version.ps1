param(
    [string]$Version = 'patch',
    [switch]$NoCommit
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$props = Join-Path $root 'Directory.Build.props'
$content = Get-Content -Raw $props

$current = [regex]::Match($content, '<Version>(.*?)</Version>').Groups[1].Value
if (-not $current) { throw "<Version> not found in $props" }

if ($Version -match '^\d+\.\d+\.\d+$') {
    $next = $Version
}
else {
    $p = $current.Split('.')
    switch ($Version) {
        'major' { $next = "$([int]$p[0] + 1).0.0" }
        'minor' { $next = "$($p[0]).$([int]$p[1] + 1).0" }
        'patch' { $next = "$($p[0]).$($p[1]).$([int]$p[2] + 1)" }
        default { throw "Use X.Y.Z or major|minor|patch, got '$Version'" }
    }
}

$content = $content -replace '<Version>.*?</Version>', "<Version>$next</Version>"
[System.IO.File]::WriteAllText($props, $content, (New-Object System.Text.UTF8Encoding $true))
Write-Host "$current -> $next"

if (-not $NoCommit) {
    git -C $root commit -m "Версия $next" -- Directory.Build.props
}
