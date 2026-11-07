# Localization Guide

Epithet is fully localizable. All user-facing UI strings route through a single
locale table, `ns.L`. This guide explains how the system works and how to add a
new language.

> The **Titles database** (`data/<flavour>/TitlesDB.enGB.lua`) is translated separately via
> sparse overlays — see [Localised title database](#localised-title-database) at
> the end. Most of this guide is about the addon's own UI text.

## How it works

- **The machinery lives in `Locales/LocaleManager.lua`.** It's locale-agnostic:
  it creates the `ns.Locales` registry, the `ns.L` proxy, and the resolution API
  (`ns.ApplyLocale`, `ns.ResolveLocaleCode`, `ns.GetAvailableLocales`,
  `ns.GetLocaleDisplayName`) plus the `LOCALE_NAMES` / `LANGUAGE_NAME_KEYS` config.
  It also defines `ns.Glyphs` (shared punctuation like the middle dot and em dash)
  so those byte escapes live in one place instead of being copied into every
  locale file. It loads **first**, before any locale data file. The locale files
  themselves (`enGB.lua`, `ruRU.lua`, …) contain only strings.
- **Every locale registers into `ns.Locales[<code>]`.** Each locale file builds a
  plain table and registers it — no `GetLocale()` guard. `enGB` is the base and
  always loads. `GetLocale()` returns `enUS` for both US and GB clients, so `enGB`
  also serves `enUS`.

  ```lua
  local _, ns = ...
  ns.Locales = ns.Locales or {}
  local L = {}
  ns.Locales.ruRU = L      -- register; do NOT touch ns.L directly
  ```

- **`ns.L` is a read-only proxy, not a table.** A lookup resolves in order:
  **active overlay → English base → the key name itself**. So untranslated keys
  fall back to English automatically, and a key missing from *every* locale
  returns its own name (never `nil`), which is easy to spot in-game.
- **The active locale is chosen at runtime, not by the client.** `ns.ApplyLocale`
  sets which registered locale is the active overlay. Epithet applies the saved
  preference (`EpithetDB` **global** `locale`, default `"auto"` — account-wide,
  like the client's own language) in `Epithet:OnInitialize`, so a player can
  override their game-client language from
  **Options → Epithet → Language**. Because locales are always registered, the
  picker can offer any shipped language on any client. Changing it prompts a UI
  reload (already-drawn text does not re-render live).

### Load order matters

In `Epithet.toc`, `LocaleManager.lua` must be first (it defines the registry and
proxy), then `enGB.lua` (the English base every other locale falls back to), then
the rest:

```txt
# Locale
Locales\LocaleManager.lua   # machinery — must be first
Locales\enGB.lua            # base — before other locales
Locales\ruRU.lua
Locales\<yours>.lua
```

## Adding a new language

1. **Copy `Locales/enGB.lua` to `Locales/<locale>.lua`** (e.g. `deDE.lua`). Valid
   locale codes: `deDE`, `esES`, `esMX`, `frFR`, `itIT`, `koKR`, `ptBR`, `ruRU`,
   `zhCN`, `zhTW`.
2. **Change the registration line** at the top from `ns.Locales.enGB = L` to
   `ns.Locales.<locale> = L`. That's the only structural change — the machinery
   is in `LocaleManager.lua`, so there's no proxy or API block to delete.
3. **Register the language in `LocaleManager.lua`:** add the code + its own-script
   name to `LOCALE_NAMES` (the picker's fallback). For a name that follows the
   active UI language instead (e.g. "German" in an English UI, "Немецкий" in a
   Russian one), also add a `LANGUAGE_<NAME>` key to every locale file and map the
   code to it in `LANGUAGE_NAME_KEYS`.
4. **Translate the right-hand side** of each `L["KEY"] = "..."`. Leave the keys
   unchanged. You may delete lines you haven't translated yet — they'll fall back
   to English.
5. **Add the file to `Epithet.toc`** under `# Locale`, after `enGB.lua`.
6. **Add a `## Notes-<locale>` line** to `Epithet.toc` for the localized addon
   description shown in the client's addon list.
7. **Run the validator** (see below) and fix any orphan keys.

### Character encoding — important

WoW's Lua 5.1 does **not** support `\xNN` hex escapes. Write UTF-8 text directly
(the existing `ruRU.lua` does this), or use **decimal** byte escapes for glyphs,
e.g. `\226\128\148` = em dash. The validator flags `\x` escapes as errors.

### Fonts and non-Latin scripts — important

The client's fonts (`FRIZQT__.TTF`, `MORPHEUS.TTF`) only contain glyphs for the
client's own region. So when the **language override** runs Epithet in a script
the client font lacks — e.g. **Russian on a Western client** — text renders as
empty boxes. Epithet loads a **bundled Unicode font** for those locales; see
`Fonts/README.md` for which files to add and recommended OFL fonts. The list of
locales that need the bundle is `BUNDLED_FONT_LOCALES` in `Core/Theme.lua`
(currently `ruRU`). Western-European locales render fine on the client fonts;
CJK is not bundled (font files are too large) and renders only on a matching
client.

## What's New content

Per-version release notes live in `WhatsNew/Retail/*.lua` and `WhatsNew/Forever/*.lua` (one folder per game flavour). Their `title` and
`body` fields may be either a plain string or a table keyed by locale:

```lua
title = { enUS = "Epithet 1.2.0", ruRU = "Epithet 1.2.0" },
body  = { enUS = [[ ... ]], ruRU = [[ ... ]] },
```

`WhatsNew:LocalizeField` resolves the active locale and falls back to `enUS`, so
adding a translation is purely additive — drop in a new locale key.

## Text-based achievements (nothing to translate)

Five Spotting achievements are decided by a title's *text*: `lord_of_lords`,
`masterclass` and `slay` look for a word in it, `quite_a_mouthful` and `terse`
measure its length.

These match the **English catalogue name**, not the name on screen, so they need
no per-locale data and work identically on every client. The spotting log is
keyed by `titleID` — Blizzard's numeric ID, the same in every locale — and the
bundled DB (`data/<flavour>/TitlesDB.enGB.lua`) is always English, so `CatalogueText()` in
`Spotting/Achievements.lua` resolves any spotted title back to its English name.
The search words are therefore plain constants:

```lua
local KEYWORD_ACHIEVEMENTS = {
    lord_of_lords = "lord",
    masterclass   = "master",
    slay          = "slayer",
}
```

Only the displayed **name and description** are translated, in the locale files.
Because the match is on the English name and the player sees a localized one,
non-English descriptions should say so rather than name a translated word — e.g.
frFR: *"Repérez 5 titres distincts dont le nom anglais contient « Lord »."*

`CatalogueText()` falls back to the live `GetTitleName()` text for any title the
DB snapshot doesn't carry yet, so a title added by a patch before the DB is
regenerated still counts on an English client.

### Gating an achievement to specific locales

`LocaleAllows(def)` still honours a `locales` set on a Registry entry (checked
against `GetLocale()`, the game client's language). Nothing uses it today — the
achievements that once needed it are language-neutral now — but it's there if a
future achievement genuinely cannot be earned in some language.

## Validating

```powershell
powershell -File scripts\validate\validate-locales.ps1
```

Reports, per locale: translation coverage, **untranslated** keys (warnings —
they fall back to English) and **orphan** keys not in `enGB` (errors — usually a
typo or a stale key). Also lints every locale for unsupported `\x` hex escapes.
Exit code is non-zero on any error, so it can gate CI.

It then scans the addon source (`Core\`, `UI\`, `Spotting\`, `WhatsNew\`,
`Locales\LocaleManager.lua`) and compares it against the `enGB` base:

- **Undefined** keys — an `L["KEY"]` the code looks up that *no* locale defines
  (error, reported with the `file:line` that uses it). Coverage alone can't catch
  these: every overlay sits at 100% while the base itself is missing the key, and
  because `ns.L` falls back to the key *name*, the UI silently renders raw text
  like `SOCIAL_LAYOUT_PORTRAIT_MODE`. **Add a key to `enGB.lua` in the same
  commit as the code that uses it.**
- **Unused** keys — defined in `enGB` but referenced nowhere (warning; stale
  leftovers to prune from every locale).

The scan is static, so keys assembled at runtime (`L["CAT_" .. code]`) are
invisible to it. Those prefixes are listed in the script's `-DynamicKeyPrefixes`
default and exempt from the unused warning — **add yours there** if you
introduce a new concatenated key family, or it will be reported as stale.

## Localised title database

The title database is separate from the UI strings above, but follows the same
base-plus-overlay shape.

> Both files are collector-generated (see the sibling `TitlesDBCollector` repo's
> `tools/schema.json` `localeOverlay` section and its README's "Locale support"
> section). The field list and output shape here are a **shared contract** —
> changing one side without the other breaks translations silently until
> someone runs `scripts/validate/validate-titlesdb-locales.ps1`.

**One folder per flavour.** `data/` has nothing at its root:

| Folder | Client | Game type | Overlays |
| --- | --- | --- | --- |
| `data/retail/` | Retail live and PTR (same game, same title IDs) | `standard` | deDE, frFR, ruRU, zhCN |
| `data/forever/` | WoW Forever | `camelot` | none yet |

Each client loads only its own folder: every data line in `Epithet.toc` carries
`[AllowLoadGameType standard]` or `[AllowLoadGameType camelot]`. The two are
complete, separate title sets with **unrelated title IDs** (Forever 1 is "of the
Magram", Retail 1 is "Private"), so an overlay only ever applies to its own
folder's base. A Retail overlay must never load on Forever: it would attach
Retail translations to unrelated Forever titles.

- **`data/<flavour>/TitlesDB.enGB.lua`** is the canonical base: the full English dataset,
  keyed by title text, carrying every field. It's collector-generated (gitignored).
  When the client gives one text several IDs (Forever's Alliance "Sergeant" 10 and
  Horde "Sergeant" 23), each ID has its own entry: the first under its text, the
  rest under `"<text>#<titleID>"`, with `text` holding the real title text.
- **`data/<flavour>/TitlesDB.<code>.lua`** (e.g. `data/retail/TitlesDB.ruRU.lua`) are **sparse overlays**
  keyed by **`titleID`** — the numeric ID Blizzard assigns, identical on every
  client locale, so it's the stable join key. An overlay translates only the
  free-prose fields Epithet displays from the database:
  `obtainability_reason`, `achievement`, `quest`, `source_item`. Any titleID or
  field it omits falls back to the enGB base.

**Not translated in an overlay:** title *names* (Epithet shows those via
`GetTitleName()`, which the client already localises, so they match nameplates);
and language-neutral data (`type`, `q`, `exp`, `cat`, `kind`, `obtainable`, …).
The `exp`/`cat`/`kind` **labels** are translated in the locale files above (the DB
ships codes, not labels).

**How it's wired:** each overlay registers into `ns.TitlesDBLocales[<code>]`
(`Core/TitleData.lua`). `ns.ResolveTitlesDBOverlay()` picks the one matching the
active display language (`ns.activeLocale`), and `TitleData:Scan()` prefers an
overlay field, falling back to the base. A language switch triggers a `ReloadUI`,
so `Scan` re-runs fresh — no live-refresh path is needed.

**Adding one:** generate it with the collector (its locale sources are split
the same way, `locales/<flavour>/`), which writes `data/<flavour>/TitlesDB.<code>.lua`.
Add it under `# Bundled Data` in `Epithet.toc` **after** that flavour's enGB
base, with the same `[AllowLoadGameType ...]` gate as the base, then validate:

```powershell
pwsh -File scripts\validate\validate-titlesdb-locales.ps1                 # every flavour
pwsh -File scripts\validate\validate-titlesdb-locales.ps1 -Flavor forever # one flavour
```

Reports, per flavour and overlay: coverage (titles translated) and **orphan
titleIDs** not in that flavour's base (errors), plus any stray file at the
`data/` root (error). Also lints for `\x` hex escapes and stray `null` literals
(Lua has no `null` — it silently becomes `nil`). Exit code is non-zero on any
error, so it can gate CI.
