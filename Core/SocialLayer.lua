-- =============================================================================
-- Epithet — Social Layer
-- Target nameplate anchored below the Blizzard target frame.
-- =============================================================================
local _, ns = ...
local L = ns.L
local T = ns.Theme
local Layouts = ns.Layouts
local SafeUnitMatches = ns.SafeUnitMatches

local UnitName = UnitName
local UnitPVPName = UnitPVPName
local UnitFullName = UnitFullName
local UnitGUID = UnitGUID
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local strlower = strlower
local floor = math.floor
local ceil = math.ceil
local sbyte = string.byte
local schar = string.char

-- Locale-safe uppercasing. Lua's strupper only folds ASCII, so with the language
-- override a non-Latin locale (e.g. Russian shown on an enUS client) would be
-- left in mixed case. This folds ASCII, Latin-1 Supplement and Cyrillic (all
-- 2-byte UTF-8) by code point; 3+ byte sequences (e.g. CJK, which have no case)
-- and the German sharp-s pass through unchanged.
local function LocaleUpper(s)
    if not s or s == "" then return s end
    local out, i, n = {}, 1, #s
    while i <= n do
        local b = sbyte(s, i)
        if b < 0x80 then
            if b >= 0x61 and b <= 0x7A then b = b - 0x20 end   -- a-z
            out[#out + 1] = schar(b)
            i = i + 1
        elseif b >= 0xC0 and b < 0xE0 and i < n then
            local cp = (b % 0x20) * 0x40 + (sbyte(s, i + 1) % 0x40)
            if (cp >= 0x00E0 and cp <= 0x00FE and cp ~= 0x00F7)  -- à-þ (Latin-1)
                or (cp >= 0x0430 and cp <= 0x044F) then          -- а-я (Cyrillic)
                cp = cp - 0x20
            elseif cp == 0x0451 then                             -- ё -> Ё
                cp = 0x0401
            end
            out[#out + 1] = schar(0xC0 + floor(cp / 0x40), 0x80 + (cp % 0x40))
            i = i + 2
        else
            out[#out + 1] = schar(b)
            i = i + 1
        end
    end
    return table.concat(out)
end
ns.Strupper = ns.Strupper or LocaleUpper

local WHITE = "Interface\\Buttons\\WHITE8X8"
local NAMEPLATE_FADE_OUT_DURATION = 0.75
-- Gap between the bottom of the nameplate and the top of its hover tooltip.
local TARGET_TOOLTIP_GAP = 6

local SocialLayer = {}
ns.SocialLayer = SocialLayer

local DEFAULT_TARGET_Y = -120

local function MakeHintPill(parent)
    if Layouts and Layouts.MakeHintPill then
        return Layouts:MakeHintPill(parent)
    end

    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0.06, 0.05, 0.03, 0.92)
    frame:SetBackdropBorderColor(0.95, 0.84, 0.52, 0.95)
    frame:Hide()
    return frame
end

local function GetProfile()
    return ns.Epithet and ns.Epithet.db and ns.Epithet.db.profile and ns.Epithet.db.profile.social or nil
end

local function NormalizeName(name)
    if not name then return nil end
    local base = name:match("^([^%-]+)") or name
    return strlower(base)
end

local function StripRealm(name)
    if not name then return nil end
    return name:match("^([^%-]+)") or name
end

local function Round(num)
    if not num then return 0 end
    if num >= 0 then
        return floor(num + 0.5)
    end
    return ceil(num - 0.5)
end

local function ClampFadeDelay(seconds)
    local value = tonumber(seconds)
    if not value then return 4.0 end
    if value < 0.5 then return 0.5 end
    if value > 20.0 then return 20.0 end
    return value
end

function SocialLayer:Init()
    if self.initialized then return true end
    self.initialized = true
    self.targetFrame = self.targetFrame or nil
    self.fadeStartTime = nil
    return true
end

function SocialLayer:SetBlizzardTargetNameAlpha(alpha)
    if TargetFrameName and TargetFrameName.SetAlpha then
        TargetFrameName:SetAlpha(alpha)
    end
end

function SocialLayer:SetTargetFrameInteractionEnabled(enabled)
    local frame = self.targetFrame
    if not (frame and frame.EnableMouse) then return end

    enabled = enabled and true or false
    if frame._epithetInteractionEnabled == enabled then
        return
    end

    frame._epithetInteractionEnabled = enabled
    frame:EnableMouse(enabled)

    -- A nameplate that fades out under the cursor stops taking mouse input, so
    -- OnLeave is not guaranteed to fire. Close the hint explicitly.
    if not enabled then
        self:HideTargetTooltip()
    end
end

-- Hover hint for the LOCKED nameplate. In edit mode the pills above and below
-- already spell the drag/lock controls out, so a tooltip would only repeat them
-- (and trail the cursor while dragging) — hence the isUnlocked bail.
function SocialLayer:ShowTargetTooltip(frame)
    frame = frame or self.targetFrame
    if not (GameTooltip and frame and frame.IsShown and frame:IsShown()) then return end
    if frame.isUnlocked then return end

    -- ANCHOR_NONE plus an explicit point rather than ANCHOR_BOTTOM: this pins the
    -- tooltip squarely under the plate with a real gap, instead of butting it
    -- against the bottom edge. GameTooltip is clamped to screen, so it still
    -- flips itself back into view when the plate sits low.
    GameTooltip:SetOwner(frame, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("TOP", frame, "BOTTOM", 0, -TARGET_TOOLTIP_GAP)
    GameTooltip:AddLine(L["SOCIAL_LAYER"] or "Title Spotting", 1, 1, 1)
    GameTooltip:AddLine(L["SOCIAL_TARGET_TOOLTIP_LEFT"] or "Left-click to view this title in Epithet.", 0.7, 0.7, 0.7)
    GameTooltip:AddLine(L["SOCIAL_TARGET_TOOLTIP_RIGHT"] or "Right-click to unlock and move this nameplate.", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

-- Only ever closes a tooltip this frame owns, so it can be called from the fade
-- and hide paths without stealing someone else's.
function SocialLayer:HideTargetTooltip(frame)
    frame = frame or self.targetFrame
    if not (GameTooltip and frame and GameTooltip.IsOwned) then return end
    -- IsShown guard keeps this cheap and idempotent: the fade path below calls it
    -- every OnUpdate tick, and an owner stays set after a Hide.
    if GameTooltip:IsShown() and GameTooltip:IsOwned(frame) then
        GameTooltip:Hide()
    end
end

function SocialLayer:ResetNameplateFade()
    self.fadeStartTime = nil
    self.fadeHoldReleased = false
    self.fadeComplete = false
    self.fadeKey = nil
    if self.targetFrame and self.targetFrame.SetAlpha then
        self.targetFrame:SetAlpha(1)
    end
    if self.targetFrame and self.targetFrame.portraitModel and self.targetFrame.portraitModel.SetAlpha then
        self.targetFrame.portraitModel:SetAlpha(1)
    end
    self:SetTargetFrameInteractionEnabled(true)
    self:SetBlizzardTargetNameAlpha(1)
end

-- Begins the countdown for `key`, a stable identity for what the plate is
-- currently showing.
--
-- RefreshTargetFrame is the only caller and it runs on plenty of incidental
-- events (UNIT_PORTRAIT_UPDATE, UNIT_NAME_UPDATE, combat entry/exit, roster
-- churn), none of which mean "the player is looking at something new". Restarting
-- on those rewound the countdown, so a target generating a steady trickle of unit
-- events kept its plate on screen indefinitely. A countdown that is already
-- running — or has already finished — for this same key is therefore left alone;
-- only a genuinely new key restarts it.
function SocialLayer:StartNameplateFade(profile, key)
    if not (profile and profile.fadeNameplates) then
        self:ResetNameplateFade()
        return
    end

    if key == self.fadeKey and (self.fadeStartTime or self.fadeComplete) then
        return
    end

    self.fadeKey = key
    self.fadeComplete = false
    self.fadeHoldReleased = false
    self.fadeStartTime = (GetTime and GetTime()) or 0
    if self.targetFrame and self.targetFrame.SetAlpha then
        self.targetFrame:SetAlpha(1)
    end
    if self.targetFrame and self.targetFrame.portraitModel and self.targetFrame.portraitModel.SetAlpha then
        self.targetFrame.portraitModel:SetAlpha(1)
    end
    self:SetTargetFrameInteractionEnabled(true)
    self:SetBlizzardTargetNameAlpha(1)
end

-- True only when the plate is the frame the cursor is actually on. Falls back to
-- the geometric test on any client that lacks IsMouseMotionFocus, paired there
-- with an explicit shown/mouse-enabled check so a hidden or input-disabled plate
-- can never report itself hovered.
function SocialLayer:IsTargetFrameHovered()
    local frame = self.targetFrame
    if not frame then return false end
    if not (frame.IsShown and frame:IsShown()) then return false end

    if frame.IsMouseMotionFocus then
        return frame:IsMouseMotionFocus() and true or false
    end

    if frame._epithetInteractionEnabled == false then return false end
    return (frame.IsMouseOver and frame:IsMouseOver()) and true or false
end

-- A left-click has done the plate's job: the browser is now open with that title
-- loaded, so the plate should see itself out from here no matter where the cursor
-- sits. Releasing the hover hold is what makes that stick, since the browser opens
-- over the plate and leaves the cursor sitting on top of it.
function SocialLayer:DismissAfterTargetClick()
    if self.fadeComplete or not self.fadeStartTime then
        return
    end

    self.fadeHoldReleased = true
    self.fadeStartTime = (GetTime and GetTime()) or 0
end

function SocialLayer:UpdateNameplateFade(profile)
    if not (profile and profile.fadeNameplates and self.fadeStartTime and GetTime) then
        return
    end

    local now = GetTime()

    -- Hover holds the countdown at zero, polled rather than driven by
    -- OnEnter/OnLeave: a window opening over the plate swallows the leave event,
    -- and every event-driven attempt at this stranded the plate on screen for good
    -- when one went missing. Polling has no state to get stuck in.
    --
    -- IsMouseMotionFocus, NOT IsMouseOver: the latter is purely geometric, so it
    -- reports true whenever the cursor is inside the plate's rectangle even when
    -- the plate is occluded or has mouse input disabled. That holds the countdown
    -- at zero indefinitely — which is why nothing was fading. Motion focus is the
    -- frame the cursor is genuinely on, so it goes false the instant another frame
    -- covers the plate.
    if not self.fadeHoldReleased and self:IsTargetFrameHovered() then
        self.fadeStartTime = now
    end

    local delay = ClampFadeDelay(profile.fadeDuration)
    local elapsed = now - self.fadeStartTime

    if elapsed <= delay then
        if self.targetFrame and self.targetFrame.SetAlpha then
            self.targetFrame:SetAlpha(1)
        end
        if self.targetFrame and self.targetFrame.portraitModel and self.targetFrame.portraitModel.SetAlpha and self.targetFrame.portraitModel.IsShown and self.targetFrame.portraitModel:IsShown() then
            self.targetFrame.portraitModel:SetAlpha(1)
        end
        self:SetTargetFrameInteractionEnabled(true)
        self:SetBlizzardTargetNameAlpha(1)
        return
    end

    -- Past the delay, so the plate is now dismissing itself: drop the hover hint
    -- with it. GameTooltip is parented to UIParent rather than to the plate, so it
    -- does not inherit this alpha ramp — left alone it sits at full opacity over an
    -- increasingly invisible nameplate, and outlives it completely whenever the
    -- cursor never leaves (no OnLeave fires, e.g. right after a left-click).
    self:HideTargetTooltip()

    local progress = (elapsed - delay) / NAMEPLATE_FADE_OUT_DURATION
    if progress < 0 then progress = 0 end
    if progress > 1 then progress = 1 end

    local alpha = 1 - progress
    if alpha < 0 then alpha = 0 end

    if self.targetFrame and self.targetFrame.SetAlpha then
        self.targetFrame:SetAlpha(alpha)
    end
    if self.targetFrame and self.targetFrame.portraitModel and self.targetFrame.portraitModel.SetAlpha and self.targetFrame.portraitModel.IsShown and self.targetFrame.portraitModel:IsShown() then
        self.targetFrame.portraitModel:SetAlpha(alpha)
    end

    if alpha <= 0.01 then
        -- Keep the frame hidden to input once fully faded. fadeComplete keeps it
        -- that way: without it, the next incidental refresh would find a nil
        -- fadeStartTime and start the whole countdown again on a plate the player
        -- has already watched dismiss itself.
        self:SetTargetFrameInteractionEnabled(false)
        self.fadeStartTime = nil
        self.fadeComplete = true
    else
        self:SetTargetFrameInteractionEnabled(true)
    end

    self:SetBlizzardTargetNameAlpha(alpha)
end

function SocialLayer:GetDefaultLayoutKey()
    return Layouts and Layouts.GetDefaultLayoutKey and Layouts:GetDefaultLayoutKey() or "classic"
end

function SocialLayer:IsValidLayoutKey(key)
    return Layouts and Layouts.IsValidLayoutKey and Layouts:IsValidLayoutKey(key) or false
end

function SocialLayer:GetLayoutDefinition(profile)
    if Layouts and Layouts.GetLayoutDefinition then
        return Layouts:GetLayoutDefinition(profile)
    end
    return nil, self:GetDefaultLayoutKey()
end

function SocialLayer:GetLayoutOptions()
    return Layouts and Layouts.GetLayoutOptions and Layouts:GetLayoutOptions(L) or {}
end

function SocialLayer:GetPreviewStyle(profile)
    return Layouts and Layouts.GetPreviewStyle and Layouts:GetPreviewStyle(profile) or nil
end

function SocialLayer:ApplyLayoutToFrame(frame, profile)
    if Layouts and Layouts.ApplyLayoutToFrame then
        return Layouts:ApplyLayoutToFrame(frame, profile)
    end
end

function SocialLayer:GetRecordForUnit(unit)
    if not unit or not UnitExists or not UnitExists(unit) then return nil end
    if SafeUnitMatches and SafeUnitMatches(unit, "player") then
        local profile = GetProfile()
        if not (profile and profile.showSelfTargetNameplate == true) then
            return nil
        end
    end
    -- Titles are a player-only concept. Without this, an NPC/critter/pet whose
    -- name happens to split on whitespace (e.g. "Light-Infused Broom") gets its
    -- trailing word misread as a suffix title by ParseDisplay below.
    if not UnitIsPlayer or not UnitIsPlayer(unit) then return nil end
    local displayName = UnitPVPName and UnitPVPName(unit) or nil
    local targetFrameText = nil
    if unit == "target" and TargetFrameName and TargetFrameName.GetText then
        targetFrameText = TargetFrameName:GetText()
        if not displayName then
            displayName = targetFrameText
        end
    end
    if not displayName then return nil end

    local unitName = UnitName and UnitName(unit)
    local fullName = UnitFullName and UnitFullName(unit)
    local baseName = StripRealm(fullName or unitName or displayName)
    if not baseName or baseName == "" then return nil end

    local escapedBase = baseName:gsub("(%W)", "%%%1")
    local titleText = nil
    local titleType = nil

    local function ParseDisplay(candidate)
        if not candidate then return nil, nil end

        if candidate:find("^" .. escapedBase) then
            local suffix = candidate:sub(#baseName + 1)
            -- Handle cross-realm display names that include "-Realm" right
            -- after the character name before any title text.
            suffix = suffix:gsub("^%-[^,%s]+", "")
            if suffix:match("^,%s+") then
                return "suffix", suffix:gsub("^,%s+", "")
            end
            if suffix:match("^%s+") then
                return "suffix", suffix:gsub("^%s+", "")
            end
        end

        local prefix = candidate:match("^(.-)%s+" .. escapedBase .. "%-?[^%s]*$")
        if prefix and prefix:match("%S") then
            return "prefix", prefix:gsub("%s+$", "")
        end

        return nil, nil
    end

    local candidates = { displayName }
    if targetFrameText and targetFrameText ~= "" then
        candidates[#candidates + 1] = targetFrameText
    end

    for i = 1, #candidates do
        titleType, titleText = ParseDisplay(candidates[i])
        if titleText and titleText ~= "" then
            break
        end
    end

    if not titleText or titleText == "" then
        -- No parseable title found: suppress the social frame entirely.
        return nil
    end

    local key = NormalizeName(titleText)
    local static = ns.EpithetData and ns.EpithetData.titles and ns.EpithetData.titles[key]

    if not static then
        -- The English-keyed text match missed — most likely because the game
        -- client isn't running in English, so the nameplate's title text isn't
        -- in the DB's language and never can match this way. Fall back to
        -- titleID resolution: TitleIndex derives its fragment map from THIS
        -- SAME client's own GetTitleName catalogue, so it works regardless of
        -- client locale.
        local resolvedID = ns.TitleIndex and ns.TitleIndex:Resolve(unit)
        if resolvedID and ns.EpithetData and ns.EpithetData.titlesByID then
            static = ns.EpithetData.titlesByID[resolvedID]
        end
    end

    if static then
        return {
            unit = unit,
            name = baseName,
            titleID = static.titleID,
            -- Preserve in-game casing from the visible nameplate when possible.
            titleText = titleText or static.text,
            -- ParseDisplay read the affix off the rendered name, i.e. where the
            -- game itself put it for THIS player — more reliable than the
            -- text-keyed DB when one title text spans two IDs of differing type.
            type = titleType or static.type,
            q = static.q,
            rarity = static.rarity,
            obtainable = static.obtainable,
            obtainability_reason = static.obtainability_reason,
            kind = static.kind,
            exp = static.exp,
            cat = static.cat,
        }
    end

    return {
        unit = unit,
        name = baseName,
        titleText = titleText,
        type = titleType,
    }
end

function SocialLayer:ApplySettings()
    local profile = GetProfile()
    if not profile or not profile.enabled then
        self:ResetNameplateFade()
        self:HideTargetFrame()
        return
    end
    if not self:IsValidLayoutKey(profile.layout) then
        profile.layout = self:GetDefaultLayoutKey()
    end
    self:RefreshTargetFrame()
end

function SocialLayer:ShouldSuppress(profile)
    if not profile then return true end

    if profile.hideInCombat and InCombatLockdown and InCombatLockdown() then
        return true
    end

    if profile.hideInGroup then
        local grouped = false
        if IsInGroup and IsInGroup() then
            grouped = true
        elseif IsInRaid and IsInRaid() then
            grouped = true
        end
        if grouped then
            return true
        end
    end

    return false
end

function SocialLayer:EnsureTargetFrame()
    if self.targetFrame then return self.targetFrame end
    if not UIParent then return nil end
    local defaultMetrics = { minWidth = 248, frameHeight = 58 }
    if Layouts and Layouts.GetLayoutDefinition then
        local def = select(1, Layouts:GetLayoutDefinition({ layout = Layouts:GetDefaultLayoutKey() }))
        defaultMetrics = (def and def.metrics) or defaultMetrics
    end
    local frame = _G["EpithetSocialTargetFrame"]
    if frame then
        self.targetFrame = frame
        return frame
    end

    frame = CreateFrame("Frame", "EpithetSocialTargetFrame", UIParent, "BackdropTemplate")
    frame.__epithetTargetFrame = true
    local frameWidth = tonumber(defaultMetrics.minWidth) or tonumber(defaultMetrics.frameWidth) or 248
    local frameHeight = tonumber(defaultMetrics.frameHeight) or tonumber(defaultMetrics.minHeight) or 58
    frame:SetSize(frameWidth, frameHeight)
    frame:SetFrameStrata("HIGH")
    frame:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    if T and T.col then
        frame:SetBackdropColor(T.col.bg0.r, T.col.bg0.g, T.col.bg0.b, 0.86)
        frame:SetBackdropBorderColor(T.col.goldDeep.r, T.col.goldDeep.g, T.col.goldDeep.b, 0.9)
    else
        frame:SetBackdropColor(0.08, 0.06, 0.04, 0.86)
        frame:SetBackdropBorderColor(0.72, 0.58, 0.26, 0.9)
    end
    if TargetFrameName then
        frame:SetPoint("TOP", TargetFrameName, "BOTTOM", 0, -2)
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    end

    -- Keep interior content inset from edges for a softer, less cramped look.
    frame:SetClipsChildren(false)

    -- Left column: rarity gem spanning full widget height.
    frame.leftCol = CreateFrame("Frame", nil, frame)
    frame.leftCol:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -3)
    frame.leftCol:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4, 3)
    frame.leftCol:SetWidth(44)

    frame.gem = frame.leftCol:CreateTexture(nil, "ARTWORK")
    frame.gem:SetSize(40, 40)
    frame.gem:SetPoint("CENTER", frame.leftCol, "CENTER", 0, 0)

    -- Right column: portrait block (full inner height) with overlapping crown badge.
    frame.portraitShell = CreateFrame("Frame", nil, frame)
    frame.portraitShell:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -3)
    frame.portraitShell:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 3)
    frame.portraitShell:SetWidth(52)

    frame.portraitBG = frame.portraitShell:CreateTexture(nil, "BACKGROUND")
    frame.portraitBG:SetAllPoints(frame.portraitShell)
    frame.portraitBG:SetColorTexture(0.05, 0.05, 0.05, 1.0)

    frame.portrait = frame.portraitShell:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetPoint("TOPLEFT", frame.portraitShell, "TOPLEFT", 0, -1)
    frame.portrait:SetPoint("BOTTOMRIGHT", frame.portraitShell, "BOTTOMRIGHT", -1, 0)

    frame.portraitTopRule = frame:CreateTexture(nil, "BORDER")
    frame.portraitTopRule:SetHeight(1)
    if T and T.col and T.col.line then
        frame.portraitTopRule:SetColorTexture(T.col.line.r, T.col.line.g, T.col.line.b, 0.85)
    else
        frame.portraitTopRule:SetColorTexture(0.70, 0.58, 0.31, 0.75)
    end
    frame.portraitTopRule:Hide()

    frame.portraitBottomRule = frame:CreateTexture(nil, "BORDER")
    frame.portraitBottomRule:SetHeight(1)
    if T and T.col and T.col.line then
        frame.portraitBottomRule:SetColorTexture(T.col.line.r, T.col.line.g, T.col.line.b, 0.85)
    else
        frame.portraitBottomRule:SetColorTexture(0.70, 0.58, 0.31, 0.75)
    end
    frame.portraitBottomRule:Hide()

    -- Crown is rendered in a sibling overlay frame so it can extend beyond
    -- the pill's top border while keeping its bottom flush to portrait top.
    local crownFrame = CreateFrame("Frame", nil, frame)
    crownFrame:SetFrameStrata("HIGH")
    crownFrame:SetFrameLevel(frame:GetFrameLevel() + 8)
    crownFrame:SetSize(34, 34)
    local crownYOffset = Layouts and Layouts.GetCrownYOffset and Layouts:GetCrownYOffset() or -7
    crownFrame:SetPoint("BOTTOM", frame.portraitShell, "TOP", 0, crownYOffset)
    local crown = crownFrame:CreateTexture(nil, "OVERLAY")
    crown:SetAllPoints(crownFrame)
    local crownIcon = Layouts and Layouts.GetCrownIcon and Layouts:GetCrownIcon() or "Interface\\AddOns\\Epithet\\icons\\logo\\epithet-crown-mark-32"
    crown:SetTexture(crownIcon)
    frame.crownFrame = crownFrame
    frame.crown = crown

    -- Middle column: title (top) + rarity (bottom) rows.
    frame.centerCol = CreateFrame("Frame", nil, frame)
    frame.centerCol:SetPoint("TOPLEFT", frame.leftCol, "TOPRIGHT", 9, -6)
    frame.centerCol:SetPoint("BOTTOMRIGHT", frame.portraitShell, "BOTTOMLEFT", -9, 6)

    frame.titleRow = CreateFrame("Frame", nil, frame.centerCol)
    frame.titleRow:SetPoint("TOPLEFT", frame.centerCol, "TOPLEFT", 0, 0)
    frame.titleRow:SetPoint("TOPRIGHT", frame.centerCol, "TOPRIGHT", 0, 0)
    frame.titleRow:SetHeight(20)

    frame.rarityRow = CreateFrame("Frame", nil, frame.centerCol)
    frame.rarityRow:SetPoint("BOTTOMLEFT", frame.centerCol, "BOTTOMLEFT", 0, 0)
    frame.rarityRow:SetPoint("BOTTOMRIGHT", frame.centerCol, "BOTTOMRIGHT", 0, 0)
    frame.rarityRow:SetHeight(18)

    if T and T.Sans and T.col then
        frame.titleText = T.Sans(frame.titleRow, 11, T.col.goldBright)
        frame.rarityText = T.Sans(frame.rarityRow, 10, T.col.muted)
    else
        frame.titleText = frame.titleRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.rarityText = frame.rarityRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.rarityText:SetTextColor(0.75, 0.75, 0.75)
    end

    frame.titleText:SetAllPoints(frame.titleRow)
    frame.titleText:SetJustifyH("LEFT")
    frame.titleText:SetJustifyV("MIDDLE")
    frame.titleText:SetWordWrap(false)

    frame.rarityText:SetAllPoints(frame.rarityRow)
    frame.rarityText:SetJustifyH("LEFT")
    frame.rarityText:SetJustifyV("MIDDLE")
    frame.rarityText:SetWordWrap(false)

    frame:SetMovable(false)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    if frame.SetPropagateMouseClicks then
        frame:SetPropagateMouseClicks(false)
    end

    frame.editHintTop = MakeHintPill(frame)
    frame.editHintTop:SetPoint("BOTTOM", frame, "TOP", 0, 3)
    frame.editHintTop:SetHeight(16)

    frame.editHintBottom = MakeHintPill(frame)
    frame.editHintBottom:SetPoint("TOP", frame, "BOTTOM", 0, -3)
    frame.editHintBottom:SetHeight(16)

    if T and T.Sans and T.col then
        frame.editHintTopText = T.Sans(frame.editHintTop, 10, T.col.goldBright)
        frame.editHintBottomText = T.Sans(frame.editHintBottom, 10, T.col.goldBright)
    else
        frame.editHintTopText = frame.editHintTop:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.editHintBottomText = frame.editHintBottom:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.editHintTopText:SetTextColor(1, 0.9, 0.4)
        frame.editHintBottomText:SetTextColor(1, 0.9, 0.4)
    end

    frame.editHintTopText:SetPoint("CENTER", frame.editHintTop, "CENTER", 0, 0)
    frame.editHintBottomText:SetPoint("CENTER", frame.editHintBottom, "CENTER", 0, 0)
    frame.editHintTopText:SetText(L["SOCIAL_TARGET_EDIT_TOP"] or "EDIT MODE")
    frame.editHintBottomText:SetText(L["SOCIAL_TARGET_EDIT_BOTTOM"] or "Left-drag to move · Right-click to lock")

    frame:SetScript("OnMouseDown", function(self_, button)
        local profile = GetProfile()
        if not profile then return end

        if button == "RightButton" then
            profile.targetUnlock = not profile.targetUnlock
            SocialLayer:ApplyTargetDragState(self_, profile)
            if ns.Settings and ns.Settings.Refresh then
                ns.Settings:Refresh()
            end
            SocialLayer:RefreshTargetFrame()
            return
        end

        if button == "LeftButton" and self_.isUnlocked then
            SocialLayer:BeginTargetDrag(self_, profile)
            return
        end

        if button == "LeftButton" and not self_.isUnlocked then
            -- The hint has done its job and the browser is now the focus. Clearing
            -- it here rather than waiting for OnLeave matters because the cursor
            -- usually stays on the plate after the click, so no OnLeave follows.
            SocialLayer:HideTargetTooltip(self_)
            SocialLayer:DismissAfterTargetClick()
            SocialLayer:OpenTargetInEpithet()
        end
    end)
    frame:SetScript("OnMouseUp", function(self_, button)
        if button == "LeftButton" and self_.isDragging then
            SocialLayer:EndTargetDrag(self_)
        end
    end)
    -- Tooltip only. The fade hold is polled in UpdateNameplateFade rather than
    -- driven from here, because these two events are exactly what goes missing.
    frame:SetScript("OnEnter", function(self_)
        SocialLayer:ShowTargetTooltip(self_)
    end)
    frame:SetScript("OnLeave", function(self_)
        SocialLayer:HideTargetTooltip(self_)
    end)
    frame:SetScript("OnHide", function(self_)
        self_.isDragging = false
        SocialLayer:HideTargetTooltip(self_)
        if self_.crownFrame then
            self_.crownFrame:Hide()
        end
    end)
    frame:SetScript("OnShow", function(self_)
        if self_.crownFrame then
            local lm = self_.layoutMetrics
            if lm and lm.layoutStyle == "portrait" then
                self_.crownFrame:Hide()
            else
                self_.crownFrame:Show()
            end
        end
    end)
    frame:SetScript("OnUpdate", function(self_)
        if self_.isDragging then
            SocialLayer:UpdateTargetDrag(self_)
        end
        SocialLayer:UpdateNameplateFade(GetProfile())
    end)
    frame.isUnlocked = false
    frame.isDragging = false
    self:ApplyLayoutToFrame(frame, GetProfile())
    frame:Hide()
    self.targetFrame = frame
    return frame
end

function SocialLayer:FormatTargetPill(record)
    if not record or not record.titleText then return nil end
    local quality = tonumber(record.q)
    if not quality or quality < 1 or quality > 5 then
        quality = 1
    end
    local rarityName = (ns.QUALITY_NAMES and ns.QUALITY_NAMES[quality]) or L["RARITY_UNKNOWN"]
    return record.titleText, quality, LocaleUpper(rarityName)
end

function SocialLayer:OpenTargetInEpithet()
    if not ns.MainFrame then return end

    local record = self:GetRecordForUnit("target")
    if not record then
        ns.MainFrame:Show()
        return
    end

    if ns.MainFrame.OpenAndSelectTitle then
        ns.MainFrame:OpenAndSelectTitle(record.titleText, record.type, record.titleID)
    else
        ns.MainFrame:Show()
    end
end

function SocialLayer:SizeTargetPill(frame)
    if Layouts and Layouts.SizeTargetPill then
        return Layouts:SizeTargetPill(frame, GetProfile())
    end
end

function SocialLayer:LayoutTargetPortrait(frame)
    if Layouts and Layouts.LayoutTargetPortrait then
        return Layouts:LayoutTargetPortrait(frame)
    end
end

function SocialLayer:SetTargetPillContent(frame, titleText, quality, rarityText)
    if Layouts and Layouts.SetTargetPillContent then
        return Layouts:SetTargetPillContent(frame, titleText, quality, rarityText)
    end
end

function SocialLayer:ApplyTargetDragState(frame, profile)
    if not frame then return end
    local unlocked = profile and profile.targetUnlock
    frame.isUnlocked = unlocked and true or false
    local style = frame.layoutMetrics and frame.layoutMetrics.layoutStyle

    if style == "portrait" then
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
    elseif T and T.col then
        if frame.isUnlocked then
            frame:SetBackdropColor(T.col.parch.r, T.col.parch.g, T.col.parch.b, 0.95)
            frame:SetBackdropBorderColor(T.col.goldBright.r, T.col.goldBright.g, T.col.goldBright.b, 1)
        else
            frame:SetBackdropColor(T.col.bg0.r, T.col.bg0.g, T.col.bg0.b, 0.86)
            frame:SetBackdropBorderColor(T.col.goldDeep.r, T.col.goldDeep.g, T.col.goldDeep.b, 0.9)
        end
    else
        if frame.isUnlocked then
            frame:SetBackdropColor(0.14, 0.1, 0.06, 0.95)
            frame:SetBackdropBorderColor(1, 0.9, 0.4, 1)
        else
            frame:SetBackdropColor(0.08, 0.06, 0.04, 0.86)
            frame:SetBackdropBorderColor(0.72, 0.58, 0.26, 0.9)
        end
    end

    if frame.editHintTop and frame.editHintTopText and frame.editHintBottom and frame.editHintBottomText then
        local topW = math.max(90, math.floor((frame.editHintTopText:GetStringWidth() or 0) + 14))
        local bottomW = math.max(230, math.floor((frame.editHintBottomText:GetStringWidth() or 0) + 16))
        frame.editHintTop:SetWidth(topW)
        frame.editHintBottom:SetWidth(bottomW)

        if frame.isUnlocked then
            frame.editHintTop:Show()
            frame.editHintBottom:Show()
        else
            frame.editHintTop:Hide()
            frame.editHintBottom:Hide()
        end
    end

    -- Right-clicking to toggle edit mode happens with the cursor already on the
    -- frame, so no OnEnter/OnLeave follows to correct the hint. Swap it here
    -- instead: the pills take over on unlock, the tooltip returns on lock.
    if frame.isUnlocked then
        self:HideTargetTooltip()
    elseif self:IsTargetFrameHovered() then
        self:ShowTargetTooltip(frame)
    end
end

function SocialLayer:SetTargetPillPlaceholder(frame)
    if Layouts and Layouts.SetTargetPillPlaceholder then
        return Layouts:SetTargetPillPlaceholder(frame)
    end
end

function SocialLayer:ResetTargetFramePosition()
    local profile = GetProfile()
    if not profile then return end

    profile.targetAnchorX = 0
    profile.targetAnchorY = DEFAULT_TARGET_Y
    profile.targetUnlock = false

    self:RefreshTargetFrame()
end

function SocialLayer:AnchorTargetFrame(frame, profile)
    if not frame then return end
    profile = profile or GetProfile()
    local x = tonumber(profile.targetAnchorX) or 0
    local y = tonumber(profile.targetAnchorY)
    if y == nil then y = DEFAULT_TARGET_Y end

    frame:SetParent(UIParent)
    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "TOP", x, y)
end

function SocialLayer:RefreshTargetFrame()
    -- Central sync path: apply suppression/layout, then choose live target, settings placeholder, or hidden state.
    local profile = GetProfile()
    local frame = self:EnsureTargetFrame()
    if profile and not self:IsValidLayoutKey(profile.layout) then
        profile.layout = self:GetDefaultLayoutKey()
    end
    self:ApplyLayoutToFrame(frame, profile)
    self:ApplyTargetDragState(frame, profile)
    if not frame or not profile or not profile.enabled then
        self:HideTargetFrame()
        return
    end

    if self:ShouldSuppress(profile) then
        self:HideTargetFrame()
        return
    end
    local record = self:GetRecordForUnit("target")
    if record then
        local titleText, quality, rarityText = self:FormatTargetPill(record)
        if not titleText then
            frame:Hide()
            self:ResetNameplateFade()
            return
        end
        self:AnchorTargetFrame(frame, profile)
        self:SetTargetPillContent(frame, titleText, quality, rarityText)
        frame:Show()
        -- GUID plus title so the countdown restarts for a new target, and also if
        -- the current one swaps their title, but not for anything else.
        self:StartNameplateFade(profile, table.concat({
            (UnitGUID and UnitGUID("target")) or "",
            tostring(record.titleID or record.titleText or ""),
        }, "|"))
    else
        -- The target-unlock/reset controls live on the Title Spotting sub-tab
        -- specifically, not the main Epithet page, so the placeholder pill
        -- should only appear while that sub-tab is the one showing.
        local settingsOpen = ns.Settings and ns.Settings.titleSpottingPanel and ns.Settings.titleSpottingPanel.IsShown and ns.Settings.titleSpottingPanel:IsShown()
        if profile.targetUnlock and settingsOpen then
            self:AnchorTargetFrame(frame, profile)
            self:SetTargetPillPlaceholder(frame)
            frame:Show()
            self:ResetNameplateFade()
        else
            frame:Hide()
            self:ResetNameplateFade()
        end
    end
end

function SocialLayer:HideTargetFrame()
    self:ResetNameplateFade()
    if self.targetFrame and self.targetFrame.Hide then self.targetFrame:Hide() end
    if self.targetFrame and self.targetFrame.crownFrame then self.targetFrame.crownFrame:Hide() end
end

function SocialLayer:HandleTargetChanged()
    self:RefreshTargetFrame()
end

function SocialLayer:HandleUnitUpdate(unit)
    if unit == "target" then
        self:RefreshTargetFrame()
    end
end

function SocialLayer:BeginTargetDrag(frame, profile)
    if not frame or not profile then return end
    local x = tonumber(profile.targetAnchorX) or 0
    local y = tonumber(profile.targetAnchorY)
    if y == nil then y = DEFAULT_TARGET_Y end
    local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    local cx, cy = GetCursorPosition()
    frame.dragCursorStartX = cx / scale
    frame.dragCursorStartY = cy / scale
    frame.dragAnchorStartX = x
    frame.dragAnchorStartY = y
    frame.isDragging = true
end

function SocialLayer:UpdateTargetDrag(frame)
    local profile = GetProfile()
    if not frame or not profile then return end
    -- Cursor positions are physical pixels; convert to UIParent units for scale-safe anchor offsets.
    local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    local cx, cy = GetCursorPosition()
    cx = cx / scale
    cy = cy / scale
    local dx = cx - (frame.dragCursorStartX or cx)
    local dy = cy - (frame.dragCursorStartY or cy)
    profile.targetAnchorX = Round((frame.dragAnchorStartX or 0) + dx)
    profile.targetAnchorY = Round((frame.dragAnchorStartY or 0) + dy)
    self:AnchorTargetFrame(frame, profile)
end

function SocialLayer:EndTargetDrag(frame)
    if not frame then return end
    frame.isDragging = false
end