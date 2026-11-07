<#
.SYNOPSIS
    Junctions the dev-only Epithet Probe into a WoW client's AddOns folder.

.EXAMPLE
    powershell -File scripts\probe\link-probe.ps1 -Client forever
    powershell -File scripts\probe\link-probe.ps1 -Client retail -Remove
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('retail', 'forever')]
    [string]$Client,
    [switch]$Remove,
    [string]$WowRoot = 'A:\Blizzard\World of Warcraft'
)

$ErrorActionPreference = 'Stop'
$folder = @{ retail = '_retail_'; forever = '_forever_' }[$Client]
$addonsPath = Join-Path $WowRoot "$folder\Interface\AddOns"
$linkPath = Join-Path $addonsPath 'EpithetProbe'
$target = (Resolve-Path (Join-Path $PSScriptRoot '..\..\tools\probe\EpithetProbe')).Path

if ($Remove) {
    if (-not (Test-Path $linkPath)) { Write-Host "Nothing to remove: $linkPath" -ForegroundColor Yellow; exit 0 }
    $item = Get-Item $linkPath -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Remove-Item $linkPath -Force
        Write-Host "Junction removed: $linkPath" -ForegroundColor Green
        exit 0
    }
    Write-Host "WARNING: $linkPath is not a junction. Skipping to avoid data loss." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $addonsPath)) { Write-Host "ERROR: $addonsPath does not exist." -ForegroundColor Red; exit 1 }
if (Test-Path $linkPath) {
    $item = Get-Item $linkPath -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "Junction already exists: $linkPath" -ForegroundColor Yellow
        exit 0
    }
    Write-Host "WARNING: $linkPath exists and is not a junction. Remove it manually first." -ForegroundColor Red
    exit 1
}
New-Item -ItemType Junction -Path $linkPath -Target $target | Out-Null
Write-Host "Junction created: $linkPath -> $target" -ForegroundColor Green
Write-Host "In game: /eprobe textures, then target players and /eprobe names, then /reload." -ForegroundColor Cyan
