local _, ns = ...
local MR = ns.MR

local FONT_HEADERS = ns.FONT_HEADERS
local FONT_ROWS = ns.FONT_ROWS
local StyledFrame = ns.StyledFrame
local RestoreFramePos = ns.RestoreFramePos
local TopAccent = ns.TopAccent
local LeftAccent = ns.LeftAccent
local TitleBar = ns.TitleBar
local CloseButton = ns.CloseButton
local HeaderIconButton = ns.HeaderIconButton
local HeaderToggleButton = ns.HeaderToggleButton
local MakeBackdrop = ns.MakeBackdrop
local Hex = ns.Hex
local OptionsGap = ns.OptionsGap
local OptionsDivider = ns.OptionsDivider
local OptionsSectionLabel = ns.OptionsSectionLabel
local OptionsCheckbox = ns.OptionsCheckbox
local OptionsBtn = ns.OptionsBtn
local OptionsSlider = ns.OptionsSlider
local OptionsColorSwatch = ns.OptionsColorSwatch
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)
local GetOrderedFactions
local GetFactionColor
local SetFactionColor
local ResetFactionColor
local RefreshRenownFrame
local RebuildRenownFrame
local SaveFactionOrder
local PopulateRenownConfig

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
        local flags = ns.GetFontFlags()
        if flags ~= nil then
            return flags
        end
    end

    return "OUTLINE"
end

local BASE_FACTIONS = {
    {
        key       = "silvermoon",
        label     = L["Faction_SilvermoonCourt"],
        factionId = 2710,
        maxRenown = 20,
        color     = { 0.85, 0.72, 0.18 },
        hex       = "d9b82e",
    },
    {
        key       = "amani",
        label     = L["Faction_AmaniTribe"],
        factionId = 2696,
        maxRenown = 20,
        color     = { 0.82, 0.36, 0.14 },
        hex       = "d15c24",
    },
    {
        key       = "harati",
        label     = L["Faction_Harati"],
        factionId = 2704,
        maxRenown = 20,
        color     = { 0.16, 0.78, 0.55 },
        hex       = "29c78c",
    },
    {
        key       = "singularity",
        label     = L["Faction_TheSingularity"],
        factionId = 2699,
        maxRenown = 20,
        color     = { 0.45, 0.22, 0.82 },
        hex       = "7238d1",
    },
}

local function GetFactionRenownCap(factionId, fallback)
    if C_MajorFactions and C_MajorFactions.GetRenownLevels and factionId then
        local levels = C_MajorFactions.GetRenownLevels(factionId)
        if levels and #levels > 0 then
            return #levels
        end
    end
    return fallback or 20
end

local function NormalizeJourneyKey(name, factionId, delvesFactionId)
    if delvesFactionId and factionId == delvesFactionId then
        return "delvers_journey"
    end
    local lower = name and name:lower() or ""
    if lower:find("delver", 1, true) then
        return "delvers_journey"
    end
    if lower:find("preyseeker", 1, true) then
        return "preyseekers_journey"
    end
    return nil
end

local function GetJourneyStyle(key)
    if key == "delvers_journey" then
        return { 0.78, 0.58, 0.24 }, "c7953d"
    end
    if key == "preyseekers_journey" then
        return { 0.76, 0.24, 0.28 }, "c23d47"
    end
    return { 0.58, 0.48, 0.72 }, "947aba"
end

local function AddDynamicFaction(factions, seenFactionIds, key, label, factionId, fallbackMax)
    if not key or not factionId or seenFactionIds[factionId] then return end
    local color, hex = GetJourneyStyle(key)
    factions[#factions + 1] = {
        key       = key,
        label     = label,
        factionId = factionId,
        maxRenown = GetFactionRenownCap(factionId, fallbackMax),
        color     = color,
        hex       = hex,
    }
    seenFactionIds[factionId] = true
end

local function BuildDynamicFactions()
    local factions = {}
    local seenFactionIds = {}
    for _, faction in ipairs(BASE_FACTIONS) do
        factions[#factions + 1] = faction
        seenFactionIds[faction.factionId] = true
    end

    local delvesFactionId = C_DelvesUI and C_DelvesUI.GetDelvesFactionForSeason and C_DelvesUI.GetDelvesFactionForSeason()
    if delvesFactionId then
        local data = C_MajorFactions and C_MajorFactions.GetMajorFactionData and C_MajorFactions.GetMajorFactionData(delvesFactionId)
        AddDynamicFaction(factions, seenFactionIds, "delvers_journey", (data and data.name) or "Delver's Journey", delvesFactionId, 10)
    end

    if C_MajorFactions and C_MajorFactions.GetMajorFactionIDs then
        local majorFactionIds = C_MajorFactions.GetMajorFactionIDs()
        local extraJourney
        for _, factionId in ipairs(majorFactionIds or {}) do
            local isJourney = C_MajorFactions.ShouldDisplayMajorFactionAsJourney
                and C_MajorFactions.ShouldDisplayMajorFactionAsJourney(factionId)
            if isJourney then
                local data = C_MajorFactions.GetMajorFactionData and C_MajorFactions.GetMajorFactionData(factionId)
                local key = NormalizeJourneyKey(data and data.name, factionId, delvesFactionId)
                if key == "preyseekers_journey" then
                    extraJourney = {
                        key = key,
                        label = (data and data.name) or "Preyseeker's Journey",
                        factionId = factionId,
                    }
                elseif not key and factionId ~= delvesFactionId then
                    extraJourney = {
                        key = "preyseekers_journey",
                        label = (data and data.name) or "Preyseeker's Journey",
                        factionId = factionId,
                    }
                end
            end
        end

        if extraJourney then
            AddDynamicFaction(
                factions,
                seenFactionIds,
                extraJourney.key,
                extraJourney.label,
                extraJourney.factionId,
                10
            )
        end
    end

    return factions
end

local function GetRenownData(faction)
    local data = C_MajorFactions.GetMajorFactionData(faction.factionId)
    local maxRenown = GetFactionRenownCap(faction.factionId, faction.maxRenown)
    if not data then return 0, maxRenown, 0, 2500 end
    local renown  = data.renownLevel or 0
    local rep     = data.renownReputationEarned or 0
    local needed  = data.renownLevelThreshold or 2500
    return renown, maxRenown, rep, needed
end

local function TryCall(object, methodName, ...)
    if object and object[methodName] then
        return pcall(object[methodName], object, ...)
    end
    return false
end

local function TryCallGlobal(functionName, ...)
    local fn = _G[functionName]
    if type(fn) == "function" then
        return pcall(fn, ...)
    end
    return false
end

local function OpenMajorFactionRenown(factionId)
    if not factionId then return end

    if not EncounterJournal then
        TryCallGlobal("EncounterJournal_LoadUI")
    end

    if not EncounterJournal then
        return
    end

    if ToggleEncounterJournal and not EncounterJournal:IsShown() then
        ToggleEncounterJournal()
    elseif not EncounterJournal:IsShown() then
        ShowUIPanel(EncounterJournal)
    end

    if EncounterJournal_OnEvent then
        local ok = pcall(EncounterJournal_OnEvent, EncounterJournal, "SHOW_JOURNEYS_UI", factionId)
        if ok then
            return
        end
    end

    if TryCall(EncounterJournal, "OnEvent", "SHOW_JOURNEYS_UI", factionId) then return end
    if TryCall(EncounterJournal, "OpenJourneys", factionId) then return end
    if TryCall(EncounterJournal, "ShowJourneys", factionId) then return end
    if TryCall(EncounterJournal, "ShowJourneysTab", factionId) then return end
    if TryCall(EncounterJournal, "SetSelectedFaction", factionId) then return end
end

local renownFrame

local function BuildRenownFrame()
    RefreshFonts()
    local db        = MR.db and MR.db.profile or {}
    local compact   = db.renownCompact
    local showLevel = db.renownShowLevel ~= false
    local FRAME_W   = db.renownWidth or 280
    local BAR_H     = db.renownBarH or 18
    local ROW_SPACE = compact and (BAR_H + 8) or (BAR_H + 34)
    local PAD       = 12
    local HEADER_H  = 24
    local minimized = db.renownMinimized or false
    local headerBottom = MR.GetManagedHeaderPosition and MR:GetManagedHeaderPosition() == "bottom"
    local hidden    = db.renownHiddenFactions or {}
    local visCount  = 0
    for _, fac in ipairs(GetOrderedFactions()) do
        if not hidden[fac.key] then visCount = visCount + 1 end
    end
    local totalH    = HEADER_H + PAD + (visCount * ROW_SPACE) + PAD

    local f = StyledFrame(UIParent, nil, "MEDIUM", 10)
    f:SetSize(FRAME_W, minimized and HEADER_H or totalH)
    f:SetBackdropColor(0.02, 0.03, 0.08, 0.97)
    f:SetBackdropBorderColor(0.55, 0.42, 0.08, 1)

    RestoreFramePos(f, "renownPos", 300, 0)
    f.topAccent = TopAccent(f)
    f.leftAccent = nil

    local titleBar = TitleBar(f, HEADER_H)
    f.titleBar = titleBar
    titleBar:SetBackdropColor(0.06, 0.05, 0.02, 1)
    titleBar:ClearAllPoints()
    if headerBottom then
        titleBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        titleBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    else
        titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    end
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        if headerBottom then
            local left = f:GetLeft()
            local bottom = f:GetBottom()
            if left and bottom and MR.db then
                MR:SetWindowLayoutValue("renownPos", { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = left, y = bottom })
                return
            end
        end
        local pt, _, rp, x, y = f:GetPoint()
        if MR.db then MR:SetWindowLayoutValue("renownPos", { point = pt, relPoint = rp, x = x, y = y }) end
    end)
    if MR.ApplyPanelHeaderAutoHide then MR:ApplyPanelHeaderAutoHide(f, titleBar) end

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(20, 20)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    titleIcon:SetTexture("Interface\\AddOns\\MidnightRoutine\\Media\\Icon")
    titleIcon:SetVertexColor(0.85, 0.65, 0.10, 1)

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(FONT_HEADERS, 10, GetFontFlags())
    titleTxt:SetPoint("LEFT", titleIcon, "RIGHT", 7, 0)
    titleTxt:SetText(L["Renown_Title"])

    local closeBtn = CloseButton(titleBar, function()
        f:Hide()
        if renownCfgFrame then renownCfgFrame:Hide() end
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("renownOpen", false) end
    end)

    local gearBtn = HeaderIconButton(
        titleBar,
        "Interface\\Buttons\\UI-OptionsButton",
        {0.85, 0.65, 0.20},
        {1, 1, 1},
        L["Renown_OptionsTitle"],
        function() MR:ToggleRenownConfig() end
    )

    local ApplyMinimized

    local function UpdateMinBtn()
        return (MR.db and MR.db.profile.renownMinimized) and "+" or "-"
    end
    local minBtn = HeaderToggleButton(titleBar, UpdateMinBtn, L["UI_Collapse"], function()
        local isMin = not (MR.db and MR.db.profile.renownMinimized)
        ApplyMinimized(isMin)
    end)
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -3, 0)
    gearBtn:SetPoint("RIGHT", minBtn, "LEFT", -3, 0)
    titleTxt:SetPoint("RIGHT", minBtn, "LEFT", -6, 0)
    titleTxt:SetJustifyH("LEFT")
    titleTxt:SetWordWrap(false)

    f.factionRows = {}

    local yOff = HEADER_H + PAD

    for i, faction in ipairs(GetOrderedFactions()) do
        if not hidden[faction.key] then
        local cr, cg, cb = GetFactionColor(faction)

        local rowFrame = CreateFrame("Button", nil, f, "BackdropTemplate")
        if headerBottom then
            rowFrame:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  PAD,  yOff)
            rowFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, yOff)
        else
            rowFrame:SetPoint("TOPLEFT",  f, "TOPLEFT",  PAD,  -yOff)
            rowFrame:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -yOff)
        end
        rowFrame:SetHeight(ROW_SPACE - 8)
        rowFrame:RegisterForClicks("LeftButtonUp")
        rowFrame:SetBackdrop(MakeBackdrop())
        local rowAlpha = db.renownAlpha or 1.0
        if compact then rowAlpha = 1.0 end
        rowFrame:SetBackdropColor(cr * 0.08, cg * 0.08, cb * 0.08, 0.85 * rowAlpha)
        rowFrame:SetBackdropBorderColor(cr * 0.4, cg * 0.4, cb * 0.4, 0.8 * rowAlpha)

        local nameLabel = rowFrame:CreateFontString(nil, "OVERLAY")
        nameLabel:SetFont(FONT_HEADERS, 10, GetFontFlags())
        nameLabel:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 8, -5)
        nameLabel:SetPoint("RIGHT", rowFrame, "RIGHT", -58, -5)
        nameLabel:SetTextColor(cr, cg, cb)
        nameLabel:SetText(faction.label)
        nameLabel:SetJustifyH("LEFT")
        if compact then nameLabel:Hide() end

        local renownLabel = rowFrame:CreateFontString(nil, "OVERLAY")
        renownLabel:SetFont(FONT_ROWS, db.renownFontSize or 9, GetFontFlags())
        renownLabel:SetPoint("TOPRIGHT", rowFrame, "TOPRIGHT", -6, -5)
        renownLabel:SetTextColor(0.65, 0.65, 0.65)
        if compact or not showLevel then renownLabel:Hide() end

        local barBg = CreateFrame("Frame", nil, rowFrame, "BackdropTemplate")
        if compact then
            barBg:SetPoint("TOPLEFT",     rowFrame, "TOPLEFT",     6, -4)
            barBg:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -6,  4)
        else
            barBg:SetPoint("BOTTOMLEFT",  rowFrame, "BOTTOMLEFT",   6,  6)
            barBg:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -6,  6)
        end
        barBg:SetHeight(BAR_H)
        barBg:SetBackdrop(MakeBackdrop())
        local barAlpha = db.renownAlpha or 1.0
        if compact then barAlpha = 1.0 end
        barBg:SetBackdropColor(0.04, 0.04, 0.04, barAlpha)
        barBg:SetBackdropBorderColor(cr * 0.25, cg * 0.25, cb * 0.25, barAlpha)

        local barFill = barBg:CreateTexture(nil, "ARTWORK")
        barFill:SetPoint("TOPLEFT",     barBg, "TOPLEFT",     1, -1)
        barFill:SetPoint("BOTTOMLEFT",  barBg, "BOTTOMLEFT",  1,  1)
        barFill:SetColorTexture(cr, cg, cb, 0.85)

        local barLabel = barBg:CreateFontString(nil, "OVERLAY")
        barLabel:SetFont(FONT_ROWS, db.renownFontSize or 9, GetFontFlags())
        barLabel:SetPoint("CENTER", barBg, "CENTER", 0, 0)
        barLabel:SetTextColor(1, 1, 1)

        local compactLevelLabel = barBg:CreateFontString(nil, "OVERLAY")
        compactLevelLabel:SetFont(FONT_ROWS, math.max(8, (db.renownFontSize or 9) - 1), GetFontFlags())
        compactLevelLabel:SetPoint("RIGHT", barBg, "RIGHT", -4, 0)
        compactLevelLabel:SetJustifyH("RIGHT")
        compactLevelLabel:SetTextColor(0.92, 0.92, 0.92)
        compactLevelLabel:Hide()

        local shimmer = barBg:CreateTexture(nil, "OVERLAY")
        shimmer:SetPoint("TOPLEFT",    barBg, "TOPLEFT",    1, -1)
        shimmer:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 1,  1)
        shimmer:SetWidth(20)
        shimmer:SetColorTexture(1, 1, 1, 0.08)
        shimmer:SetBlendMode("ADD")

        rowFrame:EnableMouse(true)
        rowFrame:SetScript("OnEnter", function()
            local v = db.renownCompact and 1.0 or ((renownFrame and renownFrame.bgAlpha) or 1.0)
            rowFrame:SetBackdropColor(cr * 0.14, cg * 0.14, cb * 0.14, 0.95 * v)
            rowFrame:SetBackdropBorderColor(cr * 0.7, cg * 0.7, cb * 0.7, v)
            local renown, maxRenown, rep, needed = GetRenownData(faction)
            local capped = C_MajorFactions.HasMaximumRenown(faction.factionId)
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(string.format("|cff%s%s|r", faction.hex, faction.label), 1, 1, 1)
            GameTooltip:AddLine(string.format(L["Renown_Level"], renown, maxRenown), cr, cg, cb)
            if capped then
                GameTooltip:AddLine(L["Renown_MaxReached"], 0.2, 1, 0.5)
            else
                GameTooltip:AddLine(string.format(L["Renown_Progress"], rep, needed), 0.7, 0.7, 0.7)
                GameTooltip:AddLine(string.format(L["Renown_RepToNext"], needed - rep), 0.5, 0.5, 0.5)
            end
            GameTooltip:Show()
        end)
        rowFrame:SetScript("OnLeave", function()
            local v = db.renownCompact and 1.0 or ((renownFrame and renownFrame.bgAlpha) or 1.0)
            rowFrame:SetBackdropColor(cr * 0.08, cg * 0.08, cb * 0.08, 0.85 * v)
            rowFrame:SetBackdropBorderColor(cr * 0.4, cg * 0.4, cb * 0.4, 0.8 * v)
            GameTooltip:Hide()
        end)
        rowFrame:SetScript("OnClick", function(_, button)
            if button == "LeftButton" then
                OpenMajorFactionRenown(faction.factionId)
            end
        end)

        f.factionRows[faction.key] = {
            renownLabel = renownLabel,
            barFill     = barFill,
            barLabel    = barLabel,
            compactLevelLabel = compactLevelLabel,
            shimmer     = shimmer,
            barBg       = barBg,
            faction     = faction,
            rowFrame    = rowFrame,
            nameLabel   = nameLabel,
        }

        yOff = yOff + ROW_SPACE
        end
    end

    local divider = f:CreateTexture(nil, "ARTWORK")
    f.divider = divider
    if headerBottom then
        divider:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  3, HEADER_H + 3)
        divider:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, HEADER_H + 3)
    else
        divider:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  3, 3)
        divider:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    end
    divider:SetHeight(1)
    divider:SetColorTexture(0.55, 0.42, 0.08, 0.3)

    f.shimmerElapsed = 0
    f.bgAlpha = db.renownAlpha or 1.0
    f:SetBackdropColor(0.02, 0.03, 0.08, 0.97 * f.bgAlpha)
    f:SetBackdropBorderColor(0.55, 0.42, 0.08, f.bgAlpha)
    f.titleBar:SetBackdropColor(0.06, 0.05, 0.02, f.bgAlpha)
    if f.leftAccent  then f.leftAccent:SetAlpha(f.bgAlpha)  end
    if f.topAccent   then f.topAccent:SetAlpha(f.bgAlpha)   end
    if f.divider     then f.divider:SetAlpha(f.bgAlpha)     end
    f:SetMovable(not db.renownLocked)
    f:SetScale(db.renownScale or 1.0)

    if db.renownShimmer ~= false then
        f:SetScript("OnUpdate", function(self, dt)
            self.shimmerElapsed = self.shimmerElapsed + dt
            local pulse = 0.06 + 0.04 * math.sin(self.shimmerElapsed * 2)
            if self.UpdatePanelHeaderVisibility then
                self:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(self))
            end
            for _, row in pairs(self.factionRows) do
                row.shimmer:SetAlpha(pulse)
            end
        end)
    else
        f:SetScript("OnUpdate", function(self)
            if self.UpdatePanelHeaderVisibility then
                self:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(self))
            end
        end)
    end

    ApplyMinimized = function(isMin)
        if MR.db then MR.db.profile.renownMinimized = isMin end
        if minBtn.RefreshLabel then minBtn:RefreshLabel() end

        for _, row in pairs(f.factionRows) do
            if row.rowFrame then
                if isMin then
                    row.rowFrame:Hide()
                else
                    row.rowFrame:Show()
                end
            end
        end

        if f.divider then
            if isMin then
                f.divider:Hide()
            else
                f.divider:Show()
            end
        end

        if isMin then
            if headerBottom then
                local left = f:GetLeft()
                local bottom = f:GetBottom()
                if left and bottom then
                    f:ClearAllPoints()
                    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
                    if MR.db then
                        MR:SetWindowLayoutValue("renownPos", { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = left, y = bottom })
                    end
                end
            else
                local left = f:GetLeft()
                local top  = f:GetTop()
                if left and top then
                    f:ClearAllPoints()
                    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
                    if MR.db then
                        MR:SetWindowLayoutValue("renownPos", { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = left, y = top })
                    end
                end
            end
            if MR.IsManagedAnimatedMinimizeEnabled and MR:IsManagedAnimatedMinimizeEnabled() then
                local startHeight = f:GetHeight()
                local targetHeight = HEADER_H
                local delta = targetHeight - startHeight
                f._mrAnimTick = 0
                f:SetScript("OnUpdate", function(self, dt)
                    self._mrAnimTick = (self._mrAnimTick or 0) + (dt or 0)
                    local duration = math.min(0.18, math.max(0.06, math.abs(delta) / 1600))
                    local progress = math.min(self._mrAnimTick / duration, 1)
                    local eased = 1 - ((1 - progress) * (1 - progress) * (1 - progress))
                    self:SetHeight(startHeight + (delta * eased))
                    if progress >= 1 then
                        self:SetHeight(targetHeight)
                        self._mrAnimTick = nil
                        self:SetScript("OnUpdate", db.renownShimmer ~= false and function(selfFrame, tickDt)
                            selfFrame.shimmerElapsed = selfFrame.shimmerElapsed + tickDt
                            local pulse = 0.06 + 0.04 * math.sin(selfFrame.shimmerElapsed * 2)
                            if selfFrame.UpdatePanelHeaderVisibility then
                                selfFrame:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(selfFrame))
                            end
                            for _, row in pairs(selfFrame.factionRows) do
                                row.shimmer:SetAlpha(pulse)
                            end
                        end or function(selfFrame)
                            if selfFrame.UpdatePanelHeaderVisibility then
                                selfFrame:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(selfFrame))
                            end
                        end)
                    end
                end)
            else
                f:SetHeight(HEADER_H)
            end
        else
            if headerBottom then
                local left = f:GetLeft()
                local bottom = f:GetBottom()
                if left and bottom then
                    f:ClearAllPoints()
                    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
                end
            end
            if MR.IsManagedAnimatedMinimizeEnabled and MR:IsManagedAnimatedMinimizeEnabled() then
                local startHeight = f:GetHeight()
                local targetHeight = totalH
                local delta = targetHeight - startHeight
                f._mrAnimTick = 0
                f:SetScript("OnUpdate", function(self, dt)
                    self._mrAnimTick = (self._mrAnimTick or 0) + (dt or 0)
                    local duration = math.min(0.18, math.max(0.06, math.abs(delta) / 1600))
                    local progress = math.min(self._mrAnimTick / duration, 1)
                    local eased = 1 - ((1 - progress) * (1 - progress) * (1 - progress))
                    self:SetHeight(startHeight + (delta * eased))
                    if progress >= 1 then
                        self:SetHeight(targetHeight)
                        self._mrAnimTick = nil
                        self:SetScript("OnUpdate", db.renownShimmer ~= false and function(selfFrame, tickDt)
                            selfFrame.shimmerElapsed = selfFrame.shimmerElapsed + tickDt
                            local pulse = 0.06 + 0.04 * math.sin(selfFrame.shimmerElapsed * 2)
                            if selfFrame.UpdatePanelHeaderVisibility then
                                selfFrame:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(selfFrame))
                            end
                            for _, row in pairs(selfFrame.factionRows) do
                                row.shimmer:SetAlpha(pulse)
                            end
                        end or function(selfFrame)
                            if selfFrame.UpdatePanelHeaderVisibility then
                                selfFrame:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(selfFrame))
                            end
                        end)
                    end
                end)
            else
                f:SetHeight(totalH)
            end
            RefreshRenownFrame()
        end
    end
    f.ApplyMinimized = ApplyMinimized

    if minimized then
        ApplyMinimized(true)
    end

    f:Hide()
    return f
end

RefreshRenownFrame = function()
    if not renownFrame or not renownFrame:IsShown() then return end
    local db         = MR.db and MR.db.profile or {}
    local showRep    = db.renownShowRep ~= false
    local hideMaxed  = db.renownHideMaxed
    local showLevel  = db.renownShowLevel ~= false
    local minimized  = db.renownMinimized

    if minimized then
        for _, row in pairs(renownFrame.factionRows) do
            if row.rowFrame then
                row.rowFrame:Hide()
            end
        end
        if renownFrame.divider then
            renownFrame.divider:Hide()
        end
        renownFrame:SetHeight((renownFrame.titleBar and renownFrame.titleBar:GetHeight()) or 24)
        return
    end

    for _, row in pairs(renownFrame.factionRows) do
        local faction   = row.faction
        local renown, maxRenown, rep, needed = GetRenownData(faction)
        local cr, cg, cb = GetFactionColor(faction)
        local capped = C_MajorFactions.HasMaximumRenown(faction.factionId)

        if hideMaxed and capped then
            row.rowFrame:Hide()
        else
            if row.rowFrame then row.rowFrame:Show() end
        end

        if row.nameLabel then
            row.nameLabel:SetText(faction.label)
            if db.renownCompact then
                row.nameLabel:Hide()
            else
                row.nameLabel:SetPoint("RIGHT", row.rowFrame, "RIGHT", showLevel and -58 or -8, -5)
                row.nameLabel:Show()
            end
        end

        if row.renownLabel then
            if not db.renownCompact and showLevel then
                row.renownLabel:SetText(string.format("|cff%s%d|r |cff444444/|r |cff888888%d|r", faction.hex, renown, maxRenown))
                row.renownLabel:Show()
            else
                row.renownLabel:Hide()
            end
        end

        if row.compactLevelLabel then
            if db.renownCompact and showLevel then
                row.compactLevelLabel:SetText(string.format("|cff%s%d|r|cff666666/|r|cffaaaaaa%d|r", faction.hex, renown, maxRenown))
                row.compactLevelLabel:Show()
            else
                row.compactLevelLabel:Hide()
            end
        end

        local barW = row.barBg:GetWidth()
        if barW and barW > 2 then
            local pct
            if capped then
                pct = 1
            elseif needed > 0 then
                pct = math.min(rep / needed, 1)
            else
                pct = 0
            end
            local fillW = math.max(2, (barW - 2) * pct)
            row.barFill:SetWidth(fillW)
            row.shimmer:SetWidth(math.min(20, fillW))

            if capped then
                row.barLabel:SetText(L["MAX"])
                row.barLabel:SetTextColor(cr, cg, cb)
            elseif showRep then
                row.barLabel:SetText(string.format("%d / %d", rep, needed))
                row.barLabel:SetTextColor(0.85, 0.85, 0.85)
            else
                row.barLabel:SetText(string.format("%.0f%%", pct * 100))
                row.barLabel:SetTextColor(0.85, 0.85, 0.85)
            end
        end
    end

    if renownFrame.divider then
        renownFrame.divider:Show()
    end
end

local renownCfgFrame

local function BuildRenownConfigFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(268)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(20)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(f) end
    f:SetBackdropColor(0.03, 0.04, 0.10, 0.98)
    f:SetBackdropBorderColor(0.55, 0.42, 0.08, 1)
    f:Hide()

    TopAccent(f)

    local tbar = TitleBar(f, 22)
    tbar:SetBackdropColor(0.06, 0.05, 0.02, 1)
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(FONT_HEADERS, 11, GetFontFlags())
    ttitle:SetText(L["Renown_Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)

    local closeBtn = CloseButton(tbar, function() f:Hide() end)

    f.body = nil
    return f
end

GetOrderedFactions = function()
    local db    = MR.db and MR.db.profile or {}
    local order = db.renownOrder or {}
    local factions = BuildDynamicFactions()
    local result, seen = {}, {}
    for _, key in ipairs(order) do
        for _, f in ipairs(factions) do
            if f.key == key and not seen[key] then
                result[#result+1] = f
                seen[key] = true
            end
        end
    end
    for _, f in ipairs(factions) do
        if not seen[f.key] then result[#result+1] = f end
    end
    return result
end

SaveFactionOrder = function(ordered)
    if not MR.db then return end
    local keys = {}
    for _, f in ipairs(ordered) do keys[#keys+1] = f.key end
    MR.db.profile.renownOrder = keys
end

RebuildRenownFrame = function()
    RefreshFonts()
    local wasShown = renownFrame and renownFrame:IsShown()
    if renownFrame then
        renownFrame:Hide()
        renownFrame = nil
    end
    renownFrame = BuildRenownFrame()
    MR.renownFrame = renownFrame
    if wasShown then
        renownFrame:Show()
        RefreshRenownFrame()
    end
end

GetFactionColor = function(faction)
    local db = MR.db and MR.db.profile or {}
    if db.renownColors and db.renownColors[faction.key] then
        local h = db.renownColors[faction.key]
        return Hex(h)
    end
    return faction.color[1], faction.color[2], faction.color[3]
end

SetFactionColor = function(faction, r, g, b)
    if not MR.db then return end
    if not MR.db.profile.renownColors then MR.db.profile.renownColors = {} end
    MR.db.profile.renownColors[faction.key] = string.format("#%02x%02x%02x", r*255, g*255, b*255)
end

ResetFactionColor = function(faction)
    if not MR.db then return end
    if MR.db.profile.renownColors then
        MR.db.profile.renownColors[faction.key] = nil
    end
end

PopulateRenownConfig = function(f)
    RefreshFonts()
    if f.body then
        f.body:EnableMouse(false)
        f.body:Hide()
        f.body:SetParent(UIParent)
        f.body = nil
    end

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    body:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.body = body

    local db  = MR.db.profile
    local yOff = -28
    local PAD  = 8
    local contentW = (f:GetWidth() or 230) - (PAD * 2)
    local activePage = MR._renownCfgPage or "display"

    local cfgFs = (ns.GetFontSize and ns.GetFontSize()) or (MR.db and MR.db.profile and MR.db.profile.fontSize) or 9

    if activePage ~= "display" and activePage ~= "factions" then
        activePage = "display"
        MR._renownCfgPage = activePage
    end

    local function Gap(h)          yOff = OptionsGap(body, yOff, h) end
    local function Divider()       yOff = OptionsDivider(body, yOff, PAD) end
    local function SecLabel(t)     yOff = OptionsSectionLabel(body, yOff, t, PAD, cfgFs) end
    local function Check(lbl, get, set, r, g, b)
        yOff = OptionsCheckbox(body, yOff, lbl, get, set, r, g, b, PAD,
            function() PopulateRenownConfig(f) end, cfgFs)
    end
    local function Btn(lbl, fn)    yOff = OptionsBtn(body, yOff, lbl, fn, math.max(184, contentW), PAD, cfgFs) end
    local function Slider(lbl, mn, mx, st, get, set, r, g, b, disabled)
        yOff = OptionsSlider(body, yOff, lbl, mn, mx, st, get, set, r, g, b, PAD, disabled, cfgFs)
    end

    do
        local tabs = {
            { key = "display", label = L["Config_TabLayout"] or "Layout" },
            { key = "factions", label = L["Config_TabModules"] or "Modules" },
        }
        local tabW = math.floor((contentW - 2) / #tabs)
        for i, tab in ipairs(tabs) do
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(tabW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", PAD + (i - 1) * (tabW + 2), yOff)
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
                MR._renownCfgPage = tab.key
                PopulateRenownConfig(f)
            end)
            btn:SetScript("OnEnter", function()
                if activePage ~= tab.key then
                    btn:SetBackdropColor(0.08, 0.18, 0.24, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.90, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = (MR._renownCfgPage or "display") == tab.key
                btn:SetBackdropColor(selected and 0.11 or 0.05, selected and 0.24 or 0.09, selected and 0.23 or 0.15, 1)
                btn:SetBackdropBorderColor(selected and 0.22 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.85 or 0.62, selected and 1.0 or 0.75, selected and 0.92 or 0.70)
            end)
        end
        yOff = yOff - 26
    end

    f:SetScript("OnUpdate", nil)

    if activePage == "display" then
        SecLabel(L["Config_Display"])
        Check(L["Config_LockPosition"],
            function() return db.renownLocked end,
            function(v)
                db.renownLocked = v
                if renownFrame then renownFrame:SetMovable(not v) end
            end)
        Check(L["Config_ShowRepNumbers"],
            function() return db.renownShowRep ~= false end,
            function(v) db.renownShowRep = v; RefreshRenownFrame() end)
        Check(L["Config_ShimmerAnim"],
            function() return db.renownShimmer ~= false end,
            function(v)
                db.renownShimmer = v
                if renownFrame then
                    renownFrame:SetScript("OnUpdate", v and function(self, dt)
                        self.shimmerElapsed = (self.shimmerElapsed or 0) + dt
                        local pulse = 0.06 + 0.04 * math.sin(self.shimmerElapsed * 2)
                        for _, row in pairs(self.factionRows) do row.shimmer:SetAlpha(pulse) end
                    end or nil)
                    if not v then
                        for _, row in pairs(renownFrame.factionRows) do row.shimmer:SetAlpha(0) end
                    end
                end
            end)
        Check(L["Config_HideAtMax"],
            function() return db.renownHideMaxed end,
            function(v) db.renownHideMaxed = v; RefreshRenownFrame() end)
        Check(L["Config_CompactMode"],
            function() return db.renownCompact end,
            function(v) db.renownCompact = v; RebuildRenownFrame() end)
        Check(L["Config_ShowRenownLevel"],
            function() return db.renownShowLevel ~= false end,
            function(v) db.renownShowLevel = v; RefreshRenownFrame() end)

        Gap(4); Divider()
        Slider(L["WIDTH"], 200, 400, 10,
            function() return db.renownWidth or 280 end,
            function(v)
                db.renownWidth = math.floor(v/10)*10
                if renownFrame then renownFrame:SetWidth(db.renownWidth) end
            end,
            0.16, 0.78, 0.75)
        Slider(L["Config_BarHeight"], 10, 30, 1,
            function() return db.renownBarH or 18 end,
            function(v) db.renownBarH = math.floor(v); RebuildRenownFrame() end,
            0.85, 0.65, 0.10)
        Slider(L["BACKGROUND"], 0, 1, 0.05,
            function() return db.renownAlpha or 1.0 end,
            function(v)
                db.renownAlpha = v
                if renownFrame then
                    renownFrame:SetBackdropColor(0.02, 0.03, 0.08, 0.97 * v)
                    renownFrame:SetBackdropBorderColor(0.55, 0.42, 0.08, v)
                    if renownFrame.titleBar  then renownFrame.titleBar:SetBackdropColor(0.06, 0.05, 0.02, v) end
                    if renownFrame.leftAccent then renownFrame.leftAccent:SetAlpha(v) end
                    if renownFrame.topAccent  then renownFrame.topAccent:SetAlpha(v)  end
                    if renownFrame.divider    then renownFrame.divider:SetAlpha(v)    end
                    for _, row in pairs(renownFrame.factionRows) do
                        local fac = row.faction
                        local cr, cg, cb = GetFactionColor(fac)
                        local rowV = db.renownCompact and 1.0 or v
                        row.rowFrame:SetBackdropColor(cr*0.08, cg*0.08, cb*0.08, 0.85*rowV)
                        row.rowFrame:SetBackdropBorderColor(cr*0.4, cg*0.4, cb*0.4, 0.8*rowV)
                        row.barBg:SetBackdropColor(0.04, 0.04, 0.04, rowV)
                    end
                end
            end,
            0.40, 0.40, 0.40)
        Slider(L["SCALE"], 0.5, 2.0, 0.05,
            function() return db.renownScale or 1.0 end,
            function(v)
                db.renownScale = v
                if renownFrame then renownFrame:SetScale(v) end
            end,
            0.55, 0.22, 0.82, MR.db.profile.syncWindowScale)
    else
        SecLabel(L["Config_FactionSettings"])

    local drag = { active = false, srcKey = nil, targetIdx = nil }
    local _facRows = {}

    local dragGhost = CreateFrame("Frame", nil, body, "BackdropTemplate")
    dragGhost:SetHeight(20)
    dragGhost:SetFrameStrata("DIALOG")
    dragGhost:SetBackdrop(MakeBackdrop())
    dragGhost:SetBackdropColor(0.10, 0.08, 0.02, 0.95)
    dragGhost:SetBackdropBorderColor(0.9, 0.72, 0.1, 1)
    dragGhost:Hide()
    local dragGhostLbl = dragGhost:CreateFontString(nil, "OVERLAY")
    dragGhostLbl:SetFont(FONT_HEADERS, 10, GetFontFlags())
    dragGhostLbl:SetPoint("LEFT", dragGhost, "LEFT", 8, 0)
    dragGhostLbl:SetTextColor(1, 0.85, 0.2)

    local dragLine = CreateFrame("Frame", nil, body)
    dragLine:SetHeight(2)
    dragLine:SetFrameStrata("DIALOG")
    dragLine:Hide()
    local dragLineTex = dragLine:CreateTexture(nil, "OVERLAY")
    dragLineTex:SetAllPoints()
    dragLineTex:SetColorTexture(0.9, 0.72, 0.1, 1)

    local function DragOnUpdate()
        if not drag.active then return end
        local rows = _facRows
        if #rows == 0 then return end

        local cx, cy = GetCursorPosition()
        local scale  = body:GetEffectiveScale()
        local bLeft  = body:GetLeft()
        local bTop   = body:GetTop()
        if not bLeft or not bTop then return end
        local localY = bTop - cy / scale

        dragGhost:ClearAllPoints()
        dragGhost:SetPoint("TOPLEFT",  body, "TOPLEFT",  PAD,  -localY + 10)
        dragGhost:SetPoint("TOPRIGHT", body, "TOPRIGHT", -PAD, -localY + 10)
        dragGhost:Show()

        local screenCY = cy / UIParent:GetEffectiveScale()
        local slot = #rows
        for i, row in ipairs(rows) do
            local rTop = row.frame:GetTop()
            local rBot = row.frame:GetBottom()
            if rTop and rBot and screenCY > (rTop + rBot) / 2 then
                slot = i - 1
                break
            end
        end
        slot = math.max(0, math.min(slot, #rows))
        drag.targetIdx = slot

        local lineRef, atBottom
        if slot == 0 then
            lineRef = rows[1].frame; atBottom = false
        elseif slot >= #rows then
            lineRef = rows[#rows].frame; atBottom = true
        else
            lineRef = rows[slot].frame; atBottom = true
        end

        if lineRef then
            local lY     = atBottom and (lineRef:GetBottom() or 0) or (lineRef:GetTop() or 0)
            local bodyTop  = body:GetTop() or 0
            local bodyLeft = body:GetLeft() or 0
            local lineBodyY = -(bodyTop - lY)
            dragLine:ClearAllPoints()
            dragLine:SetPoint("TOPLEFT",  body, "TOPLEFT",  (lineRef:GetLeft()  or 0) - bodyLeft, lineBodyY)
            dragLine:SetPoint("TOPRIGHT", body, "TOPLEFT",  (lineRef:GetRight() or 0) - bodyLeft, lineBodyY)
            dragLine:Show()
        end

        for _, row in ipairs(rows) do
            row.frame:SetAlpha(row.key == drag.srcKey and 0.3 or 1.0)
        end
    end

    f:SetScript("OnUpdate", function()
        if drag.active then DragOnUpdate() end
    end)

    local function CommitDrag()
        if not drag.active then return end
        drag.active = false
        for _, row in ipairs(_facRows) do row.frame:SetAlpha(1) end
        dragGhost:Hide()
        dragLine:Hide()

        local slot = drag.targetIdx
        if slot == nil then PopulateRenownConfig(f); return end

        local ordered = GetOrderedFactions()
        local srcIdx = nil
        for i, fc in ipairs(ordered) do
            if fc.key == drag.srcKey then srcIdx = i; break end
        end
        if not srcIdx then PopulateRenownConfig(f); return end

        local insertAt = slot + 1
        if srcIdx < insertAt then insertAt = insertAt - 1 end
        insertAt = math.max(1, math.min(insertAt, #ordered))

        if srcIdx ~= insertAt then
            local moved = table.remove(ordered, srcIdx)
            table.insert(ordered, insertAt, moved)
            SaveFactionOrder(ordered)
            RebuildRenownFrame()
        end
        drag.srcKey = nil; drag.targetIdx = nil
        PopulateRenownConfig(f)
    end

    local ordered = GetOrderedFactions()

    for _, faction in ipairs(ordered) do
        local cr, cg, cb = GetFactionColor(faction)
        local ROW_H = 22
        local rowFr = CreateFrame("Frame", nil, body)
        rowFr:SetPoint("TOPLEFT",  body, "TOPLEFT",  PAD,  yOff)
        rowFr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -PAD, yOff)
        rowFr:SetHeight(ROW_H)

        local visCheck = CreateFrame("CheckButton", nil, rowFr, "UICheckButtonTemplate")
        visCheck:SetSize(20, 20)
        visCheck:SetPoint("LEFT", rowFr, "LEFT", 18, 0)
        visCheck:SetChecked(not (db.renownHiddenFactions and db.renownHiddenFactions[faction.key]))
        visCheck:SetScript("OnClick", function(s)
            if not db.renownHiddenFactions then db.renownHiddenFactions = {} end
            db.renownHiddenFactions[faction.key] = not s:GetChecked()
            RebuildRenownFrame()
        end)

        local grip = CreateFrame("Button", nil, rowFr)
        grip:SetSize(14, ROW_H)
        grip:SetPoint("LEFT", rowFr, "LEFT", 2, 0)
        grip:RegisterForClicks("LeftButtonUp")
        local gripLbl = grip:CreateFontString(nil, "OVERLAY")
        gripLbl:SetFont(FONT_HEADERS, 11, GetFontFlags())
        gripLbl:SetPoint("CENTER")
        gripLbl:SetText("=")
        gripLbl:SetTextColor(0.28, 0.22, 0.08)
        grip:SetScript("OnEnter", function()
            if not drag.active then gripLbl:SetTextColor(0.9, 0.75, 0.2) end
        end)
        grip:SetScript("OnLeave", function()
            if not drag.active then gripLbl:SetTextColor(0.28, 0.22, 0.08) end
        end)
        grip:SetScript("OnMouseDown", function()
            if drag.active then return end
            drag.active = true
            drag.srcKey = faction.key
            drag.targetIdx = nil
            dragGhostLbl:SetText(faction.label)
        end)
        grip:SetScript("OnClick", function()
            if drag.active then CommitDrag() end
        end)
        table.insert(_facRows, { key = faction.key, frame = rowFr, label = faction.label })

        local swatch = OptionsColorSwatch(rowFr, cr, cg, cb,
            function(r, g, b)
                SetFactionColor(faction, r, g, b)
                nameLbl:SetTextColor(r, g, b)
                if renownFrame and renownFrame.factionRows[faction.key] then
                    local row = renownFrame.factionRows[faction.key]
                    row.nameLabel:SetTextColor(r, g, b)
                    row.barFill:SetColorTexture(r, g, b, 0.85)
                    local rowV = db.renownCompact and 1.0 or ((renownFrame and renownFrame.bgAlpha) or 1.0)
                    row.rowFrame:SetBackdropColor(r*0.08, g*0.08, b*0.08, 0.85 * rowV)
                    row.rowFrame:SetBackdropBorderColor(r*0.4, g*0.4, b*0.4, 0.8 * rowV)
                end
            end,
            function()
                ResetFactionColor(faction)
                local dr, dg, db2 = faction.color[1], faction.color[2], faction.color[3]
                nameLbl:SetTextColor(dr, dg, db2)
                RebuildRenownFrame()
                return dr, dg, db2
            end,
            faction.label .. L["Color_Reset_Hint"])
        swatch:SetPoint("RIGHT", rowFr, "RIGHT", 0, 0)

        local nameLbl = rowFr:CreateFontString(nil, "OVERLAY")
        nameLbl:SetFont(FONT_ROWS, 10, GetFontFlags())
        nameLbl:SetPoint("LEFT",  visCheck, "RIGHT", 2, 0)
        nameLbl:SetPoint("RIGHT", swatch,   "LEFT",  -4, 0)
        nameLbl:SetText(faction.label)
        nameLbl:SetTextColor(cr, cg, cb)
        nameLbl:SetJustifyH("LEFT")

        yOff = yOff - (ROW_H + 2)
    end

    Gap(4); Divider()
    SecLabel(L["RESETS"])
    Btn(L["Config_ResetColors"], function()
        db.renownColors = {}
        RebuildRenownFrame()
        PopulateRenownConfig(f)
    end)
    Btn(L["Config_ResetFactionOrder"], function()
        db.renownOrder = {}
        PopulateRenownConfig(f)
        RebuildRenownFrame()
    end)
    end

    local totalH = math.abs(yOff) + 10
    f:SetHeight(totalH)
    body:SetHeight(totalH)
end

function MR:ToggleRenownConfig()
    if not renownCfgFrame then
        renownCfgFrame = BuildRenownConfigFrame()
    end
    if renownCfgFrame:IsShown() then
        renownCfgFrame:Hide()
        return
    end
    if renownFrame and renownFrame:IsShown() then
        renownCfgFrame:SetPoint("TOPLEFT", renownFrame, "TOPRIGHT", 4, 0)
        renownCfgFrame:SetScale(renownFrame:GetScale())
    elseif MR.frame then
        renownCfgFrame:SetPoint("TOPLEFT", MR.frame, "TOPRIGHT", 4, 0)
    else
        renownCfgFrame:SetPoint("CENTER")
    end
    PopulateRenownConfig(renownCfgFrame)
    renownCfgFrame:Show()
end

function MR:ToggleRenown()
    if not renownFrame then
        renownFrame = BuildRenownFrame()
    end
    if renownFrame:IsShown() then
        self:HideRenown()
    else
        renownFrame:Show()
        MR.renownFrame = renownFrame
        if self.SetManagedWindowOpen then self:SetManagedWindowOpen("renownOpen", true) end
        RefreshRenownFrame()
    end
end

function MR:HideRenown(persistState)
    if renownFrame then renownFrame:Hide() end
    if renownCfgFrame then renownCfgFrame:Hide() end
    if persistState ~= false and self.db then
        self:SetManagedWindowOpen("renownOpen", false)
    end
end

function MR:EnsureRenownShown()
    if not renownFrame then
        renownFrame = BuildRenownFrame()
    end
    if not renownFrame:IsShown() then
        renownFrame:Show()
        MR.renownFrame = renownFrame
        if self.SetManagedWindowOpen then self:SetManagedWindowOpen("renownOpen", true) end
    end
    RefreshRenownFrame()
end

function MR:RefreshRenown()
    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("renown") then
        return
    end

    RefreshRenownFrame()
end

function MR:RepopulateRenownConfig()
    if renownCfgFrame and renownCfgFrame:IsShown() then
        PopulateRenownConfig(renownCfgFrame)
    end
end

function MR:RebuildRenownFrame()
    if renownFrame and renownFrame:IsShown() then
        RebuildRenownFrame()
        MR.renownFrame = renownFrame
    end
end

function MR:OnRenownUpdate()
    if renownFrame and renownFrame:IsShown() then
        self:RefreshRenown()
    end
end
