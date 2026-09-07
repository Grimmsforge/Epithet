# build.ps1 - Creates dist/ with release and PTR zips ready for CurseForge
# Usage:
#   ./scripts/build/build.ps1                 # build only
#   ./scripts/build/build.ps1 -Bump patch    # 0.1.0 -> 0.1.1, then build
#   ./scripts/build/build.ps1 -Bump minor    # 0.1.0 -> 0.2.0, then build
#   ./scripts/build/build.ps1 -Bump major    # 0.1.0 -> 1.0.0, then build

param(
    [ValidateSet("major", "minor", "patch")]
    [string]$Bump
)

$ErrorActionPreference = "Stop"

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$tocFile = Join-Path $root "Epithet.toc"

# Interface versions
$INTERFACE_LIVE = "120100"   # 12.1.0, live since 2026-08-11
$INTERFACE_PTR  = "120105"   # 12.1.5 PTR

# --- Version bump ---
if ($Bump) {
    # Read current version from .toc
    $tocContent = Get-Content $tocFile -Raw
    if ($tocContent -match '## Version:\s*(\d+)\.(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
    } else {
        throw "Could not parse version from Epithet.toc"
    }

    $old = "$major.$minor.$patch"

    switch ($Bump) {
        "major" { $major++; $minor = 0; $patch = 0 }
        "minor" { $minor++; $patch = 0 }
        "patch" { $patch++ }
    }

    $new = "$major.$minor.$patch"

    # Update .toc
    $tocContent = $tocContent -replace "## Version:\s*$([regex]::Escape($old))", "## Version: $new"
    Set-Content $tocFile $tocContent -NoNewline

    Write-Host "Version bumped: $old -> $new" -ForegroundColor Cyan
}

# --- Build ---
$distDir = Join-Path $root "dist"

# Clean previous build
if (Test-Path $distDir) {
    Remove-Item $distDir -Recurse -Force
}

# Read version for zip naming
$tocContent = Get-Content $tocFile -Raw
if ($tocContent -match '## Version:\s*(\d+\.\d+\.\d+)') {
    $version = $Matches[1]
} else {
    $version = "unknown"
}

# Build function: creates addon folder, patches interface version, zips it
function Build-Variant {
    param([string]$InterfaceVersion, [string]$Suffix)

    $variantDir = Join-Path $distDir $Suffix
    $addonDir = Join-Path $variantDir "Epithet"

    New-Item -ItemType Directory -Path $addonDir -Force | Out-Null

    # Copy addon files
    Copy-Item (Join-Path $root "Epithet.toc") -Destination $addonDir
    Copy-Item (Join-Path $root "LICENSE") -Destination $addonDir
    Copy-Item (Join-Path $root "NOTICE") -Destination $addonDir

    # Copy directories (names must match TOC paths exactly for case-sensitive OS)
    Copy-Item (Join-Path $root "Core") -Destination (Join-Path $addonDir "Core") -Recurse

    # Developer-only modules must not ship. They are gitignored and commented out
    # of the TOC for public builds, but Core/ is copied wholesale so they would
    # otherwise still ride along inside the zip. Pattern-based so any future
    # *.local.lua is covered without touching this again.
    Get-ChildItem (Join-Path $addonDir "Core") -Filter "*.local.lua" -Recurse -File |
        Remove-Item -Force
    Copy-Item (Join-Path $root "data") -Destination (Join-Path $addonDir "data") -Recurse
    # Fonts carries the bundled Unicode faces (PT Sans/Serif). Without them
    # Theme.lua's SetFont fails and falls back to the client font, so any locale
    # in BUNDLED_FONT_LOCALES (Russian) renders as boxes in a packaged build even
    # though it looks fine running from the repo folder.
    Copy-Item (Join-Path $root "Fonts") -Destination (Join-Path $addonDir "Fonts") -Recurse
    Copy-Item (Join-Path $root "Locales") -Destination (Join-Path $addonDir "Locales") -Recurse
    Copy-Item (Join-Path $root "Spotting") -Destination (Join-Path $addonDir "Spotting") -Recurse
    Copy-Item (Join-Path $root "UI") -Destination (Join-Path $addonDir "UI") -Recurse
    Copy-Item (Join-Path $root "WhatsNew") -Destination (Join-Path $addonDir "WhatsNew") -Recurse
    Copy-Item (Join-Path $root "icons") -Destination (Join-Path $addonDir "icons") -Recurse
    Copy-Item (Join-Path $root "logo") -Destination (Join-Path $addonDir "logo") -Recurse

    $aboutLogo = Join-Path $addonDir "logo\grimmsforge-logo.tga"
    if (-not (Test-Path $aboutLogo)) {
        throw "Required About modal logo is missing from the package: $aboutLogo"
    }

    # Copy libs if present (populated by .pkgmeta or manual install)
    $libsDir = Join-Path $root "libs"
    if (Test-Path $libsDir) {
        Copy-Item $libsDir -Destination $addonDir -Recurse
    }

    # Patch Interface version in the .toc copy
    $tocPath = Join-Path $addonDir "Epithet.toc"
    $content = Get-Content $tocPath -Raw
    $content = $content -replace '## Interface:\s*\d+', "## Interface: $InterfaceVersion"
    Set-Content $tocPath $content -NoNewline

    # Create zip
    $zipName = "Epithet-$version-$Suffix.zip"
    $zipPath = Join-Path $distDir $zipName
    Compress-Archive -Path $addonDir -DestinationPath $zipPath -Force

    Write-Host "  $zipName (Interface: $InterfaceVersion)" -ForegroundColor White
}

Write-Host ""
Write-Host "Building Epithet v$version..." -ForegroundColor Cyan
Write-Host ""

# Build both variants
Write-Host "Zips:" -ForegroundColor Green
Build-Variant -InterfaceVersion $INTERFACE_LIVE -Suffix "release"
Build-Variant -InterfaceVersion $INTERFACE_PTR  -Suffix "ptr"

# Show contents of the release build
$releaseAddonDir = Join-Path $distDir "release\Epithet"
Write-Host ""
Write-Host "Contents:" -ForegroundColor Green
Get-ChildItem $releaseAddonDir -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring($releaseAddonDir.Length + 1)
    if ($_.PSIsContainer) { Write-Host "  $rel/" } else { Write-Host "  $rel" }
}
Write-Host ""
Write-Host "Ready to upload to CurseForge:" -ForegroundColor Green
Write-Host "  dist/Epithet-$version-release.zip  -> Midnight (live)" -ForegroundColor White
Write-Host "  dist/Epithet-$version-ptr.zip      -> PTR/Beta" -ForegroundColor White
