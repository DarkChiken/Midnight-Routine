local _, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local function E(kind, data)
    data.kind = kind
    return data
end

local function T(data) data.mode = data.mode or "single"; return E("treasure", data) end
local function S(data) data.mode = data.mode or "single"; return E("study", data) end
local function WQ(data) data.mode = data.mode or "any"; return E("weeklyQuest", data) end
local function WD(data) data.mode = data.mode or "single"; return E("weeklyDrop", data) end
local function DMF(data) data.mode = "single"; return E("darkmoon", data) end
local function TR(data) data.mode = "single"; return E("treatise", data) end
local function Ref(data) data.mode = "reference"; data.reference = true; return E("reference", data) end

ns.T, ns.S, ns.WQ, ns.WD, ns.DMF, ns.TR, ns.Ref = T, S, WQ, WD, DMF, TR, Ref

ns.DRAGONFLIGHT_CATCHUP_ITEM_ID = 191784

local LEGACY_EXPANSIONS = {}
ns.LegacyExpansions = LEGACY_EXPANSIONS

function ns.RegisterLegacyExpansion(def)
    table.insert(LEGACY_EXPANSIONS, def)
end

local function BuildWeeklyRowsFromEntries(entries, fallbackLabel)
    local rows = {}
    for i, entry in ipairs(entries or {}) do
        if entry.kind ~= "darkmoon" then
            local questIds = entry.questIDs or (entry.questID and { entry.questID }) or nil
            if entry.spellID then
                rows[#rows + 1] = {
                    key = "w" .. i,
                    label = entry.label or entry.note or fallbackLabel,
                    note = entry.note,
                    spellId = entry.spellID,
                    spellAmount = 1,
                    max = 1,
                }
            elseif questIds and #questIds > 0 then
                local required = (entry.mode == "count") and (entry.required or #questIds) or 1
                rows[#rows + 1] = {
                    key = "w" .. i,
                    label = entry.label or entry.note or fallbackLabel,
                    note = entry.note,
                    questIds = questIds,
                    max = required,
                    zone = entry.zone,
                    x = entry.x,
                    y = entry.y,
                    waypointTitle = entry.label or entry.note,
                }
            end
        end
    end
    return rows
end

local function BuildSpellBackfillOnScan(rows)
    local spellRows = {}
    for _, row in ipairs(rows) do
        if row.spellId then
            spellRows[#spellRows + 1] = row
        end
    end
    if #spellRows == 0 then
        return nil
    end

    return function(mod)
        if not ns.IsSpellOnCooldown then
            return false
        end
        local progress = MR.db and MR.db.char and MR.db.char.progress
        if not progress then
            return false
        end

        local dirty = false
        for _, row in ipairs(spellRows) do
            local bucket = progress[mod.key]
            local current = bucket and tonumber(bucket[row.key]) or 0
            local target = row.max or 1
            if current < target and ns.IsSpellOnCooldown(row.spellId) then
                progress[mod.key] = progress[mod.key] or {}
                progress[mod.key][row.key] = target
                dirty = true
            end
        end
        return dirty
    end
end

local function RegisterWeeklyModule(expansionKey, professionKey, professionLabel, skillLine, rows)
    if #rows == 0 then return end
    MR:RegisterModule({
        key = "profknow_" .. expansionKey .. "_" .. professionKey,
        label = professionLabel .. " " .. (L["ProfKnowledge_Section_Weekly"] or "Weekly Knowledge"),
        resetType = "weekly",

        expansionKey = "midnight",
        defaultOpen = false,
        isVisible = function()
            return ns.HasProfessionLearned and ns.HasProfessionLearned(skillLine) or false
        end,
        onScan = BuildSpellBackfillOnScan(rows),
        rows = rows,
    })
end

function ns.RegisterProfessionWeeklyModules(expansionKey, professions)
    for _, profession in ipairs(professions) do
        local rows = BuildWeeklyRowsFromEntries(profession.weekly, profession.label)
        RegisterWeeklyModule(expansionKey, profession.key, profession.label, profession.skillLine, rows)
    end
end

function ns.RegisterMidnightWeeklyModules(professions)
    for _, profession in ipairs(professions) do
        local weeklyEntries
        for _, section in ipairs(profession.sections or {}) do
            if section.key == "weekly" then
                weeklyEntries = section.entries
                break
            end
        end
        local rows = BuildWeeklyRowsFromEntries(weeklyEntries, profession.label)
        RegisterWeeklyModule("midnight", profession.key, profession.label, profession.skillLine, rows)
    end
end
