# CurseForge Weekly Recommender

This automation runs weekly and scans recent WoW add-ons on CurseForge, then suggests Epithet feature ideas based on observed capabilities.

## Source strategy

1. **Primary**: CurseForge API (`CURSEFORGE_API_KEY`, when available).
2. **Optional fallback**: An explicitly configured feed/list source from `CURSEFORGE_FALLBACK_FEEDS`.
3. **Built-in fallback**: GitHub's repository search API, authenticated with the workflow's built-in `GITHUB_TOKEN`, for recently updated repositories tagged `world-of-warcraft-addon`.

The workflow prefers CurseForge API data, then the configured feed, then GitHub add-on repositories. It does not use a built-in CurseForge page scraper because those pages are commonly blocked in hosted runners. GitHub fallback results are repository-based signals rather than a complete CurseForge catalog and link to the source repository as evidence.

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

Set these in repository settings before the scheduled workflow runs:

- **Secret (optional)**: `CURSEFORGE_API_KEY`
- **Variable (optional)**: `CURSEFORGE_API_URL`
- **Variable (optional)**: `CURSEFORGE_FALLBACK_FEEDS` (comma-separated URLs)

No secret is required for the built-in GitHub fallback; the workflow passes its read-only `GITHUB_TOKEN` automatically. If `CURSEFORGE_API_URL` is not set, the script uses its default WoW add-on search endpoint. The workflow fails only when all three sources return no data.

A `403 Forbidden` response means the secret value is not an active CurseForge API key. Create a key in the [CurseForge developer console](https://console.curseforge.com/), then replace the `CURSEFORGE_API_KEY` repository secret. Use the raw API key, not a client ID, GitHub token, or quoted value. The repository secret is never stored in the repository or printed in logs.

## Tuning guidance

Update `scripts/automation/curseforge-weekly-recommendations.ps1` to tune:

- Capability keyword sets
- Suggestion text per capability
- Priority thresholds
- Window length (`-WindowDays`)
- Number of tracked add-ons (`-MaxAddons`)
