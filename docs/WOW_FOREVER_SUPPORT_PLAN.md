# WoW Forever support plan

**Status:** Forever data received from TitlesDBCollector and wired in (multi-flavour TOC, per-flavour `data/`, Forever-safe title handling, per-target builds). In-client probe and the Forever smoke test still to do.  
**Last updated:** 2026-11-07

## Goal

Extend Epithet to WoW Forever without regressing its existing Retail release and PTR builds. Every target is built from **one codebase**: shared behaviour, UI and localization stay shared, and the differences are confined to three places:

1. **TOC load conditions.** The client's own `[AllowLoadGameType ...]` directives decide which files each flavour loads.
2. **A single compatibility module** for APIs that actually differ.
3. **Flavour-specific data and content**, loaded only by that flavour.

No client should load another flavour's code or data, and no feature code should branch on the game version.

## Target matrix

| Target | Product / folder | Version | TOC interface | Game type | Status |
| --- | --- | --- | ---: | --- | --- |
| WoW Retail (live) | `wow` / `_retail_` | 12.1.5.70783 | `120105` | `standard` | Supported |
| WoW Retail (PTR/Beta) | `_xptr_` / `_beta_` | — | `120107` | `standard` | Supported test build |
| WoW Forever | `wowf` / `_forever_` | 1.60.1.70790 | `16001` | `camelot` | Planned |

Epithet currently targets Retail only. The "classic" in `Core/SocialLayouts/classic.lua` is a UI layout name, not a Classic WoW client. The root [TOC](../Epithet.toc) declares the live interface version. The [build script](../scripts/build/build.ps1) creates separate live and PTR archives by patching that value.

## Client findings (verified 2026-11-06)

These come from the local install at `A:\Blizzard\World of Warcraft\_forever_`: its `.flavor.info`, the shared `.build.info`, the client logs, and the TOCs and source of the Forever addons installed there (EllesmereUI suite, Auctionator, Syndicator, DialogueUI, WaypointUI, RareScanner and others).

### Identity

- **Product and build:** `wowf`, version `1.60.1.70790`. The interface number is `16001` (1×10000 + 60×100 + 1), which matches the `## Interface` line of every Forever addon installed.
- **Game type:** `camelot`. Retail's is `standard`.
- **Project constant:** `WOW_PROJECT_CAMELOT`. DialogueUI's source notes that "Camelot" / `WOW_PROJECT_CAMELOT` will be renamed to "Forever", so **Epithet must not depend on either name**.
- **What it is:** EllesmereUI's client gate describes it as "the 12.1 engine with vanilla content". The modern API surface applies, including secret values: DialogueUI groups Retail and Forever as "modern … have Secrets". The game content, though, is vanilla-era.
- **Ruled out:** the 3.3.5a "Forever/Camelot" community project ([mod-forever-ui](https://github.com/Adrestie/mod-forever-ui)) is a different client and not a target.

### TOC features the client supports

All of these are used by addons installed in `_forever_`, and the multi-flavour ones also load on Retail:

| Feature | Example in the install |
| --- | --- |
| Multi-value interface line | EllesmereUI: `## Interface: 120000, 120001, 120005, 120007, 120100, 120105, 16001` |
| Flavour-suffixed TOC file | WaypointUI ships `WaypointUI.toc` (`120105, 120107`) alongside `WaypointUI_Camelot.toc` (`16001`) |
| Addon-level load gate | `## AllowLoadGameType: camelot` (EllesmereUIForeverEssentials), `## AllowLoadGameType: standard` (EllesmereUIFriends) |
| Per-file load gate | Auctionator: `Source_Forever\Constants.lua [AllowLoadGameType camelot][ExcludeLoadGameType classic, standard]`; EllesmereUI: `Libs\LibKeystone\LibKeystone.lua [AllowLoadGameType standard]` |
| Per-flavour metadata | DialogueUI: `## X-GameType: Camelot [AllowLoadGameType camelot]` and `## X-GameType: Standard [AllowLoadGameType standard]`, read with `C_AddOns.GetAddOnMetadata` |
| Per-locale file gate | EllesmereUILocales: `deDE.lua [AllowLoadTextLocale deDE, enUS, enGB]` |

Use the game types `standard` and `camelot` explicitly. Do not rely on the `mainline` family keyword: it is not clear whether `mainline` includes `camelot`, which is why Auctionator adds `[ExcludeLoadGameType ...]` to its Forever-only file.

### Content and data

- The client has `CharTitles` and `Achievement` DB2 tables: hotfix records for both appear in `Logs/Hotfix.log`.
- Because the content is vanilla-era, Forever's titles will be mostly the vanilla subset. Epithet's TitlesDB has 62 titles tagged `exp = "classic"`:
  - **27 PvP rank titles.** Retail marks these as legacy and unobtainable; in Forever they are presumably obtainable again, with different rarity.
  - **34 achievement-linked titles**, mostly Retail-era achievements tagged as classic (for example Azeroth's Champion). These are likely absent from Forever.
  - **1 holiday title.**
- **Conclusion:** Forever needs its own data with its own obtainability and rarity. It cannot be just a filter over the Retail data. It should, however, be small.

### Distribution

- `_forever_/.curseclient` is present, so the CurseForge app manages this install.
- CurseForge-published addons (EllesmereUI has `## X-Curse-Project-ID: 1477613`) declare `16001` and are installed here.
- So CurseForge distribution to Forever is very likely. The upload-side game-version label still needs checking.

### Still open

| Question | Why it matters | How to answer |
| --- | --- | --- |
| Is the achievement system present and working, and what do `GetAchievementInfo` / `ACHIEVEMENT_EARNED` return? | Achievement tracking, the completion dates in TitleData, and the Logbook achievements all depend on it. RareScanner calls `GetAchievementInfo` in this install, but that alone doesn't prove the function behaves the same. | Probe addon (step 1). |
| What is the exact Forever title list (IDs, names, prefix/suffix)? | It is the input for the Forever TitlesDB. | Probe dump of `GetNumTitles()` / `GetTitleName(i)`. |
| Which name API carries which part of a Forever first + last name (`UnitName`, `UnitFullName`, `UnitPVPName`, `GetUnitName`, the target frame)? | Clicking a titleless Forever player showed a title plate: the surname was read as a suffix title. Fixed without depending on the answer (2026-11-07): `TitleIndex:ReadTitle` only accepts a title this client's catalogue has, in that position, and otherwise looks for a catalogue title at either end of the displayed name. **Answered by the probe (2026-11-07):** `UnitName` / `UnitFullName` / `UnitNameUnmodified` return first name and **surname** (`"Manny"`, `"Hunters"`), where Retail returns name and realm. `UnitPVPName` and `GetUnitName(unit, true)` give `"Manny Hunters"`. `GetPlayerInfoByGUID` gives `"Manny Hunters"` with an empty realm. Code must never read that second value as a realm on Forever. | Done. A titled player is still worth one `/eprobe names` to confirm the title placement. |
| Does any realm API give a Forever realm name players know? | The header showed `GetNormalizedRealmName()`, which on Forever is the internal ID `CAMWOWEU4Realm1PvE`. The line is blank on Forever for now (`ns.Flavor.showRealm`, `Flavors/Forever/Flavor.lua`, 2026-11-07). The header name is now the first + last name, read off `UnitPVPName("player")` with the title removed (`TitleData` `ReadPlayerName`). **Answered by the probe:** `GetRealmName()` is `"CAMWOW EU4 Realm 1 PvE"`, which is still internal. Only the ruleset part ("PvE") means anything to players, so the line stays blank. | Done. Showing just the ruleset is an option. |
| Which Blizzard textures Epithet names are missing from the Forever client (mostly the Logbook's achievement badge icons)? | A missing file shows as a blank or green square. Answer with a Forever-only content table if any are missing, not with theme overrides. | `/eprobe textures` on Retail (the control) and on Forever. |
| Does Retail honour `## X-Epithet-Flavor: ... [AllowLoadGameType ...]` conditional metadata? | `ns.FLAVOR` depends on it. DialogueUI uses this pattern on Retail too, so it most likely does. | Load the Retail build and print the metadata value. |
| Which text locales does Forever support? | Decides whether the locale overlays apply. This install has only `enUS` text, which may just be the local setup. | Check the client's locale options. |
| Can one CurseForge file be tagged for both Retail and WoW Forever? | Decides between a single package and separate packages (see [Packaging](#packaging)). | Check the CurseForge upload form. |

## API snapshot (community docs, build 70170)

A public addon-development environment documents the client's own exported `/api` ([reference site](https://atraeau.github.io/WoW-Addons/), [repo](https://github.com/Atraeau/WoW-Addons)). It also describes an export workflow: `/apiexport`, then `/reload`. A separate [Forever API index](https://github.com/RdyGaming/hated-wow-mcp/blob/b0893aac3bd42d82ee85733677fec974fb696f71/data/api-forever.json) is also available.

The snapshot is from build 70170, while the installed client is 70790, so treat these as hints and confirm them with the probe.

| Epithet dependency | Evidence | Implication |
| --- | --- | --- |
| Title catalog, ownership, equipping | The [Title API](https://github.com/Atraeau/WoW-Addons/blob/b64aab0ab698e0c907deafc1d5e8b23ba6741b0a/docs/api/Achievements-Progression/Title.md) documents `GetCurrentTitle`, `GetNumTitles`, `GetTitleName -> (string, bool)`, `IsTitleKnown` and `SetCurrentTitle`. EllesmereUI's character sheet calls `GetNumTitles` / `GetTitleName` on Forever. | Signatures look compatible. |
| Unit identity | The [Unit API](https://github.com/Atraeau/WoW-Addons/blob/b64aab0ab698e0c907deafc1d5e8b23ba6741b0a/docs/api/Units-Combat-PvP/Unit.md) documents every unit call Epithet uses. | Present. Test realm naming and the `UNIT_NAME_UPDATE` timing. |
| Achievements | [C_AchievementInfo](https://github.com/Atraeau/WoW-Addons/blob/b64aab0ab698e0c907deafc1d5e8b23ba6741b0a/docs/api/Achievements-Progression/C_AchievementInfo.md) lists 6 functions and 11 events, including `ACHIEVEMENT_EARNED(achievementID, alreadyEarned?)`, but not `GetAchievementInfo`. The global name does appear in the generated [globals list](https://github.com/Atraeau/WoW-Addons/blob/b64aab0ab698e0c907deafc1d5e8b23ba6741b0a/types/luacheck-globals.lua). | Highest-risk area. Route all access through `ns.Compat` (see below). |
| Timers | [C_Timer](https://github.com/Atraeau/WoW-Addons/blob/b64aab0ab698e0c907deafc1d5e8b23ba6741b0a/docs/api/AddOns-Scripting/C_Timer.md) documents `After` and `NewTimer`. | `NewTicker` is not listed there; probe it. |
| Addon metadata | [C_AddOns](https://github.com/Atraeau/WoW-Addons/blob/b64aab0ab698e0c907deafc1d5e8b23ba6741b0a/docs/api/AddOns-Scripting/C_AddOns.md) documents `GetAddOnMetadata`. DialogueUI uses it on Forever for conditional metadata. | Confirmed in practice. Probe `LoadAddOn`. |

## Architecture

### Principles

- **The source tree is a working addon on every client.** The same `Epithet.toc` loads correctly on Retail live, PTR and Forever, gated by the client's own load directives. You can junction the repo into either `_retail_` or `_forever_` with no build step.
- **Check for capabilities, not versions.** The code already does this, and it must stay that way: `if BlizzardSettings and BlizzardSettings.RegisterCanvasLayoutSubcategory` ([Settings.lua](../Core/Settings.lua)), `if issecretvalue and issecretvalue(...)` ([SocialLayouts.lua](../Core/SocialLayouts.lua)), the `pcall` fallbacks around `SetPortraitTexture`, and the layered achievement-frame opener in [Detail.lua](../UI/Detail.lua). Do not introduce `WOW_PROJECT_ID`, `WOW_PROJECT_CAMELOT` or `GetBuildInfo()` interface-range checks.
- **The flavour constant selects data and content only.** If an API differs, handle it in `Compat.lua` with a capability check. Never write `if ns.FLAVOR == "forever"` around an API call.
- **Wrap only what the probe proves differs.** Existing inline `if X and X.Y` guards can stay where they are.

### TOC

One source TOC, using native directives:

```toc
## Interface: 120105, 120107, 16001
## X-Epithet-Flavor: retail [AllowLoadGameType standard]
## X-Epithet-Flavor: forever [AllowLoadGameType camelot]
...
# Bundled Data
data\retail\TitlesDB.enGB.lua [AllowLoadGameType standard]
data\retail\TitlesDB.deDE.lua [AllowLoadGameType standard]
...
data\forever\TitlesDB.enGB.lua [AllowLoadGameType camelot]
...

# Core
Core\Compat.lua
Flavors\Forever\Compat.lua [AllowLoadGameType camelot]
Core\Theme.lua
...
```

- Add a gate only to files that genuinely belong to one flavour. Shared files stay ungated.
- **What's New (done 2026-11-07).** Entries live in `WhatsNew/Retail/` and `WhatsNew/Forever/`, each file gated in the TOC. Only the current version's entry is shown, and the saved "seen" state is per install, so the two never mix.
- If the per-file list ever grows unwieldy, the fallback is a flavour-suffixed TOC (`Epithet_Camelot.toc`, the same pattern WaypointUI uses). That means maintaining two file lists, so prefer per-file gates until they stop scaling.

### Folder layout

```text
Core/  Spotting/  UI/  Locales/  WhatsNew/  icons/  Fonts/  logo/   # shared (unchanged)
Core/Compat.lua                                                     # new: API differences, ns.FLAVOR
Flavors/Retail/                                                     # retail-only files (only if needed)
Flavors/Forever/                                                    # forever-only files
data/retail/                # retail + PTR data (gitignored, collector-generated)
data/forever/               # forever data (gitignored, collector-generated)
```

Every per-flavour area has one folder per flavour and nothing at its root, matching TitlesDBCollector's layout: `data/<flavour>/`, `Flavors/<Flavour>/`, `dist/<target>/` (retail, ptr, forever) and `scripts/link/<flavour>/`. The build and `validate-titlesdb-locales.ps1` fail on any file left at the `data/` root.

### Compatibility module: `Core/Compat.lua`

- Load it as the first non-library, non-data file. The data files only assign tables and don't need it.
- `ns.FLAVOR` is read once from `C_AddOns.GetAddOnMetadata(addonName, "X-Epithet-Flavor")`, defaulting to `"retail"`. No build patching is involved: the client picks the matching metadata line.
- `ns.Compat.*` functions resolve divergent APIs once at load time.
- **First wrapper:** `ns.Compat.GetAchievementCompletion(id) -> completed, timestamp`. It replaces the positional `GetAchievementInfo` reads in [TitleData.lua](../Core/TitleData.lua) and [Achievements.lua](../Spotting/Achievements.lua). If the probe shows the achievement system is absent on Forever, this helper returns `nil`, and the achievement features hide themselves through a capability flag such as `ns.Compat.HAS_ACHIEVEMENTS`. They must not error.
- Large Forever-only implementations go in `Flavors/Forever/Compat.lua`, gated `[AllowLoadGameType camelot]` and loaded straight after `Core/Compat.lua`. It overrides entries on `ns.Compat`.

### Data strategy

- TitlesDB keeps the same shape on every flavour: the `EpithetData.titles` base keyed by normalised text, plus sparse `ns.TitlesDBLocales.<code>` overlays keyed by `titleID`. Runtime code therefore doesn't change.
- Title **names** always come from `GetTitleName()`, so a data gap can only lose metadata; it cannot corrupt the displayed names.
- The collector gets a Forever mode that emits a complete, separate set into `data/forever/`. Its source is the Forever title list from the probe, with obtainability and rarity specific to Forever (for example, PvP ranks are obtainable again).
- Do not maintain a hand-written diff layer between the two datasets. The collector is the one place where flavour data differences live.
- Locale overlays for Forever ship only for locales the Forever client supports (an open question).

#### Forever data as delivered (TitlesDBCollector, 2026-11-07)

`data/forever/TitlesDB.enGB.lua`: 40 titles, `EpithetData.version = "1.0.0"`, no locale overlays. Differences from Retail that Epithet handles:

| Difference | Handling |
| --- | --- |
| Own title IDs (only Bloodsail Admiral, 111, matches Retail) | TOC gates keep Retail data and overlays off Forever. The spotting log and favourites live in SavedVariables, which are per game folder. |
| One text, several IDs: "Sergeant" is 10 (Alliance) and 23 (Horde), keyed `sergeant` and `sergeant#23` | `TitleData` indexes faction variants from the data. The dedupe key adds the faction for those titles only, so each faction keeps its own row. `TitleIndex`, the Capture text fallback and SocialLayer pick the variant by the unit's faction. |
| `[DNT] Test` (ID 36) returned by the client | `IsPlaceholderTitle` also drops a leading `[DNT]`, the collector's rule. |
| `kind = "Profession"` (new) | `KIND_PROFESSION` in every locale. |
| No `rarity` | Already optional: the detail card prints nothing, and sorting uses `q`. |
| All `exp = "classic"`, kinds Retail lacks | The sidebar facets come from the loaded data (`Filters:GetBuckets`); Retail's lists are unchanged. |

Known limitation: favourites are keyed by title text, so the two Sergeants share one favourite star.

### Flavour-specific content

- `ns.EXPANSION_ORDER` in [TitleData.lua](../Core/TitleData.lua) drives the sidebar ([Sidebar.lua](../UI/Sidebar.lua)) and filters ([Filters.lua](../Core/Filters.lua)). On Forever nearly everything is "classic", so a twelve-expansion sidebar would be mostly empty. Derive the visible list from the expansions present in the loaded data, keeping `EXPANSION_ORDER` only as the sort order. That works on both flavours with no flavour check.
- Category, kind and faction sidebar sections should hide empty buckets in the same way.
- **Achievements:** separate sets for Retail and Forever on one engine. See [ACHIEVEMENTS_FLAVOUR_SPLIT_PLAN.md](ACHIEVEMENTS_FLAVOUR_SPLIT_PLAN.md). 24 of the current 76 cannot be earned on Forever.
- Locales and fonts stay shared.
- **Theme (done 2026-11-07).** Every colour is a named token in [Core/Theme.lua](../Core/Theme.lua): the base palette plus role tokens named for the component that uses them (`btnBg`, `plateBorder`, `logbookTileBg`, ...). `MainFrame.xml` holds layout only and is painted from Lua skin tables. `Flavors/Forever/Theme.lua` (`[AllowLoadGameType camelot]`, loaded straight after the theme) calls `Theme.Apply` to override tokens in place. It is empty today, so Forever looks like Retail. The migration preserved Retail: 317 colours are identical, or within one 8-bit step where an existing palette token was reused. [validate-theme.ps1](../scripts/validate/validate-theme.ps1) rejects raw colours and unknown tokens.
  - **Token merging, stage 1 (done).** A role token can `Ref` a palette token: it keeps its own name for targeted overrides, but takes its value from the source, and overriding the source cascades to it. The 25 roles that duplicated a palette value now follow it, with no change. Eleven near-duplicates within two 8-bit steps now follow one canonical shade; each is marked "merged" in `Theme.lua`, and the change is invisible. Stage 2 is the larger merges (3–5 steps, mostly the ten-shade dark-surface ramp), which need an in-game look.
  - **Buttons (done).** `Theme.SkinButton(button, looks)` builds every gold-bordered button: background, one-pixel border, and idle/hover/selected/active/disabled looks. The seven hand-built copies (Settings, What's New ×2, Detail ×2, About, Logbook) now use it, and each site's existing quirks are kept as explicit `Theme.ButtonVariant` entries.

### Packaging

The same source supports two packaging options. Choose one at step 7, once the CurseForge question is answered.

- **A. Single package (default).** The build produces one zip with `## Interface: 120105, 120107, 16001`, uploaded once and tagged for Retail and Forever. This is the simplest option. Each client loads only its own files; the cost is that Forever users also download the roughly 750 KB of Retail data, and Retail users the small Forever data. Live and PTR collapse into the same file, which removes today's PTR interface patching.
- **B. Lean per-target packages.** The build reads each TOC line's `[AllowLoadGameType ...]` / `[ExcludeLoadGameType ...]` gate and, for each target:
  - removes the files and TOC lines that target never loads;
  - trims `## Interface` to that target's values.

  It produces `Epithet-<version>-retail.zip` and `Epithet-<version>-forever.zip`. Use this if download size matters, or if CurseForge requires a separate file per game type.

Both options replace the hard-coded `$INTERFACE_LIVE` / `$INTERFACE_PTR` values in [build.ps1](../scripts/build/build.ps1) with a target table, which is the single place that lists interface numbers:

```powershell
$Targets = @(
    @{ Name = 'retail';  GameType = 'standard'; Interfaces = @('120105', '120107') }
    @{ Name = 'forever'; GameType = 'camelot';  Interfaces = @('16001') }
)
```

The build writes the source TOC's `## Interface` line from this table, so the interface numbers can't drift between the table and the TOC.

**Decided (2026-11-07): option B, lean per-target packages.** `build.ps1` makes `Epithet-<version>-<target>.zip` for retail, ptr and forever. Each zip holds:

- its own `## Interface` value;
- only the TOC lines and files its game type loads;
- only its own flavour's `data/`, `Flavors/` and `WhatsNew/` folders, with assets only the other flavour names (Forever's ring texture) left out.

The build runs the validators and the tests (`tools/tests`) first, unless `-SkipChecks`. [FLAVOURS.md](FLAVOURS.md) is the maintenance guide.

### Dev workflow

- **Retail:** unchanged. [link-addon.ps1](../scripts/link/retail/link-addon.ps1) junctions the repo into `_retail_`.
- **Forever:** `scripts/link/forever/link-addon.ps1` and `unlink-addon.ps1` junction the repo into `A:\Blizzard\World of Warcraft\_forever_\Interface\AddOns`. The repo then runs directly in Forever, edits apply on `/reload`, and no build is needed.
- **Packaged testing:** `dist-retail` / `dist-ptr` / `dist-forever` link the built packages from `dist/retail`, `dist/ptr` and `dist/forever`. If option A is chosen, a single `dist` link script per client folder replaces them.
- The empty `scripts/link/classic-mop/` folder has been removed.

## Epithet API surface to audit

This is the inventory for the probe addon. "Current guard" says whether the call site already degrades gracefully when the API is missing.

| Area | APIs / events | Call sites | Current guard |
| --- | --- | --- | --- |
| Title catalog | `GetNumTitles`, `GetTitleName`, `IsTitleKnown`, `GetCurrentTitle`, `SetCurrentTitle` | [TitleData.lua](../Core/TitleData.lua), [TitleIndex.lua](../Spotting/TitleIndex.lua), UI | None (core requirement) |
| Unit identity | `UnitIsPlayer`, `UnitName`, `UnitPVPName`, `UnitGUID`, `UnitClass`, `UnitRace`, `UnitSex`, `UnitFactionGroup`, `UnitIsDeadOrGhost`, `UnitIsUnit`, `GetNormalizedRealmName` | [Capture.lua](../Spotting/Capture.lua), [TitleIndex.lua](../Spotting/TitleIndex.lua), [SocialLayouts.lua](../Core/SocialLayouts.lua) | None (core requirement) |
| Secret values | `issecretvalue` (on `UnitIsUnit` results under combat taint) | [SocialLayouts.lua](../Core/SocialLayouts.lua) | Yes (`if issecretvalue and ...`); also relevant on Forever |
| Achievements | `GetAchievementInfo` (positional returns), `C_AchievementInfo.IsValidAchievement` | [TitleData.lua](../Core/TitleData.lua), [Achievements.lua](../Spotting/Achievements.lua), [Detail.lua](../UI/Detail.lua) | Partial (`if not GetAchievementInfo`) |
| Achievement UI | `UIParentLoadAddOn` / `C_AddOns.LoadAddOn("Blizzard_AchievementUI")`, `AchievementFrame`, `OpenAchievementFrameToAchievement`, `AchievementFrame_SelectAchievement`, `ToggleAchievementFrame`, `ShowUIPanel` | [Detail.lua](../UI/Detail.lua), [TitleData.lua](../Core/TitleData.lua) | Yes (layered fallbacks) |
| Portraits | `SetPortraitTexture`; PlayerModel `SetUnit`, `SetPortraitZoom`, `RefreshCamera`, `OnModelLoaded` | [SocialLayouts.lua](../Core/SocialLayouts.lua), [Settings.lua](../Core/Settings.lua), [SocialLayouts/](../Core/SocialLayouts/) | Partial (`pcall` on the texture path). The 3D path is the most likely to render differently. |
| Settings panel | `Settings.RegisterCanvasLayoutCategory`, `RegisterCanvasLayoutSubcategory`, `RegisterAddOnCategory` | [Settings.lua](../Core/Settings.lua) | Yes (capability-checked) |
| Frames | `CreateFrame(..., "BackdropTemplate")`, `HookScript`, `SetFrameStrata` | Throughout | None |
| Timers / addons | `C_Timer.After`, `C_Timer.NewTimer`, `C_Timer.NewTicker`, `C_AddOns.GetAddOnMetadata`, `C_AddOns.LoadAddOn` | Throughout | Partial |
| Events | `PLAYER_ENTERING_WORLD`, `ACHIEVEMENT_EARNED`, `PLAYER_TARGET_CHANGED`, `UNIT_NAME_UPDATE`, `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED`, `GROUP_ROSTER_UPDATE`, `UNIT_PORTRAIT_UPDATE`, `PORTRAITS_UPDATED`, `UNIT_MODEL_CHANGED`, `UI_SCALE_CHANGED`, `DISPLAY_SIZE_CHANGED` | [Epithet.lua](../Core/Epithet.lua), [Capture.lua](../Spotting/Capture.lua), [SocialLayouts.lua](../Core/SocialLayouts.lua) | `RegisterEvent` raises an error on unknown events, so probe all of them |
| Libraries | LibStub, CallbackHandler, AceAddon, AceDB, LibDataBroker, LibDBIcon; SavedVariables `EpithetDB` | [Epithet.toc](../Epithet.toc), [.pkgmeta](../.pkgmeta) | Probably fine: RareScanner bundles Ace3 and loads on Forever. Confirm Epithet's copies. |

Before treating this list as complete, regenerate it with a grep over `Core/`, `Spotting/` and `UI/` for global API calls and `RegisterEvent`.

## Plan of action

1. **Probe the client.** Write a throwaway probe addon (`## Interface: 16001`, not shipped). For every API and event in the audit table, it:
   - logs `type(_G[name])` (or the namespaced equivalent);
   - calls the read-only APIs with sample arguments and logs their return shapes;
   - registers each event inside `pcall`.

   It should also:
   - dump the full title list (`GetNumTitles` / `GetTitleName`) to its SavedVariables;
   - report whether the achievement system works (`GetAchievementInfo` on a few known IDs, and whether `Blizzard_AchievementUI` loads);
   - print `X-Epithet-Flavor`-style conditional metadata, to confirm the `ns.FLAVOR` mechanism on both clients.

   Then answer the remaining [Still open](#still-open) rows.
2. **Baseline Retail.**
   - Build today's release and PTR zips and keep their file listings and TOC contents as the regression reference.
   - Run [validate-locales.ps1](../scripts/validate/validate-locales.ps1) and [validate-titlesdb-locales.ps1](../scripts/validate/validate-titlesdb-locales.ps1).
3. **Write the compatibility map.** From the probe output, record each API as one of: *identical*, *different shape*, *missing (replacement exists)* or *missing (feature unsupported)*. Only the last three need code.
4. **Restructure for multi-flavour loading (no Retail behaviour change).**
   - Add `Core/Compat.lua` with `ns.FLAVOR`, the conditional `X-Epithet-Flavor` metadata lines, and `16001` on the `## Interface` line.
   - Gate the Retail data files `[AllowLoadGameType standard]`.
   - Add the Forever link scripts.
   - Gate: Retail behaves exactly as before, and the repo loads on Forever without Lua errors (features may be empty or limited at this point).
5. **Add the compatibility wrappers and capability flags.**
   - Move the two `GetAchievementInfo` call sites to `ns.Compat.GetAchievementCompletion`.
   - Add wrappers for the other differences found in step 3.
   - Features marked *unsupported* degrade visibly (hidden or disabled with a reason).
   - Make the sidebar sections derive from the loaded data.
   - Gate: Retail is unchanged in the client.
6. **Produce the Forever data.** Add the collector's Forever mode, generate `data/forever/`, and add its gated TOC entries. Decide which WhatsNew entries are flavour-specific.
7. **Packaging and package checks.**
   - Choose [packaging](#packaging) option A or B and update `build.ps1` with the target table.
   - For every produced zip, verify:
     - the top-level folder is `Epithet`;
     - the `## Interface` values are correct;
     - every TOC-listed file is present, and no unlisted Lua files are included;
     - no `*.local.lua` or other dev-only files are included;
     - for option B, no files gated to another flavour are included.

     Fail the build on any mismatch.
8. **Run the in-client matrix.**
   - On Retail live and PTR, run a smoke test of the existing features.
   - On Forever, test load and `/reload`, the title catalog and ownership, equipping a title, target title spotting, saved-variable persistence, achievement tracking (or its documented absence), the settings panels, both social layouts with 2D and 3D portraits, and localization.
   - Check the Lua error log and combat/taint behaviour on every target.
9. **Release only after all gates pass.**
   - Publish to CurseForge with the Forever game version.
   - Update this target matrix, [RELEASE_NOTES.md](RELEASE_NOTES.md), [CURSEFORGE_DESCRIPTION.md](CURSEFORGE_DESCRIPTION.md) and the build script's upload hints.

## Acceptance criteria

- The remaining open questions are answered and recorded in this document.
- The compatibility map covers every row of the audit table, and every *unsupported* feature is documented and degrades visibly.
- One source tree, with one `Epithet.toc`, loads on Retail live, PTR and Forever, both from a repo junction and from the packaged build.
- Feature code contains no game-version or project-ID checks. `ns.FLAVOR` is used only to select data or content.
- Retail behaviour is unchanged against the baseline.
- No client loads another flavour's files. With packaging option B, no package contains them either, and the package check enforces this.
- The Forever package installs and passes the in-client smoke test without Lua errors or taint regressions.

## References

- [WoW Forever addon development environment and API reference](https://github.com/Atraeau/WoW-Addons)
- [Generated WoW Forever API index and manifest](https://github.com/RdyGaming/hated-wow-mcp/tree/b0893aac3bd42d82ee85733677fec974fb696f71/data)
- Local install evidence: `A:\Blizzard\World of Warcraft\_forever_` (`.flavor.info`, `Logs/Hotfix.log`, and the installed addons' TOCs, notably Auctionator, EllesmereUI, DialogueUI and WaypointUI)
