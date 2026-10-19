# CurseForge Weekly Recommender

This automation runs weekly and scans recent WoW add-ons on CurseForge, then suggests Epithet feature ideas based on observed capabilities.

## Source strategy

1. **Primary**: CurseForge API (`CURSEFORGE_API_KEY` required).
2. **Fallback**: Curated feed/list scraping from `CURSEFORGE_FALLBACK_FEEDS`.

The workflow will prefer API data whenever available, then fall back automatically if API access is unavailable.

## Schedule and trigger

- Workflow: `.github/workflows/weekly-curseforge-recommendations.yml`
- Schedule: every Monday at 09:00 UTC
- Manual trigger: **Run workflow** (`workflow_dispatch`)

## Outputs

Each run writes:

- `artifacts/curseforge-recommendations/report.md`
- `artifacts/curseforge-recommendations/report.json`
- `artifacts/curseforge-recommendations/issue-body.md`

The workflow uploads these as a build artifact and upserts a single rolling issue:

- **Weekly CurseForge feature recommendations**

## Guardrails

- Add-ons are deduplicated by slug.
- Suggestions seen in the current recommendation window are suppressed.
- Suggestions require evidence links to observed add-ons.
- History is persisted across runs using workflow cache:
  - `.cache/curseforge-recommender/history.json`

## Scoring model

Suggestions are capability-bucketed, then scored by:

- **User value** (impact to players)
- **Implementation effort** (lower effort scores higher)
- **Epithet fit** (alignment with collection/spotting identity)

Scores are converted to:

- High priority
- Medium priority
- Low priority

Confidence increases with amount and quality of evidence (API-backed evidence scores higher than fallback scrape evidence).

## Configuration

Set these in repository settings:

- **Secret**: `CURSEFORGE_API_KEY`
- **Variable (optional)**: `CURSEFORGE_API_URL`
- **Variable (optional)**: `CURSEFORGE_FALLBACK_FEEDS` (comma-separated URLs)

If `CURSEFORGE_API_URL` is not set, the script uses its default WoW add-on search endpoint.

## Tuning guidance

Update `scripts/automation/curseforge-weekly-recommendations.ps1` to tune:

- Capability keyword sets
- Suggestion text per capability
- Priority thresholds
- Window length (`-WindowDays`)
- Number of tracked add-ons (`-MaxAddons`)
