# link-release.ps1 - Link the dist/retail build into the WoW Retail AddOns folder
# Use this to test the packaged release distribution before uploading.
# Run scripts/build/build.ps1 first to generate dist/retail/Epithet.

$addonsPath = "A:\Blizzard\World of Warcraft\_retail_\Interface\Addons"
$linkPath = Join-Path $addonsPath "Epithet"
$root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$targetPath = Join-Path $root "dist\retail\Epithet"

if (-not (Test-Path $targetPath)) {
    Write-Host "ERROR: dist/retail/Epithet does not exist. Run scripts/build/build.ps1 first." -ForegroundColor Red
    exit 1
}

if (Test-Path $linkPath) {
    $item = Get-Item $linkPath -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        $existingTarget = $item.Target
        if ($existingTarget -eq $targetPath) {
            Write-Host "Junction already points to release dist: $linkPath" -ForegroundColor Yellow
            exit 0
        }
        Write-Host "Removing existing junction: $linkPath -> $existingTarget" -ForegroundColor Yellow
        Remove-Item $linkPath -Force
    } else {
        Write-Host "WARNING: $linkPath exists and is not a symlink. Remove it manually first." -ForegroundColor Red
        exit 1
    }
}

New-Item -ItemType Junction -Path $linkPath -Target $targetPath | Out-Null
Write-Host "Junction created: $linkPath -> $targetPath" -ForegroundColor Green
Write-Host "You are now testing the RELEASE distribution package." -ForegroundColor Cyan