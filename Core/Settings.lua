-- =============================================================================
-- Epithet — Settings
-- AddOns options panel for the social layer.
-- =============================================================================
local _, ns = ...
local L = ns.L
local T = ns.Theme
local C_Timer = C_Timer
local legacyOpenToCategory = _G.InterfaceOptionsFrame_OpenToCategory
local legacyAddCategory = _G.InterfaceOptions_AddCategory

local BlizzardSettings = _G.Settings

local Options = {}
ns.Settings = Options

local function ApplyPortraitTexture(texture, unit, style, shell)
    if ns.Layouts and ns.Layouts.ApplyPortraitTexture then
        return ns.Layouts:ApplyPortraitTexture(texture, unit, style, shell)
    end

    if not texture or not unit or not SetPortraitTexture then return end

    -- Mirrors Layouts:ApplyPortraitTexture, minus the retry bookkeeping: this
    -- branch only runs if the layout registry somehow failed to load, and the
    -- pcall is guarding the 10.0 disableMasking argument, not the call itself.
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

-- Return the social settings profile, if it has been initialised.
local function GetProfile()
    return ns.Epithet and ns.Epithet.db and ns.Epithet.db.profile and ns.Epithet.db.profile.social or nil
end

-- Normalise the stored achievement notification mode and legacy boolean flag.
local function NormalizeAchievementNotifyMode(profile)
    if not profile then
        return "full"
    end

    local mode = profile.achievementNotifyMode
    if mode ~= "full" and mode ~= "silent" and mode ~= "off" then
        if profile.achievementNotify == false then
            mode = "off"
        else
            mode = "full"
        end
    end

    profile.achievementNotifyMode = mode
    profile.achievementNotify = (mode ~= "off")
    return mode
end

-- Normalise the stored achievement popup anchor mode.
local function NormalizeAchievementAlertAnchor(profile)
    if not profile then
        return "alertframe"
    end

    local mode = profile.achievementAlertAnchor
    if mode ~= "uiparent" and mode ~= "alertframe" then
        mode = "alertframe"
    end

    profile.achievementAlertAnchor = mode
    return mode
end

-- Return the saved portrait render mode for social previews and nameplates.
function ns.GetPortraitMode()
    local profile = GetProfile()
    if profile and profile.animatedPortrait == false then
        return "2d"
    end
    return "3d"
end

-- Return whether title spotting is currently enabled.
function ns.IsTitleSpottingEnabled()
    local profile = GetProfile()
    return profile and profile.enabled == true
end

-- Build the shared settings-tab chrome and return the inner drawing canvas.
local function BuildChromedCanvas(panel)
    local canvas = panel
    if T and T.Panel and T.col then
        local shell = T.Panel(panel, T.col.bg0, T.col.line, 0.35)
        shell:SetPoint("TOPLEFT", 8, -8)
        shell:SetPoint("BOTTOMRIGHT", -8, 8)

        local inset = T.Panel(shell, T.col.panel, T.col.lineSoft, 0.35)
        inset:SetPoint("TOPLEFT", 10, -10)
        inset:SetPoint("BOTTOMRIGHT", -10, 10)
        canvas = inset

        if T.Diamond then
            local tl = T.Diamond(shell, 8, T.col.gold); tl:SetPoint("TOPLEFT", shell, "TOPLEFT", 2, -2)
            local tr = T.Diamond(shell, 8, T.col.gold); tr:SetPoint("TOPRIGHT", shell, "TOPRIGHT", -2, -2)
            local bl = T.Diamond(shell, 8, T.col.gold); bl:SetPoint("BOTTOMLEFT", shell, "BOTTOMLEFT", 2, 2)
            local br = T.Diamond(shell, 8, T.col.gold); br:SetPoint("BOTTOMRIGHT", shell, "BOTTOMRIGHT", -2, 2)
        end
    end
    return canvas
end

-- Wrap `viewport` in a scrollable canvas with mouse-wheel support.
local function BuildScrollCanvas(viewport)
    local scrollFrame = CreateFrame("ScrollFrame", nil, viewport, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", viewport, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", viewport, "BOTTOMRIGHT", -30, 8)
    scrollFrame:EnableMouseWheel(true)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollContent:SetSize(560, 760)
    scrollFrame:SetScrollChild(scrollContent)

    -- Match the child width to the usable viewport width.
    local function SyncScrollWidth()
        local frameWidth = scrollFrame:GetWidth() or 0
        local scrollbarWidth = math.max(24, (scrollFrame.ScrollBar and scrollFrame.ScrollBar:GetWidth()) or 0)
        local width = math.max(320, math.floor(frameWidth - scrollbarWidth))
        scrollContent:SetWidth(width)
    end

    scrollFrame:SetScript("OnSizeChanged", SyncScrollWidth)
    SyncScrollWidth()

    scrollFrame:SetScript("OnMouseWheel", function(self_, delta)
        local current = self_:GetVerticalScroll() or 0
        local step = 32
        local maxScroll = math.max(0, (scrollContent:GetHeight() or 0) - (self_:GetHeight() or 0))
        if delta > 0 then
            self_:SetVerticalScroll(math.max(0, current - step))
        else
            self_:SetVerticalScroll(math.min(maxScroll, current + step))
        end
    end)

    return scrollFrame, scrollContent, SyncScrollWidth
end

-- Create a settings checkbox with a caller-managed position and refresh hook.
local function MakeCheck(canvas, label, getter, setter, onChange)
    local box = CreateFrame("CheckButton", nil, canvas, "UICheckButtonTemplate")
    box:SetSize(24, 24)
    box:SetScript("OnClick", function(self_)
        setter(self_:GetChecked() and true or false)
        if onChange then onChange() end
    end)
    local text = (T and T.Sans and T.Sans(canvas, 12, T.col.text)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    text:SetPoint("LEFT", box, "RIGHT", 6, 0)
    text:SetText(label)
    box.text = text
    box.Refresh = function()
        box:SetChecked(getter() and true or false)
    end
    return box
end

local function OpenToCategory(category)
    if BlizzardSettings and BlizzardSettings.OpenToCategory and category then
        local categoryID = (type(category) == "table" and category.GetID and category:GetID()) or category.ID or category
        BlizzardSettings.OpenToCategory(categoryID)
        return true
    end
    return false
end

-- Open a legacy Interface Options panel when the modern Settings API is unavailable.
local function OpenLegacyPanel(panel)
    if legacyOpenToCategory and panel then
        legacyOpenToCategory(panel)
        legacyOpenToCategory(panel)
        return true
    end
    return false
end

-- Opens the top-level Epithet settings page (title-bar Settings button).
function Options:OpenMainSettings()
    if OpenToCategory(self.category) then
        return
    end

    OpenLegacyPanel(self.panel)
end

-- Opens directly to the Title Spotting sub-tab, where the "Enable title
-- spotting" toggle lives (used by the Spotting Log's gated "Enable in
-- Settings" prompt).
function Options:OpenSpottingSettings()
    if OpenToCategory(self.titleSpottingCategory or self.category) then
        return
    end

    local panel = self.titleSpottingPanel or self.panel
    OpenLegacyPanel(panel)
end

local function RefreshAll()
    if ns.SocialLayer then
        ns.SocialLayer:ApplySettings()
    end
end

-- Account-wide language preference helpers.
local function GetLocalePref()
    local g = ns.Epithet and ns.Epithet.db and ns.Epithet.db.global
    return (g and g.locale) or "auto"
end

-- Store the selected account-wide language preference.
local function SetLocalePref(code)
    local g = ns.Epithet and ns.Epithet.db and ns.Epithet.db.global
    if g then g.locale = code end
end

-- Return the display label for a stored language preference value.
local function LocalePrefLabel(pref)
    if not pref or pref == "auto" then
        return L["OPTIONS_LANGUAGE_AUTO"]
    end
    return ns.GetLocaleDisplayName and ns.GetLocaleDisplayName(pref) or pref
end

-- Build the Language sub-tab and register it under the parent category.
function Options:BuildLanguagePanel(parentCategory)
    if self.languagePanel then return self.languagePanel end

    if not StaticPopupDialogs["EPITHET_LOCALE_RELOAD"] then
        StaticPopupDialogs["EPITHET_LOCALE_RELOAD"] = {
            text = L["OPTIONS_LANGUAGE_RELOAD_PROMPT"],
            button1 = L["RELOAD_NOW"],
            button2 = L["LATER"],
            OnAccept = function() ReloadUI() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    local panel = CreateFrame("Frame")
    -- Created hidden, and this is load-bearing: a parentless frame is shown by
    -- default and counts as visible, so a panel built shown is "visible" from
    -- login onward and its first display by the settings UI is not a visibility
    -- transition -- OnShow never fires and none of the show-time work runs.
    -- (Later opens were always fine: ClearCurrentCategoryCanvas hides the frame
    -- on navigate-away, so every open after the first is a real transition.)
    panel:Hide()
    panel.name = L["OPTIONS_LANGUAGE_SECTION"]
    self.languagePanel = panel

    local canvas = BuildChromedCanvas(panel)

    local title = (T and T.Serif and T.Serif(canvas, 20, T.col.goldBright)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["OPTIONS_LANGUAGE_SECTION"])

    local languageLabel = (T and T.Sans and T.Sans(canvas, 12, T.col.goldDim)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    languageLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
    languageLabel:SetText(L["OPTIONS_LANGUAGE_LABEL"])

    local languageDrop = CreateFrame("Frame", "EpithetLanguageDropdown", canvas, "UIDropDownMenuTemplate")
    languageDrop:SetPoint("TOPLEFT", languageLabel, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(languageDrop, 240)

    -- Apply the locale font to the dropdown text and menu entries when needed.
    local localeFont = T and T.LocaleFontObject and T.LocaleFontObject(12)
    if localeFont then
        local dropText = _G["EpithetLanguageDropdownText"]
        if dropText and dropText.SetFontObject then dropText:SetFontObject(localeFont) end
    end

    local languageNote = (T and T.Sans and T.Sans(canvas, 11, T.col.faint)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    languageNote:SetPoint("TOPLEFT", languageDrop, "BOTTOMLEFT", 16, -2)
    languageNote:SetWidth(480)
    languageNote:SetJustifyH("LEFT")
    languageNote:SetText(L["OPTIONS_LANGUAGE_NOTE"])

    -- Sync the dropdown label with the stored language preference.
    local function RefreshLanguageDropdown()
        local pref = GetLocalePref()
        UIDropDownMenu_SetSelectedValue(languageDrop, pref)
        UIDropDownMenu_SetText(languageDrop, LocalePrefLabel(pref))
    end
    self.RefreshLanguageDropdown = RefreshLanguageDropdown

    UIDropDownMenu_Initialize(languageDrop, function(_, level)
        if level ~= 1 then return end
        local current = GetLocalePref()
        local function addOption(value, label)
            local info = UIDropDownMenu_CreateInfo()
            info.text = label
            info.value = value
            info.checked = (value == current)
            if localeFont then info.fontObject = localeFont end
            info.func = function()
                if value ~= GetLocalePref() then
                    SetLocalePref(value)
                    RefreshLanguageDropdown()
                    StaticPopup_Show("EPITHET_LOCALE_RELOAD")
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
        addOption("auto", L["OPTIONS_LANGUAGE_AUTO"])
        for _, code in ipairs(ns.GetAvailableLocales and ns.GetAvailableLocales() or {}) do
            addOption(code, ns.GetLocaleDisplayName and ns.GetLocaleDisplayName(code) or code)
        end
    end)

    panel:SetScript("OnShow", function()
        RefreshLanguageDropdown()
        if T and T.ApplyLocaleFontToTree then
            T.ApplyLocaleFontToTree(panel)
        end
    end)
    RefreshLanguageDropdown()

    if BlizzardSettings and BlizzardSettings.RegisterCanvasLayoutSubcategory and parentCategory then
        local sub = BlizzardSettings.RegisterCanvasLayoutSubcategory(parentCategory, panel, panel.name)
        self.languageCategory = sub
        if sub and sub.SetOnRefresh then
            sub:SetOnRefresh(RefreshLanguageDropdown)
        end
    elseif legacyAddCategory then
        panel.parent = "Epithet"
        legacyAddCategory(panel)
    end

    return panel
end

-- Build the Achievements sub-tab and its notification controls.
function Options:BuildAchievementsPanel(parentCategory)
    if self.achievementsPanel then return self.achievementsPanel end

    local panel = CreateFrame("Frame")
    -- Created hidden; see BuildLanguagePanel for why this is load-bearing.
    panel:Hide()
    panel.name = L["SOCIAL_ACHIEVEMENT_SECTION"] or "Achievements"
    self.achievementsPanel = panel

    local canvas = BuildChromedCanvas(panel)

    local title = (T and T.Serif and T.Serif(canvas, 20, T.col.goldBright)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["SOCIAL_ACHIEVEMENT_SECTION"] or "Achievements")

    local desc = (T and T.Sans and T.Sans(canvas, 12, T.col.text)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(520)
    desc:SetJustifyH("LEFT")
    desc:SetText(L["SOCIAL_ACHIEVEMENT_LAYER_DESC"] or "Achievement pop-ups cover your own title collection as well as titles you've spotted on others. Configure how they notify you here - title spotting itself is switched on from its own tab.")

    local achievementNotifyHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.text)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    achievementNotifyHeading:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 4, -14)
    achievementNotifyHeading:SetText(L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE"] or "Achievement notification mode")

    local achievementNotifyDrop = CreateFrame("Frame", "EpithetAchievementNotifyDropdown", canvas, "UIDropDownMenuTemplate")
    achievementNotifyDrop:SetPoint("TOPLEFT", achievementNotifyHeading, "BOTTOMLEFT", -20, -2)
    UIDropDownMenu_SetWidth(achievementNotifyDrop, 220)

    -- Store the selected achievement notification mode.
    local function SetAchievementNotifyMode(mode)
        local profile = GetProfile()
        if not profile then
            return
        end
        if mode ~= "full" and mode ~= "silent" and mode ~= "off" then
            mode = "full"
        end
        profile.achievementNotifyMode = mode
        profile.achievementNotify = (mode ~= "off")
    end

    -- Return the dropdown label for an achievement notification mode.
    local function AchievementNotifyModeLabel(mode)
        if mode == "silent" then
            return L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_SILENT"] or "Popup only (mute sound)"
        elseif mode == "off" then
            return L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_OFF"] or "Off"
        end
        return L["SOCIAL_ACHIEVEMENT_NOTIFY_MODE_FULL"] or "Popup + sound"
    end

    -- Sync the achievement notification dropdown with the stored mode.
    local function RefreshAchievementNotifyDropdown()
        local profile = GetProfile()
        local mode = NormalizeAchievementNotifyMode(profile)
        UIDropDownMenu_SetSelectedValue(achievementNotifyDrop, mode)
        UIDropDownMenu_SetText(achievementNotifyDrop, AchievementNotifyModeLabel(mode))
    end

    UIDropDownMenu_Initialize(achievementNotifyDrop, function(_, level)
        if level ~= 1 then return end

        local profile = GetProfile()
        local current = NormalizeAchievementNotifyMode(profile)
        local modes = {
            { value = "full", label = AchievementNotifyModeLabel("full") },
            { value = "silent", label = AchievementNotifyModeLabel("silent") },
            { value = "off", label = AchievementNotifyModeLabel("off") },
        }

        for _, option in ipairs(modes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.value = option.value
            info.checked = (option.value == current)
            info.func = function()
                SetAchievementNotifyMode(option.value)
                RefreshAchievementNotifyDropdown()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local achievementAnchorHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.text)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    achievementAnchorHeading:SetPoint("TOPLEFT", achievementNotifyDrop, "BOTTOMLEFT", 20, -8)
    achievementAnchorHeading:SetText(L["SOCIAL_ACHIEVEMENT_ANCHOR_MODE"] or "Achievement popup anchor")

    local achievementAnchorDrop = CreateFrame("Frame", "EpithetAchievementAnchorDropdown", canvas, "UIDropDownMenuTemplate")
    achievementAnchorDrop:SetPoint("TOPLEFT", achievementAnchorHeading, "BOTTOMLEFT", -20, -2)
    UIDropDownMenu_SetWidth(achievementAnchorDrop, 220)

    local achievementAnchorNote = (T and T.Sans and T.Sans(canvas, 11, T.col.faint)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    achievementAnchorNote:SetPoint("TOPLEFT", achievementAnchorDrop, "BOTTOMLEFT", 20, -2)
    achievementAnchorNote:SetJustifyH("LEFT")
    achievementAnchorNote:SetJustifyV("TOP")
    achievementAnchorNote:SetWidth(500)

    -- Return the dropdown label for an achievement popup anchor mode.
    local function AchievementAnchorModeLabel(mode)
        if mode == "alertframe" then
            return L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME"] or "Match Blizzard AlertFrame"
        end
        return L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT"] or "Screen top (UIParent)"
    end

    -- Return the helper text for an achievement popup anchor mode.
    local function AchievementAnchorModeNote(mode)
        if mode == "alertframe" then
            return L["SOCIAL_ACHIEVEMENT_ANCHOR_ALERTFRAME_DESC"] or "Follows Blizzard achievement/loot toast area. If another addon moves or hides AlertFrame, this popup moves with it."
        end
        return L["SOCIAL_ACHIEVEMENT_ANCHOR_UIPARENT_DESC"] or "Anchors to the top-center of the screen. Most reliable if AlertFrame is moved or hidden by UI mods."
    end

    -- Store the selected achievement popup anchor mode.
    local function SetAchievementAnchorMode(mode)
        local profile = GetProfile()
        if not profile then
            return
        end

        if mode ~= "uiparent" and mode ~= "alertframe" then
            mode = "alertframe"
        end
        profile.achievementAlertAnchor = mode
    end

    -- Sync the achievement anchor dropdown and helper text with the stored mode.
    local function RefreshAchievementAnchorDropdown()
        local profile = GetProfile()
        local mode = NormalizeAchievementAlertAnchor(profile)
        UIDropDownMenu_SetSelectedValue(achievementAnchorDrop, mode)
        UIDropDownMenu_SetText(achievementAnchorDrop, AchievementAnchorModeLabel(mode))
        achievementAnchorNote:SetText(AchievementAnchorModeNote(mode))
    end

    UIDropDownMenu_Initialize(achievementAnchorDrop, function(_, level)
        if level ~= 1 then return end

        local profile = GetProfile()
        local current = NormalizeAchievementAlertAnchor(profile)
        local modes = {
            { value = "uiparent", label = AchievementAnchorModeLabel("uiparent") },
            { value = "alertframe", label = AchievementAnchorModeLabel("alertframe") },
        }

        for _, option in ipairs(modes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.value = option.value
            info.checked = (option.value == current)
            info.func = function()
                SetAchievementAnchorMode(option.value)
                RefreshAchievementAnchorDropdown()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local achievementDisabledNote = (T and T.Sans and T.Sans(canvas, 11, T.col.warn)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    achievementDisabledNote:SetPoint("TOPLEFT", achievementAnchorNote, "BOTTOMLEFT", -4, -18)
    achievementDisabledNote:SetJustifyH("LEFT")
    achievementDisabledNote:SetJustifyV("TOP")
    achievementDisabledNote:SetWidth(500)
    achievementDisabledNote:SetText(L["SOCIAL_ACHIEVEMENT_SPOTTING_DISABLED_NOTE"] or "Title spotting is off, so spotting achievements can't progress. Turn it on from the Title Spotting tab to keep them updating. Achievements based on your own title collection are still tracked.")

    -- Refresh the Achievements tab controls from the current profile state.
    local function RefreshControls()
        RefreshAchievementNotifyDropdown()
        RefreshAchievementAnchorDropdown()
        local profile = GetProfile()
        achievementDisabledNote:SetShown(not (profile and profile.enabled))
    end

    self.RefreshAchievements = function(self_)
        if not self_ or not self_.achievementsPanel then return end
        RefreshControls()
    end

    panel:SetScript("OnShow", function()
        RefreshControls()
        if T and T.ApplyLocaleFontToTree then
            T.ApplyLocaleFontToTree(panel)
        end
    end)
    RefreshControls()

    if BlizzardSettings and BlizzardSettings.RegisterCanvasLayoutSubcategory and parentCategory then
        local sub = BlizzardSettings.RegisterCanvasLayoutSubcategory(parentCategory, panel, panel.name)
        self.achievementsCategory = sub
        if sub and sub.SetOnRefresh then
            sub:SetOnRefresh(RefreshControls)
        end
    elseif legacyAddCategory then
        panel.parent = "Epithet"
        legacyAddCategory(panel)
    end

    return panel
end

-- Build the Title Spotting sub-tab and its preview, behaviour, and position controls.
function Options:BuildTitleSpottingPanel(parentCategory)
    if self.titleSpottingPanel then return self.titleSpottingPanel end

    local panel = CreateFrame("Frame")
    -- Created hidden, and for this tab it is THE fix for the first-open 3D
    -- portrait: built shown, the panel counted as visible from login, so the
    -- portrait model was seated and its camera computed during the loading
    -- screen (aimed at z=1.5, empty air) -- and the first real display fired
    -- no OnShow, so nothing ever ran to correct it. Hidden from birth, the
    -- login-time seat is refused and deferred to the model's OnShow, which now
    -- fires on the first display and seats the model while it is genuinely on
    -- screen -- the case that computes the camera correctly. See
    -- BuildLanguagePanel for the general form of this note.
    panel:Hide()
    panel.name = L["SOCIAL_LAYER"] or "Title Spotting"
    self.titleSpottingPanel = panel

    local outerCanvas = BuildChromedCanvas(panel)
    local scrollFrame, canvas, SyncScrollWidth = BuildScrollCanvas(outerCanvas)
    self.titleSpottingScrollFrame = scrollFrame
    self.titleSpottingScrollContent = canvas

    -- Defined further down, once the controls it measures exist. Forward-declared
    -- because the preview (built well before it) resizes itself when the sample
    -- title changes, which moves everything below it.
    local UpdateScrollBounds

    local title = (T and T.Serif and T.Serif(canvas, 20, T.col.goldBright)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["SOCIAL_LAYER"] or "Title Spotting")

    local desc = (T and T.Sans and T.Sans(canvas, 12, T.col.text)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(520)
    desc:SetJustifyH("LEFT")
    desc:SetText(L["SOCIAL_LAYER_DESC"] or "Inspecting total strangers is practically a core ability by now. Point it at their titles too: spot what another players have chosen to wear and jump straight in to how it's earned in Epithet.")

    local stateHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.goldDim)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    stateHeading:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
    stateHeading:SetText(L["SOCIAL_STATE_SECTION"] or "Feature State")

    local enabled = MakeCheck(canvas, L["SOCIAL_ENABLED"] or "Enable title spotting",
        function()
            local profile = GetProfile()
            return profile and profile.enabled
        end,
        function(value)
            local profile = GetProfile()
            if profile then profile.enabled = value end
            if ns.LogbookUI and ns.LogbookUI.HandleSpottingStateChanged then
                ns.LogbookUI:HandleSpottingStateChanged()
            end
        end)
    enabled:SetPoint("TOPLEFT", stateHeading, "BOTTOMLEFT", 0, -6)

    if enabled.text and enabled.text.SetTextColor then
        if T and T.col and T.col.goldBright then
            enabled.text:SetTextColor(T.col.goldBright.r, T.col.goldBright.g, T.col.goldBright.b, 1)
        else
            enabled.text:SetTextColor(1, 0.92, 0.72)
        end
    end

    local function GetLayoutOptions()
        if ns.SocialLayer and ns.SocialLayer.GetLayoutOptions then
            return ns.SocialLayer:GetLayoutOptions()
        end
        return {
            { key = "classic", label = L["SOCIAL_LAYOUT_CLASSIC"] or "Slimline" },
        }
    end

    local function ResolveLayoutLabel(key)
        for _, option in ipairs(GetLayoutOptions()) do
            if option.key == key then
                return option.label
            end
        end
        return key or (L["SOCIAL_LAYOUT_CLASSIC"] or "Slimline")
    end

    local layoutHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.goldDim)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    layoutHeading:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 0, -22)
    layoutHeading:SetText(L["SOCIAL_LAYOUT_SECTION"] or "Nameplate Layout")

    local layoutDrop = CreateFrame("Frame", "EpithetSocialLayoutDropdown", canvas, "UIDropDownMenuTemplate")
    layoutDrop:SetPoint("TOPLEFT", layoutHeading, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(layoutDrop, 240)

    -- Sync the layout dropdown with the stored nameplate layout.
    local function RefreshLayoutDropdown()
        local profile = GetProfile()
        local key = profile and profile.layout or "classic"
        if ns.SocialLayer and ns.SocialLayer.IsValidLayoutKey and not ns.SocialLayer:IsValidLayoutKey(key) then
            if ns.SocialLayer.GetDefaultLayoutKey then
                key = ns.SocialLayer:GetDefaultLayoutKey()
            else
                key = "classic"
            end
            if profile then profile.layout = key end
        end
        UIDropDownMenu_SetSelectedValue(layoutDrop, key)
        UIDropDownMenu_SetText(layoutDrop, ResolveLayoutLabel(key))
    end

    UIDropDownMenu_Initialize(layoutDrop, function(_, level)
        if level ~= 1 then return end
        local profile = GetProfile()
        local current = profile and profile.layout or "classic"
        for _, option in ipairs(GetLayoutOptions()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.value = option.key
            info.checked = (option.key == current)
            info.func = function()
                local p = GetProfile()
                if p then p.layout = option.key end
                RefreshLayoutDropdown()
                RefreshAll()
                if Options and Options.Refresh then
                    Options:Refresh()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local previewHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.goldDim)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    previewHeading:SetPoint("TOPLEFT", layoutDrop, "BOTTOMLEFT", 16, -12)
    previewHeading:SetText(L["SOCIAL_LAYOUT_PREVIEW"] or "Layout Preview")

    local previewFrame = CreateFrame("Frame", nil, canvas, "BackdropTemplate")
    previewFrame:SetSize(520, 116)
    previewFrame:SetPoint("TOPLEFT", previewHeading, "BOTTOMLEFT", 0, -8)
    previewFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    if T and T.col then
        previewFrame:SetBackdropColor(T.col.bg0.r, T.col.bg0.g, T.col.bg0.b, 0.75)
        previewFrame:SetBackdropBorderColor(T.col.line.r, T.col.line.g, T.col.line.b, 0.7)
    else
        previewFrame:SetBackdropColor(0.08, 0.06, 0.04, 0.75)
        previewFrame:SetBackdropBorderColor(0.55, 0.46, 0.30, 0.7)
    end

    -- Keep the preview plate globally named for in-game inspection.
    local previewPlate = CreateFrame("Frame", "EpithetSocialLayoutPreviewPlate", previewFrame, "BackdropTemplate")
    previewPlate:SetPoint("CENTER", previewFrame, "CENTER", 0, 0)
    previewPlate:SetSize(244, 58)
    previewPlate:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    if T and T.col then
        previewPlate:SetBackdropColor(T.col.bg0.r, T.col.bg0.g, T.col.bg0.b, 0.9)
        previewPlate:SetBackdropBorderColor(T.col.goldDeep.r, T.col.goldDeep.g, T.col.goldDeep.b, 0.9)
    else
        previewPlate:SetBackdropColor(0.08, 0.06, 0.04, 0.9)
        previewPlate:SetBackdropBorderColor(0.72, 0.58, 0.26, 0.9)
    end

    previewPlate.leftCol = CreateFrame("Frame", nil, previewPlate)
    previewPlate.leftCol:SetPoint("TOPLEFT", previewPlate, "TOPLEFT", 4, -3)
    previewPlate.leftCol:SetPoint("BOTTOMLEFT", previewPlate, "BOTTOMLEFT", 4, 3)
    previewPlate.leftCol:SetWidth(44)

    previewPlate.gem = previewPlate.leftCol:CreateTexture(nil, "ARTWORK")
    previewPlate.gem:SetSize(40, 40)
    previewPlate.gem:SetPoint("CENTER", previewPlate.leftCol, "CENTER", 0, 0)

    previewPlate.portraitShell = CreateFrame("Frame", nil, previewPlate)
    previewPlate.portraitShell:SetPoint("TOPRIGHT", previewPlate, "TOPRIGHT", 0, -3)
    previewPlate.portraitShell:SetPoint("BOTTOMRIGHT", previewPlate, "BOTTOMRIGHT", 0, 3)
    previewPlate.portraitShell:SetWidth(52)

    previewPlate.portraitBG = previewPlate.portraitShell:CreateTexture(nil, "BACKGROUND")
    previewPlate.portraitBG:SetAllPoints(previewPlate.portraitShell)
    previewPlate.portraitBG:SetColorTexture(0.05, 0.05, 0.05, 1.0)

    previewPlate.portrait = previewPlate.portraitShell:CreateTexture(nil, "ARTWORK")
    previewPlate.portrait:SetPoint("TOPLEFT", previewPlate.portraitShell, "TOPLEFT", 0, -1)
    previewPlate.portrait:SetPoint("BOTTOMRIGHT", previewPlate.portraitShell, "BOTTOMRIGHT", -1, 0)
    previewPlate.portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    -- The model is deliberately NOT built here. This panel is parentless until
    -- SettingsPanelMixin:DisplayLayout parents it into the settings canvas, and
    -- a Model created under a parentless frame is created against the wrong
    -- effective scale. The layout builds it on the first 3D pass instead, by
    -- which point the panel is parented.

    previewPlate.portraitTopRule = previewPlate:CreateTexture(nil, "BORDER")
    previewPlate.portraitTopRule:SetHeight(1)
    if T and T.col and T.col.line then
        previewPlate.portraitTopRule:SetColorTexture(T.col.line.r, T.col.line.g, T.col.line.b, 0.85)
    else
        previewPlate.portraitTopRule:SetColorTexture(0.70, 0.58, 0.31, 0.75)
    end
    previewPlate.portraitTopRule:Hide()

    previewPlate.portraitBottomRule = previewPlate:CreateTexture(nil, "BORDER")
    previewPlate.portraitBottomRule:SetHeight(1)
    if T and T.col and T.col.line then
        previewPlate.portraitBottomRule:SetColorTexture(T.col.line.r, T.col.line.g, T.col.line.b, 0.85)
    else
        previewPlate.portraitBottomRule:SetColorTexture(0.70, 0.58, 0.31, 0.75)
    end
    previewPlate.portraitBottomRule:Hide()

    previewPlate.crownFrame = CreateFrame("Frame", nil, previewFrame)
    previewPlate.crownFrame:SetFrameStrata("HIGH")
    previewPlate.crownFrame:SetFrameLevel(previewPlate:GetFrameLevel() + 8)
    previewPlate.crownFrame:SetSize(34, 34)
    previewPlate.crown = previewPlate.crownFrame:CreateTexture(nil, "OVERLAY")
    previewPlate.crown:SetAllPoints(previewPlate.crownFrame)

    previewPlate.centerCol = CreateFrame("Frame", nil, previewPlate)
    previewPlate.centerCol:SetPoint("TOPLEFT", previewPlate.leftCol, "TOPRIGHT", 9, -6)
    previewPlate.centerCol:SetPoint("BOTTOMRIGHT", previewPlate.portraitShell, "BOTTOMLEFT", -9, 6)

    previewPlate.titleRow = CreateFrame("Frame", nil, previewPlate.centerCol)
    previewPlate.titleRow:SetPoint("TOPLEFT", previewPlate.centerCol, "TOPLEFT", 0, 0)
    previewPlate.titleRow:SetPoint("TOPRIGHT", previewPlate.centerCol, "TOPRIGHT", 0, 0)
    previewPlate.titleRow:SetHeight(20)

    previewPlate.rarityRow = CreateFrame("Frame", nil, previewPlate.centerCol)
    previewPlate.rarityRow:SetPoint("BOTTOMLEFT", previewPlate.centerCol, "BOTTOMLEFT", 0, 0)
    previewPlate.rarityRow:SetPoint("BOTTOMRIGHT", previewPlate.centerCol, "BOTTOMRIGHT", 0, 0)
    previewPlate.rarityRow:SetHeight(18)

    local previewTitle = (T and T.Sans and T.Sans(previewPlate.titleRow, 11, T.col.goldBright)) or previewPlate.titleRow:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    -- Height, wrapping and max lines are the layout's to set: the row this fills
    -- is sized from the measured title, so pinning either here would fight it.
    previewTitle:SetAllPoints(previewPlate.titleRow)
    previewTitle:SetJustifyH("LEFT")
    previewTitle:SetJustifyV("MIDDLE")
    previewTitle:SetWordWrap(false)
    previewTitle:SetText(L["SAMPLE_TITLE"])
    previewPlate.titleText = previewTitle

    local previewRarity = (T and T.Sans and T.Sans(previewPlate.rarityRow, 10, T.col.muted)) or previewPlate.rarityRow:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    previewRarity:SetAllPoints(previewPlate.rarityRow)
    previewRarity:SetJustifyH("LEFT")
    previewRarity:SetJustifyV("MIDDLE")
    previewRarity:SetWordWrap(false)
    previewRarity:SetText(L["SAMPLE_RARITY"])
    previewPlate.rarityText = previewRarity

    local previewNote = (T and T.Sans and T.Sans(previewFrame, 11, T.col.faint)) or previewFrame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    previewNote:SetPoint("BOTTOMLEFT", previewFrame, "BOTTOMLEFT", 10, 8)
    previewNote:SetPoint("BOTTOMRIGHT", previewFrame, "BOTTOMRIGHT", -10, 8)
    previewNote:SetJustifyH("LEFT")
    previewNote:SetText(L["SOCIAL_LAYOUT_PREVIEW_NOTE"] or "Preview uses sample data.")

    -- Refresh the preview plate to match the current layout and portrait settings.
    local function RefreshLayoutPreview()
        local profile = GetProfile()
        local style = ns.SocialLayer and ns.SocialLayer.GetPreviewStyle and ns.SocialLayer:GetPreviewStyle(profile) or nil
        if not style or not style.metrics then return end

        -- Always render the preview from the player portrait.
        previewPlate.portraitUnit = "player"

        -- previewPlate.portraitModeOverride is deliberately not touched here:
        -- the override is a per-frame input to the layout's mode resolution
        -- (see ResolvePortraitMode), and a refresh that reset it would silently
        -- undo whatever its owner asked for. Nothing sets it today; the preview
        -- renders the saved mode.

        local key = style.key or "classic"
        local previewProfile = { layout = key }
        local layoutEngine = ns.Layouts

        local useFunnyTitle = profile and profile.previewFunnyTitle
        if useFunnyTitle then
            previewPlate.titleText:SetText(L["SAMPLE_FUNNY_TITLE"])
        else
            previewPlate.titleText:SetText(L["SAMPLE_TITLE"])
        end

        if layoutEngine and layoutEngine.ApplyLayoutToFrame and layoutEngine.SizeTargetPill then
            layoutEngine:ApplyLayoutToFrame(previewPlate, previewProfile)
            layoutEngine:SizeTargetPill(previewPlate, previewProfile)
        end

        local m = previewPlate.layoutMetrics or style.metrics
        -- The plate now sizes itself to its title, so the box has to follow it.
        previewFrame:SetHeight(math.max(116, (previewPlate:GetHeight() or (m and m.frameHeight) or 58) + 56))

        -- Crown size and placement come from the layout's own LayoutPortrait pass
        -- (run by SizeTargetPill above); only the artwork is the preview's to set.
        if previewPlate.crownFrame and m and m.layoutStyle ~= "portrait" then
            previewPlate.crown:SetTexture(style.crownIcon)
        end

        -- Showing/hiding the model against the texture is the layout's job and it
        -- has already run above. The only thing left for the preview is the 2D
        -- artwork, which classic's LayoutPortrait positions but never fills.
        if previewPlate.portraitMode ~= "3d" then
            ApplyPortraitTexture(previewPlate.portrait, "player", m.layoutStyle, previewPlate.portraitShell)
        end

        previewPlate.gem:SetTexture(style.rarityGem)
        previewPlate.gem:SetVertexColor(0.90, 0.70, 0.25, 1.0)
        previewPlate.rarityText:SetTextColor(0.90, 0.70, 0.25)
    end

    -- Checkpoints for the portrait event log (see DumpPortraitState): the
    -- panel's show and the user's mode switches anchor the log's timeline, so
    -- a future portrait report can be read without guessing what the user did.
    local function LogPreview(fmt, ...)
        if ns.Layouts and ns.Layouts.LogPortraitEventFor then
            ns.Layouts:LogPortraitEventFor(previewPlate, fmt, ...)
        end
    end

    local previewFunnyToggle = MakeCheck(canvas, L["SOCIAL_LAYOUT_FUNNY_TOGGLE"] or "Show funny long-title preview",
        function()
            local profile = GetProfile()
            return profile and profile.previewFunnyTitle
        end,
        function(value)
            local profile = GetProfile()
            if profile then profile.previewFunnyTitle = value end
            RefreshLayoutPreview()
            -- The long sample makes the preview taller, so everything under it moves.
            if UpdateScrollBounds then UpdateScrollBounds(nil) end
        end)
    previewFunnyToggle:SetPoint("TOPLEFT", previewFrame, "BOTTOMLEFT", 0, -12)

    local portraitModeHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.text)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    portraitModeHeading:SetPoint("TOPLEFT", previewFunnyToggle, "BOTTOMLEFT", 4, -8)
    portraitModeHeading:SetText(L["SOCIAL_LAYOUT_PORTRAIT_MODE"] or "Target portrait mode")

    local portraitModeDrop = CreateFrame("Frame", "EpithetSocialPortraitModeDropdown", canvas, "UIDropDownMenuTemplate")
    portraitModeDrop:SetPoint("TOPLEFT", portraitModeHeading, "BOTTOMLEFT", -20, -2)
    UIDropDownMenu_SetWidth(portraitModeDrop, 220)

    local portraitModeNote = (T and T.Sans and T.Sans(canvas, 11, T.col.faint)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    portraitModeNote:SetPoint("TOPLEFT", portraitModeDrop, "BOTTOMLEFT", 20, -2)
    portraitModeNote:SetWidth(500)
    portraitModeNote:SetJustifyH("LEFT")
    portraitModeNote:SetText(L["SOCIAL_LAYOUT_PORTRAIT_MODE_NOTE"] or "3D uses an animated model. 2D uses a static portrait texture.")

    -- Return the saved portrait mode from the profile's legacy boolean flag.
    local function GetPortraitModeValue()
        local profile = GetProfile()
        if profile and profile.animatedPortrait == false then
            return "2d"
        end
        return "3d"
    end

    -- Store portrait mode using the existing boolean profile setting.
    local function SetPortraitModeValue(mode)
        local profile = GetProfile()
        if not profile then
            return
        end
        if mode ~= "2d" and mode ~= "3d" then
            mode = "3d"
        end
        profile.animatedPortrait = (mode == "3d")
    end

    -- Return the display label for a portrait mode value.
    local function PortraitModeLabel(mode)
        if mode == "2d" then
            return L["SOCIAL_LAYOUT_PORTRAIT_MODE_2D"] or "2D (static)"
        end
        return L["SOCIAL_LAYOUT_PORTRAIT_MODE_3D"] or "3D (animated)"
    end

    -- Sync the portrait mode dropdown to the currently stored profile value.
    local function RefreshPortraitModeDropdown()
        local mode = GetPortraitModeValue()
        UIDropDownMenu_SetSelectedValue(portraitModeDrop, mode)
        UIDropDownMenu_SetText(portraitModeDrop, PortraitModeLabel(mode))
    end

    UIDropDownMenu_Initialize(portraitModeDrop, function(_, level)
        if level ~= 1 then return end

        local current = GetPortraitModeValue()
        local modes = {
            { value = "3d", label = PortraitModeLabel("3d") },
            { value = "2d", label = PortraitModeLabel("2d") },
        }

        for _, option in ipairs(modes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.value = option.value
            info.checked = (option.value == current)
            info.func = function()
                -- Re-picking the mode that is already stored is a no-op click:
                -- bail out rather than tearing down and reseating the 3D model
                -- (and re-laying out the target nameplate) for an unchanged
                -- value. Read the stored mode again here rather than trusting
                -- `current`, which was captured when the menu was built.
                if option.value == GetPortraitModeValue() then
                    return
                end

                LogPreview("manual mode switch -> %s", tostring(option.value))
                SetPortraitModeValue(option.value)
                RefreshPortraitModeDropdown()
                RefreshAll()
                RefreshLayoutPreview()
                if Options and Options.Refresh then
                    Options:Refresh()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local fadeHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.goldDim)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    fadeHeading:SetPoint("TOPLEFT", portraitModeNote, "BOTTOMLEFT", -4, -14)
    fadeHeading:SetText(L["SOCIAL_FADE_SECTION"] or "Fade")

    local fadeToggle = MakeCheck(canvas, L["SOCIAL_FADE_ENABLE"] or "Fade target nameplates over time",
        function()
            local profile = GetProfile()
            return profile and profile.fadeNameplates == true
        end,
        function(value)
            local profile = GetProfile()
            if profile then profile.fadeNameplates = value end
            if Options and Options.Refresh then
                Options:Refresh()
            end
        end)
    fadeToggle:SetPoint("TOPLEFT", fadeHeading, "BOTTOMLEFT", 0, -6)

    local fadeLabel = (T and T.Sans and T.Sans(canvas, 12, T.col.text)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    fadeLabel:SetPoint("TOPLEFT", fadeToggle.text, "BOTTOMLEFT", 0, -8)
    fadeLabel:SetText(L["SOCIAL_FADE_DURATION"] or "Fade delay")

    local fadeSlider = CreateFrame("Slider", "EpithetFadeDurationSlider", canvas, "OptionsSliderTemplate")
    fadeSlider:SetOrientation("HORIZONTAL")
    fadeSlider:SetMinMaxValues(0.5, 20.0)
    fadeSlider:SetValueStep(0.5)
    if fadeSlider.SetObeyStepOnDrag then
        fadeSlider:SetObeyStepOnDrag(true)
    end
    fadeSlider:SetWidth(280)
    fadeSlider:SetHeight(16)
    fadeSlider:SetPoint("TOPLEFT", fadeLabel, "BOTTOMLEFT", 0, -8)

    local fadeSliderText = _G[fadeSlider:GetName() .. "Text"]
    local fadeSliderLow = _G[fadeSlider:GetName() .. "Low"]
    local fadeSliderHigh = _G[fadeSlider:GetName() .. "High"]
    if fadeSliderText and fadeSliderText.SetText then
        fadeSliderText:SetText("")
    end
    if fadeSliderLow and fadeSliderLow.SetText then
        fadeSliderLow:SetText(L["FADE_SLIDER_LOW"])
    end
    if fadeSliderHigh and fadeSliderHigh.SetText then
        fadeSliderHigh:SetText(L["FADE_SLIDER_HIGH"])
    end

    local fadeValueText = (T and T.Sans and T.Sans(canvas, 11, T.col.faint)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fadeValueText:SetPoint("LEFT", fadeSlider, "RIGHT", 10, 0)
    fadeValueText:SetJustifyH("LEFT")

    -- Format the fade slider value for the helper label.
    local function SetFadeValueText(value)
        local seconds = tonumber(value) or 4.0
        local fmt = L["SOCIAL_FADE_DURATION_FMT"] or "%.1f seconds before fade"
        fadeValueText:SetText(string.format(fmt, seconds))
    end

    fadeSlider:SetScript("OnValueChanged", function(self_, value)
        if Options and Options._refreshingFadeSlider then
            SetFadeValueText(value)
            return
        end
        local profile = GetProfile()
        if profile then
            profile.fadeDuration = value
        end
        SetFadeValueText(value)
        RefreshAll()
        if Options and Options.Refresh then
            Options:Refresh()
        end
    end)

    local behaviourHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.goldDim)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    behaviourHeading:SetPoint("LEFT", fadeHeading, "LEFT", 0, 0)
    behaviourHeading:SetPoint("TOP", fadeSlider, "BOTTOM", 0, -14)
    behaviourHeading:SetText(L["SOCIAL_BEHAVIOUR_SECTION"] or "Visibility Rules")

    local hideInCombat = MakeCheck(canvas, L["SOCIAL_HIDE_IN_COMBAT"] or "Hide target nameplate during combat",
        function()
            local profile = GetProfile()
            return profile and profile.hideInCombat
        end,
        function(value)
            local profile = GetProfile()
            if profile then profile.hideInCombat = value end
        end,
        function()
            RefreshAll()
        end)
    hideInCombat:SetPoint("TOPLEFT", behaviourHeading, "BOTTOMLEFT", 0, -6)

    local hideInGroup = MakeCheck(canvas, L["SOCIAL_HIDE_IN_GROUP"] or "Hide target nameplate when grouped",
        function()
            local profile = GetProfile()
            return profile and profile.hideInGroup
        end,
        function(value)
            local profile = GetProfile()
            if profile then profile.hideInGroup = value end
        end,
        function()
            RefreshAll()
        end)
    hideInGroup:SetPoint("TOPLEFT", hideInCombat, "BOTTOMLEFT", 0, -8)

    local showSelfTarget = MakeCheck(canvas, L["SOCIAL_SHOW_SELF_TARGET"] or "Show target nameplate when targeting yourself",
        function()
            local profile = GetProfile()
            return profile and profile.showSelfTargetNameplate == true
        end,
        function(value)
            local profile = GetProfile()
            if profile then profile.showSelfTargetNameplate = value end
        end,
        function()
            RefreshAll()
        end)
    showSelfTarget:SetPoint("TOPLEFT", hideInGroup, "BOTTOMLEFT", 0, -8)

    local selfTargetNote = (T and T.Sans and T.Sans(canvas, 11, T.col.faint)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    selfTargetNote:SetPoint("TOPLEFT", showSelfTarget.text, "BOTTOMLEFT", 0, -2)
    selfTargetNote:SetWidth(500)
    selfTargetNote:SetJustifyH("LEFT")
    selfTargetNote:SetText(L["SOCIAL_SELF_TARGET_NOTE"] or "Showing your own target nameplate is visual only. Targeting yourself never counts toward title spotting achievements.")

    local spotNotify = MakeCheck(canvas, L["SOCIAL_SPOTTING_NOTIFY"] or "Show spotting confirmations in chat",
        function()
            local profile = GetProfile()
            return profile and profile.spotNotify ~= false
        end,
        function(value)
            local profile = GetProfile()
            if profile then profile.spotNotify = value end
        end)
    spotNotify:SetPoint("TOPLEFT", selfTargetNote, "BOTTOMLEFT", -30, -8)

    local positionHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.goldDim)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    positionHeading:SetPoint("TOPLEFT", spotNotify, "BOTTOMLEFT", 0, -14)
    positionHeading:SetText(L["SOCIAL_POSITION_SECTION"] or "Position")

    local unlockTarget = MakeCheck(canvas, L["SOCIAL_TARGET_UNLOCK"] or "Unlock target nameplate (drag to move)",
        function()
            local profile = GetProfile()
            return profile and profile.targetUnlock
        end,
        function(value)
            local profile = GetProfile()
            if profile then profile.targetUnlock = value end
        end,
        function()
            RefreshAll()
        end)
    unlockTarget:SetPoint("TOPLEFT", positionHeading, "BOTTOMLEFT", 0, -6)

    local resetTarget = CreateFrame("Button", nil, canvas)
    resetTarget:SetSize(300, 30)
    resetTarget:SetPoint("TOPLEFT", unlockTarget, "BOTTOMLEFT", 0, -8)

    local resetBG = resetTarget:CreateTexture(nil, "BACKGROUND")
    resetBG:SetAllPoints()
    resetBG:SetColorTexture(0.11, 0.08, 0.04, 1.0)
    resetTarget.bg = resetBG

    local rbTop = resetTarget:CreateTexture(nil, "BORDER")
    rbTop:SetHeight(1)
    rbTop:SetPoint("TOPLEFT")
    rbTop:SetPoint("TOPRIGHT")
    rbTop:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    local rbBottom = resetTarget:CreateTexture(nil, "BORDER")
    rbBottom:SetHeight(1)
    rbBottom:SetPoint("BOTTOMLEFT")
    rbBottom:SetPoint("BOTTOMRIGHT")
    rbBottom:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    local rbLeft = resetTarget:CreateTexture(nil, "BORDER")
    rbLeft:SetWidth(1)
    rbLeft:SetPoint("TOPLEFT")
    rbLeft:SetPoint("BOTTOMLEFT")
    rbLeft:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    local rbRight = resetTarget:CreateTexture(nil, "BORDER")
    rbRight:SetWidth(1)
    rbRight:SetPoint("TOPRIGHT")
    rbRight:SetPoint("BOTTOMRIGHT")
    rbRight:SetColorTexture(0.49, 0.37, 0.15, 1.0)
    resetTarget.borders = { rbTop, rbBottom, rbLeft, rbRight }

    local resetIcon = resetTarget:CreateTexture(nil, "ARTWORK")
    resetIcon:SetTexture("Interface\\AddOns\\Epithet\\icons\\ui\\epithet-ui-reset-16")
    resetIcon:SetSize(14, 14)
    resetIcon:SetPoint("LEFT", resetTarget, "LEFT", 10, 0)
    resetIcon:SetVertexColor(0.73, 0.57, 0.25, 1.0)
    resetTarget.icon = resetIcon

    local resetText = (T and T.Sans and T.Sans(resetTarget, 12, T.col.gold)) or resetTarget:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    resetText:SetDrawLayer("OVERLAY", 2)
    resetText:SetPoint("LEFT", resetIcon, "RIGHT", 8, 0)
    resetText:SetPoint("RIGHT", resetTarget, "RIGHT", -10, 0)
    resetText:SetJustifyH("LEFT")
    resetText:SetText(L["SOCIAL_TARGET_RESET"] or "Reset target nameplate position")
    resetTarget.text = resetText

    resetTarget:SetScript("OnEnter", function(self_)
        self_.bg:SetColorTexture(0.16, 0.12, 0.07, 1.0)
        self_.icon:SetVertexColor(0.91, 0.78, 0.45, 1.0)
        if self_.text and self_.text.SetTextColor then
            self_.text:SetTextColor(0.96, 0.89, 0.65)
        end
        for _, border in ipairs(self_.borders) do
            border:SetColorTexture(0.91, 0.78, 0.45, 1.0)
        end
    end)
    resetTarget:SetScript("OnLeave", function(self_)
        self_.bg:SetColorTexture(0.11, 0.08, 0.04, 1.0)
        self_.icon:SetVertexColor(0.73, 0.57, 0.25, 1.0)
        if self_.text and self_.text.SetTextColor then
            self_.text:SetTextColor(0.91, 0.78, 0.45)
        end
        for _, border in ipairs(self_.borders) do
            border:SetColorTexture(0.49, 0.37, 0.15, 1.0)
        end
    end)

    resetTarget:SetScript("OnClick", function()
        local profile = GetProfile()
        if profile then
            profile.targetAnchorX = 0
            profile.targetAnchorY = -120
            profile.targetUnlock = false
        end
        if ns.SocialLayer and ns.SocialLayer.ResetTargetFramePosition then
            ns.SocialLayer:ResetTargetFramePosition()
        else
            RefreshAll()
        end
        if Options and Options.Refresh then
            Options:Refresh()
        end
    end)

    local dependentControls = {
        layoutHeading,
        layoutDrop,
        previewHeading,
        previewFrame,
        previewFunnyToggle,
        portraitModeHeading,
        portraitModeDrop,
        portraitModeNote,
        fadeHeading,
        fadeToggle,
        fadeLabel,
        fadeSlider,
        fadeValueText,
        behaviourHeading,
        hideInCombat,
        hideInGroup,
        showSelfTarget,
        selfTargetNote,
        spotNotify,
        positionHeading,
        unlockTarget,
        resetTarget,
    }

    local function SetControlVisible(control, visible)
        if not control then return end
        if visible then
            control:Show()
        else
            control:Hide()
        end
        if control.text then
            if visible then
                control.text:Show()
            else
                control.text:Hide()
            end
        end
    end

    -- Remember the current bottom control for later scroll-bound recalculations.
    local scrollBottomControl

    function UpdateScrollBounds(bottomControl)
        scrollBottomControl = bottomControl or scrollBottomControl
        bottomControl = scrollBottomControl

        local viewportHeight = scrollFrame:GetHeight() or 0
        local top = title and title.GetTop and title:GetTop() or nil
        local bottom = bottomControl and bottomControl.GetBottom and bottomControl:GetBottom() or nil
        local contentHeight

        if top and bottom then
            contentHeight = math.floor((top - bottom) + 40)
            contentHeight = math.max(viewportHeight + 4, contentHeight)
        else
            contentHeight = math.max(viewportHeight + 4, 760)
        end

        canvas:SetHeight(contentHeight)

        local maxScroll = math.max(0, contentHeight - viewportHeight)
        local current = scrollFrame:GetVerticalScroll() or 0
        if current > maxScroll then
            scrollFrame:SetVerticalScroll(maxScroll)
        end
    end

    local function SyncContentWidths()
        SyncScrollWidth()

        local contentWidth = canvas:GetWidth() or 560
        local bodyWidth = math.max(320, math.floor(contentWidth - 32))

        if desc and desc.SetWidth then
            desc:SetWidth(bodyWidth)
        end

        if previewFrame and previewFrame.SetWidth then
            previewFrame:SetWidth(bodyWidth)
        end
    end

    -- Keep width-dependent controls in sync with the current viewport width.
    scrollFrame:SetScript("OnSizeChanged", function()
        SyncContentWidths()
        UpdateScrollBounds(nil)
    end)

    -- Refresh the Title Spotting tab controls from the current profile state.
    local function RefreshControls()
        SyncContentWidths()
        enabled:Refresh()
        local profile = GetProfile()
        local socialEnabled = profile and profile.enabled

        RefreshLayoutDropdown()
        RefreshLayoutPreview()
        previewFunnyToggle:Refresh()
        RefreshPortraitModeDropdown()
        fadeToggle:Refresh()

        local profileFade = GetProfile()
        local fadeDuration = (profileFade and tonumber(profileFade.fadeDuration)) or 4.0
        if fadeDuration < 0.5 then fadeDuration = 0.5 end
        if fadeDuration > 20.0 then fadeDuration = 20.0 end
        if profileFade then profileFade.fadeDuration = fadeDuration end
        -- Guard programmatic slider refresh from writing settings via OnValueChanged.
        Options._refreshingFadeSlider = true
        fadeSlider:SetValue(fadeDuration)
        Options._refreshingFadeSlider = false
        SetFadeValueText(fadeDuration)

        for _, control in ipairs(dependentControls) do
            SetControlVisible(control, socialEnabled)
        end

        local fadeEnabled = socialEnabled and profileFade and profileFade.fadeNameplates
        if fadeEnabled then
            fadeSlider:Enable()
            fadeLabel:SetAlpha(1)
            fadeValueText:SetAlpha(1)
        else
            fadeSlider:Disable()
            fadeLabel:SetAlpha(0.55)
            fadeValueText:SetAlpha(0.55)
        end

        hideInCombat:Refresh()
        hideInGroup:Refresh()
        showSelfTarget:Refresh()
        spotNotify:Refresh()
        unlockTarget:Refresh()
        UpdateScrollBounds(socialEnabled and resetTarget or enabled)
    end

    self.RefreshTitleSpotting = function(self_)
        if not self_ or not self_.titleSpottingPanel then return end
        RefreshControls()
    end

    -- Apply the current dependent-control visibility during the build pass.
    RefreshControls()

    enabled:HookScript("OnClick", function()
        RefreshControls()
        if ns.Settings and ns.Settings.RefreshAchievements then
            ns.Settings:RefreshAchievements()
        end
    end)

    local showSyncTicker

    -- Run short follow-up refresh passes after the panel is shown.
    local function QueuePanelRefreshSync()
        if showSyncTicker or not C_Timer then
            return
        end

        if C_Timer.NewTicker then
            local ticks = 0
            showSyncTicker = C_Timer.NewTicker(0.1, function(ticker)
                ticks = ticks + 1

                if not panel:IsShown() then
                    ticker:Cancel()
                    showSyncTicker = nil
                    return
                end

                RefreshControls()

                local previewSized = (previewFrame:GetWidth() or 0) > 0 and (previewFrame:GetHeight() or 0) > 0

                -- The settings panel parents and anchors this canvas after
                -- showing it, so the OnShow refresh can run against unresolved
                -- rects; these follow-up passes stop once the preview has real
                -- geometry (or after a capped wait, for a client that never
                -- resolves it).
                if (ticks >= 2 and previewSized) or ticks >= 6 then
                    ticker:Cancel()
                    showSyncTicker = nil
                end
            end)
            return
        end

        if C_Timer.After then
            showSyncTicker = true
            C_Timer.After(0, function()
                showSyncTicker = nil
                if panel:IsShown() then
                    RefreshControls()
                end
            end)
        end
    end

    panel:SetScript("OnShow", function()
        if scrollFrame then
            scrollFrame:SetVerticalScroll(0)
        end
        LogPreview("panel OnShow")
        -- Reapply locale fonts to any lazily-built controls on each show.
        if T and T.ApplyLocaleFontToTree then
            T.ApplyLocaleFontToTree(panel)
        end
        RefreshControls()

        -- Run a short follow-up sync after the panel is shown.
        QueuePanelRefreshSync()
    end)

    if BlizzardSettings and BlizzardSettings.RegisterCanvasLayoutSubcategory and parentCategory then
        local sub = BlizzardSettings.RegisterCanvasLayoutSubcategory(parentCategory, panel, panel.name)
        self.titleSpottingCategory = sub
        if sub and sub.SetOnRefresh then
            sub:SetOnRefresh(function()
                RefreshControls()
                QueuePanelRefreshSync()
            end)
        end
    elseif legacyAddCategory then
        panel.parent = "Epithet"
        legacyAddCategory(panel)
    end

    return panel
end

function Options:Init()
    if self.initialized then return end
    self.initialized = true

    -- Build the main Epithet settings page and its sub-tabs.
    local panel = CreateFrame("Frame")
    -- Created hidden; see BuildLanguagePanel for why this is load-bearing.
    panel:Hide()
    panel.name = "Epithet"
    self.panel = panel

    local canvas = BuildChromedCanvas(panel)

    local title = (T and T.Serif and T.Serif(canvas, 20, T.col.goldBright)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["OPTIONS_GENERAL_SECTION"] or "General")

    local desc = (T and T.Sans and T.Sans(canvas, 12, T.col.text)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(520)
    desc:SetJustifyH("LEFT")
    desc:SetText(L["OPTIONS_GENERAL_DESC"] or "Settings that apply across Epithet as a whole.")

    local startupHeading = (T and T.Sans and T.Sans(canvas, 12, T.col.goldDim)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    startupHeading:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
    startupHeading:SetText(L["OPTIONS_STARTUP_SECTION"] or "Startup")

    local whatsNewToggle = MakeCheck(canvas, L["OPTIONS_WHATSNEW_STARTUP_TOGGLE"] or "Show What's New after an update",
        function()
            local p = ns.Epithet and ns.Epithet.db and ns.Epithet.db.profile
            return p == nil or p.showWhatsNewOnStartup ~= false
        end,
        function(value)
            local p = ns.Epithet and ns.Epithet.db and ns.Epithet.db.profile
            if p then p.showWhatsNewOnStartup = value end
        end)
    whatsNewToggle:SetPoint("TOPLEFT", startupHeading, "BOTTOMLEFT", 0, -6)

    local whatsNewNote = (T and T.Sans and T.Sans(canvas, 11, T.col.faint)) or canvas:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    whatsNewNote:SetPoint("TOPLEFT", whatsNewToggle.text, "BOTTOMLEFT", 0, -2)
    whatsNewNote:SetWidth(480)
    whatsNewNote:SetJustifyH("LEFT")
    whatsNewNote:SetText(L["OPTIONS_WHATSNEW_STARTUP_NOTE"] or "Shown once the first time you log in on a new version. You can always reopen it with /epithet whatsnew.")

    -- Refresh the main settings page controls from the current profile state.
    local function RefreshControls()
        whatsNewToggle:Refresh()
    end

    self.RefreshMain = function(self_)
        if not self_ or not self_.panel then return end
        RefreshControls()
    end

    panel:SetScript("OnShow", function()
        RefreshControls()
        if T and T.ApplyLocaleFontToTree then
            T.ApplyLocaleFontToTree(panel)
        end
    end)
    RefreshControls()

    if BlizzardSettings and BlizzardSettings.RegisterCanvasLayoutCategory and BlizzardSettings.RegisterAddOnCategory then
        local category = BlizzardSettings.RegisterCanvasLayoutCategory(panel, panel.name)
        BlizzardSettings.RegisterAddOnCategory(category)
        self.category = category

        if category and category.SetOnRefresh then
            category:SetOnRefresh(RefreshControls)
        end

        -- Register the Epithet sub-tabs under the main category.
        self:BuildAchievementsPanel(category)
        self:BuildTitleSpottingPanel(category)
        self:BuildLanguagePanel(category)
    elseif legacyAddCategory then
        legacyAddCategory(panel)
        -- Register the legacy child panels under "Epithet".
        self:BuildAchievementsPanel(nil)
        self:BuildTitleSpottingPanel(nil)
        self:BuildLanguagePanel(nil)
    end
end

-- Refresh each settings panel that has already been built.
function Options:Refresh()
    if self.RefreshMain then self:RefreshMain() end
    if self.RefreshAchievements then self:RefreshAchievements() end
    if self.RefreshTitleSpotting then self:RefreshTitleSpotting() end
end
