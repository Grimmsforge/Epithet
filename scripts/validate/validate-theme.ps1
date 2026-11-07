<#
.SYNOPSIS
    Keeps every colour in Core/Theme.lua, so per-flavour theme overrides reach it.

.DESCRIPTION
    Core/Theme.lua defines every colour as a named token (Theme.col / Theme.quality),
    and Flavors/<Flavour>/Theme.lua overrides tokens per game flavour. An override
    can only reach a colour that goes through a token, so this script fails on:

      1. Raw colour numbers in a Set*Color(...) call or an { r = ... } table
         outside Core/Theme.lua. Allowed: fully transparent calls (alpha 0) and
         untinted SetVertexColor(1, 1, 1[, 1]), which are "no colour", not a style.
      2. Literal |cffRRGGBB rich-text colours outside Core/Theme.lua (use T.Wrap).
      3. <Color>/<BarColor> tags in XML (paint XML frames from Lua with
         Theme.ApplySkin).
      4. References to tokens that Core/Theme.lua does not define: T.col.<name>,
         col.<name> in files that alias T.col, skin specs { "Path", "kind",
         "<name>", a }, { "<name>", a } look entries, and the keys of every
         Flavors/*/Theme.lua override table.

    Tokens defined but never referenced are reported as warnings.
    Exit code is non-zero on any error, so this can gate CI.

.EXAMPLE
    powershell -File scripts\validate\validate-theme.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
if (-not $RepoRoot) { $RepoRoot = Join-Path $PSScriptRoot '..\..' }
$RepoRoot = (Resolve-Path $RepoRoot).Path

$themePath = Join-Path $RepoRoot 'Core\Theme.lua'
$sourceDirs = @('Core', 'UI', 'Spotting', 'WhatsNew', 'Flavors')
$skipFiles = @('Core\Theme.lua', 'Core\AdminCommands.local.lua')

function Get-RelPath([string]$full) { $full.Substring($RepoRoot.Length + 1) }

# ---- defined tokens -------------------------------------------------------
$defined = [System.Collections.Generic.HashSet[string]]::new()
$refSources = @{}   # role -> the token it follows (Ref)
$inCol = $false
$n = 0
foreach ($line in Get-Content -LiteralPath $themePath) {
    $n++
    if ($line -match '^Theme\.col\s*=\s*\{') { $inCol = $true; continue }
    if ($inCol -and $line -match '^\}') { $inCol = $false; continue }
    if ($inCol -and $line -match '^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*(C|RGB|Ref)\(') {
        [void]$defined.Add($Matches[1])
        if ($Matches[2] -eq 'Ref' -and $line -match 'Ref\(\s*"([A-Za-z][A-Za-z0-9_]*)"') {
            $refSources[($line -replace '^\s*([A-Za-z][A-Za-z0-9_]*).*', '$1')] = @{ source = $Matches[1]; line = $n }
        }
    }
}
Write-Host "Theme tokens defined: $($defined.Count) ($($refSources.Count) follow another token)" -ForegroundColor Cyan

$errors = 0
$used = [System.Collections.Generic.HashSet[string]]::new()
function Report-Error([string]$msg) {
    Write-Host "  ERROR: $msg" -ForegroundColor Red
    $script:errors++
}
function Use-Token([string]$name, [string]$where) {
    [void]$script:used.Add($name)
    if (-not $script:defined.Contains($name)) { Report-Error "${where}: unknown colour token '$name'" }
}

# A Ref must follow a defined token that is not itself a Ref (Theme.lua also
# checks this at load; catching it here keeps a typo out of a release).
foreach ($role in $refSources.Keys) {
    $src = $refSources[$role].source
    $where = "Core\Theme.lua:$($refSources[$role].line)"
    Use-Token $src $where
    if ($refSources.ContainsKey($src)) { Report-Error "${where}: col.$role follows col.$src, which is itself a Ref" }
}

# Parts of a button look: bg = { "token" [, alpha] } (Theme.SkinButton).
$lookPartRe = [regex]'\b(?:bg|border|text|icon)\s*=\s*\{\s*"([A-Za-z][A-Za-z0-9_]*)"\s*(?:,\s*[0-9.]+\s*)?\}'

# Theme.lua may hold raw values, but its own token uses still count.
$themeRaw = Get-Content -LiteralPath $themePath -Raw
foreach ($m in [regex]::Matches($themeRaw, '\bTheme\.col\.([A-Za-z][A-Za-z0-9_]*)')) { [void]$used.Add($m.Groups[1].Value) }
foreach ($m in $lookPartRe.Matches($themeRaw)) { Use-Token $m.Groups[1].Value 'Core\Theme.lua' }

$num = '-?[0-9]*\.?[0-9]+'
$callRe = [regex]"\b(SetTextColor|SetColorTexture|SetVertexColor|SetBackdropColor|SetBackdropBorderColor|SetShadowColor|SetStatusBarColor|SetGradient)\(\s*($num)\s*,\s*($num)\s*,\s*($num)\s*(?:,\s*($num)\s*)?\)"
$tableRe = [regex]"\br\s*=\s*$num\s*,\s*g\s*=\s*$num\s*,\s*b\s*=\s*$num"
$hexRe = [regex]'\|c[fF]{2}[0-9a-fA-F]{6}'
$refRe = [regex]'\b(?:T|Theme)\.col\.([A-Za-z][A-Za-z0-9_]*)'
$aliasRefRe = [regex]'(?<![\.\w])col\.([A-Za-z][A-Za-z0-9_]*)'
$skinRe = [regex]'\{\s*"[^"]*"\s*,\s*"(?:fill|text|tint|bar|shadow|backdrop|border)"\s*,\s*"([A-Za-z][A-Za-z0-9_]*)"'
$lookRe = [regex]'=\s*\{\s*"([A-Za-z][A-Za-z0-9_]*)"\s*,\s*[0-9.]+\s*\}'

# ---- textures (Theme.tex) ---------------------------------------------------
$texDefined = [System.Collections.Generic.HashSet[string]]::new()
$texUsed = [System.Collections.Generic.HashSet[string]]::new()
$inTex = $false
foreach ($line in Get-Content -LiteralPath $themePath) {
    if ($line -match '^Theme\.tex\s*=\s*\{') { $inTex = $true; continue }
    if ($inTex -and $line -match '^\}') { $inTex = $false; continue }
    if ($inTex -and $line -match '^\s*([A-Za-z][A-Za-z0-9_]*)\s*=') { [void]$texDefined.Add($Matches[1]) }
}
# The rarity gems are read by tier ("rarity" .. q) to build Theme.RarityGems32/64.
foreach ($t in $texDefined) { if ($t -match '^rarity\d(Large)?$') { [void]$texUsed.Add($t) } }
Write-Host "Theme textures defined: $($texDefined.Count)" -ForegroundColor Cyan
function Use-Texture([string]$name, [string]$where) {
    [void]$script:texUsed.Add($name)
    if (-not $script:texDefined.Contains($name)) { Report-Error "${where}: unknown texture 'tex.$name'" }
}
$texRefRe = [regex]'\b(?:T|Theme)\.tex\.([A-Za-z][A-Za-z0-9_]*)'
$texInlineRe = [regex]'\bInlineTex\(\s*"([A-Za-z][A-Za-z0-9_]*)"'
# { "Frame.Path", "texName" } entries (MainFrame.lua MAIN_FRAME_TEXTURES); frame
# paths start upper-case, which keeps lower-case string pairs (race aliases) out.
# Texture names are lowerCamel ("logoSeal"), which keeps pairs such as
# { "Orc", "MAGE" } (race and class tokens) from reading as texture specs.
$texSpecRe = [regex]'\{\s*"[A-Z][A-Za-z0-9_.]*"\s*,\s*"([a-z][A-Za-z0-9_]*)"\s*\}'
$ownAssetRe = [regex]'(?i)Interface\\{1,2}AddOns\\{1,2}Epithet\\{1,2}(icons|logo)\\'

Write-Host ""
Write-Host "== Lua sources ==" -ForegroundColor White
$files = foreach ($d in $sourceDirs) {
    $p = Join-Path $RepoRoot $d
    if (Test-Path $p) { Get-ChildItem -LiteralPath $p -Recurse -Filter '*.lua' -File }
}
foreach ($file in $files) {
    $rel = Get-RelPath $file.FullName
    if ($skipFiles -contains $rel) { continue }
    $lines = Get-Content -LiteralPath $file.FullName
    $aliasesCol = ($lines -match '^\s*local\s+col\s*=\s*T\.col\b').Count -gt 0
    # A flavour's tex = { ... } section names texture paths by design; those
    # are checked under "Flavour overrides" below (the file must exist).
    $isFlavourTheme = $rel -match '^Flavors\\[^\\]+\\Theme\.lua$'
    $inFlavourTex = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*--') { continue }
        if ($isFlavourTheme) {
            if ($line -match '^\s*tex\s*=\s*\{') { $inFlavourTex = $true }
            elseif ($inFlavourTex -and $line -match '^\s*\}') { $inFlavourTex = $false }
        }
        $where = "${rel}:$($i + 1)"
        foreach ($m in $callRe.Matches($line)) {
            $r, $g, $b = [double]$m.Groups[2].Value, [double]$m.Groups[3].Value, [double]$m.Groups[4].Value
            $a = if ($m.Groups[5].Success) { [double]$m.Groups[5].Value } else { $null }
            if ($a -eq 0) { continue }
            if ($m.Groups[1].Value -eq 'SetVertexColor' -and $r -eq 1 -and $g -eq 1 -and $b -eq 1 -and ($null -eq $a -or $a -eq 1)) { continue }
            Report-Error "${where}: raw colour $($m.Value) - use a Theme token"
        }
        if ($tableRe.IsMatch($line)) { Report-Error "${where}: raw { r = ... } colour table - use a Theme token" }
        if ($hexRe.IsMatch($line)) { Report-Error "${where}: literal |cff colour - use T.Wrap(T.col.<token>, ...)" }
        foreach ($m in $refRe.Matches($line)) { Use-Token $m.Groups[1].Value $where }
        if ($aliasesCol) { foreach ($m in $aliasRefRe.Matches($line)) { Use-Token $m.Groups[1].Value $where } }
        foreach ($m in $skinRe.Matches($line)) { Use-Token $m.Groups[1].Value $where }
        foreach ($m in $lookRe.Matches($line)) { Use-Token $m.Groups[1].Value $where }
        foreach ($m in $lookPartRe.Matches($line)) { Use-Token $m.Groups[1].Value $where }
        if ($ownAssetRe.IsMatch($line) -and -not $inFlavourTex) { Report-Error "${where}: Epithet texture path - add it to Theme.tex and use T.tex.<name>" }
        foreach ($m in $texRefRe.Matches($line)) { Use-Texture $m.Groups[1].Value $where }
        foreach ($m in $texInlineRe.Matches($line)) { Use-Texture $m.Groups[1].Value $where }
        foreach ($m in $texSpecRe.Matches($line)) { Use-Texture $m.Groups[1].Value $where }
    }
}

Write-Host ""
Write-Host "== XML ==" -ForegroundColor White
foreach ($xml in Get-ChildItem -LiteralPath $RepoRoot -Recurse -Filter '*.xml' -File | Where-Object { $_.FullName -notmatch '\\(libs|dist|node_modules)\\' }) {
    $rel = Get-RelPath $xml.FullName
    $n = 0
    foreach ($line in Get-Content -LiteralPath $xml.FullName) {
        $n++
        if ($line -match '<(Color|BarColor)\b') { Report-Error "${rel}:${n}: <$($Matches[1])> tag - paint it from Lua with Theme.ApplySkin" }
        foreach ($m in $callRe.Matches($line)) { Report-Error "${rel}:${n}: raw colour in an XML script - move it to Lua" }
        if ($ownAssetRe.IsMatch($line)) { Report-Error "${rel}:${n}: Epithet texture in XML - set it from Lua with T.tex.<name>" }
    }
}

Write-Host ""
Write-Host "== Flavour overrides ==" -ForegroundColor White
foreach ($ov in Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'Flavors') -Recurse -Filter 'Theme.lua' -File -ErrorAction SilentlyContinue) {
    $rel = Get-RelPath $ov.FullName
    $section = $null
    $n = 0
    $count = 0
    $texCount = 0
    foreach ($line in Get-Content -LiteralPath $ov.FullName) {
        $n++
        if ($line -match '^\s*--') { continue }
        if ($line -match '^\s*(col|quality|tex)\s*=\s*\{') { $section = $Matches[1]; continue }
        # A section's closing brace (at most 4 spaces in) or the end of the
        # Apply call ends it; entries are indented further.
        if ($section -and $line -match '^\s{0,4}\}') { $section = $null; continue }
        if ($section -eq 'col' -and $line -match '^\s*([A-Za-z][A-Za-z0-9_]*)\s*=') {
            Use-Token $Matches[1] "${rel}:${n}"
            $count++
        }
        if ($section -eq 'tex' -and $line -match '^\s*([A-Za-z][A-Za-z0-9_]*)\s*=') {
            $texName = $Matches[1]
            Use-Texture $texName "${rel}:${n}"
            $texCount++
            # An Epithet path must name a file the package ships (.tga or .blp).
            $own = [regex]::Match($line, '(?i)"Interface\\{1,2}AddOns\\{1,2}Epithet\\{1,2}([^"]+)"')
            if ($own.Success) {
                $relAsset = $own.Groups[1].Value -replace '\\\\', '\'
                $onDisk = @('.tga', '.blp') | Where-Object { Test-Path -LiteralPath (Join-Path $RepoRoot ($relAsset + $_)) }
                if (-not $onDisk) { Report-Error "${rel}:${n}: tex.$texName names $relAsset(.tga/.blp), which is not in the repo" }
            }
        }
    }
    Write-Host "  $rel : $count colour override(s), $texCount texture override(s)" -ForegroundColor Green
}

$unused = @($defined | Where-Object { -not $used.Contains($_) } | Sort-Object)
if ($unused.Count -gt 0) {
    Write-Host ""
    Write-Host "  WARNING: $($unused.Count) token(s) defined but not referenced: $($unused -join ', ')" -ForegroundColor Yellow
}
$texUnused = @($texDefined | Where-Object { -not $texUsed.Contains($_) } | Sort-Object)
if ($texUnused.Count -gt 0) {
    Write-Host "  WARNING: $($texUnused.Count) texture(s) defined but not referenced: $($texUnused -join ', ')" -ForegroundColor Yellow
}

Write-Host ""
if ($errors -gt 0) {
    Write-Host "FAILED: $errors error(s) found." -ForegroundColor Red
    exit 1
}
Write-Host "OK: no errors." -ForegroundColor Green
exit 0
