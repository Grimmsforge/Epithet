# link-addon.ps1 - Create a junction from the WoW Forever AddOns folder to this repo

$addonsPath = "A:\Blizzard\World of Warcraft\_forever_\Interface\Addons"
$linkPath = Join-Path $addonsPath "Epithet"
$repoPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent

if (Test-Path $linkPath) {
    $item = Get-Item $linkPath -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "Symlink already exists: $linkPath" -ForegroundColor Yellow
    } else {
        Write-Host "WARNING: $linkPath exists and is not a symlink. Remove it manually first." -ForegroundColor Red
        exit 1
    }
} else {
    New-Item -ItemType Junction -Path $linkPath -Target $repoPath | Out-Null
    Write-Host "Junction created: $linkPath -> $repoPath" -ForegroundColor Green
}