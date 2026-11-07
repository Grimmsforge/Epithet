# Epithet What’s New Feature

## Overview

The What’s New feature shows a themed, centered popup after login when a given addon version has unseen update content.

It is designed to:

- Show once per version by default
- Be controlled by per-version flags in SavedVariables
- Load content from packaged version files
- Render simple markdown-like content with headings, emphasis, and images

## File layout

Core runtime:

- Core/WhatsNew.lua

Content registry:

- WhatsNew/Content.lua

Per-version content, one folder per game flavour (each file gated in `Epithet.toc`; see [FLAVOURS.md](FLAVOURS.md)):

- WhatsNew/Retail/v1_4_0.lua (`[AllowLoadGameType standard]`: Retail and PTR)
- WhatsNew/Forever/v1_4_0.lua (`[AllowLoadGameType camelot]`: WoW Forever)

Each game sees only its own notes. A release does not need notes:

- **With notes for the current version:** the window opens once after the update (unless the entry sets `hasNew = false`), and `/epithet whatsnew` shows them.
- **Without:** nothing opens by itself, and `/epithet whatsnew` shows the newest notes there are for that game (`WhatsNew:GetLatestContentVersion()`).

Per-version art (optional):

- WhatsNew/<Flavour>/v1_1_1/
  - A folder alongside the matching `.lua` file, for art that is specific to that
    version's changelog only (a feature banner, a one-off screenshot). It is not
    listed in `Epithet.toc` — texture files are referenced by path at runtime and
    don't need a load-order entry, unlike `.lua`/`.xml` files.
  - Brand assets reused elsewhere in the addon (e.g. the wax-seal mark) should
    stay in `icons/logo/` rather than being duplicated here.

Addon packaging/load order:

- Epithet.toc

## How content is mapped to versions

Each version file registers an entry in ns.WhatsNewContent.versions.

Example shape:

- key: 1.1.1
- fields:
  - hasNew: boolean
  - title: popup title text
  - body: markdown-like multiline string

The runtime reads the current addon version from metadata and looks up a matching entry in ns.WhatsNewContent.versions.

## Display logic

The popup is shown only when all conditions below are true:

1. There is content for the current version
2. firstRun is true for that version
3. hasNew is true for that version

There is also session protection to avoid duplicate popups from repeated PLAYER_ENTERING_WORLD event firing.

## SavedVariables model

Stored under EpithetDB.whatsNew.

Shape:

- byVersion
  - [version]
    - firstRun: boolean
    - hasNew: boolean

Behavior:

- On first encounter of a version, defaults are initialized
- Closing the popup sets firstRun to false and hasNew to false for current version

## Popup behavior

- Appears centered on screen after login delay
- Uses Epithet-style visuals and button skinning
- Is dismissible via close control or close button
- Can be reopened manually with slash command:
  - /epithet whatsnew

## Content format support

The body parser supports these patterns per line (blank lines are ignored -
spacing is automatic, see below):

- '# Heading 1'
- '## Heading 2'
- '* Bullet line' (single leading star + space; consecutive bullets are
  grouped tighter than other block transitions)
- Plain paragraph lines
- Inline bold using double stars
- Inline emphasis using single stars (rendered as a colour tint, not a slanted
  font - WoW has no italic variant of the addon's body font loaded)
- Image line using markdown image syntax:
  - `![alt](texturePath)` - defaults to a 96x96 box
  - `![alt](texturePath =WIDTHxHEIGHT)` - pins an explicit display size, for
    non-square art. The `alt` text itself is discarded; it exists only for
    author readability.

Notes:

- Each line becomes a real widget (FontString or Texture), not a markup tag
- Every block type has a fixed gap-before value (see `BLOCK_STYLE` and
  `IMAGE_GAP_BEFORE` in Core/WhatsNew.lua), so headings and images always get
  breathing room regardless of blank-line placement in the source

## Rendering implementation notes

The feature renders each parsed block as a pooled `FontString` or `Texture`
positioned directly with `SetPoint`, stacked top-to-bottom inside a plain
`Frame` scroll child - there is no HTML widget involved.

This replaced an earlier SimpleHTML-based implementation. `SimpleHTML:SetText`
only parses its input as HTML if the whole document is "well-formed" by its
own undocumented rules (only `&amp;`/`&lt;`/`&gt;`/`&quot;` are supported
entities, and even a single bare `"` character anywhere in body text - not
just inside a tag attribute - was enough to make it silently render the raw
markup as plain text, with no error to debug against). That fragility class
of bug is why the widget was dropped rather than patched further:

- `BuildBlocks(body)` parses the markdown-like source into a flat list of
  `{ type, text/path, ... }` block descriptors - no markup string is ever
  built or escaped
- `RenderInlineColor` turns `**bold**`/`*emphasis*` into WoW's native
  `|cAARRGGBB...|r` colour-code runs, which FontStrings support natively with
  no special-casing
- `WhatsNew:RenderBody` walks the blocks, acquiring pooled widgets via
  `AcquireTextWidget`/`AcquireImageWidget` and positioning each one with an
  explicit Y cursor, then hides any pooled widgets left over from a previous,
  longer body

## Height calculation

Total content height is the sum of each block's actual measured height
(`FontString:GetStringHeight()` for text, the block's own height for images)
plus each block's fixed gap-before value. `WhatsNew:RenderBody` returns this
total, which `Show()` uses to size the scroll child - no separate estimator
or client-compatibility fallback is needed, since this only depends on plain
`FontString`/`Texture` APIs rather than SimpleHTML-specific ones.

## How to add a new release entry

1. Create a new file in WhatsNew/Retail/ and/or WhatsNew/Forever/, for example v1_1_2.lua
2. Register ns.WhatsNewContent.versions[1.1.2] with title, body, and hasNew
3. If that version needs its own art, add it under a sibling WhatsNew/<Flavour>/v1_1_2/
   folder and reference it from the body with an image line — no toc entry needed
4. Add the new .lua file to Epithet.toc under the What’s New content section, with its flavour's gate (`scripts/validate/validate-flavours.ps1` checks it)
5. Bump addon version metadata in Epithet.toc

## Operational notes

- If hasNew is false, popup will not auto-show even on first run
- Reopen command bypasses auto-show gating and displays current version content directly
- Clearing EpithetDB.whatsNew.byVersion forces the system to treat versions as unseen again

## Troubleshooting checklist

If popup does not appear:

- Confirm current addon version has a matching entry in ns.WhatsNewContent.versions
- Confirm the version file is listed in Epithet.toc
- Confirm EpithetDB.whatsNew.byVersion[currentVersion].firstRun is true
- Confirm EpithetDB.whatsNew.byVersion[currentVersion].hasNew is true

If popup errors at runtime:

- Check for a typo in a block-parsing pattern in `BuildBlocks` (Core/WhatsNew.lua)
- Confirm `BLOCK_STYLE` has an entry for every block type `BuildBlocks` can emit

If content appears blank or a line is missing:

- Validate body text in the version file is non-empty
- Validate image texture paths resolve in-game
- Custom textures must be power-of-two sized (e.g. 512x256, not 431x259) or
  the client's texture loader can fail to load them; pad rather than stretch
  non-square art to avoid distorting it
- A `.png` reference must include the literal `.png` extension in the path -
  unlike `.tga`/`.blp`, the client won't infer it

If text renders but looks wrong (missing bold/emphasis, wrong colour):

- Check for an unbalanced (odd) count of `*` characters on the line -
  `RenderInlineColor` in Core/WhatsNew.lua pairs `**`/`*` markers left-to-right
  and lazily, so any stray `*` not meant as emphasis will pair with the next
  real one and swallow everything in between. Note the bullet marker's own
  leading `*` (and the space after it) is stripped out by `BuildBlocks` before
  this runs, so it's not a source of stray asterisks - only literal `*`
  characters inside the body text itself are.
