<#
.SYNOPSIS
    Keeps Epithet's flavour differences (Retail vs WoW Forever) where they belong.

.DESCRIPTION
    Epithet is one addon for every flavour. What differs lives in four places
    only (see docs/FLAVOURS.md):
      data/<flavour>/       title data
      Flavors/<Flavour>/    theme overrides, flavour settings, achievement list
      WhatsNew/<Flavour>/   release notes
      ns.Flavor.<setting>   switches the shared code reads (Core/Flavor.lua)

    This validator checks:
      1. Shared code (Core/, UI/, Spotting/) never asks which flavour it is on:
         no "camelot", no "forever" string, no ns.Flavor.id, no WOW_PROJECT_*,
         no interface-number checks. Shared code reads a ns.Flavor setting instead.
      2. Every file in a flavour folder is gated in Epithet.toc with that
         flavour's game type (retail = standard, forever = camelot).
      3. No file outside a flavour folder is gated: shared files load everywhere.
      4. Every Lua file in a flavour folder is listed in the TOC (warning).

.EXAMPLE
    powershell -File scripts\validate\validate-flavours.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 leaves $PSScriptRoot empty in parameter defaults.
if (-not $RepoRoot) { $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }

$errors = 0
$warnings = 0
function Report-Error([string]$msg) { Write-Host "  ERROR: $msg" -ForegroundColor Red; $script:errors++ }
function Report-Warning([string]$msg) { Write-Host "  WARNING: $msg" -ForegroundColor Yellow; $script:warnings++ }

# Flavour folder name (lower case) -> TOC game type.
$GameTypeOf = @{ retail = 'standard'; forever = 'camelot' }
# Folders that hold one subfolder per flavour.
$FlavourRoots = @('data', 'Flavors', 'WhatsNew')

function Get-FlavourOf([string]$rel) {
    $parts = $rel -split '[\\/]'
    if ($parts.Count -ge 3 -and $FlavourRoots -contains $parts[0]) {
        $name = $parts[1].ToLower()
        if ($GameTypeOf.ContainsKey($name)) { return $name }
    }
    return $null
}

# --- 1. Shared code never branches on the flavour ---------------------------
Write-Host ""
Write-Host "== Shared code ==" -ForegroundColor White
$patterns = @(
    @{ Re = '(?i)\bcamelot\b';                 Why = 'names the Forever game type' }
    @{ Re = '(?i)["'']forever["'']';           Why = 'compares against "forever"' }
    @{ Re = '\bFlavor\.id\b';                  Why = 'branches on ns.Flavor.id' }
    @{ Re = '\bWOW_PROJECT_';                  Why = 'branches on WOW_PROJECT_ID' }
    @{ Re = '(?i)\bIsForever\b|\bIS_FOREVER\b'; Why = 'branches on a Forever flag' }
    @{ Re = '\b1600[0-9]\b|\b1201[0-9]{2}\b';  Why = 'compares an interface number' }
)
$shared = foreach ($dir in @('Core', 'UI', 'Spotting')) {
    $p = Join-Path $RepoRoot $dir
    if (Test-Path $p) { Get-ChildItem -LiteralPath $p -Recurse -File -Include '*.lua', '*.xml' }
}
$checked = 0
foreach ($file in $shared) {
    if ($file.Name -like '*.local.lua') { continue }  # developer-only, never shipped
    $rel = $file.FullName.Substring($RepoRoot.Length + 1)
    $checked++
    $n = 0
    foreach ($line in Get-Content -LiteralPath $file.FullName) {
        $n++
        if ($line -match '^\s*--') { continue }
        $code = ($line -replace '\s--.*$', '')
        foreach ($p in $patterns) {
            if ($code -match $p.Re) {
                Report-Error "${rel}:${n}: $($p.Why). Shared code reads a ns.Flavor setting (Core/Flavor.lua) instead; the flavour sets it in Flavors/<Flavour>/Flavor.lua."
            }
        }
    }
}
Write-Host "  $checked shared file(s) checked" -ForegroundColor Green

# --- 2-4. TOC gates match the folders -----------------------------------------
Write-Host ""
Write-Host "== TOC gates ==" -ForegroundColor White
$tocPath = Join-Path $RepoRoot 'Epithet.toc'
$listed = @{}
$n = 0
foreach ($line in Get-Content -LiteralPath $tocPath) {
    $n++
    if ($line -match '^\s*#') { continue }
    $m = [regex]::Match($line, '^\s*([^\s\[]+\.(?:lua|xml))\s*(?:\[(Allow|Exclude)LoadGameType\s+([a-z|]+)\])?')
    if (-not $m.Success) { continue }
    $rel = $m.Groups[1].Value
    $gate = $m.Groups[2].Value
    # Assigned directly: an if-expression would unwrap a one-item array to a string.
    $types = @()
    if ($m.Groups[3].Success) { $types = @($m.Groups[3].Value -split '\|') }
    $listed[$rel.ToLower()] = $true
    $flavour = Get-FlavourOf $rel
    if ($flavour) {
        $want = $GameTypeOf[$flavour]
        if ($gate -ne 'Allow' -or $types.Count -ne 1 -or $types[0] -ne $want) {
            Report-Error "Epithet.toc:${n}: $rel is in the $flavour folder, so it needs [AllowLoadGameType $want]"
        }
    } elseif ($gate) {
        Report-Error "Epithet.toc:${n}: $rel is gated but is not in a flavour folder. Shared files load everywhere; move flavour-only files to data/, Flavors/ or WhatsNew/<flavour>/."
    }
}
foreach ($root in $FlavourRoots) {
    $p = Join-Path $RepoRoot $root
    if (-not (Test-Path $p)) { continue }
    foreach ($file in Get-ChildItem -LiteralPath $p -Recurse -File -Filter '*.lua') {
        $rel = $file.FullName.Substring($RepoRoot.Length + 1)
        if (-not (Get-FlavourOf $rel)) { continue }
        if (-not $listed.ContainsKey($rel.ToLower())) {
            Report-Warning "$rel is in a flavour folder but not listed in Epithet.toc, so it never loads"
        }
    }
}
Write-Host "  $($listed.Count) TOC file(s) checked" -ForegroundColor Green

Write-Host ""
if ($errors -gt 0) {
    Write-Host "FAILED: $errors error(s) found." -ForegroundColor Red
    exit 1
}
Write-Host "OK: no errors." -ForegroundColor Green
exit 0
