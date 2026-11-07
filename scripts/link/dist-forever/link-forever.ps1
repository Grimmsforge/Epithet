# link-forever.ps1 - Link the dist/forever build into the WoW Forever AddOns folder
# Use this to test the packaged forever distribution before uploading.
# Run scripts/build/build.ps1 first to generate dist/forever/Epithet.

$addonsPath = "A:\Blizzard\World of Warcraft\_forever_\Interface\Addons"
$linkPath = Join-Path $addonsPath "Epithet"
$root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$targetPath = Join-Path $root "dist\forever\Epithet"

if (-not (Test-Path $targetPath)) {
    Write-Host "ERROR: dist/forever/Epithet does not exist. Run scripts/build/build.ps1 first." -ForegroundColor Red
    exit 1
}

if (Test-Path $linkPath) {
    $item = Get-Item $linkPath -Force
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        $existingTarget = $item.Target
        if ($existingTarget -eq $targetPath) {
            Write-Host "Junction already points to forever dist: $linkPath" -ForegroundColor Yellow
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
Write-Host "You are now testing the FOREVER distribution package." -ForegroundColor Cyan