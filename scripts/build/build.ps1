# build.ps1 - Creates dist/<target>/ and a zip per target (retail, ptr, forever)
# ready for CurseForge.
#
# Usage:
#   ./scripts/build/build.ps1                 # checks, then build
#   ./scripts/build/build.ps1 -SkipChecks     # build without validators and tests
#   ./scripts/build/build.ps1 -Bump patch     # 0.1.0 -> 0.1.1, then build
#   ./scripts/build/build.ps1 -Bump minor     # 0.1.0 -> 0.2.0, then build
#   ./scripts/build/build.ps1 -Bump major     # 0.1.0 -> 1.0.0, then build
#
# Each zip is lean: it holds only what its game loads. The build reads the TOC's
# per-file [AllowLoadGameType ...] / [ExcludeLoadGameType ...] gates and drops
# the lines and files the target's game type never loads, plus any Epithet
# asset (icons, ...) that only those dropped files name. So the Forever zip has
# no Retail title data, and the Retail zip has no Forever ring texture.
# See docs/FLAVOURS.md.

param(
    [ValidateSet("major", "minor", "patch")]
    [string]$Bump,
    [switch]$SkipChecks
)

$ErrorActionPreference = "Stop"

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$tocFile = Join-Path $root "Epithet.toc"

# Build targets: the one place that lists interface numbers. Each target's zip
# gets its own "## Interface:" line and only the files its game type loads. The
# source TOC lists every value so the repo loads on every client straight from a
# junction.
#   retail / ptr : game type "standard" (Retail; PTR is the same game, same data)
#   forever      : game type "camelot" (WoW Forever)
$Targets = @(
    @{ Name = 'retail';  Interface = '120105'; GameType = 'standard'; Label = 'Midnight (live)' }   # 12.1.5
    @{ Name = 'ptr';     Interface = '120107'; GameType = 'standard'; Label = 'PTR/Beta' }          # 12.1.7
    @{ Name = 'forever'; Interface = '16001';  GameType = 'camelot';  Label = 'WoW Forever' }       # 1.60.1
)

# Per-flavour data folders. data/ has one folder per flavour and nothing at its
# root (see .gitignore); TitlesDBCollector writes into these.
$DataFlavors = @('retail', 'forever')

# Each flavour folder's game type: data/<flavour>/, Flavors/<Flavour>/ and
# WhatsNew/<Flavour>/ ship only in that game type's packages.
$FlavourGameType = @{ retail = 'standard'; forever = 'camelot' }
$FlavourRoots = @('data', 'Flavors', 'WhatsNew')

# --- Checks: validators and tests (skip with -SkipChecks) ---
function Invoke-Check([string]$Label, [scriptblock]$Run) {
    Write-Host "  $Label" -ForegroundColor Gray
    & $Run
    if ($LASTEXITCODE -ne 0) {
        throw "Check failed: $Label. Fix it, or build with -SkipChecks if you know why."
    }
}

if (-not $SkipChecks) {
    Write-Host ""
    Write-Host "Checks:" -ForegroundColor Cyan
    $validate = Join-Path $root "scripts\validate"
    Invoke-Check "validate-flavours" { powershell -NoProfile -File (Join-Path $validate "validate-flavours.ps1") | Out-Null }
    Invoke-Check "validate-theme" { powershell -NoProfile -File (Join-Path $validate "validate-theme.ps1") | Out-Null }
    Invoke-Check "validate-locales" {
        powershell -NoProfile -File (Join-Path $validate "validate-locales.ps1") -RepoRoot $root -LocalesDir (Join-Path $root "Locales") | Out-Null
    }
    Invoke-Check "validate-titlesdb-locales" { powershell -NoProfile -File (Join-Path $validate "validate-titlesdb-locales.ps1") | Out-Null }

    $testsDir = Join-Path $root "tools\tests"
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        throw "Node.js is needed to run the tests (tools/tests). Install it, or build with -SkipChecks."
    }
    if (-not (Test-Path (Join-Path $testsDir "node_modules\fengari"))) {
        throw "The tests' Lua VM is not installed. Run: cd tools/tests; npm install  (or build with -SkipChecks)."
    }
    Invoke-Check "tests (tools/tests)" {
        $out = & node (Join-Path $testsDir "run-all.js") 2>&1
        if ($LASTEXITCODE -ne 0) { $out | ForEach-Object { Write-Host "    $_" } }
        else { Write-Host "    $($out | Select-Object -Last 1)" -ForegroundColor Gray }
    }
}

# --- Data layout checks (before anything is bumped or deleted) ---
# A file at data/'s root is never loaded (the TOC only lists data\<flavour>\...),
# and usually means the collector wrote there with an old path, leaving the
# flavour folder stale. Fail rather than ship stale data.
$dataDir = Join-Path $root "data"
$strays = @(Get-ChildItem $dataDir -Force | Where-Object {
    $_.Name -ne '.gitkeep' -and -not ($_.PSIsContainer -and $DataFlavors -contains $_.Name)
})
if ($strays.Count -gt 0) {
    $names = ($strays | ForEach-Object { $_.Name }) -join ', '
    throw "Unexpected entries at the data/ root: $names. Every data file belongs under data/<flavour>/ ($($DataFlavors -join ', ')). Move them, or point TitlesDBCollector's epithetDataDir at the flavour folder."
}

# Every data file the TOC lists must exist, or that flavour loads with no titles.
$missing = @()
foreach ($line in (Get-Content $tocFile)) {
    if ($line -match '^\s*(data\\[^\s\[]+)') {
        $rel = $Matches[1]
        if (-not (Test-Path (Join-Path $root $rel))) { $missing += $rel }
    }
}
if ($missing.Count -gt 0) {
    throw "TOC-listed data files are missing: $($missing -join ', '). Generate them with TitlesDBCollector (scripts/copy-output.ps1 -Flavor <flavour>)."
}

# --- Version bump ---
if ($Bump) {
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

    $tocContent = $tocContent -replace "## Version:\s*$([regex]::Escape($old))", "## Version: $new"
    Set-Content $tocFile $tocContent -NoNewline
    Write-Host "Version bumped: $old -> $new" -ForegroundColor Cyan
}

# --- Build ---
$distDir = Join-Path $root "dist"
if (Test-Path $distDir) {
    Remove-Item $distDir -Recurse -Force
}

$tocContent = Get-Content $tocFile -Raw
if ($tocContent -match '## Version:\s*(\d+\.\d+\.\d+)') {
    $version = $Matches[1]
} else {
    $version = "unknown"
}

# Whether a TOC file line loads on a game type. Ungated lines load everywhere.
function Test-LoadsOn([string]$Line, [string]$GameType) {
    $m = [regex]::Match($Line, '\[(Allow|Exclude)LoadGameType\s+([a-z|]+)\]')
    if (-not $m.Success) { return $true }
    $types = @($m.Groups[2].Value -split '\|')
    if ($m.Groups[1].Value -eq 'Allow') { return ($types -contains $GameType) }
    return -not ($types -contains $GameType)
}

# Drops what a target never loads: TOC lines and their files, then Epithet
# assets named only by dropped files. Returns the removed paths.
function Remove-UnusedForTarget([string]$AddonDir, [string]$GameType) {
    $tocPath = Join-Path $AddonDir "Epithet.toc"
    $lines = [IO.File]::ReadAllText($tocPath) -split "`r?`n"
    $kept = New-Object System.Collections.Generic.List[string]
    $dropped = @()
    $keptFiles = @{}
    foreach ($line in $lines) {
        $m = [regex]::Match($line, '^\s*(?!#)([^\s\[]+\.(?:lua|xml))')
        if ($m.Success -and -not (Test-LoadsOn $line $GameType)) {
            $dropped += $m.Groups[1].Value
            continue
        }
        if ($m.Success) { $keptFiles[$m.Groups[1].Value.ToLower()] = $true }
        $kept.Add($line)
    }
    [IO.File]::WriteAllText($tocPath, ($kept -join "`r`n"))

    $removed = @()
    $droppedText = ""
    foreach ($rel in $dropped) {
        if ($keptFiles.ContainsKey($rel.ToLower())) { continue }   # listed again, ungated
        $full = Join-Path $AddonDir $rel
        if (Test-Path $full) {
            $droppedText += [IO.File]::ReadAllText($full) + "`n"
            Remove-Item $full -Force
            $removed += $rel
        }
    }

    # Assets the dropped files name ("Interface\\AddOns\\Epithet\\icons\\..."),
    # removed when no kept Lua or XML file mentions them by name. Theme.lua
    # builds paths from a prefix, so the check is on the file's base name.
    $assetRe = [regex]'(?i)Interface\\{1,2}AddOns\\{1,2}Epithet\\{1,2}([^"''\]\s]+)'
    $keptText = $null
    foreach ($am in $assetRe.Matches($droppedText)) {
        $assetRel = ($am.Groups[1].Value -replace '\\{1,2}', '\')
        $base = Split-Path $assetRel -Leaf
        if ($null -eq $keptText) {
            $keptText = (Get-ChildItem $AddonDir -Recurse -File -Include '*.lua', '*.xml' |
                ForEach-Object { [IO.File]::ReadAllText($_.FullName) }) -join "`n"
        }
        if ($keptText.IndexOf($base, [StringComparison]::OrdinalIgnoreCase) -ge 0) { continue }
        foreach ($ext in @('', '.tga', '.blp', '.png')) {
            $full = Join-Path $AddonDir ($assetRel + $ext)
            if ((Test-Path $full) -and -not (Get-Item $full).PSIsContainer) {
                Remove-Item $full -Force
                $removed += ($assetRel + $ext)
            }
        }
    }

    # The other flavours' folders, whatever is left in them (schema.json, ...).
    foreach ($rootName in $FlavourRoots) {
        $rootDir = Join-Path $AddonDir $rootName
        if (-not (Test-Path $rootDir)) { continue }
        foreach ($dir in Get-ChildItem $rootDir -Directory) {
            $type = $FlavourGameType[$dir.Name.ToLower()]
            if ($type -and $type -ne $GameType) {
                foreach ($f in Get-ChildItem $dir.FullName -Recurse -File -Force) {
                    $removed += $f.FullName.Substring($AddonDir.Length + 1)
                }
                Remove-Item $dir.FullName -Recurse -Force
            }
        }
    }

    # Folders the removals emptied.
    Get-ChildItem $AddonDir -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending |
        Where-Object { -not (Get-ChildItem $_.FullName -Force) } | Remove-Item -Force
    return $removed
}

# Build function: creates the addon folder, patches the interface version,
# trims it to the target's game type, checks it and zips it.
function Build-Variant {
    param([hashtable]$Target)

    $variantDir = Join-Path $distDir $Target.Name
    $addonDir = Join-Path $variantDir "Epithet"
    New-Item -ItemType Directory -Path $addonDir -Force | Out-Null

    Copy-Item (Join-Path $root "Epithet.toc") -Destination $addonDir
    Copy-Item (Join-Path $root "LICENSE") -Destination $addonDir
    Copy-Item (Join-Path $root "NOTICE") -Destination $addonDir

    # Directories (names must match TOC paths exactly for case-sensitive OS).
    Copy-Item (Join-Path $root "Core") -Destination (Join-Path $addonDir "Core") -Recurse
    # Developer-only modules must not ship. Core/ is copied wholesale so remove
    # any *.local.lua files and their active TOC entries from the package.
    Get-ChildItem (Join-Path $addonDir "Core") -Filter "*.local.lua" -Recurse -File | Remove-Item -Force
    Copy-Item (Join-Path $root "data") -Destination (Join-Path $addonDir "data") -Recurse
    # Fonts carries the bundled Unicode faces (PT Sans/Serif). Without them
    # Theme.lua's SetFont fails and falls back to the client font, so any locale
    # in BUNDLED_FONT_LOCALES (Russian) renders as boxes in a packaged build even
    # though it looks fine running from the repo folder.
    Copy-Item (Join-Path $root "Fonts") -Destination (Join-Path $addonDir "Fonts") -Recurse
    Copy-Item (Join-Path $root "Locales") -Destination (Join-Path $addonDir "Locales") -Recurse
    Copy-Item (Join-Path $root "Spotting") -Destination (Join-Path $addonDir "Spotting") -Recurse
    # Flavour-only files (theme overrides, settings, achievement lists).
    Copy-Item (Join-Path $root "Flavors") -Destination (Join-Path $addonDir "Flavors") -Recurse
    Copy-Item (Join-Path $root "UI") -Destination (Join-Path $addonDir "UI") -Recurse
    Copy-Item (Join-Path $root "WhatsNew") -Destination (Join-Path $addonDir "WhatsNew") -Recurse
    Copy-Item (Join-Path $root "icons") -Destination (Join-Path $addonDir "icons") -Recurse
    Copy-Item (Join-Path $root "logo") -Destination (Join-Path $addonDir "logo") -Recurse
    # The data folder's .gitkeep placeholders are not part of the addon.
    Get-ChildItem (Join-Path $addonDir "data") -Recurse -Force -Filter ".gitkeep" | Remove-Item -Force

    $aboutLogo = Join-Path (Join-Path $addonDir "logo") "grimmsforge-logo.tga"
    if (-not (Test-Path $aboutLogo)) {
        throw "Required About modal logo is missing from the package: $aboutLogo"
    }

    # Libs, if present (populated by .pkgmeta or manual install).
    $libsDir = Join-Path $root "libs"
    if (Test-Path $libsDir) {
        Copy-Item $libsDir -Destination $addonDir -Recurse
    }

    # The interface line, and no developer-only TOC entries.
    $tocPath = Join-Path $addonDir "Epithet.toc"
    $content = Get-Content $tocPath -Raw
    $content = $content -replace '(?m)^## Interface:[^\r\n]*', "## Interface: $($Target.Interface)"
    $content = $content -replace '(?m)^[^\r\n#]*\.local\.lua[^\r\n]*(?:\r?\n|$)', ''
    Set-Content $tocPath $content -NoNewline

    # Only what this game loads.
    $removed = @(Remove-UnusedForTarget -AddonDir $addonDir -GameType $Target.GameType)

    # Every file the packaged TOC lists must be in the package, or the client
    # silently skips it. libs\ is checked only when the libs were fetched.
    $content = Get-Content $tocPath -Raw
    $hasLibs = Test-Path (Join-Path $addonDir "libs")
    $missingInPackage = @()
    foreach ($line in ($content -split "`r?`n")) {
        if ($line -match '^\s*(?!#)([^\s\[]+\.(?:lua|xml))') {
            $rel = $Matches[1]
            if (-not $hasLibs -and $rel -like 'libs\*') { continue }
            if (-not (Test-Path (Join-Path $addonDir $rel))) { $missingInPackage += $rel }
        }
    }
    if ($missingInPackage.Count -gt 0) {
        throw "Package '$($Target.Name)' is missing TOC-listed files: $($missingInPackage -join ', ')"
    }
    # And none of the other game's files may remain listed.
    foreach ($line in ($content -split "`r?`n")) {
        if ($line -match '^\s*(?!#)[^\s\[]+\.(?:lua|xml)' -and -not (Test-LoadsOn $line $Target.GameType)) {
            throw "Package '$($Target.Name)' still lists a file its game never loads: $line"
        }
    }

    $zipName = "Epithet-$version-$($Target.Name).zip"
    $zipPath = Join-Path $distDir $zipName
    Compress-Archive -Path $addonDir -DestinationPath $zipPath -Force

    $kb = [math]::Round((Get-Item $zipPath).Length / 1KB)
    Write-Host ("  {0,-30} Interface {1,-7} {2,5} KB, {3} file(s) left out" -f $zipName, $Target.Interface, $kb, $removed.Count) -ForegroundColor White
    foreach ($r in $removed) { Write-Host "      - $r" -ForegroundColor DarkGray }
}

Write-Host ""
Write-Host "Building Epithet v$version..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Zips:" -ForegroundColor Green
foreach ($target in $Targets) {
    Build-Variant -Target $target
}

Write-Host ""
Write-Host "Ready to upload to CurseForge:" -ForegroundColor Green
foreach ($target in $Targets) {
    $zip = "dist/Epithet-$version-$($target.Name).zip"
    Write-Host ("  {0,-34} -> {1}" -f $zip, $target.Label) -ForegroundColor White
}
