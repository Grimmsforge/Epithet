-- =============================================================================
-- Epithet — Social Layouts Registry
-- Shared layout assets and dispatchers. Individual layouts register from Core/SocialLayouts/*.lua.
-- =============================================================================
local _, ns = ...

local Layouts = ns.Layouts or {}
ns.Layouts = Layouts

Layouts.order = Layouts.order or {}
Layouts.registry = Layouts.registry or {}
Layouts.defaultKey = Layouts.defaultKey or "portrait"

local WHITE = "Interface\\Buttons\\WHITE8X8"
local CROWN_ICON = "Interface\\AddOns\\Epithet\\icons\\logo\\epithet-crown-mark-32"
local CROWN_Y_OFFSET = -7
local CROWN_SIZE_MULTIPLIER = 1.2

local floor = math.floor
local ceil = math.ceil
local max = math.max
local UnitIsUnit = UnitIsUnit
local issecretvalue = _G.issecretvalue

local RARITY_GEMS = ns.Theme and ns.Theme.RarityGems32

-- UnitIsUnit can return a secret boolean under combat taint; never branch on it directly.
local function SafeUnitMatches(left, right)
    if not right then return false end
    if not left then return true end
    if left == right then return true end
    if not UnitIsUnit then return false end

    local ok, same = pcall(UnitIsUnit, left, right)
    if not ok then return false end
    if issecretvalue and issecretvalue(same) then return false end

    local compareOK, matches = pcall(function()
        return same == true
    end)
    return compareOK and matches or false
end

ns.SafeUnitMatches = SafeUnitMatches

function Layouts:RegisterLayout(key, definition)
    if type(key) ~= "string" or key == "" or type(definition) ~= "table" then
        return
    end

    if not self.registry[key] then
        self.order[#self.order + 1] = key
    end
    self.registry[key] = definition
end

function Layouts:GetDefaultLayoutKey()
    return self.defaultKey
end

function Layouts:IsValidLayoutKey(key)
    return type(key) == "string" and self.registry[key] ~= nil
end

function Layouts:GetLayoutDefinition(profile)
    local key = profile and profile.layout or nil
    if not self:IsValidLayoutKey(key) then
        key = self.defaultKey
    end
    return self.registry[key], key
end

function Layouts:GetLayoutOptions(L)
    local options = {}

    -- Keep portrait first for stable picker ordering regardless of registration order.
    if self.registry["portrait"] then
        local portraitDef = self.registry["portrait"]
        local portraitLabel = (portraitDef.labelKey and L and L[portraitDef.labelKey]) or portraitDef.label or "portrait"
        options[#options + 1] = { key = "portrait", label = portraitLabel }
    end

    for _, key in ipairs(self.order) do
        if key ~= "portrait" then
        local def = self.registry[key]
        if def then
            local label = (def.labelKey and L and L[def.labelKey]) or def.label or key
            options[#options + 1] = { key = key, label = label }
        end
        end
    end
    return options
end

function Layouts:GetPreviewStyle(profile)
    local def, key = self:GetLayoutDefinition(profile)
    if not def then
        def = self.registry[self.defaultKey]
        key = self.defaultKey
    end
    local metrics = def and def.metrics
    return {
        key = key,
        metrics = metrics,
        crownOffset = CROWN_Y_OFFSET,
        crownMultiplier = CROWN_SIZE_MULTIPLIER,
        crownIcon = CROWN_ICON,
        rarityGem = RARITY_GEMS[5],
    }
end

function Layouts:GetWhiteTexture()
    return WHITE
end

function Layouts:GetCrownIcon()
    return CROWN_ICON
end

function Layouts:GetCrownYOffset()
    return CROWN_Y_OFFSET
end

function Layouts:GetCrownSizeMultiplier()
    return CROWN_SIZE_MULTIPLIER
end

function Layouts:GetRarityGem(quality)
    local q = tonumber(quality) or 1
    if q < 1 then q = 1 end
    if q > #RARITY_GEMS then q = #RARITY_GEMS end
    return RARITY_GEMS[q]
end

-- Resize a font string in place, keeping the font file and flags it was built
-- with. Every layout has to set its own title size on each pass: the font string
-- is shared between layouts, so a size left behind by the previous one sticks.
function Layouts:SetFontSize(fontString, size)
    if not (fontString and fontString.GetFont and fontString.SetFont) then return end
    size = tonumber(size)
    if not size then return end

    local path, current, flags = fontString:GetFont()
    if not path or current == size then return end
    fontString:SetFont(path, size, flags)
end

-- Measure how a piece of text lays out, before anything visible is resized.
--
-- The visible title/rarity font strings are anchored on both sides (SetAllPoints
-- on their row), and a region anchored left AND right ignores SetWidth — so they
-- cannot answer "how tall would you be at width N?" without first being torn off
-- their anchors. This probe is anchored by a single point, so constraining its
-- width really does wrap it and GetStringHeight reports the wrapped height.
--
-- Returns naturalWidth (the unwrapped single-line width), lineHeight, and the
-- number of lines the text needs at wrapWidth (capped at maxLines when given).
-- Pass wrapWidth = 0/nil to only ask for the natural width.
function Layouts:MeasureText(frame, source, text, wrapWidth, maxLines)
    if not (frame and frame.CreateFontString and source and source.GetFont) then
        return 0, 0, 1
    end

    local path, size, flags = source:GetFont()
    if not path then return 0, 0, 1 end

    local probe = frame.__epithetTextProbe
    if not probe then
        probe = frame:CreateFontString(nil, "BACKGROUND")
        probe:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        -- Left shown so the client definitely lays it out, but fully transparent
        -- and emptied after every measurement, so it draws nothing either way.
        probe:SetAlpha(0)
        frame.__epithetTextProbe = probe
    end

    probe:SetFont(path, size or 12, flags)
    local spacing = (source.GetSpacing and source:GetSpacing()) or 0
    if probe.SetSpacing then probe:SetSpacing(spacing) end

    probe:SetWordWrap(false)
    probe:SetWidth(0)
    probe:SetText(text or "")

    local naturalWidth = probe:GetStringWidth() or 0
    local lineHeight = probe:GetStringHeight() or 0
    if lineHeight <= 0 then
        lineHeight = (size or 12) + 2
    end

    local lines = 1
    wrapWidth = tonumber(wrapWidth) or 0
    if wrapWidth > 0 and naturalWidth > wrapWidth then
        probe:SetWordWrap(true)
        probe:SetWidth(wrapWidth)

        -- wrapped = n * lineHeight + (n - 1) * spacing, solved for n.
        local wrapped = probe:GetStringHeight() or lineHeight
        lines = floor(((wrapped + spacing) / (lineHeight + spacing)) + 0.5)

        -- Words never break, so dividing the natural width by the wrap width can
        -- only ever undercount lines. Use it as a floor in case GetStringHeight
        -- reports a stale single line before the string has been laid out once.
        local estimate = ceil(naturalWidth / wrapWidth)
        if lines < estimate then lines = estimate end
        if lines < 1 then lines = 1 end
    end

    maxLines = tonumber(maxLines)
    if maxLines and maxLines >= 1 and lines > maxLines then
        lines = maxLines
    end

    -- Don't leave the measured string parked on a live region.
    probe:SetText("")

    return naturalWidth, lineHeight, lines
end

-- Height of a text block of `lines` lines, for a font measured at `lineHeight`.
function Layouts:TextBlockHeight(lines, lineHeight, spacing)
    lines = max(1, tonumber(lines) or 1)
    lineHeight = tonumber(lineHeight) or 0
    spacing = tonumber(spacing) or 0
    return ceil((lines * lineHeight) + ((lines - 1) * spacing))
end

function Layouts:MakeHintPill(parent)
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

-- =============================================================================
-- Portrait upkeep
-- =============================================================================
-- Both halves of a portrait can land before the client has what they need.
-- SetPortraitTexture leaves the texture exactly as it found it when the unit's
-- portrait is not cached yet, and SetUnit renders an empty model when the unit's
-- model has not streamed in. Neither reports that, so a call made at the wrong
-- moment is indistinguishable from a successful one and the placeholder question
-- mark (or an empty circle) stays up until something unrelated forces a redraw.
--
-- Blizzard's own frames answer this by re-running the call from the events that
-- fire once the data arrives; these two registries are what let us do the same.
-- Weak keys, so nothing here keeps a discarded frame alive.
-- Matches the layouts' own PORTRAIT_MODE_3D; frame.portraitMode is set from it.
local PORTRAIT_MODE_3D = "3d"

local portraitTextures = setmetatable({}, { __mode = "k" })
local portraitModels = setmetatable({}, { __mode = "k" })

-- Timestamped ring buffer of everything the portrait pipeline does, printed at
-- the foot of DumpPortraitState. The dump alone is a snapshot and every failure
-- mode of this pipeline is a sequence, so a broken portrait needs the history:
-- which passes ran, in what order, and what camera each one left behind.
-- Consecutive identical entries collapse into one with a count, so per-pass
-- noise (the same guard return on every refresh tick) cannot evict the sparse
-- early entries that matter.
local portraitLog = {}
local PORTRAIT_LOG_LIMIT = 120
local portraitLogLastKey, portraitLogLastIndex

local function PortraitOwnerTag(frame)
    local name = frame and frame.GetName and frame:GetName()
    if name == "EpithetSocialLayoutPreviewPlate" then return "preview" end
    if name == "EpithetSocialTargetFrame" then return "target" end
    return name or "?"
end

function Layouts:LogPortraitEvent(tag, fmt, ...)
    local ok, line = pcall(string.format, fmt, ...)
    if not ok then line = tostring(fmt) end
    local now = (GetTime and GetTime()) or 0

    local key = tostring(tag) .. "\30" .. line
    local lastEntry = portraitLogLastIndex and portraitLog[portraitLogLastIndex]
    if key == portraitLogLastKey and lastEntry then
        lastEntry.count = lastEntry.count + 1
        lastEntry.last = now
        return
    end

    portraitLog[#portraitLog + 1] = { t = now, last = now, count = 1, tag = tostring(tag), text = line }
    if #portraitLog > PORTRAIT_LOG_LIMIT then
        table.remove(portraitLog, 1)
    end
    portraitLogLastKey = key
    portraitLogLastIndex = #portraitLog
end

-- Read the model's current camera as one printable field, for the log. This is
-- a read, not an application: it is how the log records what a pass actually
-- left behind rather than what it meant to do.
local function PortraitCameraString(model)
    if not (model and model.GetCameraPosition and model.GetCameraTarget) then return "n/a" end
    local ok1, px, py, pz = pcall(model.GetCameraPosition, model)
    local ok2, tx, ty, tz = pcall(model.GetCameraTarget, model)
    if not (ok1 and ok2 and px and tx) then return "unreadable" end
    return string.format("pos=%.2f/%.2f/%.2f target=%.2f/%.2f/%.2f", px, py, pz, tx, ty, tz)
end

-- LogPortraitEvent, tagged by the frame the event belongs to, for callers
-- outside this file that hold a plate rather than a tag.
function Layouts:LogPortraitEventFor(frame, fmt, ...)
    self:LogPortraitEvent(PortraitOwnerTag(frame), fmt, ...)
end

-- Frame the model as a head-and-shoulders portrait. Applied on creation, after
-- every successful seat, from OnModelLoaded (loading a model resets its camera,
-- so a zoom set before the model arrived is gone by the time it renders), and
-- from every 3D layout pass -- see RefreshPortraitCamera for why that last one
-- is not redundant.
--
-- SetPortraitZoom is deliberately last. RefreshCamera recomputes the camera
-- from the frame's current rect, so running it afterwards can undo the portrait
-- framing; ending on the zoom makes that framing the final word either way.
--
-- Known limit: the camera SetPortraitZoom derives
-- depends on the model's render state at the moment the load completes, and a
-- seat taken before the frame has ever actually been displayed -- the settings
-- preview was once seated during the loading screen -- computes a camera aimed
-- above the character's head (z=1.5 where a good portrait gets z=0.8), and no
-- amount of re-applying the zoom afterwards moves it. Only a fresh SetUnit
-- taken while the model is genuinely on screen recomputes it. That is why the
-- settings panels are created hidden (see BuildTitleSpottingPanel) and why a
-- seat refused for visibility defers to the model's OnShow instead of running
-- anyway: the deferral is not just about wasted work, it is what guarantees
-- every camera is computed on screen.
local function ApplyPortraitCamera(model, why)
    if not model then return end
    if model.SetPosition then model:SetPosition(0, 0, 0) end
    if model.SetCamDistanceScale then model:SetCamDistanceScale(1.0) end
    if model.RefreshCamera then model:RefreshCamera() end
    if model.SetPortraitZoom then model:SetPortraitZoom(1) end
    -- Read back what the application actually produced: the camera these calls
    -- compute is the one piece of state that goes wrong invisibly.
    Layouts:LogPortraitEvent(PortraitOwnerTag(model.epithetOwner),
        "camera applied(%s): %s", tostring(why), PortraitCameraString(model))
end

-- Unit events name one unit token, and the frame showing that unit may be
-- watching a different token for it ("player" and "target" both point at you
-- when you target yourself). A nil event unit means "all of them", which is how
-- PORTRAITS_UPDATED arrives: it carries no unit at all.
local function MatchesUnit(eventUnit, frameUnit)
    return SafeUnitMatches(eventUnit, frameUnit)
end

function Layouts:ApplyPortraitTexture(texture, unit, style, shell)
    if not texture or not unit or not SetPortraitTexture then return end

    -- Recorded so the watcher below can re-run this once the portrait data
    -- actually lands. Without it, a first call made too early leaves whatever
    -- the texture already had -- which for the settings preview is the
    -- placeholder question mark it was created with.
    texture.epithetPortraitUnit = unit
    texture.epithetPortraitStyle = style
    texture.epithetPortraitShell = shell
    portraitTextures[texture] = true

    -- The pcall guards the third argument, not the call: disableMasking was
    -- added in 10.0 and older clients error on it. It cannot detect a portrait
    -- that simply was not ready, because that path raises nothing at all.
    if not pcall(SetPortraitTexture, texture, unit, true) then
        pcall(SetPortraitTexture, texture, unit)
    end

    if style == "portrait" and shell and shell.GetWidth and shell.GetHeight then
        local w = shell:GetWidth() or 0
        local h = shell:GetHeight() or 0
        if w > 0 and h > 0 then
            local aspect = w / h
            if aspect >= 1 then
                local spanY = math.max(0.20, math.min(1.0, 1 / aspect))
                local y0 = 0.5 - (spanY * 0.5)
                local y1 = 0.5 + (spanY * 0.5)
                texture:SetTexCoord(0, 1, y0, y1)
            else
                local spanX = math.max(0.20, math.min(1.0, aspect))
                local x0 = 0.5 - (spanX * 0.5)
                local x1 = 0.5 + (spanX * 0.5)
                texture:SetTexCoord(x0, x1, 0, 1)
            end
            return
        end
    end

    texture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
end

-- Drop the text-driven sizes SizePill left on a frame. Layouts derive their own
-- geometry from these, so carrying one layout's numbers into another would size
-- the plate from measurements taken with a different font and banner.
function Layouts:ClearDynamicLayout(frame)
    if not frame then return end
    frame.dynamicTitleLines = nil
    frame.dynamicTitleHeight = nil
    frame.dynamicFrameWidth = nil
    frame.dynamicFrameHeight = nil
    frame.dynamicBannerWidth = nil
    frame.dynamicBannerHeight = nil
end

function Layouts:ApplyLayoutToFrame(frame, profile)
    if not frame then return end
    local def, key = self:GetLayoutDefinition(profile)
    local m = def and def.metrics
    if not m then return end

    if frame.layoutKey ~= key then
        self:ClearDynamicLayout(frame)
    end

    frame.layoutKey = key
    frame.layoutMetrics = m
    if def.ApplyLayout then
        def.ApplyLayout(self, frame, m, profile)
    end
end

local function PortraitSeatKey(unit)
    return unit .. "\30" .. ((UnitGUID and UnitGUID(unit)) or "")
end

-- A seat is provisional until OnModelLoaded says otherwise. SetUnit reports
-- that it accepted the unit, not that anything came back, and a seat taken
-- before its frame has ever been drawn -- which is exactly what the first open
-- of a settings tab is -- is accepted and then renders nothing, with no event
-- to say so. Caching that as a finished seat is what left the first open of the
-- Title Spotting tab blank while every later open worked.
--
-- The retry stops the moment OnModelLoaded fires and is capped either way, so a
-- client that never fires it costs a fixed two seconds rather than a loop.
local SEAT_CONFIRM_DELAY = 0.1
local SEAT_CONFIRM_LIMIT = 20

local function ConfirmSeat(frame, model)
    if model.epithetLoaded or model.epithetConfirmPending then return end
    if not (C_Timer and C_Timer.After) then return end
    if (model.epithetConfirmTries or 0) >= SEAT_CONFIRM_LIMIT then return end

    model.epithetConfirmPending = true
    C_Timer.After(SEAT_CONFIRM_DELAY, function()
        model.epithetConfirmPending = nil
        if model.epithetLoaded then return end
        model.epithetConfirmTries = (model.epithetConfirmTries or 0) + 1
        Layouts:LogPortraitEvent(PortraitOwnerTag(frame),
            "seat confirm retry #%d", model.epithetConfirmTries)
        -- Forced: the provisional seat recorded by the attempt being retried
        -- would otherwise make this a no-op. A model that has gone off screen
        -- in the meantime is refused there and picked up again by its OnShow,
        -- which is what ends this loop when the panel is closed mid-flight.
        Layouts:SeatPortraitModel(frame, true)
    end)
end

-- Create the 3D portrait model for a frame, once. Everything that has to outlive
-- a reload of the model itself is wired up here rather than at the call site.
function Layouts:EnsurePortraitModel(frame)
    if not frame or not frame.portraitShell then return end
    if frame.portraitModel then return frame.portraitModel end

    -- Parented to the shell it sits on. Hosting it outside the settings panel's
    -- scroll child was tried and reverted: it did not help, and it cost the
    -- ring its crop, because a model outside that subtree draws over the ring
    -- regardless of the two frames' levels -- a square portrait, not a round one.
    local model = CreateFrame("PlayerModel", nil, frame.portraitShell)
    frame.portraitModel = model
    model.epithetOwner = frame
    model:SetFrameLevel((frame.portraitShell:GetFrameLevel() or 0) + 2)

    -- A Model unloads what it is displaying when it is hidden, and the settings
    -- panel hides on every close. Without this the model is gone by the time the
    -- panel reopens while the seat recorded below still reads as current, which
    -- is a portrait that was fine on first open and empty on the second.
    if model.SetKeepModelOnHide then
        model:SetKeepModelOnHide(true)
    end

    -- SetUnit streams the model in asynchronously and the camera returns to its
    -- default when it lands, so this is where the portrait framing has to be
    -- reapplied. Reaching here is also the one solid confirmation that a seat
    -- actually produced something, which is what ends the retry above.
    model:SetScript("OnModelLoaded", function(self_)
        self_.epithetLoaded = true
        self_.epithetConfirmTries = 0
        ApplyPortraitCamera(self_, "OnModelLoaded")
    end)

    -- Seating is refused while the model is hidden or its unit is not ready, so
    -- those passes leave a request here for whenever the model is next shown.
    model:SetScript("OnShow", function(self_)
        Layouts:LogPortraitEvent(PortraitOwnerTag(self_.epithetOwner),
            "model OnShow needsReseat=%s", tostring(self_.epithetNeedsReseat))
        if self_.epithetNeedsReseat then
            Layouts:SeatPortraitModel(self_.epithetOwner, true)
        end
    end)

    model:SetScript("OnHide", function(self_)
        Layouts:LogPortraitEvent(PortraitOwnerTag(self_.epithetOwner), "model OnHide")
    end)

    portraitModels[model] = frame
    ApplyPortraitCamera(model, "created")
    return model
end

-- Re-frame the model, independently of whether it needs re-seating.
--
-- The zoom-derived camera survives a re-application (see ApplyPortraitCamera's
-- note: a camera computed off screen stays wrong, one computed on screen stays
-- right), but how the model fills its frame is composed against the rect at
-- the moment the framing is applied, and the settings panel parents, anchors
-- and shows its canvas in a single frame (SettingsPanelMixin:DisplayLayout),
-- so an early pass can compose against a rect that is still resolving. Seating
-- cannot carry the correction -- once a seat is confirmed, every later pass
-- returns at the guard in SeatPortraitModel -- so the framing has to be
-- reachable without a seat, from every 3D layout pass.
function Layouts:RefreshPortraitCamera(frame)
    local model = frame and frame.portraitModel
    if model then
        ApplyPortraitCamera(model, "layout")
    end
end

-- Frame levels are relative to a parent, so re-parenting recomputes them for
-- the whole subtree and the offsets recorded when these frames were built stop
-- holding. The settings panel re-parents its canvas on every navigation
-- (SettingsPanelMixin:ClearCurrentCategoryCanvas sets the parent to nil, and
-- DisplayLayout parents it to the canvas again), so the model can end up level
-- with or under portraitShell -- which is to say behind portraitBG, an opaque
-- texture. Re-asserting on each layout pass costs nothing and outlives that.
function Layouts:ApplyPortraitLayering(frame)
    local shell = frame and frame.portraitShell
    local model = frame and frame.portraitModel
    if not shell then return end

    local shellLevel = shell:GetFrameLevel() or 0
    if model then
        model:SetFrameLevel(shellLevel + 2)
    end
    if frame.portraitRingFrame then
        frame.portraitRingFrame:SetFrameLevel(shellLevel + 12)
    end
end

-- Seat the 3D portrait model on its unit, but only when something actually
-- changed. SetUnit reloads the model, and a single preview refresh runs the
-- layout three times (ApplyLayoutToFrame, SizeTargetPill, then SizePill's own
-- re-apply), so an unconditional seat here reloads the model on every pass.
--
-- There is deliberately no ClearModel: it blanks the frame until the reload
-- lands, which is a visible flicker rather than a fix for one.
--
-- Anything that stops the seat from taking sets epithetNeedsReseat instead of
-- recording one, so the model's OnShow and the watcher at the foot of this file
-- can retry it. Recording a seat that never took is what left the portrait blank
-- for good: every later pass then returned at the guard below.
function Layouts:SeatPortraitModel(frame, force)
    local model = frame and frame.portraitModel
    local unit = frame and frame.portraitUnit
    if not model or not model.SetUnit or not unit then return end

    -- Nothing renders into a model that has no size or is not on screen.
    local sized = ((model:GetWidth() or 0) > 0) and ((model:GetHeight() or 0) > 0)
    if not sized or not (model.IsVisible and model:IsVisible()) then
        self:LogPortraitEvent(PortraitOwnerTag(frame),
            "seat refused: sized=%s visible=%s", tostring(sized),
            tostring(model.IsVisible and model:IsVisible()))
        model.epithetNeedsReseat = true
        return
    end

    -- The unit's model streams in with the rest of the world and can genuinely
    -- not be there yet. Blizzard gates its own model frames on exactly this and
    -- retries from UNIT_MODEL_CHANGED, which is what the watcher below does.
    --
    -- Only IsUnitModelReadyForUI: CanSetUnit looks like the matching test but
    -- returns nothing at all (no Returns block in the API docs), so reading it
    -- as a boolean refuses every seat and blanks the portrait outright.
    if IsUnitModelReadyForUI and not IsUnitModelReadyForUI(unit) then
        self:LogPortraitEvent(PortraitOwnerTag(frame), "seat refused: unit %s not ready", tostring(unit))
        model.epithetNeedsReseat = true
        return
    end

    -- Keyed on the unit's GUID as well as its token: "target" stays the same
    -- string across a target switch, so the token alone would read as unchanged
    -- and leave the previous target's model sitting there.
    --
    -- epithetLoaded is half of the test on purpose: an unconfirmed seat has to
    -- stay retryable, or the refresh passes that follow a panel being shown all
    -- return here and the portrait never recovers.
    --
    -- An unconfirmed seat with a retry already in flight defers to it, so the
    -- refresh passes and that retry cannot both reload the model and keep
    -- restarting the load they are each waiting on.
    local seat = PortraitSeatKey(unit)
    if not force and model.epithetSeat == seat
        and (model.epithetLoaded or model.epithetConfirmPending) then
        self:LogPortraitEvent(PortraitOwnerTag(frame), "seat unchanged (guard)")
        return
    end

    -- A genuinely different seat starts its retry budget over.
    if model.epithetSeat ~= seat then
        model.epithetConfirmTries = 0
    end

    -- blend = false: this is a still portrait, not an animated transition, and a
    -- blend plays in over a frame or two of nothing.
    --
    -- useNativeForm is left unset on purpose. It picks the base form over the
    -- alternate one for Worgen and Dracthyr, which is right for a dressing room
    -- and wrong here: the portrait should show the form everyone else sees.
    --
    -- SetUnit returns whether it took. pcall's own first return only says that
    -- no Lua error was raised, so treating it as the outcome -- as this did --
    -- reads a refused seat as a successful one and caches it.
    -- A new load is starting, so the previous confirmation no longer holds.
    model.epithetLoaded = nil

    local ok, seated = pcall(model.SetUnit, model, unit, false)
    if not (ok and seated ~= false) then
        ok, seated = pcall(model.SetUnit, model, "player", false)
        if ok and seated ~= false then
            seat = PortraitSeatKey("player")
        end
    end

    if not (ok and seated ~= false) then
        self:LogPortraitEvent(PortraitOwnerTag(frame), "SetUnit(%s) refused", tostring(unit))
        model.epithetSeat = nil
        model.epithetNeedsReseat = true
        return
    end

    self:LogPortraitEvent(PortraitOwnerTag(frame), "SetUnit(%s) ok force=%s", tostring(unit), tostring(force))

    if model.RefreshUnit then
        pcall(model.RefreshUnit, model)
    end

    model.epithetSeat = seat
    model.epithetNeedsReseat = nil

    -- OnModelLoaded reapplies this once the model lands. Doing it here as well
    -- covers a model that was already resident (SetKeepModelOnHide keeps it so
    -- across a panel close) and therefore never fires that script again.
    ApplyPortraitCamera(model, "seated")

    ConfirmSeat(frame, model)
end

-- Forget the current seat so the next 3D pass reloads the model. Called when the
-- model is hidden for 2D, where a mode switch is a user action and not a per-pass
-- cost worth optimising away.
function Layouts:ReleasePortraitModel(frame)
    local model = frame and frame.portraitModel
    if model then
        self:LogPortraitEvent(PortraitOwnerTag(frame), "seat released")
        model.epithetSeat = nil
    end
end

-- Re-run SetPortraitTexture for every 2D portrait on screen that is showing
-- `unit`. Hidden textures are skipped: whatever shows one next runs a layout
-- pass, and that fills it.
local function RefreshPortraitTextures(unit)
    for texture in pairs(portraitTextures) do
        local textureUnit = texture.epithetPortraitUnit
        if MatchesUnit(unit, textureUnit) and texture.IsVisible and texture:IsVisible() then
            Layouts:ApplyPortraitTexture(texture, textureUnit,
                texture.epithetPortraitStyle, texture.epithetPortraitShell)
        end
    end
end

-- Retry every 3D portrait that asked to be seated again.
local function ReseatPendingModels(unit)
    for model, frame in pairs(portraitModels) do
        if model.epithetNeedsReseat and MatchesUnit(unit, frame.portraitUnit) then
            Layouts:SeatPortraitModel(frame, true)
        end
    end
end

-- Describe one portrait plate. Everything is read defensively and reported as
-- text rather than skipped, because a field that cannot be read is itself the
-- finding -- a nil rect means the frame has never been laid out, and a missing
-- model means it was never created at all.
local function DescribePortraitPlate(emit, label, frame)
    if not frame then
        emit(label .. ": FRAME NOT FOUND")
        return
    end

    local function num(value)
        local n = tonumber(value)
        return n and string.format("%.1f", n) or "nil"
    end

    local model = frame.portraitModel
    local shell = frame.portraitShell

    emit(label .. ":")
    emit(string.format("  plate shown=%s visible=%s size=%sx%s",
        tostring(frame:IsShown()), tostring(frame:IsVisible()),
        num(frame:GetWidth()), num(frame:GetHeight())))
    emit(string.format("  unit=%s mode=%s layout=%s",
        tostring(frame.portraitUnit), tostring(frame.portraitMode),
        tostring(frame.layoutKey)))

    if shell then
        emit(string.format("  shell visible=%s size=%sx%s level=%s",
            tostring(shell:IsVisible()), num(shell:GetWidth()),
            num(shell:GetHeight()), tostring(shell:GetFrameLevel())))
    else
        emit("  shell: NONE")
    end

    if not model then
        emit("  model: NOT CREATED")
    else
        emit(string.format("  model shown=%s visible=%s size=%sx%s level=%s scale=%s alpha=%s",
            tostring(model:IsShown()), tostring(model:IsVisible()),
            num(model:GetWidth()), num(model:GetHeight()),
            tostring(model:GetFrameLevel()), num(model:GetEffectiveScale()),
            num(model:GetAlpha())))
        emit(string.format("  model rect left=%s top=%s",
            num(model:GetLeft()), num(model:GetTop())))

        -- The model's own parent, which the plate's chain below cannot show.
        local modelParent = model:GetParent()
        emit("  model parent=" .. (modelParent and (modelParent:GetName()
            or ("anon:" .. ((modelParent.GetObjectType and modelParent:GetObjectType()) or "?")))
            or "NONE"))
        emit(string.format("  seat loaded=%s needsReseat=%s tries=%s pending=%s registered=%s",
            tostring(model.epithetLoaded), tostring(model.epithetNeedsReseat),
            tostring(model.epithetConfirmTries), tostring(model.epithetConfirmPending),
            tostring(portraitModels[model] ~= nil)))
        -- The seat key embeds a \30 separator; make it printable.
        emit("  seat key=" .. (model.epithetSeat
            and (tostring(model.epithetSeat):gsub("%c", "/")) or "nil"))

        local function query(method)
            if not method then return "n/a" end
            local ok, value = pcall(method, model)
            return ok and tostring(value) or "error"
        end

        -- Multi-return getters (camera/model vectors) folded into one field.
        local function vec(method)
            if not method then return "n/a" end
            local ok, a, b, c = pcall(method, model)
            if not ok then return "error" end
            if b == nil then return num(a) end
            return string.format("%s/%s/%s", num(a), num(b), num(c))
        end

        emit(string.format("  content displayID=%s fileID=%s",
            query(model.GetDisplayInfo), query(model.GetModelFileID)))
        -- There is no getter for portrait zoom, so the camera is read instead:
        -- it is the one part of a model's state nothing else here reports, and
        -- the only place left for two identical-looking models to differ.
        emit(string.format("  camera custom=%s dist=%s pos=%s target=%s",
            query(model.HasCustomCamera), vec(model.GetCameraDistance),
            vec(model.GetCameraPosition), vec(model.GetCameraTarget)))
        emit(string.format("  transform pos=%s scale=%s facing=%s",
            vec(model.GetPosition), vec(model.GetModelScale), vec(model.GetFacing)))
    end

    if frame.portraitRingFrame then
        emit(string.format("  ring shown=%s level=%s",
            tostring(frame.portraitRingFrame:IsShown()),
            tostring(frame.portraitRingFrame:GetFrameLevel())))
    end
    if frame.portrait then
        emit("  2D texture shown=" .. tostring(frame.portrait:IsShown()))
    end

    -- Deep enough to reach Blizzard's named frames: everything Epithet builds
    -- for this panel is anonymous, so a chain that stops short of SettingsCanvas
    -- and SettingsPanel is all "anon" and says nothing. Hidden ancestors are
    -- flagged, since one of those would explain an invisible model on its own.
    local parent, chain = frame:GetParent(), {}
    while parent and #chain < 14 do
        local name = parent:GetName()
            or ("anon:" .. ((parent.GetObjectType and parent:GetObjectType()) or "?"))
        if parent.IsShown and not parent:IsShown() then
            name = name .. "[HIDDEN]"
        end
        chain[#chain + 1] = name
        parent = parent:GetParent()
    end
    emit("  parents: " .. (#chain > 0 and table.concat(chain, " < ") or "NONE (parentless)"))
end

-- Dump the live state of the portrait plates, for /epithet admin portraitdebug.
-- The ways one of these can come up empty -- never created, never seated,
-- seated but never loaded, loaded but framed wrong, loaded but drawn under an
-- opaque texture -- all look identical on screen, so this is what tells them
-- apart.
--
-- The plates are looked up by global name rather than walked out of the model
-- registry: a plate whose model was never created is absent from that registry,
-- and that absence is exactly the case worth reporting. Each plate is dumped
-- inside a pcall so one unreadable field cannot cost the whole report, and the
-- header is emitted before any of it so this can never return nothing at all.
function Layouts:DumpPortraitState(emit)
    emit = emit or print

    local registered = 0
    for _ in pairs(portraitModels) do
        registered = registered + 1
    end

    emit(string.format("Epithet portrait state | registered models: %d", registered))
    emit(string.format("saved mode=%s | IsUnitModelReadyForUI(player)=%s",
        tostring(ns.GetPortraitMode and ns.GetPortraitMode()),
        tostring(IsUnitModelReadyForUI and IsUnitModelReadyForUI("player"))))
    emit("")

    local plates = {
        { "Settings preview [EpithetSocialLayoutPreviewPlate]", _G["EpithetSocialLayoutPreviewPlate"] },
        { "Live nameplate [EpithetSocialTargetFrame]", _G["EpithetSocialTargetFrame"] },
    }

    for i = 1, #plates do
        local ok, err = pcall(DescribePortraitPlate, emit, plates[i][1], plates[i][2])
        if not ok then
            emit(plates[i][1] .. ": DUMP FAILED -- " .. tostring(err))
        end
        emit("")
    end

    -- The history behind the snapshots above. Ages are relative to this dump;
    -- a collapsed run of identical entries prints its count and the age of its
    -- most recent repeat.
    emit(string.format("Portrait event log (%d entries, oldest first):", #portraitLog))
    local now = (GetTime and GetTime()) or 0
    for i = 1, #portraitLog do
        local entry = portraitLog[i]
        local line = string.format("  -%7.2fs [%s] %s", now - entry.t, entry.tag, entry.text)
        if entry.count > 1 then
            line = line .. string.format(" (x%d, last -%.2fs)", entry.count, now - entry.last)
        end
        emit(line)
    end
end

local portraitWatcher = CreateFrame("Frame")
portraitWatcher:RegisterEvent("UNIT_PORTRAIT_UPDATE")
portraitWatcher:RegisterEvent("PORTRAITS_UPDATED")
portraitWatcher:RegisterEvent("UNIT_MODEL_CHANGED")
portraitWatcher:RegisterEvent("UI_SCALE_CHANGED")
portraitWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
portraitWatcher:SetScript("OnEvent", function(_, event, unit)
    -- How a model fills its frame depends on the resolution it was framed at, so
    -- a scale change leaves every portrait composed for the old one.
    if event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED" then
        for model in pairs(portraitModels) do
            ApplyPortraitCamera(model, "scale")
        end
        return
    end

    -- PORTRAITS_UPDATED is a blanket "portrait data changed" and carries no unit.
    if event == "PORTRAITS_UPDATED" then
        unit = nil
    end

    RefreshPortraitTextures(unit)
    ReseatPendingModels(unit)
end)

function Layouts:LayoutTargetPortrait(frame)
    if not frame then return end
    local def = frame.layoutKey and self.registry[frame.layoutKey] or nil
    if not def and frame.layoutMetrics then
        local fallbackDef = self.registry[self.defaultKey]
        def = fallbackDef
    end
    if def and def.LayoutPortrait then
        def.LayoutPortrait(self, frame, frame.layoutMetrics or def.metrics)
    end
end

function Layouts:SizeTargetPill(frame, profile)
    if not frame then return end
    self:ApplyLayoutToFrame(frame, profile)
    local def = frame.layoutKey and self.registry[frame.layoutKey] or nil
    if def and def.SizePill then
        def.SizePill(self, frame, frame.layoutMetrics or def.metrics)
    end
end

function Layouts:SetTargetPillContent(frame, titleText, quality, rarityText)
    if not frame or not frame.gem or not frame.titleText or not frame.rarityText then return end

    local q = tonumber(quality) or 1
    if q < 1 or q > 5 then q = 1 end

    frame.gem:SetTexture(self:GetRarityGem(q))
    frame.titleText:SetText(titleText or "")
    frame.rarityText:SetText(rarityText or (ns.L and ns.L["RARITY_UNKNOWN"]) or "UNKNOWN")

    local style = (frame.layoutMetrics and frame.layoutMetrics.layoutStyle) or "classic"
    frame.portraitUnit = "target"
    self:ApplyPortraitTexture(frame.portrait, "target", style, frame.portraitShell)

    local qCol = ns.QUALITY_COLOURS and ns.QUALITY_COLOURS[q]
    if qCol and qCol.text then
        frame.rarityText:SetTextColor(qCol.text.r, qCol.text.g, qCol.text.b)
    end

    -- Reflow width/height after content updates so text and metrics stay aligned.
    if ns.SocialLayer and ns.SocialLayer.SizeTargetPill then
        ns.SocialLayer:SizeTargetPill(frame)
    end
end

function Layouts:SetTargetPillPlaceholder(frame)
    if not frame or not frame.gem or not frame.titleText or not frame.rarityText then return end

    frame.gem:SetTexture(self:GetRarityGem(3))
    frame.titleText:SetText(ns.L and (ns.L["SOCIAL_TARGET_PLACEHOLDER_TITLE"] or "Example Title") or "Example Title")
    frame.rarityText:SetText(ns.L and (ns.L["SOCIAL_TARGET_PLACEHOLDER_RARITY"] or "RARE") or "RARE")

    local qCol = ns.QUALITY_COLOURS and ns.QUALITY_COLOURS[3]
    if qCol and qCol.text then
        frame.rarityText:SetTextColor(qCol.text.r, qCol.text.g, qCol.text.b)
    end

    local style = (frame.layoutMetrics and frame.layoutMetrics.layoutStyle) or "classic"
    frame.portraitUnit = "player"
    self:ApplyPortraitTexture(frame.portrait, "player", style, frame.portraitShell)

    if ns.SocialLayer and ns.SocialLayer.SizeTargetPill then
        ns.SocialLayer:SizeTargetPill(frame)
    end
end

-- Core/SocialLayouts/classic.lua and Core/SocialLayouts/portrait.lua register themselves
-- when they load (toc order places them right after this file).
