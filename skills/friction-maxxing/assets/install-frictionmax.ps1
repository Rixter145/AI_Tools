<#
.SYNOPSIS
    Installs the friction-maxxing skill and cross-agent hook runtime.

.DESCRIPTION
    Copies a fixed allowlist of managed files into your agent homes. Idempotent: a destination
    whose content already matches the source is left untouched. When a managed destination
    differs, a timestamped backup is written beside it before it is replaced.

    This installer deliberately does NOT edit settings.json, hooks.json, CLAUDE.md, AGENTS.md
    or GEMINI.md, because those files hold your other configuration and are merged by hand.
    -Check reports whether the hook wiring is present in each of them, but never writes to them.

.EXAMPLE
    .\install-frictionmax.ps1
.EXAMPLE
    .\install-frictionmax.ps1 -Check
#>
[CmdletBinding()]
param(
    [string]$SourceRoot,
    [string]$BinRoot,
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path)
}

function Get-AllowlistedPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $rootFull = Get-FullPath -Path $Root
    $sep = [System.IO.Path]::DirectorySeparatorChar
    $rootPrefix = $rootFull.TrimEnd($sep, [System.IO.Path]::AltDirectorySeparatorChar) + $sep
    $candidate = [System.IO.Path]::GetFullPath((Join-Path -Path $rootFull -ChildPath $RelativePath))
    if (-not $candidate.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing path outside root: $RelativePath"
    }
    return $candidate
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = $PSScriptRoot
}
$SourceRoot = Get-FullPath -Path $SourceRoot
# SKILL.md lives one directory above this script (skills/friction-maxxing/), while the runtime
# assets (this file included) live alongside it in skills/friction-maxxing/assets/.
$SkillRoot = Get-FullPath -Path (Join-Path -Path $SourceRoot -ChildPath '..')

if ([string]::IsNullOrWhiteSpace($BinRoot)) {
    $BinRoot = Join-Path -Path $HOME -ChildPath '.local\bin'
}
$BinRoot = Get-FullPath -Path $BinRoot

$claudeHome = Join-Path -Path $HOME -ChildPath '.claude'
$agentsHome = Join-Path -Path $HOME -ChildPath '.agents'

$codexHome = [Environment]::GetEnvironmentVariable('CODEX_HOME')
if ([string]::IsNullOrWhiteSpace($codexHome)) {
    $codexHome = Join-Path -Path $HOME -ChildPath '.codex'
}
$codexHome = Get-FullPath -Path $codexHome

# --- managed allowlist -------------------------------------------------------
# Nothing outside this list is ever written.
$managed = @(
    @{ SourceRoot = $SourceRoot; Source = 'frictionmax.cmd'; Destination = (Get-AllowlistedPath -Root $BinRoot -RelativePath 'frictionmax.cmd') }
    @{ SourceRoot = $SourceRoot; Source = 'frictionmax.mjs'; Destination = (Get-AllowlistedPath -Root $BinRoot -RelativePath 'frictionmax\frictionmax.mjs') }
    @{ SourceRoot = $SourceRoot; Source = 'mandate.md';      Destination = (Get-AllowlistedPath -Root $BinRoot -RelativePath 'frictionmax\mandate.md') }
    @{ SourceRoot = $SourceRoot; Source = 'rearm.txt';       Destination = (Get-AllowlistedPath -Root $BinRoot -RelativePath 'frictionmax\rearm.txt') }
    @{ SourceRoot = $SkillRoot;  Source = 'SKILL.md';        Destination = (Get-AllowlistedPath -Root $agentsHome -RelativePath 'skills\friction-maxxing\SKILL.md') }
    @{ SourceRoot = $SkillRoot;  Source = 'SKILL.md';        Destination = (Get-AllowlistedPath -Root $claudeHome -RelativePath 'skills\friction-maxxing\SKILL.md') }
    @{ SourceRoot = $SkillRoot;  Source = 'SKILL.md';        Destination = (Get-AllowlistedPath -Root $codexHome  -RelativePath 'skills\friction-maxxing\SKILL.md') }
)

# --- hook wiring, reported but never written ---------------------------------
# A generic check of the three per-agent config paths that carry the hook wiring. This
# installer never opens them for writing; it only reports whether each looks wired.
$wiring = @(
    @{ Name = 'Claude settings.json'; Path = (Join-Path $claudeHome 'settings.json') }
    @{ Name = 'Codex hooks.json';     Path = (Join-Path $codexHome  'hooks.json') }
    @{ Name = 'Gemini settings.json'; Path = (Join-Path $HOME '.gemini\settings.json') }
)

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmssfff')
$problems = 0

Write-Host "friction-maxxing" -ForegroundColor Cyan
Write-Host "  source: $SourceRoot"
Write-Host ""

foreach ($item in $managed) {
    $sourcePath = Get-AllowlistedPath -Root $item.SourceRoot -RelativePath $item.Source
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Managed source file is missing: $sourcePath"
    }

    $destinationPath = $item.Destination
    if ((Test-Path -LiteralPath $destinationPath) -and -not (Test-Path -LiteralPath $destinationPath -PathType Leaf)) {
        throw "Cannot replace non-file destination: $destinationPath"
    }

    $sourceHash = Get-Sha256 -Path $sourcePath
    $destinationHash = Get-Sha256 -Path $destinationPath

    if ($destinationHash -eq $sourceHash) {
        Write-Host "  OK       $destinationPath"
        continue
    }

    if ($null -eq $destinationHash) { $state = 'MISSING' } else { $state = 'STALE' }

    if ($Check) {
        Write-Host "  $state  $destinationPath" -ForegroundColor Yellow
        $problems++
        continue
    }

    $parent = Split-Path -Parent $destinationPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if ($null -ne $destinationHash) {
        $backupPath = "$destinationPath.bak-$stamp"
        Copy-Item -LiteralPath $destinationPath -Destination $backupPath -Force
        Write-Host "  BACKUP   $backupPath" -ForegroundColor DarkGray
    }

    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    Write-Host "  WROTE    $destinationPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "  hook wiring (read-only check, never written by this installer)"
foreach ($entry in $wiring) {
    if (-not (Test-Path -LiteralPath $entry.Path -PathType Leaf)) {
        Write-Host "    ABSENT   $($entry.Name) - file does not exist" -ForegroundColor Yellow
        $problems++
        continue
    }
    $content = Get-Content -LiteralPath $entry.Path -Raw
    if ($content -match 'friction') {
        Write-Host "    OK       $($entry.Name)"
    } else {
        Write-Host "    UNWIRED  $($entry.Name) - no friction-maxxing reference" -ForegroundColor Yellow
        $problems++
    }
}

Write-Host ""
if ($Check) {
    if ($problems -gt 0) {
        Write-Host "  $problems item(s) missing, stale or unwired." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  All managed files current and all agents wired." -ForegroundColor Green
    exit 0
}

if ($problems -gt 0) {
    Write-Host "  Files installed. $problems wiring item(s) still need a manual merge - see references/agent-wiring.md." -ForegroundColor Yellow
} else {
    Write-Host "  Installed. Start a fresh session in each agent to pick up changes." -ForegroundColor Green
}
exit 0
