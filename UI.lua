local _, ns = ...
local MR = ns.MR

local cfgFrame
local concentrationTrackerConfigFrame
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local PANEL_MIN_WIDTH  = 200
local PANEL_MAX_WIDTH  = 500
local PANEL_MIN_HEIGHT = 100
local PANEL_MAX_HEIGHT = 800
local FONT_ROWS = ns.FONT_ROWS
local FONT_HEADERS = ns.FONT_HEADERS
local MakeBackdrop = ns.MakeBackdrop
local StyledFrame = ns.StyledFrame
local LeftAccent = ns.LeftAccent
local TitleBar = ns.TitleBar
local CloseButton = ns.CloseButton
local RestoreFramePos = ns.RestoreFramePos
local RestoreManagedFramePos = ns.RestoreManagedFramePos
local CaptureManagedFrameAnchor = ns.CaptureManagedFrameAnchor
local ApplyManagedFrameAnchor = ns.ApplyManagedFrameAnchor
local AnimateManagedFrameHeight = ns.AnimateManagedFrameHeight
local WrapColor = ns.WrapColor
local SetDotColor = ns.SetDotColor
local OptionsGap = ns.OptionsGap
local OptionsDivider = ns.OptionsDivider
local OptionsSectionLabel = ns.OptionsSectionLabel
local OptionsCheckbox = ns.OptionsCheckbox
local OptionsBtn = ns.OptionsBtn
local OptionsSlider = ns.OptionsSlider
local OptionsColorSwatch = ns.OptionsColorSwatch
local ApplyBackgroundTexture = ns.ApplyBackgroundTexture

local FONT_SIZE_MIN = 7
local FONT_SIZE_MAX = 20
local DAY_SECONDS = 24 * 60 * 60

local ROW_HEIGHT    = 18
local HEADER_HEIGHT = 18
local PADDING       = 6
local SECTION_GAP   = 6
local ApplyCustomTaskDialogTheme
local ApplyCustomTasksTitleDialogTheme
local BuildModuleStatsCache
local GetModuleStats
local IsMainTextOnlyMode

local GetWindowLayoutValue
local SetWindowLayoutValue
local countColor
local WC = WrapColor

countColor = ns.CountColor

local function GetFontSize()
    if type(ns.GetFontSize) == "function" then
        return ns.GetFontSize()
    end

    if MR and MR.db and MR.db.profile and MR.db.profile.fontSize then
        return MR.db.profile.fontSize
    end

    return 11
end

local function GetFontFlags()
    if type(ns.GetFontFlags) == "function" then
        local flags = ns.GetFontFlags()
        if flags ~= nil then
            return flags
        end
    end

    return "OUTLINE"
end

local function GetLocaleFont()
    if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
        return STANDARD_TEXT_FONT
    end
    if GameFontNormal and GameFontNormal.GetFont then
        local f = GameFontNormal:GetFont()
        if type(f) == "string" and f ~= "" then return f end
    end
    if ns.GetDefaultFontTexture then
        local f = ns.GetDefaultFontTexture()
        if type(f) == "string" and f ~= "" then return f end
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
    end
    local loc = GetLocaleFont()
    if not FONT_ROWS    or FONT_ROWS    == "" then FONT_ROWS    = loc end
    if not FONT_HEADERS or FONT_HEADERS == "" then FONT_HEADERS = loc end
end

local function SetFontForText(fontString, text, size, flags)
    if not fontString then return end
    local fontPath = FONT_ROWS
    if ns.ResolveFontForText then
        fontPath = ns.ResolveFontForText(text, FONT_ROWS)
    elseif ns.ScriptFontForText then
        fontPath = ns.ScriptFontForText(text) or FONT_ROWS
    end
    fontString:SetFont(fontPath, size, flags)
end

local function GetMainHeaderHeight()
    return math.max(24, GetFontSize() + 11)
end

local function ApplyDialogEditBoxFont(editBox, fontSize)
    if not editBox then return end
    SetFontForText(editBox, editBox.GetText and editBox:GetText() or "", math.max(9, fontSize), GetFontFlags())
end

ApplyCustomTaskDialogTheme = function(frame)
    if not frame then return end

    RefreshFonts()
    local fontSize  = GetFontSize()
    local rowFont   = math.max(8,  fontSize - 1)
    local hintFont  = math.max(7,  fontSize - 2)
    local editFont  = math.max(9,  fontSize)


    frame:SetSize(400, 460)

    local function sf(fs, size) if fs then fs:SetFont(FONT_ROWS, size, GetFontFlags()) end end
    sf(frame.title,           math.max(10, fontSize + 1))
    sf(frame.nameLabel,       rowFont)
    sf(frame.questLabel,      rowFont)
    sf(frame.encounterLabel,  rowFont)
    sf(frame.difficultyLabel, rowFont)
    sf(frame.idHint,          hintFont)
    sf(frame.diffHint,        hintFont)
    sf(frame.targetLabel,     rowFont)
    sf(frame.targetHint,      hintFont)
    sf(frame.resetLabel,      rowFont)

    if frame.title then frame.title:SetFont(FONT_HEADERS, math.max(10, fontSize + 1), GetFontFlags()) end

    local checks = { frame.weeklyCheck, frame.dailyCheck, frame.manualQuestCheck, frame.autoUpdateCheck }
    for _, cb in ipairs(checks) do
        if cb and cb._text then cb._text:SetFont(FONT_ROWS, rowFont, GetFontFlags()) end
    end
    if frame.difficultyChecks then
        for _, cb in ipairs(frame.difficultyChecks) do
            if cb._text then cb._text:SetFont(FONT_ROWS, rowFont, GetFontFlags()) end
        end
    end

    if frame.input          then ApplyDialogEditBoxFont(frame.input,          editFont) end
    if frame.questInput     then ApplyDialogEditBoxFont(frame.questInput,     editFont) end
    if frame.encounterInput then ApplyDialogEditBoxFont(frame.encounterInput, editFont) end
    if frame.targetInput    then ApplyDialogEditBoxFont(frame.targetInput,    editFont) end

    if frame.saveBtn   and frame.saveBtn._label   then frame.saveBtn._label:SetFont(FONT_HEADERS,   10, GetFontFlags()) end
    if frame.cancelBtn and frame.cancelBtn._label then frame.cancelBtn._label:SetFont(FONT_HEADERS, 10, GetFontFlags()) end
    if frame.deleteBtn and frame.deleteBtn._label then frame.deleteBtn._label:SetFont(FONT_HEADERS, 10, GetFontFlags()) end
end

ApplyCustomTasksTitleDialogTheme = function(frame)
    if not frame then
        return
    end

    RefreshFonts()
    local fontSize = GetFontSize()
    local rowFont = math.max(8, fontSize - 1)
    local hintFont = math.max(8, fontSize - 2)
    local editFont = math.max(9, fontSize)
    local boxHeight = math.max(32, fontSize + 20)
    local hintGap = math.max(8, math.floor(fontSize * 0.7))
    local frameWidth = math.max(340, 220 + (fontSize * 8))
    local frameHeight = math.max(190, 150 + (fontSize * 9))

    frame:SetSize(frameWidth, frameHeight)

    if frame.titleText then
        frame.titleText:SetFont(FONT_HEADERS, math.max(10, fontSize + 1), GetFontFlags())
        frame.titleText:SetWidth(frameWidth - 24)
    end
    if frame.subtitle then
        frame.subtitle:SetFont(FONT_ROWS, rowFont, GetFontFlags())
        frame.subtitle:SetWidth(frameWidth - 24)
    end
    if frame.inputBg then
        frame.inputBg:SetHeight(boxHeight)
    end
    if frame.input then
        ApplyDialogEditBoxFont(frame.input, editFont)
    end
    if frame.hint then
        frame.hint:SetFont(FONT_ROWS, hintFont, GetFontFlags())
        frame.hint:ClearAllPoints()
        frame.hint:SetPoint("TOPLEFT", frame.inputBg, "BOTTOMLEFT", 0, -hintGap)
        frame.hint:SetPoint("TOPRIGHT", frame.inputBg, "BOTTOMRIGHT", 0, -hintGap)
    end
    if frame.saveBtn and frame.saveBtn._label then
        frame.saveBtn._label:SetFont(FONT_HEADERS, 10, GetFontFlags())
    end
    if frame.cancelBtn and frame.cancelBtn._label then
        frame.cancelBtn._label:SetFont(FONT_HEADERS, 10, GetFontFlags())
    end
end

local function GetMainHeaderMetrics()
    local fontSize = GetFontSize()
    local headerHeight = GetMainHeaderHeight()
    return {
        fontSize = fontSize,
        headerHeight = headerHeight,
        iconSize = math.max(14, fontSize),
        buttonSize = math.max(16, fontSize + 1),
        buttonPad = 3,
        buttonMargin = 6,
        warbandWidth = math.max(34, fontSize * 3),
    }
end

local PEEK_ALPHA_IDLE   = 0.0
local PEEK_ALPHA_HOVER  = 1.0
local PEEK_FADE_IN      = 6.0
local PEEK_FADE_OUT     = 2.5

local function PeekFrameList()
    local list = {}
    if MR.frame                  then list[#list+1] = MR.frame end
    if MR.raresFrame             then list[#list+1] = MR.raresFrame end
    if MR.renownFrame            then list[#list+1] = MR.renownFrame end
    if MR.gatheringLocationsFrame then list[#list+1] = MR.gatheringLocationsFrame end
    if MR.detachedFrames then
        for _, f in pairs(MR.detachedFrames) do
            list[#list+1] = f
        end
    end
    return list
end

local function AnyFrameHovered()
    for _, f in ipairs(PeekFrameList()) do
        if f:IsShown() and f:IsMouseOver() then return true end
    end
    return false
end

local function GetMovableHostFrame(frame)
    local current = frame
    while current do
        if current.IsMovable and current:IsMovable() then
            return current
        end
        current = current.GetParent and current:GetParent() or nil
    end
    return nil
end

local peekUpdater = CreateFrame("Frame")
peekUpdater:Hide()

function MR:ApplyPeekOnHover(enable)
    self.db.profile.peekOnHover = enable

    if not enable then
        peekUpdater:SetScript("OnUpdate", nil)
        peekUpdater:Hide()
        for _, f in ipairs(PeekFrameList()) do
            if f:IsShown() then f:SetAlpha(1.0) end
        end
        return
    end

    peekUpdater:Show()
    peekUpdater:SetScript("OnUpdate", function(_, dt)
        local target = AnyFrameHovered() and PEEK_ALPHA_HOVER or PEEK_ALPHA_IDLE
        local rate   = (target > PEEK_ALPHA_IDLE) and PEEK_FADE_IN or PEEK_FADE_OUT
        for _, f in ipairs(PeekFrameList()) do
            if f:IsShown() then
                local cur = f:GetAlpha()
                if math.abs(cur - target) < 0.005 then
                    f:SetAlpha(target)
                else
                    local step = rate * dt
                    if cur < target then
                        f:SetAlpha(math.min(cur + step, target))
                    else
                        f:SetAlpha(math.max(cur - step, target))
                    end
                end
            end
        end
    end)
end

local function RecalcLayout()
    local fs = GetFontSize()
    ROW_HEIGHT    = math.max(18, fs + 10)
    HEADER_HEIGHT = math.max(18, fs + 10)
    PADDING       = math.max(4, math.floor(fs * 0.55))
end

local hex = ns.Hex

local COL = ns.COLORS

local function ApplyTheme()
    if not MR.frame then return end
    local t = IsMainTextOnlyMode()
    local v = MR.db.profile.frameAlpha or 1.0
    local f = MR.frame
    f:SetBackdrop(MakeBackdrop())
    if MR._titleBar then
        MR._titleBar:SetBackdrop(MakeBackdrop())
    end
    if t then
        f:SetBackdropColor(0, 0, 0, 0)
        f:SetBackdropBorderColor(0, 0, 0, 0)
        if MR._titleBar    then MR._titleBar:SetBackdropColor(0, 0, 0, 0) end
        if MR._titleBar    then MR._titleBar:SetBackdropBorderColor(0, 0, 0, 0) end
        if MR._scrollBg    then ApplyBackgroundTexture(MR._scrollBg, 0, 0, 0, 0) end
        if MR._titleAccent then MR._titleAccent:SetAlpha(0) end
    else
        f:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4] * v)
        f:SetBackdropBorderColor(0.15, 0.15, 0.2, v)
        if MR._titleBar    then MR._titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98 * v) end
        if MR._titleBar    then MR._titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, v) end
        if MR._scrollBg    then ApplyBackgroundTexture(MR._scrollBg, COL.bg[1], COL.bg[2], COL.bg[3], 0.96 * v) end
        if MR._titleAccent then MR._titleAccent:SetAlpha(0) end
    end
end

local function WBClean(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end

    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

local function CleanLabelText(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end

    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

local function ExtractInlineLabelColor(text)
    if type(text) ~= "string" then
        return nil
    end

    local hexColor = text:match("|cff(%x%x%x%x%x%x)")
    if not hexColor then
        return nil
    end

    return "#" .. hexColor
end

local function HideTooltipIfOwned(frame)
    if GameTooltip and GameTooltip:IsOwned(frame) then
        GameTooltip:Hide()
    end
end

local function MainSectionHeaderOnMouseDown(selfFrame, button)
    if selfFrame._mrDetachedHost and button == "LeftButton" then
        selfFrame._pressed = true
        selfFrame._dragged = false
        return
    end

    if button == "LeftButton" then
        selfFrame._pressed = true
    end
end

local function MainSectionHeaderOnDragStart(selfFrame)
    local host = selfFrame._mrDetachedHost
    if not host or MR.db.profile.locked then
        return
    end

    selfFrame._dragged = true
    host:StartMoving()
end

local function MainSectionHeaderOnDragStop(selfFrame)
    local host = selfFrame._mrDetachedHost
    local mod = selfFrame._mrMod
    if not host or not mod then
        return
    end

    host:StopMovingOrSizing()
    local pt, _, rp, x, y = host:GetPoint()
    MR:SetDetachedModulePosition(mod.key, pt, rp, x, y)
end

local function MainSectionHeaderOnMouseUp(selfFrame, button)
    local mod = selfFrame._mrMod
    if not mod then
        selfFrame._pressed = false
        return
    end

    if selfFrame._mrDetachedHost and button == "LeftButton" and selfFrame._dragged then
        selfFrame._pressed = false
        selfFrame._dragged = false
        return
    end

    if mod.key == "custom_tasks" and button == "RightButton" and IsShiftKeyDown() then
        if MR.ShowCustomTasksTitleDialog then
            MR:ShowCustomTasksTitleDialog()
        end
        selfFrame._pressed = false
        return
    end

    if button == "LeftButton" then
        if not selfFrame._mrDetachedHost and MR.FastToggleMainSection and MR:FastToggleMainSection(mod.key) then
        elseif not selfFrame._mrDetachedHost and MR.RefreshMainPanelSectionsOnly then
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            MR:RefreshMainPanelSectionsOnly()
        elseif MR.RequestUIRefresh then
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            MR:RequestUIRefresh(0.04)
        else
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            MR:RefreshUI()
        end
    elseif button == "RightButton" then
        MR:SetModuleDetached(mod.key, not selfFrame._mrDetachedHost)
        if MR.RequestUIRefresh then
            MR:RequestUIRefresh(0.04)
        else
            MR:RefreshUI()
        end
    end

    selfFrame._pressed = false
end

local function MainSectionHeaderOnEnter(selfFrame)
    local mod = selfFrame._mrMod
    if not mod then
        return
    end

    local alpha = selfFrame._mrHoverAlpha or 0
    if selfFrame._hdrHover then
        selfFrame._hdrHover:SetColorTexture(1, 1, 1, alpha)
    end

    GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")
    GameTooltip:SetText(mod.label, 1, 1, 1)
    GameTooltip:AddLine(L["Tooltip_ExpandCollapse"], 0.5, 0.5, 0.5)
    GameTooltip:AddLine(selfFrame._mrDetachedHost and "Right-click to dock back" or "Right-click to detach", 0.5, 0.8, 1)
    if mod.key == "custom_tasks" then
        GameTooltip:AddLine("Shift-right-click to rename this header.", 0.85, 0.82, 0.45, true)
    end
    GameTooltip:Show()
end

local function MainSectionHeaderOnLeave(selfFrame)
    if selfFrame._hdrHover then
        selfFrame._hdrHover:SetColorTexture(1, 1, 1, 0)
    end
    HideTooltipIfOwned(selfFrame)
end

local function CurrencyBrowserButtonOnClick()
    if MR.ToggleCurrencyBrowserFrame then
        MR:ToggleCurrencyBrowserFrame()
    end
end

local function CurrencyBrowserButtonOnEnter(selfBtn)
    GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
    GameTooltip:SetText("Show all Blizzard currencies", 1, 1, 1)
    GameTooltip:AddLine("Opens a side window populated from the currency API.", 0.55, 0.82, 1, true)
    GameTooltip:Show()
end

local function CurrencyBrowserButtonOnLeave(selfBtn)
    HideTooltipIfOwned(selfBtn)
end

local function MainHeaderActionOnClick(selfBtn)
    local owner = selfBtn._mrOwner
    local data = owner and owner._mrData
    if data and data.row and data.row.onHeaderActionClick then
        data.row.onHeaderActionClick(data.row, data.mod, owner)
    end
end

local function MainHeaderActionOnEnter(selfBtn)
    local owner = selfBtn._mrOwner
    local data = owner and owner._mrData
    if data and data.row and data.row.headerActionTooltip and data.row.headerActionTooltip ~= "" then
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText(data.row.headerActionTooltip, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

local function MainHeaderActionOnLeave(selfBtn)
    HideTooltipIfOwned(selfBtn)
end

local function MainRowOnEnter(selfRow)
    local data = selfRow._mrData
    if not data then
        return
    end

    if data.mode == "sectionHeader" then
        if data.row.note then
            GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
            GameTooltip:SetText(data.row.label, 1, 1, 1)
            GameTooltip:AddLine(data.row.note, 0.70, 0.70, 0.76, true)
            GameTooltip:Show()
        end
        return
    end

    if data.mode == "collapsed" then
        GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Tooltip_DonePrefix"] .. data.row.label, 0.4, 0.85, 0.4, 1, true)
        GameTooltip:AddLine(L["Tooltip_CompletedWeek"], 0.3, 0.6, 0.3)
        GameTooltip:Show()
        return
    end

    if selfRow._hover then
        selfRow._hover:SetColorTexture(1, 1, 1, data.transparent and 0 or (0.04 * data.frameAlpha))
    end

    local row = data.row
    GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
    if row.currencyId and not row.noBlizzardTooltip then
        GameTooltip:SetCurrencyByID(row.currencyId)
        GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
        if row.tooltipFunc then
            row.tooltipFunc(GameTooltip)
        end
    elseif row.itemId and not row.noBlizzardTooltip then
        if GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(row.itemId)
        else
            GameTooltip:SetHyperlink("item:" .. row.itemId)
        end
        GameTooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
    else
        GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
        if row.note then
            GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true)
        end
        if data.hasWaypoint then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format(L["Gathering_Coords"], row.x, row.y), 0.7, 1, 0.9)
            GameTooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
        end
        if row.tooltipFunc then
            row.tooltipFunc(GameTooltip)
        end
        if row.noDefaultTooltipHint then
        elseif row.liveKey or row.autoTracked or (row.currencyId and row.noBlizzardTooltip) then
            GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
        elseif row.questIds then
            GameTooltip:AddLine(L["Tooltip_AutoQuest"], 0.4, 1, 0.6)
        elseif row.spellId or row.itemId then
            GameTooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
        elseif not data.hasWaypoint then
            GameTooltip:AddLine(L["Tooltip_ManualClick"], 0.5, 0.5, 0.5)
        end
    end
    GameTooltip:Show()
end

local function MainRowOnLeave(selfRow)
    if selfRow._hover then
        selfRow._hover:SetColorTexture(1, 1, 1, 0)
    end
    HideTooltipIfOwned(selfRow)
end

local function MainRowOnMouseDown(selfRow, button)
    local data = selfRow._mrData
    if not data or data.mode ~= "normal" then
        return
    end

    local row = data.row
    local mod = data.mod
    local done = data.done

    if button == "LeftButton" and row.onLeftClick then
        local handled = row.onLeftClick(row, mod, done, selfRow)
        if handled ~= false then
            return
        end
    elseif button == "RightButton" and row.onRightClick then
        local handled = row.onRightClick(row, mod, done, selfRow)
        if handled ~= false then
            return
        end
    end

    if button == "LeftButton" and data.hasWaypoint then
        local ok, source = MR:SetWaypoint(row)
        if ok then
            print(string.format(L["Waypoint_Set"], source, row.waypointTitle or row.label, row.x, row.y))
        else
            print(L["Waypoint_Unavailable"])
        end
    elseif not data.isAutoTracked and not row.encounterIds and button == "LeftButton" then
        MR:BumpProgress(mod.key, row.key, 1, row.max)
    elseif not data.isAutoTracked and not row.encounterIds and button == "RightButton" then
        MR:BumpProgress(mod.key, row.key, -1, row.max)
    end
end

local function MainStatusButtonOnClick(selfBtn)
    local owner = selfBtn._mrOwner
    local data = owner and owner._mrData
    if not data or data.mode ~= "normal" then
        return
    end

    local row = data.row
    local mod = data.mod
    if row.toggleStatus and MR.ToggleCustomTask and mod.key == "custom_tasks" then
        MR:ToggleCustomTask(tonumber((row.key or ""):match("task_(%d+)")))
        return
    end


    if row.encounterIds then return end

    local cur = MR:GetManualOverride(mod.key, row.key)
    MR:SetManualOverride(mod.key, row.key, cur >= row.max and 0 or row.max, row.max)
end

local function MainStatusButtonOnEnter(selfBtn)
    local owner = selfBtn._mrOwner
    local data = owner and owner._mrData
    if not data or data.mode ~= "normal" then
        return
    end

    if owner._hover then
        owner._hover:SetColorTexture(1, 1, 1, data.transparent and 0 or (0.04 * data.frameAlpha))
    end

    local row = data.row
    local mo = row.toggleStatus and MR:GetProgress(data.mod.key, row.key) or MR:GetManualOverride(data.mod.key, row.key)
    GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
    if row.note then
        GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true)
    end
    GameTooltip:AddLine(" ")
    if mo >= row.max then
        GameTooltip:AddLine(L["Tooltip_ManualDot_Active"], 1, 0.85, 0.1, true)
    else
        GameTooltip:AddLine(L["Tooltip_ManualDot_Hint"], 0.7, 0.7, 0.7, true)
    end
    GameTooltip:Show()
end

local function MainStatusButtonOnLeave(selfBtn)
    local owner = selfBtn._mrOwner
    if owner and owner._hover then
        owner._hover:SetColorTexture(1, 1, 1, 0)
    end
    HideTooltipIfOwned(selfBtn)
end

local function HideMainRowWidget(rowFrame)
    if not rowFrame then
        return
    end

    HideTooltipIfOwned(rowFrame)
    if rowFrame._headerActionButton then
        HideTooltipIfOwned(rowFrame._headerActionButton)
    end
    if rowFrame._statusBtn then
        HideTooltipIfOwned(rowFrame._statusBtn)
    end
    rowFrame._mrData = nil
    rowFrame._timerUpdate = nil
    rowFrame:Hide()
end

local function HideMainSectionWidget(section)
    if not section then
        return
    end

    if section._hdrFrame then
        HideTooltipIfOwned(section._hdrFrame)
    end
    if section._rows then
        for _, rowFrame in pairs(section._rows) do
            HideMainRowWidget(rowFrame)
        end
    end
    section:Hide()
end

local GetTextOnlyHeaderAlpha
local ShouldShowIcons
local ShouldShowSectionHeaders
local NormalizeIconInfo
local GetRowIconInfo
local GetModuleIconInfo
local ShouldShowModuleHeaderIcon
local GetModuleFallbackIconInfo
local ApplyIconToTexture
local EnsureMainRowWidget
local UpdateMainRowWidget

local function EnsureMainSeparator(self, index)
    self._mainColumnSeparators = self._mainColumnSeparators or {}
    local sep = self._mainColumnSeparators[index]
    if sep then
        sep:SetParent(self.content)
        sep:Show()
        return sep
    end

    sep = CreateFrame("Frame", nil, self.content)
    sep._tex = sep:CreateTexture(nil, "ARTWORK")
    sep._tex:SetAllPoints()
    sep._tex:SetColorTexture(1, 1, 1, 0.08)
    self._mainColumnSeparators[index] = sep
    return sep
end

local function EnsureMainSectionWidget(self, modKey)
    self._mainSectionFrames = self._mainSectionFrames or {}
    local card = self._mainSectionFrames[modKey]
    if card then
        card:SetParent(self.content)
        card:Show()
        return card
    end

    card = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    card._glow = card:CreateTexture(nil, "BACKGROUND")
    card._glow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card._glow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    card._glow:SetTexture("Interface\\Buttons\\WHITE8X8")

    card._hdrFrame = CreateFrame("Frame", nil, card)
    card._hdrFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card._hdrFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    card._hdrFrame:EnableMouse(true)
    card._hdrFrame._hdrHover = card._hdrFrame:CreateTexture(nil, "BORDER")
    card._hdrFrame._hdrHover:SetAllPoints()
    card._hdrFrame._hdrBg = card._hdrFrame:CreateTexture(nil, "BACKGROUND")
    card._hdrFrame._hdrBg:SetAllPoints()
    card._hdrFrame._iconPlate = CreateFrame("Frame", nil, card._hdrFrame, "BackdropTemplate")
    card._hdrFrame._icon = card._hdrFrame:CreateTexture(nil, "ARTWORK")
    card._hdrFrame._label = card._hdrFrame:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._count = card._hdrFrame:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._currencyBrowserButton = CreateFrame("Button", nil, card._hdrFrame, "BackdropTemplate")
    card._hdrFrame._currencyBrowserButton:SetSize(18, 18)
    card._hdrFrame._currencyBrowserButton:SetBackdrop(MakeBackdrop())
    card._hdrFrame._currencyBrowserButton:SetScript("OnClick", CurrencyBrowserButtonOnClick)
    card._hdrFrame._currencyBrowserButton:SetScript("OnEnter", CurrencyBrowserButtonOnEnter)
    card._hdrFrame._currencyBrowserButton:SetScript("OnLeave", CurrencyBrowserButtonOnLeave)
    card._hdrFrame._currencyBrowserText = card._hdrFrame._currencyBrowserButton:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._currencyBrowserText:SetFont(FONT_ROWS, 12, GetFontFlags())
    card._hdrFrame._currencyBrowserText:SetPoint("CENTER", card._hdrFrame._currencyBrowserButton, "CENTER", 0, 0)
    card._hdrFrame._currencyBrowserText:SetText("+")
    card._hdrFrame._arrow = card._hdrFrame:CreateTexture(nil, "OVERLAY")
    card._hdrFrame:SetScript("OnMouseDown", MainSectionHeaderOnMouseDown)
    card._hdrFrame:SetScript("OnMouseUp", MainSectionHeaderOnMouseUp)
    card._hdrFrame:SetScript("OnDragStart", MainSectionHeaderOnDragStart)
    card._hdrFrame:SetScript("OnDragStop", MainSectionHeaderOnDragStop)
    card._hdrFrame:SetScript("OnEnter", MainSectionHeaderOnEnter)
    card._hdrFrame:SetScript("OnLeave", MainSectionHeaderOnLeave)

    card._divider = CreateFrame("Frame", nil, card, "BackdropTemplate")
    card._divider:SetBackdrop(MakeBackdrop(false))

    card._rows = {}
    self._mainSectionFrames[modKey] = card
    return card
end

local function EnsureDetachedSectionWidget(frame, modKey)
    frame._sectionFrames = frame._sectionFrames or {}
    local card = frame._sectionFrames[modKey]
    if card then
        card:SetParent(frame.content)
        card:Show()
        return card
    end

    card = CreateFrame("Frame", nil, frame.content, "BackdropTemplate")
    card._glow = card:CreateTexture(nil, "BACKGROUND")
    card._glow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card._glow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    card._glow:SetTexture("Interface\\Buttons\\WHITE8X8")

    card._hdrFrame = CreateFrame("Frame", nil, card)
    card._hdrFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card._hdrFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    card._hdrFrame:EnableMouse(true)
    card._hdrFrame:RegisterForDrag("LeftButton")
    card._hdrFrame._hdrHover = card._hdrFrame:CreateTexture(nil, "BORDER")
    card._hdrFrame._hdrHover:SetAllPoints()
    card._hdrFrame._hdrBg = card._hdrFrame:CreateTexture(nil, "BACKGROUND")
    card._hdrFrame._hdrBg:SetAllPoints()
    card._hdrFrame._iconPlate = CreateFrame("Frame", nil, card._hdrFrame, "BackdropTemplate")
    card._hdrFrame._icon = card._hdrFrame:CreateTexture(nil, "ARTWORK")
    card._hdrFrame._label = card._hdrFrame:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._count = card._hdrFrame:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._currencyBrowserButton = CreateFrame("Button", nil, card._hdrFrame, "BackdropTemplate")
    card._hdrFrame._currencyBrowserButton:SetSize(18, 18)
    card._hdrFrame._currencyBrowserButton:SetBackdrop(MakeBackdrop())
    card._hdrFrame._currencyBrowserButton:SetScript("OnClick", CurrencyBrowserButtonOnClick)
    card._hdrFrame._currencyBrowserButton:SetScript("OnEnter", CurrencyBrowserButtonOnEnter)
    card._hdrFrame._currencyBrowserButton:SetScript("OnLeave", CurrencyBrowserButtonOnLeave)
    card._hdrFrame._currencyBrowserText = card._hdrFrame._currencyBrowserButton:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._currencyBrowserText:SetFont(FONT_ROWS, 12, GetFontFlags())
    card._hdrFrame._currencyBrowserText:SetPoint("CENTER", card._hdrFrame._currencyBrowserButton, "CENTER", 0, 0)
    card._hdrFrame._currencyBrowserText:SetText("+")
    card._hdrFrame._arrow = card._hdrFrame:CreateTexture(nil, "OVERLAY")
    card._hdrFrame:SetScript("OnMouseDown", MainSectionHeaderOnMouseDown)
    card._hdrFrame:SetScript("OnMouseUp", MainSectionHeaderOnMouseUp)
    card._hdrFrame:SetScript("OnDragStart", MainSectionHeaderOnDragStart)
    card._hdrFrame:SetScript("OnDragStop", MainSectionHeaderOnDragStop)
    card._hdrFrame:SetScript("OnEnter", MainSectionHeaderOnEnter)
    card._hdrFrame:SetScript("OnLeave", MainSectionHeaderOnLeave)

    card._divider = CreateFrame("Frame", nil, card, "BackdropTemplate")
    card._divider:SetBackdrop(MakeBackdrop(false))

    card._rows = {}
    frame._sectionFrames[modKey] = card
    return card
end

local function UpdateDetachedSectionWidget(self, hostFrame, mod, contentWidth)
    local transparent = IsMainTextOnlyMode()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local showSectionHeaders = ShouldShowSectionHeaders()
    local textOnlyHeaderAlpha = showSectionHeaders and GetTextOnlyHeaderAlpha() or 0
    local headerAlpha = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 0.90 or 0) * frameAlpha)
    local dividerAlpha = transparent and (0.50 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.09 or 0) * frameAlpha)
    local showSoftHeaders = transparent and textOnlyHeaderAlpha > 0
    local showIcons = ShouldShowIcons()
    local stats = GetModuleStats(self, mod)
    local isOpen = stats and stats.isOpen
    local secTotal = stats and stats.totalRows or 0
    local secDone = stats and stats.doneRows or 0
    local shownRows = stats and stats.shownRows or 0
    if shownRows == 0 then
        return nil
    end

    local allDone = (secTotal > 0) and (secDone == secTotal)
    local card = EnsureDetachedSectionWidget(hostFrame, mod.key)
    local sectionHeight = math.max((stats and stats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", hostFrame.content, "TOPLEFT", 0, 0)
    card:SetSize(math.max(contentWidth, 1), sectionHeight)
    card:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(card) end
    card._hdrFrame._mrDetachedHost = nil
    if transparent then
        card:SetBackdropColor(0, 0, 0, 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
    else
        card:SetBackdropColor(0.02, 0.03, 0.05, 0.94 * frameAlpha)
        card:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.95 * frameAlpha)
    end
    card._glow:SetColorTexture(0.12, 0.14, 0.18, transparent and 0 or (0.10 * frameAlpha))

    card._hdrFrame:SetHeight(HEADER_HEIGHT)
    card._hdrFrame._mrMod = mod
    card._hdrFrame._mrDetachedHost = hostFrame
    card._hdrFrame._mrHoverAlpha = transparent and (0.10 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.05 or 0) * frameAlpha)
    local customHeaderBg = MR.GetHeaderBackgroundColor and MR:GetHeaderBackgroundColor(mod.key) or nil
    local hdrR, hdrG, hdrB = 0.08, 0.09, 0.12
    if customHeaderBg then
        hdrR, hdrG, hdrB = hex(customHeaderBg)
    end
    card._hdrFrame._hdrBg:SetColorTexture(hdrR, hdrG, hdrB, headerAlpha)

    local explicitColor = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local customColor = MR:GetHeaderColor(mod.key)
    local headerColor = customColor or mod.labelColor or "#ffffff"
    local lr, lg, lb = hex(headerColor)
    local accentA = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 1 or 0) * frameAlpha)
    local accentR, accentG, accentB = lr, lg, lb
    if allDone then
        accentR, accentG, accentB = COL.complete[1], COL.complete[2], COL.complete[3]
    end

    card._hdrFrame._iconPlate:ClearAllPoints()
    card._hdrFrame._iconPlate:SetSize(math.max(HEADER_HEIGHT - 6, 12), math.max(HEADER_HEIGHT - 6, 12))
    card._hdrFrame._iconPlate:SetPoint("LEFT", card._hdrFrame, "LEFT", 4, 0)
    card._hdrFrame._iconPlate:SetBackdrop(MakeBackdrop())
    local iconPlateBgAlpha = transparent and (showSoftHeaders and (0.16 * accentA) or 0) or ((showSectionHeaders and 0.16 or 0) * frameAlpha)
    local iconPlateBorderAlpha = transparent and (showSoftHeaders and (0.50 * accentA) or 0) or ((showSectionHeaders and 0.50 or 0) * frameAlpha)
    card._hdrFrame._iconPlate:SetBackdropColor(accentR, accentG, accentB, iconPlateBgAlpha)
    card._hdrFrame._iconPlate:SetBackdropBorderColor(accentR, accentG, accentB, iconPlateBorderAlpha)

    local iconInfo = showIcons and ShouldShowModuleHeaderIcon(mod.key) and GetModuleIconInfo(mod) or nil
    card._hdrFrame._icon:ClearAllPoints()
    card._hdrFrame._icon:SetSize(math.max(HEADER_HEIGHT - 12, 9), math.max(HEADER_HEIGHT - 12, 9))
    card._hdrFrame._icon:SetPoint("CENTER", card._hdrFrame._iconPlate, "CENTER", 0, 0)
    local hasHeaderIcon = ApplyIconToTexture(card._hdrFrame._icon, iconInfo, { 0.14, 0.86, 0.14, 0.86 })
    card._hdrFrame._iconPlate:SetShown(hasHeaderIcon and (showIcons or showSectionHeaders))

    card._hdrFrame._label:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
    card._hdrFrame._label:ClearAllPoints()
    if hasHeaderIcon then
        card._hdrFrame._label:SetPoint("LEFT", card._hdrFrame._iconPlate, "RIGHT", 6, 0)
    else
        card._hdrFrame._label:SetPoint("LEFT", card._hdrFrame, "LEFT", 9, 0)
    end
    card._hdrFrame._label:SetJustifyH("LEFT")
    if card._hdrFrame._label.SetWordWrap then
        card._hdrFrame._label:SetWordWrap(false)
    end
    card._hdrFrame._label:SetText((allDone and not explicitColor) and WC("00ff96", mod.label) or WC(headerColor:gsub("#", ""), mod.label))

    card._hdrFrame._count:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    card._hdrFrame._count:ClearAllPoints()
    local currencyBrowserButton = card._hdrFrame._currencyBrowserButton
    local showCurrencyBrowserButton = mod.key == "currencies" and MR.ToggleCurrencyBrowserFrame
    if showCurrencyBrowserButton then
        currencyBrowserButton:ClearAllPoints()
        currencyBrowserButton:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -20, 0)
        currencyBrowserButton:SetBackdropColor(0.04, 0.10, 0.13, transparent and 0 or (0.96 * frameAlpha))
        currencyBrowserButton:SetBackdropBorderColor(0.18, 0.58, 0.48, transparent and 0 or frameAlpha)
        card._hdrFrame._currencyBrowserText:SetTextColor(0.35, 0.95, 0.78, transparent and 0.75 or 1)
        currencyBrowserButton:Show()
        card._hdrFrame._count:SetPoint("RIGHT", currencyBrowserButton, "LEFT", -6, 0)
    else
        currencyBrowserButton:Hide()
        card._hdrFrame._count:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -18, 0)
    end
    card._hdrFrame._count:SetText(string.format(L["%d / %d complete"], secDone, secTotal))
    card._hdrFrame._count:SetTextColor(countColor(secDone, secTotal))
    card._hdrFrame._count:SetJustifyH("RIGHT")
    card._hdrFrame._label:SetPoint("RIGHT", card._hdrFrame._count, "LEFT", -8, 0)

    card._hdrFrame._arrow:SetSize(10, 10)
    card._hdrFrame._arrow:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -6, 0)
    if isOpen then
        card._hdrFrame._arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    else
        card._hdrFrame._arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    end
    card._hdrFrame._arrow:SetVertexColor(0.45, 0.45, 0.45)

    local localY = HEADER_HEIGHT
    card._divider:ClearAllPoints()
    card._divider:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -localY)
    card._divider:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, -localY)
    card._divider:SetHeight(1)
    card._divider:SetBackdropColor(1, 1, 1, dividerAlpha)

    local usedRows = {}
    if isOpen then
        localY = localY + 1
        local hideComplete = stats and stats.hideComplete
        for _, row in ipairs(mod.rows) do
            local rowVisible = not row.isVisible or row.isVisible()
            if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
                local done = MR:GetProgress(mod.key, row.key)
                local rowComplete = self:IsRowComplete(mod, row, done)
                if row.control or not (hideComplete and rowComplete) then
                    local _, nextY, rowId = UpdateMainRowWidget(self, card, mod, row, done, localY, card:GetWidth())
                    localY = nextY
                    usedRows[rowId] = true
                end
            end
        end
    end

    for key, rowFrame in pairs(card._rows or {}) do
        if not usedRows[key] then
            HideMainRowWidget(rowFrame)
        end
    end

    return card
end

EnsureMainRowWidget = function(section, rowKey)
    section._rows = section._rows or {}
    local rowFrame = section._rows[rowKey]
    if rowFrame then
        rowFrame:SetParent(section)
        rowFrame:Show()
        return rowFrame
    end

    rowFrame = CreateFrame("Frame", nil, section)
    rowFrame:EnableMouse(true)
    rowFrame:SetScript("OnEnter", MainRowOnEnter)
    rowFrame:SetScript("OnLeave", MainRowOnLeave)
    rowFrame:SetScript("OnMouseDown", MainRowOnMouseDown)

    rowFrame._headerBg = rowFrame:CreateTexture(nil, "BACKGROUND")
    rowFrame._headerBg:SetAllPoints()
    rowFrame._headerText = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._headerActionButton = CreateFrame("Button", nil, rowFrame, "BackdropTemplate")
    rowFrame._headerActionButton._mrOwner = rowFrame
    rowFrame._headerActionButton:SetScript("OnClick", MainHeaderActionOnClick)
    rowFrame._headerActionButton:SetScript("OnEnter", MainHeaderActionOnEnter)
    rowFrame._headerActionButton:SetScript("OnLeave", MainHeaderActionOnLeave)
    rowFrame._headerActionText = rowFrame._headerActionButton:CreateFontString(nil, "OVERLAY")
    rowFrame._headerActionText:SetFont(FONT_ROWS, 9, GetFontFlags())
    rowFrame._headerCount = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._headerCount:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())

    rowFrame._collapsedLine = rowFrame:CreateTexture(nil, "ARTWORK")
    rowFrame._collapsedDot = rowFrame:CreateTexture(nil, "ARTWORK")

    rowFrame._hover = rowFrame:CreateTexture(nil, "BACKGROUND")
    rowFrame._hover:SetAllPoints()
    rowFrame._rowShade = rowFrame:CreateTexture(nil, "BORDER")
    rowFrame._separator = rowFrame:CreateTexture(nil, "ARTWORK")

    rowFrame._statusBtn = CreateFrame("Button", nil, rowFrame, "BackdropTemplate")
    rowFrame._statusBtn._mrOwner = rowFrame
    rowFrame._statusBtn:SetScript("OnClick", MainStatusButtonOnClick)
    rowFrame._statusBtn:SetScript("OnEnter", MainStatusButtonOnEnter)
    rowFrame._statusBtn:SetScript("OnLeave", MainStatusButtonOnLeave)
    rowFrame._statusFill = rowFrame._statusBtn:CreateTexture(nil, "ARTWORK")
    rowFrame._statusFill:SetPoint("TOPLEFT", rowFrame._statusBtn, "TOPLEFT", 2, -2)
    rowFrame._statusFill:SetPoint("BOTTOMRIGHT", rowFrame._statusBtn, "BOTTOMRIGHT", -2, 2)
    rowFrame._statusCheck = rowFrame._statusBtn:CreateFontString(nil, "OVERLAY")
    rowFrame._statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
    rowFrame._statusCheck:SetPoint("CENTER", rowFrame._statusBtn, "CENTER", 0, 1)
    rowFrame._statusCheck:SetText("x")

    rowFrame._rowIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    rowFrame._countIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    rowFrame._label = rowFrame:CreateFontString(nil, "OVERLAY")
    if rowFrame._label.SetWordWrap then
        rowFrame._label:SetWordWrap(false)
    end
    if rowFrame._label.SetNonSpaceWrap then
        rowFrame._label:SetNonSpaceWrap(false)
    end
    if rowFrame._label.SetShadowOffset then
        rowFrame._label:SetShadowOffset(0, 0)
    end
    rowFrame._count = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._count:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
    rowFrame._wallet = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._wallet:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
    rowFrame._coords = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._coords:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
    rowFrame._vault = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._vault:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())


    local DIFF_BADGE_DEFS = {
        { id = 17, label = "L" },
        { id = 14, label = "N" },
        { id = 15, label = "H" },
        { id = 16, label = "M" },
    }
    rowFrame._diffBadges = {}
    for i, def in ipairs(DIFF_BADGE_DEFS) do
        local btn = CreateFrame("Frame", nil, rowFrame, "BackdropTemplate")
        btn:SetSize(14, 14)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_ROWS, math.max(6, GetFontSize() - 3), "OUTLINE")
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
        lbl:SetText(def.label)
        btn._lbl = lbl
        btn._diffId = def.id
        btn:Hide()
        rowFrame._diffBadges[i] = btn
    end
    rowFrame._diffCount = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._diffCount:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())

    section._rows[rowKey] = rowFrame
    return rowFrame
end

UpdateMainRowWidget = function(self, section, mod, row, done, yOff, colW)
    local rowId = row.key or tostring(row.label or yOff)
    local rowFrame = EnsureMainRowWidget(section, rowId)
    local transparent = IsMainTextOnlyMode()
    local showIcons = ShouldShowIcons()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local isAutoTracked = row.autoTracked
        or ((row.questIds ~= nil) and not row.allowManualQuestClicks)
        or (row.encounterIds ~= nil)
        or (row.liveKey ~= nil)
        or (row.spellId ~= nil)
        or (row.currencyId ~= nil)
        or (row.itemId ~= nil)
    local hasWaypoint = row.zone and row.x and row.y
    local isComplete = self:IsRowComplete(mod, row, done)
    local collapsed = false
    local rowH = collapsed and 8 or ROW_HEIGHT

    rowFrame._mrData = rowFrame._mrData or {}
    rowFrame._mrData.mod = mod
    rowFrame._mrData.row = row
    rowFrame._mrData.done = done
    rowFrame._mrData.transparent = transparent
    rowFrame._mrData.frameAlpha = frameAlpha
    rowFrame._mrData.isAutoTracked = isAutoTracked
    rowFrame._mrData.hasWaypoint = hasWaypoint
    rowFrame._mrData.isComplete = isComplete
    rowFrame:ClearAllPoints()
    rowFrame:SetPoint("TOPLEFT", section, "TOPLEFT", 0, -yOff)
    rowFrame:SetSize(colW, rowH)
    rowFrame._timerUpdate = nil
    rowFrame:Show()

    rowFrame._headerBg:Hide()
    rowFrame._headerText:Hide()
    rowFrame._headerActionButton:Hide()
    rowFrame._headerCount:Hide()
    rowFrame._collapsedLine:Hide()
    rowFrame._collapsedDot:Hide()
    rowFrame._hover:Hide()
    rowFrame._rowShade:Hide()
    rowFrame._separator:Hide()
    rowFrame._statusBtn:Hide()
    rowFrame._rowIcon:Hide()
    rowFrame._countIcon:Hide()
    rowFrame._label:Hide()
    rowFrame._count:Hide()
    rowFrame._wallet:Hide()
    rowFrame._coords:Hide()
    rowFrame._vault:Hide()
    if rowFrame._diffBadges then
        for _, badge in ipairs(rowFrame._diffBadges) do badge:Hide() end
    end
    if rowFrame._diffCount then rowFrame._diffCount:Hide() end

    if row.sectionHeader then
        rowFrame._mrData.mode = "sectionHeader"
        rowFrame._headerBg:Show()
        if transparent then
            rowFrame._headerBg:SetColorTexture(1, 1, 1, 0)
        else
            rowFrame._headerBg:SetColorTexture(0.06, 0.08, 0.13, 0.92 * frameAlpha)
        end

        SetFontForText(rowFrame._headerText, row.label, math.max(8, GetFontSize() - 1), GetFontFlags())
        rowFrame._headerText:ClearAllPoints()
        rowFrame._headerText:SetPoint("LEFT", rowFrame, "LEFT", 8, 0)
        rowFrame._headerText:SetPoint("RIGHT", rowFrame, "RIGHT", -84, 0)
        rowFrame._headerText:SetJustifyH("LEFT")
        rowFrame._headerText:SetText(row.label)
        rowFrame._headerText:SetTextColor(0.82, 0.66, 0.98)
        rowFrame._headerText:Show()

        local headerActionButton = nil
        if ((row.headerActionText and row.headerActionText ~= "") or row.headerActionStyle == "visibility") and row.onHeaderActionClick then
            headerActionButton = rowFrame._headerActionButton
            headerActionButton:ClearAllPoints()
            headerActionButton:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
            headerActionButton:Show()
            rowFrame._headerActionText:ClearAllPoints()

            if row.headerActionStyle == "visibility" then
                headerActionButton:SetSize(14, 14)
                headerActionButton:SetBackdrop(MakeBackdrop())
                headerActionButton:SetBackdropColor(0.05, 0.10, 0.18, 1)
                headerActionButton:SetBackdropBorderColor(
                    row.headerActionVisible and 0.15 or 0.35,
                    row.headerActionVisible and 0.32 or 0.12,
                    row.headerActionVisible and 0.38 or 0.12,
                    1
                )
                rowFrame._headerActionText:SetFont(FONT_ROWS, 9, GetFontFlags())
                rowFrame._headerActionText:SetPoint("CENTER", headerActionButton, "CENTER", 0, 0)
                rowFrame._headerActionText:SetJustifyH("CENTER")
                rowFrame._headerActionText:SetText(row.headerActionVisible and "o" or "-")
                rowFrame._headerActionText:SetTextColor(
                    row.headerActionVisible and 0.25 or 0.55,
                    row.headerActionVisible and 0.85 or 0.25,
                    row.headerActionVisible and 0.70 or 0.25
                )
            else
                headerActionButton:SetSize(26, rowH)
                rowFrame._headerActionText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                rowFrame._headerActionText:SetPoint("CENTER", headerActionButton, "CENTER", 0, 0)
                rowFrame._headerActionText:SetJustifyH("CENTER")
                rowFrame._headerActionText:SetText(row.headerActionText)
                if row.headerActionColor then
                    rowFrame._headerActionText:SetTextColor(row.headerActionColor[1], row.headerActionColor[2], row.headerActionColor[3])
                else
                    rowFrame._headerActionText:SetTextColor(0.92, 0.78, 0.24)
                end
            end
            rowFrame._headerActionText:Show()
        end

        if row.countText and row.countText ~= "" then
            rowFrame._headerCount:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
            rowFrame._headerCount:ClearAllPoints()
            if headerActionButton then
                rowFrame._headerCount:SetPoint("RIGHT", headerActionButton, "LEFT", -8, 0)
            else
                rowFrame._headerCount:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
            end
            rowFrame._headerCount:SetJustifyH("RIGHT")
            rowFrame._headerCount:SetText(row.countText)
            if row.countColor then
                rowFrame._headerCount:SetTextColor(row.countColor[1], row.countColor[2], row.countColor[3])
            else
                rowFrame._headerCount:SetTextColor(0.74, 0.80, 0.88)
            end
            rowFrame._headerCount:Show()
        end

        return rowFrame, yOff + rowH, rowId
    end

    rowFrame._mrData.mode = "normal"
    rowFrame._hover:SetColorTexture(1, 1, 1, 0)
    rowFrame._hover:Show()
    rowFrame._rowShade:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, -1)
    rowFrame._rowShade:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, 0)
    if isComplete and not transparent then
        rowFrame._rowShade:SetColorTexture(0.12, 0.16, 0.12, 0.18 * frameAlpha)
    else
        rowFrame._rowShade:SetColorTexture(0, 0, 0, 0)
    end
    rowFrame._rowShade:Show()

    rowFrame._separator:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", 12, 0)
    rowFrame._separator:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -12, 0)
    rowFrame._separator:SetHeight(1)
    rowFrame._separator:SetColorTexture(1, 1, 1, transparent and 0 or (0.06 * frameAlpha))
    rowFrame._separator:Show()

    rowFrame._statusBtn:ClearAllPoints()
    rowFrame._statusBtn:SetSize(14, 14)
    rowFrame._statusBtn:SetPoint("LEFT", rowFrame, "LEFT", PADDING + 2, 0)
    rowFrame._statusBtn:SetBackdrop(MakeBackdrop())

    local mo = MR:GetManualOverride(mod.key, row.key)
    local forcedComplete = row.max and mo >= row.max
    local activeDone = forcedComplete and row.max or done
    if transparent then
        rowFrame._statusBtn:SetBackdropColor(0, 0, 0, 0)
    else
        rowFrame._statusBtn:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * frameAlpha)
    end
    if forcedComplete then
        rowFrame._statusBtn:SetBackdropBorderColor(transparent and 0 or 0.88, transparent and 0 or 0.74, transparent and 0 or 0.22, transparent and 0 or frameAlpha)
        rowFrame._statusFill:SetColorTexture(0.88, 0.74, 0.22, transparent and 0 or (0.85 * frameAlpha))
        rowFrame._statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
        rowFrame._statusCheck:SetTextColor(0.10, 0.08, 0.02, transparent and 0 or 1)
        if transparent then rowFrame._statusCheck:Hide() else rowFrame._statusCheck:Show() end
    elseif isComplete then
        rowFrame._statusBtn:SetBackdropBorderColor(transparent and 0 or 0.24, transparent and 0 or 0.76, transparent and 0 or 0.46, transparent and 0 or frameAlpha)
        rowFrame._statusFill:SetColorTexture(0.20, 0.72, 0.42, transparent and 0 or (0.85 * frameAlpha))
        rowFrame._statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
        rowFrame._statusCheck:SetTextColor(0.03, 0.08, 0.04, transparent and 0 or 1)
        if transparent then rowFrame._statusCheck:Hide() else rowFrame._statusCheck:Show() end
    elseif row.max and activeDone > 0 then
        rowFrame._statusBtn:SetBackdropBorderColor(transparent and 0 or 0.62, transparent and 0 or 0.52, transparent and 0 or 0.22, transparent and 0 or (0.95 * frameAlpha))
        rowFrame._statusFill:SetColorTexture(0.78, 0.62, 0.22, transparent and 0 or (0.70 * frameAlpha))
        rowFrame._statusCheck:Hide()
    else
        rowFrame._statusBtn:SetBackdropBorderColor(transparent and 0 or 0.24, transparent and 0 or 0.28, transparent and 0 or 0.34, transparent and 0 or (0.95 * frameAlpha))
        rowFrame._statusFill:SetColorTexture(0.09, 0.10, 0.14, transparent and 0 or (0.70 * frameAlpha))
        rowFrame._statusCheck:Hide()
    end
    if row.hideStatus then
        rowFrame._statusBtn:Hide()
    else
        rowFrame._statusBtn:Show()
    end
    rowFrame._statusBtn:EnableMouse((((isAutoTracked and not row.noMax) or row.toggleStatus) and not row.hideStatus) and true or false)

    local isCurrencyModule = mod and (mod.key == "currencies" or mod.key == "pvp_currencies")
    local countIconInfo = (showIcons and isCurrencyModule and row.currencyId) and GetRowIconInfo(mod, row) or nil
    local rowIconInfo = nil
    local iconSize = math.max(ROW_HEIGHT - 8, 12)
    rowFrame._rowIcon:ClearAllPoints()
    rowFrame._rowIcon:SetSize(iconSize, iconSize)
    rowFrame._rowIcon:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
    local hasRowIcon = ApplyIconToTexture(rowFrame._rowIcon, rowIconInfo)
    if isComplete and hasRowIcon then
        rowFrame._rowIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    else
        rowFrame._rowIcon:SetVertexColor(1, 1, 1, 1)
    end
    rowFrame._rowIcon:SetShown(hasRowIcon)

    rowFrame._countIcon:ClearAllPoints()
    rowFrame._countIcon:SetSize(iconSize, iconSize)
    rowFrame._countIcon:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    local hasCountIcon = ApplyIconToTexture(rowFrame._countIcon, countIconInfo)
    if isComplete and hasCountIcon then
        rowFrame._countIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    else
        rowFrame._countIcon:SetVertexColor(1, 1, 1, 1)
    end
    rowFrame._countIcon:SetShown(hasCountIcon)

    local hasNumericMax = type(row.max) == "number" and row.max > 0
    local isCurrencyRow = row.currencyId and hasNumericMax and not row.noMax
    local hasCoordText = hasWaypoint and not row.hideCoordText
    local lblRightOff = isCurrencyRow and -96 or (hasCoordText and -128 or -52)

    SetFontForText(rowFrame._label, CleanLabelText(row.label), GetFontSize(), GetFontFlags())
    rowFrame._label:ClearAllPoints()
    if hasRowIcon then
        rowFrame._label:SetPoint("LEFT", rowFrame._rowIcon, "RIGHT", 8, 0)
    else
        rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
    end
    rowFrame._label:SetPoint("RIGHT", rowFrame, "RIGHT", lblRightOff, 0)
    rowFrame._label:SetJustifyH("LEFT")
    rowFrame._label:SetJustifyV("MIDDLE")

    local rowCustom = MR:GetRowColor(mod.key, row.key)
    local headerCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local inlineColor = ExtractInlineLabelColor(row.label)
    local effectiveColor = rowCustom or headerCustom or inlineColor
    local cleanLabel = CleanLabelText(row.label)
    if isComplete then
        rowFrame._label:SetText(cleanLabel)
        if effectiveColor then
            local cr, cg, cb = hex(effectiveColor)
            rowFrame._label:SetTextColor(cr * 0.45, cg * 0.45, cb * 0.45)
        else
            rowFrame._label:SetTextColor(0.38, 0.38, 0.38)
        end
    elseif effectiveColor then
        rowFrame._label:SetText(cleanLabel)
        rowFrame._label:SetTextColor(hex(effectiveColor))
    else
        rowFrame._label:SetText(cleanLabel)
        rowFrame._label:SetTextColor(1, 1, 1)
    end
    rowFrame._label:Show()

    rowFrame._count:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
    rowFrame._count:ClearAllPoints()
    if hasCountIcon then
        rowFrame._count:SetPoint("RIGHT", rowFrame._countIcon, "LEFT", -4, 0)
    else
        rowFrame._count:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    end
    rowFrame._count:SetJustifyH("RIGHT")
    if rowFrame._count.SetWordWrap then
        rowFrame._count:SetWordWrap(false)
    end
    rowFrame._count:SetWidth(0)

    if row.countText then
        rowFrame._count:SetText(row.countText)
        if row.countColor then
            rowFrame._count:SetTextColor(row.countColor[1], row.countColor[2], row.countColor[3])
        else
            rowFrame._count:SetTextColor(0.8, 0.8, 0.8)
        end

        if not isCurrencyRow and not hasCoordText then
            local reservedWidth
            if type(row.countWidth) == "number" and row.countWidth > 0 then
                reservedWidth = row.countWidth
            else
                reservedWidth = math.min(
                    math.max(math.floor((rowFrame._count:GetStringWidth() or 0) + 8), 64),
                    math.floor(math.max(rowFrame:GetWidth() * 0.5, 64))
                )
            end
            rowFrame._count:SetWidth(reservedWidth)
            rowFrame._label:ClearAllPoints()
            if hasRowIcon then
                rowFrame._label:SetPoint("LEFT", rowFrame._rowIcon, "RIGHT", 8, 0)
            else
                rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
            end
            rowFrame._label:SetPoint("RIGHT", rowFrame._count, "LEFT", -8, 0)
        else
            rowFrame._count:SetWidth(0)
        end
    elseif isCurrencyRow then
        local mdb = MR.db and MR.db.char.progress[mod.key]
        local wallet = (mdb and mdb[row.key .. "_wallet"]) or done
        rowFrame._count:SetText(string.format("%d/%d", done, row.max))
        rowFrame._count:SetTextColor(countColor(done, row.max))
        rowFrame._wallet:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
        rowFrame._wallet:ClearAllPoints()
        rowFrame._wallet:SetPoint("RIGHT", rowFrame._count, "LEFT", -5, 0)
        rowFrame._wallet:SetJustifyH("RIGHT")
        rowFrame._wallet:SetText(string.format("|cffaaaaaa(%d)|r", wallet))
        rowFrame._wallet:Show()
        rowFrame._label:ClearAllPoints()
        if hasRowIcon then
            rowFrame._label:SetPoint("LEFT", rowFrame._rowIcon, "RIGHT", 8, 0)
        else
            rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
        end
        rowFrame._label:SetPoint("RIGHT", rowFrame._wallet, "LEFT", -8, 0)
    else
        rowFrame._count:SetText((row.noMax or not hasNumericMax) and tostring(done) or string.format("%d / %d", done, row.max))
        if row.noMax or not hasNumericMax then
            rowFrame._count:SetTextColor(0.8, 0.8, 0.8)
        else
            rowFrame._count:SetTextColor(countColor(done, row.max))
        end
        if hasCountIcon and row.currencyId then
            rowFrame._label:ClearAllPoints()
            rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
            rowFrame._label:SetPoint("RIGHT", rowFrame._count, "LEFT", -8, 0)
        end
    end
    rowFrame._count:Show()

    if hasCoordText then
        rowFrame._coords:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
        rowFrame._coords:ClearAllPoints()
        rowFrame._coords:SetPoint("RIGHT", rowFrame._count, "LEFT", -8, 0)
        rowFrame._coords:SetJustifyH("RIGHT")
        rowFrame._coords:SetText(string.format("%.2f, %.2f", row.x, row.y))
        if isComplete then
            rowFrame._coords:SetTextColor(0.4, 0.4, 0.4, 0.6)
        else
            rowFrame._coords:SetTextColor(0.65, 0.9, 1, 0.95)
        end
        rowFrame._coords:Show()
    end

    if row.vaultLabel then
        rowFrame._vault:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
        rowFrame._vault:ClearAllPoints()
        rowFrame._vault:SetPoint("RIGHT", rowFrame._count, "LEFT", -4, 0)
        rowFrame._vault:SetText(row.vaultLabel)
        rowFrame._vault:SetTextColor(hex(row.vaultColor or "#ffffff"))
        rowFrame._vault:Show()
    end



    local DIFF_BADGE_ORDER = { 17, 14, 15, 16 }
    local DIFF_BADGE_COLORS = {
        [17] = { done = { 0.30, 0.60, 1.00 }, todo = { 0.08, 0.14, 0.24 }, border_done = { 0.22, 0.50, 0.90 }, border_todo = { 0.08, 0.12, 0.20 }, text_done = { 1, 1, 1 }, text_todo = { 0.22, 0.35, 0.50 } },
        [14] = { done = { 0.22, 0.72, 0.32 }, todo = { 0.06, 0.16, 0.09 }, border_done = { 0.16, 0.58, 0.26 }, border_todo = { 0.06, 0.14, 0.08 }, text_done = { 1, 1, 1 }, text_todo = { 0.18, 0.38, 0.22 } },
        [15] = { done = { 1.00, 0.52, 0.08 }, todo = { 0.26, 0.14, 0.04 }, border_done = { 0.88, 0.42, 0.06 }, border_todo = { 0.18, 0.10, 0.03 }, text_done = { 1, 1, 1 }, text_todo = { 0.48, 0.26, 0.10 } },
        [16] = { done = { 0.85, 0.18, 0.20 }, todo = { 0.24, 0.06, 0.07 }, border_done = { 0.70, 0.12, 0.14 }, border_todo = { 0.18, 0.05, 0.05 }, text_done = { 1, 1, 1 }, text_todo = { 0.46, 0.16, 0.16 } },
    }

    local hasEncounterDiffTracking = row.encounterIds and rowFrame._diffBadges and row.taskId
    if hasEncounterDiffTracking then
        local diffState = {}
        if MR.db and MR.db.char and MR.db.char.customTaskDiffProgress then
            diffState = MR.db.char.customTaskDiffProgress[tostring(row.taskId)] or {}
        end


        local effectiveDiffs = row.encounterDifficulties
        local allDiffs = (effectiveDiffs == nil)


        local visibleBadges = {}
        for _, diffId in ipairs(DIFF_BADGE_ORDER) do
            if allDiffs or (effectiveDiffs and effectiveDiffs[diffId]) then
                for _, badge in ipairs(rowFrame._diffBadges) do
                    if badge._diffId == diffId then
                        visibleBadges[#visibleBadges + 1] = badge
                        break
                    end
                end
            end
        end

        for _, badge in ipairs(rowFrame._diffBadges) do badge:Hide() end

        local numTracked = #visibleBadges
        local numDone = 0
        for _, badge in ipairs(visibleBadges) do
            if diffState[badge._diffId] then numDone = numDone + 1 end
        end



        local BADGE_W, BADGE_GAP = 14, 2
        local rowH = ROW_HEIGHT
        local badgeY = math.floor((rowH - BADGE_W) / 2)
        for i, badge in ipairs(visibleBadges) do
            badge:SetSize(BADGE_W, BADGE_W)
            badge:ClearAllPoints()


            local xOff = -4 - (numTracked - i) * (BADGE_W + BADGE_GAP)
            badge:SetPoint("TOPRIGHT", rowFrame, "TOPRIGHT", xOff, -badgeY)
            badge:Show()

            local isDone = diffState[badge._diffId] == true
            local col = DIFF_BADGE_COLORS[badge._diffId] or DIFF_BADGE_COLORS[14]
            local bgC = isDone and col.done or col.todo
            local bdC = isDone and col.border_done or col.border_todo
            local txtC = isDone and col.text_done or col.text_todo
            badge:SetBackdropColor(bgC[1], bgC[2], bgC[3], transparent and 0 or (isDone and 0.88 or 0.65) * frameAlpha)
            badge:SetBackdropBorderColor(bdC[1], bdC[2], bdC[3], transparent and 0 or frameAlpha)
            badge._lbl:SetTextColor(txtC[1], txtC[2], txtC[3], transparent and (isDone and 0.70 or 0.25) or (isDone and 1 or 0.40))
        end


        local badgeZoneWidth = numTracked * (BADGE_W + BADGE_GAP)
        if rowFrame._diffCount then
            rowFrame._diffCount:ClearAllPoints()
            rowFrame._diffCount:SetPoint("RIGHT", rowFrame, "RIGHT", -4 - badgeZoneWidth - 4, 0)
            rowFrame._diffCount:SetJustifyH("RIGHT")
            rowFrame._diffCount:SetText(string.format("%d/%d", numDone, numTracked))
            if numDone >= numTracked and numTracked > 0 then
                rowFrame._diffCount:SetTextColor(0.22, 0.72, 0.32)
            elseif numDone > 0 then
                rowFrame._diffCount:SetTextColor(0.88, 0.72, 0.28)
            else
                rowFrame._diffCount:SetTextColor(0.38, 0.42, 0.48)
            end
            rowFrame._diffCount:Show()
        end


        rowFrame._count:Hide()
        local reservedRight = badgeZoneWidth + 32
        rowFrame._label:ClearAllPoints()
        if hasRowIcon then
            rowFrame._label:SetPoint("LEFT", rowFrame._rowIcon, "RIGHT", 8, 0)
        else
            rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
        end
        rowFrame._label:SetPoint("RIGHT", rowFrame, "RIGHT", -(reservedRight + 8), 0)
    end

    if row.timerEpoch and not isComplete and not collapsed then
        local function FormatMMSS(s)
            return string.format("%d:%02d", math.floor(s / 60), s % 60)
        end
        local function UpdateTimer()
            local now = GetServerTime()
            local offset = (now - row.timerEpoch) % row.timerInterval
            if offset < row.timerDuration then
                local rem = row.timerDuration - offset
                rowFrame._count:SetText(L["Timer_Live"] .. FormatMMSS(rem))
                rowFrame._count:SetTextColor(0.25, 0.88, 0.50, 1)
            else
                local rem = row.timerInterval - offset
                rowFrame._count:SetText(L["Timer_Next"] .. FormatMMSS(rem))
                rowFrame._count:SetTextColor(0.55, 0.55, 0.55, 1)
            end
        end
        UpdateTimer()
        rowFrame._timerUpdate = UpdateTimer
        table.insert(MR._timerRows, rowFrame)
    end

    return rowFrame, yOff + rowH, rowId
end

local function UpdateMainSectionWidget(self, mod, yOff, xOff, colW, col, recordRegistry)
    local transparent = IsMainTextOnlyMode()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local showSectionHeaders = ShouldShowSectionHeaders()
    local textOnlyHeaderAlpha = showSectionHeaders and GetTextOnlyHeaderAlpha() or 0
    local headerAlpha = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 0.90 or 0) * frameAlpha)
    local dividerAlpha = transparent and (0.50 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.09 or 0) * frameAlpha)
    local showSoftHeaders = transparent and textOnlyHeaderAlpha > 0
    local showIcons = ShouldShowIcons()
    local stats = GetModuleStats(self, mod)
    local isOpen = stats and stats.isOpen
    local secTotal = stats and stats.totalRows or 0
    local secDone = stats and stats.doneRows or 0
    local shownRows = stats and stats.shownRows or 0
    if shownRows == 0 then
        return nil
    end

    local allDone = (secTotal > 0) and (secDone == secTotal)
    local card = EnsureMainSectionWidget(self, mod.key)
    local sectionHeight = math.max((stats and stats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", self.content, "TOPLEFT", xOff + 3, -yOff)
    card:SetSize(math.max(colW - 6, 1), sectionHeight)
    card:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(card) end
    if transparent then
        card:SetBackdropColor(0, 0, 0, 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
    else
        card:SetBackdropColor(0.02, 0.03, 0.05, 0.94 * frameAlpha)
        card:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.95 * frameAlpha)
    end
    card._glow:SetColorTexture(0.12, 0.14, 0.18, transparent and 0 or (0.10 * frameAlpha))

    card._hdrFrame:SetHeight(HEADER_HEIGHT)
    card._hdrFrame._mrMod = mod
    card._hdrFrame._mrHoverAlpha = transparent and (0.10 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.05 or 0) * frameAlpha)
    local customHeaderBg = MR.GetHeaderBackgroundColor and MR:GetHeaderBackgroundColor(mod.key) or nil
    local hdrR, hdrG, hdrB = 0.08, 0.09, 0.12
    if customHeaderBg then
        hdrR, hdrG, hdrB = hex(customHeaderBg)
    end
    card._hdrFrame._hdrBg:SetColorTexture(hdrR, hdrG, hdrB, headerAlpha)

    local explicitColor = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local customColor = MR:GetHeaderColor(mod.key)
    local headerColor = customColor or mod.labelColor or "#ffffff"
    local lr, lg, lb = hex(headerColor)
    local accentA = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 1 or 0) * frameAlpha)
    local accentR, accentG, accentB = lr, lg, lb
    if allDone then
        accentR, accentG, accentB = COL.complete[1], COL.complete[2], COL.complete[3]
    end

    card._hdrFrame._iconPlate:ClearAllPoints()
    card._hdrFrame._iconPlate:SetSize(math.max(HEADER_HEIGHT - 6, 12), math.max(HEADER_HEIGHT - 6, 12))
    card._hdrFrame._iconPlate:SetPoint("LEFT", card._hdrFrame, "LEFT", 4, 0)
    card._hdrFrame._iconPlate:SetBackdrop(MakeBackdrop())
    local iconPlateBgAlpha = transparent and (showSoftHeaders and (0.16 * accentA) or 0) or ((showSectionHeaders and 0.16 or 0) * frameAlpha)
    local iconPlateBorderAlpha = transparent and (showSoftHeaders and (0.50 * accentA) or 0) or ((showSectionHeaders and 0.50 or 0) * frameAlpha)
    card._hdrFrame._iconPlate:SetBackdropColor(accentR, accentG, accentB, iconPlateBgAlpha)
    card._hdrFrame._iconPlate:SetBackdropBorderColor(accentR, accentG, accentB, iconPlateBorderAlpha)

    local iconInfo = showIcons and ShouldShowModuleHeaderIcon(mod.key) and GetModuleIconInfo(mod) or nil
    card._hdrFrame._icon:ClearAllPoints()
    card._hdrFrame._icon:SetSize(math.max(HEADER_HEIGHT - 12, 9), math.max(HEADER_HEIGHT - 12, 9))
    card._hdrFrame._icon:SetPoint("CENTER", card._hdrFrame._iconPlate, "CENTER", 0, 0)
    local hasHeaderIcon = ApplyIconToTexture(card._hdrFrame._icon, iconInfo, { 0.14, 0.86, 0.14, 0.86 })
    card._hdrFrame._iconPlate:SetShown(hasHeaderIcon and (showIcons or showSectionHeaders))

    card._hdrFrame._label:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
    card._hdrFrame._label:ClearAllPoints()
    if hasHeaderIcon then
        card._hdrFrame._label:SetPoint("LEFT", card._hdrFrame._iconPlate, "RIGHT", 6, 0)
    else
        card._hdrFrame._label:SetPoint("LEFT", card._hdrFrame, "LEFT", 9, 0)
    end
    card._hdrFrame._label:SetJustifyH("LEFT")
    if card._hdrFrame._label.SetWordWrap then
        card._hdrFrame._label:SetWordWrap(false)
    end
    card._hdrFrame._label:SetText((allDone and not explicitColor) and WC("00ff96", mod.label) or WC(headerColor:gsub("#", ""), mod.label))

    card._hdrFrame._count:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    card._hdrFrame._count:ClearAllPoints()
    local currencyBrowserButton = card._hdrFrame._currencyBrowserButton
    local showCurrencyBrowserButton = mod.key == "currencies" and MR.ToggleCurrencyBrowserFrame
    if showCurrencyBrowserButton then
        currencyBrowserButton:ClearAllPoints()
        currencyBrowserButton:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -20, 0)
        currencyBrowserButton:SetBackdropColor(0.04, 0.10, 0.13, transparent and 0 or (0.96 * frameAlpha))
        currencyBrowserButton:SetBackdropBorderColor(0.18, 0.58, 0.48, transparent and 0 or frameAlpha)
        card._hdrFrame._currencyBrowserText:SetTextColor(0.35, 0.95, 0.78, transparent and 0.75 or 1)
        currencyBrowserButton:Show()
        card._hdrFrame._count:SetPoint("RIGHT", currencyBrowserButton, "LEFT", -6, 0)
    else
        currencyBrowserButton:Hide()
        card._hdrFrame._count:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -18, 0)
    end
    card._hdrFrame._count:SetText(string.format(L["%d / %d complete"], secDone, secTotal))
    card._hdrFrame._count:SetTextColor(countColor(secDone, secTotal))
    card._hdrFrame._count:SetJustifyH("RIGHT")
    card._hdrFrame._label:SetPoint("RIGHT", card._hdrFrame._count, "LEFT", -8, 0)

    card._hdrFrame._arrow:SetSize(10, 10)
    card._hdrFrame._arrow:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -6, 0)
    if isOpen then
        card._hdrFrame._arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    else
        card._hdrFrame._arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    end
    card._hdrFrame._arrow:SetVertexColor(0.45, 0.45, 0.45)

    local localY = HEADER_HEIGHT
    card._divider:ClearAllPoints()
    card._divider:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -localY)
    card._divider:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, -localY)
    card._divider:SetHeight(1)
    card._divider:SetBackdropColor(1, 1, 1, dividerAlpha)

    local usedRows = {}
    if isOpen then
        localY = localY + 1
        local hideComplete = stats and stats.hideComplete
        for _, row in ipairs(mod.rows) do
            local rowVisible = not row.isVisible or row.isVisible()
            if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
                local done = MR:GetProgress(mod.key, row.key)
                local rowComplete = self:IsRowComplete(mod, row, done)
                if row.control or not (hideComplete and rowComplete) then
                    local rowFrame, nextY, rowId = UpdateMainRowWidget(self, card, mod, row, done, localY, card:GetWidth())
                    localY = nextY
                    usedRows[rowId] = true
                end
            end
        end
    end

    for key, rowFrame in pairs(card._rows or {}) do
        if not usedRows[key] then
            HideMainRowWidget(rowFrame)
        end
    end

    if recordRegistry ~= false then
        table.insert(self.sectionRegistry, {
            frame = card,
            modKey = mod.key,
            col = col or 1,
            yOff = yOff,
            bottom = yOff + (stats and stats.height or 0),
        })
    end
    return card
end

local function ClearArrayContents(t)
    if not t then
        return
    end

    for i = #t, 1, -1 do
        t[i] = nil
    end
end

function MR:RefreshMainPanelSectionsOnly()
    if not (self and self.frame and self.content and self.frame:IsShown()) then
        return false
    end

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self._refreshUIDirty = true
        return false
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("refreshUI") then
        self._refreshUIDirty = true
        return false
    end

    RecalcLayout()
    self._moduleStatsCache = BuildModuleStatsCache(self)

    self.widgets = self.widgets or {}
    self.sectionRegistry = self.sectionRegistry or {}
    self._timerRows = self._timerRows or {}
    ClearArrayContents(self.widgets)
    ClearArrayContents(self.sectionRegistry)
    ClearArrayContents(self._timerRows)

    local allDone, allTotal = 0, 0
    local frameW = MR.db.profile.width or 260
    local usableW = frameW - 9
    local MIN_COL = 200
    local numCols = math.max(1, math.floor(usableW / MIN_COL))
    local colW = math.floor(usableW / numCols)

    local visibleMods = self._visibleModsBuffer or {}
    self._visibleModsBuffer = visibleMods
    local visibleModCount = 0
    for _, mod in ipairs(MR:GetOrderedModules()) do
        local modVisible = not mod.isVisible or mod:isVisible()
        if MR:IsModuleEnabled(mod.key) and modVisible and not MR:IsModuleDetached(mod.key) then
            local stats = GetModuleStats(self, mod)
            local doneRows = stats and stats.doneRows or 0
            local shownRows = stats and stats.shownRows or 0
            if shownRows > 0 then
                visibleModCount = visibleModCount + 1
                local slot = visibleModCount
                local entry = visibleMods[slot] or {}
                entry.mod = mod
                entry.h = stats and stats.height or 0
                visibleMods[slot] = entry
                allTotal = allTotal + shownRows
                allDone = allDone + math.min(doneRows, shownRows)
            end
        end
    end

    local cols = self._colsBuffer or {}
    self._colsBuffer = cols
    for i = 1, numCols do
        cols[i] = 0
    end
    for i = numCols + 1, #cols do
        cols[i] = nil
    end

    local totalModH = 0
    for i = 1, visibleModCount do
        totalModH = totalModH + visibleMods[i].h
    end

    local modColAssign = self._modColAssignBuffer or {}
    self._modColAssignBuffer = modColAssign
    local modColAssignCount = 0
    local curCol = 1
    for i = 1, visibleModCount do
        local entry = visibleMods[i]
        if curCol < numCols and cols[curCol] >= totalModH / numCols then
            curCol = curCol + 1
        end
        modColAssignCount = modColAssignCount + 1
        local slot = modColAssignCount
        local assign = modColAssign[slot] or {}
        assign.mod = entry.mod
        assign.col = curCol
        assign.yOff = cols[curCol]
        modColAssign[slot] = assign
        cols[curCol] = cols[curCol] + entry.h
    end

    local activeMainSections = self._activeMainSectionsBuffer or {}
    self._activeMainSectionsBuffer = activeMainSections
    for key in pairs(activeMainSections) do
        activeMainSections[key] = nil
    end

    for i = 1, modColAssignCount do
        local assign = modColAssign[i]
        local xOff = (assign.col - 1) * colW
            local section = UpdateMainSectionWidget(self, assign.mod, assign.yOff, xOff, colW, assign.col, true)
            if section then
                activeMainSections[assign.mod.key] = true
                self.widgets[#self.widgets + 1] = section
            end
        end

    if self._mainSectionFrames then
        for key, section in pairs(self._mainSectionFrames) do
            if not activeMainSections[key] then
                HideMainSectionWidget(section)
            end
        end
    end

    for c = 2, numCols do
        local sep = EnsureMainSeparator(self, c - 1)
        sep:SetWidth(1)
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT", self.content, "TOPLEFT", (c - 1) * colW, 0)
        sep:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", (c - 1) * colW, 0)
        self.widgets[#self.widgets + 1] = sep
    end
    if self._mainColumnSeparators then
        for index, sep in pairs(self._mainColumnSeparators) do
            if index > (numCols - 1) then
                sep:Hide()
            end
        end
    end

    if self.titleCount then
        self.titleCount:SetText(string.format("%d / %d", allDone, allTotal))
        self.titleCount:SetTextColor(countColor(allDone, allTotal))
    end

    local totalH = 0
    for c = 1, numCols do
        if cols[c] > totalH then
            totalH = cols[c]
        end
    end

    self.content:SetWidth(usableW)
    self.content:SetHeight(math.max(totalH, 1))

    if self.scroll then
        local maxScroll = math.max(math.max(totalH, 1) - self.scroll:GetHeight(), 0)
        local cur = self.scroll:GetVerticalScroll()
        if cur > maxScroll then
            self.scroll:SetVerticalScroll(maxScroll)
        end
    end

    if self.UpdateScrollBar then
        self.UpdateScrollBar()
    end

    return true
end

function MR:FastToggleMainSection(modKey)
    if not (self and self.frame and self.content and self.frame:IsShown()) then
        return false
    end

    if self._refreshUIInProgress or self._refreshUIPending or self._refreshUITimer or self._refreshRequestPending or self._refreshRequestTimer then
        return false
    end

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self._refreshUIDirty = true
        return false
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("refreshUI") then
        self._refreshUIDirty = true
        return false
    end

    if self:IsModuleDetached(modKey) then
        return false
    end

    local mod = self.moduleByKey and self.moduleByKey[modKey]
    local section = self._mainSectionFrames and self._mainSectionFrames[modKey]
    local stats = self._moduleStatsCache and self._moduleStatsCache[modKey]
    if not (mod and section and stats and stats.shownRows and stats.shownRows > 0) then
        return false
    end

    local registryEntry
    for _, info in ipairs(self.sectionRegistry or {}) do
        if info.modKey == modKey then
            registryEntry = info
            break
        end
    end
    if not registryEntry then
        return false
    end

    RecalcLayout()
    local newOpen = not MR:IsModuleOpen(modKey)
    MR:SetModuleOpen(modKey, newOpen)
    stats.isOpen = newOpen
    stats.height = stats.shownRows == 0 and 0 or (HEADER_HEIGHT + 1 + SECTION_GAP + (newOpen and (stats.shownRows * ROW_HEIGHT) or 0))

    local frameW = MR.db.profile.width or 260
    local usableW = frameW - 9
    local MIN_COL = 200
    local numCols = math.max(1, math.floor(usableW / MIN_COL))
    if numCols ~= 1 then
        return false
    end
    local colW = math.floor(usableW / numCols)
    local xOff = ((registryEntry.col or 1) - 1) * colW

    UpdateMainSectionWidget(self, mod, registryEntry.yOff or 0, xOff, colW, registryEntry.col or 1, false)

    local colOffsets = self._fastToggleColOffsets or {}
    self._fastToggleColOffsets = colOffsets
    for i = 1, numCols do
        colOffsets[i] = 0
    end
    for i = numCols + 1, #colOffsets do
        colOffsets[i] = nil
    end

    local totalH = 0
    for _, info in ipairs(self.sectionRegistry or {}) do
        local curSection = self._mainSectionFrames and self._mainSectionFrames[info.modKey]
        local curStats = self._moduleStatsCache and self._moduleStatsCache[info.modKey]
        if curSection and curSection:IsShown() and curStats and curStats.shownRows > 0 then
            local col = math.max(1, math.min(info.col or 1, numCols))
            local yOff = colOffsets[col] or 0
            local x = (col - 1) * colW
            curSection:ClearAllPoints()
            curSection:SetPoint("TOPLEFT", self.content, "TOPLEFT", x + 3, -yOff)
            curSection:SetSize(math.max(colW - 6, 1), math.max((curStats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1))
            info.col = col
            info.yOff = yOff
            info.bottom = yOff + (curStats.height or 0)
            colOffsets[col] = yOff + (curStats.height or 0)
            if colOffsets[col] > totalH then
                totalH = colOffsets[col]
            end
        end
    end

    for c = 2, numCols do
        local sep = EnsureMainSeparator(self, c - 1)
        sep:SetWidth(1)
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT", self.content, "TOPLEFT", (c - 1) * colW, 0)
        sep:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", (c - 1) * colW, 0)
    end
    if self._mainColumnSeparators then
        for index, sep in pairs(self._mainColumnSeparators) do
            sep:SetShown(index <= (numCols - 1))
        end
    end

    self.content:SetWidth(usableW)
    self.content:SetHeight(math.max(totalH, 1))
    if self.scroll then
        local maxScroll = math.max(math.max(totalH, 1) - self.scroll:GetHeight(), 0)
        local cur = self.scroll:GetVerticalScroll()
        if cur > maxScroll then
            self.scroll:SetVerticalScroll(maxScroll)
        end
    end
    if self.UpdateScrollBar then
        self.UpdateScrollBar()
    end

    return true
end

IsMainTextOnlyMode = function()
    if not (MR and MR.db and MR.db.profile) then
        return false
    end

    if MR.db.profile.transparentMode then
        return true
    end

    return (MR.db.profile.frameAlpha or 1.0) <= 0.01
end

GetTextOnlyHeaderAlpha = function()
    if not (MR and MR.db and MR.db.profile) then
        return 0
    end

    if not IsMainTextOnlyMode() then
        return 0
    end

    if MR.db.profile.keepHeadersVisibleInTextMode == false then
        return 0
    end

    return 0.32
end

ShouldShowIcons = function()
    if not (MR and MR.db and MR.db.profile) then
        return false
    end

    return MR.db.profile.keepIconsVisibleInTextMode ~= false
end

ShouldShowSectionHeaders = function()
    if not (MR and MR.db and MR.db.profile) then
        return false
    end

    return MR.db.profile.keepHeadersVisibleInTextMode ~= false
end

local MODULE_ICON_FALLBACKS = {
    currencies          = { texture = "Interface\\Icons\\INV_Misc_Coin_17" },
    midnight_activities = { texture = "Interface\\Icons\\Ability_Creature_Cursed_04" },
    pvp_currencies      = { texture = "Interface\\TargetingFrame\\UI-PVP-FFA" },
    pvp_weeklies        = { texture = "Interface\\TargetingFrame\\UI-PVP-HORDE" },
    lfr_s1              = { texture = "Interface\\LFGFrame\\LFGICON-RAIDFINDER" },
    s1_weekly           = { texture = "Interface\\Icons\\INV_Misc_Note_01" },
    world_bosses        = { texture = "Interface\\Icons\\Ability_Hunter_BeastCall" },
    timewalking         = { texture = "Interface\\Icons\\Achievement_Quests_Completed_08" },
    prof_alchemy        = { texture = "Interface\\Icons\\Trade_Alchemy" },
    prof_blacksmithing  = { texture = "Interface\\Icons\\Trade_BlackSmithing" },
    prof_enchanting     = { texture = "Interface\\Icons\\Trade_Engraving" },
    prof_engineering    = { texture = "Interface\\Icons\\Trade_Engineering" },
    prof_herbalism      = { texture = "Interface\\Icons\\Trade_Herbalism" },
    prof_inscription    = { texture = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
    prof_jewelcrafting  = { texture = "Interface\\Icons\\INV_Misc_Gem_01" },
    prof_leatherworking = { texture = "Interface\\Icons\\INV_Misc_ArmorKit_17" },
    prof_mining         = { texture = "Interface\\Icons\\Trade_Mining" },
    prof_skinning       = { texture = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
    prof_tailoring      = { texture = "Interface\\Icons\\Trade_Tailoring" },
    skin_lures          = { texture = "Interface\\Icons\\INV_Misc_Food_50" },
}

local MODULE_HEADER_ICON_KEYS = {
    currencies = true,
    delves = true,
    great_vault = true,
    midnight_activities = true,
    prey = true,
    pvp_currencies = true,
    pvp_weeklies = true,
    lfr_s1 = true,
    s1_weekly = true,
    timewalking = true,
    world_bosses = true,
    prof_alchemy = true,
    prof_blacksmithing = true,
    prof_enchanting = true,
    prof_engineering = true,
    prof_herbalism = true,
    prof_inscription = true,
    prof_jewelcrafting = true,
    prof_leatherworking = true,
    prof_mining = true,
    prof_skinning = true,
    prof_tailoring = true,
    skin_lures = true,
}

ShouldShowModuleHeaderIcon = function(modKey)
    if type(modKey) == "string" and modKey:match("^story_campaign_") then
        return true
    end

    return MODULE_HEADER_ICON_KEYS[modKey] == true
end

GetModuleFallbackIconInfo = function(modKey)
    if not modKey or modKey == "" then
        return nil
    end

    local exact = MODULE_ICON_FALLBACKS[modKey]
    if exact then
        return exact
    end

    if modKey:match("^story_campaign_") then
        return { texture = "Interface\\GossipFrame\\AvailableQuestIcon" }
    end

    return nil
end

local ROW_ICON_FALLBACKS = {
    vault_raid          = { texture = "Interface\\LFGFrame\\LFGICON-RAIDFINDER" },
    vault_dungeon       = { texture = "Interface\\LFGFrame\\LFGICON-HEROICDUNGEON" },
    vault_world         = { texture = "Interface\\Icons\\INV_Misc_Map_01" },
    sparks_of_war       = { texture = "Interface\\TargetingFrame\\UI-PVP-FFA" },
    preparing_battle    = { texture = "Interface\\Icons\\Ability_Warrior_BattleShout" },
    something_different = { texture = "Interface\\Icons\\Achievement_BG_winBrawl" },
    early_training      = { texture = "Interface\\Icons\\INV_Sword_04" },
    call_to_delves      = { texture = "Interface\\Icons\\INV_Misc_Spyglass_03" },
    abundance           = { texture = "Interface\\Icons\\INV_Enchant_VoidSphere" },
    lost_legends        = { texture = "Interface\\Icons\\Achievement_Quests_Completed_08" },
    saltherils_soiree   = { texture = "Interface\\Icons\\INV_Drink_11" },
    fortify_runestones  = { texture = "Interface\\Icons\\INV_Stone_15" },
    unity_against_void  = { texture = "Interface\\Icons\\Spell_Shadow_ArcaneTorrent" },
    special_assignment  = { texture = "Interface\\Icons\\INV_Letter_15" },
    tw_dungeon          = { texture = "Interface\\LFGFrame\\LFGICON-HEROICDUNGEON" },
    tw_raid             = { texture = "Interface\\LFGFrame\\LFGICON-RAIDFINDER" },
}

NormalizeIconInfo = function(info)
    if not info then
        return nil
    end

    if type(info) == "number" then
        return { texture = info }
    end

    if type(info) == "string" then
        return { texture = info }
    end

    if type(info) == "table" then
        return {
            atlas = info.atlas,
            texture = info.texture or info.tex or info.fileID,
            texCoord = info.texCoord,
            tint = info.tint,
        }
    end

    return nil
end

GetRowIconInfo = function(mod, row)
    if not row then
        return nil
    end

    local explicit = NormalizeIconInfo(row.icon)
    if explicit then
        return explicit
    end

    if row.currencyId and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(row.currencyId)
        if info and info.iconFileID then
            return { texture = info.iconFileID }
        end
    end

    if row.itemId and C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(row.itemId)
        if icon then
            return { texture = icon }
        end
    end

    if row.spellId then
        local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(row.spellId) or GetSpellTexture(row.spellId)
        if icon then
            return { texture = icon }
        end
    end

    local fallback = ROW_ICON_FALLBACKS[row.key]
    if fallback then
        return fallback
    end

    return GetModuleFallbackIconInfo(mod and mod.key or "")
end

GetModuleIconInfo = function(mod)
    if not mod then
        return nil
    end

    if mod.key == "great_vault" then
        local keyIcon = GetRowIconInfo(nil, { currencyId = 3028 })
        if keyIcon then
            return keyIcon
        end
    end

    local explicit = NormalizeIconInfo(mod.icon)
    if explicit then
        return explicit
    end

    if mod.rows then
        for _, row in ipairs(mod.rows) do
            local rowIcon = GetRowIconInfo(mod, row)
            if rowIcon then
                return rowIcon
            end
        end
    end

    return GetModuleFallbackIconInfo(mod.key)
end

ApplyIconToTexture = function(texture, info, fallbackTexCoord)
    if not texture then
        return false
    end

    info = NormalizeIconInfo(info)
    if not info then
        texture:Hide()
        return false
    end

    texture:Show()
    if info.atlas and texture.SetAtlas then
        texture:SetAtlas(info.atlas, true)
        texture:SetTexCoord(0, 1, 0, 1)
    else
        texture:SetTexture(info.texture)
        if info.texCoord then
            texture:SetTexCoord(unpack(info.texCoord))
        elseif fallbackTexCoord then
            texture:SetTexCoord(unpack(fallbackTexCoord))
        else
            texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    end

    if info.tint then
        texture:SetVertexColor(info.tint[1] or 1, info.tint[2] or 1, info.tint[3] or 1, info.tint[4] or 1)
    else
        texture:SetVertexColor(1, 1, 1, 1)
    end

    return true
end

local function CurrencyInfoHasAnyFlag(info, ...)
    if type(info) ~= "table" then
        return false
    end

    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if info[key] then
            return true
        end
    end

    return false
end

local function IsCurrencyWarbandTransferable(currencyID, info)
    if CurrencyInfoHasAnyFlag(
        info,
        "isAccountTransferable",
        "isWarbandTransferable",
        "isTransferable",
        "transferable"
    ) then
        return true
    end

    if C_CurrencyInfo then
        local candidates = {
            "IsCurrencyAccountTransferable",
            "IsCurrencyTransferable",
            "IsAccountTransferableCurrency",
        }
        for _, methodName in ipairs(candidates) do
            local method = C_CurrencyInfo[methodName]
            if type(method) == "function" then
                local ok, result = pcall(method, currencyID)
                if ok and result then
                    return true
                end
            end
        end
    end

    return false
end

local function GetCurrencyWarbandKind(currencyID)
    if not (currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return nil
    end

    if info.isAccountWide then
        return "account", info
    end

    if IsCurrencyWarbandTransferable(currencyID, info) then
        return "transfer", info
    end

    return nil, info
end

function MR:GetCurrencyWarbandMarkerInfo(currencyID)
    local kind = GetCurrencyWarbandKind(currencyID)
    if kind == "account" then
        return {
            atlas = "warbands-icon",
            text = ACCOUNT_LEVEL_CURRENCY or "Warband Currency",
        }
    elseif kind == "transfer" then
        return {
            atlas = "warbands-transferable-icon",
            text = ACCOUNT_TRANSFERRABLE_CURRENCY or "Warband Transferable",
        }
    end

    return nil
end

function MR:AddCurrencyTransferTooltipLines(tooltip, currencyID)
    if not (tooltip and currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return false
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not IsCurrencyWarbandTransferable(currencyID, info) then
        return false
    end

    local percentage = tonumber(info and (info.transferPercentage or info.accountTransferPercentage or info.currencyTransferPercentage))
    tooltip:AddLine(" ")
    if percentage and percentage > 0 then
        tooltip:AddLine(string.format("Warband Transfer: %d%%", percentage), 0.45, 0.85, 1, true)
    else
        tooltip:AddLine("Warband Transferable", 0.45, 0.85, 1, true)
    end
    return true
end

local function WBHexColor(hexColor, fallbackR, fallbackG, fallbackB)
    if type(hexColor) == "string" and hexColor ~= "" then
        return hex(hexColor)
    end

    return fallbackR or 1, fallbackG or 1, fallbackB or 1
end

local function WBReleaseWidgets(bucket)
    if not bucket then
        return
    end

    for _, widget in ipairs(bucket or {}) do
        widget:Hide()
        widget:SetParent(nil)
    end
    wipe(bucket)
end

local function WBApplySurface(frame, variant, alpha)
    if not frame then
        return
    end

    if variant == "panel" then
        frame:SetBackdropColor(0.025, 0.045, 0.080, alpha or 0.98)
        frame:SetBackdropBorderColor(0.12, 0.22, 0.32, 0.95)
    elseif variant == "raised" then
        frame:SetBackdropColor(0.040, 0.075, 0.125, alpha or 0.98)
        frame:SetBackdropBorderColor(0.16, 0.30, 0.40, 0.95)
    elseif variant == "soft" then
        frame:SetBackdropColor(0.030, 0.055, 0.095, alpha or 0.94)
        frame:SetBackdropBorderColor(0.08, 0.16, 0.24, 0.80)
    else
        frame:SetBackdropColor(0.018, 0.030, 0.055, alpha or 0.98)
        frame:SetBackdropBorderColor(0.10, 0.18, 0.26, 0.90)
    end
end

local function WBStylePillButton(btn, active)
    if not btn then
        return
    end

    btn:SetBackdropColor(active and 0.07 or 0.035, active and 0.17 or 0.075, active and 0.23 or 0.12, active and 0.98 or 0.92)
    btn:SetBackdropBorderColor(active and 0.24 or 0.13, active and 0.82 or 0.32, active and 0.70 or 0.38, active and 1 or 0.88)
    if btn._label then
        btn._label:SetTextColor(active and 0.92 or 0.68, active and 1.00 or 0.84, active and 0.96 or 0.84)
    end
end

local function WBAddSoftSheen(frame, r, g, b, alpha)
    if not frame then
        return nil
    end

    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    tex:SetPoint("RIGHT", frame, "RIGHT", -1, 0)
    tex:SetHeight(28)
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    tex:SetColorTexture(r or 0.10, g or 0.20, b or 0.30, alpha or 0.12)
    return tex
end

function MR:RequestWarbandBoardRefresh(immediate)
    if not (self and self.altBoardFrame and self.altBoardFrame:IsShown() and self.RefreshWarbandBoard) then
        return
    end

    if immediate then
        self._warbandBoardRefreshQueued = nil
        self:RefreshWarbandBoard()
        return
    end

    local now = GetTime and GetTime() or 0
    local lastRefreshAt = self._warbandBoardLastRefreshAt or 0
    local minInterval = 0.75

    if (now - lastRefreshAt) >= minInterval then
        self:RefreshWarbandBoard()
        return
    end

    if self._warbandBoardRefreshQueued then
        return
    end

    self._warbandBoardRefreshQueued = true
    C_Timer.After(minInterval, function()
        if not MR then
            return
        end
        MR._warbandBoardRefreshQueued = nil
        if MR.altBoardFrame and MR.altBoardFrame:IsShown() and MR.RefreshWarbandBoard then
            MR:RefreshWarbandBoard()
        end
    end)
end

local function WBFormatTimestamp(ts)
    if not ts or ts <= 0 then
        return L["AltBoard_NoScanRecorded"] or "No scan recorded"
    end

    return date("%b %d, %H:%M", ts)
end

local function WBStatusText(entry)
    if not entry then
        return L["AltBoard_NoCharacters"] or "No characters found"
    end
    if entry.stale then
        return L["AltBoard_NeedsLogin"] or "Needs login after reset"
    end
    if entry.doneRows >= entry.totalRows and entry.totalRows > 0 then
        return L["AltBoard_EverythingDone"] or "Everything done"
    end
    if entry.doneRows == 0 and entry.activeRows == 0 then
        return L["AltBoard_FreshWeek"] or "Fresh week"
    end

    if entry.activeRows > 0 then
        return string.format(L["AltBoard_StatusCompleteProgress"] or "%d complete, %d in progress", entry.doneRows, entry.activeRows)
    end

    return string.format(L["AltBoard_StatusCompleteOnly"] or "%d complete", entry.doneRows)
end

local function WBStatusColor(entry)
    if not entry then
        return 0.6, 0.6, 0.6
    end
    if entry.stale then
        return 0.95, 0.50, 0.25
    end
    if entry.doneRows >= entry.totalRows and entry.totalRows > 0 then
        return 0.20, 0.95, 0.60
    end
    if entry.activeRows > 0 then
        return 1.00, 0.76, 0.28
    end

    return 0.55, 0.72, 0.95
end

local function WBClassColor(entry)
    local classFile = entry and entry.classFile
    local classColor = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if classColor then
        return classColor.r, classColor.g, classColor.b
    end

    return WBStatusColor(entry)
end

local function WBConcentrationColor(entry)
    if not entry then
        return 0.55, 0.72, 0.95
    end

    local current = tonumber(entry.estimatedQuantity) or tonumber(entry.quantity) or 0
    local maxQuantity = tonumber(entry.maxQuantity) or 0
    if maxQuantity > 0 and current >= maxQuantity then
        return 0.20, 0.95, 0.60
    end
    if current <= 0 then
        return 0.95, 0.35, 0.35
    end

    return 1.00, 0.76, 0.28
end

local function GetExpansionDisplayInfo(forAltBoard)
    local key = MR:GetSelectedExpansionKey(forAltBoard)
    return MR:GetExpansionInfo(key)
end

local function GetExpansionDisplayLabel(forAltBoard)
    local info = GetExpansionDisplayInfo(forAltBoard)
    return info and (info.shortLabel or info.label or info.key) or "Midnight"
end

local function CycleExpansion(forAltBoard, direction)
    local expansions = MR:GetSelectableExpansions()
    if #expansions <= 1 then
        return
    end

    local currentKey = MR:GetSelectedExpansionKey(forAltBoard)
    local currentIndex = 1
    for idx, info in ipairs(expansions) do
        if info.key == currentKey then
            currentIndex = idx
            break
        end
    end

    local nextIndex = currentIndex + (direction or 1)
    if nextIndex < 1 then
        nextIndex = #expansions
    elseif nextIndex > #expansions then
        nextIndex = 1
    end

    MR:SetSelectedExpansionKey(expansions[nextIndex].key, forAltBoard)
end

local function BuildExpansionDropdown(parent, forAltBoard, opts)
    opts = opts or {}

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(opts.width or 150, opts.height or 18)
    btn.forAltBoard = forAltBoard
    btn:SetBackdrop(MakeBackdrop())
    btn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
    btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_ROWS, opts.fontSize or 8, GetFontFlags())
    label:SetPoint("LEFT", btn, "LEFT", 8, 1)
    label:SetPoint("RIGHT", btn, "RIGHT", -20, 1)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.76, 0.97, 0.94)
    btn._label = label

    local caret = btn:CreateFontString(nil, "OVERLAY")
    caret:SetFont(FONT_HEADERS, 10, GetFontFlags())
    caret:SetPoint("RIGHT", btn, "RIGHT", -7, 1)
    caret:SetText("v")
    caret:SetTextColor(0.78, 0.90, 0.92)
    btn._caret = caret

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(50)
    popup:SetBackdrop(MakeBackdrop())
    popup:SetBackdropColor(0.04, 0.09, 0.15, 0.98)
    popup:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
    popup:Hide()
    popup.buttons = {}
    btn._popup = popup

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
    btn._dismiss = dismiss

    function btn:ApplyFonts()
        local fontSize = GetFontSize()
        local labelSize = opts.fontSize or math.max(8, fontSize - 1)
        local caretSize = math.max(9, labelSize + 1)

        if self._label then
            self._label:SetFont(FONT_ROWS, labelSize, GetFontFlags())
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
        end
    end

    btn:SetScript("OnEnter", function(selfBtn)
        selfBtn:SetBackdropColor(0.08, 0.18, 0.28, 0.98)
        selfBtn:SetBackdropBorderColor(0.26, 0.78, 0.72, 1)
    end)
    btn:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
        selfBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
    end)

    function btn:Update()
        local expansions = MR:GetSelectableExpansions()
        self:ApplyFonts()
        if #expansions <= 1 then
            self:Hide()
            return
        end

        local current = MR:GetExpansionInfo(MR:GetSelectedExpansionKey(self.forAltBoard))
        self._label:SetText(current.shortLabel or current.label or current.key)
        self:Show()
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
        row._label:SetFont(FONT_ROWS, opts.fontSize or 8, GetFontFlags())
        row._label:SetPoint("LEFT", row, "LEFT", 8, 1)
        row._label:SetPoint("RIGHT", row, "RIGHT", -22, 1)
        row._label:SetJustifyH("LEFT")

        row._check = row:CreateFontString(nil, "OVERLAY")
        row._check:SetFont(FONT_HEADERS, 10, GetFontFlags())
        row._check:SetPoint("RIGHT", row, "RIGHT", -7, 1)

        row:SetScript("OnEnter", function(selfRow)
            selfRow:SetBackdropColor(0.08, 0.18, 0.28, 0.98)
            selfRow:SetBackdropBorderColor(0.26, 0.78, 0.72, 1)
        end)
        row:SetScript("OnLeave", function(selfRow)
            local active = selfRow._checked == true
            selfRow:SetBackdropColor(active and 0.10 or 0.05, active and 0.22 or 0.12, active and 0.30 or 0.20, active and 0.98 or 0.94)
            selfRow:SetBackdropBorderColor(active and 0.28 or 0.12, active and 0.86 or 0.26, active and 0.78 or 0.32, active and 1 or 0.95)
        end)

        popup.buttons[index] = row
        return row
    end

    btn:SetScript("OnClick", function(selfBtn)
        local expansions = MR:GetSelectableExpansions()
        if #expansions <= 1 then
            return
        end

        local selectedKey = MR:GetSelectedExpansionKey(selfBtn.forAltBoard)
        local rowWidth = math.max(selfBtn:GetWidth(), 130)
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", selfBtn, "BOTTOMLEFT", 0, -4)
        popup:SetSize(rowWidth, (#expansions * 20) + 6)

        for index, info in ipairs(expansions) do
            local row = EnsurePopupButton(index)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -3 - ((index - 1) * 20))
            row:SetSize(rowWidth - 6, 18)
            row._checked = info.key == selectedKey
            row._label:SetText(info.shortLabel or info.label or info.key)
            row._label:SetTextColor(row._checked and 0.96 or 0.74, row._checked and 1.00 or 0.90, row._checked and 1.00 or 0.92)
            row._check:SetText(row._checked and "x" or "")
            row._check:SetTextColor(0.80, 0.94, 0.92)
            row:SetBackdropColor(row._checked and 0.10 or 0.05, row._checked and 0.22 or 0.12, row._checked and 0.30 or 0.20, row._checked and 0.98 or 0.94)
            row:SetBackdropBorderColor(row._checked and 0.28 or 0.12, row._checked and 0.86 or 0.26, row._checked and 0.78 or 0.32, row._checked and 1 or 0.95)
            row:SetScript("OnClick", function()
                MR:SetSelectedExpansionKey(info.key, selfBtn.forAltBoard)
                popup:Hide()
                dismiss:Hide()
            end)
            row:Show()
        end

        for index = #expansions + 1, #popup.buttons do
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

local function WBConcentrationText(entry)
    if not entry then
        return "-"
    end

    local current = math.floor((tonumber(entry.estimatedQuantity) or tonumber(entry.quantity) or 0) + 0.0001)
    local maxQuantity = tonumber(entry.maxQuantity) or 0
    if maxQuantity > 0 then
        return string.format("%d / %d", current, maxQuantity)
    end

    return tostring(current)
end

local function WBConcentrationCurrent(entry)
    return math.max(0, math.floor((tonumber(entry and entry.estimatedQuantity) or tonumber(entry and entry.quantity) or 0) + 0.0001))
end

local function WBConcentrationDailyGain(entry)
    local cycleMS = tonumber(entry and entry.rechargingCycleDurationMS) or 0
    local amountPerCycle = tonumber(entry and entry.rechargingAmountPerCycle) or 0
    if cycleMS <= 0 or amountPerCycle <= 0 then
        return 0
    end

    return math.max(0, math.floor(((DAY_SECONDS * 1000) / cycleMS) * amountPerCycle + 0.0001))
end

local function WBConcentrationProjectedQuantity(entry, aheadSeconds)
    local current = WBConcentrationCurrent(entry)
    local maxQuantity = tonumber(entry and entry.maxQuantity) or 0
    local cycleMS = tonumber(entry and entry.rechargingCycleDurationMS) or 0
    local amountPerCycle = tonumber(entry and entry.rechargingAmountPerCycle) or 0
    local secondsAhead = tonumber(aheadSeconds) or 0

    if maxQuantity > 0 and current >= maxQuantity then
        return maxQuantity
    end
    if secondsAhead <= 0 or cycleMS <= 0 or amountPerCycle <= 0 then
        return maxQuantity > 0 and math.min(current, maxQuantity) or current
    end

    local cycles = math.floor((secondsAhead * 1000) / cycleMS)
    local projected = current + (cycles * amountPerCycle)
    if maxQuantity > 0 then
        projected = math.min(projected, maxQuantity)
    end

    return math.max(0, math.floor(projected + 0.0001))
end

local function WBConcentrationTimeToFull(entry)
    local current = WBConcentrationCurrent(entry)
    local maxQuantity = tonumber(entry and entry.maxQuantity) or 0
    local cycleMS = tonumber(entry and entry.rechargingCycleDurationMS) or 0
    local amountPerCycle = tonumber(entry and entry.rechargingAmountPerCycle) or 0

    if maxQuantity <= 0 or current >= maxQuantity then
        return 0, GetServerTime()
    end
    if cycleMS <= 0 or amountPerCycle <= 0 then
        return nil, nil
    end

    local remaining = math.max(0, maxQuantity - current)
    local cyclesNeeded = math.ceil(remaining / amountPerCycle)
    local seconds = math.max(0, math.floor((cyclesNeeded * cycleMS) / 1000 + 0.5))
    return seconds, (GetServerTime() or time()) + seconds
end

local function WBFormatDurationShort(seconds)
    if not seconds or seconds <= 0 then
        return "0h"
    end

    local days = math.floor(seconds / DAY_SECONDS)
    local hours = math.floor((seconds % DAY_SECONDS) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if days > 0 then
        return string.format("%dd %dh", days, hours)
    end
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    end
    return string.format("%dm", math.max(1, minutes))
end

local function WBFormatConcentrationFullAt(ts)
    if not ts or ts <= 0 then
        return "-"
    end

    return date("%d.%m %H:%M", ts)
end

local function WBConcentrationLabel()
    return rawget(L, "Concentration") or "Concentration"
end

local function WBGetConcentrationTrackerAlpha()
    local value = tonumber(GetWindowLayoutValue("concentrationTrackerAlpha")) or 1
    return math.max(0, math.min(1, value))
end

local function WBSetConcentrationTrackerAlpha(value)
    SetWindowLayoutValue("concentrationTrackerAlpha", math.max(0, math.min(1, tonumber(value) or 1)))
end

local function WBIsConcentrationTrackerCompact()
    return GetWindowLayoutValue("concentrationTrackerCompact") == true
end

local function WBSetConcentrationTrackerCompact(value)
    SetWindowLayoutValue("concentrationTrackerCompact", value and true or false)
end

local function WBGetConcentrationTrackerHiddenCharacters()
    local hidden = GetWindowLayoutValue("concentrationTrackerHiddenCharacters")
    if type(hidden) ~= "table" then
        hidden = {}
        SetWindowLayoutValue("concentrationTrackerHiddenCharacters", hidden)
    end
    return hidden
end

local function WBIsConcentrationTrackerCharacterHidden(charKey)
    return charKey and WBGetConcentrationTrackerHiddenCharacters()[charKey] == true
end

local function WBSetConcentrationTrackerCharacterHidden(charKey, hidden)
    if not charKey then
        return
    end

    local hiddenCharacters = WBGetConcentrationTrackerHiddenCharacters()
    hiddenCharacters[charKey] = hidden and true or nil
end

local function WBApplyConcentrationTrackerTheme(frame)
    if not frame then
        return
    end

    local value = WBGetConcentrationTrackerAlpha()
    frame:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4] * value)
    frame:SetBackdropBorderColor(0.15, 0.15, 0.20, value)
    if frame.titleBar then
        frame.titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98 * value)
        frame.titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, value)
    end
end

local function WBAltLoginPrompt()
    return L["AltBoard_LoginAltPrompt"] or "Log into an alt for it to show here."
end

local function WBGetAltBoardView()
    local view = MR and MR.db and MR.db.profile and MR.db.profile.altBoardView
    return view == "concentration" and "concentration" or "character"
end

local function WBSetAltBoardView(view)
    if MR and MR.db and MR.db.profile then
        MR.db.profile.altBoardView = (view == "concentration") and "concentration" or "character"
    end
end

local function WBShouldHideCompletedCharacters()
    return MR
        and MR.db
        and MR.db.profile
        and MR.db.profile.altBoardHideCompleted == true
end

local function WBCreateScrollArea(parent, topLeftAnchor, bottomRightAnchor)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint(topLeftAnchor[1], topLeftAnchor[2], topLeftAnchor[3], topLeftAnchor[4], topLeftAnchor[5])
    scroll:SetPoint(bottomRightAnchor[1], bottomRightAnchor[2], bottomRightAnchor[3], bottomRightAnchor[4], bottomRightAnchor[5])
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local track = CreateFrame("Frame", nil, parent)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 3, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 3, 0)
    track:SetWidth(5)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0.00, 0.00, 0.00, 0.30)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(5)
    thumb:EnableMouse(true)
    thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.24, 0.72, 0.72, 0.80)

    local function UpdateScrollBar()
        local viewH = scroll:GetHeight()
        local contentH = content:GetHeight()
        local maxScroll = math.max(contentH - viewH, 0)
        local currentScroll = scroll:GetVerticalScroll()

        if currentScroll > maxScroll then
            scroll:SetVerticalScroll(maxScroll)
            currentScroll = maxScroll
        elseif currentScroll < 0 then
            scroll:SetVerticalScroll(0)
            currentScroll = 0
        end

        if contentH <= viewH or viewH <= 0 then
            if currentScroll ~= 0 then
                scroll:SetVerticalScroll(0)
            end
            track:Hide()
            thumb:Hide()
            return
        end

        track:Show()
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 18)
        local pct = currentScroll / math.max(maxScroll, 1)
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
        thumb._dragging = true
        thumb._grabOffset = thumb:GetHeight() * 0.5
        thumb:SetScript("OnUpdate", function(self)
            if not IsMouseButtonDown("LeftButton") then
                self._dragging = nil
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
        self._dragging = true
        self:SetScript("OnUpdate", function(btn)
            if not IsMouseButtonDown("LeftButton") then
                btn._dragging = nil
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
        self._dragging = nil
        self._grabOffset = nil
        self:SetScript("OnUpdate", nil)
    end)

    scroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = scroll:GetVerticalScroll()
        local max = math.max(content:GetHeight() - scroll:GetHeight(), 0)
        scroll:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, max)))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", function() UpdateScrollBar() end)
    scroll:SetScript("OnVerticalScroll", function() UpdateScrollBar() end)

    return scroll, content, UpdateScrollBar, track
end

local function WBRefreshAltBoardTabs(frame)
    if not frame or not frame.altTabs then
        return
    end

    local activeView = WBGetAltBoardView()
    for viewKey, tab in pairs(frame.altTabs) do
        local active = viewKey == activeView
        WBStylePillButton(tab, active)
    end
end

local function WBPopulateConcentrationOverview(frame, data)
    if not frame or not frame.overviewContent then
        return 0, 0
    end

    frame.overviewWidgets = frame.overviewWidgets or {}
    WBReleaseWidgets(frame.overviewWidgets)

    local contentWidth = math.max((frame.overviewScroll and frame.overviewScroll:GetWidth() or frame.rightPane:GetWidth() or 520) - 8, 320)
    frame.overviewContent:SetWidth(contentWidth)

    local totalCharacters = 0
    local totalProfessions = 0
    local yOff = 0

    for _, charEntry in ipairs(data or {}) do
        local concentrationEntries = type(charEntry.concentration) == "table" and charEntry.concentration or nil
        if concentrationEntries and #concentrationEntries > 0 then
            totalCharacters = totalCharacters + 1
            totalProfessions = totalProfessions + #concentrationEntries

            local card = CreateFrame("Frame", nil, frame.overviewContent, "BackdropTemplate")
            card:SetPoint("TOPLEFT", frame.overviewContent, "TOPLEFT", 0, -yOff)
            card:SetWidth(contentWidth)
            card:SetBackdrop(MakeBackdrop())
            WBApplySurface(card, "soft", 0.96)

            local cr, cg, cb = WBClassColor(charEntry)
            WBAddSoftSheen(card, cr, cg, cb, 0.08)

            local topAccent = card:CreateTexture(nil, "ARTWORK")
            topAccent:SetPoint("TOPLEFT")
            topAccent:SetPoint("TOPRIGHT")
            topAccent:SetHeight(3)
            topAccent:SetColorTexture(cr, cg, cb, 1)

            local header = card:CreateFontString(nil, "OVERLAY")
            header:SetFont(FONT_HEADERS, math.max(11, GetFontSize() + 1), GetFontFlags())
            header:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
            header:SetText(charEntry.isCurrent and (charEntry.name .. "  |cff7ce7d8" .. (L["AltBoard_Current"] or "Current") .. "|r") or charEntry.name)
            header:SetTextColor(0.94, 0.98, 1.00)

            local meta = card:CreateFontString(nil, "OVERLAY")
            meta:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            meta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -10)
            meta:SetJustifyH("RIGHT")
            meta:SetText(charEntry.realm ~= "" and charEntry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"))
            meta:SetTextColor(0.64, 0.72, 0.82)

            local rowY = 32
            for _, concentrationEntry in ipairs(concentrationEntries) do
                local rr, rg, rb = WBConcentrationColor(concentrationEntry)
                local current = WBConcentrationCurrent(concentrationEntry)
                local maxQuantity = tonumber(concentrationEntry.maxQuantity) or 0
                local projected = WBConcentrationProjectedQuantity(concentrationEntry, DAY_SECONDS)
                local dailyGain = math.max(0, projected - current)
                local fullInSeconds, fullAt = WBConcentrationTimeToFull(concentrationEntry)

                local row = CreateFrame("Frame", nil, card)
                row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -rowY)
                row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -rowY)
                row:SetHeight(54)

                local label = row:CreateFontString(nil, "OVERLAY")
                label:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
                label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
                label:SetPoint("TOPRIGHT", row, "TOPRIGHT", -110, 0)
                label:SetJustifyH("LEFT")
                label:SetText(concentrationEntry.label or (L["Unknown"] or "Unknown"))
                label:SetTextColor(0.88, 0.92, 0.97)

                local value = row:CreateFontString(nil, "OVERLAY")
                value:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
                value:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
                value:SetJustifyH("RIGHT")
                value:SetText(maxQuantity > 0 and string.format("%d / %d", current, maxQuantity) or tostring(current))
                value:SetTextColor(rr, rg, rb)

                local barBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
                barBg:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -18)
                barBg:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -18)
                barBg:SetHeight(8)
                barBg:SetBackdrop(MakeBackdrop(false))
                barBg:SetBackdropColor(0.08, 0.12, 0.18, 1)

                local projectedFill = barBg:CreateTexture(nil, "ARTWORK")
                projectedFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
                projectedFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
                projectedFill:SetColorTexture(rr, rg, rb, 0.22)

                local currentFill = barBg:CreateTexture(nil, "OVERLAY")
                currentFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
                currentFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
                currentFill:SetColorTexture(rr, rg, rb, 0.88)

                local barWidth = math.max(contentWidth - 24, 1)
                local currentPct = maxQuantity > 0 and math.min(1, current / maxQuantity) or 0
                local projectedPct = maxQuantity > 0 and math.min(1, projected / maxQuantity) or currentPct
                currentFill:SetWidth(barWidth * currentPct)
                projectedFill:SetWidth(barWidth * projectedPct)

                local gainText = row:CreateFontString(nil, "OVERLAY")
                gainText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                gainText:SetPoint("TOPLEFT", barBg, "BOTTOMLEFT", 0, -4)
                gainText:SetJustifyH("LEFT")
                gainText:SetText(string.format(L["AltBoard_ConcentrationProjected24h"] or "24h +%d", dailyGain))
                gainText:SetTextColor(0.68, 0.77, 0.86)

                local fullInText = row:CreateFontString(nil, "OVERLAY")
                fullInText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                fullInText:SetPoint("TOPRIGHT", barBg, "BOTTOMRIGHT", 0, -4)
                fullInText:SetJustifyH("RIGHT")
                if fullInSeconds == nil then
                    fullInText:SetText(L["AltBoard_AwaitingRefresh"] or "Awaiting refresh")
                elseif fullInSeconds <= 0 then
                    fullInText:SetText(L["AltBoard_ConcentrationFull"] or "Fully replenished")
                else
                    fullInText:SetText(string.format(L["AltBoard_ConcentrationFullIn"] or "Full in %s", WBFormatDurationShort(fullInSeconds)))
                end
                fullInText:SetTextColor(0.68, 0.77, 0.86)

                local fullAtText = row:CreateFontString(nil, "OVERLAY")
                fullAtText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                fullAtText:SetPoint("TOPLEFT", gainText, "BOTTOMLEFT", 0, -3)
                fullAtText:SetPoint("TOPRIGHT", fullInText, "BOTTOMRIGHT", 0, -3)
                fullAtText:SetJustifyH("RIGHT")
                if fullInSeconds == nil then
                    fullAtText:SetText("")
                elseif fullInSeconds <= 0 then
                    fullAtText:SetText(L["AltBoard_ConcentrationFullNow"] or "Full now")
                else
                    fullAtText:SetText(string.format(L["AltBoard_ConcentrationFullAt"] or "Full on %s", WBFormatConcentrationFullAt(fullAt)))
                end
                fullAtText:SetTextColor(0.52, 0.62, 0.72)

                table.insert(frame.overviewWidgets, row)
                rowY = rowY + 62
            end

            card:SetHeight(rowY + 4)
            table.insert(frame.overviewWidgets, card)
            yOff = yOff + card:GetHeight() + 14
        end
    end

    if totalProfessions == 0 then
        local empty = frame.overviewEmptyLabel
        if empty then
            empty:SetPoint("TOPLEFT", frame.overviewContent, "TOPLEFT", 8, -6)
            empty:SetPoint("TOPRIGHT", frame.overviewContent, "TOPRIGHT", -8, -6)
            empty:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
            empty:Show()
        end
        frame.overviewContent:SetHeight(40)
    else
        if frame.overviewEmptyLabel then
            frame.overviewEmptyLabel:Hide()
        end
        frame.overviewContent:SetHeight(math.max(yOff, 1))
    end

    if frame.overviewScrollUpdate then
        frame.overviewScrollUpdate()
    end

    return totalCharacters, totalProfessions
end

local function WBPopulateConcentrationTracker(frame)
    if not frame or not frame.content then
        return
    end

    frame.widgets = frame.widgets or {}
    WBReleaseWidgets(frame.widgets)

    local data = MR:GetWarbandWeeklyData()
    local contentWidth = math.max((frame.scroll and frame.scroll:GetWidth() or frame:GetWidth() or 430) - 8, 300)
    local compact = WBIsConcentrationTrackerCompact()
    local totalCharacters = 0
    local totalProfessions = 0
    local hiddenCount = 0
    local yOff = 0

    frame.content:SetWidth(contentWidth)

    for _, charEntry in ipairs(data or {}) do
        local concentrationEntries = type(charEntry.concentration) == "table" and charEntry.concentration or nil
        if concentrationEntries and #concentrationEntries > 0 and WBIsConcentrationTrackerCharacterHidden(charEntry.key) then
            hiddenCount = hiddenCount + 1
        elseif concentrationEntries and #concentrationEntries > 0 then
            totalCharacters = totalCharacters + 1
            totalProfessions = totalProfessions + #concentrationEntries

            local card = CreateFrame("Frame", nil, frame.content, "BackdropTemplate")
            card:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOff)
            card:SetWidth(contentWidth)
            card:SetBackdrop(MakeBackdrop())
            WBApplySurface(card, "soft", 0.96 * WBGetConcentrationTrackerAlpha())
            card:SetBackdropBorderColor(0.08, 0.16, 0.24, 0.80 * WBGetConcentrationTrackerAlpha())

            local cr, cg, cb = WBClassColor(charEntry)
            local accent = card:CreateTexture(nil, "ARTWORK")
            accent:SetPoint("TOPLEFT")
            accent:SetPoint("BOTTOMLEFT")
            accent:SetWidth(3)
            accent:SetColorTexture(cr, cg, cb, 1)

            local name = card:CreateFontString(nil, "OVERLAY")
            name:SetFont(FONT_HEADERS, compact and math.max(9, GetFontSize()) or math.max(10, GetFontSize() + 1), GetFontFlags())
            name:SetPoint("TOPLEFT", card, "TOPLEFT", 12, compact and -7 or -10)
            name:SetPoint("TOPRIGHT", card, "TOPRIGHT", -110, -10)
            name:SetJustifyH("LEFT")
            name:SetText(charEntry.isCurrent and (charEntry.name .. "  |cff7ce7d8" .. (L["AltBoard_Current"] or "Current") .. "|r") or charEntry.name)
            name:SetTextColor(0.94, 0.98, 1.00)

            local realm = card:CreateFontString(nil, "OVERLAY")
            realm:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            realm:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -11)
            realm:SetJustifyH("RIGHT")
            realm:SetText(charEntry.realm ~= "" and charEntry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"))
            realm:SetTextColor(0.62, 0.70, 0.80)

            local rowY = compact and 26 or 34
            for _, concentrationEntry in ipairs(concentrationEntries) do
                local rr, rg, rb = WBConcentrationColor(concentrationEntry)
                local current = WBConcentrationCurrent(concentrationEntry)
                local maxQuantity = tonumber(concentrationEntry.maxQuantity) or 0
                local projected = WBConcentrationProjectedQuantity(concentrationEntry, DAY_SECONDS)
                local dailyGain = math.max(0, projected - current)
                local fullInSeconds = WBConcentrationTimeToFull(concentrationEntry)

                local row = CreateFrame("Frame", nil, card)
                row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -rowY)
                row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -rowY)
                row:SetHeight(compact and 24 or 42)

                local label = row:CreateFontString(nil, "OVERLAY")
                label:SetFont(FONT_ROWS, compact and math.max(8, GetFontSize() - 1) or math.max(9, GetFontSize()), GetFontFlags())
                label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
                label:SetPoint("TOPRIGHT", row, "TOPRIGHT", -105, 0)
                label:SetJustifyH("LEFT")
                label:SetText(concentrationEntry.label or (L["Unknown"] or "Unknown"))
                label:SetTextColor(0.86, 0.91, 0.97)

                local value = row:CreateFontString(nil, "OVERLAY")
                value:SetFont(FONT_HEADERS, compact and math.max(8, GetFontSize() - 1) or math.max(9, GetFontSize()), GetFontFlags())
                value:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
                value:SetJustifyH("RIGHT")
                value:SetText(maxQuantity > 0 and string.format("%d / %d", current, maxQuantity) or tostring(current))
                value:SetTextColor(rr, rg, rb)

                local barBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
                barBg:SetPoint("TOPLEFT", row, "TOPLEFT", 0, compact and -15 or -18)
                barBg:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, compact and -15 or -18)
                barBg:SetHeight(compact and 4 or 7)
                barBg:SetBackdrop(MakeBackdrop(false))
                barBg:SetBackdropColor(0.08, 0.12, 0.18, 1)

                local projectedFill = barBg:CreateTexture(nil, "ARTWORK")
                projectedFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
                projectedFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
                projectedFill:SetColorTexture(rr, rg, rb, 0.22)

                local currentFill = barBg:CreateTexture(nil, "OVERLAY")
                currentFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
                currentFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
                currentFill:SetColorTexture(rr, rg, rb, 0.88)

                local barWidth = math.max(contentWidth - 24, 1)
                local currentPct = maxQuantity > 0 and math.min(1, current / maxQuantity) or 0
                local projectedPct = maxQuantity > 0 and math.min(1, projected / maxQuantity) or currentPct
                currentFill:SetWidth(barWidth * currentPct)
                projectedFill:SetWidth(barWidth * projectedPct)

                if not compact then
                    local gainText = row:CreateFontString(nil, "OVERLAY")
                    gainText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                    gainText:SetPoint("TOPLEFT", barBg, "BOTTOMLEFT", 0, -4)
                    gainText:SetJustifyH("LEFT")
                    gainText:SetText(string.format(L["AltBoard_ConcentrationProjected24h"] or "24h +%d", dailyGain))
                    gainText:SetTextColor(0.64, 0.74, 0.84)

                    local fullText = row:CreateFontString(nil, "OVERLAY")
                    fullText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                    fullText:SetPoint("TOPRIGHT", barBg, "BOTTOMRIGHT", 0, -4)
                    fullText:SetJustifyH("RIGHT")
                    if fullInSeconds == nil then
                        fullText:SetText(L["AltBoard_AwaitingRefresh"] or "Awaiting refresh")
                    elseif fullInSeconds <= 0 then
                        fullText:SetText(L["AltBoard_ConcentrationFull"] or "Fully replenished")
                    else
                        fullText:SetText(string.format(L["AltBoard_ConcentrationFullIn"] or "Full in %s", WBFormatDurationShort(fullInSeconds)))
                    end
                    fullText:SetTextColor(0.64, 0.74, 0.84)
                end

                table.insert(frame.widgets, row)
                rowY = rowY + (compact and 30 or 48)
            end

            card:SetHeight(rowY + (compact and 2 or 4))
            table.insert(frame.widgets, card)
            yOff = yOff + card:GetHeight() + (compact and 6 or 10)
        end
    end

    if frame.summary then
        if totalProfessions > 0 then
            local summaryText = string.format(L["AltBoard_ConcentrationOverviewSub"] or "%d professions across %d characters", totalProfessions, totalCharacters)
            if hiddenCount > 0 then
                summaryText = summaryText .. string.format("  |  " .. (L["AltBoard_ConcentrationHiddenCount"] or "%d hidden"), hiddenCount)
            end
            frame.summary:SetText(summaryText)
        elseif hiddenCount > 0 then
            frame.summary:SetText(string.format(L["AltBoard_ConcentrationHiddenCount"] or "%d hidden", hiddenCount))
        else
            frame.summary:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
        end
    end

    if totalProfessions == 0 then
        if frame.emptyLabel then
            frame.emptyLabel:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 8, -6)
            frame.emptyLabel:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -8, -6)
            frame.emptyLabel:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
            frame.emptyLabel:Show()
        end
        frame.content:SetHeight(42)
    else
        if frame.emptyLabel then
            frame.emptyLabel:Hide()
        end
        frame.content:SetHeight(math.max(yOff, 1))
    end

    if frame.scrollUpdate then
        frame.scrollUpdate()
    end
end

function MR:RefreshConcentrationTracker()
    if self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() then
        WBPopulateConcentrationTracker(self.concentrationTrackerFrame)
    end
end

local function WBCreateHeaderButton(parent, icon, normalColor, hoverBg, hoverBorder, tooltipText, onClick)
    local size = icon.size or 18
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(size, size)
    btn:SetBackdrop(MakeBackdrop())
    btn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
    btn:SetBackdropBorderColor(0.18, 0.23, 0.30, 0.95)

    local iconObj
    if icon.tex then
        iconObj = btn:CreateTexture(nil, "OVERLAY")
        iconObj:SetSize(size - 4, size - 4)
        iconObj:SetPoint("CENTER", btn, "CENTER", 0, 0)
        iconObj:SetTexture(icon.tex)
        iconObj:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
        btn._isTexture = true
    else
        iconObj = btn:CreateFontString(nil, "OVERLAY")
        iconObj:SetFont(FONT_HEADERS, math.max(8, size - 7), GetFontFlags())
        iconObj:SetPoint("CENTER", btn, "CENTER", 0, 1)
        iconObj:SetText(icon.text)
        iconObj:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
    end

    btn._iconObj = iconObj
    btn._normalColor = normalColor
    btn:SetScript("OnEnter", function(selfBtn)
        selfBtn:SetBackdropColor(hoverBg[1], hoverBg[2], hoverBg[3], 1)
        selfBtn:SetBackdropBorderColor(hoverBorder[1], hoverBorder[2], hoverBorder[3], 1)
        if selfBtn._isTexture then
            selfBtn._iconObj:SetVertexColor(1, 1, 1)
        else
            selfBtn._iconObj:SetTextColor(1, 1, 1)
        end
        if tooltipText then
            GameTooltip:SetOwner(selfBtn, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tooltipText, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
        selfBtn:SetBackdropBorderColor(0.18, 0.23, 0.30, 0.95)
        if selfBtn._isTexture then
            selfBtn._iconObj:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
        else
            selfBtn._iconObj:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
        end
        GameTooltip:Hide()
    end)
    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    return btn
end

local WBHideConcentrationTrackerOptions

local function WBApplyConcentrationTrackerLayout(frame)
    if not frame then
        return
    end

    local minimized = GetWindowLayoutValue("concentrationTrackerMinimized") == true
    local headerHeight = math.max(24, GetFontSize() + 11)
    WBApplyConcentrationTrackerTheme(frame)
    if frame.titleBar then
        frame.titleBar:SetHeight(headerHeight)
    end
    if frame.body then frame.body:SetShown(not minimized) end
    if frame.summary then frame.summary:SetShown(not minimized) end
    if frame.refreshBtn then frame.refreshBtn:SetShown(not minimized) end
    if frame.scroll then frame.scroll:SetShown(not minimized) end
    if frame.scrollTrack then frame.scrollTrack:SetShown(not minimized) end
    if frame.dragger then frame.dragger:SetShown(not minimized) end
    if minimized then
        WBHideConcentrationTrackerOptions(frame)
    end
    if frame.minBtn and frame.minBtn._iconObj then
        frame.minBtn._iconObj:SetText(minimized and "+" or "-")
    end

    if minimized then
        frame:SetHeight(headerHeight)
    else
        local size = GetWindowLayoutValue("concentrationTrackerSize")
        frame:SetSize((size and size.width) or 440, (size and size.height) or 520)
    end

    if frame.content then
        frame.content:SetWidth(math.max((frame.scroll and frame.scroll:GetWidth() or frame:GetWidth() or 430) - 8, 300))
    end
    if frame.scrollUpdate then
        frame.scrollUpdate()
    end
end

WBHideConcentrationTrackerOptions = function(frame)
    if concentrationTrackerConfigFrame then
        concentrationTrackerConfigFrame:Hide()
    end
end

function MR:ToggleConcentrationTracker()
    if self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() then
        self:HideConcentrationTracker()
        return
    end

    if not self.concentrationTrackerFrame then
        local frame = StyledFrame(UIParent, nil, "DIALOG", 35)
        local savedSize = GetWindowLayoutValue("concentrationTrackerSize")
        frame:SetSize((savedSize and savedSize.width) or 440, (savedSize and savedSize.height) or 520)
        frame:SetScale(self.db.profile.scale or 1)
        local pos = GetWindowLayoutValue("concentrationTrackerPosition")
        if pos and pos.point then
            frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 260, 10)
        end

        local titleBar = TitleBar(frame, math.max(24, GetFontSize() + 11))
        titleBar:SetBackdropColor(0.04, 0.11, 0.20, 1)
        titleBar:SetScript("OnDragStart", function()
            if not (MR.db and MR.db.profile and MR.db.profile.locked) then
                frame:StartMoving()
            end
        end)
        titleBar:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            local pt, _, rp, x, y = frame:GetPoint()
            SetWindowLayoutValue("concentrationTrackerPosition", { point = pt, relPoint = rp, x = x, y = y })
        end)

        local title = titleBar:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_HEADERS, math.max(8, GetFontSize() - 2), GetFontFlags())
        title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
        title:SetPoint("RIGHT", titleBar, "RIGHT", -100, 0)
        title:SetJustifyH("LEFT")
        title:SetText(L["AltBoard_ConcentrationTrackerTitle"] or "Alt Concentration")
        title:SetTextColor(0.92, 0.97, 1.0)

        local closeBtn = WBCreateHeaderButton(
            titleBar,
            { text = "x", size = 18 },
            {0.88, 0.56, 0.56},
            {0.28, 0.10, 0.10},
            {0.90, 0.25, 0.25},
            L["Close"],
            function()
                MR:HideConcentrationTracker()
            end
        )
        closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)

        local minBtn = WBCreateHeaderButton(
            titleBar,
            { text = "-", size = 18 },
            {0.80, 0.84, 0.88},
            {0.10, 0.17, 0.24},
            {0.32, 0.58, 0.72},
            L["Minimize"],
            function()
                SetWindowLayoutValue("concentrationTrackerMinimized", GetWindowLayoutValue("concentrationTrackerMinimized") ~= true)
                WBApplyConcentrationTrackerLayout(frame)
            end
        )
        minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)

        local cfgBtn = WBCreateHeaderButton(
            titleBar,
            { tex = "Interface\\Buttons\\UI-OptionsButton", size = 18 },
            {0.92, 0.76, 0.24},
            {0.18, 0.14, 0.05},
            {0.98, 0.82, 0.24},
            L["Options"],
            function() MR:ToggleConcentrationTrackerConfig() end
        )
        cfgBtn:SetPoint("RIGHT", minBtn, "LEFT", -4, 0)

        local summary = frame:CreateFontString(nil, "OVERLAY")
        summary:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        summary:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -36)
        summary:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -100, -36)
        summary:SetJustifyH("LEFT")
        summary:SetTextColor(0.64, 0.74, 0.84)

        local refreshBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        refreshBtn:SetSize(78, 20)
        refreshBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -32)
        refreshBtn:SetBackdrop(MakeBackdrop())
        refreshBtn:SetBackdropColor(0.05, 0.10, 0.18, 0.95)
        refreshBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
        refreshBtn._label = refreshBtn:CreateFontString(nil, "OVERLAY")
        refreshBtn._label:SetFont(FONT_ROWS, 9, GetFontFlags())
        refreshBtn._label:SetPoint("CENTER", refreshBtn, "CENTER", 0, 0)
        refreshBtn._label:SetText(L["CurrencyBrowser_Refresh"] or "Refresh")
        refreshBtn._label:SetTextColor(0.70, 0.88, 0.85)
        refreshBtn:SetScript("OnClick", function()
            WBPopulateConcentrationTracker(frame)
        end)
        refreshBtn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            selfBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            selfBtn._label:SetTextColor(1, 1, 1)
        end)
        refreshBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.05, 0.10, 0.18, 0.95)
            selfBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
            selfBtn._label:SetTextColor(0.70, 0.88, 0.85)
        end)

        local scroll, content, scrollUpdate, scrollTrack = WBCreateScrollArea(
            frame,
            { "TOPLEFT", frame, "TOPLEFT", 14, -62 },
            { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 14 }
        )
        content:SetSize(400, 1)

        local emptyLabel = content:CreateFontString(nil, "OVERLAY")
        emptyLabel:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
        emptyLabel:SetJustifyH("LEFT")
        emptyLabel:SetTextColor(0.68, 0.74, 0.84)
        emptyLabel:Hide()

        local dragger = CreateFrame("Frame", nil, frame)
        dragger:SetSize(12, 12)
        dragger:SetFrameLevel(frame:GetFrameLevel() + 10)
        dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        dragger:EnableMouse(true)
        local dTex = dragger:CreateTexture(nil, "OVERLAY")
        dTex:SetAllPoints()
        dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

        dragger:SetScript("OnEnter", function()
            if not (MR.db and MR.db.profile and MR.db.profile.locked) then
                dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
            end
        end)
        dragger:SetScript("OnLeave", function()
            dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        end)

        local dragStartW, dragStartH, dragStartX, dragStartY
        dragger:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" and not (MR.db and MR.db.profile and MR.db.profile.locked) then
                dragStartW = frame:GetWidth()
                dragStartH = frame:GetHeight()
                dragStartX, dragStartY = GetCursorPosition()
                local scale = frame:GetEffectiveScale()
                dragStartX = dragStartX / scale
                dragStartY = dragStartY / scale
                dragger._dragging = true
            end
        end)
        dragger:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and dragger._dragging then
                dragger._dragging = false
                local newW = math.max(320, math.min(700, math.floor(frame:GetWidth())))
                local newH = math.max(260, math.min(800, math.floor(frame:GetHeight())))
                frame:SetSize(newW, newH)
                SetWindowLayoutValue("concentrationTrackerSize", { width = newW, height = newH })
                WBPopulateConcentrationTracker(frame)
            end
        end)
        dragger:SetScript("OnUpdate", function()
            if not dragger._dragging then return end
            local cx, cy = GetCursorPosition()
            local scale = frame:GetEffectiveScale()
            cx = cx / scale
            cy = cy / scale
            local dx = cx - dragStartX
            local dy = dragStartY - cy
            frame:SetSize(
                math.max(320, math.min(700, dragStartW + dx)),
                math.max(260, math.min(800, dragStartH + dy))
            )
            if frame.content then
                frame.content:SetWidth(math.max((frame.scroll and frame.scroll:GetWidth() or frame:GetWidth() or 430) - 8, 300))
            end
            if frame.scrollUpdate then
                frame.scrollUpdate()
            end
        end)

        frame.titleBar = titleBar
        frame.summary = summary
        frame.refreshBtn = refreshBtn
        frame.scroll = scroll
        frame.content = content
        frame.scrollUpdate = scrollUpdate
        frame.scrollTrack = scrollTrack
        frame.emptyLabel = emptyLabel
        frame.closeBtn = closeBtn
        frame.minBtn = minBtn
        frame.cfgBtn = cfgBtn
        frame.dragger = dragger
        frame.widgets = {}

        self.concentrationTrackerFrame = frame
    end

    self.concentrationTrackerFrame:SetScale(self.db.profile.scale or 1)
    self.concentrationTrackerFrame:Show()
    if self.SetManagedWindowOpen then
        self:SetManagedWindowOpen("concentrationTrackerOpen", true)
    end
    WBApplyConcentrationTrackerLayout(self.concentrationTrackerFrame)
    WBPopulateConcentrationTracker(self.concentrationTrackerFrame)
end

function MR:HideConcentrationTracker(persistState)
    if self.concentrationTrackerFrame then
        self.concentrationTrackerFrame:Hide()
    end
    WBHideConcentrationTrackerOptions(self.concentrationTrackerFrame)
    if persistState ~= false and self.db and self.SetManagedWindowOpen then
        self:SetManagedWindowOpen("concentrationTrackerOpen", false)
    end
end

function MR:EnsureConcentrationTrackerShown()
    if not (self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown()) then
        self:ToggleConcentrationTracker()
        return
    end

    if self.SetManagedWindowOpen then
        self:SetManagedWindowOpen("concentrationTrackerOpen", true)
    end
    WBApplyConcentrationTrackerLayout(self.concentrationTrackerFrame)
    WBPopulateConcentrationTracker(self.concentrationTrackerFrame)
end

local function ReleaseConcentrationTrackerConfigBody(frame)
    if frame and frame.body then
        frame.body:EnableMouse(false)
        frame.body:Hide()
        frame.body:SetParent(UIParent)
        frame.body = nil
    end
end

function MR:BuildConcentrationTrackerConfigFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(300)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(40)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(f) end
    f:SetBackdropColor(0.03, 0.07, 0.12, 0.98)
    f:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
    f:Hide()

    local tbar = TitleBar(f, 22)
    tbar:SetBackdropColor(0.04, 0.11, 0.20, 1)
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local title = tbar:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_HEADERS, 10, GetFontFlags())
    title:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    title:SetPoint("RIGHT", tbar, "RIGHT", -28, 0)
    title:SetJustifyH("LEFT")
    title:SetText(L["Options"] or "Options")
    title:SetTextColor(0.92, 0.97, 1.0)

    CloseButton(tbar, function() f:Hide() end)
    return f
end

function MR:PopulateConcentrationTrackerConfigFrame(f)
    if not f then
        return
    end

    RefreshFonts()
    ReleaseConcentrationTrackerConfigBody(f)

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    body:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.body = body

    local yOff = -28
    local pad = 8
    local cfgFs = (ns.GetFontSize and ns.GetFontSize()) or (MR.db and MR.db.profile and MR.db.profile.fontSize) or 9
    local contentW = (f:GetWidth() or 300) - (pad * 2)
    body:SetSize(f:GetWidth() or 300, 1)

    local function Gap(h) yOff = OptionsGap(body, yOff, h) end
    local function Divider() yOff = OptionsDivider(body, yOff, pad) end
    local function SectionLabel(text) yOff = OptionsSectionLabel(body, yOff, text, pad, cfgFs) end
    local function Check(label, getValue, setValue, r, g, b)
        yOff = OptionsCheckbox(body, yOff, label, getValue, setValue, r or 0.78, g or 0.78, b or 0.88, pad,
            function() MR:PopulateConcentrationTrackerConfigFrame(f) end, cfgFs)
    end
    local function Slider(label, minValue, maxValue, step, getValue, setValue, r, g, b)
        yOff = OptionsSlider(body, yOff, label, minValue, maxValue, step, getValue, setValue, r, g, b, pad, false, cfgFs)
    end

    SectionLabel(L["Config_Display"] or "Display")
    Slider(L["BACKGROUND"] or "BACKGROUND", 0, 1, 0.05,
        function() return WBGetConcentrationTrackerAlpha() end,
        function(value)
            WBSetConcentrationTrackerAlpha(value)
            if MR.concentrationTrackerFrame then
                WBApplyConcentrationTrackerLayout(MR.concentrationTrackerFrame)
                WBPopulateConcentrationTracker(MR.concentrationTrackerFrame)
            end
        end,
        0.40, 0.75, 0.82)

    Gap(2)
    Check(L["AltBoard_ConcentrationCompactMode"] or "Compact Mode",
        function() return WBIsConcentrationTrackerCompact() end,
        function(value)
            WBSetConcentrationTrackerCompact(value)
            if MR.concentrationTrackerFrame then
                WBPopulateConcentrationTracker(MR.concentrationTrackerFrame)
            end
        end,
        0.38, 0.90, 0.72)

    Gap(4)
    Divider()
    SectionLabel(L["AltBoard_ConcentrationCharacterVisibility"] or "Show / Hide Characters")

    local data = MR:GetWarbandWeeklyData()
    local anyCharacters = false
    for _, charEntry in ipairs(data or {}) do
        local concentrationEntries = type(charEntry.concentration) == "table" and charEntry.concentration or nil
        if concentrationEntries and #concentrationEntries > 0 then
            anyCharacters = true
            local label = string.format(
                (L["AltBoard_ConcentrationShowCharacter"] or "Show %s - %s"),
                charEntry.name or "?",
                charEntry.realm ~= "" and charEntry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm")
            )
            Check(label,
                function() return not WBIsConcentrationTrackerCharacterHidden(charEntry.key) end,
                function(value)
                    WBSetConcentrationTrackerCharacterHidden(charEntry.key, not value)
                    if MR.concentrationTrackerFrame then
                        WBPopulateConcentrationTracker(MR.concentrationTrackerFrame)
                    end
                end,
                0.78, 0.86, 0.95)
        end
    end

    if not anyCharacters then
        local empty = body:CreateFontString(nil, "OVERLAY")
        empty:SetFont(FONT_ROWS, math.max(8, cfgFs - 1), GetFontFlags())
        empty:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
        empty:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
        empty:SetJustifyH("LEFT")
        empty:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
        empty:SetTextColor(0.68, 0.74, 0.84)
        yOff = yOff - 28
    end

    body:SetHeight(math.max(1, -yOff))
    f:SetHeight(math.max(150, -yOff + 10))
end

function MR:ToggleConcentrationTrackerConfig()
    if concentrationTrackerConfigFrame and concentrationTrackerConfigFrame:IsShown() then
        concentrationTrackerConfigFrame:Hide()
        return
    end

    if not concentrationTrackerConfigFrame then
        concentrationTrackerConfigFrame = self:BuildConcentrationTrackerConfigFrame()
    end

    self:PopulateConcentrationTrackerConfigFrame(concentrationTrackerConfigFrame)
    concentrationTrackerConfigFrame:ClearAllPoints()
    if self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() then
        concentrationTrackerConfigFrame:SetPoint("TOPLEFT", self.concentrationTrackerFrame, "TOPRIGHT", 4, 0)
    else
        concentrationTrackerConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    concentrationTrackerConfigFrame:Show()
end

function MR:RefreshWarbandBoard()
    local frame = self.altBoardFrame
    if not frame then return end
    self._warbandBoardLastRefreshAt = GetTime and GetTime() or 0
    frame:SetScale(self.db.profile.scale or 1)
    if self.RefreshConcentrationTracker then
        self:RefreshConcentrationTracker()
    end
    local expansionInfo = GetExpansionDisplayInfo(true)
    local activeView = WBGetAltBoardView()

    if frame.titleText then
        frame.titleText:SetText(L["AltBoard_Title"] or "Alt Weekly Board")
    end
    WBRefreshAltBoardTabs(frame)
    if frame.expansionDropdown and frame.expansionDropdown.Update then
        frame.expansionDropdown:Update()
    end

    if frame.summarySub then
        frame.summarySub:ClearAllPoints()
        frame.summarySub:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -52)
    end
    if frame.leftPane then
        frame.leftPane:ClearAllPoints()
        frame.leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -76)
        frame.leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
    end

    local data = self:GetWarbandWeeklyData()
    frame._data = data

    if not frame.selectedCharKey or not data then
        frame.selectedCharKey = nil
    end

    local selected = nil
    for _, entry in ipairs(data) do
        if frame.selectedCharKey and entry.key == frame.selectedCharKey then
            selected = entry
            break
        end
    end
    if not selected then
        selected = data[1]
        frame.selectedCharKey = selected and selected.key or nil
    end

    WBReleaseWidgets(frame.charButtons)
    WBReleaseWidgets(frame.detailWidgets)

    local totalDone, totalRows, staleCount = 0, 0, 0
    for _, entry in ipairs(data) do
        totalDone = totalDone + entry.doneRows
        totalRows = totalRows + entry.totalRows
        if entry.stale then
            staleCount = staleCount + 1
        end
    end

    if activeView == "concentration" then
        frame.summaryValue:SetText("")
    else
        frame.summaryValue:SetText(string.format("%d / %d", totalDone, totalRows))
        frame.summaryValue:SetTextColor(countColor(totalDone, math.max(totalRows, 1)))
    end

    if #data <= 1 then
        frame.summarySub:SetText(string.format("%s  |  %s", expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key, WBAltLoginPrompt()))
    else
        frame.summarySub:SetText(string.format("%s  |  " .. (L["AltBoard_CharactersTracked"] or "%d characters tracked"), expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key, #data))
    end

    if frame.showHiddenBtn and frame.showHiddenBtn._label then
        frame.showHiddenBtn._label:SetText(MR.db.profile.altBoardShowHidden and (L["AltBoard_HideHidden"] or "Hide Hidden") or (L["AltBoard_ShowHidden"] or "Show Hidden"))
        WBStylePillButton(frame.showHiddenBtn, MR.db.profile.altBoardShowHidden == true)
    end
    if frame.hideCompletedBtn and frame.hideCompletedBtn._label then
        frame.hideCompletedBtn._label:SetText(MR.db.profile.altBoardHideCompleted and (L["AltBoard_ShowCompleted"] or "Show Completed") or (L["AltBoard_HideCompleted"] or "Hide Completed"))
        WBStylePillButton(frame.hideCompletedBtn, MR.db.profile.altBoardHideCompleted == true)
        if activeView == "character" then
            frame.hideCompletedBtn:Show()
            if frame.detailFilterBar then frame.detailFilterBar:Show() end
        else
            frame.hideCompletedBtn:Hide()
            if frame.detailFilterBar then frame.detailFilterBar:Hide() end
        end
    end

    if not selected then
        frame.heroName:SetText(L["AltBoard_NoTrackedCharacters"] or "No tracked characters yet")
        frame.heroMeta:SetText(WBAltLoginPrompt())
        frame.heroStatus:SetText("")
        WBReleaseWidgets(frame.heroConcentrationWidgets)
        WBReleaseWidgets(frame.overviewWidgets)
        if frame.concentrationPane then
            frame.concentrationPane:SetHeight(42)
        end
        if frame.concentrationStatus then
            frame.concentrationStatus:SetText(WBAltLoginPrompt())
            frame.concentrationStatus:SetTextColor(0.68, 0.74, 0.84)
        end
        if frame.hero then frame.hero:Hide() end
        if frame.concentrationPane then frame.concentrationPane:Hide() end
        if frame.detailScroll then frame.detailScroll:Hide() end
        if frame.overviewScroll then frame.overviewScroll:Show() end
        if frame.overviewEmptyLabel then
            frame.overviewEmptyLabel:SetPoint("TOPLEFT", frame.overviewContent, "TOPLEFT", 8, -6)
            frame.overviewEmptyLabel:SetPoint("TOPRIGHT", frame.overviewContent, "TOPRIGHT", -8, -6)
            frame.overviewEmptyLabel:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
            frame.overviewEmptyLabel:Show()
        end
        if frame.overviewContent then
            frame.overviewContent:SetHeight(40)
        end
        if frame.overviewScrollUpdate then
            frame.overviewScrollUpdate()
        end
        frame.detailContent:SetHeight(1)
        return
    end

    for index, entry in ipairs(data) do
        local btn = CreateFrame("Button", nil, frame.charRail, "BackdropTemplate")
        btn:SetSize(204, 54)
        btn:SetPoint("TOPLEFT", frame.charRail, "TOPLEFT", 0, -((index - 1) * 60))
        btn:SetBackdrop(MakeBackdrop())

        local isSelected = (selected.key == entry.key)
        local sr, sg, sb = WBClassColor(entry)
        if isSelected then
            btn:SetBackdropColor(0.055, 0.120, 0.185, 0.99)
            btn:SetBackdropBorderColor(sr, sg, sb, 0.95)
        else
            btn:SetBackdropColor(0.025, 0.050, 0.090, 0.94)
            btn:SetBackdropBorderColor(0.08, 0.16, 0.24, 0.78)
        end

        WBAddSoftSheen(btn, sr, sg, sb, isSelected and 0.16 or 0.06)

        local accent = btn:CreateTexture(nil, "ARTWORK")
        accent:SetPoint("TOPLEFT")
        accent:SetPoint("BOTTOMLEFT")
        accent:SetWidth(isSelected and 4 or 3)
        accent:SetColorTexture(sr, sg, sb, 1)

        local progressBg = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
        progressBg:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 10, 7)
        progressBg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -34, 7)
        progressBg:SetHeight(3)
        progressBg:SetColorTexture(0.07, 0.10, 0.14, 0.95)

        local progressFill = btn:CreateTexture(nil, "ARTWORK")
        progressFill:SetPoint("LEFT", progressBg, "LEFT", 0, 0)
        progressFill:SetHeight(3)
        local pr, pg, pb = countColor(entry.doneRows, math.max(entry.totalRows, 1))
        progressFill:SetColorTexture(pr, pg, pb, 1)
        progressFill:SetWidth(math.max(1, (160 * math.min(1, entry.doneRows / math.max(entry.totalRows, 1)))))

        local name = btn:CreateFontString(nil, "OVERLAY")
        name:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
        name:SetPoint("TOPLEFT", btn, "TOPLEFT", 12, -8)
        name:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -34, -7)
        name:SetJustifyH("LEFT")
        name:SetText(entry.isCurrent and (entry.name .. "  |cff7ce7d8" .. (L["AltBoard_Current"] or "Current") .. "|r") or entry.name)

        local meta = btn:CreateFontString(nil, "OVERLAY")
        meta:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        meta:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
        meta:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -34, -3)
        meta:SetJustifyH("LEFT")
        meta:SetText(string.format("%s  |  %d/%d", entry.realm ~= "" and entry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"), entry.doneRows, entry.totalRows))
        meta:SetTextColor(0.72, 0.79, 0.86)

        local hideBtn = CreateFrame("Button", nil, btn, "BackdropTemplate")
        hideBtn:SetSize(18, 18)
        hideBtn:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -8, -9)
        hideBtn:SetBackdrop(MakeBackdrop())
        hideBtn:SetBackdropColor(0.07, 0.12, 0.18, 0.95)
        hideBtn:SetBackdropBorderColor(0.18, 0.30, 0.36, 0.95)

        local hideLabel = hideBtn:CreateFontString(nil, "OVERLAY")
        hideLabel:SetFont(FONT_HEADERS, 10, GetFontFlags())
        hideLabel:SetPoint("CENTER", hideBtn, "CENTER", 0, 1)
        hideLabel:SetText(entry.hidden and "+" or "x")
        hideLabel:SetTextColor(0.78, 0.88, 0.92)

        hideBtn:SetScript("OnClick", function()
            local makeHidden = not entry.hidden
            MR:SetAltBoardCharacterHidden(entry.key, makeHidden)
            if makeHidden and frame.selectedCharKey == entry.key then
                frame.selectedCharKey = nil
            end
            MR:RefreshWarbandBoard()
        end)
        hideBtn:SetScript("OnEnter", function(selfBtn)
            if entry.hidden then
                selfBtn:SetBackdropColor(0.08, 0.18, 0.10, 0.95)
                selfBtn:SetBackdropBorderColor(0.30, 0.90, 0.42, 1)
            else
                selfBtn:SetBackdropColor(0.18, 0.08, 0.08, 0.95)
                selfBtn:SetBackdropBorderColor(0.90, 0.30, 0.30, 1)
            end
            hideLabel:SetTextColor(1, 1, 1)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:SetText(entry.hidden and (L["AltBoard_ShowCharacter"] or "Show on Alt Weekly Board") or (L["AltBoard_HideCharacter"] or "Hide from Alt Weekly Board"), 1, 1, 1)
            GameTooltip:Show()
        end)
        hideBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.07, 0.12, 0.18, 0.95)
            selfBtn:SetBackdropBorderColor(0.18, 0.30, 0.36, 0.95)
            hideLabel:SetTextColor(0.78, 0.88, 0.92)
            GameTooltip:Hide()
        end)

        btn:SetScript("OnClick", function()
            frame.selectedCharKey = entry.key
            MR:RefreshWarbandBoard()
        end)
        btn:SetScript("OnEnter", function(selfBtn)
            if not isSelected then
                selfBtn:SetBackdropColor(0.040, 0.085, 0.135, 0.98)
                selfBtn:SetBackdropBorderColor(sr, sg, sb, 1)
            end
        end)
        btn:SetScript("OnLeave", function(selfBtn)
            if not isSelected then
                selfBtn:SetBackdropColor(0.025, 0.050, 0.090, 0.94)
                selfBtn:SetBackdropBorderColor(0.08, 0.16, 0.24, 0.78)
            end
        end)

        table.insert(frame.charButtons, btn)
    end

    frame.charRail:SetHeight(math.max(#data * 60, 1))
    if frame.leftScrollUpdate then
        frame.leftScrollUpdate()
    end

    if activeView == "concentration" then
        if frame.hero then frame.hero:Hide() end
        if frame.concentrationPane then frame.concentrationPane:Hide() end
        if frame.detailScroll then frame.detailScroll:Hide() end
        if frame.overviewScroll then frame.overviewScroll:Show() end

        local totalCharacters, totalProfessions = WBPopulateConcentrationOverview(frame, data)
        frame.summarySub:SetText(string.format(
            "%s  |  " .. (L["AltBoard_ConcentrationOverviewSub"] or "%d professions across %d characters"),
            expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key,
            totalProfessions,
            totalCharacters
        ))
        return
    end

    WBReleaseWidgets(frame.overviewWidgets)
    if frame.overviewEmptyLabel then
        frame.overviewEmptyLabel:Hide()
    end
    if frame.overviewScroll then frame.overviewScroll:Hide() end
    if frame.hero then frame.hero:Show() end
    if frame.concentrationPane then frame.concentrationPane:Show() end
    if frame.detailScroll then frame.detailScroll:Show() end

    frame.heroName:SetText(selected.name)
    local syncAt = selected.lastSyncAt and selected.lastSyncAt > 0 and selected.lastSyncAt or selected.lastResetAt
    frame.heroMeta:SetText(string.format(L["AltBoard_LastSynced"] or "%s  |  Last synced: %s", selected.realm ~= "" and selected.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"), WBFormatTimestamp(syncAt)))
    frame.heroStatus:ClearAllPoints()
    frame.heroStatus:SetPoint("BOTTOMLEFT", frame.hero, "BOTTOMLEFT", 14, 12)
    frame.heroStatus:SetText("")

    WBReleaseWidgets(frame.heroConcentrationWidgets)
    frame.heroConcentrationWidgets = frame.heroConcentrationWidgets or {}

    local showHiddenCharacters = MR.db and MR.db.profile and MR.db.profile.altBoardShowHidden == true
    local concentrationEntries = (not showHiddenCharacters) and type(selected.concentration) == "table" and selected.concentration or nil
    local concentrationHeight = 42
    if concentrationEntries and #concentrationEntries > 0 and frame.concentrationPane then
        local contentWidth = math.max((frame.concentrationPane:GetWidth() or 520) - 28, 200)
        local columns = math.max(1, math.min(4, #concentrationEntries))
        if contentWidth >= 520 then
            columns = math.max(columns, math.min(3, #concentrationEntries))
        end
        local gap = 8
        local chipWidth = math.max(110, math.floor((contentWidth - ((columns - 1) * gap)) / columns))
        local rowHeight = 26
        local usedRows = math.max(1, math.ceil(#concentrationEntries / columns))

        for index, concentrationEntry in ipairs(concentrationEntries) do
            local rr, rg, rb = WBConcentrationColor(concentrationEntry)
            local labelText = concentrationEntry.label or (L["Unknown"] or "Unknown")
            local valueText = WBConcentrationText(concentrationEntry)
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            local xOffset = 14 + (col * (chipWidth + gap))
            local yOffset = -34 - (row * (rowHeight + gap))

            local chip = CreateFrame("Frame", nil, frame.concentrationPane, "BackdropTemplate")
            chip:SetSize(chipWidth, rowHeight)
            chip:SetPoint("TOPLEFT", frame.concentrationPane, "TOPLEFT", xOffset, yOffset)
            chip:SetBackdrop(MakeBackdrop())
            chip:SetBackdropColor(0.025 + rr * 0.08, 0.040 + rg * 0.08, 0.060 + rb * 0.08, 0.96)
            chip:SetBackdropBorderColor(rr * 0.60, rg * 0.60, rb * 0.60, 0.95)

            local chipGlow = chip:CreateTexture(nil, "BACKGROUND")
            chipGlow:SetAllPoints()
            chipGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
            chipGlow:SetColorTexture(rr, rg, rb, 0.08)

            local dot = chip:CreateTexture(nil, "ARTWORK")
            dot:SetSize(6, 12)
            dot:SetPoint("LEFT", chip, "LEFT", 8, 0)
            dot:SetColorTexture(rr, rg, rb, 1)

            local label = chip:CreateFontString(nil, "OVERLAY")
            label:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            label:SetPoint("LEFT", dot, "RIGHT", 6, 0)
            label:SetPoint("RIGHT", chip, "RIGHT", -78, 0)
            label:SetJustifyH("LEFT")
            label:SetText(labelText)
            label:SetTextColor(0.84, 0.89, 0.96)

            local value = chip:CreateFontString(nil, "OVERLAY")
            value:SetFont(FONT_HEADERS, math.max(9, GetFontSize() - 1), GetFontFlags())
            value:SetPoint("RIGHT", chip, "RIGHT", -8, 0)
            value:SetJustifyH("RIGHT")
            value:SetText(valueText)
            value:SetTextColor(0.97, 0.98, 1.00)

            table.insert(frame.heroConcentrationWidgets, chip)
        end

        concentrationHeight = 34 + (usedRows * rowHeight) + (math.max(0, usedRows - 1) * gap) + 10
    else
        frame.heroStatus:SetText(selected.stale and (L["AltBoard_AwaitingRefresh"] or "Awaiting refresh") or "")
        if frame.concentrationStatus then
            frame.concentrationStatus:SetText(selected.stale and (L["AltBoard_AwaitingRefresh"] or "Awaiting refresh") or WBAltLoginPrompt())
            frame.concentrationStatus:SetTextColor(selected.stale and 0.95 or 0.68, selected.stale and 0.50 or 0.74, selected.stale and 0.25 or 0.84)
        end
    end

    if frame.concentrationStatus and concentrationEntries and #concentrationEntries > 0 then
        frame.concentrationStatus:SetText("")
    end

    if frame.concentrationPane then
        frame.concentrationPane:SetHeight(concentrationHeight)
    end
    if frame.detailEmptyLabel then
        frame.detailEmptyLabel:Hide()
    end

    local detailWidth = math.max((frame.detailScroll and frame.detailScroll:GetWidth() or 540) - 8, 320)
    frame.detailContent:SetWidth(detailWidth)

    local orderIndex = {}
    for idx, mod in ipairs(MR:GetOrderedModules(MR:GetSelectedExpansionKey(true))) do
        orderIndex[mod.key] = idx
    end
    table.sort(selected.modules, function(a, b)
        local ai = orderIndex[a.key] or 9999
        local bi = orderIndex[b.key] or 9999
        if ai ~= bi then
            return ai < bi
        end
        return a.label < b.label
    end)

    local yOff = 0

    local hideCompletedRows = WBShouldHideCompletedCharacters()

    for _, moduleEntry in ipairs(selected.modules) do
        local visibleRows = {}
        for _, rowEntry in ipairs(moduleEntry.rows) do
            if not (hideCompletedRows and rowEntry.complete) then
                table.insert(visibleRows, rowEntry)
            end
        end

        if not (hideCompletedRows and #visibleRows == 0) then
        local card = CreateFrame("Frame", nil, frame.detailContent, "BackdropTemplate")
        card:SetPoint("TOPLEFT", frame.detailContent, "TOPLEFT", 0, -yOff)
        card:SetSize(1, 1)
        card:SetWidth(detailWidth)
        card:SetBackdrop(MakeBackdrop())
        WBApplySurface(card, "soft", 0.96)

        local mr, mg, mb = WBHexColor(moduleEntry.color, 1, 1, 1)
        local collapsedModules = (MR.db and MR.db.profile and MR.db.profile.altBoardCollapsedModules) or {}
        local isCollapsed = collapsedModules[moduleEntry.key] == true
        WBAddSoftSheen(card, mr, mg, mb, 0.09)

        local topAccent = card:CreateTexture(nil, "ARTWORK")
        topAccent:SetPoint("TOPLEFT")
        topAccent:SetPoint("TOPRIGHT")
        topAccent:SetHeight(3)
        topAccent:SetColorTexture(mr, mg, mb, 1)

        local headerBtn = CreateFrame("Button", nil, card)
        headerBtn:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
        headerBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
        headerBtn:SetHeight(38)

        local headerHover = headerBtn:CreateTexture(nil, "BACKGROUND")
        headerHover:SetAllPoints()
        headerHover:SetColorTexture(1, 1, 1, 0)

        local arrow = headerBtn:CreateFontString(nil, "OVERLAY")
        arrow:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
        arrow:SetPoint("TOPLEFT", headerBtn, "TOPLEFT", 12, -11)
        arrow:SetText(isCollapsed and "+" or "-")
        arrow:SetTextColor(0.78, 0.88, 0.92)

        local title = headerBtn:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
        title:SetPoint("TOPLEFT", arrow, "TOPRIGHT", 7, 0)
        title:SetPoint("RIGHT", headerBtn, "RIGHT", -120, 0)
        title:SetJustifyH("LEFT")
        title:SetText(moduleEntry.label)
        title:SetTextColor(mr, mg, mb)

        local progress = card:CreateFontString(nil, "OVERLAY")
        progress:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        progress:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -11)
        progress:SetText(string.format("%d / %d", moduleEntry.doneRows, moduleEntry.totalRows))
        local pr, pg, pb = countColor(moduleEntry.doneRows, math.max(moduleEntry.totalRows, 1))
        progress:SetTextColor(pr, pg, pb)

        local progressTrack = card:CreateTexture(nil, "BACKGROUND", nil, 1)
        progressTrack:SetPoint("TOPLEFT", card, "TOPLEFT", 13, -31)
        progressTrack:SetPoint("TOPRIGHT", card, "TOPRIGHT", -13, -31)
        progressTrack:SetHeight(3)
        progressTrack:SetColorTexture(0.08, 0.11, 0.16, 0.92)

        local progressFill = card:CreateTexture(nil, "ARTWORK")
        progressFill:SetPoint("LEFT", progressTrack, "LEFT", 0, 0)
        progressFill:SetHeight(3)
        progressFill:SetColorTexture(pr, pg, pb, 1)
        progressFill:SetWidth(math.max(1, (detailWidth - 26) * math.min(1, moduleEntry.doneRows / math.max(moduleEntry.totalRows, 1))))

        headerBtn:SetScript("OnClick", function()
            if not MR.db.profile.altBoardCollapsedModules then
                MR.db.profile.altBoardCollapsedModules = {}
            end
            MR.db.profile.altBoardCollapsedModules[moduleEntry.key] = not isCollapsed or nil
            MR:RefreshWarbandBoard()
        end)
        headerBtn:SetScript("OnEnter", function()
            headerHover:SetColorTexture(1, 1, 1, 0.04)
        end)
        headerBtn:SetScript("OnLeave", function()
            headerHover:SetColorTexture(1, 1, 1, 0)
        end)

        local moduleY = 44
        if not isCollapsed then
            for rowIndex, rowEntry in ipairs(visibleRows) do
                local row = CreateFrame("Frame", nil, card)
                row:SetPoint("TOPLEFT", card, "TOPLEFT", 11, -moduleY)
                row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -11, -moduleY)
                row:SetHeight(24)

                if rowIndex % 2 == 0 then
                    local rowBg = row:CreateTexture(nil, "BACKGROUND")
                    rowBg:SetAllPoints()
                    rowBg:SetColorTexture(1, 1, 1, 0.025)
                end

                local rr, rg, rb
                if selected.stale then
                    rr, rg, rb = 0.42, 0.42, 0.46
                elseif rowEntry.complete then
                    rr, rg, rb = 0.20, 0.95, 0.60
                elseif rowEntry.value > 0 then
                    rr, rg, rb = 1.00, 0.76, 0.28
                else
                    rr, rg, rb = 0.42, 0.48, 0.56
                end

                local dot = row:CreateTexture(nil, "ARTWORK")
                dot:SetSize(6, 12)
                dot:SetPoint("LEFT", row, "LEFT", 2, 0)
                dot:SetColorTexture(rr, rg, rb, 1)

                local label = row:CreateFontString(nil, "OVERLAY")
                label:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
                label:SetPoint("LEFT", row, "LEFT", 18, 0)
                label:SetPoint("RIGHT", row, "RIGHT", -120, 0)
                label:SetJustifyH("LEFT")
                label:SetText(rowEntry.label)
                label:SetTextColor(0.90, 0.93, 0.97)

                local value = row:CreateFontString(nil, "OVERLAY")
                value:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
                value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                value:SetJustifyH("RIGHT")
                value:SetText(selected.stale and (L["AltBoard_AwaitingRefresh"] or "Awaiting refresh") or rowEntry.displayValue)
                value:SetTextColor(rr, rg, rb)

                if rowEntry.accentLabel then
                    local accent = row:CreateFontString(nil, "OVERLAY")
                    accent:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
                    accent:SetPoint("RIGHT", value, "LEFT", -8, 0)
                    accent:SetJustifyH("RIGHT")
                    accent:SetText(WBClean(rowEntry.accentLabel))
                    accent:SetTextColor(WBHexColor(rowEntry.accentColor, 0.78, 0.82, 0.95))
                end

                row:EnableMouse(true)
                row:SetScript("OnEnter", function(selfRow)
                    GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                    if rowEntry.currencyId and not rowEntry.noBlizzardTooltip then
                        GameTooltip:SetCurrencyByID(rowEntry.currencyId)
                        if rowEntry.trackWeeklyEarned then
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine(string.format("Collected this week: %s", rowEntry.displayValue), 0.72, 0.86, 1, true)
                            GameTooltip:AddLine(string.format("Currently held: %d", rowEntry.wallet or 0), 0.72, 0.86, 1, true)
                        else
                            GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
                        end
                    else
                        GameTooltip:SetText(rowEntry.label, 1, 1, 1, 1, true)
                    end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function(selfRow)
                    HideTooltipIfOwned(selfRow)
                end)

                table.insert(frame.detailWidgets, row)
                moduleY = moduleY + 25
            end
        end

        card:SetHeight(moduleY + 8)
        table.insert(frame.detailWidgets, card)
        yOff = yOff + moduleY + 18
        end
    end

    if yOff == 0 and hideCompletedRows and frame.detailEmptyLabel then
        frame.detailEmptyLabel:SetPoint("TOPLEFT", frame.detailContent, "TOPLEFT", 8, -6)
        frame.detailEmptyLabel:SetPoint("TOPRIGHT", frame.detailContent, "TOPRIGHT", -8, -6)
        frame.detailEmptyLabel:SetText(L["AltBoard_NoIncompleteRows"] or "No incomplete rows to show.")
        frame.detailEmptyLabel:Show()
        frame.detailContent:SetHeight(40)
    else
        frame.detailContent:SetHeight(math.max(yOff, 1))
    end
    if frame.detailScrollUpdate then
        frame.detailScrollUpdate()
    end
end

function MR:ToggleWarbandBoard()
    if self.altBoardFrame and self.altBoardFrame:IsShown() then
        self.altBoardFrame:Hide()
        return
    end

    if not self.altBoardFrame then
        local frame = StyledFrame(UIParent, nil, "DIALOG", 30)
        frame:SetSize(820, 640)
        frame:SetScale(self.db.profile.scale or 1)
        local pos = GetWindowLayoutValue("warbandBoardPosition")
        if pos and pos.point then
            frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 130, 10)
        end

        local bgGlow = frame:CreateTexture(nil, "BACKGROUND")
        bgGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        bgGlow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        bgGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
        bgGlow:SetColorTexture(0.02, 0.05, 0.10, 0.98)

        local titleBar = TitleBar(frame, 42)
        titleBar:SetBackdropColor(0.025, 0.070, 0.125, 1)
        titleBar:SetScript("OnDragStart", function()
            frame:StartMoving()
        end)
        titleBar:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            local pt, _, rp, x, y = frame:GetPoint()
            SetWindowLayoutValue("warbandBoardPosition", { point = pt, relPoint = rp, x = x, y = y })
        end)
        local title = titleBar:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_HEADERS, math.max(14, GetFontSize() + 3), GetFontFlags())
        title:SetPoint("LEFT", titleBar, "LEFT", 14, 1)
        title:SetPoint("RIGHT", titleBar, "RIGHT", -150, 0)
        title:SetJustifyH("LEFT")
        title:SetText(L["AltBoard_Title"] or "Alt Weekly Board")
        title:SetTextColor(0.92, 0.97, 1.0)

        local summaryValue = titleBar:CreateFontString(nil, "OVERLAY")
        summaryValue:SetFont(FONT_HEADERS, math.max(11, GetFontSize() + 1), GetFontFlags())
        summaryValue:SetPoint("RIGHT", titleBar, "RIGHT", -58, 1)
        summaryValue:SetText("0 / 0")

        local summarySub = frame:CreateFontString(nil, "OVERLAY")
        summarySub:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        summarySub:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -52)
        summarySub:SetTextColor(0.62, 0.71, 0.79)
        summarySub:SetText("")

        CloseButton(titleBar, function() frame:Hide() end)

        local expansionDropdown = BuildExpansionDropdown(frame, true, {
            width = 160,
            height = 18,
        })
        expansionDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -48)

        local leftPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -76)
        leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
        leftPane:SetWidth(226)
        leftPane:SetBackdrop(MakeBackdrop())
        WBApplySurface(leftPane, "panel")
        WBAddSoftSheen(leftPane, 0.10, 0.22, 0.28, 0.08)

        local leftLabel = leftPane:CreateFontString(nil, "OVERLAY")
        leftLabel:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
        leftLabel:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 12, -12)
        leftLabel:SetText(L["AltBoard_Characters"] or "Characters")
        leftLabel:SetTextColor(0.74, 0.86, 0.89)

        local showHiddenBtn = CreateFrame("Button", nil, leftPane, "BackdropTemplate")
        showHiddenBtn:SetSize(96, 20)
        showHiddenBtn:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", -10, -9)
        showHiddenBtn:SetBackdrop(MakeBackdrop())
        WBStylePillButton(showHiddenBtn, false)

        local showHiddenLabel = showHiddenBtn:CreateFontString(nil, "OVERLAY")
        showHiddenLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        showHiddenLabel:SetPoint("LEFT", showHiddenBtn, "LEFT", 6, 0)
        showHiddenLabel:SetPoint("RIGHT", showHiddenBtn, "RIGHT", -6, 0)
        showHiddenLabel:SetJustifyH("CENTER")
        showHiddenLabel:SetText(L["AltBoard_ShowHidden"] or "Show Hidden")
        showHiddenLabel:SetTextColor(0.70, 0.88, 0.85)
        showHiddenBtn._label = showHiddenLabel

        showHiddenBtn:SetScript("OnClick", function()
            MR.db.profile.altBoardShowHidden = not MR.db.profile.altBoardShowHidden
            MR:RefreshWarbandBoard()
        end)
        showHiddenBtn:SetScript("OnEnter", function(selfBtn)
            WBStylePillButton(selfBtn, true)
            showHiddenLabel:SetTextColor(1, 1, 1)
        end)
        showHiddenBtn:SetScript("OnLeave", function(selfBtn)
            WBStylePillButton(selfBtn, MR.db.profile.altBoardShowHidden == true)
        end)

        local leftScroll, charRail, leftScrollUpdate = WBCreateScrollArea(
            leftPane,
            { "TOPLEFT", leftPane, "TOPLEFT", 8, -30 },
            { "BOTTOMRIGHT", leftPane, "BOTTOMRIGHT", -12, 8 }
        )

        local rightPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        rightPane:SetPoint("TOPLEFT", leftPane, "TOPRIGHT", 14, 0)
        rightPane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
        rightPane:SetBackdrop(MakeBackdrop())
        WBApplySurface(rightPane, "panel")
        WBAddSoftSheen(rightPane, 0.08, 0.16, 0.25, 0.08)

        local tabBar = CreateFrame("Frame", nil, rightPane)
        tabBar:SetPoint("TOPLEFT", rightPane, "TOPLEFT", 14, -14)
        tabBar:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -14, -14)
        tabBar:SetHeight(26)

        local function CreateAltBoardTab(label, viewKey)
            local btn = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
            btn:SetSize(146, 24)
            btn:SetBackdrop(MakeBackdrop())
            btn:SetScript("OnClick", function()
                WBSetAltBoardView(viewKey)
                MR:RefreshWarbandBoard()
            end)
            btn:SetScript("OnEnter", function(selfBtn)
                if WBGetAltBoardView() ~= viewKey then
                    WBStylePillButton(selfBtn, true)
                    if selfBtn._label then
                        selfBtn._label:SetTextColor(1, 1, 1)
                    end
                end
            end)
            btn:SetScript("OnLeave", function()
                WBRefreshAltBoardTabs(frame)
            end)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
            lbl:SetText(label)
            btn._label = lbl
            return btn
        end

        local characterTab = CreateAltBoardTab(L["AltBoard_TabCharacter"] or "Character", "character")
        characterTab:SetPoint("LEFT", tabBar, "LEFT", 0, 0)

        local concentrationTab = CreateAltBoardTab(L["AltBoard_TabConcentration"] or "Concentration", "concentration")
        concentrationTab:SetPoint("LEFT", characterTab, "RIGHT", 8, 0)

        local concentrationTrackerBtn = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        concentrationTrackerBtn:SetSize(154, 24)
        concentrationTrackerBtn:SetPoint("LEFT", concentrationTab, "RIGHT", 8, 0)
        concentrationTrackerBtn:SetBackdrop(MakeBackdrop())
        concentrationTrackerBtn:SetBackdropColor(0.05, 0.10, 0.18, 0.95)
        concentrationTrackerBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

        local concentrationTrackerLabel = concentrationTrackerBtn:CreateFontString(nil, "OVERLAY")
        concentrationTrackerLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        concentrationTrackerLabel:SetPoint("LEFT", concentrationTrackerBtn, "LEFT", 6, 0)
        concentrationTrackerLabel:SetPoint("RIGHT", concentrationTrackerBtn, "RIGHT", -6, 0)
        concentrationTrackerLabel:SetJustifyH("CENTER")
        concentrationTrackerLabel:SetText(L["AltBoard_TrackAllConcentration"] or "Concentration Popout")
        concentrationTrackerLabel:SetTextColor(0.70, 0.88, 0.85)
        concentrationTrackerBtn._label = concentrationTrackerLabel

        concentrationTrackerBtn:SetScript("OnClick", function()
            MR:ToggleConcentrationTracker()
        end)
        concentrationTrackerBtn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            selfBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            concentrationTrackerLabel:SetTextColor(1, 1, 1)
        end)
        concentrationTrackerBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.05, 0.10, 0.18, 0.95)
            selfBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
            concentrationTrackerLabel:SetTextColor(0.70, 0.88, 0.85)
        end)

        local hero = CreateFrame("Frame", nil, rightPane, "BackdropTemplate")
        hero:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -14)
        hero:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", 0, -14)
        hero:SetHeight(86)
        hero:SetBackdrop(MakeBackdrop())
        WBApplySurface(hero, "raised")

        local heroGlow = hero:CreateTexture(nil, "BACKGROUND")
        heroGlow:SetPoint("TOPLEFT")
        heroGlow:SetPoint("BOTTOMRIGHT")
        heroGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
        heroGlow:SetColorTexture(0.10, 0.24, 0.30, 0.16)

        local heroName = hero:CreateFontString(nil, "OVERLAY")
        heroName:SetFont(FONT_HEADERS, math.max(13, GetFontSize() + 3), GetFontFlags())
        heroName:SetPoint("TOPLEFT", hero, "TOPLEFT", 16, -14)
        heroName:SetTextColor(0.96, 0.99, 1.00)

        local heroMeta = hero:CreateFontString(nil, "OVERLAY")
        heroMeta:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        heroMeta:SetPoint("TOPLEFT", heroName, "BOTTOMLEFT", 0, -7)
        heroMeta:SetTextColor(0.70, 0.78, 0.86)

        local heroStatus = hero:CreateFontString(nil, "OVERLAY")
        heroStatus:SetFont(FONT_ROWS, math.max(10, GetFontSize()), GetFontFlags())
        heroStatus:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 16, 14)

        local concentrationPane = CreateFrame("Frame", nil, rightPane, "BackdropTemplate")
        concentrationPane:SetPoint("TOPLEFT", hero, "BOTTOMLEFT", 0, -14)
        concentrationPane:SetPoint("TOPRIGHT", hero, "BOTTOMRIGHT", 0, -14)
        concentrationPane:SetHeight(42)
        concentrationPane:SetBackdrop(MakeBackdrop())
        WBApplySurface(concentrationPane, "soft")

        local concentrationAccent = concentrationPane:CreateTexture(nil, "ARTWORK")
        concentrationAccent:SetPoint("TOPLEFT")
        concentrationAccent:SetPoint("TOPRIGHT")
        concentrationAccent:SetHeight(2)
        concentrationAccent:SetColorTexture(0.76, 0.62, 0.98, 1)

        local concentrationTitle = concentrationPane:CreateFontString(nil, "OVERLAY")
        concentrationTitle:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
        concentrationTitle:SetPoint("TOPLEFT", concentrationPane, "TOPLEFT", 14, -10)
        concentrationTitle:SetText(WBConcentrationLabel())
        concentrationTitle:SetTextColor(0.88, 0.82, 1.00)

        local concentrationStatus = concentrationPane:CreateFontString(nil, "OVERLAY")
        concentrationStatus:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        concentrationStatus:SetPoint("TOPLEFT", concentrationTitle, "BOTTOMLEFT", 0, -8)
        concentrationStatus:SetPoint("RIGHT", concentrationPane, "RIGHT", -12, 0)
        concentrationStatus:SetJustifyH("LEFT")
        concentrationStatus:SetTextColor(0.70, 0.78, 0.88)

        local detailFilterBar = CreateFrame("Frame", nil, rightPane)
        detailFilterBar:SetPoint("TOPLEFT", concentrationPane, "BOTTOMLEFT", 0, -10)
        detailFilterBar:SetPoint("TOPRIGHT", concentrationPane, "BOTTOMRIGHT", 0, -10)
        detailFilterBar:SetHeight(22)

        local hideCompletedBtn = CreateFrame("Button", nil, detailFilterBar, "BackdropTemplate")
        hideCompletedBtn:SetSize(122, 20)
        hideCompletedBtn:SetPoint("TOPRIGHT", detailFilterBar, "TOPRIGHT", -2, 0)
        hideCompletedBtn:SetBackdrop(MakeBackdrop())
        WBStylePillButton(hideCompletedBtn, false)

        local hideCompletedLabel = hideCompletedBtn:CreateFontString(nil, "OVERLAY")
        hideCompletedLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        hideCompletedLabel:SetPoint("LEFT", hideCompletedBtn, "LEFT", 6, 0)
        hideCompletedLabel:SetPoint("RIGHT", hideCompletedBtn, "RIGHT", -6, 0)
        hideCompletedLabel:SetJustifyH("CENTER")
        hideCompletedLabel:SetText(L["AltBoard_HideCompleted"] or "Hide Completed")
        hideCompletedLabel:SetTextColor(0.70, 0.88, 0.85)
        hideCompletedBtn._label = hideCompletedLabel

        hideCompletedBtn:SetScript("OnClick", function()
            MR.db.profile.altBoardHideCompleted = not MR.db.profile.altBoardHideCompleted
            MR:RefreshWarbandBoard()
        end)
        hideCompletedBtn:SetScript("OnEnter", function(selfBtn)
            WBStylePillButton(selfBtn, true)
            hideCompletedLabel:SetTextColor(1, 1, 1)
        end)
        hideCompletedBtn:SetScript("OnLeave", function(selfBtn)
            WBStylePillButton(selfBtn, MR.db.profile.altBoardHideCompleted == true)
        end)

        local detailScroll, detailContent, detailScrollUpdate = WBCreateScrollArea(
            rightPane,
            { "TOPLEFT", detailFilterBar, "BOTTOMLEFT", 0, -8 },
            { "BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", -10, 10 }
        )
        detailContent:SetSize(520, 1)
        local detailEmptyLabel = detailContent:CreateFontString(nil, "OVERLAY")
        detailEmptyLabel:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
        detailEmptyLabel:SetJustifyH("LEFT")
        detailEmptyLabel:SetTextColor(0.68, 0.74, 0.84)
        detailEmptyLabel:Hide()

        local overviewScroll, overviewContent, overviewScrollUpdate = WBCreateScrollArea(
            rightPane,
            { "TOPLEFT", tabBar, "BOTTOMLEFT", 0, -12 },
            { "BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", -10, 10 }
        )
        overviewContent:SetSize(520, 1)
        overviewScroll:Hide()

        local overviewEmptyLabel = overviewContent:CreateFontString(nil, "OVERLAY")
        overviewEmptyLabel:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
        overviewEmptyLabel:SetJustifyH("LEFT")
        overviewEmptyLabel:SetTextColor(0.68, 0.74, 0.84)
        overviewEmptyLabel:Hide()

        frame.charButtons = {}
        frame.detailWidgets = {}
        frame.overviewWidgets = {}
        frame.charRail = charRail
        frame.leftScroll = leftScroll
        frame.leftScrollUpdate = leftScrollUpdate
        frame.detailScroll = detailScroll
        frame.detailScrollUpdate = detailScrollUpdate
        frame.detailContent = detailContent
        frame.detailEmptyLabel = detailEmptyLabel
        frame.detailFilterBar = detailFilterBar
        frame.overviewScroll = overviewScroll
        frame.overviewScrollUpdate = overviewScrollUpdate
        frame.overviewContent = overviewContent
        frame.overviewEmptyLabel = overviewEmptyLabel
        frame.summaryValue = summaryValue
        frame.summarySub = summarySub
        frame.expansionDropdown = expansionDropdown
        frame.hero = hero
        frame.heroConcentrationWidgets = {}
        frame.concentrationPane = concentrationPane
        frame.concentrationTitle = concentrationTitle
        frame.concentrationStatus = concentrationStatus
        frame.concentrationTrackerBtn = concentrationTrackerBtn
        frame.leftPane = leftPane
        frame.showHiddenBtn = showHiddenBtn
        frame.hideCompletedBtn = hideCompletedBtn
        frame.heroName = heroName
        frame.heroMeta = heroMeta
        frame.heroStatus = heroStatus
        frame.titleText = title
        frame.leftLabel = leftLabel
        frame.showHiddenLabel = showHiddenLabel
        frame.hideCompletedLabel = hideCompletedLabel
        frame.tabBar = tabBar
        frame.altTabs = {
            character = characterTab,
            concentration = concentrationTab,
        }
        frame.rightPane = rightPane

        self.altBoardFrame = frame
    end

    self.altBoardFrame:SetScale(self.db.profile.scale or 1)
    self.altBoardFrame:Show()
    self:RefreshWarbandBoard()
end

local function EnsureCustomTaskDialog()
    if MR.customTaskDialog then
        return MR.customTaskDialog
    end


    local PAD  = 14
    local GAP  = 10
    local IGAP = 6
    local IH   = 28
    local LH   = 14

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(400, 460)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(80)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame:SetBackdrop(MakeBackdrop())
    frame:SetBackdropColor(0.03, 0.08, 0.14, 0.98)
    frame:SetBackdropBorderColor(0.20, 0.44, 0.48, 1)
    frame:Hide()

    local dragRegion = CreateFrame("Frame", nil, frame)
    dragRegion:SetPoint("TOPLEFT",  frame, "TOPLEFT",  8, -8)
    dragRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    dragRegion:SetHeight(26)
    dragRegion:EnableMouse(true)
    dragRegion:RegisterForDrag("LeftButton")
    dragRegion:SetScript("OnDragStart", function() frame:StartMoving() end)
    dragRegion:SetScript("OnDragStop",  function() frame:StopMovingOrSizing() end)


    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
    title:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD, -PAD)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD)
    title:SetJustifyH("LEFT")
    title:SetText(L["CustomTasks_Title"] or "Custom Tasks")
    title:SetTextColor(0.92, 0.97, 1)
    frame.title = title


    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  title, "BOTTOMLEFT",  0, -8)
    sep:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -8)
    sep:SetColorTexture(0.20, 0.44, 0.48, 0.5)


    local function MakeLabel(anchorFrame, anchorPoint, xOff, yOff, text)
        local lbl = frame:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
        lbl:SetPoint("TOPLEFT", anchorFrame, anchorPoint, xOff, yOff)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(text)
        lbl:SetTextColor(0.55, 0.70, 0.82)
        return lbl
    end


    local function MakeInputBg(anchorFrame, anchorPoint, xOff, yOff, w, h)
        local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        if w then
            bg:SetSize(w, h or IH)
            bg:SetPoint("TOPLEFT", anchorFrame, anchorPoint, xOff, yOff)
        else
            bg:SetHeight(h or IH)
            bg:SetPoint("TOPLEFT",  anchorFrame, anchorPoint, xOff, yOff)
            bg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, 0)
        end
        bg:SetBackdrop(MakeBackdrop())
        bg:SetBackdropColor(0.04, 0.09, 0.16, 0.98)
        bg:SetBackdropBorderColor(0.16, 0.36, 0.42, 1)
        return bg
    end

    local function MakeEditBox(bg, maxLen, isNumeric)
        local eb = CreateFrame("EditBox", nil, bg, "InputBoxTemplate")
        eb:SetAutoFocus(false)
        eb:SetPoint("TOPLEFT",     bg, "TOPLEFT",     6, -6)
        eb:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -6,  6)
        eb:SetFontObject(ChatFontNormal)
        eb:SetTextInsets(0, 0, 0, 0)
        eb:SetMaxLetters(maxLen or 120)
        eb:SetTextColor(0.95, 0.97, 1)
        if isNumeric then eb:SetNumeric(true) end
        eb:SetScript("OnEscapePressed", function() frame:Hide() end)
        eb:SetScript("OnTextChanged", function(selfEdit)
            ApplyDialogEditBoxFont(selfEdit, GetFontSize())
            if frame.RefreshSmartState then frame:RefreshSmartState() end
        end)
        return eb
    end


    local nameLabel = MakeLabel(sep, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_NameLabel"] or "Task name")
    nameLabel:SetTextColor(0.74, 0.84, 0.92)
    local nameBg    = MakeInputBg(nameLabel, "BOTTOMLEFT", 0, -IGAP)
    local input     = MakeEditBox(nameBg, 120)
    input:SetScript("OnEscapePressed", function() frame:Hide() end)
    frame.nameLabel = nameLabel
    frame.inputBg   = nameBg
    frame.input     = input


    local COL2W = 170

    local questLabel = MakeLabel(nameBg, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_QuestIdsLabel"] or "Quest ID(s)")
    local questBg    = MakeInputBg(questLabel, "BOTTOMLEFT", 0, -IGAP, COL2W, IH)
    local questInput = MakeEditBox(questBg, 120)
    frame.questLabel = questLabel
    frame.questBg    = questBg
    frame.questInput = questInput

    local encounterLabel = MakeLabel(nameBg, "BOTTOMLEFT", COL2W + GAP, -GAP, L["CustomTasks_EncounterIdsLabel"] or "Encounter ID(s)")
    local encounterBg    = MakeInputBg(encounterLabel, "BOTTOMLEFT", 0, -IGAP, COL2W, IH)
    local encounterInput = MakeEditBox(encounterBg, 120)
    frame.encounterLabel  = encounterLabel
    frame.encounterBg     = encounterBg
    frame.encounterInput  = encounterInput


    local idHint = frame:CreateFontString(nil, "OVERLAY")
    idHint:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    idHint:SetPoint("TOPLEFT",  questBg, "BOTTOMLEFT",  0, -4)
    idHint:SetPoint("TOPRIGHT", frame,   "TOPRIGHT",   -PAD, 0)
    idHint:SetJustifyH("LEFT")
    idHint:SetText("Enter quest IDs for quest tracking, or encounter IDs for boss-kill tracking. Cannot combine both.")
    idHint:SetTextColor(0.46, 0.58, 0.70)
    frame.idHint = idHint


    local DIFF_OPTIONS = {
        { id = 17, label = "LFR" },
        { id = 14, label = "Normal" },
        { id = 15, label = "Heroic" },
        { id = 16, label = "Mythic" },
    }
    local difficultyLabel = MakeLabel(idHint, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_DifficultyLabel"] or "Difficulties")
    difficultyLabel:SetTextColor(0.74, 0.84, 0.92)
    frame.difficultyLabel = difficultyLabel

    frame.difficultyChecks = {}
    local prevDiffCheck = nil
    for i, opt in ipairs(DIFF_OPTIONS) do
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        if i == 1 then
            cb:SetPoint("TOPLEFT", difficultyLabel, "BOTTOMLEFT", 0, -4)
        else
            cb:SetPoint("LEFT", prevDiffCheck._text, "RIGHT", 14, 0)
        end
        cb:SetChecked(true)
        local cbText = frame:CreateFontString(nil, "OVERLAY")
        cbText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        cbText:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cbText:SetText(opt.label)
        cbText:SetTextColor(0.84, 0.90, 0.96)
        cb._text  = cbText
        cb._diffId = opt.id
        frame.difficultyChecks[i] = cb
        prevDiffCheck = cb
    end

    local diffHint = frame:CreateFontString(nil, "OVERLAY")
    diffHint:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    diffHint:SetPoint("LEFT", prevDiffCheck._text, "RIGHT", 18, 0)
    diffHint:SetText("(all = any)")
    diffHint:SetTextColor(0.40, 0.52, 0.62)
    frame.diffHint = diffHint






    local targetLabel = MakeLabel(difficultyLabel, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_TargetLabel"] or "Target")
    targetLabel:SetTextColor(0.74, 0.84, 0.92)
    local targetBg    = MakeInputBg(targetLabel, "BOTTOMLEFT", 0, -IGAP, 60, IH)
    local targetInput = MakeEditBox(targetBg, 3, true)
    targetInput:SetScript("OnTextChanged", function(selfEdit)
        ApplyDialogEditBoxFont(selfEdit, GetFontSize())
    end)
    local targetHint = frame:CreateFontString(nil, "OVERLAY")
    targetHint:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    targetHint:SetPoint("LEFT",  targetBg, "RIGHT", 8, 0)
    targetHint:SetPoint("RIGHT", frame,    "RIGHT", -PAD, 0)
    targetHint:SetJustifyH("LEFT")
    targetHint:SetText("1 = checkbox   2+ = counter (e.g. 0/3)")
    targetHint:SetTextColor(0.46, 0.58, 0.70)
    frame.targetLabel = targetLabel
    frame.targetBg    = targetBg
    frame.targetInput = targetInput
    frame.targetHint  = targetHint


    local resetLabel = MakeLabel(targetBg, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_ResetType"] or "Resets")
    resetLabel:SetTextColor(0.74, 0.84, 0.92)
    frame.resetLabel = resetLabel

    local function CreateResetCheckbox(anchorTo, anchorPt, xOff, yOff, labelText, value)
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", anchorTo, anchorPt, xOff, yOff)
        local text = frame:CreateFontString(nil, "OVERLAY")
        text:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        text:SetText(labelText)
        text:SetTextColor(0.84, 0.90, 0.96)
        cb._text  = text
        cb._value = value
        cb:SetScript("OnClick", function(selfBtn)
            if not selfBtn:GetChecked() then selfBtn:SetChecked(true) end
            frame.resetType = selfBtn._value
            if frame.RefreshResetChecks then frame:RefreshResetChecks() end
        end)
        return cb
    end


    local weeklyCheck = CreateResetCheckbox(resetLabel, "BOTTOMLEFT", 0, -4, L["CustomTasks_ResetWeekly"] or "Weekly", "weekly")
    local dailyCheck  = CreateResetCheckbox(weeklyCheck, "TOPLEFT", 0, 0, L["CustomTasks_ResetDaily"] or "Daily", "daily")
    dailyCheck:ClearAllPoints()
    dailyCheck:SetPoint("LEFT", weeklyCheck._text, "RIGHT", 14, 0)
    frame.weeklyCheck = weeklyCheck
    frame.dailyCheck  = dailyCheck


    local manualQuestCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    manualQuestCheck:SetSize(20, 20)
    manualQuestCheck:SetPoint("TOPLEFT", weeklyCheck, "BOTTOMLEFT", 0, -GAP)
    local manualQuestText = frame:CreateFontString(nil, "OVERLAY")
    manualQuestText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    manualQuestText:SetPoint("LEFT", manualQuestCheck, "RIGHT", 2, 0)
    manualQuestText:SetText(L["CustomTasks_ManualQuestClicks"] or "Allow manual clicks")
    manualQuestText:SetTextColor(0.84, 0.90, 0.96)
    manualQuestCheck._text = manualQuestText
    manualQuestCheck:SetScript("OnClick", function(selfBtn)
        frame.allowManualQuestClicks = selfBtn:GetChecked() and true or false
        if frame.RefreshSmartState then frame:RefreshSmartState() end
    end)
    frame.manualQuestCheck = manualQuestCheck
    frame.manualQuestHint  = frame:CreateFontString(nil, "OVERLAY")

    local autoUpdateCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    autoUpdateCheck:SetSize(20, 20)
    autoUpdateCheck:SetPoint("TOPLEFT", manualQuestCheck, "BOTTOMLEFT", 0, -4)
    local autoUpdateText = frame:CreateFontString(nil, "OVERLAY")
    autoUpdateText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    autoUpdateText:SetPoint("LEFT", autoUpdateCheck, "RIGHT", 2, 0)
    autoUpdateText:SetText(L["CustomTasks_AutoUpdateInstances"] or "Auto-update in instances")
    autoUpdateText:SetTextColor(0.84, 0.90, 0.96)
    autoUpdateCheck._text = autoUpdateText
    autoUpdateCheck:SetScript("OnClick", function(selfBtn)
        frame.autoUpdateInstances = selfBtn:GetChecked() and true or false
    end)
    frame.autoUpdateCheck = autoUpdateCheck
    frame.autoUpdateHint  = frame:CreateFontString(nil, "OVERLAY")


    local function CreateDialogButton(width, label, color, borderColor)
        local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetSize(width, 26)
        btn:SetBackdrop(MakeBackdrop())
        btn:SetBackdropColor(color[1], color[2], color[3], 0.95)
        btn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(FONT_HEADERS, 10, GetFontFlags())
        text:SetPoint("CENTER", btn, "CENTER", 0, 1)
        text:SetText(label)
        text:SetTextColor(0.92, 0.96, 1)
        btn._label = text
        btn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(color[1]+0.04, color[2]+0.04, color[3]+0.04, 1)
            selfBtn:SetBackdropBorderColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(color[1], color[2], color[3], 0.95)
            selfBtn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
        end)
        return btn
    end

    local saveBtn   = CreateDialogButton(88, L["CustomTasks_Save"]   or "Save",   {0.10,0.26,0.20},{0.28,0.78,0.50})
    local cancelBtn = CreateDialogButton(88, L["CustomTasks_Cancel"] or "Cancel", {0.10,0.12,0.16},{0.28,0.34,0.42})
    local deleteBtn = CreateDialogButton(88, L["CustomTasks_Delete"] or "Delete", {0.22,0.08,0.08},{0.72,0.20,0.20})

    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
    cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
    deleteBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)

    cancelBtn:SetScript("OnClick", function() frame:Hide() end)
    deleteBtn:SetScript("OnClick", function()
        if frame.taskId then MR:DeleteCustomTask(frame.taskId) end
        frame:Hide()
    end)
    frame.saveBtn   = saveBtn
    frame.cancelBtn = cancelBtn
    frame.deleteBtn = deleteBtn


    function frame:RefreshSmartState()
        local hasQuestIds    = self.questInput    and (self.questInput:GetText()    or ""):match("%d") ~= nil
        local hasEncounterIds = self.encounterInput and (self.encounterInput:GetText() or ""):match("%d") ~= nil


        if self.manualQuestCheck then
            self.manualQuestCheck:EnableMouse(hasQuestIds)
            self.manualQuestCheck:SetChecked(hasQuestIds and self.allowManualQuestClicks == true or false)
            if self.manualQuestCheck._text then
                self.manualQuestCheck._text:SetAlpha(hasQuestIds and 1 or 0.50)
            end
        end


        if self.encounterInput then
            local disableEncounter = hasQuestIds
            self.encounterInput:EnableMouse(not disableEncounter)
            self.encounterInput:SetAlpha(disableEncounter and 0.40 or 1)
            if disableEncounter then self.encounterInput:SetText("") end
        end
        if self.encounterLabel then self.encounterLabel:SetAlpha(hasQuestIds and 0.40 or 1) end


        if self.questInput then
            local disableQuest = hasEncounterIds and not hasQuestIds
            self.questInput:EnableMouse(not disableQuest)
            self.questInput:SetAlpha(disableQuest and 0.40 or 1)
        end
        if self.questLabel then self.questLabel:SetAlpha(hasEncounterIds and not hasQuestIds and 0.40 or 1) end


        local enableTarget = hasQuestIds
        if self.targetInput then
            self.targetInput:EnableMouse(enableTarget)
            self.targetInput:SetAlpha(enableTarget and 1 or 0.40)
        end
        if self.targetBg    then self.targetBg:SetAlpha(enableTarget and 1 or 0.40) end
        if self.targetLabel then self.targetLabel:SetAlpha(enableTarget and 1 or 0.40) end
        if self.targetHint  then self.targetHint:SetAlpha(enableTarget and 1 or 0.40) end


        local showDiff = hasEncounterIds and not hasQuestIds
        if self.difficultyLabel then self.difficultyLabel:SetShown(showDiff) end
        if self.diffHint        then self.diffHint:SetShown(showDiff) end
        if self.difficultyChecks then
            for _, cb in ipairs(self.difficultyChecks) do
                cb:SetShown(showDiff)
                if cb._text then cb._text:SetShown(showDiff) end
            end
        end
    end

    function frame:RefreshResetChecks()
        local isDaily = self.resetType == "daily"
        if self.weeklyCheck then self.weeklyCheck:SetChecked(not isDaily) end
        if self.dailyCheck  then self.dailyCheck:SetChecked(isDaily) end
    end


    function frame:Commit()
        local text = self.input:GetText() or ""
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then
            if UIErrorsFrame and UIErrorsFrame.AddMessage then
                UIErrorsFrame:AddMessage(L["CustomTasks_EmptyError"] or "Enter a task name first.", 1, 0.25, 0.25)
            end
            self.input:SetFocus()
            return
        end

        local maxValue = math.floor(tonumber(self.targetInput:GetText() or "") or 1)
        if maxValue < 1 then maxValue = 1 elseif maxValue > 999 then maxValue = 999 end

        local encounterDifficulties = nil
        if self.difficultyChecks then
            local allChecked = true
            for _, cb in ipairs(self.difficultyChecks) do
                if not cb:GetChecked() then allChecked = false break end
            end
            if not allChecked then
                encounterDifficulties = {}
                for _, cb in ipairs(self.difficultyChecks) do
                    if cb:GetChecked() then encounterDifficulties[cb._diffId] = true end
                end
            end
        end

        if self.taskId then
            MR:UpdateCustomTask(self.taskId, text, self.resetType, maxValue, self.questInput:GetText() or "", self.allowManualQuestClicks, self.encounterInput and self.encounterInput:GetText() or "", self.autoUpdateInstances, encounterDifficulties)
        else
            MR:AddCustomTask(text, self.resetType, maxValue, self.questInput:GetText() or "", self.allowManualQuestClicks, self.encounterInput and self.encounterInput:GetText() or "", self.autoUpdateInstances, encounterDifficulties)
        end
        self:Hide()
    end

    saveBtn:SetScript("OnClick",  function() frame:Commit() end)
    input:SetScript("OnEnterPressed",         function() frame:Commit() end)
    questInput:SetScript("OnEnterPressed",    function() frame:Commit() end)
    encounterInput:SetScript("OnEnterPressed",function() frame:Commit() end)
    targetInput:SetScript("OnEnterPressed",   function() frame:Commit() end)

    if frame.RefreshSmartState then frame:RefreshSmartState() end
    MR.customTaskDialog = frame
    ApplyCustomTaskDialogTheme(frame)
    return frame
end


function MR:ShowCustomTaskDialog(taskId, presetResetType)
    local dialog = EnsureCustomTaskDialog()
    local task = taskId and self.GetCustomTaskById and self:GetCustomTaskById(taskId) or nil

    dialog.taskId = task and task.id or nil
    dialog.resetType = (task and task.resetType) or presetResetType or "weekly"
    dialog.title:SetText(task and (L["CustomTasks_EditTitle"] or "Edit Custom Task") or (L["CustomTasks_AddTitle"] or "Add Custom Task"))
    dialog.input:SetText(task and task.label or "")
    dialog.questInput:SetText((task and task.questIds and table.concat(task.questIds, ", ")) or "")
    dialog.encounterInput:SetText((task and task.encounterIds and table.concat(task.encounterIds, ", ")) or "")
    dialog.targetInput:SetText(tostring((task and task.max) or 1))
    dialog.allowManualQuestClicks = task and task.allowManualQuestClicks or false
    dialog.autoUpdateInstances = task and task.autoUpdateInstances or false
    if dialog.autoUpdateCheck then
        dialog.autoUpdateCheck:SetChecked(dialog.autoUpdateInstances)
    end

    local storedDiffs = task and task.encounterDifficulties or nil
    if dialog.difficultyChecks then
        for _, cb in ipairs(dialog.difficultyChecks) do
            cb:SetChecked(storedDiffs == nil or storedDiffs[cb._diffId] == true)
        end
    end
    dialog.deleteBtn:SetShown(task ~= nil)
    if dialog.RefreshResetChecks then
        dialog:RefreshResetChecks()
    end
    if dialog.RefreshSmartState then
        dialog:RefreshSmartState()
    end
    ApplyCustomTaskDialogTheme(dialog)
    dialog:Show()
    dialog.input:SetFocus()
    dialog.input:HighlightText(0, -1)
end

local function EnsureCustomTasksTitleDialog()
    if MR.customTasksTitleDialog then
        return MR.customTasksTitleDialog
    end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(340, 190)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(80)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    frame:SetBackdrop(MakeBackdrop())
    frame:SetBackdropColor(0.03, 0.08, 0.14, 0.98)
    frame:SetBackdropBorderColor(0.20, 0.44, 0.48, 1)
    frame:Hide()

    local dragRegion = CreateFrame("Frame", nil, frame)
    dragRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    dragRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    dragRegion:SetHeight(26)
    dragRegion:EnableMouse(true)
    dragRegion:RegisterForDrag("LeftButton")
    dragRegion:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    dragRegion:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12)
    title:SetJustifyH("LEFT")
    title:SetText(L["CustomTasks_EditModuleTitle"] or "Rename custom task title")
    title:SetTextColor(0.92, 0.97, 1)

    local subtitle = frame:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -6)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(L["CustomTasks_EditModuleTitleNote"] or "Click to rename the Custom Tasks header for this character.")
    subtitle:SetTextColor(0.68, 0.78, 0.86)
    frame.titleText = title
    frame.subtitle = subtitle

    local inputBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    inputBg:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -14)
    inputBg:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -14)
    inputBg:SetHeight(34)
    inputBg:SetBackdrop(MakeBackdrop())
    inputBg:SetBackdropColor(0.05, 0.10, 0.18, 0.98)
    inputBg:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

    local input = CreateFrame("EditBox", nil, inputBg, "InputBoxTemplate")
    input:SetAutoFocus(false)
    input:SetPoint("TOPLEFT", inputBg, "TOPLEFT", 8, -8)
    input:SetPoint("BOTTOMRIGHT", inputBg, "BOTTOMRIGHT", -8, 8)
    input:SetFontObject(ChatFontNormal)
    input:SetTextInsets(0, 0, 0, 0)
    input:SetMaxLetters(120)
    input:SetTextColor(0.95, 0.97, 1)
    input:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    frame.input = input

    local hint = frame:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
    hint:SetPoint("TOPLEFT", inputBg, "BOTTOMLEFT", 0, -8)
    hint:SetPoint("TOPRIGHT", inputBg, "BOTTOMRIGHT", 0, -8)
    hint:SetJustifyH("LEFT")
    hint:SetText(L["CustomTasks_EditModuleTitleHint"] or "Leave it as Custom Tasks, or rename it to something like Weekly Goals.")
    hint:SetTextColor(0.60, 0.72, 0.82)
    frame.hint = hint

    local function CreateDialogButton(width, label, color, borderColor)
        local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetSize(width, 24)
        btn:SetBackdrop(MakeBackdrop())
        btn:SetBackdropColor(color[1], color[2], color[3], 0.95)
        btn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)

        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(FONT_HEADERS, 10, GetFontFlags())
        text:SetPoint("CENTER", btn, "CENTER", 0, 1)
        text:SetText(label)
        text:SetTextColor(0.92, 0.96, 1)
        btn._label = text

        btn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(color[1] + 0.04, color[2] + 0.04, color[3] + 0.04, 1)
            selfBtn:SetBackdropBorderColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(color[1], color[2], color[3], 0.95)
            selfBtn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
        end)

        return btn
    end

    local saveBtn = CreateDialogButton(92, L["CustomTasks_Save"] or "Save", { 0.10, 0.26, 0.20 }, { 0.28, 0.78, 0.50 })
    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
    frame.saveBtn = saveBtn

    local cancelBtn = CreateDialogButton(92, L["CustomTasks_Cancel"] or "Cancel", { 0.10, 0.12, 0.16 }, { 0.28, 0.34, 0.42 })
    cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
    cancelBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.cancelBtn = cancelBtn

    function frame:Commit()
        local text = self.input:GetText() or ""
        MR:SetCustomTasksTitle(text)
        self:Hide()
    end

    saveBtn:SetScript("OnClick", function()
        frame:Commit()
    end)
    input:SetScript("OnEnterPressed", function()
        frame:Commit()
    end)

    MR.customTasksTitleDialog = frame
    ApplyCustomTasksTitleDialogTheme(frame)
    return frame
end

function MR:ShowCustomTasksTitleDialog()
    local dialog = EnsureCustomTasksTitleDialog()
    dialog.input:SetText(self.GetCustomTasksTitle and self:GetCustomTasksTitle() or (L["CustomTasks_Title"] or "Custom Tasks"))
    ApplyCustomTasksTitleDialogTheme(dialog)
    dialog:Show()
    dialog.input:SetFocus()
    dialog.input:HighlightText(0, -1)
end

local function GetModuleWindowTitle(mod)
    local cleanLabel = mod.label:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
    return cleanLabel
end

local function ApplyWidth(newW)
    newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, math.floor(newW)))
    MR.db.profile.width = newW
    if MR.frame then MR.frame:SetWidth(newW) end
    if MR.RequestUIRefresh then
        MR:RequestUIRefresh(0.02)
    else
        MR:RefreshUI()
    end
end
MR.ApplyWidth = ApplyWidth

local function ApplyHeight(newH)
    newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, math.floor(newH)))
    MR.db.profile.height = newH
    if MR.frame then MR.frame:SetHeight(newH) end
    if MR.RequestUIRefresh then
        MR:RequestUIRefresh(0.02)
    else
        MR:RefreshUI()
    end
end
MR.ApplyHeight = ApplyHeight

local function ApplyFontSize(newSize)
    newSize = math.max(FONT_SIZE_MIN, math.min(FONT_SIZE_MAX, math.floor(newSize)))
    MR.db.profile.fontSize = newSize
    RecalcLayout()
    if MR.ApplySharedMediaSettings then
        MR:ApplySharedMediaSettings()
    else
        if MR.RequestUIRefresh then
            MR:RequestUIRefresh(0.02)
        else
            MR:RefreshUI()
        end
    end
end
MR.ApplyFontSize = ApplyFontSize

GetWindowLayoutValue = function(key)
    if MR and MR.GetWindowLayoutValue then
        return MR:GetWindowLayoutValue(key)
    end

    if not (MR and MR.db and key) then return nil end

    if MR.db.profile and MR.db.profile.characterWindowLayout == true then
        local charLayout = MR.db.char and MR.db.char.windowLayout
        if charLayout and charLayout[key] ~= nil then
            return charLayout[key]
        end
    end

    return MR.db.profile and MR.db.profile[key]
end

SetWindowLayoutValue = function(key, value)
    if MR and MR.SetWindowLayoutValue then
        MR:SetWindowLayoutValue(key, value)
        return
    end

    if not (MR and MR.db and key) then return end

    if MR.db.profile and MR.db.profile.characterWindowLayout == true then
        if not MR.db.char.windowLayout then
            MR.db.char.windowLayout = {}
        end
        MR.db.char.windowLayout[key] = value
        return
    end

    MR.db.profile[key] = value
end

local function GetMainHeaderPosition()
    if GetWindowLayoutValue and GetWindowLayoutValue("mainHeaderPosition") == "bottom" then
        return "bottom"
    end

    return "top"
end

local function IsAnimatedMinimizeEnabled()
    if GetWindowLayoutValue then
        return GetWindowLayoutValue("animatedMinimize") == true
    end

    return false
end

function MR:GetManagedHeaderPosition()
    return GetMainHeaderPosition()
end

function MR:IsManagedAnimatedMinimizeEnabled()
    return IsAnimatedMinimizeEnabled()
end

local function IsMainHeaderAtBottom()
    return GetMainHeaderPosition() == "bottom"
end

local function GetMainFrameExpandedHeight()
    return math.max(PANEL_MIN_HEIGHT, math.min(MR.db.profile.height or 400, PANEL_MAX_HEIGHT))
end

local function GetMainFrameCollapsedHeight()
    return GetMainHeaderHeight()
end

local function GetStoredMainFrameCollapsedAnchor()
    local pos = GetWindowLayoutValue("collapsedPosition")
    if pos and pos.point then
        return pos
    end

    return GetWindowLayoutValue("position")
end

local function SetStoredMainFrameCollapsedAnchor(pos)
    if not pos or not pos.point then
        return
    end

    SetWindowLayoutValue("collapsedPosition", {
        point = pos.point,
        relPoint = pos.relPoint or pos.point,
        x = pos.x or 0,
        y = pos.y or 0,
    })
end

local function GetStoredMainFrameActiveAnchor()
    if MR and MR.db and MR.db.profile and MR.db.profile.minimized then
        return GetStoredMainFrameCollapsedAnchor()
    end

    return GetWindowLayoutValue("position")
end

local function SetStoredMainFrameActiveAnchor(pos)
    if not pos or not pos.point then
        return
    end

    if MR and MR.db and MR.db.profile and MR.db.profile.minimized then
        SetStoredMainFrameCollapsedAnchor(pos)
    else
        SetWindowLayoutValue("position", {
            point = pos.point,
            relPoint = pos.relPoint or pos.point,
            x = pos.x or 0,
            y = pos.y or 0,
        })
    end
end

local function CaptureMainFrameAnchor(frame, anchorMode)
    return CaptureManagedFrameAnchor(frame, anchorMode, GetStoredMainFrameActiveAnchor())
end

local function ApplyMainFrameAnchor(frame, anchorMode, preserveScreenPosition)
    if not frame then
        return
    end

    if MR and MR._mainFrameDragging then
        return
    end

    local pos = preserveScreenPosition and CaptureMainFrameAnchor(frame, anchorMode) or GetStoredMainFrameActiveAnchor()
    if not pos or not pos.point then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        return
    end

    ApplyManagedFrameAnchor(frame, pos)
    SetStoredMainFrameActiveAnchor(pos)
end

local function ApplyExplicitMainFrameAnchor(frame, pos)
    if not frame or not pos or not pos.point then
        return
    end

    ApplyManagedFrameAnchor(frame, pos)
end

local function GetBottomHeaderCollapseTarget(frame)
    local movedSinceExpand = MR and MR._mainFrameMovedSinceExpand == true
    local anchor

    if movedSinceExpand then
        anchor = CaptureMainFrameAnchor(frame, "bottom")
    else
        anchor = (MR and MR._mainCollapsedAnchorBeforeExpand) or GetStoredMainFrameCollapsedAnchor()
    end

    if not (anchor and anchor.point) then
        anchor = CaptureMainFrameAnchor(frame, "bottom")
    end

    if anchor and anchor.point then
        SetStoredMainFrameCollapsedAnchor(anchor)
    end

    if MR then
        MR._mainCollapsedAnchorBeforeExpand = nil
        MR._mainFrameMovedSinceExpand = false
    end

    return anchor
end

local function ApplyMainFrameLayout(frame, preserveScreenPosition)
    if not frame then
        return
    end

    local titleBar = MR and MR._titleBar
    local scrollBg = MR and MR._scrollBg
    local scroll = MR and MR.scroll
    local track = MR and MR._scrollTrack
    local dragger = MR and MR._dragger
    local expansionDropdown = MR and MR.expansionDropdown
    local headerHeight = titleBar and titleBar:GetHeight() or GetMainHeaderHeight()
    local headerBottom = IsMainHeaderAtBottom()

    if titleBar then
        titleBar:ClearAllPoints()
        if headerBottom then
            titleBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
            titleBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        else
            titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        end
    end

    if scrollBg then
        scrollBg:ClearAllPoints()
        if headerBottom then
            scrollBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            scrollBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, headerHeight)
        else
            scrollBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -headerHeight)
            scrollBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        end
    end

    if scroll then
        scroll:ClearAllPoints()
        if headerBottom then
            scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
            scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, headerHeight + 6)
        else
            scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(headerHeight + 6))
            scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, 4)
        end
    end

    if track and scroll then
        track:ClearAllPoints()
        track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 1, 0)
        track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    end

    if dragger then
        dragger:ClearAllPoints()
        if headerBottom then
            dragger:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
        else
            dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        end
    end

    if expansionDropdown then
        expansionDropdown:ClearAllPoints()
        if headerBottom then
            expansionDropdown:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -4, 0)
        else
            expansionDropdown:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -4, 0)
        end
    end

    ApplyMainFrameAnchor(frame, GetMainHeaderPosition(), preserveScreenPosition == true)
end

local function SetMainFrameChromeVisible(visible)
    if MR.scroll then MR.scroll:SetShown(visible) end
    if MR._scrollBg then MR._scrollBg:SetShown(visible) end
    if MR._scrollTrack then MR._scrollTrack:SetShown(visible) end
    if MR._dragger then
        MR._dragger:SetShown(visible and not (MR.db and MR.db.profile and MR.db.profile.minimized))
    end
end

local mainFrameAnimator = CreateFrame("Frame")
mainFrameAnimator:Hide()

local function StopMainFrameAnimation()
    mainFrameAnimator:SetScript("OnUpdate", nil)
    mainFrameAnimator:Hide()
end

local function AnimateMainFrameHeight(targetHeight, onFinished)
    local frame = MR and MR.frame
    if not frame then
        if onFinished then onFinished() end
        return
    end

    local startHeight = frame:GetHeight() or targetHeight
    local delta = targetHeight - startHeight
    if math.abs(delta) < 1 then
        frame:SetHeight(targetHeight)
        if onFinished then onFinished() end
        return
    end

    StopMainFrameAnimation()
    mainFrameAnimator:Show()
    AnimateManagedFrameHeight(frame, targetHeight, function()
        StopMainFrameAnimation()
        if onFinished then onFinished() end
    end, nil, mainFrameAnimator)
end

function MR:BuildUI()
    RefreshFonts()
    if self.frame then self.frame:Show() return end

    RecalcLayout()
    local w = MR.db.profile.width or 260
    local h = MR.db.profile.height or 400

    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(w)
    f:SetHeight(h)
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(f) end
    f:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4])
    f:SetBackdropBorderColor(0.15, 0.15, 0.2, 1)
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    RestoreManagedFramePos(f, nil, 0, 0, GetStoredMainFrameActiveAnchor())
    f:SetScale(MR.db.profile.scale or 1)
    self.frame = f
    f:SetScript("OnShow", function()
        if MR._refreshUIDirty or MR._mainPanelNeedsRefresh then
            MR:RefreshUI()
        end
    end)

    local scrollBg = f:CreateTexture(nil, "BACKGROUND")
    ApplyBackgroundTexture(scrollBg, COL.bg[1], COL.bg[2], COL.bg[3], 0.96)
    MR._scrollBg = scrollBg

    local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    MR._titleBar = titleBar
    titleBar:SetHeight(GetMainHeaderHeight())
    titleBar:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(titleBar) end
    titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98)
    titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, 1)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        if not MR.db.profile.locked then
            MR._mainFrameDragging = true
            f:StartMoving()
        end
    end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local pos = CaptureMainFrameAnchor(f, GetMainHeaderPosition())
        if pos then
            SetStoredMainFrameActiveAnchor(pos)
            if (not MR.db.profile.minimized) and IsMainHeaderAtBottom() then
                MR._mainFrameMovedSinceExpand = true
            end
        end
        MR._mainFrameDragging = false
    end)
    if MR.ApplyPanelHeaderAutoHide then MR:ApplyPanelHeaderAutoHide(f, titleBar) end

    local titleAccent = titleBar:CreateTexture(nil, "ARTWORK")
    MR._titleAccent = titleAccent
    titleAccent:SetPoint("TOPLEFT",    titleBar, "TOPLEFT",    0, 0)
    titleAccent:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    titleAccent:SetWidth(0)
    titleAccent:SetColorTexture(0.92, 0.72, 0.20, 1)

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(22, 22)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    titleIcon:SetTexture("Interface\\AddOns\\MidnightRoutine\\Media\\Icon")
    titleIcon:SetVertexColor(1, 0.84, 0.24, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_HEADERS, math.max(8, GetFontSize() - 2), GetFontFlags())
    title:SetPoint("LEFT", titleIcon, "RIGHT", 5, 0)
    title:SetPoint("RIGHT", titleBar, "RIGHT", -110, 0)
    title:SetJustifyH("LEFT")
    title:SetText(L["Title"])
    self.titleText = title

    local titleCount = titleBar:CreateFontString(nil, "OVERLAY")
    titleCount:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    titleCount:SetTextColor(0.84, 0.88, 0.90)
    self.titleCount = titleCount

    local BTN_SIZE   = 20
    local BTN_PAD    = 4
    local BTN_MARGIN = 8

    local function MakeHeaderBtn(icon, normalColor, hoverBg, hoverBorder, tooltipText, tooltipSub)
        local btn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
        btn:SetSize(BTN_SIZE, BTN_SIZE)
        btn:SetBackdrop(MakeBackdrop())
        btn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
        btn:SetBackdropBorderColor(0.18, 0.23, 0.30, 0.95)

        local iconObj
        if icon.tex then
            local t = btn:CreateTexture(nil, "OVERLAY")
            t:SetSize(BTN_SIZE - 6, BTN_SIZE - 6)
            t:SetPoint("CENTER", btn, "CENTER", 0, 0)
            t:SetTexture(icon.tex)
            t:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
            iconObj = t
            btn._iconTex = t
        else
            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_HEADERS, 11, GetFontFlags())
            lbl:SetPoint("CENTER", btn, "CENTER", 0, 1)
            lbl:SetText(icon.text)
            lbl:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
            iconObj = lbl
            btn._lbl = lbl
        end

        btn._normalColor = normalColor
        btn._iconObj     = iconObj
        btn._isTexture   = (icon.tex ~= nil)

        btn:SetScript("OnEnter", function(s)
            btn:SetBackdropColor(hoverBg[1], hoverBg[2], hoverBg[3], 1)
            btn:SetBackdropBorderColor(hoverBorder[1], hoverBorder[2], hoverBorder[3], 1)
            if btn._isTexture then
                btn._iconObj:SetVertexColor(1, 1, 1)
            else
                btn._iconObj:SetTextColor(1, 1, 1)
            end
            if tooltipText then
                GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
                GameTooltip:SetText(tooltipText, 1, 1, 1)
                if tooltipSub then GameTooltip:AddLine(tooltipSub, 0.6, 0.6, 0.6) end
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
            btn:SetBackdropBorderColor(0.18, 0.23, 0.30, 0.95)
            if btn._isTexture then
                btn._iconObj:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
            else
                btn._iconObj:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
            end
            GameTooltip:Hide()
        end)
        return btn
    end

    local closeBtn = MakeHeaderBtn(
        { text = "x" },
        {0.88, 0.56, 0.56},
        {0.28, 0.10, 0.10},
        {0.90, 0.25, 0.25},
        L["Close"],
        L["UI_HideAddon"]
    )
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -BTN_MARGIN, 0)
    closeBtn:SetScript("OnClick", function()
        if MR.HideCurrencyBrowserFrame then
            MR:HideCurrencyBrowserFrame()
        end
        f:Hide()
        MR.db.char.panelOpen = false
    end)
    self.closeBtn = closeBtn

    local minBtn = MakeHeaderBtn(
        { text = "-" },
        {0.80, 0.84, 0.88},
        {0.10, 0.17, 0.24},
        {0.32, 0.58, 0.72},
        L["Minimize"],
        L["UI_CollapseHint"]
    )
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -BTN_PAD, 0)
    self.minBtn = minBtn

    local function UpdateMinimizeVisual()
        minBtn._lbl:SetText(MR.db.profile.minimized and "+" or "-")
    end
    UpdateMinimizeVisual()
    self.UpdateMinimizeVisual = UpdateMinimizeVisual

    local function ApplyMinimizeState()
        local collapsed = MR.db.profile.minimized == true
        local targetHeight = collapsed and GetMainFrameCollapsedHeight() or GetMainFrameExpandedHeight()
        local useAnimation = IsAnimatedMinimizeEnabled()
        ApplyMainFrameLayout(f, true)
        if collapsed then
            if MR._dragger then MR._dragger:Hide() end
        else
            SetMainFrameChromeVisible(true)
        end

        local function finalize()
            if collapsed then
                SetMainFrameChromeVisible(false)
            else
                SetMainFrameChromeVisible(true)
            end
            UpdateMinimizeVisual()
        end

        if useAnimation then
            AnimateMainFrameHeight(targetHeight, finalize)
        else
            StopMainFrameAnimation()
            f:SetHeight(targetHeight)
            finalize()
        end
    end
    self.ApplyMinimizeState = ApplyMinimizeState

    minBtn:SetScript("OnClick", function()
        MR.db.profile.minimized = not MR.db.profile.minimized
        if MR.db.profile.minimized and MR.HideCurrencyBrowserFrame then
            MR:HideCurrencyBrowserFrame()
        end
        ApplyMinimizeState()
    end)

    local cfgBtn = MakeHeaderBtn(
        { tex = "Interface\\Buttons\\UI-OptionsButton" },
        {0.92, 0.76, 0.24},
        {0.18, 0.14, 0.05},
        {0.98, 0.82, 0.24},
        L["Options"],
        L["UI_ChatHint"]
    )
    cfgBtn:SetPoint("RIGHT", minBtn, "LEFT", -BTN_PAD, 0)
    cfgBtn:SetScript("OnClick", function()
        MR:ToggleConfig()
        MR:DismissFirstTimeGlow()
    end)

    local origCfgEnter = cfgBtn:GetScript("OnEnter")
    cfgBtn:SetScript("OnEnter", function(s)
        origCfgEnter(s)
        if MR.db and not MR.db.profile.firstSeen then
            GameTooltip:AddLine(L["Options_Glow"], 1, 1, 1)
            GameTooltip:AddLine(L["UI_ModularHint"], 0.9, 0.85, 0.3)
            GameTooltip:Show()
        end
    end)

    local cfgShine = CreateFrame("Frame", nil, cfgBtn)
    cfgShine:SetSize(28, 28)
    cfgShine:SetPoint("CENTER", cfgBtn, "CENTER", 0, 0)
    cfgShine:Hide()
    local function MakeSparkle(parent, x, y)
        local t = parent:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\ItemSocketingFrame\\UI-ItemSockingFrame-Glow")
        t:SetSize(10, 10)
        t:SetPoint("CENTER", parent, "CENTER", x, y)
        t:SetBlendMode("ADD")
        return t
    end
    cfgShine._sparks = {
        MakeSparkle(cfgShine, -9,  9),
        MakeSparkle(cfgShine,  9,  9),
        MakeSparkle(cfgShine, -9, -9),
        MakeSparkle(cfgShine,  9, -9),
    }
    local elapsed = 0
    cfgShine:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local alpha = 0.5 + 0.5 * math.sin(elapsed * 4)
        for _, s in ipairs(self._sparks) do s:SetAlpha(alpha) end
    end)
    cfgShine.Play = function(self) self:Show() end
    cfgShine.Stop = function(self) self:Hide() end
    self.cfgShine = cfgShine

    self.cfgBtn = cfgBtn

    local warbandBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    warbandBtn:SetSize(50, BTN_SIZE)
    warbandBtn:SetPoint("RIGHT", cfgBtn, "LEFT", -BTN_PAD, 0)
    warbandBtn:SetBackdrop(MakeBackdrop())
    warbandBtn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
    warbandBtn:SetBackdropBorderColor(0.24, 0.31, 0.38, 0.95)
    local warbandGlow = warbandBtn:CreateTexture(nil, "BACKGROUND")
    warbandGlow:SetPoint("TOPLEFT")
    warbandGlow:SetPoint("BOTTOMRIGHT")
    warbandGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    warbandGlow:SetColorTexture(0.15, 0.42, 0.45, 0.14)
    local warbandText = warbandBtn:CreateFontString(nil, "OVERLAY")
    warbandText:SetFont(FONT_HEADERS, 9, GetFontFlags())
    warbandText:SetPoint("CENTER", warbandBtn, "CENTER", 0, 1)
    warbandText:SetText(L["AltBoard_ButtonLabel"] or "ALTS")
    warbandText:SetTextColor(0.84, 0.92, 0.96)
    self.warbandBtnText = warbandText
    warbandBtn:SetScript("OnEnter", function(selfBtn)
        selfBtn:SetBackdropColor(0.11, 0.17, 0.24, 1)
        selfBtn:SetBackdropBorderColor(0.42, 0.62, 0.76, 1)
        warbandText:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["AltBoard_OpenTooltip"] or "Open Alt Weekly Board", 1, 1, 1)
        GameTooltip:AddLine(L["AltBoard_OpenTooltipSub"] or "Browse every tracked alt and see exactly what is done, in progress, or untouched this week.", 0.6, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    warbandBtn:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
        selfBtn:SetBackdropBorderColor(0.24, 0.31, 0.38, 0.95)
        warbandText:SetTextColor(0.84, 0.92, 0.96)
        GameTooltip:Hide()
    end)
    warbandBtn:SetScript("OnClick", function()
        MR:ToggleWarbandBoard()
    end)
    self.warbandBtn = warbandBtn

    titleCount:SetPoint("RIGHT", warbandBtn, "LEFT", -6, 0)
    title:ClearAllPoints()
    title:SetPoint("LEFT", titleIcon, "RIGHT", 5, 0)
    title:SetPoint("RIGHT", titleCount, "LEFT", -8, 0)
    title:SetJustifyH("LEFT")

    local function RefreshMainHeaderChrome()
        local metrics = GetMainHeaderMetrics()
        titleBar:SetHeight(metrics.headerHeight)
        titleIcon:SetSize(metrics.iconSize, metrics.iconSize)
        closeBtn:SetSize(metrics.buttonSize, metrics.buttonSize)
        minBtn:SetSize(metrics.buttonSize, metrics.buttonSize)
        cfgBtn:SetSize(metrics.buttonSize, metrics.buttonSize)
        warbandBtn:SetSize(metrics.warbandWidth, metrics.buttonSize)
        if cfgBtn._iconTex then
            cfgBtn._iconTex:SetSize(metrics.buttonSize - 5, metrics.buttonSize - 5)
        end
        if closeBtn._lbl then
            closeBtn._lbl:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 1), GetFontFlags())
        end
        if minBtn._lbl then
            minBtn._lbl:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 1), GetFontFlags())
        end
        title:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 2), GetFontFlags())
        titleCount:SetFont(FONT_ROWS, math.max(8, metrics.fontSize - 2), GetFontFlags())
        warbandText:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 2), GetFontFlags())
        ApplyMainFrameLayout(f)
    end
    self.RefreshMainHeaderChrome = RefreshMainHeaderChrome
    RefreshMainHeaderChrome()

    local expansionDropdown = BuildExpansionDropdown(f, false, {
        width = 150,
        height = 16,
    })
    self.expansionDropdown = expansionDropdown

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:EnableMouseWheel(true)
    self.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth((MR.db.profile.width or 260) - 9)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    self.content = content

    local track = CreateFrame("Frame", nil, f)
    self._scrollTrack = track
    track:SetPoint("TOPLEFT",    scroll, "TOPRIGHT",    1, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    track:SetWidth(5)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0, 0, 0, 0.3)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(5)
    thumb:EnableMouse(true)
    thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.25, 0.65, 0.65, 0.75)

    local function UpdateScrollBar()
        local viewH    = scroll:GetHeight()
        local contentH = content:GetHeight()
        if contentH <= viewH or viewH <= 0 then thumb:Hide() return end
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 14)
        local pct    = scroll:GetVerticalScroll() / (contentH - viewH)
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
        thumb._dragging = true
        thumb._grabOffset = thumb:GetHeight() * 0.5
        thumb:SetScript("OnUpdate", function(self)
            if not IsMouseButtonDown("LeftButton") then
                self._dragging = nil
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
        self._dragging = true
        self:SetScript("OnUpdate", function(btn)
            if not IsMouseButtonDown("LeftButton") then
                btn._dragging = nil
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
        self._dragging = nil
        self._grabOffset = nil
        self:SetScript("OnUpdate", nil)
    end)

    scroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = scroll:GetVerticalScroll()
        local max = math.max(content:GetHeight() - scroll:GetHeight(), 0)
        scroll:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, max)))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", function() UpdateScrollBar() end)
    scroll:SetScript("OnVerticalScroll",     function() UpdateScrollBar() end)
    self.UpdateScrollBar = UpdateScrollBar

    self.widgets         = {}
    self.sectionRegistry = {}

    local dragger = CreateFrame("Frame", nil, f)
    dragger:SetSize(12, 12)
    dragger:SetFrameLevel(f:GetFrameLevel() + 10)
    dragger:EnableMouse(true)

    local dTex = dragger:CreateTexture(nil, "OVERLAY")
    dTex:SetAllPoints()
    dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    dragger:SetScript("OnEnter", function()
        if not MR.db.profile.locked then
            dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        end
    end)
    dragger:SetScript("OnLeave", function()
        dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    local dragStartW, dragStartH, dragStartX, dragStartY
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not MR.db.profile.locked then
            dragStartW = f:GetWidth()
            dragStartH = f:GetHeight()
            dragStartX, dragStartY = GetCursorPosition()
            local scale = f:GetEffectiveScale()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            local newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, math.floor(f:GetWidth())))
            local newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, math.floor(f:GetHeight())))
            MR.db.profile.width  = newW
            MR.db.profile.height = newH
            f:SetWidth(newW)
            f:SetHeight(newH)
            MR:RefreshUI()
            if cfgFrame and cfgFrame:IsShown() then MR:PopulateConfigFrame(cfgFrame) end
        end
    end)
    dragger:SetScript("OnUpdate", function()
        if not dragger._dragging then return end
        local cx, cy = GetCursorPosition()
        local scale = f:GetEffectiveScale()
        cx = cx / scale
        cy = cy / scale
        local dx = cx - dragStartX
        local dy = dragStartY - cy
        local newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, dragStartW + dx))
        local newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, dragStartH + dy))
        f:SetWidth(newW)
        f:SetHeight(newH)
    end)
    self._dragger = dragger

    self._timerRows = {}
    local _tick = 0
    local tickFrame = CreateFrame("Frame")
    tickFrame:SetScript("OnUpdate", function(_, elapsed)
        _tick = _tick + elapsed
        if _tick < 1 then return end
        _tick = 0
        for _, f in ipairs(MR._timerRows) do
            if f:IsShown() and f._timerUpdate then
                f._timerUpdate()
            end
        end
    end)
    self._tickFrame = tickFrame

    ApplyMainFrameLayout(f)
    self:RefreshUI()
    ApplyTheme()
end

function MR:HideDetachedModules()
    if not self.detachedFrames then return end
    for _, frame in pairs(self.detachedFrames) do
        frame:Hide()
    end
end

function MR:ShowDetachedModules()
    if self._instanceFramesHidden then return end
    if self:IsManagedWindowsBundleHidden() then return end
    if not self.detachedFrames then return end
    for key, frame in pairs(self.detachedFrames) do
        local mod = self.moduleByKey[key]
        local modVisible = mod and (not mod.isVisible or mod:isVisible())
        if self:IsModuleDetached(key) and self:IsModuleEnabled(key) and modVisible then
            frame:Show()
        end
    end
end

function MR:EnsureDetachedFrame(mod)
    self.detachedFrames = self.detachedFrames or {}
    local frame = self.detachedFrames[mod.key]
    if frame then return frame end

    local savedSize = self:GetDetachedModuleSize(mod.key)
    local defaultW = math.max(220, (self.db.profile.width or 260) - 20)
    local defaultH = HEADER_HEIGHT + 120
    local title = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    title:SetSize(savedSize and savedSize.width or defaultW, savedSize and savedSize.height or defaultH)
    title:SetFrameStrata("MEDIUM")
    title:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(title) end
    title:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4])
    title:SetBackdropBorderColor(0.15, 0.15, 0.2, 1)
    title:SetClampedToScreen(true)
    title:SetMovable(true)

    local pos = self:GetDetachedModulePosition(mod.key)
    if pos and pos.point then
        title:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else
        title:SetPoint("CENTER", UIParent, "CENTER", 40, -40)
    end

    local dragBar = CreateFrame("Frame", nil, title, "BackdropTemplate")
    dragBar:SetPoint("TOPLEFT", title, "TOPLEFT", 0, 0)
    dragBar:SetPoint("TOPRIGHT", title, "TOPRIGHT", 0, 0)
    dragBar:SetHeight(6)
    dragBar:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(dragBar) end
    dragBar:SetBackdropColor(0.04, 0.10, 0.20, 1)
    dragBar:SetBackdropBorderColor(0.10, 0.28, 0.35, 1)
    dragBar:EnableMouse(false)

    local dragAccent = dragBar:CreateTexture(nil, "ARTWORK")
    dragAccent:SetPoint("TOPLEFT", dragBar, "TOPLEFT", 0, 0)
    dragAccent:SetPoint("BOTTOMLEFT", dragBar, "BOTTOMLEFT", 0, 0)
    dragAccent:SetWidth(3)
    dragAccent:SetColorTexture(0.16, 0.78, 0.75, 1)

    local scroll = CreateFrame("ScrollFrame", nil, title)
    scroll:SetPoint("TOPLEFT", title, "TOPLEFT", 4, -8)
    scroll:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", -4, 4)
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = scroll:GetVerticalScroll()
        local max = math.max(content:GetHeight() - scroll:GetHeight(), 0)
        scroll:SetVerticalScroll(math.max(0, math.min(cur - delta * 24, max)))
    end)

    local dragger = CreateFrame("Frame", nil, title)
    dragger:SetSize(12, 12)
    dragger:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", -1, 1)
    dragger:SetFrameLevel(title:GetFrameLevel() + 10)
    dragger:EnableMouse(true)

    local dTex = dragger:CreateTexture(nil, "OVERLAY")
    dTex:SetAllPoints()
    dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    dragger:SetScript("OnEnter", function()
        if not MR.db.profile.locked then
            dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        end
    end)
    dragger:SetScript("OnLeave", function()
        dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    local dragStartW, dragStartH, dragStartX, dragStartY
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not MR.db.profile.locked then
            dragStartW = title:GetWidth()
            dragStartH = title:GetHeight()
            dragStartX, dragStartY = GetCursorPosition()
            local scale = title:GetEffectiveScale()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            local newW = math.max(180, math.min(PANEL_MAX_WIDTH, math.floor(title:GetWidth())))
            local newH = math.max(HEADER_HEIGHT + 48, math.min(PANEL_MAX_HEIGHT, math.floor(title:GetHeight())))
            title:SetWidth(newW)
            title:SetHeight(newH)
            MR:SetDetachedModuleSize(mod.key, newW, newH)
            MR:RefreshUI()
        end
    end)
    dragger:SetScript("OnUpdate", function()
        if not dragger._dragging then return end
        local cx, cy = GetCursorPosition()
        local scale = title:GetEffectiveScale()
        cx = cx / scale
        cy = cy / scale
        local dx = cx - dragStartX
        local dy = dragStartY - cy
        local newW = math.max(180, math.min(PANEL_MAX_WIDTH, dragStartW + dx))
        local newH = math.max(HEADER_HEIGHT + 48, math.min(PANEL_MAX_HEIGHT, dragStartH + dy))
        title:SetWidth(newW)
        title:SetHeight(newH)
    end)

    frame = title
    frame.scroll = scroll
    frame.content = content
    frame._dragBar = dragBar
    frame._dragAccent = dragAccent
    frame._dragger = dragger
    frame._widgets = {}
    frame._modKey = mod.key
    frame:SetScript("OnShow", function()
        if MR._refreshUIDirty or frame._needsRefresh then
            MR:RefreshUI()
        end
    end)
    self.detachedFrames[mod.key] = frame
    return frame
end

function MR:HasVisibleDetachedFrames()
    if not self.detachedFrames then
        return false
    end

    for _, frame in pairs(self.detachedFrames) do
        if frame and frame:IsShown() then
            return true
        end
    end

    return false
end

function MR:CanRefreshUIImmediately()
    if self._instanceFramesHidden then
        return false
    end

    if self.frame and self.frame:IsShown() then
        return true
    end

    return self:HasVisibleDetachedFrames()
end

function MR:RefreshVisibleDetachedFrames()
    self.detachedFrames = self.detachedFrames or {}
    local seenDetached = {}
    local allowShowing = not self._instanceFramesHidden and not self:IsManagedWindowsBundleHidden()

    for _, mod in ipairs(MR:GetOrderedModules()) do
        local modVisible = not mod.isVisible or mod:isVisible()
        local detached = MR:IsModuleDetached(mod.key)
        local frame = self.detachedFrames[mod.key]
        local stats = GetModuleStats(self, mod)
        local shownRows = stats and stats.shownRows or 0

        if detached and MR:IsModuleEnabled(mod.key) and modVisible and shownRows > 0 then
            frame = self:EnsureDetachedFrame(mod)
            seenDetached[mod.key] = true

            local savedSize = self:GetDetachedModuleSize(mod.key)
            local alpha = self.db.profile.frameAlpha or 1.0
            frame:SetScale(self.db.profile.scale or 1.0)
            frame:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4] * alpha)
            frame:SetBackdropBorderColor(0.15, 0.15, 0.2, alpha)
            if savedSize and savedSize.width and savedSize.height then
                frame:SetSize(savedSize.width, savedSize.height)
            end
            if frame._dragBar then
                frame._dragBar:SetBackdropColor(0.05, 0.12, 0.22, alpha)
                frame._dragBar:SetBackdropBorderColor(0.10, 0.28, 0.35, alpha)
            end
            if frame._dragAccent then
                frame._dragAccent:SetAlpha(alpha)
            end

            local shouldRefreshFrame = allowShowing or frame:IsShown()
            if shouldRefreshFrame then
                local scrollWidth = frame.scroll and frame.scroll:GetWidth() or (frame:GetWidth() - 8)
                frame.content:SetWidth(math.max(scrollWidth, 1))
                local section = UpdateDetachedSectionWidget(self, frame, mod, math.max(scrollWidth, 1))
                local sectionHeight = section and section:GetHeight() or HEADER_HEIGHT
                frame.content:SetHeight(math.max(sectionHeight, 1))
                if frame.scroll then
                    local maxScroll = math.max(frame.content:GetHeight() - frame.scroll:GetHeight(), 0)
                    if frame.scroll:GetVerticalScroll() > maxScroll then
                        frame.scroll:SetVerticalScroll(maxScroll)
                    end
                end
                if not MR:IsModuleOpen(mod.key) then
                    frame:SetHeight(HEADER_HEIGHT + 12)
                elseif not (savedSize and savedSize.height) then
                    frame:SetHeight(math.max(sectionHeight + 12, HEADER_HEIGHT + 48))
                end
                frame._needsRefresh = nil
            else
                frame._needsRefresh = true
            end

            if allowShowing then
                frame:Show()
            else
                frame:Hide()
            end
        elseif frame then
            frame._needsRefresh = true
            if frame._sectionFrames then
                for _, section in pairs(frame._sectionFrames) do
                    HideMainSectionWidget(section)
                end
            end
            frame:Hide()
        end
    end

    for key, frame in pairs(self.detachedFrames) do
        if not seenDetached[key] then
            frame._needsRefresh = true
            if frame._sectionFrames then
                for _, section in pairs(frame._sectionFrames) do
                    HideMainSectionWidget(section)
                end
            end
            frame:Hide()
        end
    end
end

function MR:RefreshUI()
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self._refreshUIDirty = true
        return
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("refreshUI") then
        self._refreshUIDirty = true
        return
    end

    if not self.frame or not self.content then
        self._refreshUIDirty = true
        return
    end

    if not self:CanRefreshUIImmediately() then
        self._refreshUIDirty = true
        return
    end

    local now = GetTime and GetTime() or 0
    local minRefreshInterval = 0.15

    if self._refreshUIInProgress then
        self._refreshUIPending = true
        return
    end

    if self._lastRefreshUIAt and (now - self._lastRefreshUIAt) < minRefreshInterval then
        self._refreshUIPending = true
        if not self._refreshUITimer then
            local delay = math.max(minRefreshInterval - (now - self._lastRefreshUIAt), 0.01)
            self._refreshUITimer = self:ScheduleTimer(function()
                self._refreshUITimer = nil
                if self._refreshUIPending then
                    self._refreshUIPending = nil
                    self:RefreshUI()
                end
            end, delay)
        end
        return
    end

    self._refreshUIInProgress = true
    self._refreshUIDirty = nil

    RecalcLayout()
    self._moduleStatsCache = BuildModuleStatsCache(self)
    local expansionInfo = GetExpansionDisplayInfo(false)
    local refreshMain = self.frame and self.frame:IsShown()

    if not refreshMain then
        self._mainPanelNeedsRefresh = true
    end

    if refreshMain then
        self._mainPanelNeedsRefresh = nil

        if self.titleText then
            self.titleText:SetText(L["Title"] or "Routine")
        end
        if self.expansionDropdown and self.expansionDropdown.Update then
            self.expansionDropdown:Update()
        end
        ApplyMainFrameLayout(self.frame)
        self.widgets = {}
        self.sectionRegistry = {}
        self._timerRows = {}

        local allDone, allTotal = 0, 0

        local frameW   = MR.db.profile.width or 260
        local usableW  = frameW - 9
        local MIN_COL  = 200
        local numCols  = math.max(1, math.floor(usableW / MIN_COL))
        local colW     = math.floor(usableW / numCols)

        local visibleMods = self._visibleModsBuffer or {}
        self._visibleModsBuffer = visibleMods
        local visibleModCount = 0
        for _, mod in ipairs(MR:GetOrderedModules()) do
            local modVisible = not mod.isVisible or mod:isVisible()
            if MR:IsModuleEnabled(mod.key) and modVisible and not MR:IsModuleDetached(mod.key) then
                local stats = GetModuleStats(self, mod)
                local totalRows = stats and stats.totalRows or 0
                local doneRows = stats and stats.doneRows or 0
                local shownRows = stats and stats.shownRows or 0
                if shownRows > 0 then
                    local h = stats and stats.height or 0
                    visibleModCount = visibleModCount + 1
                    local slot = visibleModCount
                    local entry = visibleMods[slot] or {}
                    entry.mod = mod
                    entry.h = h
                    visibleMods[slot] = entry
                    allTotal = allTotal + shownRows
                    allDone = allDone + math.min(doneRows, shownRows)
                end
            end
        end

        local cols = self._colsBuffer or {}
        self._colsBuffer = cols
        for i = 1, numCols do
            cols[i] = 0
        end
        for i = numCols + 1, #cols do
            cols[i] = nil
        end

        local totalModH = 0
        for i = 1, visibleModCount do
            totalModH = totalModH + visibleMods[i].h
        end

        local modColAssign = self._modColAssignBuffer or {}
        self._modColAssignBuffer = modColAssign
        local modColAssignCount = 0
        local curCol = 1
        for i = 1, visibleModCount do
            local entry = visibleMods[i]
            if curCol < numCols and cols[curCol] >= totalModH / numCols then
                curCol = curCol + 1
            end
            modColAssignCount = modColAssignCount + 1
            local slot = modColAssignCount
            local assign = modColAssign[slot] or {}
            assign.mod = entry.mod
            assign.col = curCol
            assign.yOff = cols[curCol]
            modColAssign[slot] = assign
            cols[curCol] = cols[curCol] + entry.h
        end

        local activeMainSections = self._activeMainSectionsBuffer or {}
        self._activeMainSectionsBuffer = activeMainSections
        for key in pairs(activeMainSections) do
            activeMainSections[key] = nil
        end
        for i = 1, modColAssignCount do
            local assign = modColAssign[i]
            local xOff = (assign.col - 1) * colW
            local section = UpdateMainSectionWidget(self, assign.mod, assign.yOff, xOff, colW, assign.col)
            if section then
                activeMainSections[assign.mod.key] = true
                table.insert(self.widgets, section)
            end
        end

        if self._mainSectionFrames then
            for key, section in pairs(self._mainSectionFrames) do
                if not activeMainSections[key] then
                    HideMainSectionWidget(section)
                end
            end
        end

        for c = 2, numCols do
            local sep = EnsureMainSeparator(self, c - 1)
            sep:SetWidth(1)
            sep:ClearAllPoints()
            sep:SetPoint("TOPLEFT",    self.content, "TOPLEFT",    (c - 1) * colW, 0)
            sep:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", (c - 1) * colW, 0)
            table.insert(self.widgets, sep)
        end
        if self._mainColumnSeparators then
            for index, sep in pairs(self._mainColumnSeparators) do
                if index > (numCols - 1) then
                    sep:Hide()
                end
            end
        end

        self.titleCount:SetText(string.format("%d / %d", allDone, allTotal))
        self.titleCount:SetTextColor(countColor(allDone, allTotal))

        local totalH = 0
        for c = 1, numCols do if cols[c] > totalH then totalH = cols[c] end end

        self.content:SetWidth(usableW)

        self.content:SetHeight(math.max(totalH, 1))
        local userH = MR.db.profile.height or 400
        self.frame:SetHeight(math.max(PANEL_MIN_HEIGHT, math.min(userH, PANEL_MAX_HEIGHT)))

        if self.scroll then
            local maxScroll = math.max(math.max(totalH, 1) - self.scroll:GetHeight(), 0)
            local cur = self.scroll:GetVerticalScroll()
            if cur > maxScroll then
                self.scroll:SetVerticalScroll(maxScroll)
            end
        end

        if self.UpdateScrollBar then self.UpdateScrollBar() end

        if MR.db.profile.minimized then
            StopMainFrameAnimation()
            SetMainFrameChromeVisible(false)
            self.frame:SetHeight(GetMainFrameCollapsedHeight())
            if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
        else
            SetMainFrameChromeVisible(true)
        end
    end

    self:RefreshVisibleDetachedFrames()

    if self.altBoardFrame and self.altBoardFrame:IsShown() and self.RequestWarbandBoardRefresh then
        self:RequestWarbandBoardRefresh(false)
    end

    self._moduleStatsCache = nil
    self._lastRefreshUIAt = GetTime and GetTime() or now
    self._refreshUIInProgress = nil

    if self._refreshUIPending and not self._refreshUITimer then
        self._refreshUIPending = nil
        self._refreshUITimer = self:ScheduleTimer(function()
            self._refreshUITimer = nil
            self:RefreshUI()
        end, minRefreshInterval)
    end

end

local function ReleaseConfigWidgetTree(frame)
    if not frame then
        return
    end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        ReleaseConfigWidgetTree(child)
    end

    if frame.GetObjectType and frame:GetObjectType() == "Button" then
        frame:SetScript("OnClick", nil)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        frame:SetScript("OnMouseDown", nil)
        frame:SetScript("OnMouseUp", nil)
    end

    frame:SetScript("OnUpdate", nil)
    frame:EnableMouse(false)
    frame:Hide()
    frame:SetParent(nil)
end

function MR:ApplySharedMediaSettings()
    if ns.ApplySharedMedia then
        ns.ApplySharedMedia(self.GetActiveMediaSettings and self:GetActiveMediaSettings() or (self.db and self.db.profile))
    end

    RefreshFonts()
    local fontSize = GetFontSize()
    if self.titleText then
        self.titleText:SetFont(FONT_HEADERS, math.max(8, fontSize - 2), GetFontFlags())
    end
    if self.titleCount then
        self.titleCount:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
    end
    if self.warbandBtnText then
        self.warbandBtnText:SetFont(FONT_HEADERS, 9, GetFontFlags())
    end
    if self.customTaskDialog then
        ApplyCustomTaskDialogTheme(self.customTaskDialog)
    end
    if self.customTasksTitleDialog then
        ApplyCustomTasksTitleDialogTheme(self.customTasksTitleDialog)
    end
    if self.expansionDropdown and self.expansionDropdown.ApplyFonts then
        self.expansionDropdown:ApplyFonts()
    end
    if self.altBoardFrame then
        local frame = self.altBoardFrame
        if frame.titleText then
            frame.titleText:SetFont(FONT_HEADERS, math.max(12, fontSize + 2), GetFontFlags())
        end
        if frame.summaryValue then
            frame.summaryValue:SetFont(FONT_HEADERS, math.max(11, fontSize + 1), GetFontFlags())
        end
        if frame.summarySub then
            frame.summarySub:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        end
        if frame.leftLabel then
            frame.leftLabel:SetFont(FONT_ROWS, math.max(9, fontSize), GetFontFlags())
        end
        if frame.showHiddenLabel then
            frame.showHiddenLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        end
        if frame.hideCompletedLabel then
            frame.hideCompletedLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        end
        if frame.heroName then
            frame.heroName:SetFont(FONT_HEADERS, math.max(13, fontSize + 3), GetFontFlags())
        end
        if frame.heroMeta then
            frame.heroMeta:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        end
        if frame.heroStatus then
            frame.heroStatus:SetFont(FONT_ROWS, math.max(10, fontSize), GetFontFlags())
        end
        if frame.expansionDropdown and frame.expansionDropdown.ApplyFonts then
            frame.expansionDropdown:ApplyFonts()
        end
    end
    ApplyTheme()
    local configWasShown = cfgFrame and cfgFrame:IsShown() or false
    if self.frame and ns.RefreshFrameBackground then
        ns.RefreshFrameBackground(self.frame)
    end
    if self._titleBar and ns.RefreshFrameBackground then
        ns.RefreshFrameBackground(self._titleBar)
    end
    if self.ApplyCurrencyBrowserTheme then
        self:ApplyCurrencyBrowserTheme()
    end
    if self.RefreshMainHeaderChrome then
        self:RefreshMainHeaderChrome()
    end
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.02)
    else
        self:RefreshUI()
    end

    if self.RebuildRaresFrame then self:RebuildRaresFrame() end
    if self.RebuildGatheringLocationsFrame then self:RebuildGatheringLocationsFrame() end
    if self.RebuildRenownFrame then self:RebuildRenownFrame() end
    if self.RepopulateRaresConfig then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig then self:RepopulateGatheringConfig() end
    if self.RepopulateRenownConfig then self:RepopulateRenownConfig() end
    if configWasShown and cfgFrame then
        if self.RequestConfigRepopulate then
            self:RequestConfigRepopulate(cfgFrame, 0.08)
        else
            self:PopulateConfigFrame(cfgFrame)
        end
    elseif cfgFrame and cfgFrame:IsShown() then
        if self.RequestConfigRepopulate then
            self:RequestConfigRepopulate(cfgFrame, 0.08)
        else
            self:PopulateConfigFrame(cfgFrame)
        end
    end
end

function MR:IsRowComplete(mod, row, done)
    if mod and (mod.key == "currencies" or mod.key == "pvp_currencies") and not self:IsModuleHideComplete(mod.key) then
        return false
    end
    if row.completeFunc then
        return row.completeFunc(done, row, mod) == true
    end
    return row.max and not row.noMax and done >= row.max
end

BuildModuleStatsCache = function(self)
    local cache = self._moduleStatsCache or {}
    local seen = self._moduleStatsSeen or {}
    self._moduleStatsSeen = seen

    for _, mod in ipairs(MR:GetOrderedModules()) do
        local hideComplete = MR:IsModuleHideComplete(mod.key)
        local isOpen = MR:IsModuleOpen(mod.key)
        local totalRows, doneRows, shownRows = 0, 0, 0
        local height = HEADER_HEIGHT + 1 + SECTION_GAP

        for _, row in ipairs(mod.rows) do
            local rowVisible = not row.isVisible or row.isVisible()
            if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
                local done = MR:GetProgress(mod.key, row.key)
                local countsForTotals = not row.control
                local isComplete = countsForTotals and self:IsRowComplete(mod, row, done) or false
                if countsForTotals then
                    totalRows = totalRows + 1
                    if isComplete then
                        doneRows = doneRows + 1
                    end
                end

                if row.control or not (hideComplete and isComplete) then
                    shownRows = shownRows + 1
                    if isOpen then
                        height = height + ROW_HEIGHT
                    end
                end
            end
        end

        if shownRows == 0 then
            height = 0
        end

        local entry = cache[mod.key] or {}
        entry.doneRows = doneRows
        entry.height = height
        entry.hideComplete = hideComplete
        entry.isOpen = isOpen
        entry.shownRows = shownRows
        entry.totalRows = totalRows
        cache[mod.key] = entry
        seen[mod.key] = true
    end

    for key in pairs(cache) do
        if not seen[key] then
            cache[key] = nil
        end
        seen[key] = nil
    end

    return cache
end

GetModuleStats = function(self, mod)
    local cache = self._moduleStatsCache
    if cache and cache[mod.key] then
        return cache[mod.key]
    end

    local fallback = BuildModuleStatsCache(self)
    return fallback[mod.key]
end

function MR:MeasureSection(mod)
    local stats = GetModuleStats(self, mod)
    return stats and stats.height or 0
end

function MR:GetModuleRowStats(mod)
    local stats = GetModuleStats(self, mod)
    if not stats then
        return 0, 0, 0
    end

    return stats.totalRows, stats.doneRows, stats.shownRows
end

function MR:BuildSection(mod, yOff, xOff, colW, col, parent, widgetBucket, opts)
    parent = parent or self.content
    widgetBucket = widgetBucket or self.widgets
    opts = opts or {}
    local transparent = IsMainTextOnlyMode()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local showSectionHeaders = ShouldShowSectionHeaders()
    local textOnlyHeaderAlpha = showSectionHeaders and GetTextOnlyHeaderAlpha() or 0
    local headerAlpha = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 0.90 or 0) * frameAlpha)
    local dividerAlpha = transparent and (0.50 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.09 or 0) * frameAlpha)
    local showSoftHeaders = transparent and textOnlyHeaderAlpha > 0
    local showIcons = ShouldShowIcons()
    local stats = GetModuleStats(self, mod)
    local isOpen = stats and stats.isOpen
    local secTotal = stats and stats.totalRows or 0
    local secDone = stats and stats.doneRows or 0
    local shownRows = stats and stats.shownRows or 0
    if shownRows == 0 then
        return yOff
    end
    local allDone = (secTotal > 0) and (secDone == secTotal)

    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff + 3, -yOff)
    card:SetSize(math.max(colW - 6, 1), math.max((stats and stats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1))
    card:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(card) end
    if transparent then
        card:SetBackdropColor(0, 0, 0, 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
    else
        card:SetBackdropColor(0.02, 0.03, 0.05, 0.94 * frameAlpha)
        card:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.95 * frameAlpha)
    end
    table.insert(widgetBucket, card)

    local cardGlow = card:CreateTexture(nil, "BACKGROUND")
    cardGlow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    cardGlow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    cardGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    cardGlow:SetColorTexture(0.12, 0.14, 0.18, transparent and 0 or (0.10 * frameAlpha))

    local hdrFrame = CreateFrame("Frame", nil, card)
    hdrFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    hdrFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    hdrFrame:SetHeight(HEADER_HEIGHT)
    hdrFrame:EnableMouse(true)
    if opts.detached then
        hdrFrame:RegisterForDrag("LeftButton")
    end

    local hdrBg = hdrFrame:CreateTexture(nil, "BACKGROUND")
    hdrBg:SetAllPoints()
    local customHeaderBg = MR.GetHeaderBackgroundColor and MR:GetHeaderBackgroundColor(mod.key) or nil
    local hdrR, hdrG, hdrB = 0.08, 0.09, 0.12
    if customHeaderBg then
        hdrR, hdrG, hdrB = hex(customHeaderBg)
    end
    hdrBg:SetColorTexture(hdrR, hdrG, hdrB, headerAlpha)

    local hdrHover = hdrFrame:CreateTexture(nil, "BORDER")
    hdrHover:SetAllPoints()
    hdrHover:SetColorTexture(1, 1, 1, 0)

    local explicitColor = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local customColor = MR:GetHeaderColor(mod.key)
    local headerColor = customColor or mod.labelColor or "#ffffff"
    local lr,lg,lb = hex(headerColor)
    local accentA = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 1 or 0) * frameAlpha)
    local accentR, accentG, accentB = lr, lg, lb
    if allDone then
        accentR, accentG, accentB = COL.complete[1], COL.complete[2], COL.complete[3]
    end

    local iconPlate = CreateFrame("Frame", nil, hdrFrame, "BackdropTemplate")
    iconPlate:SetSize(math.max(HEADER_HEIGHT - 6, 12), math.max(HEADER_HEIGHT - 6, 12))
    iconPlate:SetPoint("LEFT", hdrFrame, "LEFT", 4, 0)
    iconPlate:SetBackdrop(MakeBackdrop())
    local iconPlateBgAlpha = transparent and (showSoftHeaders and (0.16 * accentA) or 0) or ((showSectionHeaders and 0.16 or 0) * frameAlpha)
    local iconPlateBorderAlpha = transparent and (showSoftHeaders and (0.50 * accentA) or 0) or ((showSectionHeaders and 0.50 or 0) * frameAlpha)
    iconPlate:SetBackdropColor(accentR, accentG, accentB, iconPlateBgAlpha)
    iconPlate:SetBackdropBorderColor(accentR, accentG, accentB, iconPlateBorderAlpha)

    local iconInfo = showIcons and ShouldShowModuleHeaderIcon(mod.key) and GetModuleIconInfo(mod) or nil
    local icon = hdrFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(math.max(HEADER_HEIGHT - 12, 9), math.max(HEADER_HEIGHT - 12, 9))
    icon:SetPoint("CENTER", iconPlate, "CENTER", 0, 0)
    local hasHeaderIcon = ApplyIconToTexture(icon, iconInfo, { 0.14, 0.86, 0.14, 0.86 })
    iconPlate:SetShown(hasHeaderIcon and (showIcons or showSectionHeaders))

    local lbl = hdrFrame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
    lbl:ClearAllPoints()
    if hasHeaderIcon then
        lbl:SetPoint("LEFT", iconPlate, "RIGHT", 6, 0)
    else
        lbl:SetPoint("LEFT", hdrFrame, "LEFT", 9, 0)
    end
    lbl:SetJustifyH("LEFT")
    if lbl.SetWordWrap then
        lbl:SetWordWrap(false)
    end
    lbl:SetText((allDone and not explicitColor)
        and WC("00ff96", mod.label)
        or  WC(headerColor:gsub("#",""), mod.label))

    local cnt = hdrFrame:CreateFontString(nil, "OVERLAY")
    cnt:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    cnt:SetPoint("RIGHT", hdrFrame, "RIGHT", -18, 0)
    cnt:SetText(string.format(L["%d / %d complete"], secDone, secTotal))
    cnt:SetTextColor(countColor(secDone, secTotal))
    cnt:SetJustifyH("RIGHT")
    lbl:SetPoint("RIGHT", cnt, "LEFT", -8, 0)

    local arrow = hdrFrame:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(10, 10)
    arrow:SetPoint("RIGHT", hdrFrame, "RIGHT", -6, 0)
    if isOpen then
        arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    else
        arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    end
    arrow:SetVertexColor(0.45, 0.45, 0.45)

    hdrFrame:EnableMouse(true)
    hdrFrame:SetScript("OnMouseDown", function(_, button)
        if opts.detached and button == "LeftButton" then
            hdrFrame._pressed = true
            hdrFrame._dragged = false
        end
    end)
    hdrFrame:SetScript("OnDragStart", function()
        if not opts.detached or MR.db.profile.locked then return end
        hdrFrame._dragged = true
        local host = GetMovableHostFrame(parent)
        if host then
            host:StartMoving()
        end
    end)
    hdrFrame:SetScript("OnDragStop", function()
        if not opts.detached then return end
        local host = GetMovableHostFrame(parent)
        if host then
            host:StopMovingOrSizing()
            local pt, _, rp, x, y = host:GetPoint()
            MR:SetDetachedModulePosition(mod.key, pt, rp, x, y)
        end
    end)
    hdrFrame:SetScript("OnMouseUp", function(_, button)
        if opts.detached and button == "LeftButton" and hdrFrame._dragged then
            hdrFrame._pressed = false
            hdrFrame._dragged = false
            return
        end
        if mod.key == "custom_tasks" and button == "RightButton" and IsShiftKeyDown() then
            if MR.ShowCustomTasksTitleDialog then
                MR:ShowCustomTasksTitleDialog()
            end
            hdrFrame._pressed = false
            hdrFrame._dragged = false
            return
        end
        if button == "LeftButton" then
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            if MR.RequestUIRefresh then
                MR:RequestUIRefresh(0.04)
            else
                MR:RefreshUI()
            end
        elseif button == "RightButton" then
            MR:SetModuleDetached(mod.key, not opts.detached)
            if MR.RequestUIRefresh then
                MR:RequestUIRefresh(0.04)
            else
                MR:RefreshUI()
            end
        end
        hdrFrame._pressed = false
    end)
    hdrFrame:SetScript("OnEnter", function()
        hdrHover:SetColorTexture(1, 1, 1, transparent and (0.10 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.05 or 0) * frameAlpha))
        GameTooltip:SetOwner(hdrFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(mod.label, 1, 1, 1)
        GameTooltip:AddLine(L["Tooltip_ExpandCollapse"], 0.5, 0.5, 0.5)
        GameTooltip:AddLine(opts.detached and "Right-click to dock back" or "Right-click to detach", 0.5, 0.8, 1)
        if mod.key == "custom_tasks" then
            GameTooltip:AddLine("Shift-right-click to rename this header.", 0.85, 0.82, 0.45, true)
        end
        GameTooltip:Show()
    end)
    hdrFrame:SetScript("OnLeave", function()
        hdrHover:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
    end)

    table.insert(widgetBucket, hdrFrame)
    if widgetBucket == self.widgets then
        table.insert(self.sectionRegistry, { frame = card, modKey = mod.key, col = col or 1, yOff = yOff })
    end

    local localY = HEADER_HEIGHT

    local div = CreateFrame("Frame", nil, card, "BackdropTemplate")
    div:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -localY)
    div:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, -localY)
    div:SetHeight(1)
    div:SetBackdrop(MakeBackdrop(false))
    div:SetBackdropColor(1, 1, 1, dividerAlpha)
    table.insert(widgetBucket, div)

    if isOpen then
        localY = localY + 1
        local hideComplete = stats and stats.hideComplete
        for _, row in ipairs(mod.rows) do
            local rowVisible = not row.isVisible or row.isVisible()
            if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
                local done       = MR:GetProgress(mod.key, row.key)
                local isComplete = self:IsRowComplete(mod, row, done)
                if row.control or not (hideComplete and isComplete) then
                    localY = self:BuildRow(mod, row, done, localY, false, 0, card:GetWidth(), card, widgetBucket)
                end
            end
        end
    end

    if widgetBucket == self.widgets then
        self.sectionRegistry[#self.sectionRegistry].bottom = yOff + (stats and stats.height or 0)
    end

    return yOff + (stats and stats.height or 0)
end

function MR:BuildRow(mod, row, done, yOff, collapsed, xOff, colW, parent, widgetBucket)
    xOff = xOff or 0
    colW = colW or ((MR.db.profile.width or 260) - 13)
    parent = parent or self.content
    widgetBucket = widgetBucket or self.widgets
    local transparent = IsMainTextOnlyMode()
    local showIcons = ShouldShowIcons()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local isAutoTracked = row.autoTracked
        or ((row.questIds ~= nil) and not row.allowManualQuestClicks)
        or (row.encounterIds ~= nil)
        or (row.liveKey ~= nil)
        or (row.spellId ~= nil)
        or (row.currencyId ~= nil)
        or (row.itemId ~= nil)
    local hasWaypoint   = row.zone and row.x and row.y
    local isComplete    = self:IsRowComplete(mod, row, done)
    local GHOST_H       = 8
    local rowH          = collapsed and GHOST_H or ROW_HEIGHT

    local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, -yOff)
    rowFrame:SetSize(colW, rowH)
    rowFrame:EnableMouse(true)

    if row.sectionHeader then
        local headerBg = rowFrame:CreateTexture(nil, "BACKGROUND")
        headerBg:SetAllPoints()
        if transparent then
            headerBg:SetColorTexture(1, 1, 1, 0)
        else
            headerBg:SetColorTexture(0.06, 0.08, 0.13, 0.92 * frameAlpha)
        end

        local headerText = rowFrame:CreateFontString(nil, "OVERLAY")
        SetFontForText(headerText, row.label, math.max(8, GetFontSize() - 1), GetFontFlags())
        headerText:SetPoint("LEFT", rowFrame, "LEFT", 8, 0)
        headerText:SetPoint("RIGHT", rowFrame, "RIGHT", -84, 0)
        headerText:SetJustifyH("LEFT")
        headerText:SetText(row.label)
        headerText:SetTextColor(0.82, 0.66, 0.98)

        local headerActionButton
        if ((row.headerActionText and row.headerActionText ~= "") or row.headerActionStyle == "visibility") and row.onHeaderActionClick then
            headerActionButton = CreateFrame("Button", nil, rowFrame, "BackdropTemplate")
            headerActionButton:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
            if row.headerActionStyle == "visibility" then
                headerActionButton:SetSize(14, 14)
                headerActionButton:SetBackdrop(MakeBackdrop())
                headerActionButton:SetBackdropColor(0.05, 0.10, 0.18, 1)
                headerActionButton:SetBackdropBorderColor(
                    row.headerActionVisible and 0.15 or 0.35,
                    row.headerActionVisible and 0.32 or 0.12,
                    row.headerActionVisible and 0.38 or 0.12,
                    1
                )

                local actionText = headerActionButton:CreateFontString(nil, "OVERLAY")
                actionText:SetFont(FONT_ROWS, 9, GetFontFlags())
                actionText:SetPoint("CENTER", headerActionButton, "CENTER", 0, 0)
                actionText:SetJustifyH("CENTER")
                actionText:SetText(row.headerActionVisible and "o" or "-")
                actionText:SetTextColor(
                    row.headerActionVisible and 0.25 or 0.55,
                    row.headerActionVisible and 0.85 or 0.25,
                    row.headerActionVisible and 0.70 or 0.25
                )
            else
                headerActionButton:SetSize(26, rowH)

                local actionText = headerActionButton:CreateFontString(nil, "OVERLAY")
                actionText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                actionText:SetPoint("CENTER", headerActionButton, "CENTER", 0, 0)
                actionText:SetJustifyH("CENTER")
                actionText:SetText(row.headerActionText)
                if row.headerActionColor then
                    actionText:SetTextColor(row.headerActionColor[1], row.headerActionColor[2], row.headerActionColor[3])
                else
                    actionText:SetTextColor(0.92, 0.78, 0.24)
                end
            end

            headerActionButton:SetScript("OnClick", function()
                row.onHeaderActionClick(row, mod, rowFrame)
            end)
            headerActionButton:SetScript("OnEnter", function()
                if row.headerActionTooltip and row.headerActionTooltip ~= "" then
                    GameTooltip:SetOwner(headerActionButton, "ANCHOR_RIGHT")
                    GameTooltip:SetText(row.headerActionTooltip, 1, 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end)
            headerActionButton:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end

        if row.countText and row.countText ~= "" then
            local countText = rowFrame:CreateFontString(nil, "OVERLAY")
            countText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
            if headerActionButton then
                countText:SetPoint("RIGHT", headerActionButton, "LEFT", -8, 0)
            else
                countText:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
            end
            countText:SetJustifyH("RIGHT")
            countText:SetText(row.countText)
            if row.countColor then
                countText:SetTextColor(row.countColor[1], row.countColor[2], row.countColor[3])
            else
                countText:SetTextColor(0.74, 0.80, 0.88)
            end
        end

        rowFrame:SetScript("OnEnter", function()
            if row.note then
                GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
                GameTooltip:SetText(row.label, 1, 1, 1)
                GameTooltip:AddLine(row.note, 0.70, 0.70, 0.76, true)
                GameTooltip:Show()
            end
        end)
        rowFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        table.insert(widgetBucket, rowFrame)
        return yOff + rowH
    end

    if collapsed then
        local line = rowFrame:CreateTexture(nil, "ARTWORK")
        line:SetPoint("LEFT",  rowFrame, "LEFT",  PADDING + 10, 0)
        line:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
        line:SetHeight(1)
        line:SetColorTexture(0.25, 0.25, 0.25, 0.5)

        local dot = rowFrame:CreateTexture(nil, "ARTWORK")
        dot:SetSize(4, 4)
        dot:SetPoint("LEFT", rowFrame, "LEFT", PADDING, 0)
        dot:SetColorTexture(0.25, 0.55, 0.25, 0.6)

        rowFrame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Tooltip_DonePrefix"] .. row.label, 0.4, 0.85, 0.4, 1, true)
            GameTooltip:AddLine(L["Tooltip_CompletedWeek"], 0.3, 0.6, 0.3)
            GameTooltip:Show()
        end)
        rowFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(widgetBucket, rowFrame)
        return yOff + rowH
    end

    local hover = rowFrame:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0)

    local rowShade = rowFrame:CreateTexture(nil, "BORDER")
    rowShade:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, -1)
    rowShade:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, 0)
    if isComplete and not transparent then
        rowShade:SetColorTexture(0.12, 0.16, 0.12, 0.18 * frameAlpha)
    else
        rowShade:SetColorTexture(0, 0, 0, 0)
    end

    local separator = rowFrame:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", 12, 0)
    separator:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -12, 0)
    separator:SetHeight(1)
    separator:SetColorTexture(1, 1, 1, transparent and 0 or (0.06 * frameAlpha))

    rowFrame:SetScript("OnEnter", function()
        hover:SetColorTexture(1, 1, 1, transparent and 0 or (0.04 * frameAlpha))
        if row.currencyId and not row.noBlizzardTooltip then
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetCurrencyByID(row.currencyId)
            GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
            if row.tooltipFunc then
                row.tooltipFunc(GameTooltip)
            end
            GameTooltip:Show()
        elseif row.itemId and not row.noBlizzardTooltip then
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            if GameTooltip.SetItemByID then
                GameTooltip:SetItemByID(row.itemId)
            else
                GameTooltip:SetHyperlink("item:" .. row.itemId)
            end
            GameTooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
            GameTooltip:Show()
        else
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
            if row.note then GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true) end
            if hasWaypoint then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(string.format(L["Gathering_Coords"], row.x, row.y), 0.7, 1, 0.9)
                GameTooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
            end
            if row.tooltipFunc then
                row.tooltipFunc(GameTooltip)
            end
            if row.noDefaultTooltipHint then
            elseif row.liveKey or row.autoTracked or (row.currencyId and row.noBlizzardTooltip) then
                GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
            elseif row.questIds then
                GameTooltip:AddLine(L["Tooltip_AutoQuest"], 0.4, 1, 0.6)
            elseif row.spellId or row.itemId then
                GameTooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
            elseif not hasWaypoint then
                GameTooltip:AddLine(L["Tooltip_ManualClick"], 0.5, 0.5, 0.5)
            end
            GameTooltip:Show()
        end
    end)
    rowFrame:SetScript("OnLeave", function()
        hover:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
    end)

    rowFrame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and row.onLeftClick then
            local handled = row.onLeftClick(row, mod, done, rowFrame)
            if handled ~= false then
                return
            end
        elseif button == "RightButton" and row.onRightClick then
            local handled = row.onRightClick(row, mod, done, rowFrame)
            if handled ~= false then
                return
            end
        end

        if button == "LeftButton" and hasWaypoint then
            local ok, source = MR:SetWaypoint(row)
            if ok then
                print(string.format(L["Waypoint_Set"], source, row.waypointTitle or row.label, row.x, row.y))
            else
                print(L["Waypoint_Unavailable"])
            end
        elseif not isAutoTracked and button == "LeftButton" then
                MR:BumpProgress(mod.key, row.key, 1, row.max)
        elseif not isAutoTracked and button == "RightButton" then
            MR:BumpProgress(mod.key, row.key, -1, row.max)
        end
    end)

    local statusObjectType = ((isAutoTracked and not row.noMax) or row.toggleStatus) and "Button" or "Frame"
    local statusBtn = CreateFrame(statusObjectType, nil, rowFrame, "BackdropTemplate")
    statusBtn:SetSize(14, 14)
    statusBtn:SetPoint("LEFT", rowFrame, "LEFT", PADDING + 2, 0)
    statusBtn:SetBackdrop(MakeBackdrop())

    local statusFill = statusBtn:CreateTexture(nil, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBtn, "TOPLEFT", 2, -2)
    statusFill:SetPoint("BOTTOMRIGHT", statusBtn, "BOTTOMRIGHT", -2, 2)

    local statusCheck = statusBtn:CreateFontString(nil, "OVERLAY")
    statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
    statusCheck:SetPoint("CENTER", statusBtn, "CENTER", 0, 1)
    statusCheck:SetText("x")

    local function RefreshStatusDisplay()
        local mo = MR:GetManualOverride(mod.key, row.key)
        local forcedComplete = row.max and mo >= row.max
        local activeDone = forcedComplete and row.max or done

        if transparent then
            statusBtn:SetBackdropColor(0, 0, 0, 0)
        else
            statusBtn:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * frameAlpha)
        end
        if forcedComplete then
            statusBtn:SetBackdropBorderColor(transparent and 0 or 0.88, transparent and 0 or 0.74, transparent and 0 or 0.22, transparent and 0 or frameAlpha)
            statusFill:SetColorTexture(0.88, 0.74, 0.22, transparent and 0 or (0.85 * frameAlpha))
            statusCheck:SetTextColor(0.10, 0.08, 0.02, transparent and 0 or 1)
            if transparent then statusCheck:Hide() else statusCheck:Show() end
        elseif isComplete then
            statusBtn:SetBackdropBorderColor(transparent and 0 or 0.24, transparent and 0 or 0.76, transparent and 0 or 0.46, transparent and 0 or frameAlpha)
            statusFill:SetColorTexture(0.20, 0.72, 0.42, transparent and 0 or (0.85 * frameAlpha))
            statusCheck:SetTextColor(0.03, 0.08, 0.04, transparent and 0 or 1)
            if transparent then statusCheck:Hide() else statusCheck:Show() end
        elseif row.max and activeDone > 0 then
            statusBtn:SetBackdropBorderColor(transparent and 0 or 0.62, transparent and 0 or 0.52, transparent and 0 or 0.22, transparent and 0 or (0.95 * frameAlpha))
            statusFill:SetColorTexture(0.78, 0.62, 0.22, transparent and 0 or (0.70 * frameAlpha))
            statusCheck:Hide()
        else
            statusBtn:SetBackdropBorderColor(transparent and 0 or 0.24, transparent and 0 or 0.28, transparent and 0 or 0.34, transparent and 0 or (0.95 * frameAlpha))
            statusFill:SetColorTexture(0.09, 0.10, 0.14, transparent and 0 or (0.70 * frameAlpha))
            statusCheck:Hide()
        end
    end
    RefreshStatusDisplay()
    if row.hideStatus then
        statusBtn:Hide()
    end

    if statusBtn:GetObjectType() == "Button" then
        statusBtn:SetScript("OnClick", function()
            if row.toggleStatus and MR.ToggleCustomTask and mod.key == "custom_tasks" then
                MR:ToggleCustomTask(tonumber((row.key or ""):match("task_(%d+)")))
                return
            end
            local cur = MR:GetManualOverride(mod.key, row.key)
            MR:SetManualOverride(mod.key, row.key, cur >= row.max and 0 or row.max, row.max)
        end)
        statusBtn:SetScript("OnEnter", function()
            hover:SetColorTexture(1, 1, 1, transparent and 0 or (0.04 * frameAlpha))
            local mo = row.toggleStatus and MR:GetProgress(mod.key, row.key) or MR:GetManualOverride(mod.key, row.key)
            GameTooltip:SetOwner(statusBtn, "ANCHOR_RIGHT")
            GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
            if row.note then GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true) end
            GameTooltip:AddLine(" ")
            if mo >= row.max then
                GameTooltip:AddLine(L["Tooltip_ManualDot_Active"], 1, 0.85, 0.1, true)
            else
                GameTooltip:AddLine(L["Tooltip_ManualDot_Hint"], 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()
        end)
        statusBtn:SetScript("OnLeave", function()
            hover:SetColorTexture(1, 1, 1, 0)
            GameTooltip:Hide()
        end)
    end

    local isCurrencyModule = mod and (mod.key == "currencies" or mod.key == "pvp_currencies")
    local rowIconInfo = nil
    local countIconInfo = (showIcons and isCurrencyModule and row.currencyId) and GetRowIconInfo(mod, row) or nil
    local iconSize = math.max(ROW_HEIGHT - 8, 12)
    local rowIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    rowIcon:SetSize(iconSize, iconSize)
    rowIcon:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
    local hasRowIcon = ApplyIconToTexture(rowIcon, rowIconInfo)
    if isComplete and hasRowIcon then
        rowIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    end
    local countIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    countIcon:SetSize(iconSize, iconSize)
    countIcon:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    local hasCountIcon = ApplyIconToTexture(countIcon, countIconInfo)
    if isComplete and hasCountIcon then
        countIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    end
    local hasNumericMax = type(row.max) == "number" and row.max > 0
    local isCurrencyRow = row.currencyId and hasNumericMax and not row.noMax
    local hasCoordText  = hasWaypoint and not row.hideCoordText
    local lblRightOff   = isCurrencyRow and -96 or (hasCoordText and -128 or -52)

    local lbl = rowFrame:CreateFontString(nil, "OVERLAY")
    if lbl.SetWordWrap then
        lbl:SetWordWrap(false)
    end
    if lbl.SetNonSpaceWrap then
        lbl:SetNonSpaceWrap(false)
    end
    if lbl.SetShadowOffset then
        lbl:SetShadowOffset(0, 0)
    end
    SetFontForText(lbl, CleanLabelText(row.label), GetFontSize(), GetFontFlags())
    if hasRowIcon then
        lbl:SetPoint("LEFT", rowIcon, "RIGHT", 8, 0)
    else
        lbl:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
    end
    lbl:SetPoint("RIGHT", rowFrame, "RIGHT", lblRightOff, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")

    local rowCustom    = MR:GetRowColor(mod.key, row.key)
    local headerCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local inlineColor  = ExtractInlineLabelColor(row.label)
    local effectiveColor = rowCustom or headerCustom or inlineColor
    local cleanLabel = CleanLabelText(row.label)

    if isComplete then
        lbl:SetText(cleanLabel)
        if effectiveColor then
            local cr, cg, cb = hex(effectiveColor)
            lbl:SetTextColor(cr * 0.45, cg * 0.45, cb * 0.45)
        else
            lbl:SetTextColor(0.38, 0.38, 0.38)
        end
    elseif effectiveColor then
        lbl:SetText(cleanLabel)
        lbl:SetTextColor(hex(effectiveColor))
    else
        lbl:SetText(cleanLabel)
        lbl:SetTextColor(1, 1, 1)
    end

    local countFS = rowFrame:CreateFontString(nil, "OVERLAY")
    countFS:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
    if hasCountIcon then
        countFS:SetPoint("RIGHT", countIcon, "LEFT", -4, 0)
    else
        countFS:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    end
    countFS:SetJustifyH("RIGHT")
    if countFS.SetWordWrap then
        countFS:SetWordWrap(false)
    end

    if row.countText then
        countFS:SetText(row.countText)
        if row.countColor then
            countFS:SetTextColor(row.countColor[1], row.countColor[2], row.countColor[3])
        else
            countFS:SetTextColor(0.8, 0.8, 0.8)
        end

        if not isCurrencyRow and not hasCoordText then
            local reservedWidth
            if type(row.countWidth) == "number" and row.countWidth > 0 then
                reservedWidth = row.countWidth
            else
                reservedWidth = math.min(
                    math.max(math.floor((countFS:GetStringWidth() or 0) + 8), 64),
                    math.floor(math.max(rowFrame:GetWidth() * 0.5, 64))
                )
            end
            countFS:SetWidth(reservedWidth)
            lbl:ClearAllPoints()
            if hasRowIcon then
                lbl:SetPoint("LEFT", rowIcon, "RIGHT", 8, 0)
            else
                lbl:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
            end
            lbl:SetPoint("RIGHT", countFS, "LEFT", -8, 0)
        end
    elseif isCurrencyRow then
        local mdb    = MR.db and MR.db.char.progress[mod.key]
        local wallet = (mdb and mdb[row.key .. "_wallet"]) or done

        countFS:SetText(string.format("%d/%d", done, row.max))
        countFS:SetTextColor(countColor(done, row.max))

        local walletFS = rowFrame:CreateFontString(nil, "OVERLAY")
        walletFS:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
        walletFS:SetPoint("RIGHT", countFS, "LEFT", -5, 0)
        walletFS:SetJustifyH("RIGHT")
        walletFS:SetText(string.format("|cffaaaaaa(%d)|r", wallet))
        lbl:ClearAllPoints()
        lbl:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
        lbl:SetPoint("RIGHT", walletFS, "LEFT", -8, 0)
    else
        countFS:SetText((row.noMax or not hasNumericMax) and tostring(done) or string.format("%d / %d", done, row.max))
        if row.noMax or not hasNumericMax then
            countFS:SetTextColor(0.8, 0.8, 0.8)
        else
            countFS:SetTextColor(countColor(done, row.max))
        end
        if hasCountIcon and row.currencyId then
            lbl:ClearAllPoints()
            lbl:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
            lbl:SetPoint("RIGHT", countFS, "LEFT", -8, 0)
        end
    end

    if hasCoordText then
        local coordsFS = rowFrame:CreateFontString(nil, "OVERLAY")
        coordsFS:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
        coordsFS:SetPoint("RIGHT", countFS, "LEFT", -8, 0)
        coordsFS:SetJustifyH("RIGHT")
        coordsFS:SetText(string.format("%.2f, %.2f", row.x, row.y))
        if isComplete then
            coordsFS:SetTextColor(0.4, 0.4, 0.4, 0.6)
        else
            coordsFS:SetTextColor(0.65, 0.9, 1, 0.95)
        end
    end

    if row.vaultLabel then
        local vl = rowFrame:CreateFontString(nil, "OVERLAY")
        vl:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
        vl:SetPoint("RIGHT", countFS, "LEFT", -4, 0)
        vl:SetText(row.vaultLabel)
        vl:SetTextColor(hex(row.vaultColor or "#ffffff"))
    end

    if row.timerEpoch and not isComplete and not collapsed then
        local function FormatMMSS(s)
            return string.format("%d:%02d", math.floor(s / 60), s % 60)
        end
        local function UpdateTimer()
            local now    = GetServerTime()
            local offset = (now - row.timerEpoch) % row.timerInterval
            if offset < row.timerDuration then
                local rem = row.timerDuration - offset
                countFS:SetText(L["Timer_Live"] .. FormatMMSS(rem))
                countFS:SetTextColor(0.25, 0.88, 0.50, 1)
            else
                local rem = row.timerInterval - offset
                countFS:SetText(L["Timer_Next"] .. FormatMMSS(rem))
                countFS:SetTextColor(0.55, 0.55, 0.55, 1)
            end
        end
        UpdateTimer()
        rowFrame._timerUpdate = UpdateTimer
        table.insert(MR._timerRows, rowFrame)
    end

    table.insert(widgetBucket, rowFrame)
    return yOff + rowH
end

function MR:ToggleConfig()
    if cfgFrame and cfgFrame:IsShown() then cfgFrame:Hide() return end
    if not cfgFrame then cfgFrame = self:BuildConfigFrame() end
    self:PopulateConfigFrame(cfgFrame)
    cfgFrame:Show()
end

function MR:IsConfigShown()
    return cfgFrame and cfgFrame:IsShown() or false
end

function MR:EnsureConfigShown()
    if not cfgFrame then
        cfgFrame = self:BuildConfigFrame()
    end
    self:PopulateConfigFrame(cfgFrame)
    cfgFrame:Show()
end

function MR:HideConfig()
    if cfgFrame then cfgFrame:Hide() end
end

function MR:BuildConfigFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(292)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(f) end
    f:SetBackdropColor(0.03, 0.06, 0.12, 0.98)
    f:SetBackdropBorderColor(0.4, 0.28, 0, 1)
    f:Hide()
    if MR.frame then
        f:SetPoint("TOPLEFT", MR.frame, "TOPRIGHT", 4, 0)
    else
        f:SetPoint("CENTER")
    end

    local tbar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    tbar:SetPoint("TOPLEFT")
    tbar:SetPoint("TOPRIGHT")
    tbar:SetHeight(22)
    tbar:SetBackdrop(MakeBackdrop(false))
    if ns.HookBackdropFrame then ns.HookBackdropFrame(tbar) end
    tbar:SetBackdropColor(0.06, 0.10, 0.20, 1)
    tbar:EnableMouse(true)
    tbar:RegisterForDrag("LeftButton")
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(FONT_HEADERS, 11, GetFontFlags())
    ttitle:SetText(L["Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    f.titleText = ttitle
    f.titleBar = tbar

    local closeBtn = CloseButton(tbar, function() f:Hide() end)

    return f
end

function MR:PopulateConfigFrame(f)
    if f.body then
        ReleaseConfigWidgetTree(f.body)
        f.body = nil
    end

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    body:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.body = body

    local yOff = -26
    local cfgFs = GetFontSize()
    local contentW = (f:GetWidth() or 292) - 16
    local activePage = MR._cfgPage or "windows"

    if activePage ~= "windows" and activePage ~= "layout" and activePage ~= "modules" and activePage ~= "reset" then
        activePage = "windows"
        MR._cfgPage = activePage
    end

    local function Gap(h)          yOff = OptionsGap(body, yOff, h) end
    local function Divider()       yOff = OptionsDivider(body, yOff, 4) end
    local function SectionLabel(t) yOff = OptionsSectionLabel(body, yOff, t, 8, cfgFs) end
    local function Checkbox(label, getVal, setVal, color)
        local r, g, b
        if color then r, g, b = hex(color) end
        yOff = OptionsCheckbox(body, yOff, label, getVal, setVal, r, g, b, 4, nil, cfgFs)
    end
    local function Btn(label, onClick) yOff = OptionsBtn(body, yOff, label, onClick, math.max(192, contentW), 8, cfgFs) end
    local function ChoiceDropdown(label, choices, getVal, setVal, getResetValue)
        local current = getVal()
        local currentIndex = 1
        for index, choice in ipairs(choices) do
            if choice.value == current then
                currentIndex = index
                break
            end
        end

        local caption = body:CreateFontString(nil, "OVERLAY")
        caption:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
        caption:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        caption:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
        caption:SetJustifyH("LEFT")
        caption:SetWordWrap(false)
        caption:SetText("|cff888888" .. label .. "|r")

        yOff = yOff - 14

        local row = CreateFrame("Frame", nil, body)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        row:SetSize(contentW, 26)

        local measure = row:CreateFontString(nil, "OVERLAY")
        measure:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
        local widestLabel = 0
        for _, choice in ipairs(choices) do
            measure:SetText(choice.label or "")
            widestLabel = math.max(widestLabel, measure:GetStringWidth() or 0)
        end
        measure:Hide()

        local valueBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        valueBtn:SetSize(math.max(170, contentW - 28), 20)
        valueBtn:SetPoint("LEFT", row, "LEFT", 0, 0)
        valueBtn:SetBackdrop(MakeBackdrop())
        valueBtn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
        valueBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

        local valueText = valueBtn:CreateFontString(nil, "OVERLAY")
        valueText:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
        valueText:SetPoint("LEFT", valueBtn, "LEFT", 8, 1)
        valueText:SetPoint("RIGHT", valueBtn, "RIGHT", -22, 1)
        valueText:SetJustifyH("LEFT")
        valueText:SetWordWrap(false)
        valueText:SetTextColor(0.76, 0.97, 0.94)

        local caret = valueBtn:CreateFontString(nil, "OVERLAY")
        caret:SetFont(FONT_HEADERS, 10, GetFontFlags())
        caret:SetPoint("RIGHT", valueBtn, "RIGHT", -7, 1)
        caret:SetText("v")
        caret:SetTextColor(0.78, 0.90, 0.92)

        local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        popup:SetFrameStrata("DIALOG")
        popup:SetFrameLevel(50)
        popup:SetBackdrop(MakeBackdrop())
        popup:SetBackdropColor(0.04, 0.09, 0.15, 0.98)
        popup:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
        popup:EnableMouseWheel(true)
        popup:Hide()
        popup.buttons = {}

        local popupScroll = CreateFrame("ScrollFrame", nil, popup)
        popupScroll:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -3)
        popupScroll:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -3, 3)
        popupScroll:EnableMouseWheel(true)

        local popupContent = CreateFrame("Frame", nil, popupScroll)
        popupContent:SetSize(1, 1)
        popupScroll:SetScrollChild(popupContent)

        local scrollTrack = CreateFrame("Button", nil, popup, "BackdropTemplate")
        scrollTrack:SetWidth(8)
        scrollTrack:SetBackdrop(MakeBackdrop())
        scrollTrack:SetBackdropColor(0.03, 0.07, 0.11, 0.95)
        scrollTrack:SetBackdropBorderColor(0.12, 0.26, 0.32, 0.95)
        scrollTrack:Hide()

        local scrollThumb = CreateFrame("Button", nil, scrollTrack, "BackdropTemplate")
        scrollThumb:SetWidth(8)
        scrollThumb:SetBackdrop(MakeBackdrop())
        scrollThumb:SetBackdropColor(0.20, 0.66, 0.63, 0.95)
        scrollThumb:SetBackdropBorderColor(0.30, 0.88, 0.82, 1)
        scrollThumb:Hide()

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

        local function ApplySelection(index, commit)
            currentIndex = index
            local selected = choices[currentIndex] or choices[1]
            valueText:SetText(selected.label)
            if commit ~= false then
                setVal(selected.value, selected)
            end
        end

        local function EnsurePopupButton(index)
            local btn = popup.buttons[index]
            if btn then
                return btn
            end

            btn = CreateFrame("Button", nil, popupContent, "BackdropTemplate")
            btn:SetHeight(18)
            btn:SetBackdrop(MakeBackdrop())
            btn:SetBackdropColor(0.05, 0.12, 0.20, 0.94)
            btn:SetBackdropBorderColor(0.12, 0.26, 0.32, 0.95)

            btn._label = btn:CreateFontString(nil, "OVERLAY")
            btn._label:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            btn._label:SetPoint("LEFT", btn, "LEFT", 8, 1)
            btn._label:SetPoint("RIGHT", btn, "RIGHT", -22, 1)
            btn._label:SetJustifyH("LEFT")

            btn._check = btn:CreateFontString(nil, "OVERLAY")
            btn._check:SetFont(FONT_HEADERS, 10, GetFontFlags())
            btn._check:SetPoint("RIGHT", btn, "RIGHT", -7, 1)

            btn:SetScript("OnEnter", function(selfBtn)
                selfBtn:SetBackdropColor(0.08, 0.18, 0.28, 0.98)
                selfBtn:SetBackdropBorderColor(0.26, 0.78, 0.72, 1)
            end)
            btn:SetScript("OnLeave", function(selfBtn)
                local active = selfBtn._checked == true
                selfBtn:SetBackdropColor(active and 0.10 or 0.05, active and 0.22 or 0.12, active and 0.30 or 0.20, active and 0.98 or 0.94)
                selfBtn:SetBackdropBorderColor(active and 0.28 or 0.12, active and 0.86 or 0.26, active and 0.78 or 0.32, active and 1 or 0.95)
            end)

            popup.buttons[index] = btn
            return btn
        end

        local function UpdatePopupScrollBar()
            local viewH = popupScroll:GetHeight() or 0
            local contentH = popupContent:GetHeight() or 0
            local maxScroll = math.max(contentH - viewH, 0)
            local current = math.max(0, math.min(popupScroll:GetVerticalScroll() or 0, maxScroll))

            if current ~= (popupScroll:GetVerticalScroll() or 0) then
                popupScroll:SetVerticalScroll(current)
            end

            if maxScroll <= 0 then
                scrollTrack:Hide()
                scrollThumb:Hide()
                return
            end

            scrollTrack:Show()
            local trackH = scrollTrack:GetHeight() or 0
            local thumbH = math.max(18, math.floor(trackH * (viewH / math.max(contentH, 1))))
            thumbH = math.min(thumbH, trackH)
            scrollThumb:SetHeight(thumbH)

            local travel = math.max(trackH - thumbH, 0)
            local pct = current / math.max(maxScroll, 1)
            scrollThumb:ClearAllPoints()
            scrollThumb:SetPoint("TOP", scrollTrack, "TOP", 0, -travel * pct)
            scrollThumb:Show()
        end

        local function SetPopupScrollFromCursor(cursorY, grabOffset)
            local contentH = popupContent:GetHeight() or 0
            local viewH = popupScroll:GetHeight() or 0
            local maxScroll = math.max(contentH - viewH, 0)
            if maxScroll <= 0 then
                popupScroll:SetVerticalScroll(0)
                UpdatePopupScrollBar()
                return
            end

            local trackTop = select(2, scrollTrack:GetCenter())
            local trackH = scrollTrack:GetHeight() or 0
            local thumbH = scrollThumb:GetHeight() or 0
            local cursorOffset = (trackTop + trackH * 0.5) - cursorY - (grabOffset or thumbH * 0.5)
            local travel = math.max(trackH - thumbH, 1)
            local pct = math.max(0, math.min(cursorOffset / travel, 1))
            popupScroll:SetVerticalScroll(maxScroll * pct)
            UpdatePopupScrollBar()
        end

        local function RefreshPopup()
            local width = math.max(valueBtn:GetWidth(), math.ceil(widestLabel) + 52)
            local rowHeight = 18
            local spacing = 2
            local visibleCount = #choices
            local maxVisibleRows = 10
            local needsScroll = visibleCount > maxVisibleRows
            local shownRows = math.min(visibleCount, maxVisibleRows)
            local scrollGutter = needsScroll and 12 or 0
            popup:SetSize(width + scrollGutter, math.max(shownRows * (rowHeight + spacing) + 6, 24))
            popupScroll:ClearAllPoints()
            if needsScroll then
                popupScroll:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -3)
                popupScroll:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -14, 3)
                scrollTrack:ClearAllPoints()
                scrollTrack:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -3, -3)
                scrollTrack:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -3, 3)
            else
                popupScroll:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -3)
                popupScroll:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -3, 3)
                scrollTrack:Hide()
                scrollThumb:Hide()
            end

            local contentWidth = math.max(width - 6, 1)
            local contentHeight = math.max(visibleCount * (rowHeight + spacing) - spacing + 6, 1)
            popupContent:SetSize(contentWidth, contentHeight)

            for index, choice in ipairs(choices) do
                local btn = EnsurePopupButton(index)
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", popupContent, "TOPLEFT", 0, -3 - (index - 1) * (rowHeight + spacing))
                btn:SetPoint("TOPRIGHT", popupContent, "TOPRIGHT", 0, -3 - (index - 1) * (rowHeight + spacing))
                btn:SetHeight(rowHeight)
                btn._label:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
                btn._check:SetFont(FONT_HEADERS, 10, GetFontFlags())
                btn._label:SetText(choice.label)
                btn._check:SetText(index == currentIndex and "v" or "")
                btn._checked = index == currentIndex
                btn:SetBackdropColor(btn._checked and 0.10 or 0.05, btn._checked and 0.22 or 0.12, btn._checked and 0.30 or 0.20, btn._checked and 0.98 or 0.94)
                btn:SetBackdropBorderColor(btn._checked and 0.28 or 0.12, btn._checked and 0.86 or 0.26, btn._checked and 0.78 or 0.32, btn._checked and 1 or 0.95)
                btn:SetScript("OnClick", function()
                    ApplySelection(index, true)
                    popup:Hide()
                    dismiss:Hide()
                end)
                btn:Show()
            end

            for index = visibleCount + 1, #popup.buttons do
                popup.buttons[index]:Hide()
            end

            local selectedOffset = math.max(0, (currentIndex - 1) * (rowHeight + spacing))
            local maxScroll = math.max(contentHeight - (popupScroll:GetHeight() or 0), 0)
            popupScroll:SetVerticalScroll(math.max(0, math.min(selectedOffset, maxScroll)))
            UpdatePopupScrollBar()
        end

        valueBtn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(0.08, 0.18, 0.28, 0.98)
            selfBtn:SetBackdropBorderColor(0.26, 0.78, 0.72, 1)
        end)
        valueBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
            selfBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
        end)
        valueBtn:SetScript("OnClick", function()
            if popup:IsShown() then
                popup:Hide()
                dismiss:Hide()
                return
            end

            RefreshPopup()
            popup:ClearAllPoints()
            local left = valueBtn:GetLeft() or 0
            local popupWidth = popup:GetWidth() or valueBtn:GetWidth()
            local screenWidth = UIParent and UIParent:GetWidth() or 0
            local xOffset = 0
            if screenWidth > 0 and left + popupWidth > screenWidth - 12 then
                xOffset = math.min(0, (screenWidth - 12) - (left + popupWidth))
            end
            if left + xOffset < 12 then
                xOffset = 12 - left
            end
            popup:SetPoint("TOPLEFT", valueBtn, "BOTTOMLEFT", xOffset, -2)
            dismiss:Show()
            popup:Show()
            UpdatePopupScrollBar()
        end)

        local function ScrollPopup(delta)
            local current = popupScroll:GetVerticalScroll() or 0
            local maxScroll = math.max((popupContent:GetHeight() or 0) - (popupScroll:GetHeight() or 0), 0)
            if maxScroll <= 0 then
                popupScroll:SetVerticalScroll(0)
                UpdatePopupScrollBar()
                return
            end

            popupScroll:SetVerticalScroll(math.max(0, math.min(current - delta * 24, maxScroll)))
            UpdatePopupScrollBar()
        end

        popup:SetScript("OnMouseWheel", function(_, delta)
            ScrollPopup(delta)
        end)
        popupScroll:SetScript("OnMouseWheel", function(_, delta)
            ScrollPopup(delta)
        end)
        popupScroll:SetScript("OnScrollRangeChanged", UpdatePopupScrollBar)
        popupScroll:SetScript("OnVerticalScroll", UpdatePopupScrollBar)

        scrollTrack:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" then
                return
            end

            local _, cursorY = GetCursorPosition()
            local scale = UIParent and UIParent:GetEffectiveScale() or 1
            SetPopupScrollFromCursor(cursorY / scale, scrollThumb:GetHeight() * 0.5)
        end)

        scrollThumb:RegisterForDrag("LeftButton")
        scrollThumb:SetScript("OnDragStart", function(selfBtn)
            local _, cursorY = GetCursorPosition()
            local scale = UIParent and UIParent:GetEffectiveScale() or 1
            local thumbCenterY = select(2, selfBtn:GetCenter()) or 0
            local thumbTopY = thumbCenterY + (selfBtn:GetHeight() or 0) * 0.5
            selfBtn._grabOffset = thumbTopY - (cursorY / scale)
        end)
        scrollThumb:SetScript("OnDragStop", function(selfBtn)
            selfBtn._grabOffset = nil
        end)
        scrollThumb:SetScript("OnUpdate", function(selfBtn)
            if not selfBtn._grabOffset then
                return
            end

            local _, cursorY = GetCursorPosition()
            local scale = UIParent and UIParent:GetEffectiveScale() or 1
            SetPopupScrollFromCursor(cursorY / scale, selfBtn._grabOffset)
        end)

        local resetBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        resetBtn:SetSize(20, 20)
        resetBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        resetBtn:SetBackdrop(MakeBackdrop())
        resetBtn:SetBackdropColor(0.12, 0.04, 0.04, 1)
        resetBtn:SetBackdropBorderColor(0.45, 0.12, 0.12, 1)

        local resetText = resetBtn:CreateFontString(nil, "OVERLAY")
        resetText:SetFont(FONT_HEADERS, 10, GetFontFlags())
        resetText:SetPoint("CENTER", resetBtn, "CENTER", 0, 1)
        resetText:SetText("x")
        resetText:SetTextColor(0.75, 0.28, 0.28)

        resetBtn:SetScript("OnClick", function()
            local resetValue = getResetValue and getResetValue() or choices[1].value
            for index, choice in ipairs(choices) do
                if choice.value == resetValue then
                    ApplySelection(index, true)
                    RefreshPopup()
                    return
                end
            end
            ApplySelection(1, true)
            RefreshPopup()
        end)

        ApplySelection(currentIndex, false)
        yOff = yOff - 34
    end

    local function MediaSelector(label, kind, getVal, setVal)
        local sharedMedia = ns.GetSharedMedia and ns.GetSharedMedia()
        local defaultLabel = kind == "font" and "Game Default" or "Midnight Default"
        local choices = {
            { label = defaultLabel, value = ns.MEDIA_DEFAULT_TOKEN },
        }
        local seen = { [defaultLabel] = true }
        if ns.GetSharedMediaList then
            for _, name in ipairs(ns.GetSharedMediaList(kind)) do
                if type(name) == "string" and name ~= "" and not seen[name] then
                    choices[#choices + 1] = { label = name, value = name }
                    seen[name] = true
                end
            end
        end

        ChoiceDropdown(label, choices,
            function()
                local current = getVal()
                if current == nil or current == ns.MEDIA_DEFAULT_TOKEN then
                    return ns.MEDIA_DEFAULT_TOKEN
                end
                return current
            end,
            function(value)
                local path
                if value and value ~= ns.MEDIA_DEFAULT_TOKEN and sharedMedia then
                    local mediaType = kind == "font" and sharedMedia.MediaType.FONT or sharedMedia.MediaType.BACKGROUND
                    path = sharedMedia:Fetch(mediaType, value, true)
                end
                if value == ns.MEDIA_DEFAULT_TOKEN and kind == "font" and ns.GetDefaultFontTexture then
                    path = ns.GetDefaultFontTexture()
                elseif value == ns.MEDIA_DEFAULT_TOKEN and kind == "background" and ns.GetDefaultBackgroundTexture then
                    path = ns.GetDefaultBackgroundTexture()
                end
                setVal(value, path)
            end,
            function()
                return ns.MEDIA_DEFAULT_TOKEN
            end)
    end
    local function SetLayoutMode(enabled)
        MR.db.profile.characterWindowLayout = enabled
        if MR.ApplySharedMediaSettings then
            MR:ApplySharedMediaSettings()
        end
        MR:RefreshUI()
        if MR.frame then
            ApplyMainFrameLayout(MR.frame)
        end
        if MR.raresFrame then
            MR.raresFrame:ClearAllPoints()
            RestoreFramePos(MR.raresFrame, "raresPos", 580, 0)
        end
        if MR.renownFrame then
            MR.renownFrame:ClearAllPoints()
            RestoreFramePos(MR.renownFrame, "renownPos", 300, 0)
        end
        if MR.gatheringLocationsFrame then
            MR.gatheringLocationsFrame:ClearAllPoints()
            RestoreFramePos(MR.gatheringLocationsFrame, "gatheringLocPos", 860, 0)
        end
        if MR.RebuildRaresFrame then
            MR:RebuildRaresFrame()
        end
        if MR.RebuildRenownFrame then
            MR:RebuildRenownFrame()
        end
        if MR.RebuildGatheringLocationsFrame then
            MR:RebuildGatheringLocationsFrame()
        end
        MR:PopulateConfigFrame(f)
    end

    do
        local tabs = {
            { key = "windows", label = L["Config_TabWindows"] or "Windows" },
            { key = "layout",  label = L["Config_TabLayout"]  or "Layout"  },
            { key = "modules", label = L["Config_TabModules"] or "Modules" },
            { key = "reset",   label = L["Config_TabReset"]   or "Reset"   },
        }
        local tabW = math.floor((contentW - 6) / #tabs)
        local tabY = yOff
        for i, tab in ipairs(tabs) do
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(tabW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", 8 + (i - 1) * (tabW + 2), tabY)
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
                MR._cfgPage = tab.key
                MR:PopulateConfigFrame(f)
            end)
            btn:SetScript("OnEnter", function()
                if activePage ~= tab.key then
                    btn:SetBackdropColor(0.08, 0.18, 0.24, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.90, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = (MR._cfgPage or "windows") == tab.key
                btn:SetBackdropColor(selected and 0.11 or 0.05, selected and 0.24 or 0.09, selected and 0.23 or 0.15, 1)
                btn:SetBackdropBorderColor(selected and 0.22 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.85 or 0.62, selected and 1.0 or 0.75, selected and 0.92 or 0.70)
            end)
        end
        yOff = yOff - 26
    end

    f:SetScript("OnUpdate", nil)

    if activePage == "windows" then
        SectionLabel(L["Title"])
        Checkbox(L["Config_ShowMainFrame"],
            function() return MR.frame and MR.frame:IsShown() or false end,
            function(v)
                if v then
                    if not MR.frame then
                        MR:BuildUI()
                    elseif not MR.frame:IsShown() then
                        MR.frame:Show()
                    end
                    MR.db.char.panelOpen = true
                    if MR.ClearManagedWindowsBundleHidden then
                        MR:ClearManagedWindowsBundleHidden()
                    end
                else
                    if MR.frame then
                        MR.frame:Hide()
                    end
                    MR.db.char.panelOpen = false
                end
            end, "#2ae7c6")

        Checkbox(L["Config_OpenRenown"],
            function() return MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("renownOpen") end,
            function(v)
                if MR.SetManagedWindowOpen then
                    MR:SetManagedWindowOpen("renownOpen", v)
                end
                if MR.ToggleRenown then MR:ToggleRenown() end
            end, "#d9b82e")

        Checkbox(L["Config_OpenRares"],
            function() return MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("raresOpen") end,
            function(v)
                if MR.SetManagedWindowOpen then
                    MR:SetManagedWindowOpen("raresOpen", v)
                end
                if MR.ToggleRares then MR:ToggleRares() end
            end, "#e05050")

        Checkbox(L["Profession_Knowledge"],
            function() return MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("gatheringLocOpen") end,
            function(v)
                if MR.SetManagedWindowOpen then
                    MR:SetManagedWindowOpen("gatheringLocOpen", v)
                end
                if MR.ToggleGatheringLocations then MR:ToggleGatheringLocations() end
            end, "#c9853f")

        Gap(4); Divider()
        SectionLabel(L["OPTIONS"])
        Checkbox(L["Config_HideWhenCompleted"],
            function() return MR.db.char.hideComplete end,
            function(v)
                local moduleStorage = MR:GetActiveModuleStorage()
                MR.db.char.hideComplete = v
                for _, mod in ipairs(MR.modules) do
                    if moduleStorage and moduleStorage[mod.key] then
                        moduleStorage[mod.key].hideComplete = nil
                    end
                end
                if MR.RequestConfigRefresh then
                    MR:RequestConfigRefresh()
                else
                    MR:RefreshUI()
                end
            end)
        Checkbox(L["Config_HideCurrenciesWhenCompleted"] or "Hide Currencies When Completed",
            function() return MR:IsModuleHideComplete("currencies") end,
            function(v)
                MR:SetModuleHideComplete("currencies", v and true or false, true)
                if MR.RequestConfigRefresh then
                    MR:RequestConfigRefresh()
                else
                    MR:RefreshUI()
                end
            end)
        Checkbox(L["Config_LockFrame"],
            function() return MR.db.profile.locked end,
            function(v)
                MR.db.profile.locked = v
                MR.frame:SetMovable(not v)
            end)
        Checkbox(L["Config_HideMinimap"],
            function() return MR.db.profile.minimap and MR.db.profile.minimap.hide or false end,
            function(v) MR:SetMinimapHidden(v) end)
        Checkbox(L["Config_HideInInstances"],
            function() return MR.db.profile.hideFramesInInstances end,
            function(v)
                MR.db.profile.hideFramesInInstances = v
                if MR.UpdateInstanceFrameVisibility then
                    MR:UpdateInstanceFrameVisibility()
                end
            end)
        Checkbox(L["Config_RememberManagedWindowsVisibility"],
            function() return MR.db.profile.rememberManagedWindowsVisibility end,
            function(v)
                MR.db.profile.rememberManagedWindowsVisibility = v and true or false
                if not MR.db.profile.rememberManagedWindowsVisibility then
                    MR.db.profile.managedWindowsBundleHidden = false
                    MR:RefreshUI()
                end
            end)
        Checkbox(L["Config_PeekOnHover"],
            function() return MR.db.profile.peekOnHover end,
            function(v) MR:ApplyPeekOnHover(v) end)
        Checkbox(L["Config_AutoHidePanelHeaders"],
            function() return MR.db.profile.autoHidePanelHeaders end,
            function(v)
                MR.db.profile.autoHidePanelHeaders = v
                if MR.frame and MR.frame.UpdatePanelHeaderVisibility then
                    MR.frame:UpdatePanelHeaderVisibility(MR.frame:IsMouseOver())
                end
                if MR.renownFrame and MR.renownFrame.UpdatePanelHeaderVisibility then
                    MR.renownFrame:UpdatePanelHeaderVisibility(MR.renownFrame:IsMouseOver())
                end
                if MR.raresFrame and MR.raresFrame.UpdatePanelHeaderVisibility then
                    MR.raresFrame:UpdatePanelHeaderVisibility(MR.raresFrame:IsMouseOver())
                end
                if MR.gatheringLocationsFrame and MR.gatheringLocationsFrame.UpdatePanelHeaderVisibility then
                    MR.gatheringLocationsFrame:UpdatePanelHeaderVisibility(MR.gatheringLocationsFrame:IsMouseOver())
                end
            end)
        Gap(4); Divider()
        SectionLabel(L["GreatVault_Title"])
        Checkbox(L["Config_CompactGreatVault"],
            function() return MR.db and MR.db.profile and MR.db.profile.greatVaultCombined == true end,
            function(v)
                MR.db.profile.greatVaultCombined = v and true or false
                MR:RefreshUI()
            end, "#ff8000")
    elseif activePage == "layout" then
        SectionLabel(L["Config_LayoutMode"] or "Layout Mode")

        local modeY = yOff - 4
        local modeBtnW = math.floor((contentW - 2) / 2)
        local function CreateModeButton(label, enabled, x)
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(modeBtnW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", x, modeY)
            btn:SetBackdrop(MakeBackdrop())
            local active = MR.db.profile.characterWindowLayout == enabled
            btn:SetBackdropColor(active and 0.12 or 0.05, active and 0.30 or 0.09, active and 0.24 or 0.16, 1)
            btn:SetBackdropBorderColor(active and 0.24 or 0.16, active and 0.82 or 0.28, active and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            lbl:SetPoint("CENTER")
            lbl:SetText(label)
            lbl:SetTextColor(active and 0.92 or 0.70, active and 1.0 or 0.78, active and 0.94 or 0.74)

            btn:SetScript("OnClick", function() SetLayoutMode(enabled) end)
            btn:SetScript("OnEnter", function()
                if MR.db.profile.characterWindowLayout ~= enabled then
                    btn:SetBackdropColor(0.08, 0.20, 0.25, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.92, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = MR.db.profile.characterWindowLayout == enabled
                btn:SetBackdropColor(selected and 0.12 or 0.05, selected and 0.30 or 0.09, selected and 0.24 or 0.16, 1)
                btn:SetBackdropBorderColor(selected and 0.24 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.92 or 0.70, selected and 1.0 or 0.78, selected and 0.94 or 0.74)
            end)
        end

        CreateModeButton(L["Config_LayoutShared"] or "Shared", false, 8)
        CreateModeButton(L["Config_LayoutCharacter"] or "Per Character", true, 8 + modeBtnW + 2)
        yOff = yOff - 30

        Divider()
        SectionLabel(L["Config_Display"])

        yOff = OptionsSlider(body, yOff, L["WIDTH"], PANEL_MIN_WIDTH, PANEL_MAX_WIDTH, 10,
            function() return MR.db.profile.width or 260 end,
            function(v)
                ApplyWidth(v)
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.08)
                else
                    MR:PopulateConfigFrame(f)
                end
            end,
            0.16, 0.78, 0.75, 8, nil, cfgFs)

        Gap(6)
        yOff = OptionsSlider(body, yOff, L["HEIGHT"], PANEL_MIN_HEIGHT, PANEL_MAX_HEIGHT, 10,
            function() return MR.db.profile.height or 400 end,
            function(v)
                ApplyHeight(v)
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.08)
                else
                    MR:PopulateConfigFrame(f)
                end
            end,
            0.16, 0.75, 0.78, 8, nil, cfgFs)

        Gap(6)
        yOff = OptionsSlider(body, yOff, L["SCALE"], 0.5, 2.0, 0.05,
            function() return MR.db.profile.scale or 1.0 end,
            function(v)
                if MR.db.profile.syncWindowScale then
                    MR:ApplyScaleToAll(v)
                else
                    MR.db.profile.scale = v
                    if MR.frame then MR.frame:SetScale(v) end
                end
            end,
            0.55, 0.22, 0.82, 8, nil, cfgFs)

        Gap(2)
        yOff = OptionsCheckbox(body, yOff, L["Config_SyncScale"],
            function() return MR.db.profile.syncWindowScale end,
            function(v)
                MR.db.profile.syncWindowScale = v
                if v then MR:ApplyScaleToAll(MR.db.profile.scale or 1.0) end
                MR:PopulateConfigFrame(f)
            end,
            0.55, 0.22, 0.82, 8, nil, cfgFs)

        Gap(4); Divider()
        SectionLabel(L["Config_MainHeaderPosition"] or "Main Header Position")

        local headerModeY = yOff - 4
        local headerModeBtnW = math.floor((contentW - 2) / 2)
        local function CreateHeaderModeButton(label, value, x)
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(headerModeBtnW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", x, headerModeY)
            btn:SetBackdrop(MakeBackdrop())
            local active = GetMainHeaderPosition() == value
            btn:SetBackdropColor(active and 0.12 or 0.05, active and 0.30 or 0.09, active and 0.24 or 0.16, 1)
            btn:SetBackdropBorderColor(active and 0.24 or 0.16, active and 0.82 or 0.28, active and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            lbl:SetPoint("CENTER")
            lbl:SetText(label)
            lbl:SetTextColor(active and 0.92 or 0.70, active and 1.0 or 0.78, active and 0.94 or 0.74)

            btn:SetScript("OnClick", function()
                if GetMainHeaderPosition() == value then
                    return
                end
                SetWindowLayoutValue("mainHeaderPosition", value)
                ApplyMainFrameLayout(MR.frame, true)
                MR:RefreshUI()
                if MR.RebuildRaresFrame then
                    MR:RebuildRaresFrame()
                end
                if MR.RebuildRenownFrame then
                    MR:RebuildRenownFrame()
                end
                if MR.RebuildGatheringLocationsFrame then
                    MR:RebuildGatheringLocationsFrame()
                end
                MR:PopulateConfigFrame(f)
            end)
            btn:SetScript("OnEnter", function()
                if GetMainHeaderPosition() ~= value then
                    btn:SetBackdropColor(0.08, 0.20, 0.25, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.92, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = GetMainHeaderPosition() == value
                btn:SetBackdropColor(selected and 0.12 or 0.05, selected and 0.30 or 0.09, selected and 0.24 or 0.16, 1)
                btn:SetBackdropBorderColor(selected and 0.24 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.92 or 0.70, selected and 1.0 or 0.78, selected and 0.94 or 0.74)
            end)
        end

        CreateHeaderModeButton(L["Config_MainHeaderTop"] or "Top / Grow Down", "top", 8)
        CreateHeaderModeButton(L["Config_MainHeaderBottom"] or "Bottom / Grow Up", "bottom", 8 + headerModeBtnW + 2)
        yOff = yOff - 30

        Gap(2)
        yOff = OptionsCheckbox(body, yOff,
            L["Config_AnimatedMinimize"] or "Animated Minimize / Restore",
            function() return IsAnimatedMinimizeEnabled() end,
            function(v)
                SetWindowLayoutValue("animatedMinimize", v and true or false)
            end,
            0.55, 0.22, 0.82, 8, nil, cfgFs)

        Gap(4); Divider()

        Gap(6)
        yOff = OptionsSlider(body, yOff, L["Config_FontSize"], FONT_SIZE_MIN, FONT_SIZE_MAX, 1,
            function() return GetFontSize() end,
            function(v)
                if MR.db.profile.syncWindowFontSize then
                    MR:ApplyFontSizeToAll(math.floor(v))
                else
                    ApplyFontSize(math.floor(v))
                end
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.08)
                else
                    MR:PopulateConfigFrame(f)
                end
            end,
            0.78, 0.55, 0.16, 8, nil, cfgFs)

        local presets = { {"S", 9}, {"M", 11}, {"L", 14}, {"XL", 17} }
        local btnW = math.floor((contentW - 6) / #presets)
        for i, p in ipairs(presets) do
            local pb = CreateFrame("Button", nil, body, "BackdropTemplate")
            pb:SetSize(btnW, 16)
            pb:SetPoint("TOPLEFT", body, "TOPLEFT", 8 + (i - 1) * (btnW + 2), yOff - 18)
            pb:SetBackdrop(MakeBackdrop())
            local isActive = (GetFontSize() == p[2])
            pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, 1)
            pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, 1)
            local pfs = pb:CreateFontString(nil, "OVERLAY")
            pfs:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            pfs:SetPoint("CENTER")
            pfs:SetText(p[1])
            pfs:SetTextColor(isActive and 0.2 or 0.6, isActive and 0.95 or 0.75, isActive and 0.75 or 0.65)
            pb:SetScript("OnClick", function()
                if MR.db.profile.syncWindowFontSize then
                    MR:ApplyFontSizeToAll(p[2])
                else
                    ApplyFontSize(p[2])
                end
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.08)
                else
                    MR:PopulateConfigFrame(f)
                end
            end)
            pb:SetScript("OnEnter", function()
                pb:SetBackdropColor(0.10, 0.28, 0.28, 1)
                pb:SetBackdropBorderColor(0.25, 0.90, 0.75, 1)
            end)
            pb:SetScript("OnLeave", function()
                pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, 1)
                pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, 1)
            end)
        end

        yOff = yOff - 40

        Gap(2)
        yOff = OptionsCheckbox(body, yOff, L["Config_SyncFontSize"],
            function() return MR.db.profile.syncWindowFontSize end,
            function(v)
                MR.db.profile.syncWindowFontSize = v
                if v then MR:ApplyFontSizeToAll(GetFontSize()) end
                MR:PopulateConfigFrame(f)
            end,
            0.78, 0.55, 0.16, 8, nil, cfgFs)

        Gap(4); Divider()
        SectionLabel(L["Config_SharedMedia"] or "Shared Media")
        MediaSelector(L["Config_Font"] or "Font", "font",
            function() return MR.GetMediaSetting and MR:GetMediaSetting("fontMedia") or MR.db.profile.fontMedia end,
            function(value, path)
                if MR.SetMediaSetting then
                    MR:SetMediaSetting("fontMedia", value)
                    MR:SetMediaSetting("fontMediaPath", path)
                else
                    MR.db.profile.fontMedia = value
                    MR.db.profile.fontMediaPath = path
                end
                MR:ApplySharedMediaSettings()
            end)
        ChoiceDropdown(L["Config_FontStyle"] or "Font Style", {
                { label = L["Config_FontStyleOutline"] or "Outline", value = "OUTLINE" },
                { label = L["Config_FontStyleNone"] or "None", value = "" },
                { label = L["Config_FontStyleThick"] or "Thick Outline", value = "THICKOUTLINE" },
                { label = L["Config_FontStyleMono"] or "Monochrome", value = "MONOCHROME" },
                { label = L["Config_FontStyleMonoOutline"] or "Monochrome Outline", value = "OUTLINE, MONOCHROME" },
                { label = L["Config_FontStyleMonoThick"] or "Monochrome Thick Outline", value = "THICKOUTLINE, MONOCHROME" },
            },
            function()
                if ns.GetFontFlags then
                    return ns.GetFontFlags(MR.GetActiveMediaSettings and MR:GetActiveMediaSettings() or MR.db.profile)
                end
                return MR.GetMediaSetting and MR:GetMediaSetting("fontFlags") or MR.db.profile.fontFlags or "OUTLINE"
            end,
            function(value)
                if MR.SetMediaSetting then
                    MR:SetMediaSetting("fontFlags", value)
                else
                    MR.db.profile.fontFlags = value
                end
                MR:ApplySharedMediaSettings()
            end,
            function()
                return "OUTLINE"
            end)
        MediaSelector(L["Config_BackgroundTexture"] or "Background texture", "background",
            function() return MR.GetMediaSetting and MR:GetMediaSetting("backgroundMedia") or MR.db.profile.backgroundMedia end,
            function(value, path)
                if MR.SetMediaSetting then
                    MR:SetMediaSetting("backgroundMedia", value)
                    MR:SetMediaSetting("backgroundMediaPath", path)
                else
                    MR.db.profile.backgroundMedia = value
                    MR.db.profile.backgroundMediaPath = path
                end
                MR:ApplySharedMediaSettings()
            end)

        Gap(4)
        yOff = OptionsSlider(body, yOff, L["BACKGROUND"], 0, 1, 0.05,
            function() return MR.db.profile.frameAlpha or 1.0 end,
            function(v)
                MR.db.profile.frameAlpha = v
                ApplyTheme()
                MR:RefreshUI()
            end,
            0.40, 0.40, 0.40, 8, nil, cfgFs)

        Gap(2)
        yOff = OptionsCheckbox(body, yOff,
            L["Config_ShowIcons"] or "Show Icons",
            function() return MR.db.profile.keepIconsVisibleInTextMode ~= false end,
            function(v)
                MR.db.profile.keepIconsVisibleInTextMode = v
                MR:RefreshUI()
            end,
            0.40, 0.40, 0.40, 8, nil, cfgFs)

        Gap(2)
        yOff = OptionsCheckbox(body, yOff,
            L["Config_ShowSectionHeaders"] or "Show Section Headers",
            function() return MR.db.profile.keepHeadersVisibleInTextMode ~= false end,
            function(v)
                MR.db.profile.keepHeadersVisibleInTextMode = v
                MR:RefreshUI()
            end,
            0.40, 0.40, 0.40, 8, nil, cfgFs)
    end

    if activePage == "modules" then
        Gap(4); Divider()
        SectionLabel(L["Config_ModuleSettings"])

    if not MR._cfgExpanded then MR._cfgExpanded = {} end

    local function ApplyToggleButtonState(btn, fs, active)
        if not (btn and fs) then
            return
        end

        btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        btn:SetBackdropBorderColor(
            active and 0.15 or 0.35,
            active and 0.32 or 0.12,
            active and 0.38 or 0.12, 1)
        fs:SetText(active and "H" or "S")
        fs:SetTextColor(
            active and 0.45 or 0.55,
            active and 0.75 or 0.25,
            active and 0.70 or 0.25)
    end

    local function BuildHideCompleteBtn(parent, key, anchorRight)
        local hideActive = MR:IsModuleHideComplete(key)
        local isCurrencyModule = key == "currencies" or key == "pvp_currencies"
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(16, 16)
        if anchorRight == parent then
            btn:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        else
            btn:SetPoint("RIGHT", anchorRight, "LEFT", -2, 0)
        end
        btn:SetBackdrop(MakeBackdrop())
        btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        btn:SetBackdropBorderColor(
            hideActive and 0.15 or 0.35,
            hideActive and 0.32 or 0.12,
            hideActive and 0.38 or 0.12, 1)
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT_ROWS, 8, GetFontFlags())
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        ApplyToggleButtonState(btn, fs, hideActive)
        btn:SetScript("OnClick", function()
            local active = not MR:IsModuleHideComplete(key)
            MR:SetModuleHideComplete(key, active, true)
            ApplyToggleButtonState(btn, fs, active)
            if MR.RequestConfigRefresh then
                MR:RequestConfigRefresh()
            else
                MR:RefreshUI()
            end
        end)
        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            btn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            fs:SetTextColor(1, 1, 1)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            if isCurrencyModule then
                GameTooltip:SetText(
                    MR:IsModuleHideComplete(key)
                        and "Hide Currencies When Completed enabled - capped currencies will be hidden"
                        or "Hide Currencies When Completed disabled - currencies stay visible at cap",
                    1, 1, 1
                )
            else
                GameTooltip:SetText(MR:IsModuleHideComplete(key) and L["Config_RowsCollapsed"] or L["Config_RowsShown"], 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            local active = MR:IsModuleHideComplete(key)
            btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            btn:SetBackdropBorderColor(active and 0.15 or 0.35, active and 0.32 or 0.12, active and 0.38 or 0.12, 1)
            fs:SetTextColor(active and 0.45 or 0.55, active and 0.75 or 0.25, active and 0.70 or 0.25)
            GameTooltip:Hide()
        end)
        return btn
    end

    local function BuildColorSwatch(parent, key, mod, anchorRight)
        local currentColor = MR:GetHeaderColor(key)
        local r, g, b = hex(currentColor or mod.labelColor or "#ffffff")
        local swatch = OptionsColorSwatch(parent, r, g, b,
            function(nr, ng, nb)
                local hx = string.format("#%02x%02x%02x", nr*255, ng*255, nb*255)
                MR:SetHeaderColor(key, hx)
            end,
            function()
                MR:ResetHeaderColor(key)
                local dr, dg, db = hex(mod.labelColor or "#ffffff")
                MR:PopulateConfigFrame(f)
                return dr, dg, db
            end,
            L["Config_HeaderColor"])
        swatch:SetPoint("RIGHT", anchorRight, "LEFT", -2, 0)
        return swatch
    end

    local function BuildHeaderBackgroundSwatch(parent, key, anchorRight)
        local currentColor = MR.GetHeaderBackgroundColor and MR:GetHeaderBackgroundColor(key) or nil
        local r, g, b = 0.08, 0.09, 0.12
        if currentColor then
            r, g, b = hex(currentColor)
        end
        local swatch = OptionsColorSwatch(parent, r, g, b,
            function(nr, ng, nb)
                local hx = string.format("#%02x%02x%02x", nr*255, ng*255, nb*255)
                MR:SetHeaderBackgroundColor(key, hx)
            end,
            function()
                MR:ResetHeaderBackgroundColor(key)
                MR:PopulateConfigFrame(f)
                return 0.08, 0.09, 0.12
            end,
            L["Config_HeaderBackgroundColor"] or "Header Background")
        swatch:SetPoint("RIGHT", anchorRight, "LEFT", -2, 0)
        return swatch
    end

    local drag = { active = false, srcKey = nil, targetIdx = nil }

    local dragGhost = CreateFrame("Frame", nil, body, "BackdropTemplate")
    dragGhost:SetHeight(20)
    dragGhost:SetFrameStrata("DIALOG")
    dragGhost:SetBackdrop(MakeBackdrop())
    dragGhost:SetBackdropColor(0.08, 0.28, 0.22, 0.95)
    dragGhost:SetBackdropBorderColor(0.2, 0.9, 0.65, 1)
    dragGhost:Hide()
    local dragGhostLbl = dragGhost:CreateFontString(nil, "OVERLAY")
    dragGhostLbl:SetFont(FONT_HEADERS, 10, GetFontFlags())
    dragGhostLbl:SetPoint("LEFT", dragGhost, "LEFT", 8, 0)
    dragGhostLbl:SetTextColor(0.3, 1, 0.75)

    local dragLine = CreateFrame("Frame", nil, body)
    dragLine:SetHeight(2)
    dragLine:SetFrameStrata("DIALOG")
    dragLine:Hide()
    local dragLineTex = dragLine:CreateTexture(nil, "OVERLAY")
    dragLineTex:SetAllPoints()
    dragLineTex:SetColorTexture(0.2, 0.9, 0.65, 1)

    local _allMods = MR:GetOrderedModules()
    local _cfgRows = {}

    local function DragOnUpdate()
        if not drag.active then return end
        local rows = _cfgRows
        if #rows == 0 then return end

        local cx, cy = GetCursorPosition()
        local scale  = body:GetEffectiveScale()
        local bLeft  = body:GetLeft()
        local bTop   = body:GetTop()
        if not bLeft or not bTop then return end
        local localX = cx / scale - bLeft
        local localY = bTop - cy / scale

        dragGhost:ClearAllPoints()
        dragGhost:SetPoint("TOPLEFT",  body, "TOPLEFT", 4,       -localY + 10)
        dragGhost:SetPoint("TOPRIGHT", body, "TOPRIGHT", -4,     -localY + 10)
        dragGhost:Show()

        local screenCY = cy / UIParent:GetEffectiveScale()
        local slot = #rows
        for i, row in ipairs(rows) do
            local rTop = row.frame:GetTop()
            local rBot = row.frame:GetBottom()
            if rTop and rBot then
                local mid = (rTop + rBot) / 2
                if screenCY > mid then
                    slot = i - 1
                    break
                end
            end
        end
        slot = math.max(0, math.min(slot, #rows))
        drag.targetIdx = slot

        local lineRefFrame
        local lineAtBottom = false
        if slot == 0 then
            lineRefFrame = rows[1].frame
            lineAtBottom = false
        elseif slot >= #rows then
            lineRefFrame = rows[#rows].frame
            lineAtBottom = true
        else
            lineRefFrame = rows[slot].frame
            lineAtBottom = true
        end

        if lineRefFrame then
            local lY = lineAtBottom and (lineRefFrame:GetBottom() or 0) or (lineRefFrame:GetTop() or 0)
            local lLeft  = lineRefFrame:GetLeft()  or 0
            local lRight = lineRefFrame:GetRight() or 0
            local bodyTop   = body:GetTop() or 0
            local bodyLeft  = body:GetLeft() or 0
            local lineBodyY = -(bodyTop - lY)
            local lineBodyL = lLeft - bodyLeft
            local lineBodyR = lRight - bodyLeft
            dragLine:ClearAllPoints()
            dragLine:SetPoint("TOPLEFT",  body, "TOPLEFT", lineBodyL, lineBodyY)
            dragLine:SetPoint("TOPRIGHT", body, "TOPLEFT", lineBodyR, lineBodyY)
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
        for _, row in ipairs(_cfgRows) do row.frame:SetAlpha(1) end
        dragGhost:Hide()
        dragLine:Hide()

        local slot = drag.targetIdx
        if slot == nil then MR:PopulateConfigFrame(f); return end

        local allMods = MR:GetOrderedModules()
        local visMods = {}
        for _, row in ipairs(_cfgRows) do
            for _, m in ipairs(allMods) do
                if m.key == row.key then table.insert(visMods, m); break end
            end
        end
        local srcIdx = nil
        for i, m in ipairs(visMods) do
            if m.key == drag.srcKey then srcIdx = i; break end
        end
        if not srcIdx then MR:PopulateConfigFrame(f); return end

        local insertAt = slot + 1
        if srcIdx < insertAt then insertAt = insertAt - 1 end
        insertAt = math.max(1, math.min(insertAt, #visMods))

        if srcIdx ~= insertAt then
            local moved = table.remove(visMods, srcIdx)
            table.insert(visMods, insertAt, moved)
            local inCfgRows = {}
            for _, row in ipairs(_cfgRows) do inCfgRows[row.key] = true end
            local newOrder = {}
            local vi = 1
            for _, m in ipairs(allMods) do
                if inCfgRows[m.key] then
                    table.insert(newOrder, visMods[vi].key); vi = vi + 1
                else
                    table.insert(newOrder, m.key)
                end
            end
            MR:SetModuleOrder(newOrder)
            MR:RefreshUI()
        end
        drag.srcKey = nil; drag.targetIdx = nil
        MR:PopulateConfigFrame(f)
    end

    for _, mod in ipairs(_allMods) do
        local key = mod.key
        local optVisible = not mod.isVisible or mod:isVisible()

        if mod.profSkillLine then
            if MR.playerProfessions[mod.profSkillLine] then
                local ROW_H = 22
                local headerFr = CreateFrame("Frame", nil, body)
                headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
                headerFr:SetSize(contentW, ROW_H)

                local grip = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
                grip:SetSize(16, ROW_H - 2)
                grip:SetPoint("LEFT", headerFr, "LEFT", 1, 0)
                grip:RegisterForClicks("LeftButtonUp")
                grip:SetBackdrop(MakeBackdrop())
                grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
                grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
                local gripLbl = grip:CreateFontString(nil, "OVERLAY")
                gripLbl:SetFont(FONT_HEADERS, 13, GetFontFlags())
                gripLbl:SetPoint("CENTER", grip, "CENTER", 0, 0)
                gripLbl:SetText("=")
                gripLbl:SetTextColor(0.50, 0.75, 0.68)
                grip:SetScript("OnEnter", function()
                    if not drag.active then
                        gripLbl:SetTextColor(0.3, 1, 0.8)
                        grip:SetBackdropColor(0.15, 0.35, 0.30, 0.9)
                        grip:SetBackdropBorderColor(0.3, 1, 0.75, 1)
                    end
                end)
                grip:SetScript("OnLeave", function()
                    if not drag.active then
                        gripLbl:SetTextColor(0.50, 0.75, 0.68)
                        grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
                        grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
                    end
                end)
                grip:SetScript("OnMouseDown", function()
                    if drag.active then return end
                    drag.active = true
                    drag.srcKey = key
                    drag.targetIdx = nil
                    dragGhostLbl:SetText(mod.label)
                end)
                grip:SetScript("OnClick", function()
                    if drag.active then CommitDrag() end
                end)
                table.insert(_cfgRows, { key = key, frame = headerFr, label = mod.label })

                local cb = CreateFrame("CheckButton", nil, headerFr, "UICheckButtonTemplate")
                cb:SetSize(20, 20)
                cb:SetPoint("LEFT", headerFr, "LEFT", 18, 0)
                cb:SetChecked(MR:IsModuleEnabled(key))
                cb:SetScript("OnClick", function(s)
                    MR:SetModuleEnabled(key, s:GetChecked(), true)
                    if MR.RequestConfigRefresh then
                        MR:RequestConfigRefresh()
                    else
                        MR:RefreshUI()
                    end
                end)

                local hideBtn = BuildHideCompleteBtn(headerFr, key, headerFr)
                local bgSwatch = BuildHeaderBackgroundSwatch(headerFr, key, hideBtn)
                local colorSwatch = BuildColorSwatch(headerFr, key, mod, bgSwatch)

                local lbl = headerFr:CreateFontString(nil, "OVERLAY")
                lbl:SetFont(FONT_ROWS, 10, GetFontFlags())
                lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
                lbl:SetPoint("RIGHT", colorSwatch, "LEFT", -2, 0)
                lbl:SetText(mod.label)
                lbl:SetJustifyH("LEFT")
                local customColor = MR:GetHeaderColor(key)
                if customColor or mod.labelColor then
                    lbl:SetTextColor(hex(customColor or mod.labelColor))
                else
                    lbl:SetTextColor(0.88, 0.88, 0.88)
                end

                yOff = yOff - ROW_H
            end

        elseif optVisible then
            local ROW_H = 22
            local headerFr = CreateFrame("Frame", nil, body)
            headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
            headerFr:SetSize(contentW, ROW_H)

            local cb = CreateFrame("CheckButton", nil, headerFr, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", headerFr, "LEFT", 18, 0)
            cb:SetChecked(MR:IsModuleEnabled(key))
            cb:SetScript("OnClick", function(s)
                MR:SetModuleEnabled(key, s:GetChecked(), true)
                if MR.RequestConfigRefresh then
                    MR:RequestConfigRefresh()
                else
                    MR:RefreshUI()
                end
            end)

            local isExp = MR._cfgExpanded[key]
            local arrowBtn = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
            arrowBtn:SetSize(16, 16)
            arrowBtn:SetPoint("RIGHT", headerFr, "RIGHT", 0, 0)
            arrowBtn:SetBackdrop(MakeBackdrop())
            arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
            local arrowLbl = arrowBtn:CreateFontString(nil, "OVERLAY")
            arrowLbl:SetFont(FONT_HEADERS, 10, GetFontFlags())
            arrowLbl:SetPoint("CENTER", arrowBtn, "CENTER", 0, 1)
            arrowLbl:SetText(isExp and "v" or ">")
            arrowLbl:SetTextColor(0.45, 0.75, 0.70)
            arrowBtn:SetScript("OnClick", function()
                MR._cfgExpanded[key] = not MR._cfgExpanded[key]
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.04)
                else
                    MR:PopulateConfigFrame(f)
                end
            end)
            arrowBtn:SetScript("OnEnter", function()
                arrowBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                arrowBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                arrowLbl:SetTextColor(1, 1, 1)
                GameTooltip:SetOwner(arrowBtn, "ANCHOR_RIGHT")
                GameTooltip:SetText(L["Config_ExpandCollapseRows"], 1, 1, 1)
                GameTooltip:Show()
            end)
            arrowBtn:SetScript("OnLeave", function()
                arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                arrowLbl:SetTextColor(0.45, 0.75, 0.70)
                GameTooltip:Hide()
            end)

            local grip = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
            grip:SetSize(16, ROW_H - 2)
            grip:SetPoint("LEFT", headerFr, "LEFT", 1, 0)
            grip:RegisterForClicks("LeftButtonUp")
            grip:SetBackdrop(MakeBackdrop())
            grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
            grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
            local gripLbl = grip:CreateFontString(nil, "OVERLAY")
            gripLbl:SetFont(FONT_HEADERS, 13, GetFontFlags())
            gripLbl:SetPoint("CENTER", grip, "CENTER", 0, 0)
            gripLbl:SetText("=")
            gripLbl:SetTextColor(0.50, 0.75, 0.68)
            grip:SetScript("OnEnter", function()
                if not drag.active then
                    gripLbl:SetTextColor(0.3, 1, 0.8)
                    grip:SetBackdropColor(0.15, 0.35, 0.30, 0.9)
                    grip:SetBackdropBorderColor(0.3, 1, 0.75, 1)
                end
            end)
            grip:SetScript("OnLeave", function()
                if not drag.active then
                    gripLbl:SetTextColor(0.50, 0.75, 0.68)
                    grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
                    grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
                end
            end)
            grip:SetScript("OnMouseDown", function()
                if drag.active then return end
                drag.active = true
                drag.srcKey = key
                drag.targetIdx = nil
                dragGhostLbl:SetText(mod.label)
            end)
            grip:SetScript("OnClick", function()
                if drag.active then CommitDrag() end
            end)
            table.insert(_cfgRows, { key = key, frame = headerFr, label = mod.label })

            local hideBtn = BuildHideCompleteBtn(headerFr, key, arrowBtn)
            local bgSwatch = BuildHeaderBackgroundSwatch(headerFr, key, hideBtn)
            local colorSwatch = BuildColorSwatch(headerFr, key, mod, bgSwatch)

            local lbl = headerFr:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, 10, GetFontFlags())
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            lbl:SetPoint("RIGHT", colorSwatch, "LEFT", -2, 0)
            lbl:SetText(mod.label)
            lbl:SetJustifyH("LEFT")
            local customColor = MR:GetHeaderColor(key)
            if customColor or mod.labelColor then
                lbl:SetTextColor(hex(customColor or mod.labelColor))
            else
                lbl:SetTextColor(0.88, 0.88, 0.88)
            end

            yOff = yOff - ROW_H

            if MR._cfgExpanded[key] then
                local guide = body:CreateTexture(nil, "ARTWORK")
                guide:SetWidth(1)
                guide:SetColorTexture(0.20, 0.55, 0.50, 0.35)

                local guideTopY = yOff

                for _, row in ipairs(mod.rows) do
                    if not row.control then
                    local rkey    = row.key
                    local enabled = MR:IsRowEnabled(key, rkey)

                    local rowFr = CreateFrame("Frame", nil, body)
                    rowFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
                    rowFr:SetSize(contentW - 20, 18)

                    local rdot = rowFr:CreateTexture(nil, "ARTWORK")
                    rdot:SetSize(5, 5)
                    rdot:SetPoint("LEFT", rowFr, "LEFT", 0, 0)
                    rdot:SetColorTexture(hex(MR:GetRowColor(key, rkey) or MR:GetHeaderColor(key)))
                    rdot:SetAlpha(enabled and 0.8 or 0.25)

                    local cleanLabel = row.label:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
                    local rlbl = rowFr:CreateFontString(nil, "OVERLAY")
                    rlbl:SetFont(FONT_ROWS, 9, GetFontFlags())
                    rlbl:SetPoint("LEFT", rowFr, "LEFT", 10, 0)
                    rlbl:SetPoint("RIGHT", rowFr, "RIGHT", -32, 0)
                    rlbl:SetJustifyH("LEFT")
                    rlbl:SetText(cleanLabel)
                    if not enabled then
                        rlbl:SetTextColor(0.35, 0.35, 0.35)
                    else
                        local rRowCustom    = MR:GetRowColor(key, rkey)
                        local rHeaderCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[key]
                        local rEffective    = rRowCustom or rHeaderCustom
                        if rEffective then
                            rlbl:SetTextColor(hex(rEffective))
                        else
                            rlbl:SetTextColor(0.80, 0.80, 0.80)
                        end
                    end

                    local eyeBtn = CreateFrame("Button", nil, rowFr, "BackdropTemplate")
                    eyeBtn:SetSize(14, 14)
                    eyeBtn:SetPoint("RIGHT", rowFr, "RIGHT", 0, 0)
                    eyeBtn:SetBackdrop(MakeBackdrop())
                    eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                    eyeBtn:SetBackdropBorderColor(
                        enabled and 0.15 or 0.35,
                        enabled and 0.32 or 0.12,
                        enabled and 0.38 or 0.12, 1)
                    local eyeLbl = eyeBtn:CreateFontString(nil, "OVERLAY")
                    eyeLbl:SetFont(FONT_ROWS, 9, GetFontFlags())
                    eyeLbl:SetPoint("CENTER", eyeBtn, "CENTER", 0, 0)
                    eyeLbl:SetText(enabled and "o" or "-")
                    eyeLbl:SetTextColor(
                        enabled and 0.25 or 0.55,
                        enabled and 0.85 or 0.25,
                        enabled and 0.70 or 0.25)

                    local function ApplyRowToggleState(isEnabled)
                        rdot:SetAlpha(isEnabled and 0.8 or 0.25)
                        if not isEnabled then
                            rlbl:SetTextColor(0.35, 0.35, 0.35)
                        else
                            local rRowCustom = MR:GetRowColor(key, rkey)
                            local rHeaderCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[key]
                            local rEffective = rRowCustom or rHeaderCustom
                            if rEffective then
                                rlbl:SetTextColor(hex(rEffective))
                            else
                                rlbl:SetTextColor(0.80, 0.80, 0.80)
                            end
                        end
                        eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                        eyeBtn:SetBackdropBorderColor(
                            isEnabled and 0.15 or 0.35,
                            isEnabled and 0.32 or 0.12,
                            isEnabled and 0.38 or 0.12, 1)
                        eyeLbl:SetText(isEnabled and "o" or "-")
                        eyeLbl:SetTextColor(
                            isEnabled and 0.25 or 0.55,
                            isEnabled and 0.85 or 0.25,
                            isEnabled and 0.70 or 0.25)
                    end

                    eyeBtn:SetScript("OnClick", function()
                        enabled = not MR:IsRowEnabled(key, rkey)
                        MR:SetRowEnabled(key, rkey, enabled, true)
                        if MR.RequestConfigRefresh then
                            MR:RequestConfigRefresh()
                        else
                            MR:RefreshUI()
                        end
                        ApplyRowToggleState(enabled)
                    end)
                    eyeBtn:SetScript("OnEnter", function()
                        eyeBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                        eyeBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                        eyeLbl:SetTextColor(1, 1, 1)
                        GameTooltip:SetOwner(eyeBtn, "ANCHOR_RIGHT")
                        GameTooltip:SetText(enabled and L["Config_HideRow"] or L["Config_ShowRow"], 1, 1, 1)
                        GameTooltip:Show()
                    end)
                    eyeBtn:SetScript("OnLeave", function()
                        ApplyRowToggleState(enabled)
                        GameTooltip:Hide()
                    end)

                    local rsr, rsg, rsb = hex(MR:GetRowColor(key, rkey) or MR:GetHeaderColor(key))
                    local rowSwatch = OptionsColorSwatch(rowFr, rsr, rsg, rsb,
                        function(nr, ng, nb)
                            local hx = string.format("#%02x%02x%02x", nr*255, ng*255, nb*255)
                            MR:SetRowColor(key, rkey, hx)
                        end,
                        function()
                            MR:ResetRowColor(key, rkey)
                            return hex(MR:GetHeaderColor(key))
                        end,
                        L["Config_RowColor"])
                    rowSwatch:SetSize(14, 14)
                    rowSwatch:SetPoint("RIGHT", eyeBtn, "LEFT", -2, 0)

                    yOff = yOff - 19
                    end
                end

                if yOff == guideTopY then
                    guide:Hide()
                else
                    guide:SetPoint("TOPLEFT",    body, "TOPLEFT", 14, guideTopY)
                    guide:SetPoint("BOTTOMLEFT", body, "TOPLEFT", 14, yOff + 4)
                end

                Gap(3)
            end
        end
    end
    end

    if activePage == "reset" then
        SectionLabel(L["RESETS"])
        Btn(L["Config_ResetEverything"], function()
            MR:ResetAllSettings()
            MR:PopulateConfigFrame(f)
        end)
        Btn(L["Config_ResetColors"], function()
            MR.db.profile.headerColors = {}
            MR.db.profile.headerBackgroundColors = {}
            MR.db.profile.rowColors = {}
            MR:RefreshUI()
            MR:PopulateConfigFrame(f)
        end)
        Btn(L["Config_ResetOrder"], function()
            if MR:IsCharacterWindowLayoutEnabled() then
                MR.db.char.moduleOrder = {}
            else
                MR.db.profile.moduleOrder = {}
            end
            MR._orderedModulesCache = nil
            MR:RefreshUI()
            MR:PopulateConfigFrame(f)
        end)
    end

    Gap(8)
    local totalH = math.abs(yOff) + 8
    body:SetHeight(totalH)
    f:SetHeight(totalH)
end

function MR:RequestConfigRepopulate(frame, delay)
    frame = frame or cfgFrame
    if not frame or not frame:IsShown() then
        return
    end

    if not self.ScheduleTimer then
        self:PopulateConfigFrame(frame)
        return
    end

    delay = tonumber(delay) or 0.04
    self._configRepopulatePendingFrame = frame
    if self._configRepopulateTimer and self.CancelTimer then
        self:CancelTimer(self._configRepopulateTimer)
        self._configRepopulateTimer = nil
    end

    self._configRepopulateTimer = self:ScheduleTimer(function()
        local target = self._configRepopulatePendingFrame
        self._configRepopulateTimer = nil
        self._configRepopulatePendingFrame = nil
        if target and target:IsShown() then
            self:PopulateConfigFrame(target)
        end
    end, delay)
end

function MR:RepopulateConfigFrame()
    if cfgFrame and cfgFrame:IsShown() then
        self:PopulateConfigFrame(cfgFrame)
    end
end








do
    local OVERLAY_KEY = "MR_DungeonIDLabel"

    local function HideOverlay(btn)
        local label = btn and btn[OVERLAY_KEY]
        if label then
            label:Hide()
        end
    end

    local function IsLootFrame(frame)
        if not frame then return false end

        local current = frame
        while current do
            local name = current.GetName and current:GetName() or nil
            if type(name) == "string" and name:find("Loot", 1, true) then
                return true
            end
            current = current.GetParent and current:GetParent() or nil
        end

        return frame.itemID ~= nil
            or frame.itemLink ~= nil
            or frame.lootID ~= nil
    end

    local function ApplyOverlayToButton(btn)
        if not btn then return end
        if not btn.encounterID or btn.encounterID <= 0 then
            HideOverlay(btn)
            return
        end
        if IsLootFrame(btn) then
            HideOverlay(btn)
            return
        end

        local journalEncounterID = btn.encounterID
        local _, _, _, _, _, _, dungeonEncounterID = EJ_GetEncounterInfo(journalEncounterID)
        local displayID = (dungeonEncounterID and dungeonEncounterID > 0) and dungeonEncounterID or journalEncounterID
        local prefix    = (dungeonEncounterID and dungeonEncounterID > 0) and "" or "J:"

        local label = btn[OVERLAY_KEY]
        if not label then
            label = btn:CreateFontString(nil, "OVERLAY")
            label:SetFont(FONT_ROWS or "Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            label:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -8, 5)
            label:SetTextColor(0.40, 0.85, 1.00, 1)
            btn[OVERLAY_KEY] = label
        end
        label:SetText("|cff55d6ff" .. prefix .. tostring(displayID) .. "|r")
        label:Show()
    end

    local function TryExtractEncounterID(frame)
        if not frame then return end





        ApplyOverlayToButton(frame)
    end

    local function ScanFrameTree(root, depth)
        if not root or depth > 8 then return end
        TryExtractEncounterID(root)
        local ok, children = pcall(function() return {root:GetChildren()} end)
        if not ok then return end
        for _, child in ipairs(children) do
            ScanFrameTree(child, depth + 1)
        end
        if type(root.ForEachFrame) == "function" then
            pcall(function()
                root:ForEachFrame(function(frame)
                    TryExtractEncounterID(frame)
                    local ok2, children2 = pcall(function() return {frame:GetChildren()} end)
                    if ok2 then
                        for _, c in ipairs(children2) do
                            TryExtractEncounterID(c)
                        end
                    end
                end)
            end)
        end
    end

    local function RefreshEJOverlays()
        if not EncounterJournal or not EncounterJournal:IsShown() then return end
        ScanFrameTree(EncounterJournal, 0)
    end

    local function HookScrollBoxIfFound(root, depth)
        if not root or depth > 8 then return false end
        if type(root.ForEachFrame) == "function" and type(root.RegisterCallback) == "function" then
            pcall(function()
                root:RegisterCallback("OnUpdate", function()
                    root:ForEachFrame(TryExtractEncounterID)
                end)
            end)
            return true
        end
        local ok, children = pcall(function() return {root:GetChildren()} end)
        if not ok then return false end
        for _, child in ipairs(children) do
            if HookScrollBoxIfFound(child, depth + 1) then
                return true
            end
        end
        return false
    end

    local ejHookFrame = CreateFrame("Frame")
    ejHookFrame:RegisterEvent("ADDON_LOADED")
    ejHookFrame:SetScript("OnEvent", function(_, event, arg1)
        if event ~= "ADDON_LOADED" or arg1 ~= "Blizzard_EncounterJournal" then return end

        C_Timer.After(0.5, function()
            HookScrollBoxIfFound(EncounterJournal, 0)
            RefreshEJOverlays()
        end)

        for _, fname in ipairs({
            "EncounterJournal_DisplayEncounters",
            "EncounterJournal_DisplayInstance",
            "EncounterJournal_OpenJournal",
        }) do
            if type(_G[fname]) == "function" then
                hooksecurefunc(fname, function()
                    C_Timer.After(0.1, RefreshEJOverlays)
                end)
            end
        end
    end)

end
