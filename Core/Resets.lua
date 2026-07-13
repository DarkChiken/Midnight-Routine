local addonName, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local DAY_SECONDS = 24 * 60 * 60
local WEEK_SECONDS = 7 * DAY_SECONDS
local WEEKLY_RESET_SCHEDULE = {
    [1] = { weekday = 3, hour = 3 },
    [2] = { weekday = 4, hour = 3 },
    [3] = { weekday = 3, hour = 3 },
    [4] = { weekday = 4, hour = 3 },
    [5] = { weekday = 4, hour = 3 },
}

local function GetResetTimestampFromCountdown(secondsUntilReset, cycleSeconds)
    if type(secondsUntilReset) ~= "number" then
        return nil
    end

    secondsUntilReset = math.floor(secondsUntilReset)
    if secondsUntilReset < 0 then
        return nil
    end

    local maxExpected = cycleSeconds + (2 * 60 * 60)
    if secondsUntilReset > maxExpected then
        return nil
    end

    return GetServerTime() + secondsUntilReset - cycleSeconds
end

function MR:GetLastDailyTimestamp()
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
        local ts = GetResetTimestampFromCountdown(C_DateAndTime.GetSecondsUntilDailyReset(), DAY_SECONDS)
        if ts then
            return ts
        end
    end

    local cal = C_DateAndTime.GetCurrentCalendarTime()
    if not cal then return nil end
    local now = GetServerTime()
    local secondsSinceMidnight = (cal.hour * 3600) + (cal.minute * 60) + (cal.second or 0)
    return now - secondsSinceMidnight
end

function MR:CheckDailyReset()
    local lastDailyAt = self:GetLastDailyTimestamp()
    if not lastDailyAt then return end
    local prevDailyAt = self.db.char.lastDailyAt
    if not prevDailyAt or prevDailyAt == 0 then
        self.db.char.lastDailyAt = lastDailyAt
        return
    end
    if lastDailyAt > prevDailyAt + 300 then
        if self:ShouldDeferForCombat("dailyReset") then
            return
        end
        self:DoDailyReset()
    end
end

function MR:DoDailyReset()
    if self:ShouldDeferForCombat("dailyReset") then
        return
    end

    local ts = self:GetLastDailyTimestamp()
    if ts then self.db.char.lastDailyAt = ts end
    for _, mod in ipairs(self.modules) do
        if mod.resetType == "daily" then
            self.db.char.progress[mod.key] = {}
            if self.db.char.manualOverrides then
                self.db.char.manualOverrides[mod.key] = nil
            end
        end
    end
    if self.ResetCustomTasksByType then
        self:ResetCustomTasksByType("daily")
    end
    self:RefreshUI()
end

function MR:GetLastResetTimestamp()
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
        local ts = GetResetTimestampFromCountdown(C_DateAndTime.GetSecondsUntilWeeklyReset(), WEEK_SECONDS)
        if ts then
            return ts
        end
    end

    local region    = GetCurrentRegion() or 1
    local resetInfo = WEEKLY_RESET_SCHEDULE[region]
    if not resetInfo then return nil end

    local cal = C_DateAndTime.GetCurrentCalendarTime()
    if not cal then return nil end

    local now                 = GetServerTime()
    local secondsSinceMidnight = (cal.hour * 3600) + (cal.minute * 60) + (cal.second or 0)
    local todayReset          = now - secondsSinceMidnight + (resetInfo.hour * 3600)
    local diffDays            = ((cal.weekday - resetInfo.weekday) + 7) % 7
    local candidate           = todayReset - (diffDays * 24 * 3600)

    if candidate > now then candidate = candidate - (7 * 24 * 3600) end

    return candidate
end

function MR:GetCurrentWeekKey()
    return self:GetLastResetTimestamp() or 0
end

function MR:CheckWeeklyReset()
    local lastResetAt = self:GetLastResetTimestamp()
    if not lastResetAt then return end

    local prevResetAt = self.db.char.lastResetAt

    if not prevResetAt then
        self.db.char.lastResetAt = lastResetAt
        return
    end

    if lastResetAt > prevResetAt + 300 then
        if self:ShouldDeferForCombat("weeklyReset") then
            return
        end
        self:DoWeeklyReset()
    end
end

function MR:DoWeeklyReset()
    if self:ShouldDeferForCombat("weeklyReset") then
        return
    end

    local ts = self:GetLastResetTimestamp()
    if ts then self.db.char.lastResetAt = ts end

    self._scanSuppressedUntil = GetTime() + 15

    for _, mod in ipairs(self.modules) do
        if mod.resetType == "weekly" then
            self.db.char.progress[mod.key] = {}
            if self.db.char.manualOverrides then
                self.db.char.manualOverrides[mod.key] = nil
            end
        end
    end
    if self.ResetCustomTasksByType then
        self:ResetCustomTasksByType("weekly")
    end
    self.db.char.raresKills = {}
    self:RefreshUI()
    self:RequestScan(20)
    print(L["Weekly_Reset"] or "|cff2ae7c6MidnightRoutine:|r Weekly reset applied.")
end

