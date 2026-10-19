[CmdletBinding()]
param(
    [string]$OutputDir = (Join-Path $PSScriptRoot "..\..\artifacts\curseforge-recommendations"),
    [string]$HistoryPath = (Join-Path $PSScriptRoot "..\..\artifacts\curseforge-recommendations\history.json"),
    [int]$WindowDays = 7,
    [int]$MaxAddons = 20
)

$ErrorActionPreference = "Stop"

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $raw = Get-Content -LiteralPath $Path -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    return $raw | ConvertFrom-Json -Depth 20
}

function Invoke-JsonRequest {
    param(
        [string]$Uri,
        [hashtable]$Headers
    )
    try {
        return Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers -TimeoutSec 30
    }
    catch {
        Write-Warning "Request failed for $($Uri): $($_.Exception.Message)"
        return $null
    }
}

function Get-ApiAddons {
    $apiKey = $env:CURSEFORGE_API_KEY
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Warning "CURSEFORGE_API_KEY is not configured; skipping CurseForge API."
        return @()
    }
    $apiKey = $apiKey.Trim().Trim('"').Trim("'")

    $apiUrl = $env:CURSEFORGE_API_URL
    if ([string]::IsNullOrWhiteSpace($apiUrl)) {
        $apiUrl = "https://api.curseforge.com/v1/mods/search?gameId=1&classId=4471&pageSize=50&sortField=2&sortOrder=desc"
    }

    $response = Invoke-JsonRequest -Uri $apiUrl -Headers @{ "x-api-key" = $apiKey; "Accept" = "application/json" }
    if ($null -eq $response -or $null -eq $response.data) {
        Write-Warning "CurseForge API returned no add-on data. A 403 response means the secret value is not an active CurseForge API key; create one at https://console.curseforge.com/ and replace CURSEFORGE_API_KEY."
        return @()
    }

    $items = @()
    foreach ($mod in $response.data) {
        $slug = if ($mod.slug) { [string]$mod.slug } else { "" }
        $url = if ($mod.links.websiteUrl) { [string]$mod.links.websiteUrl } elseif ($slug) { "https://www.curseforge.com/wow/addons/$slug" } else { "" }
        $summary = if ($mod.summary) { [string]$mod.summary } else { "" }
        $name = if ($mod.name) { [string]$mod.name } else { "" }
        $updated = if ($mod.dateModified) { [datetime]$mod.dateModified } else { $null }
        $categories = @()
        if ($mod.categories) {
            foreach ($c in $mod.categories) {
                if ($c.name) { $categories += [string]$c.name }
            }
        }

        $items += [pscustomobject]@{
            Name       = $name
            Summary    = $summary
            Url        = $url
            Slug       = $slug
            UpdatedUtc = $updated
            Categories = $categories
            Source     = "curseforge-api"
        }
    }
    return $items
}

function Get-RssFallbackAddons {
    $feedCsv = $env:CURSEFORGE_FALLBACK_FEEDS
    if ([string]::IsNullOrWhiteSpace($feedCsv)) {
        return @()
    }

    $feeds = $feedCsv.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $items = @()

    foreach ($feed in $feeds) {
        try {
            $response = Invoke-WebRequest -Uri $feed -Headers @{ "User-Agent" = "Grimmsforge-Epithet-Weekly-Recommender"; "Accept" = "application/rss+xml,application/atom+xml,text/xml,text/html" } -TimeoutSec 30
        }
        catch {
            Write-Warning "Fallback feed failed: $($feed): $($_.Exception.Message)"
            continue
        }

        $contentType = [string]$response.Headers["Content-Type"]
        $text = [string]$response.Content
        if ([string]::IsNullOrWhiteSpace($text)) { continue }

        if ($contentType -like "*xml*" -or $text.TrimStart().StartsWith("<rss") -or $text.TrimStart().StartsWith("<feed")) {
            try {
                [xml]$xml = $text
                $nodes = @($xml.rss.channel.item) + @($xml.feed.entry)
                foreach ($n in $nodes) {
                    if ($null -eq $n) { continue }
                    $title = [string]($n.title.'#text' ?? $n.title)
                    $link = [string]($n.link.href ?? $n.link)
                    $summary = [string]($n.description.'#text' ?? $n.summary.'#text' ?? $n.summary)
                    $updatedRaw = [string]($n.pubDate ?? $n.updated)
                    $updated = $null
                    if ($updatedRaw) {
                        try { $updated = [datetime]$updatedRaw } catch { }
                    }
                    if (-not $link -or $link -notmatch "/wow/addons/") { continue }
                    $slug = ($link -replace '/+$', '') -replace '^.+/wow/addons/', ''

                    $items += [pscustomobject]@{
                        Name       = $title
                        Summary    = $summary
                        Url        = $link
                        Slug       = $slug
                        UpdatedUtc = $updated
                        Categories = @()
                        Source     = "rss-fallback"
                    }
                }
            }
            catch {
                continue
            }
            continue
        }

        $matches = [regex]::Matches($text, 'href="(/wow/addons/[^"/?#]+)"[^>]*>([^<]{2,120})<')
        foreach ($m in $matches) {
            $slugPath = [string]$m.Groups[1].Value
            $name = ([string]$m.Groups[2].Value).Trim()
            if (-not $slugPath -or -not $name) { continue }
            if ($slugPath -match "/search") { continue }
            $slug = ($slugPath -replace '^/wow/addons/', '')
            $items += [pscustomobject]@{
                Name       = $name
                Summary    = ""
                Url        = "https://www.curseforge.com$slugPath"
                Slug       = $slug
                UpdatedUtc = $null
                Categories = @()
                Source     = "html-fallback"
            }
        }
    }

    return $items
}

function Normalize-Addons {
    param([object[]]$Addons)
    $map = @{}
    foreach ($a in $Addons) {
        if ([string]::IsNullOrWhiteSpace($a.Name)) { continue }
        $slug = if ($a.Slug) { [string]$a.Slug } else { (($a.Name -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLowerInvariant()) }
        if ([string]::IsNullOrWhiteSpace($slug)) { continue }
        if (-not $map.ContainsKey($slug)) {
            $map[$slug] = $a
            continue
        }
        $existing = $map[$slug]
        if ($existing.Source -ne "curseforge-api" -and $a.Source -eq "curseforge-api") {
            $map[$slug] = $a
        }
    }
    return @($map.Values)
}

Ensure-Dir -Path $OutputDir
Ensure-Dir -Path (Split-Path -Parent $HistoryPath)

$history = Read-JsonFile -Path $HistoryPath
if ($null -eq $history) {
    $history = [pscustomobject]@{
        seenAddons      = @{}
        seenSuggestions = @{}
    }
}
if ($null -eq $history.seenAddons) { $history | Add-Member -NotePropertyName "seenAddons" -NotePropertyValue @{} -Force }
if ($null -eq $history.seenSuggestions) { $history | Add-Member -NotePropertyName "seenSuggestions" -NotePropertyValue @{} -Force }

$apiAddons = Get-ApiAddons
$fallbackAddons = @()
if ($apiAddons.Count -eq 0) {
    $fallbackAddons = Get-RssFallbackAddons
}

$allAddons = Normalize-Addons -Addons ($apiAddons + $fallbackAddons)
if ($allAddons.Count -eq 0) {
    throw "No CurseForge add-ons were retrieved. Configure the CURSEFORGE_API_KEY repository secret, or provide an accessible CURSEFORGE_FALLBACK_FEEDS repository variable."
}

$now = (Get-Date).ToUniversalTime()
$windowStart = $now.AddDays(-1 * $WindowDays)

$capabilityModel = @(
    @{ Key = "social-recognition"; Keywords = @("guild", "social", "party", "group", "community", "friends", "inspect"); UserValue = 5; Effort = 3; Fit = 5; Suggestion = "Add richer social spotting context (where/when spotted, group context, and optional social badges) in the Spotting Log." },
    @{ Key = "ui-discovery"; Keywords = @("tooltip", "search", "filter", "bookmark", "browser", "list", "panel", "ui"); UserValue = 4; Effort = 2; Fit = 5; Suggestion = "Expand discovery UX with saved filter presets, quick-find shortcuts, and adaptive list hints for unearned titles." },
    @{ Key = "collection-insights"; Keywords = @("collection", "achievement", "progress", "tracker", "completion", "meta"); UserValue = 5; Effort = 3; Fit = 5; Suggestion = "Introduce progression insights (near-complete title sets, seasonal watchlists, and collection milestone prompts)." },
    @{ Key = "data-automation"; Keywords = @("import", "export", "sync", "share", "profile", "history", "analytics"); UserValue = 4; Effort = 4; Fit = 4; Suggestion = "Improve data workflows with robust profile export/import presets and optional analytics snapshots for title progression trends." },
    @{ Key = "contextual-overlays"; Keywords = @("nameplate", "overlay", "portrait", "target", "combat", "heads-up"); UserValue = 4; Effort = 3; Fit = 5; Suggestion = "Add contextual overlay modes that adapt layout to encounter state (solo, group, combat) with cleaner information density controls." }
)

$categoryAllow = @("social", "ui", "tooltip", "achievement", "collection", "information", "quality of life", "roleplay", "nameplate", "interface")
$filtered = @()
foreach ($addon in $allAddons) {
    $text = ("{0} {1} {2}" -f $addon.Name, $addon.Summary, (($addon.Categories -join " "))).ToLowerInvariant()
    $catText = (($addon.Categories -join " ")).ToLowerInvariant()
    $relevantByCategory = $false
    foreach ($needle in $categoryAllow) {
        if ($catText.Contains($needle) -or $text.Contains($needle)) { $relevantByCategory = $true; break }
    }
    if (-not $relevantByCategory -and $addon.Source -eq "curseforge-api") {
        continue
    }
    $filtered += $addon
}

$scoredAddons = foreach ($addon in $filtered) {
    $text = ("{0} {1}" -f $addon.Name, $addon.Summary).ToLowerInvariant()
    $capHits = @()
    foreach ($cap in $capabilityModel) {
        foreach ($kw in $cap.Keywords) {
            if ($text.Contains($kw)) { $capHits += $cap.Key; break }
        }
    }
    [pscustomobject]@{
        Name        = $addon.Name
        Url         = $addon.Url
        Slug        = $addon.Slug
        Summary     = $addon.Summary
        UpdatedUtc  = $addon.UpdatedUtc
        Source      = $addon.Source
        Capabilities= ($capHits | Select-Object -Unique)
    }
}

$newAddons = @()
foreach ($addon in $scoredAddons) {
    $seenRaw = $history.seenAddons.$($addon.Slug)
    $seenDate = $null
    if ($seenRaw) { try { $seenDate = [datetime]$seenRaw } catch { } }
    $updatedRecently = $null -eq $addon.UpdatedUtc -or $addon.UpdatedUtc -ge $windowStart
    if ($updatedRecently -and ($null -eq $seenDate -or $seenDate -lt $windowStart)) {
        $newAddons += $addon
    }
}

$topAddons = @($newAddons | Select-Object -First $MaxAddons)

$suggestions = @()
foreach ($cap in $capabilityModel) {
    $evidence = @($topAddons | Where-Object { $_.Capabilities -contains $cap.Key })
    if ($evidence.Count -eq 0) { continue }
    $confidence = [Math]::Min(95, 45 + ($evidence.Count * 10) + ((@($evidence | Where-Object { $_.Source -eq "curseforge-api" }).Count) * 5))
    $score = [Math]::Round((((($cap.UserValue * 0.45) + ($cap.Fit * 0.35) + ((6 - $cap.Effort) * 0.20)) / 5.0) * 100), 1)
    $priority = if ($score -ge 80) { "High" } elseif ($score -ge 65) { "Medium" } else { "Low" }
    $lastSeenRaw = $history.seenSuggestions.$($cap.Key)
    $lastSeen = $null
    if ($lastSeenRaw) { try { $lastSeen = [datetime]$lastSeenRaw } catch { } }
    if ($lastSeen -and $lastSeen -gt $windowStart) {
        continue
    }

    $suggestions += [pscustomobject]@{
        Key        = $cap.Key
        Suggestion = $cap.Suggestion
        Evidence   = @($evidence | Select-Object -First 5)
        Score      = $score
        Priority   = $priority
        Confidence = [Math]::Min($confidence, 99)
    }
}

foreach ($addon in $scoredAddons) {
    $history.seenAddons | Add-Member -NotePropertyName $addon.Slug -NotePropertyValue ($now.ToString("o")) -Force
}
foreach ($s in $suggestions) {
    $history.seenSuggestions | Add-Member -NotePropertyName $s.Key -NotePropertyValue ($now.ToString("o")) -Force
}

$history | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $HistoryPath -Encoding UTF8

$reportPath = Join-Path $OutputDir "report.md"
$issueBodyPath = Join-Path $OutputDir "issue-body.md"
$dataPath = Join-Path $OutputDir "report.json"

$sourceUsed = if ($apiAddons.Count -gt 0) { "CurseForge API" } elseif ($fallbackAddons.Count -gt 0) { "Curated fallback feeds/scrape" } else { "No data source reachable" }
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Weekly CurseForge Recommendations")
$lines.Add("")
$lines.Add("- Generated: $($now.ToString("u"))")
$lines.Add("- Source used: $sourceUsed")
$lines.Add("- Recommendation window: last $WindowDays days")
$lines.Add("- New candidate add-ons scanned: $($topAddons.Count)")
$lines.Add("")
$lines.Add("## Top Add-ons")
$lines.Add("")
$lines.Add("| Add-on | Source | Capability signals |")
$lines.Add("|---|---|---|")
foreach ($a in $topAddons) {
    $name = $a.Name.Replace("|", "\|")
    $url = if ($a.Url) { $a.Url } else { "https://www.curseforge.com/wow/addons/$($a.Slug)" }
    $caps = if ($a.Capabilities.Count -gt 0) { ($a.Capabilities -join ", ") } else { "none-detected" }
    $lines.Add("| [$name]($url) | $($a.Source) | $caps |")
}
if ($topAddons.Count -eq 0) {
    $lines.Add("| _No add-ons captured this run_ | n/a | n/a |")
}
$lines.Add("")
$lines.Add("## Suggested Epithet Features")
$lines.Add("")
$lines.Add("| Priority | Score | Confidence | Suggestion | Evidence |")
$lines.Add("|---|---:|---:|---|---|")
foreach ($s in ($suggestions | Sort-Object -Property Score -Descending)) {
    $evidenceText = ($s.Evidence | ForEach-Object { "[{0}]({1})" -f $_.Name.Replace("|", "\|"), ($_.Url ? $_.Url : "https://www.curseforge.com/wow/addons/$($_.Slug)") }) -join "<br/>"
    $lines.Add("| $($s.Priority) | $($s.Score) | $($s.Confidence)% | $($s.Suggestion.Replace("|", "\|")) | $evidenceText |")
}
if ($suggestions.Count -eq 0) {
    $lines.Add("| _No new suggestions after dedupe guardrails_ | 0 | 0% | Existing recommendation set still current. | n/a |")
}
$lines.Add("")
$lines.Add("## Guardrails")
$lines.Add("")
$lines.Add("- Duplicate add-ons are collapsed by slug.")
$lines.Add("- Suggestions emitted in the last recommendation window are suppressed.")
$lines.Add("- Every suggestion includes evidence links to the observed add-ons.")

$report = $lines -join "`n"
Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

$issueLines = [System.Collections.Generic.List[string]]::new()
$issueLines.Add("<!-- epithet-weekly-curseforge-recommendations -->")
$issueLines.Add("")
$issueLines.Add($report)
Set-Content -LiteralPath $issueBodyPath -Value ($issueLines -join "`n") -Encoding UTF8

$json = [pscustomobject]@{
    generatedAt = $now.ToString("o")
    sourceUsed = $sourceUsed
    topAddons = $topAddons
    suggestions = $suggestions
}
$json | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $dataPath -Encoding UTF8

Write-Host "Wrote:"
Write-Host " - $reportPath"
Write-Host " - $issueBodyPath"
Write-Host " - $dataPath"
