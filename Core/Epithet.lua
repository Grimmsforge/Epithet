-- =============================================================================
-- Epithet — Addon Core
-- Initialisation, slash commands, minimap button, event wiring, persistence.
-- =============================================================================
local ADDON_NAME, ns = ...

local Epithet = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
ns.Epithet = Epithet

local C_Timer = C_Timer
local T = ns.Theme
local strlower = string.lower

-- ---------------------------------------------------------------------------
-- Saved variable defaults
-- ---------------------------------------------------------------------------
local DB_DEFAULTS = {
    global = {
        locale = "auto",          -- account-wide: "auto" (follow client) | locale code override
    },
    profile = {
        filters = {
            search   = "",
            status   = "all",
            rarity   = {},
            type     = {},
            exp      = {},
            cat      = {},
            kind     = {},
            faction  = {},
            hideUnobtainable   = false,
            hideTimeSensitive  = false,
            favouritesOnly     = false,
        },
        favourites = {},          -- set keyed by lowercase title text: { ["the explorer"] = true }
        sort = "collectedFirst",  -- "collectedFirst" | "expansion" | "alphabetical" | "quality" | "category"
        obtainableOnly = false,   -- toggle: show earned % against obtainable pool only
        showWhatsNewOnStartup = true, -- toggle: auto-show the What's New popup on first login after an update
        social = {
            enabled = true,
            layout = "portrait",
            animatedPortrait = true,
            showSelfTargetNameplate = false,
            fadeNameplates = false,
            fadeDuration = 4.0,
            previewFunnyTitle = false,
            spotNotify = true,
            achievementNotify = true,
            achievementNotifyMode = "full",
            achievementAlertAnchor = "alertframe",
            spotLogScope = "spotted",
            spotLogView = "grid",
            hideInCombat = true,
            hideInGroup = false,
            targetAnchorX = 0,
            targetAnchorY = -120,
            targetUnlock = false,
        },
        framePoint = nil,         -- {point, relPoint, x, y}
        scale = 1.0,
        minimap = { hide = false },
    },
}

-- ---------------------------------------------------------------------------
-- Print helper
-- ---------------------------------------------------------------------------
local function Print(msg)
    print(T.Wrap(T.col.gold, "Epithet:") .. " " .. msg)
end
ns.Print = Print

local DEBUG_MODAL_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function ThemeRGBA(token, fr, fg, fb, fa)
    local palette = T and T.col
    local c = palette and token and palette[token]
    if c then
        return c.r or fr, c.g or fg, c.b or fb, c.a or fa
    end
    return fr, fg, fb, fa
end

local debugModal = nil

local DEBUG_MODAL_COMMANDS = {
    {
        id = "title_parse_debug",
        label = "Title parse debug",
        previewTitle = "Title Parse Debug",
        previewNote = "Inspect raw title names and parsed type classification.",
    },
    {
        id = "scan_titles",
        label = "Scan title totals",
        previewTitle = "Title Scan Result",
        previewNote = "Run a fresh title scan and show collected totals.",
    },
    {
        id = "raceicons_check",
        label = "Race icons: run check",
        previewTitle = "Race Icon Check",
        previewNote = "Run one-shot icon resolution checks against spotted entries.",
    },
    {
        id = "raceicons_clear",
        label = "Race icons: clear miss cache",
        previewTitle = "Race Icon Debug",
        previewNote = "Clear cached unresolved combinations and captured output.",
    },
    {
        id = "raceicons_show",
        label = "Race icons: show last output",
        previewTitle = "Race Icon Debug Log",
        previewNote = "Show the most recently captured unresolved race icon entries.",
    },
    {
        id = "dbcheck",
        label = "DB audit: summary",
        previewTitle = "Title DB Audit",
        previewNote = "Compare live client titles against Epithet DB and show summary counts.",
    },
    {
        id = "dbmissing",
        label = "DB audit: missing titles",
        previewTitle = "Title DB Missing Audit",
        previewNote = "List client titles missing from Epithet DB.",
    },
    {
        id = "portrait_debug",
        label = "Portraits: model state",
        previewTitle = "Portrait Model State",
        previewNote = "Seat, load, framing, layering and parent chain for every 3D portrait model.",
    },
}

local function FindDebugModalCommandByID(id)
    for i = 1, #DEBUG_MODAL_COMMANDS do
        if DEBUG_MODAL_COMMANDS[i].id == id then
            return DEBUG_MODAL_COMMANDS[i], i
        end
    end
    return nil, nil
end

local function BuildTitleParseDebugPayload()
    local lines = {}
    local shown = 0
    for id = 1, (GetNumTitles and GetNumTitles() or 0) do
        local raw = GetTitleName and GetTitleName(id)
        if raw and raw ~= "" then
            local rec = ns.TitleData.GetRecord and ns.TitleData:GetRecord(id)
            local t = rec and rec.type or "?"
            lines[#lines + 1] = string.format("[%d] '%s'  ->  %s", id, raw:gsub("|", "||"), t)
            shown = shown + 1
            if shown >= 25 then break end
        end
    end

    local payload = table.concat(lines, "\n")
    if payload == "" then
        payload = "(No raw titles found. Run /epithet scan first.)"
    end

    return payload, shown, lines
end

local function BuildTitleDBAuditPayload()
    if ns.TitleData and ns.TitleData.Scan then
        ns.TitleData:Scan(true)
    end

    local records = (ns.TitleData and ns.TitleData.records) or {}
    local staticTitles = (ns.EpithetData and ns.EpithetData.titles) or {}

    local staticByID = {}
    local staticCount = 0
    for _, data in pairs(staticTitles) do
        staticCount = staticCount + 1
        local id = data and tonumber(data.titleID)
        if id then
            staticByID[id] = true
        end
    end

    local liveCount = #records
    local missingByIDCount = 0
    local missingByTextCount = 0
    local missingLines = {}
    local seenMissingText = {}

    for i = 1, liveCount do
        local record = records[i]
        local titleID = record and tonumber(record.titleID)
        local text = record and record.text or ""
        local lowerText = text and strlower(text) or ""
        local inStaticByID = titleID and staticByID[titleID] == true or false
        local inStaticByText = lowerText ~= "" and staticTitles[lowerText] ~= nil or false

        if not inStaticByID then
            missingByIDCount = missingByIDCount + 1
            missingLines[#missingLines + 1] = string.format("[%d] %s", tonumber(titleID) or 0, text ~= "" and text or "<unnamed>")
        end

        if not inStaticByText and lowerText ~= "" and not seenMissingText[lowerText] then
            seenMissingText[lowerText] = true
            missingByTextCount = missingByTextCount + 1
        end
    end

    table.sort(missingLines)

    local summaryLines = {
        string.format("Client titles: %d", liveCount),
        string.format("Epithet DB entries: %d", staticCount),
        string.format("Missing by titleID: %d", missingByIDCount),
        string.format("Missing by title text: %d", missingByTextCount),
    }

    local summary = table.concat(summaryLines, " | ")
    local payload = table.concat(summaryLines, "\n")
    if #missingLines > 0 then
        payload = payload .. "\n\nMissing live titles (by ID):\n" .. table.concat(missingLines, "\n")
    end

    return {
        summary = summary,
        payload = payload,
        missingLines = missingLines,
        liveCount = liveCount,
        staticCount = staticCount,
        missingByIDCount = missingByIDCount,
        missingByTextCount = missingByTextCount,
    }
end

ns.BuildTitleDBAuditPayload = BuildTitleDBAuditPayload

local function RunDebugModalCommand(commandID)
    -- Execute one debug action and normalize its result for modal rendering.
    -- Returns: true, { title, note, payload } on success; false, "error" on failure.
    local command = commandID or "title_parse_debug"

    if command == "title_parse_debug" then
        local payload = BuildTitleParseDebugPayload()
        return true, {
            title = "Title Parse Debug",
            note = "Copy the raw title lines below for debugging.",
            payload = payload,
        }
    end

    if command == "scan_titles" then
        ns.TitleData.dirty = true
        ns.TitleData:Scan()
        return true, {
            title = "Title Scan Result",
            note = "Latest title count scan summary.",
            payload = string.format(ns.L["SLASH_SCAN_COMPLETE"], ns.TitleData.earnedCount or 0, ns.TitleData.totalCount or 0),
        }
    end

    if command == "raceicons_check" then
        if type(ns.RunRaceIconDebugCheck) ~= "function" then
            return false, "Race icon check helper is unavailable in this build."
        end

        local ok, payload = ns.RunRaceIconDebugCheck()
        if not ok then
            return false, payload or "Race icon check failed"
        end

        return true, {
            title = "Race Icon Check",
            note = "One-shot race icon mapping check over spotted entries.",
            payload = tostring(payload or ""),
        }
    end

    if command == "raceicons_show" then
        local payload = (ns.GetRaceIconDebugPayload and ns.GetRaceIconDebugPayload()) or "(No unresolved race icon entries captured yet.)"
        return true, {
            title = "Race Icon Debug Log",
            note = "Most recently captured unresolved race icon entries.",
            payload = payload,
        }
    end

    if command == "dbcheck" then
        local report = BuildTitleDBAuditPayload()
        return true, {
            title = "Title DB Audit",
            note = "Summary comparison between live client titles and Epithet DB.",
            payload = report.payload,
        }
    end

    if command == "dbmissing" then
        local report = BuildTitleDBAuditPayload()
        return true, {
            title = "Title DB Missing Audit",
            note = "Live client titles that are not present in Epithet DB.",
            payload = report.payload,
        }
    end

    if command == "portrait_debug" then
        local layouts = ns.Layouts
        if not layouts or type(layouts.DumpPortraitState) ~= "function" then
            return false, "Portrait state dump is unavailable in this build."
        end

        local lines = {}
        layouts:DumpPortraitState(function(line)
            lines[#lines + 1] = line
        end)

        return true, {
            title = "Portrait Model State",
            note = "Run this while a blank portrait is on screen.",
            payload = table.concat(lines, "\n"),
        }
    end

    local admin = ns.AdminCommands
    if not admin or type(admin.HandleRaceIconDebug) ~= "function" then
        return false, "Admin race icon commands are unavailable in this build."
    end

    local modeMap = {
        raceicons_clear = "clear",
    }

    local mode = modeMap[command]
    if mode then
        local message = admin:HandleRaceIconDebug(mode)
        return true, {
            title = "Race Icon Debug",
            note = "Result from race icon debug command.",
            payload = tostring(message or "(No response)"),
        }
    end

    return false, "Unknown debug modal command: " .. tostring(command)
end

ns.RunDebugModalCommand = RunDebugModalCommand

local function SkinDebugModalButton(button, isPrimary)
    local bgR, bgG, bgB, bgA = ThemeRGBA("panel", 0.11, 0.08, 0.04, 1.0)
    local hoverR, hoverG, hoverB, hoverA = ThemeRGBA("parch", 0.16, 0.12, 0.06, 1.0)
    local downR, downG, downB, downA = ThemeRGBA("panel2", 0.08, 0.06, 0.03, 1.0)
    local edgeR, edgeG, edgeB = ThemeRGBA("goldDeep", 0.49, 0.37, 0.15, 1.0)
    local edgeSoftR, edgeSoftG, edgeSoftB = ThemeRGBA("line", 0.44, 0.34, 0.14, 1.0)
    local textR, textG, textB, textA = ThemeRGBA("text", 0.92, 0.88, 0.78, 1.0)

    if isPrimary then
        bgR, bgG, bgB, bgA = ThemeRGBA("goldDim", 0.62, 0.45, 0.18, 1.0)
        hoverR, hoverG, hoverB, hoverA = ThemeRGBA("goldBright", 0.91, 0.78, 0.45, 1.0)
        downR, downG, downB, downA = ThemeRGBA("goldDeep", 0.49, 0.37, 0.15, 1.0)
        edgeR, edgeG, edgeB = ThemeRGBA("goldBright", 0.91, 0.78, 0.45, 1.0)
        edgeSoftR, edgeSoftG, edgeSoftB = ThemeRGBA("gold", 0.78, 0.66, 0.34, 1.0)
        textR, textG, textB, textA = ThemeRGBA("ink", 0.08, 0.06, 0.03, 1.0)
    end

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(bgR, bgG, bgB, bgA)
    button.bg = bg

    local top = button:CreateTexture(nil, "BORDER")
    top:SetHeight(1)
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetColorTexture(edgeR, edgeG, edgeB, 1.0)

    local bottom = button:CreateTexture(nil, "BORDER")
    bottom:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")
    bottom:SetColorTexture(edgeR, edgeG, edgeB, 1.0)

    local left = button:CreateTexture(nil, "BORDER")
    left:SetWidth(1)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetColorTexture(edgeR, edgeG, edgeB, 1.0)

    local right = button:CreateTexture(nil, "BORDER")
    right:SetWidth(1)
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
    right:SetColorTexture(edgeR, edgeG, edgeB, 1.0)

    button:SetNormalFontObject("GameFontNormalSmall")
    button:SetHighlightFontObject("GameFontHighlightSmall")

    local label = button:GetFontString()
    if label then
        label:SetTextColor(textR, textG, textB, textA)
        if isPrimary then
            local fontPath, fontSize, fontFlags = label:GetFont()
            if fontPath then
                label:SetFont(fontPath, (fontSize or 12) + 1, fontFlags)
            end
            label:SetShadowColor(0, 0, 0, 0)
            label:SetShadowOffset(0, 0)
        end
    end

    button:SetScript("OnEnter", function(self_)
        if self_.bg then
            self_.bg:SetColorTexture(hoverR, hoverG, hoverB, hoverA)
        end
    end)

    button:SetScript("OnLeave", function(self_)
        if self_.bg then
            self_.bg:SetColorTexture(bgR, bgG, bgB, bgA)
        end
    end)

    button:HookScript("OnMouseDown", function(self_)
        if self_.bg then
            self_.bg:SetColorTexture(downR, downG, downB, downA)
        end
    end)

    button:HookScript("OnMouseUp", function(self_)
        if self_.bg then
            self_.bg:SetColorTexture(hoverR, hoverG, hoverB, hoverA)
        end
    end)
end

local function ApplyCommandPreview(modal, commandID)
    if not modal then
        return
    end

    local command = FindDebugModalCommandByID(commandID)
    if not command then
        modal.heading:SetText("Debug Output")
        modal.note:SetText("Select a debug command.")
        return
    end

    modal.heading:SetText(command.previewTitle or "Debug Output")
    modal.note:SetText(command.previewNote or "Select and run a debug command.")
end

local function EnsureDebugModal()
    if debugModal then
        return debugModal
    end

    local modal = CreateFrame("Frame", "EpithetDebugModal", UIParent, "BackdropTemplate")
    modal:SetSize(900, 520)
    modal:SetPoint("CENTER")
    modal:SetFrameStrata("DIALOG")
    modal:SetFrameLevel(200)
    modal:EnableMouse(true)
    modal:SetMovable(true)
    modal:RegisterForDrag("LeftButton")
    modal:SetScript("OnDragStart", modal.StartMoving)
    modal:SetScript("OnDragStop", modal.StopMovingOrSizing)
    modal:SetBackdrop(DEBUG_MODAL_BACKDROP)
    modal:SetBackdropColor(ThemeRGBA("panel", 0.07, 0.05, 0.03, 0.97))
    modal:SetBackdropBorderColor(ThemeRGBA("goldDeep", 0.55, 0.45, 0.26, 0.95))
    modal:Hide()

    local titleBar = modal:CreateTexture(nil, "BACKGROUND")
    titleBar:SetPoint("TOPLEFT", modal, "TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -1, -1)
    titleBar:SetHeight(32)
    titleBar:SetColorTexture(ThemeRGBA("bg0", 0.14, 0.10, 0.06, 0.92))

    local titleSep = modal:CreateTexture(nil, "BORDER")
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT", modal, "TOPLEFT", 1, -33)
    titleSep:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -1, -33)
    titleSep:SetColorTexture(T.RGBA(T.col.line, 0.30))

    local topInset = modal:CreateTexture(nil, "BORDER")
    topInset:SetHeight(1)
    topInset:SetPoint("TOPLEFT", modal, "TOPLEFT", 2, -2)
    topInset:SetPoint("TOPRIGHT", modal, "TOPRIGHT", -2, -2)
    topInset:SetColorTexture(T.RGBA(T.col.line, 0.18))

    local heading = modal:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    heading:SetPoint("RIGHT", titleBar, "RIGHT", -12, 0)
    heading:SetJustifyH("LEFT")
    heading:SetJustifyV("MIDDLE")
    heading:SetTextColor(ThemeRGBA("gold", 0.91, 0.78, 0.45, 1.0))
    modal.heading = heading

    local note = modal:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -16)
    note:SetPoint("TOPRIGHT", -12, -16)
    note:SetJustifyH("LEFT")
    note:SetTextColor(ThemeRGBA("muted", 0.62, 0.55, 0.42, 1.0))
    modal.note = note

    local hasDropDownAPI = type(UIDropDownMenu_SetWidth) == "function"
        and type(UIDropDownMenu_Initialize) == "function"
        and type(UIDropDownMenu_CreateInfo) == "function"
        and type(UIDropDownMenu_AddButton) == "function"
        and type(UIDropDownMenu_SetText) == "function"

    local commandLabel = nil
    local commandDropDown = nil
    local runCommand = nil

    if hasDropDownAPI then
        commandLabel = modal:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        commandLabel:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -10)
        commandLabel:SetText("DEBUG COMMAND")
        commandLabel:SetTextColor(ThemeRGBA("gold", 0.91, 0.78, 0.45, 1.0))

        commandDropDown = CreateFrame("Frame", "EpithetDebugModalCommandDropDown", modal, "UIDropDownMenuTemplate")
        commandDropDown:SetPoint("TOPLEFT", commandLabel, "BOTTOMLEFT", -16, -2)
        UIDropDownMenu_SetWidth(commandDropDown, 380)

        modal.selectedCommandID = DEBUG_MODAL_COMMANDS[1].id
        UIDropDownMenu_Initialize(commandDropDown, function(_, level)
            if level ~= 1 then
                return
            end

            for i = 1, #DEBUG_MODAL_COMMANDS do
                local command = DEBUG_MODAL_COMMANDS[i]
                local info = UIDropDownMenu_CreateInfo()
                info.text = command.label
                info.value = command.id
                info.checked = (modal.selectedCommandID == command.id)
                info.func = function(self_)
                    modal.selectedCommandID = self_.value
                    UIDropDownMenu_SetText(commandDropDown, self_:GetText())
                    ApplyCommandPreview(modal, self_.value)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetText(commandDropDown, DEBUG_MODAL_COMMANDS[1].label)
        ApplyCommandPreview(modal, DEBUG_MODAL_COMMANDS[1].id)

        runCommand = CreateFrame("Button", nil, modal)
        runCommand:SetSize(144, 30)
        runCommand:SetPoint("LEFT", commandDropDown, "RIGHT", 12, 0)
        runCommand:SetPoint("CENTER", commandDropDown, "CENTER", 0, 0)
        runCommand:SetText("Run Selected")
        SkinDebugModalButton(runCommand, true)
        runCommand:SetScript("OnClick", function()
            local ok, result = RunDebugModalCommand(modal.selectedCommandID)
            if not ok then
                modal.heading:SetText("Debug Command Error")
                modal.note:SetText("The selected command failed.")
                modal.edit:SetText(tostring(result or "Unknown error"))
                modal.edit:SetFocus()
                modal.edit:HighlightText(0, -1)
                return
            end

            modal.heading:SetText(result.title or "Debug Output")
            modal.note:SetText(result.note or "Copy/paste the payload below.")
            modal.edit:SetText(result.payload or "")
            modal.edit:SetFocus()
            modal.edit:HighlightText(0, -1)
        end)
    else
        modal.selectedCommandID = DEBUG_MODAL_COMMANDS[1].id
        ApplyCommandPreview(modal, DEBUG_MODAL_COMMANDS[1].id)
    end

    local editorTopOffset = hasDropDownAPI and -118 or -56

    local editorWrap = CreateFrame("Frame", nil, modal, "BackdropTemplate")
    editorWrap:SetPoint("TOPLEFT", modal, "TOPLEFT", 12, editorTopOffset)
    editorWrap:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -12, 48)
    editorWrap:SetBackdrop(DEBUG_MODAL_BACKDROP)
    editorWrap:SetBackdropColor(ThemeRGBA("inset", 0.11, 0.08, 0.04, 1.0))
    editorWrap:SetBackdropBorderColor(ThemeRGBA("goldDeep", 0.40, 0.34, 0.22, 0.95))

    local scroll = CreateFrame("ScrollFrame", nil, editorWrap, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", editorWrap, "TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", editorWrap, "BOTTOMRIGHT", -26, 4)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetAutoFocus(false)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    edit:SetWidth(520)
    edit:SetHeight(180)
    edit:SetScript("OnEscapePressed", function() modal:Hide() end)
    edit:SetScript("OnTextChanged", function(self_)
        local w = math.max(520, (self_:GetStringWidth() or 0) + 24)
        self_:SetWidth(w)
    end)
    scroll:SetScrollChild(edit)

    local function ResizeEditor()
        local wrapW = editorWrap:GetWidth() or 0
        local wrapH = editorWrap:GetHeight() or 0
        local minW = math.max(520, wrapW - 40)
        local minH = math.max(140, wrapH - 10)
        if (edit:GetWidth() or 0) < minW then
            edit:SetWidth(minW)
        end
        edit:SetHeight(minH)
    end

    editorWrap:SetScript("OnMouseDown", function()
        edit:SetFocus()
    end)
    editorWrap:SetScript("OnSizeChanged", ResizeEditor)
    ResizeEditor()

    local close = CreateFrame("Button", nil, modal)
    close:SetSize(120, 24)
    close:SetPoint("BOTTOMRIGHT", modal, "BOTTOMRIGHT", -12, 12)
    close:SetText("Close")
    SkinDebugModalButton(close)
    close:SetScript("OnClick", function() modal:Hide() end)

    local selectAll = CreateFrame("Button", nil, modal)
    selectAll:SetSize(120, 24)
    selectAll:SetPoint("RIGHT", close, "LEFT", -8, 0)
    selectAll:SetText("Select All")
    SkinDebugModalButton(selectAll)
    selectAll:SetScript("OnClick", function()
        edit:HighlightText(0, -1)
        edit:SetFocus()
    end)

    modal.edit = edit
    modal.commandDropDown = commandDropDown
    modal.runCommandButton = runCommand
    debugModal = modal
    return modal
end

function ns.OpenDebugTextModal(title, payload, note)
    local modal = EnsureDebugModal()
    if not modal then
        return false, "Unable to create debug modal."
    end

    modal.heading:SetText(title or "Debug Output")
    modal.note:SetText(note or "Copy/paste the payload below.")
    modal.edit:SetText(payload or "")
    modal:Show()
    modal.edit:SetFocus()
    modal.edit:HighlightText(0, -1)

    return true
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------
function Epithet:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("EpithetDB", DB_DEFAULTS, true)

    -- Every file has loaded, including any flavour theme overrides; from here
    -- on frames get built, so a later Theme.Apply would only half-apply.
    T.Seal()

    -- Apply the saved language preference before any UI is built. Modules capture
    -- `local L = ns.L` at load, but the proxy resolves lazily, so switching the
    -- active overlay here takes effect for everything drawn from now on.
    if ns.ApplyLocale and ns.ResolveLocaleCode then
        ns.ApplyLocale(ns.ResolveLocaleCode(self.db.global.locale))
    end

    -- Sanitise saved filters: search is ephemeral (don't persist across sessions)
    -- and ensure new facet tables exist for profiles saved before they were added.
    local f = self.db.profile.filters
    f.search = ""
    f.cat = f.cat or {}
    f.kind = f.kind or {}
    f.faction = f.faction or {}
    self.db.profile.showWhatsNewOnStartup = (self.db.profile.showWhatsNewOnStartup ~= false)
    local s = self.db.profile.social or {}
    s.enabled = (s.enabled ~= false)
    s.targetAnchorPoint = nil -- legacy field removed; target is always anchored below target frame.
    if type(s.layout) ~= "string" then s.layout = "portrait" end
    if ns.SocialLayer and ns.SocialLayer.IsValidLayoutKey and not ns.SocialLayer:IsValidLayoutKey(s.layout) then
        if ns.SocialLayer.GetDefaultLayoutKey then
            s.layout = ns.SocialLayer:GetDefaultLayoutKey()
        else
            s.layout = "portrait"
        end
    end
    if type(s.targetAnchorX) ~= "number" then s.targetAnchorX = 0 end
    if type(s.targetAnchorY) ~= "number" then s.targetAnchorY = -120 end
    s.animatedPortrait = (s.animatedPortrait ~= false)
    s.fadeNameplates = (s.fadeNameplates == true)
    local fadeSeconds = tonumber(s.fadeDuration)
    if not fadeSeconds then fadeSeconds = 5.0 end
    if fadeSeconds < 0.5 then fadeSeconds = 0.5 end
    if fadeSeconds > 20.0 then fadeSeconds = 20.0 end
    s.fadeDuration = fadeSeconds
    s.previewFunnyTitle = (s.previewFunnyTitle == true)
    s.spotNotify = (s.spotNotify ~= false)
    local mode = s.achievementNotifyMode
    if mode ~= "full" and mode ~= "silent" and mode ~= "off" then
        if s.achievementNotify == false then
            mode = "off"
        else
            mode = "full"
        end
    end
    s.achievementNotifyMode = mode
    s.achievementNotify = (mode ~= "off")
    if s.achievementAlertAnchor ~= "uiparent" and s.achievementAlertAnchor ~= "alertframe" then
        s.achievementAlertAnchor = "alertframe"
    end
    if s.spotLogScope ~= "spotted" and s.spotLogScope ~= "remaining" then
        s.spotLogScope = "spotted"
    end
    if s.spotLogView ~= "list" and s.spotLogView ~= "grid" then
        s.spotLogView = "grid"
    end
    if s.hideInCombat == nil then
        -- Preserve legacy behaviour for existing profiles created before this
        -- setting was introduced; only new profiles should default to true.
        s.hideInCombat = false
    else
        s.hideInCombat = (s.hideInCombat == true)
    end
    s.hideInGroup = (s.hideInGroup == true)
    -- Never persist drag-unlocked mode across sessions; relock on load to avoid accidental moves.
    s.targetUnlock = false
    self.db.profile.social = s

    -- Slash commands
    SLASH_EPITHET1 = "/epithet"
    SLASH_EPITHET2 = "/titles"
    SlashCmdList["EPITHET"] = function(input)
        self:HandleSlash(input)
    end

    -- Minimap button
    self:SetupMinimapButton()

    if ns.SpottingLog and ns.SpottingLog.Init then
        ns.SpottingLog:Init()
    end
    if ns.SpottingAchievements and ns.SpottingAchievements.Init then
        ns.SpottingAchievements:Init()
    end
    if ns.WhatsNew and ns.WhatsNew.Init then
        ns.WhatsNew:Init()
    end

    if ns.Settings and ns.Settings.Init then
        ns.Settings:Init()
    end

    if ns.SocialLayer and ns.SocialLayer:Init() then
        ns.SocialLayer:ApplySettings()
    end
end

function Epithet:OnEnable()
    -- Register events via a lightweight frame
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...)
        if self[event] then
            self[event](self, ...)
        end
    end)
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("ACHIEVEMENT_EARNED")
    -- Only "player"/"target" are ever handled below; let the client filter
    -- delivery instead of receiving every unit's update and checking in Lua.
    self.eventFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", "player", "target")
    self.eventFrame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player", "target")
    self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

    if ns.SocialLayer and ns.SocialLayer:Init() then
        ns.SocialLayer:ApplySettings()
    end

    if ns.SpottingCapture and ns.SpottingCapture.Init then
        ns.SpottingCapture:Init()
    end
end

-- ---------------------------------------------------------------------------
-- Event handlers
-- ---------------------------------------------------------------------------
function Epithet:PLAYER_ENTERING_WORLD()
    ns.TitleData.dirty = true
    ns.TitleData:Scan()
    if ns.TitleIndex and ns.TitleIndex.Build then
        ns.TitleIndex:Build()
    end
    if ns.MainFrame and ns.MainFrame:IsShown() then
        ns.MainFrame:FullRefresh()
    end

    if ns.WhatsNew and ns.WhatsNew.ShowForCurrentVersionIfNeeded then
        ns.WhatsNew:ShowForCurrentVersionIfNeeded()
    end
end

function Epithet:ACHIEVEMENT_EARNED()
    -- A new title may have unlocked
    ns.TitleData.dirty = true
    ns.TitleData:Scan()
    if ns.TitleIndex and ns.TitleIndex.Reset then
        -- Invalidate the name-fragment index so a newly earned title becomes
        -- resolvable by SpottingCapture/SocialLayer without a relog.
        ns.TitleIndex:Reset()
    end
    if ns.MainFrame and ns.MainFrame:IsShown() then
        ns.MainFrame:FullRefresh()
    end
end

function Epithet:UNIT_NAME_UPDATE(unit)
    if unit == "player" then
        ns.TitleData:RefreshActiveState()
        if ns.MainFrame and ns.MainFrame:IsShown() then
            ns.MainFrame:FullRefresh()
        end
    end
    if ns.SocialLayer then
        ns.SocialLayer:HandleUnitUpdate(unit)
    end
end

function Epithet:UNIT_PORTRAIT_UPDATE(unit)
    if not ns.SocialLayer then return end
    if unit == "target" or unit == "player" then
        ns.SocialLayer:RefreshTargetFrame()
    end
end

function Epithet:PLAYER_TARGET_CHANGED()
    if ns.SocialLayer then
        ns.SocialLayer:HandleTargetChanged()
    end
end

function Epithet:PLAYER_REGEN_DISABLED()
    if ns.SocialLayer then
        ns.SocialLayer:RefreshTargetFrame()
    end
end

function Epithet:PLAYER_REGEN_ENABLED()
    if ns.SocialLayer then
        ns.SocialLayer:RefreshTargetFrame()
    end
end

-- GROUP_ROSTER_UPDATE can fire in rapid bursts in large raids; debounce so a
-- burst of N events results in one refresh instead of N.
local GROUP_ROSTER_DEBOUNCE = 0.2

function Epithet:GROUP_ROSTER_UPDATE()
    if not ns.SocialLayer then return end
    if self.groupRosterRefreshPending then return end
    self.groupRosterRefreshPending = true
    C_Timer.After(GROUP_ROSTER_DEBOUNCE, function()
        self.groupRosterRefreshPending = false
        if ns.SocialLayer then
            ns.SocialLayer:RefreshTargetFrame()
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Slash command handler
-- ---------------------------------------------------------------------------
function Epithet:HandleSlash(input)
    local cmd = input and input:trim():lower() or ""
    local adminArgs = cmd:match("^admin%s*(.-)%s*$")
    if adminArgs then
        local admin = ns.AdminCommands
        if admin and type(admin.HandleSlash) == "function" then
            local ok, handled, message = pcall(admin.HandleSlash, admin, adminArgs, Print)
            if not ok then
                Print("Admin command failed: " .. tostring(handled))
                return
            end
            if handled then
                if message and message ~= "" then
                    Print(message)
                end
                return
            end
            Print("Unknown admin command. Try /epithet admin achievement")
            return
        end

        Print("Admin commands are not available in this build.")
        return
    end

    if cmd == "minimap" then
        local hide = not self.db.profile.minimap.hide
        self.db.profile.minimap.hide = hide
        local LDBIcon = LibStub("LibDBIcon-1.0", true)
        if LDBIcon then
            if hide then
                LDBIcon:Hide("Epithet")
                Print(ns.L["MINIMAP_HIDDEN"])
            else
                LDBIcon:Show("Epithet")
                Print(ns.L["MINIMAP_SHOWN"])
            end
        end
        return
    elseif cmd == "scan" then
        ns.TitleData.dirty = true
        ns.TitleData:Scan()
        Print(string.format(ns.L["SLASH_SCAN_COMPLETE"], ns.TitleData.earnedCount or 0, ns.TitleData.totalCount or 0))
        return
    elseif cmd == "debug" then
        -- Dump the raw GetTitleName format + classified type for the first
        -- known titles, to verify prefix/suffix detection in this client.
        local payload, shown, lines = BuildTitleParseDebugPayload()

        local openedModal = false
        if ns.OpenDebugTextModal then
            openedModal = ns.OpenDebugTextModal("Title Parse Debug", payload, "Copy the raw title lines below for debugging.") == true
        end

        if not openedModal then
            for i = 1, #lines do
                Print(lines[i])
            end
            Print("Showed " .. shown .. " raw titles. (Run /epithet scan first if empty.)")
        else
            Print("Opened debug modal with " .. shown .. " raw title lines.")
        end
        return
    elseif cmd == "whatsnew" then
        if ns.WhatsNew and ns.WhatsNew.Show then
            -- The current version's notes, or the newest there are: a release
            -- does not have to have its own.
            ns.WhatsNew:Show(ns.WhatsNew:GetLatestContentVersion())
        end
        return
    end

    -- Default: toggle window
    if ns.MainFrame then
        ns.MainFrame:Toggle()
    end
end

-- ---------------------------------------------------------------------------
-- Minimap button (LibDataBroker + LibDBIcon)
-- ---------------------------------------------------------------------------
function Epithet:SetupMinimapButton()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDB or not LDBIcon then return end

    local L = ns.L
    local launcher = LDB:NewDataObject("Epithet", {
        type = "launcher",
        text = "Epithet",
        icon = T.tex.logoSealMinimap,
        OnClick = function(_, button)
            if button == "LeftButton" then
                if ns.MainFrame then
                    ns.MainFrame:Toggle()
                end
            elseif button == "RightButton" then
                self.db.profile.minimap.hide = true
                LDBIcon:Hide("Epithet")
                Print(L["MINIMAP_HIDDEN"])
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(L["MINIMAP_TOOLTIP_TITLE"], 1, 1, 1)
            tooltip:AddLine(L["MINIMAP_TOOLTIP_LEFT"], 0.7, 0.7, 0.7)
            tooltip:AddLine(L["MINIMAP_TOOLTIP_RIGHT"], 0.7, 0.7, 0.7)
            if ns.TitleData.earnedCount and ns.TitleData.totalCount then
                tooltip:AddLine(string.format(L["MINIMAP_TOOLTIP_COLLECTED"],
                    ns.TitleData.earnedCount, ns.TitleData.totalCount), 0.5, 0.8, 0.5)
            end
        end,
    })

    LDBIcon:Register("Epithet", launcher, self.db.profile.minimap)
end
