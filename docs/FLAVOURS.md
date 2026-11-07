# Flavours: one Epithet for Retail and WoW Forever

Epithet is one addon, one codebase and one version number for every game it
runs on. The game is a dimension of the build, not a second app: Retail (with
PTR) and WoW Forever load the same shared code, and each loads only its own
flavour files on top.

| Flavour | Game type in the TOC | Clients |
| --- | --- | --- |
| retail | `standard` | Retail live (120105) and PTR (120107) |
| forever | `camelot` | WoW Forever (16001) |

## Where differences live

Everything that differs between flavours sits in one of four places. Nothing
else may know which flavour it runs on.

| What | Where | Example |
| --- | --- | --- |
| Title data | `data/<flavour>/` | `data/forever/TitlesDB.enGB.lua` |
| Theme, settings, achievement list | `Flavors/<Flavour>/` | `Flavors/Forever/Theme.lua`, `Flavor.lua`, `Achievements.lua` |
| Release notes | `WhatsNew/<Flavour>/` | `WhatsNew/Forever/v1_4_0.lua` |
| Switches the shared code reads | `ns.Flavor.<setting>`: defaults in `Core/Flavor.lua`, set in `Flavors/<Flavour>/Flavor.lua` | `showRealm`, `campfireSpellID` |

Every file in a flavour folder is gated in `Epithet.toc` with its flavour's
game type, for example `Flavors\Forever\Theme.lua [AllowLoadGameType camelot]`.
Shared files are never gated.

## The rules

1. **Shared code never asks which flavour it is on.** Core/, UI/ and Spotting/
   contain no `camelot`, no `"forever"`, no `ns.Flavor.id`, no `WOW_PROJECT_ID`
   and no interface-number checks. When behaviour must differ, add a setting to
   `ns.Flavor` with the Retail value as the default, and set it in the other
   flavour's `Flavor.lua`. The shared code reads the setting, never the
   flavour.
2. **Handle API differences by what the API does, in one place.** On Forever,
   `UnitName` and `UnitFullName` return the surname where Retail returns the
   realm. Code reads the displayed name (`TitleData`'s `ReadPlayerName`) rather
   than guessing which game it is on.
3. **Data decides, sets state facts.** Achievement checks read the loaded title
   data (counts, tiers, kinds, ladders). A flavour's achievement list states
   only its own facts, such as `CLASS_TOTAL = 9` on Forever.
4. **Retail stays as it is unless a change is meant for Retail.** The Retail
   achievement snapshot test (below) fails if a change alters how any Retail
   achievement behaves.

`scripts/validate/validate-flavours.ps1` enforces rule 1 and the TOC gates, and
the build runs it.

## Common tasks

**A Forever-only file.** Put it in `Flavors/Forever/` (or `data/forever/`,
`WhatsNew/Forever/`) and list it in `Epithet.toc` with
`[AllowLoadGameType camelot]`, next to the shared file it extends.

**Behaviour that differs.** Add `ns.Flavor.mySetting` to `Core/Flavor.lua` with
the Retail value, set it in `Flavors/Forever/Flavor.lua`, and read
`ns.Flavor.mySetting` in the shared code.

**A colour or texture for one flavour.** Name the token or texture in
`Flavors/<Flavour>/Theme.lua` (`Theme.Apply`). See `Core/Theme.lua` for every
token. A texture override must name a file that exists; the theme validator
checks this.

**Achievements.**

- **The lists:** each flavour's list is `Flavors/<Flavour>/Achievements.lua`.
  The engine and the shared check builders (`ns.SpottingAchievements.B`) live
  in `Spotting/Achievements.lua`.
- **Kept and hidden ids:** keep an id when the same achievement exists on both
  flavours, so names and translations are shared. A flavour hides ids it drops
  (`hidden = { ... }`), so anything already earned stays saved.
- **New text:** add the name and description to every locale file.

**A title data update.** After TitlesDBCollector writes `data/<flavour>/`, run
the tests. The audit (`tools/tests/achievements-audit.test.js`, or
`/epithet admin achvaudit` in game) lists any achievement the new data makes
impossible or free. New titles can also bring back a hidden one.

**Release notes (optional).** A release only needs notes when there is
something to tell players. Add `WhatsNew/<Flavour>/vX_Y_Z.lua`, keyed to the new
version, for each flavour that needs them. Without notes, nothing opens after
the update, and `/epithet whatsnew` shows the newest notes there are. With
notes, the tests require a title and body in every locale.

**Client differences.** The dev-only probe addon (`tools/probe/EpithetProbe`,
`scripts/probe/link-probe.ps1`) records what a client's APIs return
(`/eprobe names`, `/eprobe self`) and which textures load (`/eprobe textures`).
Run it on both clients, Retail first as the control.

## Tests

The tests run Epithet's Lua in a Lua VM (fengari), with both flavours' data:

```sh
cd tools/tests
npm install        # once
npm test           # everything; or: node run-all.js <name filter>
```

| File | Covers |
| --- | --- |
| `compile.test.js` | Every addon file compiles, with room under Lua's 200-local limit |
| `titles.test.js` | Title data, filters and title reading on both flavours |
| `theme.test.js` | The theme system and the Forever theme |
| `achievements-retail.test.js` | Retail's 76 achievements against a snapshot |
| `achievements-forever.test.js` | Forever's 64 achievements and the Logbook's sighting details |
| `achievements-audit.test.js` | Every achievement can be earned with its flavour's data |
| `character-key.test.js` | Per-character data keyed by character ID, and its migration |
| `logbook-retail.test.js` | The Logbook's sighting details on Retail |
| `whatsnew.test.js` | Each flavour loads only its own release notes |
| `probe.test.js` | The probe addon's commands |

The Retail snapshot (`tools/tests/golden/retail-achievements.txt`) holds one
fingerprint per Retail achievement. When a change to Retail achievements is
intended, review the failure, then refresh it:

```sh
node tools/tests/achievements-retail.test.js --update
```

## Building and releasing

```powershell
./scripts/build/build.ps1              # validators + tests, then the zips
./scripts/build/build.ps1 -Bump minor  # bump the version first
./scripts/build/build.ps1 -SkipChecks  # build only
```

The build makes one lean zip per target from the `$Targets` table in
`build.ps1`:

- **Per-target TOC.** It writes the target's `## Interface` line.
- **Only what the game loads.** It drops the TOC lines and files the target's
  game type never loads, the other flavours' `data/`, `Flavors/` and
  `WhatsNew/` folders, and any Epithet asset only those files name (such as
  Forever's ring texture in the Retail zip).
- **A final check.** It fails if a package lists a missing file or a file its
  game never loads.

Upload each zip to its CurseForge game version:

| Zip | CurseForge game version |
| --- | --- |
| `Epithet-<version>-retail.zip` | Retail |
| `Epithet-<version>-ptr.zip` | PTR / Beta |
| `Epithet-<version>-forever.zip` | WoW Forever |

All flavours release together under one version number.

**If CurseForge packages from the repo** (`.pkgmeta`), it does not do this
trimming: it builds a single zip with everything, and the TOC gates still
decide what each client loads. The `build.ps1` zips are the lean ones.

## When to change this approach

Per-file TOC gates scale to dozens of files. If the gated list ever becomes
hard to follow, the next step is a flavour-suffixed TOC per game
(`Epithet_Camelot.toc` next to `Epithet.toc`). That is still one codebase, with
two file lists to keep in step. Separate branches or separate addons are not
recommended: most of Epithet is shared, so every fix would have to land twice.
