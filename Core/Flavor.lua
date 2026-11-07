-- =============================================================================
-- Epithet — Flavour settings
-- What differs between game flavours outside the theme (colours and textures
-- live in Core/Theme.lua). These are the Retail values; Flavors/<Flavour>/
-- Flavor.lua overrides them on its own client only (gated in Epithet.toc).
-- =============================================================================
local _, ns = ...

ns.Flavor = {
    id = "retail",
    -- The realm line under the player's name in the main window header.
    showRealm = true,
    -- The buff a nearby campfire gives the player, if the flavour has
    -- campsites; the Logbook notes sightings made with it (seenAtCampfire).
    campfireSpellID = nil,
}
