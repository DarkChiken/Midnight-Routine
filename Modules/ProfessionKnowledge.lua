local _, ns = ...
local MR = ns.MR

local FONT_HEADERS = ns.FONT_HEADERS
local FONT_ROWS = ns.FONT_ROWS
local StyledFrame = ns.StyledFrame
local RestoreManagedFramePos = ns.RestoreManagedFramePos
local SaveManagedFramePos = ns.SaveManagedFramePos
local SyncManagedFramePos = ns.SyncManagedFramePos
local AnimateManagedFrameHeight = ns.AnimateManagedFrameHeight
local IsManagedHeaderBottom = ns.IsManagedHeaderBottom
local LeftAccent = ns.LeftAccent
local TopAccent = ns.TopAccent
local TitleBar = ns.TitleBar
local CloseButton = ns.CloseButton
local HeaderIconButton = ns.HeaderIconButton
local HeaderToggleButton = ns.HeaderToggleButton
local MakeBackdrop = ns.MakeBackdrop
local OptionsGap = ns.OptionsGap
local OptionsDivider = ns.OptionsDivider
local OptionsSectionLabel = ns.OptionsSectionLabel
local OptionsCheckbox = ns.OptionsCheckbox
local OptionsSlider = ns.OptionsSlider
local OptionsBtn = ns.OptionsBtn
local OptionsColorSwatch = ns.OptionsColorSwatch
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local gatheringLocationsFrame
local gatheringMinimized = false
local gatheringCfgFrame
local PopulateGatheringConfig
local RebuildGatheringLocationsFrame

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
        return
    end

    FONT_HEADERS = ns.FONT_HEADERS or FONT_HEADERS
    FONT_ROWS = ns.FONT_ROWS or FONT_ROWS
end

local function GetFontFlags()
    if ns.GetFontFlags then
        local flags = ns.GetFontFlags(MR.GetActiveMediaSettings and MR:GetActiveMediaSettings() or (MR.db and MR.db.profile))
        if flags ~= nil then
            return flags
        end
    end

    return "OUTLINE"
end

local DEFAULT_W = 350
local DEFAULT_H = 450
local MIN_W = 250
local MAX_W = 700
local MIN_H = 150
local MAX_H = 800
local TITLE_H = 22


local function IsLegacyEntryVisible(entry)
    if entry.kind == "darkmoon" then
        return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() or false
    end
    return true
end

local PROFESSION_ICONS = {
    alchemy = "Interface\\Icons\\Trade_Alchemy",
    blacksmithing = "Interface\\Icons\\Trade_BlackSmithing",
    enchanting = "Interface\\Icons\\Trade_Engraving",
    engineering = "Interface\\Icons\\Trade_Engineering",
    herbalism = "Interface\\Icons\\Trade_Herbalism",
    inscription = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    jewelcrafting = "Interface\\Icons\\INV_Misc_Gem_01",
    leatherworking = "Interface\\Icons\\Trade_LeatherWorking",
    mining = "Interface\\Icons\\Trade_Mining",
    skinning = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    tailoring = "Interface\\Icons\\Trade_Tailoring",
}

local PROFESSION_CATCHUP_CURRENCIES = {
    [2906] = 3189,
    [2907] = 3199,
    [2909] = 3198,
    [2910] = 3197,
    [2912] = 3196,
    [2913] = 3195,
    [2914] = 3194,
    [2915] = 3193,
    [2916] = 3192,
    [2917] = 3191,
    [2918] = 3190,
}

local DRAGONFLIGHT_CATCHUP_ITEM_ID = 191784

local LEGACY_EXPANSIONS = ns.LegacyExpansions

local KNOWLEDGE_EXPANSION_MIDNIGHT_KEY = "midnight"

local function GetKnowledgeExpansionOptions()
    local options = { { key = KNOWLEDGE_EXPANSION_MIDNIGHT_KEY, label = L["Expansion_Midnight"] or "Midnight" } }
    for _, expansion in ipairs(LEGACY_EXPANSIONS) do
        options[#options + 1] = { key = expansion.key, label = expansion.label }
    end
    return options
end

local function GetSelectedKnowledgeExpansion()
    local key = MR.db and MR.db.profile and MR.db.profile.gatheringSelectedKnowledgeExpansion
    if key == KNOWLEDGE_EXPANSION_MIDNIGHT_KEY then
        return key
    end
    for _, expansion in ipairs(LEGACY_EXPANSIONS) do
        if expansion.key == key then
            return key
        end
    end
    return KNOWLEDGE_EXPANSION_MIDNIGHT_KEY
end

local function SetSelectedKnowledgeExpansion(key)
    if not (MR.db and MR.db.profile) then
        return
    end
    MR.db.profile.gatheringSelectedKnowledgeExpansion = key
    RebuildGatheringLocationsFrame()
end

local ENTRY_FALLBACK_ICONS = {
    treasure = "Interface\\Icons\\INV_Misc_Map_01",
    study = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    weeklyQuest = "Interface\\Icons\\INV_Misc_Note_01",
    weeklyDrop = "Interface\\Icons\\INV_Box_01",
    darkmoon = "Interface\\Icons\\INV_Misc_Ticket_Tarot_BlueDragon",
    reference = "Interface\\Icons\\INV_Misc_Book_09",
}

local PROFESSIONS = ns.MidnightProfessions

local function ShowInKnowledgeTracker(section)
    return section and (section.key == "discoveries" or section.key == "studies")
end

local function HasProfessionLearned(skillLine)
    if MR.db and MR.db.char and MR.db.char.knownProfessionLines and MR.db.char.knownProfessionLines[skillLine] then
        return true
    end

    if MR.playerProfessions and MR.playerProfessions[skillLine] then
        if MR.db and MR.db.char then
            MR.db.char.knownProfessionLines = MR.db.char.knownProfessionLines or {}
            MR.db.char.knownProfessionLines[skillLine] = true
        end
        return true
    end

    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLine)
        if info and (info.skillLevel or 0) > 0 then
            if MR.db and MR.db.char then
                MR.db.char.knownProfessionLines = MR.db.char.knownProfessionLines or {}
                MR.db.char.knownProfessionLines[skillLine] = true
            end
            return true
        end
    end

    return false
end

ns.HasProfessionLearned = HasProfessionLearned

local function QuestIDs(entry)
    if entry.questIDs then return entry.questIDs end
    if entry.questID then return { entry.questID } end
    return {}
end

local function Required(entry)
    if entry.mode == "count" then return entry.required or #QuestIDs(entry) end
    return 1
end

local function IsSpellOnCooldown(spellID)
    if not spellID then
        return false
    end

    local startTime, duration = 0, 0
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            startTime = info.startTime or 0
            duration = info.duration or 0
        end
    end

    if duration <= 1.5 and GetSpellCooldown then
        local legacyStart, legacyDuration = GetSpellCooldown(spellID)
        startTime = legacyStart or startTime
        duration = legacyDuration or duration
    end

    if duration <= 1.5 then
        return false
    end

    return ((startTime or 0) + duration) > GetTime()
end

ns.IsSpellOnCooldown = IsSpellOnCooldown

local function Completed(entry)
    if entry.spellID then
        return IsSpellOnCooldown(entry.spellID) and 1 or 0
    end

    local total = 0
    for _, questID in ipairs(QuestIDs(entry)) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then total = total + 1 end
    end
    return total
end

local function Progress(entry)
    local completed = Completed(entry)
    local required = Required(entry)
    if entry.mode == "count" then
        return math.min(completed, required), required
    end
    if completed > 0 then return 1, 1 end
    return 0, 1
end

local function IsDone(entry)
    local current, required = Progress(entry)
    return current >= required
end

local function KPDone(entry)
    local current = Progress(entry)
    if entry.mode == "count" then return (entry.kp or 0) * current end
    return current > 0 and (entry.kp or 0) or 0
end

local function KPTotal(entry)
    return (entry.mode == "count" and Required(entry) or 1) * (entry.kp or 0)
end

local function EntryName(entry)
    if entry.itemID then
        local name = GetItemInfo(entry.itemID)
        if name and name ~= "" then return name end
    end
    return entry.label or "|cffaaaaaa...|r"
end

local function ProgressText(entry)
    local current, required = Progress(entry)
    if required > 1 then return current .. "/" .. required end
    return current > 0 and (L["Done"] or "Done") or L["ProfKnowledge_StatusPending"]
end

local function SectionStats(section)
    local done, total, kpDone, kpTotal = 0, 0, 0, 0
    for _, entry in ipairs(section.entries) do
        if IsLegacyEntryVisible(entry) then
            total = total + 1
            if IsDone(entry) then done = done + 1 end
            kpDone = kpDone + KPDone(entry)
            kpTotal = kpTotal + KPTotal(entry)
        end
    end
    return done, total, kpDone, kpTotal
end

local function ProfessionStats(profession)
    local done, total, kpDone, kpTotal = 0, 0, 0, 0
    for _, section in ipairs(profession.sections) do
        if ShowInKnowledgeTracker(section) then
            local sd, st, skd, skt = SectionStats(section)
            done = done + sd
            total = total + st
            kpDone = kpDone + skd
            kpTotal = kpTotal + skt
        end
    end
    return done, total, kpDone, kpTotal
end

local function ProfessionWeeklyStats(profession)
    local kpDone, kpTotal = 0, 0
    for _, section in ipairs(profession.sections) do
        if not ShowInKnowledgeTracker(section) then
            for _, entry in ipairs(section.entries) do
                if IsLegacyEntryVisible(entry) then
                    kpDone = kpDone + KPDone(entry)
                    kpTotal = kpTotal + KPTotal(entry)
                end
            end
        end
    end
    return kpDone, kpTotal
end

local function GetProfessionSkillSummary(skillLineID)
    if not (C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID) then
        return nil
    end

    local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
    if not info then
        return nil
    end

    local skill = info.skillLevel or 0
    local maxSkill = info.maxSkillLevel or 0
    if skill <= 0 or maxSkill <= 0 then
        return nil
    end

    local bonus = info.bonusSkillLevel or info.bonusSkill or 0
    if bonus > 0 then
        return string.format("%d/%d +%d", skill, maxSkill, bonus)
    end

    return string.format("%d/%d", skill, maxSkill)
end

local function GetProfessionCatchupAmount(skillLineID)
    local currencyID = PROFESSION_CATCHUP_CURRENCIES[skillLineID]
    if not (currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return 0
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return 0
    end

    local maxQuantity = info.maxQuantity or 0
    local quantity = info.quantity or 0
    if maxQuantity > 0 then
        return math.max(maxQuantity - quantity, 0)
    end

    return quantity
end

local PROFESSION_TASK_CATEGORY_ORDER = {
    "quests",
    "drops",
    "treatises",
    "darkmoon",
    "catchup",
    "other",
}

local PROFESSION_TASK_CATEGORY_LABELS = {
    quests = "Weekly Quests",
    drops = "Weekly Drops",
    treatises = "Treatises",
    darkmoon = "Darkmoon Faire",
    catchup = "Catch-Up",
    other = "Other Tasks",
}

local function GetProfessionKnowledgeTaskCategories()
    local db = MR.db and MR.db.profile or {}
    db.professionKnowledgeTaskCategories = db.professionKnowledgeTaskCategories or {}
    local categories = db.professionKnowledgeTaskCategories
    for _, key in ipairs(PROFESSION_TASK_CATEGORY_ORDER) do
        if categories[key] == nil then
            categories[key] = true
        end
    end
    return categories
end

local function IsProfessionTaskCategoryEnabled(category)
    return GetProfessionKnowledgeTaskCategories()[category or "other"] ~= false
end

local function GetProfessionTaskCategory(row)
    local key = row and row.key or ""
    if key:find("treatise") then
        return "treatises"
    elseif key:find("dmf") then
        return "darkmoon"
    elseif key == "prof_catchup" then
        return "catchup"
    elseif key:find("drop") or key:find("rock") or key:find("plumes") or key:find("bone") or key:find("essence") or key:find("shard") or key:find("tail") or key:find("nodule") then
        return "drops"
    elseif key:find("quest") or key:find("notebook") then
        return "quests"
    end

    return "other"
end

local function GetProfessionTaskModules(profession)
    local modules = {}
    if not (profession and profession.skillLine and MR.modules) then
        return modules
    end

    for _, mod in ipairs(MR.modules) do
        if mod.profSkillLine == profession.skillLine and MR:IsModuleEnabled(mod.key) then
            local modVisible = not mod.isVisible or mod:isVisible()
            if modVisible then
                modules[#modules + 1] = mod
            end
        end
    end

    table.sort(modules, function(a, b)
        return (a.order or 9999) < (b.order or 9999)
    end)
    return modules
end

local function GetProfessionTaskProgress(mod, row)
    local current = MR:GetProgress(mod.key, row.key) or 0
    local max = tonumber(row.max)
    if max and max > 0 and not row.noMax then
        return math.min(current, max), max, current >= max
    end

    return current, nil, current and current > 0
end

local function GetProfessionTaskProgressText(mod, row)
    local current, max, done = GetProfessionTaskProgress(mod, row)
    if max then
        return string.format("%d/%d", current or 0, max)
    end

    if row.max == 0 or row.noMax then
        return tostring(current or 0)
    end

    return done and (L["Done"] or "Done") or (L["ProfKnowledge_StatusPending"] or "Pending")
end

local function GetProfessionTaskRows(profession)
    local rows = {}
    local doneCount, totalCount = 0, 0
    local db = MR.db and MR.db.profile or {}

    for _, mod in ipairs(GetProfessionTaskModules(profession)) do
        for _, row in ipairs(mod.rows or {}) do
            local rowVisible = not row.isVisible or row.isVisible()
            local category = GetProfessionTaskCategory(row)
            if rowVisible and IsProfessionTaskCategoryEnabled(category) then
                local current, max, done = GetProfessionTaskProgress(mod, row)
                if not (done and db.gatheringHideCompleted) then
                    rows[#rows + 1] = {
                        mod = mod,
                        row = row,
                        category = category,
                        done = done,
                        current = current,
                        max = max,
                    }
                end
                if max then
                    totalCount = totalCount + 1
                    if done then doneCount = doneCount + 1 end
                end
            end
        end
    end

    return rows, doneCount, totalCount
end

local function GetCurrencyAmount(currencyID)
    if not (currencyID and currencyID > 0 and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return 0
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return 0
    end

    local maxQuantity = info.maxQuantity or 0
    local quantity = info.quantity or 0
    if maxQuantity > 0 then
        return math.max(maxQuantity - quantity, 0)
    end

    return quantity
end

local function GetDragonShardCount()
    if not (C_Item and C_Item.GetItemCount) then
        return 0
    end

    return C_Item.GetItemCount(DRAGONFLIGHT_CATCHUP_ITEM_ID, false, false, true) or 0
end

local function LegacyProfessionWeeklyStats(profession)
    local done, total, kpDone, kpTotal = 0, 0, 0, 0
    for _, entry in ipairs(profession.weekly or {}) do
        if IsLegacyEntryVisible(entry) then
            total = total + 1
            if IsDone(entry) then done = done + 1 end
            kpDone = kpDone + KPDone(entry)
            kpTotal = kpTotal + KPTotal(entry)
        end
    end
    return done, total, kpDone, kpTotal
end

local function GetEntryIcon(entry)
    if entry.itemID and C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(entry.itemID)
        if icon then
            return icon
        end
    end

    if entry.itemID then
        local icon = GetItemIcon(entry.itemID)
        if icon then
            return icon
        end
    end

    return ENTRY_FALLBACK_ICONS[entry.kind] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local watchedItemIDs = {}
for _, profession in ipairs(PROFESSIONS) do
    for _, section in ipairs(profession.sections) do
        for _, entry in ipairs(section.entries) do
            if entry.itemID then watchedItemIDs[entry.itemID] = true end
        end
    end
end

local function AllWatchedItemsCached()
    for itemID in pairs(watchedItemIDs) do
        local name = GetItemInfo(itemID)
        if not name or name == "" then return false end
    end
    return true
end

local waypointAlt = {}
local zoneNameCache = {}

local function GetGatheringZoneName(mapID)
    if not mapID then return L["ProfKnowledge_NoWaypoint"] end
    if zoneNameCache[mapID] then return zoneNameCache[mapID] end
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    local zoneName = (info and info.name) or ("Map " .. tostring(mapID))
    zoneNameCache[mapID] = zoneName
    return zoneName
end

local function SetGatheringWaypoint(entry)
    local mapID = entry and entry.zone
    local x = entry and entry.x and (entry.x / 100)
    local y = entry and entry.y and (entry.y / 100)
    local tomTom = _G and rawget(_G, "TomTom")
    if not mapID or not x or not y then return false, "Invalid coordinates" end

    if tomTom and tomTom.AddWaypoint then
        local ok = pcall(function()
            tomTom:AddWaypoint(mapID, x, y, { title = EntryName(entry), persistent = false, minimap = true, world = true })
        end)
        if ok then return true, "TomTom" end
    end

    if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint then
        local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        if point then
            C_Map.SetUserWaypoint(point)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
            return true, "Blizzard"
        end
    end

    return false, "No waypoint API available"
end

local function RescanKnownProfessionLines()
    local changed = false
    for _, expansion in ipairs(LEGACY_EXPANSIONS) do
        for _, profession in ipairs(expansion.professions) do
            local wasKnown = MR.db and MR.db.char and MR.db.char.knownProfessionLines and MR.db.char.knownProfessionLines[profession.skillLine]
            if not wasKnown and HasProfessionLearned(profession.skillLine) then
                changed = true
            end
        end
    end
    return changed
end

local itemCacheFrame = CreateFrame("Frame")
itemCacheFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemCacheFrame:RegisterEvent("QUEST_TURNED_IN")
itemCacheFrame:RegisterEvent("QUEST_LOG_UPDATE")
itemCacheFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
itemCacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
itemCacheFrame:RegisterEvent("TRADE_SKILL_SHOW")
itemCacheFrame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
itemCacheFrame:SetScript("OnEvent", function(self, event, itemID)
    if event == "GET_ITEM_INFO_RECEIVED" then
        if not watchedItemIDs[itemID] then return end
        if AllWatchedItemsCached() then self:UnregisterEvent("GET_ITEM_INFO_RECEIVED") end
    end
    if event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
        if RescanKnownProfessionLines() and MR.RequestScan then
            MR:RequestScan(1)
        end
    end
    if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then RebuildGatheringLocationsFrame() end
end)

local function GetProfessionColor(professionKey)
    local colors = MR.db.profile.gatheringProfColors or {}
    local saved = colors[professionKey]
    if saved then return saved[1], saved[2], saved[3] end
    for _, profession in ipairs(PROFESSIONS) do
        if profession.key == professionKey then
            return profession.color[1], profession.color[2], profession.color[3]
        end
    end
    return 1, 1, 1
end

local function MixColor(r, g, b, mix, target)
    target = target or 1
    return r + ((target - r) * mix), g + ((target - g) * mix), b + ((target - b) * mix)
end

local function CreateSummaryChip(parent, x, y, width, height, text, r, g, b, fontSize)
    local chip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    chip:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    chip:SetSize(width, height)
    chip:SetBackdrop(MakeBackdrop())
    chip:SetBackdropColor(r * 0.12, g * 0.12, b * 0.12, 0.90)
    chip:SetBackdropBorderColor(r * 0.55, g * 0.55, b * 0.55, 0.95)

    local glow = chip:CreateTexture(nil, "ARTWORK")
    glow:SetPoint("TOPLEFT", chip, "TOPLEFT", 1, -1)
    glow:SetPoint("BOTTOMRIGHT", chip, "BOTTOMRIGHT", -1, 1)
    glow:SetColorTexture(r * 0.18, g * 0.18, b * 0.18, 0.55)

    local label = chip:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_ROWS, fontSize or 9, GetFontFlags())
    label:SetPoint("CENTER", chip, "CENTER", 0, 0)
    label:SetText(text)
    label:SetTextColor(MixColor(r, g, b, 0.55))

    return chip
end

local function GetVisibleKnowledgeTotals()
    local professions, sourcesDone, sourcesTotal, kpDone, kpTotal = 0, 0, 0, 0, 0
    for _, profession in ipairs(PROFESSIONS) do
        if HasProfessionLearned(profession.skillLine) then
            professions = professions + 1
            local pd, pt, kd, kt = ProfessionStats(profession)
            sourcesDone = sourcesDone + pd
            sourcesTotal = sourcesTotal + pt
            kpDone = kpDone + kd
            kpTotal = kpTotal + kt
        end
    end
    return professions, sourcesDone, sourcesTotal, kpDone, kpTotal
end

local function StripInlineColor(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    return text
end

local function IsProfessionCollapsed(professionKey)
    local profile = MR.db and MR.db.profile
    local saved = profile and profile.gatheringCollapsedProfessions and profile.gatheringCollapsedProfessions[professionKey]
    return saved ~= false
end

local function SetProfessionCollapsed(professionKey, collapsed)
    if not (MR.db and MR.db.profile) then
        return
    end

    MR.db.profile.gatheringCollapsedProfessions = MR.db.profile.gatheringCollapsedProfessions or {}
    if collapsed then
        MR.db.profile.gatheringCollapsedProfessions[professionKey] = nil
    else
        MR.db.profile.gatheringCollapsedProfessions[professionKey] = false
    end
end

local function GetLegacyProfessionStateKey(expansionKey, professionKey)
    return tostring(expansionKey or "legacy") .. ":" .. tostring(professionKey or "")
end

local function IsLegacyProfessionCollapsed(expansionKey, professionKey)
    local profile = MR.db and MR.db.profile
    local states = profile and profile.gatheringCollapsedLegacyProfessions
    local key = GetLegacyProfessionStateKey(expansionKey, professionKey)
    return not (states and states[key] == false)
end

local function SetLegacyProfessionCollapsed(expansionKey, professionKey, collapsed)
    if not (MR.db and MR.db.profile) then
        return
    end

    MR.db.profile.gatheringCollapsedLegacyProfessions = MR.db.profile.gatheringCollapsedLegacyProfessions or {}
    local key = GetLegacyProfessionStateKey(expansionKey, professionKey)
    if collapsed then
        MR.db.profile.gatheringCollapsedLegacyProfessions[key] = nil
    else
        MR.db.profile.gatheringCollapsedLegacyProfessions[key] = false
    end
end

local function LegacyEntryLabel(entry)
    local name = EntryName(entry)
    if name and name ~= "|cffaaaaaa...|r" then
        return name
    end
    return entry.note or entry.label or L["ProfKnowledge_WeeklyDrop"] or "Weekly source"
end

local function ApplyGatheringFrameTheme(frame, opts)
    if not frame then
        return
    end

    opts = opts or {}
    local alpha = opts.alpha or 1
    local bg = opts.bg or { 0.03, 0.05, 0.09, 0.97 * alpha }
    local border = opts.border or { 0.24, 0.31, 0.42, alpha }
    local accent = opts.accent or { 0.18, 0.78, 0.72 }

    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)

    if not frame._gatheringTopAccent then
        frame._gatheringTopAccent = TopAccent(frame, accent[1], accent[2], accent[3])
    else
        frame._gatheringTopAccent:SetColorTexture(accent[1], accent[2], accent[3], 1)
    end
    frame.topAccent = frame._gatheringTopAccent
    frame.topAccent:SetAlpha(alpha)

    if not frame._gatheringGlow then
        frame._gatheringGlow = frame:CreateTexture(nil, "BACKGROUND")
        frame._gatheringGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame._gatheringGlow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end
    frame._gatheringGlow:SetColorTexture(bg[1], math.min(bg[2] + 0.07, 1), math.min(bg[3] + 0.07, 1), 0.30 * alpha)

    if opts.headerGlow ~= false then
        if not frame._gatheringHeaderGlow then
            frame._gatheringHeaderGlow = frame:CreateTexture(nil, "BORDER")
            frame._gatheringHeaderGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            frame._gatheringHeaderGlow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            frame._gatheringHeaderGlow:SetHeight(opts.headerHeight or 64)
        end
        frame._gatheringHeaderGlow:SetHeight(opts.headerHeight or 64)
        frame._gatheringHeaderGlow:SetColorTexture(accent[1] * 0.45, accent[2] * 0.45, accent[3] * 0.45, 0.22 * alpha)
        frame._gatheringHeaderGlow:Show()
    elseif frame._gatheringHeaderGlow then
        frame._gatheringHeaderGlow:Hide()
    end
end

local function VisibleSortedLegacyEntries(entries)
    local list = {}
    for i, entry in ipairs(entries or {}) do
        if IsLegacyEntryVisible(entry) then
            list[#list + 1] = { entry = entry, index = i, done = IsDone(entry) }
        end
    end
    table.sort(list, function(a, b)
        if a.done ~= b.done then return not a.done end
        return a.index < b.index
    end)
    local result = {}
    for i, item in ipairs(list) do
        result[i] = item.entry
    end
    return result
end

local function RenderLegacyEntryRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, entry)
    local current, required = Progress(entry)
    local done = current >= required
    if done and db.gatheringHideCompleted then return cardY end

    local row = CreateFrame("Button", nil, card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    row:SetSize(cardW - 24, rowHeight + 4)
    row:RegisterForClicks("LeftButtonUp")
    row:SetBackdrop(MakeBackdrop())
    if done then
        row:SetBackdropColor(1, 1, 1, 0.025 * contentAlpha)
        row:SetBackdropBorderColor(0.16, 0.30, 0.22, 0.55 * chromeAlpha)
    else
        row:SetBackdropColor(1, 1, 1, 0.035 * contentAlpha)
        row:SetBackdropBorderColor(0.20, 0.24, 0.28, 0.58 * chromeAlpha)
    end

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(cr, cg, cb, 0)

    local rowIcon = row:CreateTexture(nil, "ARTWORK")
    rowIcon:SetSize(14, 14)
    rowIcon:SetPoint("LEFT", row, "LEFT", 5, 0)
    rowIcon:SetTexture(GetEntryIcon(entry))
    rowIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local dot = row:CreateTexture(nil, "ARTWORK")
    dot:SetSize(6, 6)
    dot:SetPoint("LEFT", rowIcon, "RIGHT", 5, 0)
    if done then
        dot:SetColorTexture(0.26, 0.86, 0.52, 1)
    elseif required > 1 and current > 0 then
        dot:SetColorTexture(0.95, 0.80, 0.25, 1)
    else
        dot:SetColorTexture(cr, cg, cb, 1)
    end

    local waypointIcon
    if entry.zone and entry.x and entry.y then
        waypointIcon = row:CreateTexture(nil, "ARTWORK")
        waypointIcon:SetAtlas("Waypoint-MapPin-Untracked", true)
        waypointIcon:SetSize(14, 14)
        waypointIcon:SetPoint("RIGHT", row, "RIGHT", -72, 0)
        waypointIcon:SetAlpha(0.75)
    end

    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    nameText:SetPoint("LEFT", dot, "RIGHT", 6, 0)
    nameText:SetPoint("RIGHT", row, "RIGHT", waypointIcon and -90 or -74, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetText(LegacyEntryLabel(entry))
    nameText:SetTextColor(done and 0.45 or 0.90, done and 0.45 or 0.90, done and 0.45 or 0.90)

    local statusText = row:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    statusText:SetWidth(62)
    statusText:SetJustifyH("RIGHT")
    if done then
        statusText:SetText(L["Done"] or "Done")
        statusText:SetTextColor(0.32, 0.80, 0.50, 0.95)
    elseif required > 1 then
        statusText:SetText(current .. "/" .. required)
        statusText:SetTextColor(current > 0 and 0.95 or cr, current > 0 and 0.80 or cg, current > 0 and 0.25 or cb, 0.95)
    else
        statusText:SetText("+" .. tostring(entry.kp or 0))
        statusText:SetTextColor(cr, cg, cb, 0.95)
    end

    row:SetScript("OnEnter", function()
        hover:SetColorTexture(cr, cg, cb, 0.12 * accentAlpha)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetText(LegacyEntryLabel(entry), 1, 1, 1)
        GameTooltip:AddLine(string.format(L["ProfKnowledge_KPValue"], KPDone(entry), KPTotal(entry)), 0.80, 0.80, 0.90)
        GameTooltip:AddLine(string.format(L["ProfKnowledge_RowProgress"], current, required), 0.70, 0.90, 1)
        if entry.zone and entry.x and entry.y then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(GetGatheringZoneName(entry.zone), 0.85, 0.85, 0.85)
            GameTooltip:AddLine(string.format(L["Gathering_Coords"], entry.x, entry.y), 0.7, 1, 0.9)
        else
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["ProfKnowledge_NoWaypoint"], 0.65, 0.65, 0.65)
        end
        if entry.note and entry.note ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(entry.note, 0.65, 0.85, 0.95, true)
        end
        GameTooltip:AddLine(" ")
        if done then
            GameTooltip:AddLine(L["Gathering_AlreadyCollected"], 0, 0.8, 0.27)
        elseif entry.zone and entry.x and entry.y then
            GameTooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        hover:SetColorTexture(cr, cg, cb, 0)
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function()
        if not (entry.zone and entry.x and entry.y) then return end
        local ok, source = SetGatheringWaypoint(entry)
        if ok then print(string.format(L["Waypoint_Set"], source, LegacyEntryLabel(entry), entry.x, entry.y)) else print(L["Waypoint_Unavailable"]) end
    end)

    return cardY + rowHeight + 6
end

local function RenderLegacyReferenceRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, cr, cg, cb, entry)
    local row = CreateFrame("Button", nil, card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    row:SetSize(cardW - 24, rowHeight + 4)
    row:RegisterForClicks("LeftButtonUp")
    row:SetBackdrop(MakeBackdrop())
    row:SetBackdropColor(1, 1, 1, 0.035 * contentAlpha)
    row:SetBackdropBorderColor(0.20, 0.24, 0.28, 0.58 * chromeAlpha)

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(cr, cg, cb, 0)

    local rowIcon = row:CreateTexture(nil, "ARTWORK")
    rowIcon:SetSize(14, 14)
    rowIcon:SetPoint("LEFT", row, "LEFT", 5, 0)
    rowIcon:SetTexture(GetEntryIcon(entry))
    rowIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local waypointIcon
    if entry.zone and entry.x and entry.y then
        waypointIcon = row:CreateTexture(nil, "ARTWORK")
        waypointIcon:SetAtlas("Waypoint-MapPin-Untracked", true)
        waypointIcon:SetSize(14, 14)
        waypointIcon:SetPoint("RIGHT", row, "RIGHT", -72, 0)
        waypointIcon:SetAlpha(0.75)
    end

    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    nameText:SetPoint("LEFT", rowIcon, "RIGHT", 6, 0)
    nameText:SetPoint("RIGHT", row, "RIGHT", waypointIcon and -90 or -74, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetText(LegacyEntryLabel(entry))
    nameText:SetTextColor(0.72, 0.72, 0.72)

    local kpText = row:CreateFontString(nil, "OVERLAY")
    kpText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    kpText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    kpText:SetWidth(62)
    kpText:SetJustifyH("RIGHT")
    kpText:SetText("+" .. tostring(entry.kp or 0))
    kpText:SetTextColor(cr, cg, cb, 0.95)

    row:SetScript("OnEnter", function()
        hover:SetColorTexture(cr, cg, cb, 0.12 * chromeAlpha)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetText(LegacyEntryLabel(entry), 1, 1, 1)
        GameTooltip:AddLine(string.format(L["ProfKnowledge_KPValue"], 0, entry.kp or 0), 0.80, 0.80, 0.90)
        if entry.note and entry.note ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(entry.note, 0.70, 0.82, 0.92, true)
        end
        if entry.zone and entry.x and entry.y then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(GetGatheringZoneName(entry.zone), 0.85, 0.85, 0.85)
            GameTooltip:AddLine(string.format(L["Gathering_Coords"], entry.x, entry.y), 0.7, 1, 0.9)
            GameTooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["ProfKnowledge_ReferenceOnly"] or "One-time source, not auto-tracked.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        hover:SetColorTexture(cr, cg, cb, 0)
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function()
        if not (entry.zone and entry.x and entry.y) then return end
        local ok, source = SetGatheringWaypoint(entry)
        if ok then print(string.format(L["Waypoint_Set"], source, LegacyEntryLabel(entry), entry.x, entry.y)) else print(L["Waypoint_Unavailable"]) end
    end)

    return cardY + rowHeight + 6
end

local function BuildLegacyKnowledgeSection(content, width, yOff, fontSize, contentAlpha, borderAlpha, chromeAlpha, accentAlpha, db, filterExpansionKey)
    for _, expansion in ipairs(LEGACY_EXPANSIONS) do
      if not filterExpansionKey or expansion.key == filterExpansionKey then
        local learnedProfessions = {}
        for _, profession in ipairs(expansion.professions) do
            if HasProfessionLearned(profession.skillLine) then
                learnedProfessions[#learnedProfessions + 1] = profession
            end
        end

        for _, profession in ipairs(learnedProfessions) do
                local weeklyDone, weeklyTotal, kpDone, kpTotal = LegacyProfessionWeeklyStats(profession)
                local weeklyRemaining = math.max(0, kpTotal - kpDone)
                local catchupAmount = (profession.catchupCurrency and GetCurrencyAmount(profession.catchupCurrency)) or 0
                local skillSummary = GetProfessionSkillSummary(profession.skillLine)
                local isCollapsed = IsLegacyProfessionCollapsed(expansion.key, profession.key)
                local cr, cg, cb = GetProfessionColor(profession.key)
                local cardW = math.max(1, width - 20)
                local collapsedRowH = math.max(24, fontSize + 15)
                local collapsedIconSize = math.max(16, math.min(20, fontSize + 7))

                local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
                card:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -yOff)
                card:SetWidth(cardW)
                card:SetBackdrop(MakeBackdrop())
                card:SetBackdropColor(0.018, 0.022, 0.028, (isCollapsed and 0.58 or 0.86) * contentAlpha)
                card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)

                local iconPlate = CreateFrame("Frame", nil, card, "BackdropTemplate")
                iconPlate:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
                iconPlate:SetSize(28, 28)
                iconPlate:SetBackdrop(MakeBackdrop())
                iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.95 * chromeAlpha)
                iconPlate:SetBackdropBorderColor(cr * 0.55, cg * 0.55, cb * 0.55, 0.85 * chromeAlpha)

                local iconTex = iconPlate:CreateTexture(nil, "ARTWORK")
                iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
                iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
                iconTex:SetTexture(PROFESSION_ICONS[profession.key] or "Interface\\Icons\\INV_Misc_QuestionMark")
                iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

                local cardGlow = card:CreateTexture(nil, "BACKGROUND")
                cardGlow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
                cardGlow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
                cardGlow:SetColorTexture(1, 1, 1, isCollapsed and 0 or (0.025 * contentAlpha))

                local header = card:CreateFontString(nil, "OVERLAY")
                header:SetFont(FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
                if isCollapsed then
                    iconPlate:ClearAllPoints()
                    iconPlate:SetPoint("LEFT", card, "LEFT", 7, 0)
                    iconPlate:SetSize(collapsedIconSize, collapsedIconSize)
                    iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.70 * chromeAlpha)
                    iconPlate:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, 0.70 * chromeAlpha)
                    iconTex:ClearAllPoints()
                    iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
                    iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
                    header:SetPoint("LEFT", iconPlate, "RIGHT", 6, 0)
                    header:SetPoint("RIGHT", card, "RIGHT", -64, 0)
                else
                    header:SetPoint("TOPLEFT", iconPlate, "TOPRIGHT", 8, -1)
                    header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -96, -1)
                end
                header:SetJustifyH("LEFT")
                header:SetWordWrap(false)
                header:SetTextColor(0.96, 0.97, 0.98, 1)
                header:SetText(profession.label)

                local headerSub = card:CreateFontString(nil, "OVERLAY")
                headerSub:SetFont(FONT_ROWS, math.max(8, fontSize - 2), GetFontFlags())
                headerSub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
                headerSub:SetPoint("RIGHT", card, "RIGHT", -12, 0)
                headerSub:SetJustifyH("LEFT")
                headerSub:SetTextColor(0.66, 0.72, 0.78, 0.95)
                headerSub:SetWordWrap(false)

                local headerMeta = card:CreateFontString(nil, "OVERLAY")
                headerMeta:SetFont(FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
                if isCollapsed then
                    headerMeta:SetPoint("RIGHT", card, "RIGHT", -10, 0)
                    headerMeta:SetWidth(48)
                else
                    headerMeta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -30, -10)
                    headerMeta:SetWidth(64)
                end
                headerMeta:SetJustifyH("RIGHT")
                headerMeta:SetWordWrap(false)
                headerMeta:SetTextColor(0.88, 0.91, 0.94, 0.95)
                headerMeta:SetText(string.format("%d/%d", weeklyDone, weeklyTotal))

                local collapseBtn = CreateFrame("Button", nil, card)
                collapseBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -7, -8)
                collapseBtn:SetSize(18, 18)
                collapseBtn:RegisterForClicks("LeftButtonUp")

                local collapseLbl = collapseBtn:CreateFontString(nil, "OVERLAY")
                collapseLbl:SetFont(FONT_HEADERS, math.max(10, fontSize), GetFontFlags())
                collapseLbl:SetPoint("CENTER")
                collapseLbl:SetText(isCollapsed and "+" or "-")
                collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
                collapseBtn:SetShown(not isCollapsed)

                local function ToggleLegacyProfessionCard()
                    SetLegacyProfessionCollapsed(expansion.key, profession.key, not IsLegacyProfessionCollapsed(expansion.key, profession.key))
                    RebuildGatheringLocationsFrame()
                end

                local headerHit = CreateFrame("Button", nil, card)
                headerHit:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
                headerHit:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
                headerHit:SetHeight(isCollapsed and collapsedRowH or 44)
                headerHit:RegisterForClicks("LeftButtonUp")
                headerHit:SetScript("OnClick", ToggleLegacyProfessionCard)
                headerHit:SetScript("OnEnter", function()
                    card:SetBackdropBorderColor(cr * 0.52, cg * 0.52, cb * 0.52, math.min(1, chromeAlpha + 0.15) * chromeAlpha)
                    collapseLbl:SetTextColor(1, 1, 1, 1)
                end)
                headerHit:SetScript("OnLeave", function()
                    card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)
                    collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
                end)
                collapseBtn:SetScript("OnClick", ToggleLegacyProfessionCard)

                if isCollapsed then
                    headerSub:Hide()
                    headerMeta:SetText(string.format("%d/%d", weeklyDone, weeklyTotal))
                else
                    headerSub:SetText(string.format(L["ProfKnowledge_HeaderSubFormat"], skillSummary or "--", weeklyRemaining, catchupAmount))
                    headerMeta:SetText(string.format("%d/%d KP", kpDone, kpTotal))
                end

                local cardY = isCollapsed and collapsedRowH or 54

                if not isCollapsed then
                    local sectionChip = CreateFrame("Frame", nil, card, "BackdropTemplate")
                    sectionChip:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
                    sectionChip:SetHeight(18)
                    sectionChip:SetBackdrop(MakeBackdrop())
                    sectionChip:SetBackdropColor(1, 1, 1, 0.035 * contentAlpha)
                    sectionChip:SetBackdropBorderColor(0.24, 0.28, 0.32, 0.65 * chromeAlpha)

                    local sectionHeader = sectionChip:CreateFontString(nil, "OVERLAY")
                    sectionHeader:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
                    sectionHeader:SetPoint("LEFT", sectionChip, "LEFT", 6, 0)
                    sectionHeader:SetTextColor(0.84, 0.88, 0.92, 0.95)
                    sectionHeader:SetText(string.format(L["ProfKnowledge_SectionFormat"], L["ProfKnowledge_Section_Weekly"], weeklyDone, weeklyTotal))
                    sectionChip:SetWidth(math.min((sectionHeader:GetStringWidth() or 90) + 14, cardW - 24))
                    cardY = cardY + 22

                    local rowHeight = math.max(fontSize + 11, 22)
                    for _, entry in ipairs(VisibleSortedLegacyEntries(profession.weekly)) do
                        cardY = RenderLegacyEntryRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, entry)
                    end
                    cardY = cardY + 4

                    if profession.treasures and #profession.treasures > 0 then
                        local treasureDone = 0
                        for _, entry in ipairs(profession.treasures) do
                            if IsDone(entry) then treasureDone = treasureDone + 1 end
                        end

                        local treasureChip = CreateFrame("Frame", nil, card, "BackdropTemplate")
                        treasureChip:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
                        treasureChip:SetHeight(18)
                        treasureChip:SetBackdrop(MakeBackdrop())
                        treasureChip:SetBackdropColor(1, 1, 1, 0.035 * contentAlpha)
                        treasureChip:SetBackdropBorderColor(0.24, 0.28, 0.32, 0.65 * chromeAlpha)

                        local treasureHeader = treasureChip:CreateFontString(nil, "OVERLAY")
                        treasureHeader:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
                        treasureHeader:SetPoint("LEFT", treasureChip, "LEFT", 6, 0)
                        treasureHeader:SetTextColor(0.84, 0.88, 0.92, 0.95)
                        treasureHeader:SetText(string.format(L["ProfKnowledge_SectionFormat"], L["ProfKnowledge_Section_Treasures"] or "Knowledge Treasures", treasureDone, #profession.treasures))
                        treasureChip:SetWidth(math.min((treasureHeader:GetStringWidth() or 90) + 14, cardW - 24))
                        cardY = cardY + 22

                        for _, entry in ipairs(VisibleSortedLegacyEntries(profession.treasures)) do
                            cardY = RenderLegacyEntryRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, entry)
                        end
                        cardY = cardY + 4
                    end

                    if profession.books and #profession.books > 0 then
                        local booksDone, booksTrackable = 0, 0
                        for _, entry in ipairs(profession.books) do
                            if entry.questID or entry.questIDs or entry.spellID then
                                booksTrackable = booksTrackable + 1
                                if IsDone(entry) then booksDone = booksDone + 1 end
                            end
                        end

                        local booksChip = CreateFrame("Frame", nil, card, "BackdropTemplate")
                        booksChip:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
                        booksChip:SetHeight(18)
                        booksChip:SetBackdrop(MakeBackdrop())
                        booksChip:SetBackdropColor(1, 1, 1, 0.035 * contentAlpha)
                        booksChip:SetBackdropBorderColor(0.24, 0.28, 0.32, 0.65 * chromeAlpha)

                        local booksHeader = booksChip:CreateFontString(nil, "OVERLAY")
                        booksHeader:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
                        booksHeader:SetPoint("LEFT", booksChip, "LEFT", 6, 0)
                        booksHeader:SetTextColor(0.84, 0.88, 0.92, 0.95)
                        if booksTrackable > 0 then
                            booksHeader:SetText(string.format(L["ProfKnowledge_SectionFormat"], L["ProfKnowledge_Section_Books"] or "Knowledge Books", booksDone, #profession.books))
                        else
                            booksHeader:SetText((L["ProfKnowledge_Section_Books"] or "Knowledge Books") .. " (" .. tostring(#profession.books) .. ")")
                        end
                        booksChip:SetWidth(math.min((booksHeader:GetStringWidth() or 90) + 14, cardW - 24))
                        cardY = cardY + 22

                        for _, entry in ipairs(VisibleSortedLegacyEntries(profession.books)) do
                            if entry.questID or entry.questIDs or entry.spellID then
                                cardY = RenderLegacyEntryRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, entry)
                            else
                                cardY = RenderLegacyReferenceRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, cr, cg, cb, entry)
                            end
                        end
                        cardY = cardY + 4
                    end
                end

                card:SetHeight(cardY + 8)
                yOff = yOff + card:GetHeight() + 8
        end

        if #learnedProfessions > 0 and expansion.sharedCatchupItemID then
            local shardCount = GetDragonShardCount()
            local shardRow = content:CreateFontString(nil, "OVERLAY")
            shardRow:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
            shardRow:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -yOff)
            shardRow:SetTextColor(0.70, 0.85, 1.00, 0.90)
            shardRow:SetText(string.format(L["ProfKnowledge_LegacyDragonShard"] or "Dragon Shards of Knowledge: %d", shardCount))
            yOff = yOff + 18 + 6
        end
      end
    end

    return yOff
end

local function BuildKnowledgeExpansionDropdown(parent, opts)
    opts = opts or {}

    local function ResolveDropdownFontSize()
        if type(opts.fontSize) == "function" then
            return opts.fontSize() or 8
        end

        if type(opts.fontSize) == "number" then
            return opts.fontSize
        end

        local db = MR.db and MR.db.profile or {}
        return math.max(8, db.gatheringFontSize or db.fontSize or 9)
    end

    local function ResolveDropdownAlpha()
        if type(opts.alpha) == "function" then
            local value = opts.alpha()
            if type(value) == "number" then
                return math.max(0, math.min(value, 1))
            end
        elseif type(opts.alpha) == "number" then
            return math.max(0, math.min(opts.alpha, 1))
        end

        return 1
    end

    local function EstimateDropdownTextWidth(text, fontSize)
        text = tostring(text or "")
        return (#text * math.max(fontSize or 8, 8) * 0.58) + 34
    end

    local function ResolveOptionListWidth(optionList, fontSize)
        local width = opts.width or 78
        for _, option in ipairs(optionList or {}) do
            width = math.max(width, EstimateDropdownTextWidth(option.label, fontSize))
        end
        return math.min(opts.maxWidth or 220, math.ceil(width))
    end

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(opts.width or 78, opts.height or 18)
    btn:SetBackdrop(MakeBackdrop())
    btn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
    btn:SetBackdropBorderColor(0.40, 0.32, 0.18, 1)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_ROWS, ResolveDropdownFontSize(), GetFontFlags())
    label:SetPoint("LEFT", btn, "LEFT", 6, 0)
    label:SetPoint("RIGHT", btn, "RIGHT", -14, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.90, 0.80, 0.55)
    btn._label = label

    local caret = btn:CreateFontString(nil, "OVERLAY")
    caret:SetFont(FONT_HEADERS, math.max(9, ResolveDropdownFontSize() + 1), GetFontFlags())
    caret:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
    caret:SetText("v")
    caret:SetTextColor(0.85, 0.75, 0.55)
    btn._caret = caret

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(50)
    popup:SetBackdrop(MakeBackdrop())
    popup:SetBackdropColor(0.04, 0.09, 0.15, 0.98)
    popup:SetBackdropBorderColor(0.40, 0.32, 0.18, 1)
    popup:Hide()
    popup.buttons = {}

    function btn:ApplyFonts()
        local labelSize = ResolveDropdownFontSize()
        local caretSize = math.max(9, labelSize + 1)
        local rowHeight = math.max(18, labelSize + 10)
        local minWidth = opts.width or 78
        local maxWidth = opts.maxWidth or 220
        local minHeight = opts.height or 18
        local maxHeight = opts.maxHeight or minHeight
        local alpha = ResolveDropdownAlpha()

        self:SetHeight(math.min(maxHeight, math.max(minHeight, labelSize + 6)))
        self:SetBackdropColor(0.05, 0.12, 0.20, 0.95 * alpha)
        self:SetBackdropBorderColor(0.40, 0.32, 0.18, alpha)
        if self._label then
            self._label:SetFont(FONT_ROWS, labelSize, GetFontFlags())
            local textWidth = math.max((self._label:GetStringWidth() or 0) + 30, EstimateDropdownTextWidth(self._label:GetText(), labelSize))
            self:SetWidth(math.max(minWidth, math.min(maxWidth, math.ceil(textWidth))))
        end
        if self._caret then
            self._caret:SetFont(FONT_HEADERS, caretSize, GetFontFlags())
        end

        for _, row in ipairs(popup.buttons) do
            if row._label then
                row._label:SetFont(FONT_ROWS, labelSize, GetFontFlags())
            end
            if row._check then
                row._check:SetFont(FONT_HEADERS, caretSize, GetFontFlags())
            end
            row:SetHeight(rowHeight)
        end
    end

    local dismiss = CreateFrame("Frame", nil, UIParent)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("DIALOG")
    dismiss:SetFrameLevel(49)
    dismiss:EnableMouse(true)
    dismiss:Hide()
    dismiss:SetScript("OnMouseDown", function()
        popup:Hide()
        dismiss:Hide()
    end)

    btn:SetScript("OnEnter", function(selfBtn)
        local alpha = ResolveDropdownAlpha()
        selfBtn:SetBackdropColor(0.08, 0.18, 0.28, 0.98 * alpha)
        selfBtn:SetBackdropBorderColor(0.85, 0.70, 0.35, alpha)
    end)
    btn:SetScript("OnLeave", function(selfBtn)
        local alpha = ResolveDropdownAlpha()
        selfBtn:SetBackdropColor(0.05, 0.12, 0.20, 0.95 * alpha)
        selfBtn:SetBackdropBorderColor(0.40, 0.32, 0.18, alpha)
    end)

    function btn:Update()
        local optionList = opts.getOptions()
        local selectedKey = opts.getSelected()
        for _, option in ipairs(optionList) do
            if option.key == selectedKey then
                self._label:SetText(option.label)
                break
            end
        end
        self:ApplyFonts()
    end

    local function EnsurePopupButton(index)
        local row = popup.buttons[index]
        if row then
            return row
        end

        row = CreateFrame("Button", nil, popup, "BackdropTemplate")
        row:SetHeight(18)
        row:SetBackdrop(MakeBackdrop())
        row:SetBackdropColor(0.05, 0.12, 0.20, 0.94)
        row:SetBackdropBorderColor(0.12, 0.26, 0.32, 0.95)

        row._label = row:CreateFontString(nil, "OVERLAY")
        row._label:SetFont(FONT_ROWS, ResolveDropdownFontSize(), GetFontFlags())
        row._label:SetPoint("LEFT", row, "LEFT", 8, 1)
        row._label:SetPoint("RIGHT", row, "RIGHT", -22, 1)
        row._label:SetJustifyH("LEFT")

        row._check = row:CreateFontString(nil, "OVERLAY")
        row._check:SetFont(FONT_HEADERS, math.max(9, ResolveDropdownFontSize() + 1), GetFontFlags())
        row._check:SetPoint("RIGHT", row, "RIGHT", -7, 1)

        row:SetScript("OnEnter", function(selfRow)
            local alpha = ResolveDropdownAlpha()
            selfRow:SetBackdropColor(0.08, 0.18, 0.28, 0.98 * alpha)
            selfRow:SetBackdropBorderColor(0.85, 0.70, 0.35, alpha)
        end)
        row:SetScript("OnLeave", function(selfRow)
            local active = selfRow._checked == true
            local alpha = ResolveDropdownAlpha()
            selfRow:SetBackdropColor(active and 0.10 or 0.05, active and 0.22 or 0.12, active and 0.30 or 0.20, (active and 0.98 or 0.94) * alpha)
            selfRow:SetBackdropBorderColor(active and 0.55 or 0.12, active and 0.46 or 0.26, active and 0.20 or 0.32, (active and 1 or 0.95) * alpha)
        end)

        popup.buttons[index] = row
        return row
    end

    btn:SetScript("OnClick", function(selfBtn)
        local optionList = opts.getOptions()
        if #optionList <= 1 then
            return
        end

        local selectedKey = opts.getSelected()
        local labelSize = ResolveDropdownFontSize()
        local rowHeight = math.max(18, labelSize + 10)
        selfBtn:ApplyFonts()
        local rowWidth = math.max(selfBtn:GetWidth(), ResolveOptionListWidth(optionList, labelSize), 130)
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", selfBtn, "BOTTOMLEFT", 0, -4)
        popup:SetSize(rowWidth, (#optionList * (rowHeight + 2)) + 6)
        local menuAlpha = ResolveDropdownAlpha()
        popup:SetBackdropColor(0.04, 0.09, 0.15, 0.98 * menuAlpha)
        popup:SetBackdropBorderColor(0.40, 0.32, 0.18, menuAlpha)

        for index, option in ipairs(optionList) do
            local row = EnsurePopupButton(index)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -3 - ((index - 1) * (rowHeight + 2)))
            row:SetSize(rowWidth - 6, rowHeight)
            row._checked = option.key == selectedKey
            row._label:SetText(option.label)
            row._label:SetTextColor(row._checked and 0.96 or 0.85, row._checked and 0.90 or 0.80, row._checked and 0.65 or 0.75)
            row._check:SetText(row._checked and "x" or "")
            row._check:SetTextColor(0.90, 0.80, 0.55)
            row:SetBackdropColor(row._checked and 0.10 or 0.05, row._checked and 0.22 or 0.12, row._checked and 0.30 or 0.20, (row._checked and 0.98 or 0.94) * menuAlpha)
            row:SetBackdropBorderColor(row._checked and 0.55 or 0.12, row._checked and 0.46 or 0.26, row._checked and 0.20 or 0.32, (row._checked and 1 or 0.95) * menuAlpha)
            row:SetScript("OnClick", function()
                opts.onSelect(option.key)
                popup:Hide()
                dismiss:Hide()
            end)
            row:Show()
        end

        for index = #optionList + 1, #popup.buttons do
            popup.buttons[index]:Hide()
        end

        if popup:IsShown() then
            popup:Hide()
            dismiss:Hide()
        else
            dismiss:Show()
            popup:Show()
        end
    end)

    return btn
end

local function CreateKnowledgeExpansionDropdown(titleBar, gearBtn)
    local dropdown = BuildKnowledgeExpansionDropdown(titleBar, {
        width = 122,
        height = 18,
        maxHeight = 18,
        fontSize = function()
            local db = MR.db and MR.db.profile or {}
            return math.max(8, db.gatheringFontSize or db.fontSize or 9)
        end,
        alpha = function()
            local db = MR.db and MR.db.profile or {}
            return db.gatheringAlpha or 1
        end,
        getOptions = GetKnowledgeExpansionOptions,
        getSelected = GetSelectedKnowledgeExpansion,
        onSelect = SetSelectedKnowledgeExpansion,
    })
    dropdown:SetPoint("RIGHT", gearBtn, "LEFT", -4, 0)
    dropdown:Update()
    return dropdown, GetSelectedKnowledgeExpansion()
end

local function BuildGatheringLocationsFrame(isRetry)
    RefreshFonts()
    local db = MR.db and MR.db.profile or {}
    local hadProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
    if not hadProfCache and MR.RefreshPlayerProfessions then MR:RefreshPlayerProfessions() end
    local hasProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
    local alpha = db.gatheringAlpha or 1.0
    local width = db.gatheringWidth or DEFAULT_W
    local height = db.gatheringHeight or DEFAULT_H
    local minimized = db.gatheringMinimized or false
    local headerBottom = IsManagedHeaderBottom()
    gatheringMinimized = minimized
    local panelAlpha = math.max(0, math.min(alpha, 1))
    local contentAlpha = panelAlpha
    local borderAlpha = 0.20 + (0.75 * panelAlpha)
    local accentAlpha = 0.10 + (0.85 * panelAlpha)
    local chromeAlpha = panelAlpha

    local function ApplyFrameHeight(frame, targetHeight)
        AnimateManagedFrameHeight(frame, targetHeight, function(self)
            self:SetScript("OnUpdate", nil)
        end)
    end

    local frame = StyledFrame(UIParent, nil, "MEDIUM", 10)
    frame:SetSize(width, minimized and TITLE_H or height)
    RestoreManagedFramePos(frame, "gatheringLocPos", 860, 0)
    frame.leftAccent = nil
    ApplyGatheringFrameTheme(frame, {
        alpha = alpha,
        bg = { 0.03, 0.05, 0.09, 0.97 * alpha },
        border = { 0.24, 0.31, 0.42, alpha },
        accent = { 0.18, 0.78, 0.72 },
        headerHeight = 64,
    })

    local titleBar = TitleBar(frame, TITLE_H)
    frame.titleBar = titleBar
    titleBar:SetBackdropColor(0, 0, 0, 0)
    titleBar:ClearAllPoints()
    if headerBottom then
        titleBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        titleBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    else
        titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    end
    titleBar:SetScript("OnDragStart", function() if not db.gatheringLocked then frame:StartMoving() end end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SaveManagedFramePos(frame, "gatheringLocPos", headerBottom and "bottom" or "top")
    end)
    if MR.ApplyPanelHeaderAutoHide then MR:ApplyPanelHeaderAutoHide(frame, titleBar) end

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(16, 16)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 9, 0)
    titleIcon:SetTexture("Interface\\AddOns\\MidnightRoutine\\Media\\Icon")
    titleIcon:SetVertexColor(0.18, 0.82, 0.74, 1)
    titleIcon:Hide()

    local closeBtn = CloseButton(titleBar, function()
        frame:Hide()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", false) end
    end)

    local gearBtn = HeaderIconButton(
        titleBar,
        "Interface\\Buttons\\UI-OptionsButton",
        {0.85, 0.65, 0.20},
        {1, 1, 1},
        L["ProfKnowledge_OptionsTitle"],
        function() MR:ToggleGatheringLocationsConfig() end
    )

    local expansionDropdown, selectedExpansion = CreateKnowledgeExpansionDropdown(titleBar, gearBtn)
    frame.expansionDropdown = expansionDropdown
    expansionDropdown:ClearAllPoints()
    expansionDropdown:SetPoint("LEFT", titleBar, "LEFT", 8, -1)

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(FONT_HEADERS, math.max(10, (db.gatheringFontSize or 9) + 1), GetFontFlags())
    titleTxt:SetPoint("LEFT", titleIcon, "RIGHT", 5, 0)
    titleTxt:SetPoint("RIGHT", expansionDropdown, "LEFT", -6, 0)
    titleTxt:SetJustifyH("LEFT")
    titleTxt:SetText(StripInlineColor(L["ProfKnowledge_Title"] or "Profession Knowledge"))
    titleTxt:SetTextColor(1, 1, 1)
    titleTxt:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, frame)
    if headerBottom then
        scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
        scroll:SetPoint("BOTTOMRIGHT", titleBar, "TOPRIGHT", -8, 1)
    else
        scroll:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -1)
        scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 4)
    end
    scroll:EnableMouseWheel(true)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(width - 8)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    local track = CreateFrame("Frame", nil, frame)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 1, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    track:SetWidth(5)
    frame._scroll = scroll
    frame._scrollTrack = track
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0, 0, 0, 0.3 * chromeAlpha)
    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(5)
    thumb:EnableMouse(true)
    thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.80, 0.53, 0.20, 0.6 * chromeAlpha)

    local function UpdateScrollBar()
        local viewH, contentH = scroll:GetHeight(), content:GetHeight()
        if contentH <= viewH or viewH <= 0 then thumb:Hide(); return end
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 14)
        local pct = scroll:GetVerticalScroll() / math.max(contentH - viewH, 1)
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackH - thumbH) * pct))
    end

    local function SetScrollFromCursor(cursorY, grabOffset)
        local viewH = scroll:GetHeight()
        local contentH = content:GetHeight()
        local maxScroll = math.max(contentH - viewH, 0)
        if maxScroll <= 0 then
            scroll:SetVerticalScroll(0)
            UpdateScrollBar()
            return
        end

        local trackTop = track:GetTop()
        local trackBottom = track:GetBottom()
        if not trackTop or not trackBottom then return end

        local trackH = math.max(trackTop - trackBottom, 1)
        local thumbH = thumb:GetHeight()
        local movable = math.max(trackH - thumbH, 1)
        local offset = grabOffset or (thumbH * 0.5)
        local y = math.max(0, math.min((trackTop - cursorY) - offset, movable))
        local pct = y / movable
        scroll:SetVerticalScroll(maxScroll * pct)
        UpdateScrollBar()
    end

    track:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or not thumb:IsShown() then return end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        SetScrollFromCursor(cursorY, thumb:GetHeight() * 0.5)
        thumb._grabOffset = thumb:GetHeight() * 0.5
        thumb:SetScript("OnUpdate", function(self)
            if not IsMouseButtonDown("LeftButton") then
                self._grabOffset = nil
                self:SetScript("OnUpdate", nil)
                return
            end

            local _, dragCursorY = GetCursorPosition()
            dragCursorY = dragCursorY / UIParent:GetEffectiveScale()
            SetScrollFromCursor(dragCursorY, self._grabOffset)
        end)
    end)

    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or not self:IsShown() then return end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        local thumbTop = self:GetTop()
        self._grabOffset = thumbTop and (thumbTop - cursorY) or (self:GetHeight() * 0.5)
        self:SetScript("OnUpdate", function(btn)
            if not IsMouseButtonDown("LeftButton") then
                btn._grabOffset = nil
                btn:SetScript("OnUpdate", nil)
                return
            end

            local _, dragCursorY = GetCursorPosition()
            dragCursorY = dragCursorY / UIParent:GetEffectiveScale()
            SetScrollFromCursor(dragCursorY, btn._grabOffset)
        end)
    end)

    thumb:SetScript("OnMouseUp", function(self)
        self._grabOffset = nil
        self:SetScript("OnUpdate", nil)
    end)

    scroll:SetScript("OnMouseWheel", function(_, delta)
        scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScroll() - delta * 30, math.max(content:GetHeight() - scroll:GetHeight(), 0))))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", UpdateScrollBar)
    scroll:SetScript("OnVerticalScroll", UpdateScrollBar)
    frame.UpdateScrollBar = UpdateScrollBar

    local ApplyMinimized

    local function UpdateMinBtn() return gatheringMinimized and "+" or "-" end
    local minBtn = HeaderToggleButton(titleBar, UpdateMinBtn, L["UI_Collapse"], function()
        gatheringMinimized = not gatheringMinimized
        minimized = gatheringMinimized
        if MR.db then MR.db.profile.gatheringMinimized = gatheringMinimized end
        ApplyMinimized(gatheringMinimized)
    end)
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -3, 0)
    gearBtn:SetPoint("RIGHT", minBtn, "LEFT", -3, 0)
    if chromeAlpha <= 0.001 then
        for _, headerBtn in ipairs({ closeBtn, gearBtn, minBtn }) do
            if headerBtn.SetBackdropColor then
                headerBtn:SetBackdropColor(0, 0, 0, 0)
                headerBtn:SetBackdropBorderColor(0, 0, 0, 0)
            end
        end
    end

    local yOff = 0
    local fontSize = db.gatheringFontSize or 9

    if selectedExpansion == "midnight" then
    for _, profession in ipairs(PROFESSIONS) do
        if HasProfessionLearned(profession.skillLine) then
            local cr, cg, cb = GetProfessionColor(profession.key)
            local doneSources, totalSources, kpDone, kpTotal = ProfessionStats(profession)
            local weeklyDone, weeklyTotal = ProfessionWeeklyStats(profession)
            local weeklyRemaining = math.max(0, weeklyTotal - weeklyDone)
            local catchupAmount = GetProfessionCatchupAmount(profession.skillLine)
            local skillSummary = GetProfessionSkillSummary(profession.skillLine)
            local isCollapsed = IsProfessionCollapsed(profession.key)
            local cardW = math.max(1, width - 20)
            local collapsedRowH = math.max(24, fontSize + 15)
            local collapsedIconSize = math.max(16, math.min(20, fontSize + 7))
            local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
            card:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -yOff)
            card:SetWidth(cardW)
            card:SetBackdrop(MakeBackdrop())
            card:SetBackdropColor(0.018, 0.022, 0.028, (isCollapsed and 0.58 or 0.86) * contentAlpha)
            card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)

            local iconPlate = CreateFrame("Frame", nil, card, "BackdropTemplate")
            iconPlate:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
            iconPlate:SetSize(28, 28)
            iconPlate:SetBackdrop(MakeBackdrop())
            iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.95 * chromeAlpha)
            iconPlate:SetBackdropBorderColor(cr * 0.55, cg * 0.55, cb * 0.55, 0.85 * chromeAlpha)

            local iconTex = iconPlate:CreateTexture(nil, "ARTWORK")
            iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
            iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
            iconTex:SetTexture(PROFESSION_ICONS[profession.key] or "Interface\\Icons\\INV_Misc_QuestionMark")
            iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

            local cardStripe = card:CreateTexture(nil, "ARTWORK")
            cardStripe:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
            cardStripe:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 1, 1)
            cardStripe:SetWidth(3)
            cardStripe:SetColorTexture(cr, cg, cb, 0)

            local cardGlow = card:CreateTexture(nil, "BACKGROUND")
            cardGlow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
            cardGlow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
            cardGlow:SetColorTexture(1, 1, 1, isCollapsed and 0 or (0.025 * contentAlpha))

            local header = card:CreateFontString(nil, "OVERLAY")
            header:SetFont(FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
            if isCollapsed then
                iconPlate:ClearAllPoints()
                iconPlate:SetPoint("LEFT", card, "LEFT", 7, 0)
                iconPlate:SetSize(collapsedIconSize, collapsedIconSize)
                iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.70 * chromeAlpha)
                iconPlate:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, 0.70 * chromeAlpha)
                iconTex:ClearAllPoints()
                iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
                iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
                header:SetPoint("LEFT", iconPlate, "RIGHT", 6, 0)
                header:SetPoint("RIGHT", card, "RIGHT", -64, 0)
            else
                header:SetPoint("TOPLEFT", iconPlate, "TOPRIGHT", 8, -1)
                header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -96, -1)
            end
            header:SetJustifyH("LEFT")
            header:SetWordWrap(false)
            header:SetTextColor(0.96, 0.97, 0.98, 1)
            header:SetText(profession.label)

            local headerSub = card:CreateFontString(nil, "OVERLAY")
            headerSub:SetFont(FONT_ROWS, math.max(8, fontSize - 2), GetFontFlags())
            headerSub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
            headerSub:SetPoint("RIGHT", card, "RIGHT", -12, 0)
            headerSub:SetJustifyH("LEFT")
            headerSub:SetTextColor(0.66, 0.72, 0.78, 0.95)
            headerSub:SetWordWrap(false)

            local headerMeta = card:CreateFontString(nil, "OVERLAY")
            headerMeta:SetFont(FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
            if isCollapsed then
                headerMeta:SetPoint("RIGHT", card, "RIGHT", -10, 0)
                headerMeta:SetWidth(48)
            else
                headerMeta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -30, -10)
                headerMeta:SetWidth(64)
            end
            headerMeta:SetJustifyH("RIGHT")
            headerMeta:SetWordWrap(false)
            headerMeta:SetTextColor(0.88, 0.91, 0.94, 0.95)
            headerMeta:SetText(string.format("%d/%d", doneSources, totalSources))

            local collapseBtn = CreateFrame("Button", nil, card)
            collapseBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -7, -8)
            collapseBtn:SetSize(18, 18)
            collapseBtn:RegisterForClicks("LeftButtonUp")

            local collapseLbl = collapseBtn:CreateFontString(nil, "OVERLAY")
            collapseLbl:SetFont(FONT_HEADERS, math.max(10, fontSize), GetFontFlags())
            collapseLbl:SetPoint("CENTER")
            collapseLbl:SetText(isCollapsed and "+" or "-")
            collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
            collapseBtn:SetShown(not isCollapsed)

            local function ToggleProfessionCard()
                SetProfessionCollapsed(profession.key, not IsProfessionCollapsed(profession.key))
                RebuildGatheringLocationsFrame()
            end

            local headerHit = CreateFrame("Button", nil, card)
            headerHit:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
            headerHit:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
            headerHit:SetHeight(isCollapsed and collapsedRowH or 44)
            headerHit:RegisterForClicks("LeftButtonUp")
            headerHit:SetScript("OnClick", ToggleProfessionCard)
            headerHit:SetScript("OnEnter", function()
                card:SetBackdropBorderColor(cr * 0.52, cg * 0.52, cb * 0.52, math.min(1, chromeAlpha + 0.15) * chromeAlpha)
                collapseLbl:SetTextColor(1, 1, 1, 1)
            end)
            headerHit:SetScript("OnLeave", function()
                card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)
                collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
            end)
            collapseBtn:SetScript("OnClick", ToggleProfessionCard)

            if isCollapsed then
                headerSub:Hide()
                headerMeta:SetText(string.format("%d/%d", doneSources, totalSources))
            else
                headerSub:SetText(string.format(L["ProfKnowledge_HeaderSubFormat"], skillSummary or "--", weeklyRemaining, catchupAmount))
                headerMeta:SetText(string.format("%d/%d KP", kpDone, kpTotal))
            end

            local cardY = isCollapsed and collapsedRowH or 54

            if not isCollapsed then
                for _, section in ipairs(profession.sections) do
                    if ShowInKnowledgeTracker(section) then
                        local sectionDone, sectionTotal = SectionStats(section)
                        local sectionChip = CreateFrame("Frame", nil, card, "BackdropTemplate")
                        sectionChip:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
                        sectionChip:SetHeight(18)
                        sectionChip:SetBackdrop(MakeBackdrop())
                        sectionChip:SetBackdropColor(1, 1, 1, 0.035 * contentAlpha)
                        sectionChip:SetBackdropBorderColor(0.24, 0.28, 0.32, 0.65 * chromeAlpha)

                        local sectionHeader = sectionChip:CreateFontString(nil, "OVERLAY")
                        sectionHeader:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
                        sectionHeader:SetPoint("LEFT", sectionChip, "LEFT", 6, 0)
                        sectionHeader:SetTextColor(0.84, 0.88, 0.92, 0.95)
                        sectionHeader:SetText(string.format(L["ProfKnowledge_SectionFormat"], section.label, sectionDone, sectionTotal))
                        sectionChip:SetWidth(math.min((sectionHeader:GetStringWidth() or 90) + 14, cardW - 24))
                        cardY = cardY + 22

                        local rowHeight = math.max(fontSize + 11, 22)
                        for _, entry in ipairs(section.entries) do
                            local current, required = Progress(entry)
                            local done = current >= required
                            if not (done and db.gatheringHideCompleted) then
                                local row = CreateFrame("Button", nil, card, "BackdropTemplate")
                                row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
                                row:SetSize(cardW - 24, rowHeight + 4)
                                row:RegisterForClicks("LeftButtonUp")
                                row:SetBackdrop(MakeBackdrop())
                                if done then
                                    row:SetBackdropColor(1, 1, 1, 0.025 * contentAlpha)
                                    row:SetBackdropBorderColor(0.16, 0.30, 0.22, 0.55 * chromeAlpha)
                                else
                                    row:SetBackdropColor(1, 1, 1, 0.035 * contentAlpha)
                                    row:SetBackdropBorderColor(0.20, 0.24, 0.28, 0.58 * chromeAlpha)
                                end

                                local hover = row:CreateTexture(nil, "BACKGROUND")
                                hover:SetAllPoints()
                                hover:SetColorTexture(cr, cg, cb, 0)

                                local rowIcon = row:CreateTexture(nil, "ARTWORK")
                                rowIcon:SetSize(14, 14)
                                rowIcon:SetPoint("LEFT", row, "LEFT", 5, 0)
                                rowIcon:SetTexture(GetEntryIcon(entry))
                                rowIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

                                local dot = row:CreateTexture(nil, "ARTWORK")
                                dot:SetSize(6, 6)
                                dot:SetPoint("LEFT", rowIcon, "RIGHT", 5, 0)
                                if done then
                                    dot:SetColorTexture(0.26, 0.86, 0.52, 1)
                                elseif required > 1 and current > 0 then
                                    dot:SetColorTexture(0.95, 0.80, 0.25, 1)
                                else
                                    dot:SetColorTexture(cr, cg, cb, 1)
                                end

                                local waypointIcon
                                if entry.zone and entry.x and entry.y then
                                    waypointIcon = row:CreateTexture(nil, "ARTWORK")
                                    waypointIcon:SetAtlas("Waypoint-MapPin-Untracked", true)
                                    waypointIcon:SetSize(14, 14)
                                    waypointIcon:SetPoint("RIGHT", row, "RIGHT", -72, 0)
                                    waypointIcon:SetAlpha(0.75)
                                end

                                local nameText = row:CreateFontString(nil, "OVERLAY")
                                nameText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
                                nameText:SetPoint("LEFT", dot, "RIGHT", 6, 0)
                                nameText:SetPoint("RIGHT", row, "RIGHT", waypointIcon and -90 or -74, 0)
                                nameText:SetJustifyH("LEFT")
                                nameText:SetWordWrap(false)
                                nameText:SetText(EntryName(entry))
                                nameText:SetTextColor(done and 0.45 or 0.90, done and 0.45 or 0.90, done and 0.45 or 0.90)

                                local statusText = row:CreateFontString(nil, "OVERLAY")
                                statusText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
                                statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                                statusText:SetWidth(62)
                                statusText:SetJustifyH("RIGHT")
                                statusText:SetText(ProgressText(entry))
                                if done then statusText:SetTextColor(0.32, 0.80, 0.50, 0.95)
                                elseif required > 1 and current > 0 then statusText:SetTextColor(0.95, 0.80, 0.25, 0.95)
                                else statusText:SetTextColor(cr, cg, cb, 0.95) end

                                row:SetScript("OnEnter", function()
                                    hover:SetColorTexture(cr, cg, cb, 0.12 * accentAlpha)
                                    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                                    GameTooltip:SetText(EntryName(entry), 1, 1, 1)
                                    GameTooltip:AddLine(string.format(L["ProfKnowledge_KPValue"], KPDone(entry), KPTotal(entry)), 0.80, 0.80, 0.90)
                                    GameTooltip:AddLine(string.format(L["ProfKnowledge_RowProgress"], current, required), 0.70, 0.90, 1)
                                    if entry.zone and entry.x and entry.y then
                                        local altKey = entry.itemID or entry.label
                                        local useAlt = entry.altZone and waypointAlt[altKey]
                                        local mapID = useAlt and entry.altZone or entry.zone
                                        local mapX = useAlt and entry.altX or entry.x
                                        local mapY = useAlt and entry.altY or entry.y
                                        GameTooltip:AddLine(" ")
                                        GameTooltip:AddLine(GetGatheringZoneName(mapID), 0.85, 0.85, 0.85)
                                        GameTooltip:AddLine(string.format(L["Gathering_Coords"], mapX, mapY), 0.7, 1, 0.9)
                                        if entry.altZone then
                                            GameTooltip:AddLine(" ")
                                            GameTooltip:AddLine(L["Gathering_AltLocationLabel"], 0.65, 0.65, 0.65)
                                            GameTooltip:AddLine(GetGatheringZoneName(useAlt and entry.zone or entry.altZone), 0.6, 0.6, 0.6)
                                            GameTooltip:AddLine(string.format("%.1f, %.1f", useAlt and entry.x or entry.altX, useAlt and entry.y or entry.altY), 0.45, 0.7, 0.55)
                                        end
                                    else
                                        GameTooltip:AddLine(" ")
                                        GameTooltip:AddLine(L["ProfKnowledge_NoWaypoint"], 0.65, 0.65, 0.65)
                                    end
                                    if entry.note and entry.note ~= "" then
                                        GameTooltip:AddLine(" ")
                                        GameTooltip:AddLine(entry.note, 0.65, 0.85, 0.95, true)
                                    end
                                    GameTooltip:AddLine(" ")
                                    if done then GameTooltip:AddLine(L["Gathering_AlreadyCollected"], 0, 0.8, 0.27)
                                    elseif entry.zone and entry.x and entry.y then GameTooltip:AddLine(entry.altZone and L["Gathering_ClickCycleHint"] or L["Gathering_ClickWaypoint"], 0.45, 0.85, 1) end
                                    GameTooltip:Show()
                                end)
                                row:SetScript("OnLeave", function() hover:SetColorTexture(cr, cg, cb, 0); GameTooltip:Hide() end)
                                row:SetScript("OnClick", function()
                                    if not entry.zone or not entry.x or not entry.y then return end
                                    local altKey = entry.itemID or entry.label
                                    local useAlt = entry.altZone and waypointAlt[altKey]
                                    local target = useAlt and { itemID = entry.itemID, label = entry.label, zone = entry.altZone, x = entry.altX, y = entry.altY } or entry
                                    if entry.altZone then waypointAlt[altKey] = not waypointAlt[altKey] end
                                    local ok, source = SetGatheringWaypoint(target)
                                    if ok then print(string.format(L["Waypoint_Set"], source, EntryName(entry), target.x, target.y)) else print(L["Waypoint_Unavailable"]) end
                                end)
                                cardY = cardY + rowHeight + 6
                            end
                        end
                        cardY = cardY + 4
                    end
                end

                if db.professionKnowledgeShowTasks ~= false then
                    local taskRows, taskDone, taskTotal = GetProfessionTaskRows(profession)
                    if #taskRows > 0 then
                        local sectionChip = CreateFrame("Frame", nil, card, "BackdropTemplate")
                        sectionChip:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
                        sectionChip:SetHeight(18)
                        sectionChip:SetBackdrop(MakeBackdrop())
                        sectionChip:SetBackdropColor(1, 1, 1, 0.040 * contentAlpha)
                        sectionChip:SetBackdropBorderColor(0.28, 0.32, 0.36, 0.70 * chromeAlpha)

                        local sectionHeader = sectionChip:CreateFontString(nil, "OVERLAY")
                        sectionHeader:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
                        sectionHeader:SetPoint("LEFT", sectionChip, "LEFT", 6, 0)
                        sectionHeader:SetTextColor(0.88, 0.91, 0.95, 0.95)
                        sectionHeader:SetText(string.format("Profession Tasks %d/%d", taskDone, taskTotal))
                        sectionChip:SetWidth(math.min((sectionHeader:GetStringWidth() or 116) + 14, cardW - 24))
                        cardY = cardY + 22

                        local grouped = {}
                        for _, entry in ipairs(taskRows) do
                            grouped[entry.category] = grouped[entry.category] or {}
                            grouped[entry.category][#grouped[entry.category] + 1] = entry
                        end

                        local taskRowHeight = math.max(fontSize + 9, 20)
                        for _, category in ipairs(PROFESSION_TASK_CATEGORY_ORDER) do
                            local categoryRows = grouped[category]
                            if categoryRows and #categoryRows > 0 then
                                local categoryLabel = card:CreateFontString(nil, "OVERLAY")
                                categoryLabel:SetFont(FONT_ROWS, math.max(8, fontSize - 2), GetFontFlags())
                                categoryLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 15, -cardY)
                                categoryLabel:SetTextColor(0.58, 0.64, 0.70, 0.95)
                                categoryLabel:SetText(PROFESSION_TASK_CATEGORY_LABELS[category] or category)
                                cardY = cardY + math.max(13, fontSize + 3)

                                for _, task in ipairs(categoryRows) do
                                    local row = task.row
                                    local mod = task.mod
                                    local taskFrame = CreateFrame("Button", nil, card, "BackdropTemplate")
                                    taskFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
                                    taskFrame:SetSize(cardW - 24, taskRowHeight + 3)
                                    taskFrame:RegisterForClicks("LeftButtonUp")
                                    taskFrame:SetBackdrop(MakeBackdrop())
                                    if task.done then
                                        taskFrame:SetBackdropColor(1, 1, 1, 0.020 * contentAlpha)
                                        taskFrame:SetBackdropBorderColor(0.14, 0.26, 0.20, 0.50 * chromeAlpha)
                                    else
                                        taskFrame:SetBackdropColor(1, 1, 1, 0.032 * contentAlpha)
                                        taskFrame:SetBackdropBorderColor(0.18, 0.22, 0.26, 0.55 * chromeAlpha)
                                    end

                                    local hover = taskFrame:CreateTexture(nil, "BACKGROUND")
                                    hover:SetAllPoints()
                                    hover:SetColorTexture(cr, cg, cb, 0)

                                    local dot = taskFrame:CreateTexture(nil, "ARTWORK")
                                    dot:SetSize(6, 6)
                                    dot:SetPoint("LEFT", taskFrame, "LEFT", 7, 0)
                                    if task.done then
                                        dot:SetColorTexture(0.26, 0.86, 0.52, 1)
                                    elseif task.max and task.current and task.current > 0 then
                                        dot:SetColorTexture(0.95, 0.80, 0.25, 1)
                                    else
                                        dot:SetColorTexture(cr, cg, cb, 1)
                                    end

                                    local waypointIcon
                                    if row.zone and row.x and row.y then
                                        waypointIcon = taskFrame:CreateTexture(nil, "ARTWORK")
                                        waypointIcon:SetAtlas("Waypoint-MapPin-Untracked", true)
                                        waypointIcon:SetSize(13, 13)
                                        waypointIcon:SetPoint("RIGHT", taskFrame, "RIGHT", -70, 0)
                                        waypointIcon:SetAlpha(0.72)
                                    end

                                    local nameText = taskFrame:CreateFontString(nil, "OVERLAY")
                                    nameText:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
                                    nameText:SetPoint("LEFT", dot, "RIGHT", 7, 0)
                                    nameText:SetPoint("RIGHT", taskFrame, "RIGHT", waypointIcon and -88 or -72, 0)
                                    nameText:SetJustifyH("LEFT")
                                    nameText:SetWordWrap(false)
                                    nameText:SetText(StripInlineColor(row.label or mod.label or row.key))
                                    nameText:SetTextColor(task.done and 0.46 or 0.90, task.done and 0.46 or 0.90, task.done and 0.46 or 0.90)

                                    local statusText = taskFrame:CreateFontString(nil, "OVERLAY")
                                    statusText:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
                                    statusText:SetPoint("RIGHT", taskFrame, "RIGHT", -8, 0)
                                    statusText:SetWidth(58)
                                    statusText:SetJustifyH("RIGHT")
                                    statusText:SetWordWrap(false)
                                    statusText:SetText(GetProfessionTaskProgressText(mod, row))
                                    if task.done then
                                        statusText:SetTextColor(0.32, 0.80, 0.50, 0.95)
                                    elseif task.max and task.current and task.current > 0 then
                                        statusText:SetTextColor(0.95, 0.80, 0.25, 0.95)
                                    else
                                        statusText:SetTextColor(cr, cg, cb, 0.95)
                                    end

                                    taskFrame:SetScript("OnEnter", function()
                                        hover:SetColorTexture(cr, cg, cb, 0.10 * accentAlpha)
                                        GameTooltip:SetOwner(taskFrame, "ANCHOR_RIGHT")
                                        GameTooltip:SetText(StripInlineColor(row.label or mod.label or row.key), 1, 1, 1)
                                        if row.note and row.note ~= "" then
                                            GameTooltip:AddLine(row.note, 0.70, 0.82, 0.92, true)
                                        end
                                        if row.zone and row.x and row.y then
                                            GameTooltip:AddLine(" ")
                                            GameTooltip:AddLine(string.format(L["Gathering_Coords"], row.x, row.y), 0.7, 1, 0.9)
                                            GameTooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
                                        end
                                        GameTooltip:Show()
                                    end)
                                    taskFrame:SetScript("OnLeave", function()
                                        hover:SetColorTexture(cr, cg, cb, 0)
                                        GameTooltip:Hide()
                                    end)
                                    taskFrame:SetScript("OnClick", function()
                                        if row.zone and row.x and row.y then
                                            local ok, source = SetGatheringWaypoint(row)
                                            if ok then
                                                print(string.format(L["Waypoint_Set"], source, StripInlineColor(row.label or mod.label or row.key), row.x, row.y))
                                            else
                                                print(L["Waypoint_Unavailable"])
                                            end
                                        end
                                    end)

                                    cardY = cardY + taskRowHeight + 5
                                end

                                cardY = cardY + 2
                            end
                        end
                    end
                end
            end
            card:SetHeight(isCollapsed and collapsedRowH or (cardY + 8))
            yOff = yOff + card:GetHeight() + (isCollapsed and 3 or 8)
        end
    end
    end

    if selectedExpansion ~= "midnight" then
        yOff = BuildLegacyKnowledgeSection(content, width, yOff, fontSize, contentAlpha, borderAlpha, chromeAlpha, accentAlpha, db, selectedExpansion)
    end

    if yOff == 0 then
        local emptyText = content:CreateFontString(nil, "OVERLAY")
        emptyText:SetFont(FONT_ROWS, fontSize, GetFontFlags())
        emptyText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
        emptyText:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -10)
        emptyText:SetJustifyH("LEFT")
        emptyText:SetTextColor(0.72, 0.72, 0.72, 0.95)
        emptyText:SetText(hasProfCache and L["Gathering_NoProfessions"] or L["Gathering_Loading"])
        yOff = 32
        if not hasProfCache and not isRetry and C_Timer then
            C_Timer.After(0.75, function()
                if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then
                    if MR.RefreshPlayerProfessions then MR:RefreshPlayerProfessions() end
                    gatheringLocationsFrame:Hide()
                    gatheringLocationsFrame = BuildGatheringLocationsFrame(true)
                end
            end)
        end
    end

    content:SetHeight(yOff)
    scroll:SetVerticalScroll(0)
    UpdateScrollBar()

    local dragger = CreateFrame("Frame", nil, frame)
    dragger:SetSize(12, 12)
    if headerBottom then
        dragger:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    else
        dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end
    dragger:SetFrameLevel(frame:GetFrameLevel() + 10)
    dragger:EnableMouse(true)
    frame._dragger = dragger
    local dTex = dragger:CreateTexture(nil, "OVERLAY")
    dTex:SetAllPoints()
    dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    dragger:SetScript("OnEnter", function() if not db.gatheringLocked then dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight") end end)
    dragger:SetScript("OnLeave", function() dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up") end)

    local dragStartW, dragStartH, dragStartX, dragStartY
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not db.gatheringLocked then
            dragStartW, dragStartH = frame:GetWidth(), frame:GetHeight()
            local scale = frame:GetEffectiveScale()
            dragStartX, dragStartY = GetCursorPosition()
            dragStartX, dragStartY = dragStartX / scale, dragStartY / scale
            dragger._dragging = true
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            if MR.db then
                MR.db.profile.gatheringWidth = math.max(MIN_W, math.min(MAX_W, math.floor(frame:GetWidth())))
                MR.db.profile.gatheringHeight = math.max(MIN_H, math.min(MAX_H, math.floor(frame:GetHeight())))
            end
            RebuildGatheringLocationsFrame()
            if gatheringCfgFrame and gatheringCfgFrame:IsShown() then PopulateGatheringConfig(gatheringCfgFrame) end
        end
    end)
    dragger:SetScript("OnUpdate", function()
        if not dragger._dragging then return end
        local cx, cy = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        frame:SetWidth(math.max(MIN_W, math.min(MAX_W, dragStartW + (cx - dragStartX))))
        frame:SetHeight(math.max(MIN_H, math.min(MAX_H, dragStartH + (dragStartY - cy))))
    end)

    ApplyMinimized = function(isMin)
        gatheringMinimized = isMin and true or false
        minimized = gatheringMinimized
        if MR.db then MR.db.profile.gatheringMinimized = gatheringMinimized end
        if minBtn.RefreshLabel then minBtn:RefreshLabel() end

        if gatheringMinimized then
            SyncManagedFramePos(frame, "gatheringLocPos", headerBottom and "bottom" or "top")
            if frame._scroll then frame._scroll:Hide() end
            if frame._scrollTrack then frame._scrollTrack:Hide() end
            if frame._dragger then frame._dragger:Hide() end
            frame._mrAnimTick = nil
            frame:SetScript("OnUpdate", nil)
            frame:SetHeight(TITLE_H)
        else
            SyncManagedFramePos(frame, "gatheringLocPos", headerBottom and "bottom" or "top")
            if frame._scroll then frame._scroll:Show() end
            if frame._scrollTrack then frame._scrollTrack:Show() end
            if frame._dragger then frame._dragger:Show() end
            local savedH = db.gatheringHeight or DEFAULT_H
            local naturalH = TITLE_H + 1 + yOff + 6
            ApplyFrameHeight(frame, math.min(savedH, naturalH))
            if frame.UpdateScrollBar then frame.UpdateScrollBar() end
        end
    end
    frame.ApplyMinimized = ApplyMinimized

    ApplyMinimized(minimized)

    frame:SetMovable(not db.gatheringLocked)
    frame:SetScale(db.gatheringScale or 1.0)
    MR.gatheringLocationsFrame = frame
    frame:Show()
    return frame
end

RebuildGatheringLocationsFrame = function()
    RefreshFonts()
    local wasShown = gatheringLocationsFrame and gatheringLocationsFrame:IsShown()
    if gatheringLocationsFrame then gatheringLocationsFrame:Hide() end
    gatheringLocationsFrame = BuildGatheringLocationsFrame()
    if not wasShown then gatheringLocationsFrame:Hide() end
end

local function SetProfessionColor(professionKey, r, g, b)
    if not MR.db.profile.gatheringProfColors then MR.db.profile.gatheringProfColors = {} end
    MR.db.profile.gatheringProfColors[professionKey] = { r, g, b }
    RebuildGatheringLocationsFrame()
end

local function ResetProfessionColor(professionKey)
    if MR.db.profile.gatheringProfColors then MR.db.profile.gatheringProfColors[professionKey] = nil end
    RebuildGatheringLocationsFrame()
end

local function BuildGatheringConfigFrame()
    local frame = StyledFrame(UIParent, nil, "HIGH", 20)
    frame:SetWidth(268)
    ApplyGatheringFrameTheme(frame, {
        alpha = 1,
        bg = { 0.03, 0.05, 0.09, 0.98 },
        border = { 0.24, 0.31, 0.42, 1 },
        accent = { 0.18, 0.78, 0.72 },
        headerHeight = 44,
    })
    frame._configMinHeight = 250
    frame:Hide()

    local tbar = TitleBar(frame, 22)
    tbar:SetBackdropColor(0.05, 0.12, 0.22, 1)
    tbar:SetScript("OnDragStart", function() frame:StartMoving() end)
    tbar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(FONT_HEADERS, 10, GetFontFlags())
    ttitle:SetText(L["ProfKnowledge_Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    CloseButton(tbar, function() frame:Hide() end)
    frame.body = nil
    return frame
end

PopulateGatheringConfig = function(frame)
    RefreshFonts()
    if frame.body then
        frame.body:EnableMouse(false)
        frame.body:Hide()
        frame.body:SetParent(UIParent)
        frame.body = nil
    end

    local body = CreateFrame("Frame", nil, frame)
    body:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    body:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.body = body

    local db = MR.db.profile
    local yOff, pad = -28, 8
    local contentW = (frame:GetWidth() or 224) - (pad * 2)
    local activePage = MR._gatheringCfgPage or "display"
    local cfgFs = (ns.GetFontSize and ns.GetFontSize()) or (MR.db and MR.db.profile and MR.db.profile.fontSize) or 9

    if activePage ~= "display" and activePage ~= "professions" and activePage ~= "reset" then
        activePage = "display"
        MR._gatheringCfgPage = activePage
    end

    local function Gap(h) yOff = OptionsGap(body, yOff, h) end
    local function Divider() yOff = OptionsDivider(body, yOff, pad) end
    local function SecLabel(text) yOff = OptionsSectionLabel(body, yOff, text, pad, cfgFs) end
    local function Check(label, getValue, setValue, r, g, b)
        yOff = OptionsCheckbox(body, yOff, label, getValue, setValue, r or 0.78, g or 0.78, b or 0.88, pad, function() PopulateGatheringConfig(frame) end, cfgFs)
    end
    local function Slider(label, mn, mx, st, getValue, setValue, r, g, b, disabled)
        yOff = OptionsSlider(body, yOff, label, mn, mx, st, getValue, setValue, r, g, b, pad, disabled, cfgFs)
    end
    local function Btn(label, fn) yOff = OptionsBtn(body, yOff, label, fn, math.max(184, contentW), pad, cfgFs) end

    do
        local tabs = {
            { key = "display", label = L["Config_TabLayout"] or "Layout" },
            { key = "professions", label = L["Config_TabModules"] or "Professions" },
            { key = "reset", label = L["Config_TabReset"] or "Reset" },
        }
        local tabW = math.floor((contentW - 4) / #tabs)
        for i, tab in ipairs(tabs) do
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(tabW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", pad + (i - 1) * (tabW + 2), yOff)
            btn:SetBackdrop(MakeBackdrop())
            local isActive = activePage == tab.key
            btn:SetBackdropColor(isActive and 0.11 or 0.05, isActive and 0.24 or 0.09, isActive and 0.23 or 0.15, 1)
            btn:SetBackdropBorderColor(isActive and 0.22 or 0.16, isActive and 0.82 or 0.28, isActive and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            lbl:SetPoint("CENTER")
            lbl:SetText(tab.label)
            lbl:SetTextColor(isActive and 0.85 or 0.62, isActive and 1.0 or 0.75, isActive and 0.92 or 0.70)

            btn:SetScript("OnClick", function()
                MR._gatheringCfgPage = tab.key
                PopulateGatheringConfig(frame)
            end)
            btn:SetScript("OnEnter", function()
                if activePage ~= tab.key then
                    btn:SetBackdropColor(0.08, 0.18, 0.24, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.90, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = (MR._gatheringCfgPage or "display") == tab.key
                btn:SetBackdropColor(selected and 0.11 or 0.05, selected and 0.24 or 0.09, selected and 0.23 or 0.15, 1)
                btn:SetBackdropBorderColor(selected and 0.22 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.85 or 0.62, selected and 1.0 or 0.75, selected and 0.92 or 0.70)
            end)
        end
        yOff = yOff - 26
    end

    if activePage == "display" then
        SecLabel(L["Config_Display"])
        Check(L["Config_LockPosition"], function() return db.gatheringLocked end, function(value)
            db.gatheringLocked = value
            if gatheringLocationsFrame then gatheringLocationsFrame:SetMovable(not value) end
        end)
        Check(L["Config_HideWhenCompleted"], function() return db.gatheringHideCompleted end, function(value)
            db.gatheringHideCompleted = value
            RebuildGatheringLocationsFrame()
        end)
        Gap(4); Divider()
        SecLabel("Profession Hub")
        Check("Show profession tasks here", function() return db.professionKnowledgeShowTasks ~= false end, function(value)
            db.professionKnowledgeShowTasks = value and true or false
            RebuildGatheringLocationsFrame()
            if MR.RequestUIRefresh then MR:RequestUIRefresh(0.04) end
        end, 0.78, 0.86, 1.00)
        Check("Hide profession tasks from main menu", function() return db.professionKnowledgeHideMainTasks == true end, function(value)
            db.professionKnowledgeHideMainTasks = value and true or false
            if MR.RequestUIRefresh then MR:RequestUIRefresh(0.04) end
        end, 0.78, 0.86, 1.00)
        local hubCategories = GetProfessionKnowledgeTaskCategories()
        for _, categoryKey in ipairs(PROFESSION_TASK_CATEGORY_ORDER) do
            Check(PROFESSION_TASK_CATEGORY_LABELS[categoryKey] or categoryKey, function()
                return hubCategories[categoryKey] ~= false
            end, function(value)
                hubCategories[categoryKey] = value and true or false
                RebuildGatheringLocationsFrame()
                PopulateGatheringConfig(frame)
            end, 0.66, 0.78, 0.92)
        end
        Gap(4); Divider()
        Slider(L["WIDTH"], MIN_W, MAX_W, 10, function() return db.gatheringWidth or DEFAULT_W end, function(value)
            db.gatheringWidth = math.floor(value / 10) * 10
            RebuildGatheringLocationsFrame()
        end, 0.80, 0.53, 0.20)
        Slider(L["HEIGHT"], MIN_H, MAX_H, 10, function() return db.gatheringHeight or DEFAULT_H end, function(value)
            db.gatheringHeight = math.floor(value / 10) * 10
            if gatheringLocationsFrame and not db.gatheringMinimized then gatheringLocationsFrame:SetHeight(db.gatheringHeight) end
        end, 0.60, 0.80, 0.40)
        local syncFs = MR.db.profile.syncWindowFontSize
        Slider(L["Config_FontSize"], 7, 16, 1, function() return db.gatheringFontSize or 9 end, function(value)
            db.gatheringFontSize = math.floor(value)
            RebuildGatheringLocationsFrame()
            PopulateGatheringConfig(frame)
        end, 0.78, 0.55, 0.16, syncFs)
        Slider(L["BACKGROUND"], 0, 1, 0.05, function() return db.gatheringAlpha or 1.0 end, function(value)
            db.gatheringAlpha = math.floor(value * 20) / 20
            RebuildGatheringLocationsFrame()
            PopulateGatheringConfig(frame)
        end, 0.40, 0.40, 0.40)
        Slider(L["SCALE"], 0.5, 2.0, 0.05, function() return db.gatheringScale or 1.0 end, function(value)
            db.gatheringScale = value
            if gatheringLocationsFrame then gatheringLocationsFrame:SetScale(value) end
        end, 0.45, 0.22, 0.82, MR.db.profile.syncWindowScale == true)
    elseif activePage == "professions" then
        SecLabel(L["Config_TabModules"] or "Professions")
        for _, profession in ipairs(PROFESSIONS) do
            local cr, cg, cb = GetProfessionColor(profession.key)
            local row = CreateFrame("Frame", nil, body)
            row:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
            row:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
            row:SetHeight(26)
            local nameLbl
            local toggleBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
            toggleBtn:SetSize(18, 18)
            toggleBtn:SetPoint("LEFT", row, "LEFT", 0, 0)
            toggleBtn:SetBackdrop(MakeBackdrop())
            toggleBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            toggleBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

                local toggleLbl = toggleBtn:CreateFontString(nil, "OVERLAY")
                toggleLbl:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
                toggleLbl:SetPoint("CENTER")
                toggleLbl:SetText(IsProfessionCollapsed(profession.key) and "+" or "-")
                toggleLbl:SetTextColor(0.85, 0.93, 0.98)

                toggleBtn:SetScript("OnClick", function()
                    SetProfessionCollapsed(profession.key, not IsProfessionCollapsed(profession.key))
                    RebuildGatheringLocationsFrame()
                    PopulateGatheringConfig(frame)
                end)

                local swatch = OptionsColorSwatch(row, cr, cg, cb, function(r, g, b)
                    SetProfessionColor(profession.key, r, g, b)
                    if nameLbl then nameLbl:SetTextColor(r, g, b) end
                end, function()
                    ResetProfessionColor(profession.key)
                    local dr, dg, db2 = profession.color[1], profession.color[2], profession.color[3]
                    if nameLbl then nameLbl:SetTextColor(dr, dg, db2) end
                    return dr, dg, db2
                end, profession.label .. L["Color_Reset_Hint"])
                swatch:SetPoint("RIGHT", row, "RIGHT", 0, 0)
                nameLbl = row:CreateFontString(nil, "OVERLAY")
                nameLbl:SetFont(FONT_ROWS, 10, GetFontFlags())
                nameLbl:SetPoint("LEFT", toggleBtn, "RIGHT", 6, 0)
                nameLbl:SetPoint("RIGHT", swatch, "LEFT", -4, 0)
                nameLbl:SetJustifyH("LEFT")
                nameLbl:SetText(profession.label .. (IsProfessionCollapsed(profession.key) and ("  " .. (L["Config_Collapsed"] or "Collapsed")) or ""))
                nameLbl:SetTextColor(cr, cg, cb)
                yOff = yOff - 28
        end
    else
        SecLabel(L["RESETS"])
        Btn(L["Config_ResetColors"], function()
            MR.db.profile.gatheringProfColors = {}
            RebuildGatheringLocationsFrame()
            PopulateGatheringConfig(frame)
        end)
    end

    local totalH = math.abs(yOff) + 10
    if activePage == "display" then
        frame._configMinHeight = math.max(frame._configMinHeight or 0, totalH)
    end
    totalH = math.max(totalH, frame._configMinHeight or totalH)
    frame:SetHeight(totalH)
    body:SetHeight(totalH)
end

function MR:ToggleGatheringLocationsConfig()
    if not gatheringCfgFrame then
        gatheringCfgFrame = BuildGatheringConfigFrame()
        PopulateGatheringConfig(gatheringCfgFrame)
    end
    if gatheringCfgFrame:IsShown() then gatheringCfgFrame:Hide()
    else
        gatheringCfgFrame:Show()
        if gatheringLocationsFrame then
            local x, y = gatheringLocationsFrame:GetCenter()
            if x and y then
                gatheringCfgFrame:ClearAllPoints()
                gatheringCfgFrame:SetPoint("LEFT", gatheringLocationsFrame, "RIGHT", 10, 0)
                gatheringCfgFrame:SetScale(gatheringLocationsFrame:GetScale())
            end
        end
    end
end

local function ToggleGatheringLocations()
    if not gatheringLocationsFrame then
        gatheringLocationsFrame = BuildGatheringLocationsFrame()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", true) end
    elseif gatheringLocationsFrame:IsShown() then
        gatheringLocationsFrame:Hide()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", false) end
    else
        gatheringLocationsFrame:Show()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", true) end
    end
end

MR.ToggleGatheringLocations = ToggleGatheringLocations

function MR:ShowGatheringLocations()
    if not gatheringLocationsFrame then gatheringLocationsFrame = BuildGatheringLocationsFrame() else gatheringLocationsFrame:Show() end
    if self.SetManagedWindowOpen then self:SetManagedWindowOpen("gatheringLocOpen", true) end
end

function MR:EnsureGatheringLocationsShown()
    if not gatheringLocationsFrame then gatheringLocationsFrame = BuildGatheringLocationsFrame() else gatheringLocationsFrame:Show() end
    if self.SetManagedWindowOpen then self:SetManagedWindowOpen("gatheringLocOpen", true) end
end

function MR:RefreshGatheringLocationsFrame()
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self._deferredInstanceGatheringRefresh = true
        return
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("gatheringFrame") then
        return
    end

    if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then RebuildGatheringLocationsFrame() end
end

function MR:HideGatheringLocations(persistState)
    if gatheringLocationsFrame then gatheringLocationsFrame:Hide() end
    if gatheringCfgFrame then gatheringCfgFrame:Hide() end
    if persistState ~= false and self.db then self:SetManagedWindowOpen("gatheringLocOpen", false) end
end

function MR:RepopulateGatheringConfig()
    if gatheringCfgFrame and gatheringCfgFrame:IsShown() then PopulateGatheringConfig(gatheringCfgFrame) end
end

function MR:RebuildGatheringLocationsFrame()
    if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then RebuildGatheringLocationsFrame() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "MidnightRoutine" then
        if MR.db then
            gatheringMinimized = MR.db.profile.gatheringMinimized or false
        end
        eventFrame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if MR.db and MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("gatheringLocOpen") then
            MR:ShowGatheringLocations()
        end
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
    end
end)
