-- =============================================================================
-- Epithet — WoW Forever flavour settings
-- Loaded only on WoW Forever (Epithet.toc: [AllowLoadGameType camelot]), right
-- after Core/Flavor.lua. Change only what differs from Retail.
-- =============================================================================
local _, ns = ...

ns.Flavor.id = "forever"
-- Forever's realm name is an internal ID ("CAMWOWEU4Realm1PvE"), not a name
-- players know, so the header leaves the realm line blank.
ns.Flavor.showRealm = false
-- "Campfire Nearby": given while near a campsite (probe, 1.60.1). Resting is
-- not a reliable sign, as the probe showed resting = false at a camp.
ns.Flavor.campfireSpellID = 1283391
