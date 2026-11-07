# Plan: separate Epithet achievements for Retail and WoW Forever

Status: all six steps done, 2026-11-07, not yet tested in game. Part of the
[WoW Forever support plan](WOW_FOREVER_SUPPORT_PLAN.md). The tests are in
`tools/tests/` (see [FLAVOURS.md](FLAVOURS.md)). The one-off equivalence proof
against the old single-file engine has been replaced by a Retail snapshot
test. Retail's `count_700` now asks for 650, as agreed.

Probe answers (Forever 1.60.1):

- **Icons:** all 104 textures Epithet names load, including every achievement
  icon.
- **Classes:** nine. The IDs are sparse: 6 (Death Knight) is missing and Druid
  is 11.
- **Campfire buff:** "Campfire Nearby" is spell 1283391. `IsResting()` is false
  at a camp, so the buff is the only reliable sign.
- **Skyborne:** the race token is `Skyborne` (race 95, Alliance "High Order
  Skyborne"). The Horde Windshapers' token is not probed yet; the check matches
  it as a prefix.
- **Realms:** `GetPlayerInfoByGUID` gives internal realms ("Realm1",
  "Realm5"), so the ruleset "mega-realm" is several realms underneath. Names
  are unique per region, so name keys still never collide.

## Goal

Each flavour gets an achievement set that fits its own titles:

- **Retail** keeps its 76 achievements exactly as they are.
- **Forever** gets the achievements that work with its 40 titles, plus a set
  made for Forever: its two-part names, PvP rank ladders, new race and class
  pairings, campfires, and the launch-week jokes.

Both flavours share one engine, so storage, evaluation, alerts and the Logbook
achievements panel stay single-sourced.

## Where things stand

- One registry of 76 achievements in
  [Spotting/Achievements.lua](../Spotting/Achievements.lua) (`Registry`, around
  line 1644). It loads on every flavour, so Forever has been running the Retail
  set since 4 November.
- The checks hardcode Retail facts: count thresholds up to 700,
  `CLASS_TOTAL = 13`, five rarity tiers, and Retail titleIDs for Jenkins (110)
  and the Insane (112). They also rely on sources Forever's data does not have:
  raids, removed titles, and titles linked to an achievement or quest.
- Icons live separately, in `ACHIEVEMENT_FALLBACK_ICONS` in
  [Spotting/LogbookUI.lua](../Spotting/LogbookUI.lua). Names and descriptions are
  `SPOT_ACHV_NAME_<ID>` / `SPOT_ACHV_DESC_<ID>` in the locale files (152 keys in
  enGB).
- `EXPECTED_ACHIEVEMENT_TOTAL = 76` is checked at load.
- Saved data (`EpithetDB`) is per game install. Retail (`_retail_`) and Forever
  (`_forever_`) each have their own WTF folder, so they never share earned
  achievements or spotting logs.

### What the name probe showed (Forever 1.60.1, 2026-11-07)

| API | Returns for "Manny Hunters" |
| --- | --- |
| `UnitName`, `UnitFullName`, `UnitNameUnmodified` | `"Manny"`, `"Hunters"` |
| `UnitPVPName`, `GetUnitName(unit, false/true)` | `"Manny Hunters"` |
| `GetPlayerInfoByGUID` name, realm | `"Manny Hunters"`, `""` |
| `GetRealmName` / `GetNormalizedRealmName` | `"CAMWOW EU4 Realm 1 PvE"` / `"CAMWOWEU4Realm1PvE"` |

On Forever the second value of `UnitName` and `UnitFullName` is the **surname**,
where Retail puts the realm. Consequences:

- The character key that `Spotting/Log.lua` and `Spotting/Achievements.lua` each
  build as `name-realm` comes out as `"Manny-Hunters"`. That is the full name.
  Forever names are unique per region and cannot be changed, so characters
  never collide.
- The Logbook records spotted players with `GetUnitName(unit, true)`, which is
  the full `"Manny Hunters"`. So name-based achievements already see full
  names.
- Any future code must not treat that second value as a realm on Forever.

## Audit: the Retail set against Forever's data

Forever's data (`data/forever/TitlesDB.enGB.lua`, 2026-11-07) has 40 titles:

- 28 PvP ranks (14 per faction), 7 profession, 4 reputation and 1 achievement title.
- Rarity tiers: 16 Common, 16 Uncommon, 6 Rare, 0 Epic and 2 Legendary (the
  rank 14 titles).
- One expansion ("classic") and no removed titles.
- No achievement, quest or item sources.
- One character can hold at most 26 of the titles: its own faction's 14 ranks
  plus the 12 non-PvP titles.

| Result on Forever | Count | Achievements |
| --- | --- | --- |
| Cannot be earned | 24 | `count_50`, `count_100`, `count_200`, `count_350`, `count_500`, `count_700` (40 titles); `full_spectrum`, `owned_spectrum`, `matching_set` (no Epic tier); `seeing_stars` (2 Legendary titles); `old_money`, `museum_curator`, `owned_removed` (nothing removed); `at_least_chicken`, `certified` (Retail titleIDs); `lord_of_lords`, `masterclass`, `slay` (2, 2 and 0 matching titles, need 5); `raid_spectator` (no raid titles); `brown_noser` (4 reputation titles, needs 5); `how_its_made` (no achievement, quest or item sources); `owned_50`, `owned_100` (26 per character); `secret_keeper` (needs Retail-only secrets) |
| Earned for free | 3 | `potted_history`, `curriculum_vitae` (one expansion); `old_school` (every title is Classic) |
| Barely possible | 1 | `quite_a_mouthful`: the only qualifying title, the Harbinger of Darkness, has no known source |
| Depends on classes | 2 | `roll_call` (needs 13 classes); `dead_man_walking` (Death Knights, which Forever does not have) |
| Works as it is | 46 | The rest |

## The Forever set

### Kept from Retail (48)

- **The 46 that work.** They keep the same ids, so they share names,
  descriptions and translations with Retail.
- **`roll_call`:** kept, but its total comes from the client
  (`GetNumClasses()`) instead of the constant 13.
- **`secret_keeper`:** kept, re-based on the Forever set's own secrets.
  Time-limited achievements never count toward it.

The dropped ids are listed in the audit above.

### Thresholds that fit 40 titles

Retail's "spot N distinct titles" ladder runs 1, 10, 25, 50, 100, 200, 350, 500
and 700. Forever only has 40 titles, so every step above 40 can never be
reached. Forever keeps 1, 10 and 25, and adds one new top step:

- **`count_40`, The Whole Collection:** spot all 40 titles. That needs both
  factions' ladders, so it is a real capstone.

The "own N titles" ladder keeps 1, 10 and 25. A character can hold 26 titles
at most, so 25 is already near the ceiling.

### New for Forever (15)

The table's last column says what Epithet needs before each achievement can
be built:

- **Ready:** works with the data Epithet already records.
- **Needs capture:** one more field recorded when a title is spotted.
- **Needs probe:** a value read from the Forever client first.

| Name | Description | How Epithet tells | Ready? |
| --- | --- | --- | --- |
| **Keeping Up with the Joneses** | Spot titles on 3 different players who share a last name. | The surname is the last word of the spotted player's full name. | Ready |
| **Family Business** | Spot the same title on two players who share a last name. | The first and latest player seen with a title share a surname but have different first names. | Ready |
| **Chain of Command** | Spot all 14 ranks of one faction's ladder. | PvP rank titles per faction. | Ready |
| **Mirror Image** | Spot the same rank worn by both factions. | For example, both Sergeants (titleIDs 10 and 23). | Ready |
| **Top Brass** | Spot a Grand Marshal and a High Warlord. | The two rank 14 titles. | Ready |
| **Centaur of Attention** | Spot both "of the Gelkis" and "of the Magram". | The two clans are sworn rivals, and earning one sets the other against you. | Ready |
| **Trade Secrets** | Spot all 7 profession titles. | `kind = "Profession"`. | Ready |
| **Who Are You?** *(secret)* | Spot the Harbinger of Darkness. | No one has said how it is earned. | Ready |
| **New Combo, Who Dis?** | Spot titles on all six new race and class pairings: Orc Mage, Troll Warlock, Undead Paladin, Human Hunter, Gnome Priest and Dwarf Shaman. | Race and class tags, already recorded. Undead's race tag is `Scourge`. | Ready |
| **Slaps Roof** *(secret)* | "This bad boy can fit so many titles." Spot titles on 3 Gnomes in one day. | A nod to the official account's launch meme of a Gnome slapping the roof of a car with the Forever logo. | Ready |
| **First Wave** *(secret, time-limited)* | First-spot a title in launch week, 4 to 11 November 2026. | Spot dates. Logs from launch week count, so early players earn it straight away. | Ready |
| **Position in Queue: 1** | Spot a title within 2 minutes of logging in. | For everyone who sat in the launch queues. | Needs capture: session start time |
| **Forever Young** | Spot a title on a player below level 20. | The spotted player's level. | Needs capture: `UnitLevel` |
| **Head in the Clouds** | Spot a title on a Skyborne. | The race tag. | Needs probe: `/eprobe names` on a Skyborne player |
| **Campfire Stories** | Spot 3 titles while you rest at a campsite. | Your campfire buff. | Needs probe: the buff's spell ID, read at a camp |

**Boats? What Boats?** (launch day's broken boats and zeppelins) was considered
and dropped. Epithet has no reliable way to tell that you are on a boat.

That makes **64 achievements** on Forever: 48 kept, 1 new count step and 15
new.

## Design

### 1. Engine and achievement sets kept apart

- `Spotting/Achievements.lua` keeps the engine: storage, evaluation, progress,
  reveal, alerts. It also holds a library of check builders, such as
  `CountSpotted(n)`, `Keyword(word, n)`, `Source(kind, n)`, `Tier(q, n)`,
  `TitleSpotted(key)`, `AllOfKind(kind)`, `RaceClass(pairs)` and
  `SharedSurname(n)`. These replace the one-off `Check*` functions where a
  parameter is all that differs.
- Each flavour's set is a plain list in its flavour folder, gated in the TOC
  like the theme:
  - `Flavors/Retail/Achievements.lua` with `[AllowLoadGameType standard]`;
  - `Flavors/Forever/Achievements.lua` with `[AllowLoadGameType camelot]`.

  Each calls `ns.SpottingAchievements.DefineSet({ ... })`. An entry has `id`,
  `check`, `progress`, `group`, `scope`, `secret`, `timeLimited` and `icon`.
  The icon moves from LogbookUI's table into the entry.
- Retail-only facts move into the Retail set: Jenkins and the Insane are named
  there by title key, not by a titleID constant in the engine.
- `EXPECTED_ACHIEVEMENT_TOTAL` becomes the set's own `expected` count. At load,
  the engine reports duplicate ids, unknown builders and missing locale keys.
- **Retail stays exactly as it is.** An equivalence test runs the old registry
  and the new Retail set over fixture spotting logs and checks every
  achievement gives the same result.

### 2. Character identity: character ID as the key, full name as the label

Both together is possible, and it is the better option:

- **The key** is the character's ID (`UnitGUID("player")`). It stays the same
  through a Retail name change, which today leaves a character's owned titles
  and per-character achievements stranded under the old name. It also never
  depends on what an API's second value means on a given flavour.
- **The label** is stored with it: the full name (`"Manny Hunters"`, from
  `TitleData`'s `ReadPlayerName`) and the realm where there is one. That keeps
  SavedVariables readable and gives the UI something to show.
- **Migration** happens once per character at login. Epithet knows both the old
  `name-realm` key and the ID, so it moves that character's data across. Other
  characters move when they next log in.
- **One helper.** It replaces the two copies of the key function in `Log.lua`
  and `Achievements.lua`.
- **Not urgent for Forever.** Its full-name keys are already unique, so this
  can follow the set split rather than block it. A realm transfer changes the
  ID, but it changes today's `name-realm` key as well, so nothing gets worse.

### 3. Achievements already earned on Forever

Hide, don't delete (decided). Achievements the Forever set drops stay stored,
most likely the three free ones. They are left out of the panel and the counts.
Ids in both sets keep their earned state and date.
`db.achievementSet = "forever-1"` is recorded so later set changes can migrate
deliberately.

### 4. Text, icons and tooling

- **Locale keys.** New ids need `SPOT_ACHV_NAME_` / `SPOT_ACHV_DESC_` keys in
  enGB. The overlays fall back to English until translated.
- **Icons.** Moving them into the set entries lets
  [build-probe-textures.ps1](../scripts/probe/build-probe-textures.ps1) pick up
  both sets. Every Forever icon is then checked on the Forever client by
  `/eprobe textures` before release.
- **Probe additions.** The probe gains a `/eprobe self` command that records
  your buffs (for the campfire spell), the class list and your `UnitGUID`.
- **Spot-time capture.** `Spotting/Log.lua` records two more fields when a
  title is spotted: the player's level and the session's login time. Old
  entries without them simply don't count toward those two achievements.
- **Achievability audit.** This is a test that loads each set with its
  flavour's data. It flags any achievement whose threshold is above what the
  data allows, or that needs a tier, source or title the data lacks. It reruns
  whenever Forever's data changes, because new phases add titles and can bring
  back achievements dropped today.
- **A naming trap.** A spotted entry's `firstName` and `lastName` mean the
  first and the latest player the title was seen on. They are not a person's
  first and last names. Comment them in `Spotting/Log.lua` now that Forever has
  surnames.

## Steps

Each step ships on its own.

1. **Engine refactor and Retail set**, with the equivalence test. No visible
   change on either flavour. **Done:** the engine is
   [Spotting/Achievements.lua](../Spotting/Achievements.lua) (with builders in
   `ns.SpottingAchievements.B`); the list is
   [Flavors/Retail/Achievements.lua](../Flavors/Retail/Achievements.lua),
   generated from the old registry and icon table. The old and new code gave
   identical results for all 76 achievements over 600 generated spotting logs
   (46,200 results compared).
2. **Forever set v1:**
   - the 48 kept and `count_40`;
   - the 11 new achievements marked Ready;
   - the dropped ids hidden;
   - the locale keys.

   **Done:** [Flavors/Forever/Achievements.lua](../Flavors/Forever/Achievements.lua),
   with 60 achievements and 28 hidden. A test gives every new achievement a
   log that should earn it and one that shouldn't. The new text is English
   only so far.

   Two things to follow up:
   - `roll_call` assumes Forever's nine Classic classes.
   - Mirror Image and Top Brass read the rank from the title's prose ("Horde
     PvP rank 7 of 14"). A `rank` field from the TitlesDBCollector would be
     sturdier.
3. **Probe run (needs you in game).** At a campsite: `/eprobe self`. Then
   `/eprobe names` on a Skyborne player. **Done:** the answers are at the
   top of this plan.
4. **The remaining four:**
   - Position in Queue: 1 and Forever Young, with the new capture fields;
   - Head in the Clouds and Campfire Stories, with the probe values.

   **Done:** [Spotting/Log.lua](../Spotting/Log.lua) now records three
   moments with each sighting:
   - `lowestLevel`, the lowest level a wearer was seen at;
   - `seenSoonAfterLogin`, seen within 2 minutes of a fresh login (a `/reload`
     does not restart the clock);
   - `seenAtCampfire`, seen while the flavour's `ns.Flavor.campfireSpellID`
     buff is on you.

   The fields survive the load-time normalise and the import merge, but are
   not in the export format. Forever has 64 achievements.
5. **Character ID keys with full-name labels** (Design §2), on both flavours,
   with the login migration. **Done** in
   [Spotting/Achievements.lua](../Spotting/Achievements.lua):
   - Per-character achievements, owned titles and the scan baseline are keyed
     by `UnitGUID("player")`.
   - `db.characters[id]` holds `name` (the full name on Forever), `realm`
     (Retail only) and `lastLogin`.
   - The first key lookup each session folds the old name-realm entry into
     the ID, keeping the earliest earned date and preferring reliable owned
     dates, then removes the old entry.
   - **What stays on the old key:** the Logbook export codes. Their signature
     and import check use name-realm, so changing it would break codes
     already shared.
   - **Lua's limit:** the engine had reached 200 file-level locals, the limit
     in WoW as well. The new helpers and the progress functions now sit in
     scoped blocks, which leaves room for 50 more.
6. **Achievability audit, docs, and a What's New entry for Forever.** **Done:**
   - **Audit.** Each check builder notes what it needs from the title data,
     and `Achievements:Audit()` lists what the loaded data makes impossible or
     free. `/epithet admin achvaudit` (local admin file) prints it; run it
     after a data update.
   - **Audit results.** On Forever's data it flags nothing in the Forever set.
     Run on the Retail set with Forever's data, it independently reproduces
     the 28 achievements hidden on Forever. On Retail's data it flags
     `count_700`: there are 694 titles, so it can't be earned, and neither can
     Secret Keeper, which needs it. Retail's set is unchanged pending a
     decision.
   - **What's New per flavour.** Retail's entries are in `WhatsNew/Retail/`
     and Forever's in `WhatsNew/Forever/`, each gated in the TOC.
   - **1.4.0 entries.** Forever's opens by itself. Retail's has
     `hasNew = false` because nothing visible changed there, but
     `/epithet whatsnew` still shows it. Both are English only. They are keyed
     to version 1.4.0, so they show once the TOC version is 1.4.0.

## Decided

- Forever-only achievements: the 15 above, with their working names. Edit any
  name or drop any you don't like before step 2.
- Thresholds: spot 1/10/25/40, own 1/10/25.
- Dropped achievements already earned on Forever: hidden, not deleted.
- Character identity: character ID as the key, full name as the label.
