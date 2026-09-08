-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) Grimmsforge

local _, ns = ...
local L = ns.L
local SafeUnitMatches = ns.SafeUnitMatches

local Capture = {}
ns.SpottingCapture = Capture

local C_Timer = C_Timer
local GetTime = GetTime
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitIsPlayer = UnitIsPlayer
local UnitName = UnitName
local UnitClass = UnitClass
local UnitRace = UnitRace
local UnitSex = UnitSex
local UnitFactionGroup = UnitFactionGroup
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local GetCurrentTitle = GetCurrentTitle
local time = time

local RETRY_DELAY = 0.3
local RETRY_WINDOW = 1.0
local GUID_DEBOUNCE_SECONDS = 0.75

function Capture:Init()
    if self.initialized then return end
    self.initialized = true

    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(_, event, ...)
        if self[event] then
            self[event](self, ...)
        end
    end)

    self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:RegisterEvent("UNIT_NAME_UPDATE")

    self.lastGUID = nil
    self.lastAt = 0
    self.retryGUID = nil
    self.retryDeadline = 0
    self.retryTimerPending = false
end

function Capture:IsEnabled()
    if not ns.IsTitleSpottingEnabled then
        return false
    end
    return ns.IsTitleSpottingEnabled()
end

function Capture:IsNotifyEnabled()
    local profile = ns.Epithet and ns.Epithet.db and ns.Epithet.db.profile and ns.Epithet.db.profile.social
    if not profile then
        return false
    end
    return profile.spotNotify ~= false
end

function Capture:ShouldDebounce(guid)
    if not guid then
        return true
    end

    local now = GetTime()
    if self.lastGUID == guid and (now - (self.lastAt or 0)) <= GUID_DEBOUNCE_SECONDS then
        return true
    end

    return false
end

function Capture:MarkProcessed(guid)
    self.lastGUID = guid
    self.lastAt = GetTime()
end

function Capture:QueueRetry(guid)
    if not guid then return end

    self.retryGUID = guid
    self.retryDeadline = GetTime() + RETRY_WINDOW

    if self.retryTimerPending or not C_Timer or not C_Timer.After then
        return
    end

    self.retryTimerPending = true
    C_Timer.After(RETRY_DELAY, function()
        self.retryTimerPending = false
        if not self.retryGUID then return end
        if GetTime() > (self.retryDeadline or 0) then
            self.retryGUID = nil
            return
        end
        if UnitGUID("target") ~= self.retryGUID then
            self.retryGUID = nil
            return
        end
        self:TryCapture("target", true)
    end)
end

function Capture:NotifyNewSpot(titleID)
    if not self:IsNotifyEnabled() then
        return
    end

    local record = ns.TitleData and ns.TitleData.GetRecord and ns.TitleData:GetRecord(titleID)
    local text = record and record.text
    if not text then
        return
    end

    if ns.Print then
        ns.Print((L and L["SPOTTING_NEW_SPOT_FMT"] and string.format(L["SPOTTING_NEW_SPOT_FMT"], text)) or ("Spotted: " .. text))
    end
end

function Capture:TryCapture(unit, fromRetry)
    if unit ~= "target" then return end
    if not self:IsEnabled() then return end

    if not UnitExists or not UnitExists(unit) then return end
    if not UnitIsPlayer or not UnitIsPlayer(unit) then return end
    if SafeUnitMatches and SafeUnitMatches(unit, "player") then return end

    local guid = UnitGUID and UnitGUID(unit)
    if not guid then return end

    if self:ShouldDebounce(guid) then
        return
    end

    local baseName = UnitName and UnitName(unit)
    local displayName = nil
    if unit == "target" and TargetFrameName and TargetFrameName.GetText then
        displayName = TargetFrameName:GetText()
    end
    if not fromRetry and baseName and (not displayName or displayName == "") then
        self:QueueRetry(guid)
        return
    end

    local titleID = nil
    local titleText = nil
    local titleType = nil
    local quality = nil
    local kind = nil
    local cat = nil
    local classTag = nil
    local raceTag = nil
    local sex = nil

    if UnitClass then
        local _, classFile = UnitClass(unit)
        classTag = classFile
    end

    if UnitRace then
        local _, raceFile = UnitRace(unit)
        raceTag = raceFile
    end

    if UnitSex then
        local unitSex = tonumber(UnitSex(unit))
        if unitSex == 2 or unitSex == 3 then
            sex = unitSex
        end
    end

    -- Prefer runtime-resolved IDs first so sightings always map to live TitleData.
    if ns.TitleIndex and ns.TitleIndex.Resolve then
        titleID = ns.TitleIndex:Resolve(unit)
        if titleID and ns.TitleData and ns.TitleData.GetRecord then
            local record = ns.TitleData:GetRecord(titleID)
            if record then
                titleText = record.text
                titleType = record.type
                quality = record.q
                kind = record.kind
                cat = record.cat
            end
        end
    end

    if not titleID and ns.SocialLayer and ns.SocialLayer.GetRecordForUnit then
        local socialRecord = ns.SocialLayer:GetRecordForUnit(unit)

        if socialRecord and socialRecord.titleText and ns.TitleData and ns.TitleData.recordsByLowerText then
            -- O(1) lookup via the lowercase-text index built during Scan(),
            -- instead of a linear scan over every known title record.
            local targetText = tostring(socialRecord.titleText):lower()
            local targetType = socialRecord.type
            local candidates = ns.TitleData.recordsByLowerText[targetText]
            if candidates then
                for _, record in ipairs(candidates) do
                    if record and record.titleID and (not targetType or record.type == targetType) then
                        titleID = record.titleID
                        titleText = record.text
                        titleType = record.type
                        quality = record.q
                        kind = record.kind
                        cat = record.cat
                        break
                    end
                end
            end
        end

        if not titleID and socialRecord and socialRecord.titleID then
            local fallbackID = tonumber(socialRecord.titleID)
            if fallbackID then
                titleID = fallbackID
                titleText = socialRecord.titleText or titleText
                titleType = socialRecord.type or titleType
                quality = socialRecord.q or quality
                kind = socialRecord.kind or kind
                cat = socialRecord.cat or cat
            end
        end
    end

    if not titleID then
        if not fromRetry and baseName and (not displayName or displayName == "") then
            self:QueueRetry(guid)
        end
        return
    end

    local myTitleID = GetCurrentTitle and tonumber(GetCurrentTitle()) or nil
    if myTitleID and myTitleID == titleID then
        local db = ns.EnsureSpottingRootDB and ns.EnsureSpottingRootDB()
        if db and not db.spottingEvents.twinsies then
            db.spottingEvents.twinsies = {
                at = time(),
                titleID = titleID,
            }
        end
    end

    self.retryGUID = nil
    self:MarkProcessed(guid)

    local isNew = ns.SpottingLog and ns.SpottingLog.Record and ns.SpottingLog:Record(titleID, unit, {
        titleText = titleText,
        titleType = titleType,
        quality = quality,
        kind = kind,
        cat = cat,
        classTag = classTag,
        raceTag = raceTag,
        sex = sex,
    })

    local db = ns.EnsureSpottingRootDB and ns.EnsureSpottingRootDB()
    if db and db.spottingEvents then
        if not db.spottingEvents.beyond_the_grave and UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
            db.spottingEvents.beyond_the_grave = {
                at = time(),
                titleID = titleID,
            }
        end

        if not db.spottingEvents.know_thy_enemy and UnitFactionGroup then
            local playerFaction = UnitFactionGroup("player")
            local targetFaction = UnitFactionGroup(unit)
            if playerFaction and targetFaction and playerFaction ~= targetFaction then
                db.spottingEvents.know_thy_enemy = {
                    at = time(),
                    titleID = titleID,
                }
            end
        end
    end

    if ns.SpottingAchievements and ns.SpottingAchievements.OnSpotRecorded then
        ns.SpottingAchievements:OnSpotRecorded()
    end

    if isNew then
        self:NotifyNewSpot(titleID)
    end

    if ns.LogbookUI and ns.LogbookUI.OnLogUpdated then
        ns.LogbookUI:OnLogUpdated()
    end
end

function Capture:PLAYER_TARGET_CHANGED()
    self.retryGUID = nil
    self:TryCapture("target", false)
end

function Capture:UNIT_NAME_UPDATE(unit)
    if unit ~= "target" then
        return
    end

    if not self.retryGUID then
        return
    end

    if GetTime() > (self.retryDeadline or 0) then
        self.retryGUID = nil
        return
    end

    if UnitGUID("target") ~= self.retryGUID then
        self.retryGUID = nil
        return
    end

    self:TryCapture("target", true)
end
