local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local CUSTOM_MODULE_KEY = "custom_tasks"
local DAILY_HEADER_KEY = "__custom_task_daily_header"
local WEEKLY_HEADER_KEY = "__custom_task_weekly_header"
local DAILY_ADD_ROW_KEY = "__custom_task_add_daily"
local WEEKLY_ADD_ROW_KEY = "__custom_task_add_weekly"

local function TrimText(value)
    value = tostring(value or "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

local function GetTaskStorage()
    if not (MR and MR.db and MR.db.char) then
        return nil
    end

    MR.db.char.customTasks = MR.db.char.customTasks or {}
    MR.db.char.customTaskNextId = tonumber(MR.db.char.customTaskNextId) or 1
    return MR.db.char.customTasks
end

local function GetTaskRowKey(taskId)
    return ("task_%s"):format(tostring(taskId))
end

local function NormalizeResetType(resetType)
    return resetType == "daily" and "daily" or "weekly"
end

local function NormalizeTaskMax(maxValue)
    local value = tonumber(maxValue) or 1
    value = math.floor(value)
    if value < 1 then
        value = 1
    elseif value > 999 then
        value = 999
    end
    return value
end

local function NormalizeQuestIds(value)
    if value == nil or value == "" then
        return nil
    end

    local ids = {}
    local seen = {}

    local function addQuestId(raw)
        local questId = tonumber(raw)
        if not questId then
            return
        end

        questId = math.floor(questId)
        if questId <= 0 or seen[questId] then
            return
        end

        seen[questId] = true
        ids[#ids + 1] = questId
    end

    if type(value) == "table" then
        for _, entry in ipairs(value) do
            addQuestId(entry)
        end
    elseif type(value) == "number" then
        addQuestId(value)
    elseif type(value) == "string" then
        for token in value:gmatch("%d+") do
            addQuestId(token)
        end
    end

    if #ids == 0 then
        return nil
    end

    table.sort(ids)
    return ids
end

local function GetQuestFrequencyResetType(questId)
    if not questId or not C_QuestLog then
        return nil
    end

    local logIndex = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questId)
    if logIndex and logIndex > 0 and C_QuestLog.GetInfo then
        local info = C_QuestLog.GetInfo(logIndex)
        local frequency = info and info.frequency
        local dailyValue = (Enum and Enum.QuestFrequency and Enum.QuestFrequency.Daily) or 1
        local weeklyValue = (Enum and Enum.QuestFrequency and Enum.QuestFrequency.Weekly) or 2

        if frequency == dailyValue then
            return "daily"
        elseif frequency == weeklyValue then
            return "weekly"
        end
    end

    if GetQuestID and GetQuestID() == questId then
        if QuestIsDaily and QuestIsDaily() then
            return "daily"
        end
        if QuestIsWeekly and QuestIsWeekly() then
            return "weekly"
        end
    end

    return nil
end

local function ResolveQuestResetType(questIds, fallbackResetType)
    if type(questIds) ~= "table" then
        return NormalizeResetType(fallbackResetType)
    end

    for _, questId in ipairs(questIds) do
        local resetType = GetQuestFrequencyResetType(questId)
        if resetType then
            return resetType
        end
    end

    return NormalizeResetType(fallbackResetType)
end

local function BuildQuestIdsText(questIds)
    if type(questIds) ~= "table" or #questIds == 0 then
        return nil
    end

    local values = {}
    for _, questId in ipairs(questIds) do
        values[#values + 1] = tostring(questId)
    end
    return table.concat(values, ", ")
end

local function NormalizeBoolean(value)
    return value == true
end

local RefreshCustomTaskViews

local function SortTasks(tasks)
    table.sort(tasks, function(a, b)
        local aOrder = tonumber(a and a.order) or 0
        local bOrder = tonumber(b and b.order) or 0
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end

        local aId = tonumber(a and a.id) or 0
        local bId = tonumber(b and b.id) or 0
        return aId < bId
    end)
end

function MR:GetCustomTaskRowKey(taskId)
    return GetTaskRowKey(taskId)
end

function MR:GetCustomTasks()
    local tasks = GetTaskStorage() or {}
    for index, task in ipairs(tasks) do
        task.id = tonumber(task.id) or index
        task.label = TrimText(task.label ~= "" and task.label or (L["CustomTasks_Untitled"] or "Untitled Task"))
        task.max = NormalizeTaskMax(task.max)
        task.order = tonumber(task.order) or index
        task.questIds = NormalizeQuestIds(task.questIds or task.questId)
        task.resetType = ResolveQuestResetType(task.questIds, task.resetType)
        task.allowManualQuestClicks = NormalizeBoolean(task.allowManualQuestClicks)
        task.questId = nil
    end
    SortTasks(tasks)
    return tasks
end

function MR:GetCustomTasksTitle()
    if not (self and self.db and self.db.char) then
        return L["CustomTasks_Title"] or "Custom Tasks"
    end

    local savedTitle = TrimText(self.db.char.customTasksTitle)
    if savedTitle == "" then
        return L["CustomTasks_Title"] or "Custom Tasks"
    end

    return savedTitle
end

function MR:SetCustomTasksTitle(title)
    if not (self and self.db and self.db.char) then
        return false
    end

    local cleanTitle = TrimText(title)
    if cleanTitle == "" then
        cleanTitle = L["CustomTasks_Title"] or "Custom Tasks"
    end

    self.db.char.customTasksTitle = cleanTitle
    RefreshCustomTaskViews(self)
    return true
end

function MR:GetCustomTaskById(taskId)
    taskId = tonumber(taskId)
    if not taskId then
        return nil
    end

    for _, task in ipairs(self:GetCustomTasks()) do
        if tonumber(task.id) == taskId then
            return task
        end
    end

    return nil
end

RefreshCustomTaskViews = function(self)
    if self.RefreshCustomTasksModule then
        self:RefreshCustomTasksModule()
    end
    if self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
    if self.RefreshUI then
        self:RefreshUI()
    end
end

local function BuildSectionRows(rows, tasks, resetType, headerKey, addKey, headerLabel, headerNote, addLabel)
    local doneCount = 0
    local addRowVisible = MR:IsRowEnabled(CUSTOM_MODULE_KEY, addKey)
    for _, task in ipairs(tasks) do
        if NormalizeResetType(task.resetType) == resetType then
            if tonumber(MR:GetProgress(CUSTOM_MODULE_KEY, GetTaskRowKey(task.id))) >= NormalizeTaskMax(task.max) then
                doneCount = doneCount + 1
            end
        end
    end

    rows[#rows + 1] = {
        key = headerKey,
        label = headerLabel,
        note = headerNote,
        control = true,
        sectionHeader = true,
        hideStatus = true,
        noDefaultTooltipHint = true,
        countText = string.format("%d / %d", doneCount, #tasks),
        countColor = { 0.74, 0.80, 0.88 },
        headerActionStyle = "visibility",
        headerActionVisible = addRowVisible,
        headerActionTooltip = addRowVisible
            and (L["CustomTasks_HideAddRow"] or "Click to hide the add-task row for this section.")
            or (L["CustomTasks_ShowAddRow"] or "Click to show the add-task row for this section."),
        onHeaderActionClick = function()
            MR:SetRowEnabled(CUSTOM_MODULE_KEY, addKey, not addRowVisible)
            RefreshCustomTaskViews(MR)
        end,
    }

    for _, task in ipairs(tasks) do
        if NormalizeResetType(task.resetType) == resetType then
            local taskId = tonumber(task.id)
            if taskId then
                local rowKey = GetTaskRowKey(taskId)
                local resetLabel = (resetType == "daily")
                    and (L["CustomTasks_ResetDaily"] or "Daily reset")
                    or (L["CustomTasks_ResetWeekly"] or "Weekly reset")
                local questIds = NormalizeQuestIds(task.questIds)
                local questIdText = BuildQuestIdsText(questIds)
                local noteText
                if questIds then
                    noteText = string.format(
                        "%s\n%s",
                        resetLabel,
                        string.format(
                            L["CustomTasks_QuestNote"] or "Auto-tracks quest completion for quest ID%s %s. Shift-left-click to edit. Shift-right-click to delete.",
                            (#questIds == 1) and "" or "s",
                            questIdText or ""
                        )
                    )
                else
                    noteText = string.format(
                        "%s\n%s",
                        resetLabel,
                        (task.max > 1)
                            and (L["CustomTasks_CounterNote"] or "Left-click to add progress. Right-click to remove progress. Shift-left-click to edit. Shift-right-click to delete.")
                            or (L["CustomTasks_TaskNote"] or "Left-click the checkbox to toggle. Shift-left-click to rename. Shift-right-click to delete.")
                    )
                end
                rows[#rows + 1] = {
                    key = rowKey,
                    label = task.label,
                    max = task.max,
                    note = noteText,
                    toggleStatus = (task.max <= 1) and ((not questIds) or task.allowManualQuestClicks),
                    questIds = questIds,
                    allowManualQuestClicks = task.allowManualQuestClicks,
                    noDefaultTooltipHint = true,
                    tooltipFunc = function(tip)
                        tip:AddLine(" ")
                        tip:AddLine(resetLabel, 0.80, 0.90, 1.00, true)
                        if questIds then
                            tip:AddLine(
                                string.format(
                                    L["CustomTasks_QuestHint"] or "Tracks quest completion automatically for quest ID%s %s.",
                                    (#questIds == 1) and "" or "s",
                                    questIdText or ""
                                ),
                                0.70, 0.90, 0.70, true
                            )
                            if task.allowManualQuestClicks then
                                tip:AddLine(L["CustomTasks_QuestManualHint"] or "Manual clicking is enabled for this quest task.", 0.95, 0.82, 0.50, true)
                            end
                        elseif task.max > 1 then
                            tip:AddLine(L["CustomTasks_CounterIncreaseHint"] or "Left-click to add progress", 0.70, 0.90, 0.70, true)
                            tip:AddLine(L["CustomTasks_CounterDecreaseHint"] or "Right-click to remove progress", 1, 0.80, 0.45, true)
                        else
                            tip:AddLine(L["CustomTasks_CheckboxHint"] or "Left-click the checkbox to toggle complete", 0.70, 0.90, 0.70, true)
                        end
                        tip:AddLine(L["CustomTasks_EditHint"] or "Shift-left-click to rename", 0.45, 0.85, 1, true)
                        tip:AddLine(L["CustomTasks_DeleteHint"] or "Shift-right-click to delete", 1, 0.55, 0.55, true)
                    end,
                    onLeftClick = function(row)
                        if IsShiftKeyDown() and MR.ShowCustomTaskDialog then
                            MR:ShowCustomTaskDialog(taskId)
                            return true
                        end
                        return false
                    end,
                    onRightClick = function(row)
                        if IsShiftKeyDown() then
                            MR:DeleteCustomTask(taskId)
                            return true
                        end
                        return false
                    end,
                }
            end
        end
    end

    rows[#rows + 1] = {
        key = addKey,
        label = addLabel,
        note = L["CustomTasks_AddNote"] or "Click to create a new custom task for this character.",
        control = true,
        hideStatus = true,
        noDefaultTooltipHint = true,
        countText = L["CustomTasks_AddButton"] or "[ + ]",
        countColor = { 0.92, 0.78, 0.24 },
        onLeftClick = function()
            if MR.ShowCustomTaskDialog then
                MR:ShowCustomTaskDialog(nil, resetType)
            end
            return true
        end,
        onRightClick = function()
            if MR.ShowCustomTaskDialog then
                MR:ShowCustomTaskDialog(nil, resetType)
            end
            return true
        end,
    }
end

function MR:AddCustomTask(label, resetType, maxValue, questIds, allowManualQuestClicks)
    local tasks = GetTaskStorage()
    local cleanLabel = TrimText(label)
    if not tasks or cleanLabel == "" then
        return nil
    end

    questIds = NormalizeQuestIds(questIds)
    resetType = ResolveQuestResetType(questIds, resetType)
    allowManualQuestClicks = NormalizeBoolean(allowManualQuestClicks)

    local taskId = tonumber(self.db.char.customTaskNextId) or 1
    self.db.char.customTaskNextId = taskId + 1

    tasks[#tasks + 1] = {
        id = taskId,
        label = cleanLabel,
        max = NormalizeTaskMax(maxValue),
        order = #tasks + 1,
        resetType = resetType,
        questIds = questIds,
        allowManualQuestClicks = allowManualQuestClicks,
    }

    RefreshCustomTaskViews(self)
    if questIds and self.RefreshQuestProgress then
        self:RefreshQuestProgress(nil, true)
    end
    return taskId
end

function MR:UpdateCustomTask(taskId, label, resetType, maxValue, questIds, allowManualQuestClicks)
    local task = self:GetCustomTaskById(taskId)
    local cleanLabel = TrimText(label)
    if not task or cleanLabel == "" then
        return false
    end

    questIds = NormalizeQuestIds(questIds)
    resetType = ResolveQuestResetType(questIds, resetType)
    allowManualQuestClicks = NormalizeBoolean(allowManualQuestClicks)
    task.label = cleanLabel
    task.resetType = resetType
    task.max = NormalizeTaskMax(maxValue)
    task.questIds = questIds
    task.allowManualQuestClicks = allowManualQuestClicks
    RefreshCustomTaskViews(self)
    if self.RefreshQuestProgress then
        self:RefreshQuestProgress(nil, true)
    end
    return true
end

function MR:ToggleCustomTask(taskId)
    local task = self:GetCustomTaskById(taskId)
    if not task then
        return false
    end

    local rowKey = GetTaskRowKey(task.id)
    local cur = tonumber(self:GetProgress(CUSTOM_MODULE_KEY, rowKey)) or 0
    self:SetProgress(CUSTOM_MODULE_KEY, rowKey, cur >= 1 and 0 or 1, 1)
    return true
end

function MR:ResetCustomTasksByType(resetType)
    resetType = NormalizeResetType(resetType)
    local tasks = self:GetCustomTasks()
    local progress = self.db and self.db.char and self.db.char.progress and self.db.char.progress[CUSTOM_MODULE_KEY]
    local overrides = self.db and self.db.char and self.db.char.manualOverrides and self.db.char.manualOverrides[CUSTOM_MODULE_KEY]
    if not tasks or (not progress and not overrides) then
        return
    end

    for _, task in ipairs(tasks) do
        if NormalizeResetType(task.resetType) == resetType then
            local rowKey = GetTaskRowKey(task.id)
            if progress then
                progress[rowKey] = nil
            end
            if overrides then
                overrides[rowKey] = nil
            end
        end
    end
end

function MR:DeleteCustomTask(taskId)
    local tasks = GetTaskStorage()
    taskId = tonumber(taskId)
    if not tasks or not taskId then
        return false
    end

    local removed = false
    for index = #tasks, 1, -1 do
        if tonumber(tasks[index].id) == taskId then
            table.remove(tasks, index)
            removed = true
            break
        end
    end

    if not removed then
        return false
    end

    SortTasks(tasks)
    for index, task in ipairs(tasks) do
        task.order = index
    end

    local rowKey = GetTaskRowKey(taskId)
    if self.db.char.progress and self.db.char.progress[CUSTOM_MODULE_KEY] then
        self.db.char.progress[CUSTOM_MODULE_KEY][rowKey] = nil
    end
    if self.db.char.manualOverrides and self.db.char.manualOverrides[CUSTOM_MODULE_KEY] then
        self.db.char.manualOverrides[CUSTOM_MODULE_KEY][rowKey] = nil
    end
    if self.db.profile.rowColors and self.db.profile.rowColors[CUSTOM_MODULE_KEY] then
        self.db.profile.rowColors[CUSTOM_MODULE_KEY][rowKey] = nil
    end

    local storage = self:GetActiveModuleStorage()
    if storage and storage[CUSTOM_MODULE_KEY] and storage[CUSTOM_MODULE_KEY].hiddenRows then
        storage[CUSTOM_MODULE_KEY].hiddenRows[rowKey] = nil
    end

    RefreshCustomTaskViews(self)
    return true
end

function MR:RefreshCustomTasksModule()
    local mod = self.moduleByKey and self.moduleByKey[CUSTOM_MODULE_KEY]
    if not mod then
        return
    end

    local rows = {}
    local tasks = self:GetCustomTasks()
    local dailyTasks = {}
    local weeklyTasks = {}
    for _, task in ipairs(tasks) do
        if NormalizeResetType(task.resetType) == "daily" then
            dailyTasks[#dailyTasks + 1] = task
        else
            weeklyTasks[#weeklyTasks + 1] = task
        end
    end

    BuildSectionRows(
        rows,
        dailyTasks,
        "daily",
        DAILY_HEADER_KEY,
        DAILY_ADD_ROW_KEY,
        L["CustomTasks_DailyHeader"] or "Daily",
        L["CustomTasks_DailyNote"] or "Resets automatically at the daily reset.",
        L["CustomTasks_AddDailyLabel"] or "Add daily task"
    )
    BuildSectionRows(
        rows,
        weeklyTasks,
        "weekly",
        WEEKLY_HEADER_KEY,
        WEEKLY_ADD_ROW_KEY,
        L["CustomTasks_WeeklyHeader"] or "Weekly",
        L["CustomTasks_WeeklyNote"] or "Resets automatically at the weekly reset.",
        L["CustomTasks_AddWeeklyLabel"] or "Add weekly task"
    )

    mod.rows = rows
    mod.label = self:GetCustomTasksTitle()
    self._moduleStatsCache = nil
    self._orderedModulesCache = nil
end

MR:RegisterModule({
    key = CUSTOM_MODULE_KEY,
    label = L["CustomTasks_Title"] or "Custom Tasks",
    labelColor = "#b07cff",
    defaultOpen = true,
    rows = {},
})
