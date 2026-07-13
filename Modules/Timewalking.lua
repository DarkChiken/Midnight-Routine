local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local HOLIDAY_TIMEWALKING = {
    1056,
    1063,
    1326,
    1400,
    1404,
    1500,
}

local function CombineQuestIds(...)
    local merged = {}
    for i = 1, select("#", ...) do
        local source = select(i, ...)
        if type(source) == "table" then
            for _, questId in ipairs(source) do
                merged[#merged + 1] = questId
            end
        end
    end
    return merged
end

local TIMEWALKING_DUNGEON_QUESTS = {
    burning = {
        current = { 93608, 83363 },
        compat = { 39020, 40753 },
        fallbackName = "A Burning Path Through Time",
    },
    wrath = {
        current = { 83365 },
        compat = { 39021, 40173 },
        fallbackName = "A Frozen Path Through Time",
    },
    cataclysm = {
        current = { 93611, 83359 },
        compat = { 40786, 40792 },
        fallbackName = "A Shattered Path Through Time",
    },
    mists = {
        current = { 93612, 83362 },
        compat = { 72725, 62635, 53035, 45799, 40785 },
        fallbackName = "A Shrouded Path Through Time",
    },
    draenor = {
        current = { 93613, 83364 },
        compat = { 45566, 54995 },
        fallbackName = "A Savage Path Through Time",
    },
    legion = {
        current = { 83360 },
        compat = { 62786 },
        fallbackName = "A Fel Path Through Time",
    },
    bfa = {
        current = { 88805 },
        compat = {},
        fallbackName = "A Scarred Path Through Time",
    },
    shadowlands = {
        current = { 93628 },
        compat = { 92649 },
        fallbackName = "A Shadowed Path Through Time",
    },
}

local TIMEWALKING_DUNGEON_WEEKLIES = CombineQuestIds(
    TIMEWALKING_DUNGEON_QUESTS.burning.current,
    TIMEWALKING_DUNGEON_QUESTS.burning.compat,
    TIMEWALKING_DUNGEON_QUESTS.wrath.current,
    TIMEWALKING_DUNGEON_QUESTS.wrath.compat,
    TIMEWALKING_DUNGEON_QUESTS.cataclysm.current,
    TIMEWALKING_DUNGEON_QUESTS.cataclysm.compat,
    TIMEWALKING_DUNGEON_QUESTS.mists.current,
    TIMEWALKING_DUNGEON_QUESTS.mists.compat,
    TIMEWALKING_DUNGEON_QUESTS.draenor.current,
    TIMEWALKING_DUNGEON_QUESTS.draenor.compat,
    TIMEWALKING_DUNGEON_QUESTS.legion.current,
    TIMEWALKING_DUNGEON_QUESTS.legion.compat,
    TIMEWALKING_DUNGEON_QUESTS.bfa.current,
    TIMEWALKING_DUNGEON_QUESTS.shadowlands.current,
    TIMEWALKING_DUNGEON_QUESTS.shadowlands.compat
)

local TIMEWALKING_RAID_WEEKLIES = {
    47523,
    50316,
    57637,
}

local TIMEWALKING_DUNGEON_PICKUP_LOCATION = {
    zone = 2393,
    x = 48.4,
    y = 64.5,
}

local TIMEWALKING_RAID_PICKUP_LOCATIONS = {
    [47523] = { zone = 111, x = 54.6, y = 39.6 },
    [50316] = { zone = 125, x = 51.0, y = 47.6 },
    [57637] = {
        alliance = { zone = 84, x = 76.6, y = 16.6 },
        horde = { zone = 85, x = 52.0, y = 41.6 },
    },
}

local TIMEWALKING_EVENT_HINTS = {
    {
        key = "burning",
        holidayMatches = { "burning", "outland", "twistingnether" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.burning.current, TIMEWALKING_DUNGEON_QUESTS.burning.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.burning.fallbackName,
        raidQuestIds = { 47523 },
        raidFallbackName = "Disturbance Detected: Black Temple",
        hasRaid = true,
    },
    {
        key = "wrath",
        holidayMatches = { "frozen", "northrend", "scourge", "lichking" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.wrath.current, TIMEWALKING_DUNGEON_QUESTS.wrath.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.wrath.fallbackName,
        raidQuestIds = { 50316 },
        raidFallbackName = "Disturbance Detected: Ulduar",
        hasRaid = true,
    },
    {
        key = "cataclysm",
        holidayMatches = { "shattered", "cataclysm", "destroyer" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.cataclysm.current, TIMEWALKING_DUNGEON_QUESTS.cataclysm.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.cataclysm.fallbackName,
        raidQuestIds = { 57637 },
        raidFallbackName = "Disturbance Detected: Firelands",
        hasRaid = true,
    },
    {
        key = "mists",
        holidayMatches = { "mist", "pandaria", "shrouded" },
        auraSpellId = 335151,
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.mists.current, TIMEWALKING_DUNGEON_QUESTS.mists.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.mists.fallbackName,
        hasRaid = false,
    },
    {
        key = "draenor",
        holidayMatches = { "savage", "draenor", "iron" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.draenor.current, TIMEWALKING_DUNGEON_QUESTS.draenor.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.draenor.fallbackName,
        hasRaid = false,
    },
    {
        key = "legion",
        holidayMatches = { "fel", "legion" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.legion.current, TIMEWALKING_DUNGEON_QUESTS.legion.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.legion.fallbackName,
        hasRaid = false,
    },
    {
        key = "bfa",
        holidayMatches = { "scarred", "azeroth" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.bfa.current, TIMEWALKING_DUNGEON_QUESTS.bfa.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.bfa.fallbackName,
        hasRaid = false,
    },
    {
        key = "shadowlands",
        holidayMatches = { "shadowed", "shadowlands" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.shadowlands.current, TIMEWALKING_DUNGEON_QUESTS.shadowlands.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.shadowlands.fallbackName,
        hasRaid = false,
    },
}

local IsQuestCurrentlyActive
local PlayerHasAuraSpell

local function ColorsEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end

    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

local function NormalizeText(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:lower():gsub("[^%a%d]", "")
end

local function IsHolidayActive(holidayId)
    if not C_DateAndTime or not C_DateAndTime.GetHolidayInfo then
        return false
    end

    local info = C_DateAndTime.GetHolidayInfo(holidayId)
    return info ~= nil and info.startTime ~= nil and GetServerTime() >= info.startTime and GetServerTime() <= info.endTime
end

local function IsTimewalkingActive()
    for _, id in ipairs(HOLIDAY_TIMEWALKING) do
        if IsHolidayActive(id) then
            return true
        end
    end

    for _, hint in ipairs(TIMEWALKING_EVENT_HINTS) do
        if PlayerHasAuraSpell and PlayerHasAuraSpell(hint.auraSpellId) then
            return true
        end
    end

    for _, questId in ipairs(TIMEWALKING_DUNGEON_WEEKLIES) do
        if IsQuestCurrentlyActive(questId) then
            return true
        end
    end

    for _, questId in ipairs(TIMEWALKING_RAID_WEEKLIES) do
        if IsQuestCurrentlyActive(questId) then
            return true
        end
    end

    return false
end

local function GetActiveTimewalkingHolidayInfo()
    if not (C_DateAndTime and C_DateAndTime.GetHolidayInfo) then
        return nil, nil
    end

    for _, holidayId in ipairs(HOLIDAY_TIMEWALKING) do
        local info = C_DateAndTime.GetHolidayInfo(holidayId)
        if info and info.startTime and info.endTime then
            local now = GetServerTime()
            if now >= info.startTime and now <= info.endTime then
                return holidayId, info
            end
        end
    end

    return nil, nil
end

IsQuestCurrentlyActive = function(questId)
    if not questId then
        return false
    end

    if C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questId) then
        return true
    end

    if C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questId) then
        if C_TaskQuest and C_TaskQuest.GetQuestTimeLeftSeconds then
            local timeLeft = C_TaskQuest.GetQuestTimeLeftSeconds(questId)
            if timeLeft and timeLeft > 0 then
                return true
            end
        end
    end

    if MR.IsQuestOfferVisible and MR:IsQuestOfferVisible(questId) then
        return true
    end

    if GetQuestID and GetQuestID() == questId then
        return true
    end

    return false
end

PlayerHasAuraSpell = function(spellId)
    if not spellId then
        return false
    end

    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        return C_UnitAuras.GetPlayerAuraBySpellID(spellId) ~= nil
    end

    if AuraUtil and AuraUtil.FindAuraByName and GetSpellInfo then
        local spellName = GetSpellInfo(spellId)
        if spellName and spellName ~= "" then
            return AuraUtil.FindAuraByName(spellName, "player", "HELPFUL") ~= nil
        end
    end

    return false
end

local function GetActiveTimewalkingEventHint()
    local _, holidayInfo = GetActiveTimewalkingHolidayInfo()
    local holidayName = NormalizeText(holidayInfo and holidayInfo.name)

    if holidayName ~= "" then
        for _, hint in ipairs(TIMEWALKING_EVENT_HINTS) do
            for _, match in ipairs(hint.holidayMatches or {}) do
                if holidayName:find(NormalizeText(match), 1, true) then
                    return hint
                end
            end
        end
    end

    for _, hint in ipairs(TIMEWALKING_EVENT_HINTS) do
        if PlayerHasAuraSpell(hint.auraSpellId) then
            return hint
        end
    end

    return nil
end

local function ClearWaypoint(row)
    if type(row) ~= "table" then
        return
    end

    row.zone = nil
    row.x = nil
    row.y = nil
    row.waypointTitle = nil
end

local function ApplyWaypoint(row, location)
    if type(row) ~= "table" then
        return
    end

    if type(location) ~= "table" or not location.zone or not location.x or not location.y then
        ClearWaypoint(row)
        return
    end

    row.zone = location.zone
    row.x = location.x
    row.y = location.y
    row.waypointTitle = location.title or row.label
end

local function GetRaidPickupLocation(questId)
    local location = TIMEWALKING_RAID_PICKUP_LOCATIONS[questId]
    if type(location) ~= "table" then
        return nil
    end

    if location.zone then
        return location
    end

    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Alliance" then
        return location.alliance
    end

    return location.horde
end

local function GetLocalizedDungeonPickupNote()
    local npcName = L["TW_NPC_Aethas"] or "Archmage Aethas Sunreaver"
    local pattern = L["TW_DungeonPickup_Aethas"] or "Pick up the weekly from %s in Silvermoon City, or use the Adventure Journal."
    return string.format(pattern, npcName)
end

local function GetLocalizedRaidPickupNote(questId)
    local npcName = L["TW_NPC_Vormu"] or "Vormu"
    if questId == 47523 then
        local pattern = L["TW_RaidPickup_BlackTemple"] or "Pick up the raid quest from %s in Shattrath City."
        return string.format(pattern, npcName)
    end
    if questId == 50316 then
        local pattern = L["TW_RaidPickup_Ulduar"] or "Pick up the raid quest from %s in Dalaran."
        return string.format(pattern, npcName)
    end
    if questId == 57637 then
        local pattern = L["TW_RaidPickup_Firelands"] or "Pick up the raid quest from %s in Orgrimmar or Stormwind."
        return string.format(pattern, npcName)
    end
    return L["TW_Raid_Note"] or "Complete the Timewalking raid quest available this week."
end

local function UpdateTimewalkingQuestRow(progressBucket, row, questIds, storagePrefix, defaultNote, emptyText, eventHint)
    if type(progressBucket) ~= "table" or type(row) ~= "table" or type(questIds) ~= "table" then
        return false
    end

    local activeQuestId, activeQuestName
    local completedQuestId, completedQuestName
    local rowNote = defaultNote
    local storedQuestId = progressBucket[storagePrefix .. "_active_quest"]
    local storedQuestName = progressBucket[storagePrefix .. "_active_name"]
    local prevValue = tonumber(progressBucket[row.key]) or 0
    local prevCompletedQuestId = progressBucket[storagePrefix .. "_completed_quest"]
    local prevCompletedQuestName = progressBucket[storagePrefix .. "_completed_name"]
    local prevVisible = tonumber(progressBucket[storagePrefix .. "_visible"]) or 0
    local prevCountText = row.countText
    local prevCountColor = row.countColor and { row.countColor[1], row.countColor[2], row.countColor[3] } or nil
    local prevNote = row.note
    local prevZone = row.zone
    local prevX = row.x
    local prevY = row.y
    local prevWaypointTitle = row.waypointTitle

    for _, questId in ipairs(questIds) do
        if not activeQuestId and IsQuestCurrentlyActive(questId) then
            activeQuestId = questId
            if storedQuestId == questId and storedQuestName then
                activeQuestName = storedQuestName
            else
                activeQuestName = MR:GetQuestName(questId)
            end
        end
        if not completedQuestId and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questId) then
            completedQuestId = questId
            if prevCompletedQuestId == questId and prevCompletedQuestName then
                completedQuestName = prevCompletedQuestName
            else
                completedQuestName = MR:GetQuestName(questId)
            end
        end
    end

    if not activeQuestId and eventHint and storagePrefix == "tw_dungeon" and eventHint.dungeonQuestIds then
        for _, questId in ipairs(eventHint.dungeonQuestIds) do
            if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questId) then
                completedQuestId = completedQuestId or questId
                completedQuestName = completedQuestName or MR:GetQuestName(questId, eventHint.dungeonFallbackName)
                break
            end
        end

        activeQuestId = eventHint.dungeonQuestIds[1]
        activeQuestName = MR:GetQuestName(activeQuestId, eventHint.dungeonFallbackName)
    elseif not activeQuestId and eventHint and storagePrefix == "tw_raid" and eventHint.hasRaid and eventHint.raidQuestIds then
        for _, questId in ipairs(eventHint.raidQuestIds) do
            if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questId) then
                completedQuestId = completedQuestId or questId
                completedQuestName = completedQuestName or MR:GetQuestName(questId, eventHint.raidFallbackName)
                break
            end
        end

        activeQuestId = eventHint.raidQuestIds[1]
        activeQuestName = MR:GetQuestName(activeQuestId, eventHint.raidFallbackName)
    elseif not activeQuestId and eventHint and storagePrefix == "tw_raid" and eventHint.hasRaid == false then
        progressBucket[storagePrefix .. "_visible"] = 0
    end

    if storagePrefix == "tw_dungeon" and eventHint then
        rowNote = GetLocalizedDungeonPickupNote()
    elseif storagePrefix == "tw_raid" and eventHint then
        if eventHint.hasRaid == false then
            rowNote = L["TW_Raid_NotAvailable_Mists"] or "There is no Timewalking raid quest during Mists of Pandaria Timewalking."
        else
            rowNote = GetLocalizedRaidPickupNote(activeQuestId or completedQuestId or storedQuestId)
        end
    end

    if activeQuestId then
        progressBucket[storagePrefix .. "_active_quest"] = activeQuestId
        progressBucket[storagePrefix .. "_active_name"] = activeQuestName
        storedQuestId = activeQuestId
        storedQuestName = activeQuestName
    end

    local isDone = completedQuestId ~= nil
    if not isDone and storedQuestId and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(storedQuestId) then
        completedQuestId = storedQuestId
        completedQuestName = MR:GetQuestName(storedQuestId, storedQuestName)
        isDone = true
    end

    progressBucket[row.key] = isDone and 1 or 0
    progressBucket[storagePrefix .. "_completed_quest"] = completedQuestId
    progressBucket[storagePrefix .. "_completed_name"] = completedQuestName
    progressBucket[storagePrefix .. "_visible"] = (activeQuestId or completedQuestId or storedQuestId) and 1 or 0

    if isDone then
        row.countText = completedQuestName or (L["Done"] or "Done")
        row.countColor = { 0.4, 0.85, 0.4 }
        ClearWaypoint(row)
    elseif activeQuestId then
        row.countText = activeQuestName or (L["Weekly_SA_Count_ActiveSingle"] or "Active")
        row.countColor = { 1, 0.9, 0.3 }
        if storagePrefix == "tw_dungeon" then
            ApplyWaypoint(row, {
                zone = TIMEWALKING_DUNGEON_PICKUP_LOCATION.zone,
                x = TIMEWALKING_DUNGEON_PICKUP_LOCATION.x,
                y = TIMEWALKING_DUNGEON_PICKUP_LOCATION.y,
                title = L["TW_NPC_Aethas"] or "Archmage Aethas Sunreaver",
            })
        elseif storagePrefix == "tw_raid" then
            local raidLocation = GetRaidPickupLocation(activeQuestId)
            if raidLocation then
                raidLocation = {
                    zone = raidLocation.zone,
                    x = raidLocation.x,
                    y = raidLocation.y,
                    title = L["TW_NPC_Vormu"] or "Vormu",
                }
            end
            ApplyWaypoint(row, raidLocation)
        else
            ClearWaypoint(row)
        end
    elseif emptyText then
        row.countText = emptyText
        row.countColor = { 0.75, 0.78, 0.86 }
        ClearWaypoint(row)
    else
        row.countText = nil
        row.countColor = nil
        ClearWaypoint(row)
    end

    row.note = rowNote
    local changed = prevValue ~= (progressBucket[row.key] or 0)
        or prevCompletedQuestId ~= progressBucket[storagePrefix .. "_completed_quest"]
        or prevCompletedQuestName ~= progressBucket[storagePrefix .. "_completed_name"]
        or prevVisible ~= (progressBucket[storagePrefix .. "_visible"] or 0)
        or prevCountText ~= row.countText
        or not ColorsEqual(prevCountColor, row.countColor)
        or prevNote ~= row.note
        or prevZone ~= row.zone
        or prevX ~= row.x
        or prevY ~= row.y
        or prevWaypointTitle ~= row.waypointTitle

    return isDone or activeQuestId ~= nil, changed
end

MR:RegisterModule({
    key         = "timewalking",
    label       = L["Timewalking"] or "Timewalking",
    labelColor  = "#66ccff",
    icon        = "Interface\\Icons\\Achievement_Quests_Completed_08",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible   = IsTimewalkingActive,
    scanReturnsChanged = true,

    onScan = function(mod)
        local db = MR.db.char.progress
        if not db[mod.key] then
            db[mod.key] = {}
        end

        local eventHint = GetActiveTimewalkingEventHint()
        local changed = false

        for _, row in ipairs(mod.rows) do
            if row.key == "tw_dungeon" then
                local _, rowChanged = UpdateTimewalkingQuestRow(
                    db[mod.key],
                    row,
                    TIMEWALKING_DUNGEON_WEEKLIES,
                    "tw_dungeon",
                    L["TW_Weekly_Note"] or "Complete the Timewalking dungeon weekly for the cache.",
                    nil,
                    eventHint
                )
                changed = changed or rowChanged
            elseif row.key == "tw_raid" then
                local _, rowChanged = UpdateTimewalkingQuestRow(
                    db[mod.key],
                    row,
                    TIMEWALKING_RAID_WEEKLIES,
                    "tw_raid",
                    L["TW_Raid_Note"] or "Complete the Timewalking raid quest available this week.",
                    L["TW_Raid_NotActive"] or "Not up this week",
                    eventHint
                )
                changed = changed or rowChanged
            end
        end

        return changed
    end,

    rows = {
        {
            key         = "tw_dungeon",
            label       = L["TW_DungeonTitle"] or "Dungeon",
            max         = 1,
            note        = L["TW_Weekly_Note"],
            autoTracked = true,
            hideCoordText = true,
        },
        {
            key         = "tw_raid",
            label       = L["Raid"] or "Raid",
            max         = 1,
            note        = L["TW_Raid_Note"] or "Complete the Timewalking raid quest available this week.",
            autoTracked = true,
            hideCoordText = true,
        },
    },
})
