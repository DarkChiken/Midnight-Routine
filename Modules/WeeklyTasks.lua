local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local SA_ASSIGNMENTS = {
    { quest = 91390, unlock = 94865, name = L["SA_Temple"],    zone = 2437, zoneLabel = L["Zone_ZulAman"] },
    { quest = 91796, unlock = 94866, name = L["SA_Ours"],      zone = 2437, zoneLabel = L["Zone_ZulAman"] },
    { quest = 92063, unlock = 94390, name = L["SA_Hunter"],    zone = 2413, zoneLabel = L["Zone_Harandar"] },
    { quest = 92139, unlock = 95435, name = L["SA_Shade"],     zone = 2395, zoneLabel = L["Zone_EversongWoods"] },
    { quest = 92145, unlock = 92848, name = L["SA_Drink"],     zone = 2395, zoneLabel = L["Zone_EversongWoods"] },
    { quest = 93013, unlock = 94391, name = L["SA_Push"],      zone = 2413, zoneLabel = L["Zone_Harandar"] },
    { quest = 93244, unlock = 94795, name = L["SA_Agents"],    zone = 2405, zoneLabel = L["Zone_Voidstorm"] },
    { quest = 93438, unlock = 94743, name = L["SA_Precision"], zone = 2405, zoneLabel = L["Zone_Voidstorm"] },
}

local UATV_BRANCHES = {
    { quest = 93890, name = L["Unity_Abundance"]     },
    { quest = 93767, name = L["Unity_Arcantina"]     },
    { quest = 94457, name = L["Unity_Battlegrounds"] },
    { quest = 93909, name = L["Unity_Delves"]        },
    { quest = 93911, name = L["Unity_Dungeons"]      },
    { quest = 93769, name = L["Unity_Housing"]       },
    { quest = 93891, name = L["Unity_Legends"]       },
    { quest = 93910, name = L["Unity_Prey"]          },
    { quest = 93912, name = L["Unity_Raids"]         },
    { quest = 93889, name = L["Unity_Soiree"]        },
    { quest = 93892, name = L["Unity_Stormarion"]    },
    { quest = 93913, name = L["Unity_WorldBoss"]     },
    { quest = 93766, name = L["Unity_WorldQuests"]   },
}

local UATV_BRANCH_QUEST_IDS = {
    93890, 93767, 94457, 93909, 93911, 93769, 93891, 93910, 93912, 93889, 93892, 93913, 93766,
}

local HALDURON_WEEKLIES = {
    { quest = 93751, name = L["Halduron_WindrunnerSpire"]     },
    { quest = 93752, name = L["Halduron_MurderRow"]           },
    { quest = 93753, name = L["Halduron_MagistersTerrace"]   },
    { quest = 93754, name = L["Halduron_MaisaraCaverns"]     },
    { quest = 93755, name = L["Halduron_DenOfNalorakk"]      },
    { quest = 93756, name = L["Halduron_BlindingVale"]       },
    { quest = 93757, name = L["Halduron_VoidscarArena"]      },
    { quest = 93758, name = L["Halduron_NexusPointXenas"]    },
    { quest = 95468, name = L["Halduron_HopeDarkestCorners"] },
}

local ARCANTINA_WEEKLIES = {
    { quest = 92319, name = L["Arcantina_AFavorToAxe"] },
    { quest = 92321, name = L["Arcantina_AFrostbittenTally"] },
    { quest = 92320, name = L["Arcantina_StillBehindEnemyPortals"] },
    { quest = 92322, name = L["Arcantina_TimearForeseesProofOfDemise"] },
    { quest = 92323, name = L["Arcantina_WhereTheFireOnceBurned"] },
    { quest = 92324, name = L["Arcantina_UncrownedsColdCase"] },
    { quest = 92325, name = L["Arcantina_HellscreamsHeritage"] },
    { quest = 92326, name = L["Arcantina_TheFragranceOfTheDunes"] },
    { quest = 92327, name = L["Arcantina_AGenerationalMoment"] },
}

local VOID_ASSAULT_WEEKLIES = {
    { quest = 94385, name = L["Zone_EversongWoods"] or "Eversong Woods" },
    { quest = 94386, name = L["Zone_ZulAman"] or "Zul'Aman" },
}

local MIDNIGHT_MAP_IDS = {
    [2393] = true,
    [2395] = true,
    [2405] = true,
    [2413] = true,
    [2437] = true,
    [2576] = true,
}

local function IsPlayerInMidnightArea()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then
        return false
    end

    local mapId = C_Map.GetBestMapForUnit("player")
    local checked = 0
    while mapId and checked < 10 do
        if MIDNIGHT_MAP_IDS[mapId] then
            return true
        end

        local info = C_Map.GetMapInfo(mapId)
        if not info or not info.parentMapID or info.parentMapID == 0 then
            break
        end

        mapId = info.parentMapID
        checked = checked + 1
    end

    return false
end

local function GetMapName(_, fallback)
    return fallback
end

local function ResolveVariantName(variant)
    if not variant then
        return nil
    end

    return MR:GetQuestName(variant.quest, variant.name)
end

local function IsQuestCurrentlyActive(questId)
    if not questId then
        return false
    end

    if C_QuestLog.IsOnQuest(questId) then
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

    if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
        local availableQuests = C_GossipInfo.GetAvailableQuests()
        if availableQuests then
            for _, info in ipairs(availableQuests) do
                if info.questID == questId then
                    return true
                end
            end
        end
    end

    return false
end

local function UpdateRotatingWeeklyQuestState(progressBucket, row, questId)
    if type(progressBucket) ~= "table" or type(row) ~= "table" or not row.key or not questId then
        return false, false
    end

    local seenKey = row.key .. "_seen_active"
    local isActive = IsQuestCurrentlyActive(questId)
    local isCompleted = C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questId) or false
    local wasDone = (tonumber(progressBucket[row.key]) or 0) > 0

    if isActive then
        progressBucket[seenKey] = true
    end

    local isDone = wasDone
    if isCompleted and (isActive or progressBucket[seenKey]) then
        isDone = true
    elseif not isActive and not wasDone then
        isDone = false
    end

    progressBucket[row.key] = isDone and 1 or 0
    row.countText = isDone and (L["Done"] or "Done") or (isActive and (L["Weekly_SA_Count_ActiveSingle"] or "Active") or nil)
    row.countColor = isDone and { 0.4, 0.85, 0.4 } or (isActive and { 1, 0.9, 0.3 } or nil)

    return isActive, isDone
end

local function CollectSpecialAssignments()
    local completed = {}
    local active = {}
    local allowActive = IsPlayerInMidnightArea()

    for _, assignment in ipairs(SA_ASSIGNMENTS) do
        local entry = {
            quest = assignment.quest,
            unlock = assignment.unlock,
            name = MR:GetQuestName(assignment.quest, assignment.name),
            zone = assignment.zone,
            zoneName = GetMapName(assignment.zone, assignment.zoneLabel),
        }

        if C_QuestLog.IsQuestFlaggedCompleted(assignment.quest) then
            table.insert(completed, entry)
        elseif allowActive and (IsQuestCurrentlyActive(assignment.quest) or IsQuestCurrentlyActive(assignment.unlock)) then
            table.insert(active, entry)
        end
    end

    return completed, active
end

local function FindActiveQuestVariant(variants)
    for _, variant in ipairs(variants) do
        if IsQuestCurrentlyActive(variant.quest) then
            return {
                quest = variant.quest,
                name = ResolveVariantName(variant),
            }
        end
    end
    return nil
end

local function CollectQuestVariants(variants)
    local completed = {}
    local active = {}

    for _, variant in ipairs(variants) do
        local entry = {
            quest = variant.quest,
            name = ResolveVariantName(variant),
        }

        if C_QuestLog.IsQuestFlaggedCompleted(variant.quest) then
            table.insert(completed, entry)
        elseif IsQuestCurrentlyActive(variant.quest) then
            table.insert(active, entry)
        end
    end

    return completed, active
end

function MR:DebugSpecialAssignments()
    print("|cff2ae7c6[MidnightRoutine]|r Special Assignment debug:")

    for _, assignment in ipairs(SA_ASSIGNMENTS) do
        print(string.format(
            "  %s | quest=%d completed=%s active=%s | unlock=%d active=%s | zone=%s",
            assignment.name,
            assignment.quest,
            tostring(C_QuestLog.IsQuestFlaggedCompleted(assignment.quest)),
            tostring(IsQuestCurrentlyActive(assignment.quest)),
            assignment.unlock,
            tostring(IsQuestCurrentlyActive(assignment.unlock)),
            tostring(assignment.zoneLabel)
        ))
    end
end

MR:RegisterModule({
    key         = "s1_weekly",
    label       = L["Weekly_SeasonTitle"],
    labelColor  = "#2ae7c6",
    resetType   = "weekly",
    defaultOpen = true,

    onScan = function(mod)
        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end
        db[mod.key]["special_assignment"] = 0
        db[mod.key]["sa_active_name"] = nil
        db[mod.key]["sa_active_names"] = nil
        db[mod.key]["sa_active_zones"] = nil
        db[mod.key]["halduron_active_name"] = nil
        db[mod.key]["halduron_active_names"] = nil
        db[mod.key]["halduron_completed_name"] = nil
        db[mod.key]["halduron_completed_names"] = nil
        db[mod.key]["arcantina_active_name"] = nil
        db[mod.key]["arcantina_active_names"] = nil
        db[mod.key]["arcantina_completed_name"] = nil
        db[mod.key]["arcantina_completed_names"] = nil
        db[mod.key]["void_assault_active_name"] = nil
        db[mod.key]["void_assault_completed_name"] = nil

        local completedAssignments, activeAssignments = CollectSpecialAssignments()
        local totalAssignments = math.max(#completedAssignments + #activeAssignments, 1)
        db[mod.key]["special_assignment"] = #completedAssignments

        local detectedAssignments = (#activeAssignments > 0) and activeAssignments or completedAssignments
        if #detectedAssignments > 0 then
            local names = {}
            local zones = {}
            for _, assignment in ipairs(detectedAssignments) do
                names[#names + 1] = assignment.name
                zones[#zones + 1] = assignment.zoneName or ""
            end
            db[mod.key]["sa_active_name"] = names[1]
            db[mod.key]["sa_active_names"] = table.concat(names, " || ")
            db[mod.key]["sa_active_zones"] = table.concat(zones, " || ")
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "special_assignment" then
                row.max = totalAssignments
                if #activeAssignments > 0 then
                    row.countText = string.format(
                        L["Weekly_SA_Count_Active"] or "%d active",
                        #activeAssignments
                    )
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = string.format(
                        L["Weekly_SA_Note_Multi"] or "Detected %d active special assignments this week. Hover for the full list and zones.",
                        #activeAssignments
                    )
                elseif #completedAssignments > 1 then
                    row.countText = string.format(
                        L["Weekly_SA_Count_Completed"] or "%d done",
                        #completedAssignments
                    )
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = string.format(
                        L["Weekly_SA_Note_CompletedMulti"] or "Completed %d special assignments this week. Hover for the full list and zones.",
                        #completedAssignments
                    )
                elseif #completedAssignments == 1 and totalAssignments == 1 then
                    row.countText = L["Done"] or "Done"
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_SA_Note"]
                elseif #completedAssignments > 0 then
                    row.countText = string.format(
                        L["Weekly_SA_Count_Completed"] or "%d done",
                        #completedAssignments
                    )
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = string.format(
                        L["Weekly_SA_Note_CompletedMulti"] or "Completed %d special assignments this week. Hover for the full list and zones.",
                        #completedAssignments
                    )
                elseif #detectedAssignments == 1 then
                    row.countText = L["Weekly_SA_Count_ActiveSingle"] or "Active"
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_SA_Note"]
                else
                    row.countText = nil
                    row.countColor = nil
                    row.note = L["Weekly_SA_Note"]
                end
                break
            end
        end

        local completedVoidAssaultWeeklies, activeVoidAssaultWeeklies = CollectQuestVariants(VOID_ASSAULT_WEEKLIES)
        if #activeVoidAssaultWeeklies > 0 then
            db[mod.key]["void_assault_active_name"] = activeVoidAssaultWeeklies[1].name
        end
        if #completedVoidAssaultWeeklies > 0 then
            db[mod.key]["void_assault_completed_name"] = completedVoidAssaultWeeklies[1].name
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "void_assaults" then
                local metaDone = C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(95842) or false
                if metaDone or #completedVoidAssaultWeeklies > 0 then
                    row.countText = db[mod.key]["void_assault_completed_name"] or (L["Done"] or "Done")
                    row.countColor = { 0.4, 0.85, 0.4 }
                elseif #activeVoidAssaultWeeklies > 0 then
                    row.countText = db[mod.key]["void_assault_active_name"]
                    row.countColor = { 1, 0.9, 0.3 }
                else
                    row.countText = nil
                    row.countColor = nil
                end
                break
            end
        end

        local completedArcantinaWeeklies, activeArcantinaWeeklies = CollectQuestVariants(ARCANTINA_WEEKLIES)
        if #activeArcantinaWeeklies > 0 then
            local names = {}
            for _, variant in ipairs(activeArcantinaWeeklies) do
                names[#names + 1] = variant.name
            end
            db[mod.key]["arcantina_active_name"] = names[1]
            db[mod.key]["arcantina_active_names"] = table.concat(names, " || ")
        end

        if #completedArcantinaWeeklies > 0 then
            local names = {}
            for _, variant in ipairs(completedArcantinaWeeklies) do
                names[#names + 1] = variant.name
            end
            db[mod.key]["arcantina_weekly"] = 1
            db[mod.key]["arcantina_completed_name"] = names[1]
            db[mod.key]["arcantina_completed_names"] = table.concat(names, " || ")
        else
            db[mod.key]["arcantina_weekly"] = db[mod.key]["arcantina_weekly"] or 0
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "arcantina_weekly" then
                if #activeArcantinaWeeklies > 1 then
                    row.countText = string.format(L["Weekly_SA_Count_Active"] or "%d active", #activeArcantinaWeeklies)
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_Arcantina_Note"]
                elseif #activeArcantinaWeeklies == 1 then
                    row.countText = activeArcantinaWeeklies[1].name
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_Arcantina_Note"]
                elseif #completedArcantinaWeeklies > 1 then
                    row.countText = string.format(L["Weekly_SA_Count_Completed"] or "%d done", #completedArcantinaWeeklies)
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_Arcantina_Note"]
                elseif #completedArcantinaWeeklies == 1 then
                    row.countText = completedArcantinaWeeklies[1].name
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_Arcantina_Note"]
                else
                    row.countText = nil
                    row.countColor = nil
                    row.note = L["Weekly_Arcantina_Note"]
                end
                break
            end
        end

        local completedHalduronWeeklies, activeHalduronWeeklies = CollectQuestVariants(HALDURON_WEEKLIES)
        if #activeHalduronWeeklies > 0 then
            local names = {}
            for _, variant in ipairs(activeHalduronWeeklies) do
                names[#names + 1] = variant.name
            end
            db[mod.key]["halduron_active_name"] = names[1]
            db[mod.key]["halduron_active_names"] = table.concat(names, " || ")
        end

        if #completedHalduronWeeklies > 0 then
            local names = {}
            for _, variant in ipairs(completedHalduronWeeklies) do
                names[#names + 1] = variant.name
            end
            db[mod.key]["halduron_weekly"] = 1
            db[mod.key]["halduron_completed_name"] = names[1]
            db[mod.key]["halduron_completed_names"] = table.concat(names, " || ")
        else
            db[mod.key]["halduron_weekly"] = db[mod.key]["halduron_weekly"] or 0
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "halduron_weekly" then
                if #activeHalduronWeeklies > 1 then
                    row.countText = string.format(L["Weekly_SA_Count_Active"] or "%d active", #activeHalduronWeeklies)
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_Halduron_Note"]
                elseif #activeHalduronWeeklies == 1 then
                    row.countText = activeHalduronWeeklies[1].name
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_Halduron_Note"]
                elseif #completedHalduronWeeklies > 1 then
                    row.countText = string.format(L["Weekly_SA_Count_Completed"] or "%d done", #completedHalduronWeeklies)
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_Halduron_Note"]
                elseif #completedHalduronWeeklies == 1 then
                    row.countText = completedHalduronWeeklies[1].name
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_Halduron_Note"]
                else
                    row.countText = nil
                    row.countColor = nil
                    row.note = L["Weekly_Halduron_Note"]
                end
                break
            end
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "call_to_delves" then
                UpdateRotatingWeeklyQuestState(db[mod.key], row, 93595)
                break
            end
        end

        local activeUATVBranch = FindActiveQuestVariant(UATV_BRANCHES)
        db[mod.key]["uatv_branch_name"] = activeUATVBranch and activeUATVBranch.name or nil
        db[mod.key]["uatv_branch_quest"] = activeUATVBranch and activeUATVBranch.quest or nil
        db[mod.key]["uatv_completed_branch_name"] = nil
        db[mod.key]["unity_against_void"] = db[mod.key]["unity_against_void"] or 0

        if C_QuestLog.IsQuestFlaggedCompleted(93744) then
            db[mod.key]["unity_against_void"] = 1
        else
            for _, branch in ipairs(UATV_BRANCHES) do
                if C_QuestLog.IsQuestFlaggedCompleted(branch.quest) then
                    db[mod.key]["unity_against_void"] = 1
                    db[mod.key]["uatv_completed_branch_name"] = branch.name
                    break
                end
            end
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "unity_against_void" then
                local completedBranch = db[mod.key]["uatv_completed_branch_name"]
                local activeBranch = db[mod.key]["uatv_branch_name"]
                local unityProgress = db[mod.key]["unity_against_void"] or 0

                if completedBranch or unityProgress >= 1 then
                    row.countText = completedBranch or (L["Done"] or "Done")
                    row.countColor = { 0.4, 0.85, 0.4 }
                elseif activeBranch then
                    row.countText = activeBranch
                    row.countColor = { 1, 0.9, 0.3 }
                else
                    row.countText = nil
                    row.countColor = nil
                end
                break
            end
        end

        local soireeVariants = {
            { quest = 91966, name = "Saltheril's Soiree" },
            { quest = 89289, name = L["Weekly_Soiree_Label"] },
        }
        local activeSoireeVariant = FindActiveQuestVariant(soireeVariants)
        db[mod.key]["soiree_active_quest"] = activeSoireeVariant and activeSoireeVariant.quest or nil
        db[mod.key]["soiree_active_name"] = activeSoireeVariant and activeSoireeVariant.name or nil
        db[mod.key]["soiree_completed_name"] = nil

        for _, variant in ipairs(soireeVariants) do
            if C_QuestLog.IsQuestFlaggedCompleted(variant.quest) then
                db[mod.key]["saltherils_soiree"] = 1
                db[mod.key]["soiree_completed_name"] = variant.name
                break
            end
        end

    end,

    rows = {
        {
            key      = "void_assaults",
            label    = L["Weekly_VoidAssaults_Label"] or "|cff2ae7c6Void Assaults:|r",
            max      = 1,
            note     = L["Weekly_VoidAssaults_Note"] or "Complete the active Void Assault weekly in Eversong Woods or Zul'Aman for a Spark of Radiance.",
            questIds = { 95842, 94385, 94386 },
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(VOID_ASSAULT_WEEKLIES)
                local s1db = MR.db.char.progress["s1_weekly"] or {}
                local completedName = s1db["void_assault_completed_name"]
                local activeName = s1db["void_assault_active_name"]

                tip:AddLine(" ")
                if completedName or #completedVariants > 0 or (C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(95842)) then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (completedName or completedVariants[1].name or (L["Done"] or "Done")), 0.4, 0.85, 0.4)
                elseif activeName or #activeVariants > 0 then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (activeName or activeVariants[1].name), 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_VoidAssaults"] or "|cffaaaaaa? No Void Assault weekly detected.|r", 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_VoidAssaults"] or "  Visit the active assault zone in Eversong Woods or Zul'Aman.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "ritual_sites",
            label    = L["Weekly_RitualSites_Label"] or "|cff2ae7c6Ritual Sites:|r",
            max      = 1,
            note     = L["Weekly_RitualSites_Note"] or "Complete a Ritual Site in Midnight for a Spark of Radiance.",
            questIds = { 95843 },
            tooltipFunc = function(tip)
                tip:AddLine(" ")
                if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(95843) then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (L["Weekly_RitualSites_Label"] or "Ritual Sites"), 0.4, 0.85, 0.4)
                elseif IsQuestCurrentlyActive(95843) then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (L["Weekly_RitualSites_Label"] or "Ritual Sites"), 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_RitualSites"] or "|cffaaaaaa? Ritual Sites weekly not yet detected.|r", 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_RitualSites"] or "  Complete a Ritual Site in the active location to reveal this week's progress.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "elementary_voidcore",
            label    = L["Weekly_Voidforge_Label"] or "|cff2ae7c6An Elementary Voidcore:|r",
            max      = 1,
            note     = L["Weekly_Voidforge_Note"] or "Collect 3 Elementary Voidcore Shards for Decimus. This repeating construction quest advances the Voidforge unlock.",
            questIds = { 94625 },
            tooltipFunc = function(tip)
                tip:AddLine(" ")
                if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(94625) then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (L["Weekly_Voidforge_Label"] or "An Elementary Voidcore"), 0.4, 0.85, 0.4)
                elseif IsQuestCurrentlyActive(94625) then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (L["Weekly_Voidforge_Label"] or "An Elementary Voidcore"), 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Voidforge"] or "|cffaaaaaa? An Elementary Voidcore is not yet active.|r", 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Voidforge"] or "  Visit Decimus in Voidstorm when the Voidforge construction quest is available.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "arcantina_weekly",
            label    = L["Weekly_Arcantina_Label"],
            max      = 1,
            note     = L["Weekly_Arcantina_Note"],
            turnInTracked = true,
            questIds = { 92319, 92321, 92320, 92322, 92323, 92324, 92325, 92326, 92327 },
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(ARCANTINA_WEEKLIES)

                tip:AddLine(" ")
                if #activeVariants > 0 then
                    tip:AddLine(L["Tooltip_Active_Week"], 1, 1, 1)
                    for _, variant in ipairs(activeVariants) do
                        tip:AddLine("  " .. variant.name, 1, 0.9, 0.3)
                    end
                elseif #completedVariants > 0 then
                    tip:AddLine(L["Tooltip_Done_Completed"], 1, 1, 1)
                    for _, variant in ipairs(completedVariants) do
                        tip:AddLine("  " .. variant.name, 0.4, 0.85, 0.4)
                    end
                else
                    tip:AddLine(L["Tooltip_No_Arcantina"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Arcantina"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "halduron_weekly",
            label    = L["Weekly_Halduron_Label"],
            max      = 1,
            note     = L["Weekly_Halduron_Note"],
            questIds = { 93753, 93754, 93755, 93756, 93757, 93758, 95468 },
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(HALDURON_WEEKLIES)

                tip:AddLine(" ")
                if #activeVariants > 0 then
                    tip:AddLine(L["Tooltip_Active_Week"], 1, 1, 1)
                    for _, variant in ipairs(activeVariants) do
                        tip:AddLine("  " .. variant.name, 1, 0.9, 0.3)
                    end
                elseif #completedVariants > 0 then
                    tip:AddLine(L["Tooltip_Done_Completed"], 1, 1, 1)
                    for _, variant in ipairs(completedVariants) do
                        tip:AddLine("  " .. variant.name, 0.4, 0.85, 0.4)
                    end
                else
                    tip:AddLine(L["Tooltip_No_Halduron"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Halduron"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "call_to_delves",
            label    = L["Weekly_CallToDelves_Label"],
            max      = 1,
            note     = L["Delves_Call_Note"],
            isVisible = function()
                local mdb = MR and MR.db and MR.db.char and MR.db.char.progress and MR.db.char.progress["s1_weekly"]
                return IsQuestCurrentlyActive(93595) or ((mdb and tonumber(mdb["call_to_delves"])) or 0) > 0
            end,
        },
        {
            key      = "abundance",
            label    = L["Weekly_Abundance_Label"],
            max      = 1,
            questIds = { 89507 },
        },
        {
            key      = "lost_legends",
            label    = L["Weekly_Legends_Label"],
            max      = 1,
            questIds = { 89268 }, 
        },
        {
            key      = "saltherils_soiree",
            label    = L["Weekly_Soiree_Label"],
            max      = 1,
            note     = L["Weekly_Soiree_Note"],
            turnInTracked = true,
            questIds = { 89289, 91966 }, 
            tooltipFunc = function(tip)
                local variants = {
                    { quest = 91966, name = "Saltheril's Soiree" },
                    { quest = 89289, name = L["Weekly_Soiree_Label"] },
                }

                local s1db = MR.db.char.progress["s1_weekly"] or {}
                local completedName = (MR:GetProgress("s1_weekly", "saltherils_soiree") >= 1 and s1db["soiree_completed_name"]) or nil
                local activeName = s1db["soiree_active_name"]

                tip:AddLine(" ")
                if completedName then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. completedName, 0.4, 0.85, 0.4)
                elseif activeName then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. activeName, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Soiree"], 1, 1, 1)
                end
            end,
        },
        {
            key      = "fortify_runestones",
            label    = L["Weekly_Fortify_Label"],
            max      = 1,
            note     = L["Weekly_Fortify_Note"],
            questIds = { 90573, 90574, 90575, 90576 },

            tooltipFunc = function(tip)
                local variants = {
                    { quest = 90573, name = L["Magisters"]                },
                    { quest = 90574, name = L["Subfaction_BloodKnights"]  },
                    { quest = 90575, name = L["Farstriders"]              },
                    { quest = 90576, name = L["Subfaction_ShadesOfTheRow"] },
                }
                local completedName, activeName = nil, nil
                for _, v in ipairs(variants) do
                    if C_QuestLog.IsQuestFlaggedCompleted(v.quest) then
                        completedName = v.name; break
                    end
                end
                if not completedName then
                    for _, v in ipairs(variants) do
                        if IsQuestCurrentlyActive(v.quest) then
                            activeName = v.name; break
                        end
                    end
                end
                tip:AddLine(" ")
                if completedName then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. completedName, 0.4, 0.85, 0.4)
                elseif activeName then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. activeName, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Subfaction"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Haven"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "unity_against_void",
            label    = L["Weekly_Unity_Label"],
            max      = 1,
            note     = L["Weekly_Unity_Note"],
            turnInTracked = true,
            questIds = { 93744 },
            branchQuestIds = UATV_BRANCH_QUEST_IDS,

            isVisible = function()
                for _, qid in ipairs(UATV_BRANCH_QUEST_IDS) do
                    if IsQuestCurrentlyActive(qid) or C_QuestLog.IsQuestFlaggedCompleted(qid) then
                        return true
                    end
                end
                return IsQuestCurrentlyActive(93744)
                    or C_QuestLog.IsQuestFlaggedCompleted(93744)
                    or MR:GetProgress("s1_weekly", "unity_against_void") >= 1
            end,

            tooltipFunc = function(tip)
                local s1db = MR.db.char.progress["s1_weekly"] or {}
                local activeBranchInfo = FindActiveQuestVariant(UATV_BRANCHES)
                local completedBranch = (MR:GetProgress("s1_weekly", "unity_against_void") >= 1 and s1db["uatv_completed_branch_name"]) or nil
                local activeBranch = (activeBranchInfo and activeBranchInfo.name) or s1db["uatv_branch_name"]

                tip:AddLine(" ")
                if completedBranch or MR:GetProgress("s1_weekly", "unity_against_void") >= 1 then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    if completedBranch then
                        tip:AddLine("  " .. completedBranch, 0.4, 0.85, 0.4)
                    end
                elseif activeBranch then
                    tip:AddLine(L["Tooltip_Active_Progress"], 1, 1, 1)
                    tip:AddLine("  " .. activeBranch, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Activity"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Pick_Activity"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "special_assignment",
            label    = L["Weekly_SA_Label"],
            max      = 1,
            note     = L["Weekly_SA_Note"],

            questIds = { 91390, 91796, 92063, 92139, 92145, 93013, 93244, 93438 },
            tooltipFunc = function(tip)
                local completedAssignments, activeAssignments = CollectSpecialAssignments()
                local zoneLabel = L["Tooltip_SA_Zone"] or "Zone:"

                tip:AddLine(" ")
                if #activeAssignments > 0 then
                    tip:AddLine(L["Tooltip_Active_Week"], 1, 1, 1)
                    for _, assignment in ipairs(activeAssignments) do
                        tip:AddLine("  " .. assignment.name, 1, 0.9, 0.3)
                        if assignment.zoneName then
                            tip:AddLine("    " .. zoneLabel .. " " .. assignment.zoneName, 0.65, 0.82, 1)
                        end
                    end
                elseif #completedAssignments > 0 then
                    tip:AddLine(L["Tooltip_Done_Completed"], 1, 1, 1)
                    for _, assignment in ipairs(completedAssignments) do
                        tip:AddLine("  " .. assignment.name, 0.4, 0.85, 0.4)
                        if assignment.zoneName then
                            tip:AddLine("    " .. zoneLabel .. " " .. assignment.zoneName, 0.55, 0.7, 0.55)
                        end
                    end
                else
                    tip:AddLine(L["Tooltip_No_Assignment"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Silvermoon"], 0.7, 0.7, 0.7)
                end
            end,
        },
    },
})
