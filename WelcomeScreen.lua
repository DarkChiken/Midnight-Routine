local _, ns = ...
local MR = ns.MR

local FONT_HEADERS = ns.FONT_HEADERS
local FONT_ROWS = ns.FONT_ROWS
local MakeBackdrop = ns.MakeBackdrop
local hex = ns.Hex
local StyledFrame = ns.StyledFrame
local TitleBar = ns.TitleBar
local L            = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local pendingEnabled = {}
local pendingRenown      = false
local pendingRares       = false
local pendingGathering   = false
local checkboxRefs   = {}

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
        return
    end

    FONT_ROWS = ns.FONT_ROWS or FONT_ROWS or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    FONT_HEADERS = ns.FONT_HEADERS or FONT_HEADERS or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
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

local function BuildWelcomeScreen()
    RefreshFonts()
    wipe(pendingEnabled)
    wipe(checkboxRefs)

    for _, mod in ipairs(MR:GetOrderedModules()) do
        pendingEnabled[mod.key] = MR:IsModuleEnabled(mod.key)
    end

    pendingRenown = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("renownOpen") or false
    pendingRares = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("raresOpen") or false
    pendingGathering = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("gatheringLocOpen") or false

    local f = StyledFrame(UIParent, nil, "FULLSCREEN_DIALOG", 200)
    f:SetSize(388, 584)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetBackdropColor(0.02, 0.04, 0.10, 0.98)
    f:SetBackdropBorderColor(0.16, 0.78, 0.75, 1)

    local titleBar = TitleBar(f, 36)
    titleBar:SetBackdropColor(0.04, 0.10, 0.22, 1)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local icon = titleBar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("LEFT", titleBar, "LEFT", 10, -2)
    icon:SetTexture("Interface\\AddOns\\MidnightRoutine\\Media\\Icon")
    icon:SetVertexColor(0.16, 0.78, 0.75, 1)

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(FONT_HEADERS, 13, GetFontFlags())
    titleTxt:SetPoint("LEFT", icon, "RIGHT", 7, 0)
    titleTxt:SetText(L["Welcome_Title"])

    local function ScrollByDelta(delta)
        if not f._welcomeScroll then
            return
        end

        local current = f._welcomeScroll:GetVerticalScroll()
        local maxScroll = f._welcomeScroll:GetVerticalScrollRange() or 0
        local step = 40
        if delta > 0 then
            f._welcomeScroll:SetVerticalScroll(math.max(current - step, 0))
        else
            f._welcomeScroll:SetVerticalScroll(math.min(current + step, maxScroll))
        end
        if f.UpdateWelcomeScrollBar then
            f.UpdateWelcomeScrollBar()
        end
    end

    local headerInset = 14
    local headerTop = -46

    local heading = f:CreateFontString(nil, "OVERLAY")
    heading:SetFont(FONT_HEADERS, 12, GetFontFlags())
    heading:SetPoint("TOPLEFT",  f, "TOPLEFT",  headerInset, headerTop)
    heading:SetPoint("TOPRIGHT", f, "TOPRIGHT", -headerInset, headerTop)
    heading:SetJustifyH("LEFT")
    heading:SetText(L["Welcome_Heading"])

    local hintTop = headerTop - 18

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT_ROWS, 10, GetFontFlags())
    hint:SetPoint("TOPLEFT",  f, "TOPLEFT",  headerInset, hintTop)
    hint:SetPoint("TOPRIGHT", f, "TOPRIGHT", -headerInset, hintTop)
    hint:SetJustifyH("LEFT")
    hint:SetText(L["Welcome_Hint"])

    local function MakeDivider(parent, y)
        local d = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        d:SetPoint("TOPLEFT",  parent, "TOPLEFT",   8, y)
        d:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
        d:SetHeight(1)
        d:SetBackdrop(MakeBackdrop(false))
        d:SetBackdropColor(0.16, 0.78, 0.75, 0.25)
        return d
    end
    local footer = CreateFrame("Frame", nil, f, "BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    footer:SetHeight(108)
    footer:SetBackdrop(MakeBackdrop(false))
    if ns.HookBackdropFrame then
        ns.HookBackdropFrame(footer)
    end
    footer:SetBackdropColor(0.03, 0.08, 0.16, 0.96)

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 12, hintTop - 26)
    scroll:SetPoint("TOPRIGHT", f, "TOPRIGHT", -22, hintTop - 26)
    scroll:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 12, 12)
    scroll:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", -22, 12)
    scroll:EnableMouseWheel(true)
    f._welcomeScroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(336, 1)
    scroll:SetScrollChild(content)
    content:EnableMouseWheel(true)
    content:SetScript("OnMouseWheel", function(_, delta)
        ScrollByDelta(delta)
    end)

    scroll:SetScript("OnMouseWheel", function(self, delta)
        ScrollByDelta(delta)
    end)
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta)
        ScrollByDelta(delta)
    end)

    local track = CreateFrame("Frame", nil, f)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 4, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 4, 0)
    track:SetWidth(6)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0.00, 0.00, 0.00, 0.32)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(6)
    thumb:EnableMouse(true)
    thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.24, 0.72, 0.72, 0.82)

    f._welcomeTrack = track
    f._welcomeThumb = thumb

    local scrollBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", scroll, "TOPLEFT", -4, 4)
    scrollBg:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 4, -4)
    scrollBg:SetFrameLevel(scroll:GetFrameLevel() - 1)
    scrollBg:SetBackdrop(MakeBackdrop())
    scrollBg:SetBackdropColor(0.01, 0.03, 0.08, 0.55)
    scrollBg:SetBackdropBorderColor(0.10, 0.28, 0.35, 0.75)

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
            thumb:Hide()
            return
        end

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
        if not trackTop or not trackBottom then
            return
        end

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
        if button ~= "LeftButton" or not thumb:IsShown() then
            return
        end

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
        if button ~= "LeftButton" or not self:IsShown() then
            return
        end

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
    thumb:SetScript("OnEnter", function()
        thumbTex:SetColorTexture(0.36, 0.86, 0.82, 0.95)
    end)
    thumb:SetScript("OnLeave", function()
        thumbTex:SetColorTexture(0.24, 0.72, 0.72, 0.82)
    end)
    scroll:SetScript("OnScrollRangeChanged", function()
        UpdateScrollBar()
    end)
    scroll:SetScript("OnVerticalScroll", function()
        UpdateScrollBar()
    end)
    f.UpdateWelcomeScrollBar = UpdateScrollBar

    local yOff = -2
    MakeDivider(content, yOff)
    yOff = yOff - 10

    for _, mod in ipairs(MR:GetOrderedModules()) do
        local skip = mod.profSkillLine and not MR.playerProfessions[mod.profSkillLine]
        if not skip then
            local key = mod.key

            local row = CreateFrame("Frame", nil, content)
            row:SetPoint("TOPLEFT",  content, "TOPLEFT",  10, yOff)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, yOff)
            row:SetHeight(22)
            row:EnableMouseWheel(true)
            row:SetScript("OnMouseWheel", function(_, delta)
                ScrollByDelta(delta)
            end)

            local dot = row:CreateTexture(nil, "ARTWORK")
            dot:SetSize(5, 5)
            dot:SetPoint("LEFT", row, "LEFT", 0, 0)
            local lr, lg, lb = hex(mod.labelColor or "#aaaaaa")
            dot:SetColorTexture(lr, lg, lb, 1)

            local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", dot, "RIGHT", 4, 0)
            cb:SetChecked(pendingEnabled[key])
            cb:SetScript("OnClick", function(s)
                pendingEnabled[key] = s:GetChecked()
            end)
            checkboxRefs[key] = cb

            local lbl = row:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, 11, GetFontFlags())
            lbl:SetPoint("LEFT",  cb,  "RIGHT",  4, 0)
            lbl:SetPoint("RIGHT", row, "RIGHT",  0, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetWordWrap(true)
            local colHex = (mod.labelColor or "#dddddd"):gsub("#","")
            lbl:SetText(string.format("|cff%s%s|r", colHex, mod.label))

            local rowHeight = math.max(22, math.ceil(lbl:GetStringHeight() or 0) + 6)
            row:SetHeight(rowHeight)
            yOff = yOff - (rowHeight + 2)
        end
    end

    local function CreateUtilityPanel(title, desc, getChecked, setChecked, bgColor, borderColor, accentColor)
        local panel = CreateFrame("Frame", nil, content, "BackdropTemplate")
        panel:SetPoint("TOPLEFT",  content, "TOPLEFT",  8, yOff)
        panel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, yOff)
        panel:SetHeight(60)
        panel:SetBackdrop(MakeBackdrop())
        panel:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.85)
        panel:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 0.90)
        panel:EnableMouseWheel(true)
        panel:SetScript("OnMouseWheel", function(_, delta)
            ScrollByDelta(delta)
        end)

        local accent = panel:CreateTexture(nil, "ARTWORK")
        accent:SetHeight(2)
        accent:SetPoint("TOPLEFT",  panel, "TOPLEFT",  1, -1)
        accent:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
        accent:SetColorTexture(accentColor[1], accentColor[2], accentColor[3], accentColor[4] or 0.85)

        local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -10)
        cb:SetChecked(getChecked())
        cb:SetScript("OnClick", function(s)
            setChecked(s:GetChecked())
        end)

        local titleFs = panel:CreateFontString(nil, "OVERLAY")
        titleFs:SetFont(FONT_HEADERS, 12, GetFontFlags())
        titleFs:SetPoint("TOPLEFT",  cb, "TOPRIGHT", 4, -1)
        titleFs:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
        titleFs:SetJustifyH("LEFT")
        titleFs:SetWordWrap(true)
        titleFs:SetText(title)

        local descFs = panel:CreateFontString(nil, "OVERLAY")
        descFs:SetFont(FONT_ROWS, 10, GetFontFlags())
        descFs:SetPoint("TOPLEFT",  panel, "TOPLEFT", 12, -31)
        descFs:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -31)
        descFs:SetJustifyH("LEFT")
        descFs:SetJustifyV("TOP")
        descFs:SetWordWrap(true)
        descFs:SetText(desc)

        local titleHeight = math.max(14, math.ceil(titleFs:GetStringHeight() or 14))
        local descTop = 14 + titleHeight + 8
        descFs:ClearAllPoints()
        descFs:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -descTop)
        descFs:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -descTop)

        local descHeight = math.max(14, math.ceil(descFs:GetStringHeight() or 14))
        panel:SetHeight(math.max(62, descTop + descHeight + 10))
        yOff = yOff - panel:GetHeight() - 10

        return panel
    end

    yOff = yOff - 8

    CreateUtilityPanel(
        L["Welcome_Renown"],
        L["Welcome_Renown_Desc"],
        function() return pendingRenown end,
        function(val) pendingRenown = val end,
        { 0.10, 0.08, 0.02, 0.85 },
        { 0.65, 0.50, 0.10, 0.90 },
        { 0.85, 0.65, 0.10, 0.85 }
    )

    CreateUtilityPanel(
        L["Welcome_Rares"],
        L["Welcome_Rares_Desc"],
        function() return pendingRares end,
        function(val) pendingRares = val end,
        { 0.12, 0.03, 0.03, 0.85 },
        { 0.65, 0.20, 0.10, 0.90 },
        { 0.85, 0.25, 0.10, 0.85 }
    )

    CreateUtilityPanel(
        L["Welcome_ProfKnowledge"],
        L["Welcome_ProfKnowledge_Desc"],
        function() return pendingGathering end,
        function(val) pendingGathering = val end,
        { 0.08, 0.10, 0.03, 0.85 },
        { 0.65, 0.57, 0.10, 0.90 },
        { 0.80, 0.53, 0.20, 0.85 }
    )

    content:SetHeight(math.abs(yOff) + 20)
    UpdateScrollBar()

    local footerDivider = CreateFrame("Frame", nil, f, "BackdropTemplate")
    footerDivider:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 8, 8)
    footerDivider:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", -8, 8)
    footerDivider:SetHeight(1)
    footerDivider:SetBackdrop(MakeBackdrop(false))
    footerDivider:SetBackdropColor(0.16, 0.78, 0.75, 0.35)

    local allOn = true
    local enableAllBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    enableAllBtn:SetPoint("TOPLEFT",  footer, "TOPLEFT",  12, -14)
    enableAllBtn:SetPoint("TOPRIGHT", footer, "TOPRIGHT", -12, -14)
    enableAllBtn:SetHeight(24)
    enableAllBtn:SetBackdrop(MakeBackdrop())
    enableAllBtn:SetBackdropColor(0.04, 0.14, 0.22, 1)
    enableAllBtn:SetBackdropBorderColor(0.18, 0.55, 0.60, 1)

    local eaLbl = enableAllBtn:CreateFontString(nil, "OVERLAY")
    eaLbl:SetFont(FONT_ROWS, 10, GetFontFlags())
    eaLbl:SetPoint("CENTER")
    eaLbl:SetText(L["Welcome_Disable_All"])

    enableAllBtn:SetScript("OnClick", function()
        allOn = not allOn
        for _, mod in ipairs(MR:GetOrderedModules()) do
            local skip = mod.profSkillLine and not MR.playerProfessions[mod.profSkillLine]
            if not skip then
                pendingEnabled[mod.key] = allOn
                if checkboxRefs[mod.key] then
                    checkboxRefs[mod.key]:SetChecked(allOn)
                end
            end
        end
        eaLbl:SetText(allOn and L["Welcome_Disable_All"] or L["Welcome_Enable_All"])
    end)
    enableAllBtn:SetScript("OnEnter", function()
        enableAllBtn:SetBackdropColor(0.06, 0.22, 0.32, 1)
        enableAllBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
    end)
    enableAllBtn:SetScript("OnLeave", function()
        enableAllBtn:SetBackdropColor(0.04, 0.14, 0.22, 1)
        enableAllBtn:SetBackdropBorderColor(0.18, 0.55, 0.60, 1)
    end)

    local suppressCb = CreateFrame("CheckButton", nil, footer, "UICheckButtonTemplate")
    suppressCb:SetSize(20, 20)
    suppressCb:SetPoint("TOPLEFT", footer, "TOPLEFT", 12, -46)
    suppressCb:SetChecked(false)

    local suppressLbl = footer:CreateFontString(nil, "OVERLAY")
    suppressLbl:SetFont(FONT_ROWS, 10, GetFontFlags())
    suppressLbl:SetPoint("LEFT", suppressCb, "RIGHT", 2, 0)
    suppressLbl:SetPoint("RIGHT", footer, "RIGHT", -12, 0)
    suppressLbl:SetJustifyH("LEFT")
    suppressLbl:SetWordWrap(true)
    suppressLbl:SetText(L["Welcome_SuppressAll"])
    suppressLbl:SetTextColor(0.6, 0.6, 0.6)

    local confirmBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    confirmBtn:SetPoint("BOTTOMLEFT",  footer, "BOTTOMLEFT",  12, 10)
    confirmBtn:SetPoint("BOTTOMRIGHT", footer, "BOTTOMRIGHT", -12, 10)
    confirmBtn:SetHeight(28)
    confirmBtn:SetBackdrop(MakeBackdrop())
    confirmBtn:SetBackdropColor(0.05, 0.20, 0.12, 1)
    confirmBtn:SetBackdropBorderColor(0.15, 0.78, 0.42, 1)

    local confirmLbl = confirmBtn:CreateFontString(nil, "OVERLAY")
    confirmLbl:SetFont(FONT_HEADERS, 12, GetFontFlags())
    confirmLbl:SetPoint("CENTER")
    confirmLbl:SetText(L["Welcome_Confirm"])
    local cr, cg, cb = hex("#00ff96")
    confirmLbl:SetTextColor(cr, cg, cb)

    confirmBtn:SetScript("OnClick", function()
        local anyEnabled = false
        for key, val in pairs(pendingEnabled) do
            MR:SetModuleEnabled(key, val, true)
            if val then anyEnabled = true end
        end
        MR:DismissFirstTimeGlow()
        MR.db.char.welcomeSeen = true
        if suppressCb:GetChecked() then
            MR.db.profile.welcomeSuppressed = true
        end
        f:Hide()

        C_Timer.After(0, function()
            if not MR.db then
                return
            end

            local prevRenown = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("renownOpen") or false
            local prevRares = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("raresOpen") or false
            local prevGathering = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("gatheringLocOpen") or false

            if pendingRenown ~= prevRenown then
                if MR.SetManagedWindowOpen then
                    MR:SetManagedWindowOpen("renownOpen", pendingRenown)
                end
                if pendingRenown and MR.ToggleRenown then
                    MR:ToggleRenown()
                elseif not pendingRenown and MR.HideRenown then
                    MR:HideRenown(false)
                end
            end
            if pendingRares ~= prevRares then
                if MR.SetManagedWindowOpen then
                    MR:SetManagedWindowOpen("raresOpen", pendingRares)
                end
                if pendingRares and MR.ToggleRares then
                    MR:ToggleRares()
                elseif not pendingRares and MR.HideRares then
                    MR:HideRares(false)
                end
            end
            if pendingGathering ~= prevGathering then
                if MR.SetManagedWindowOpen then
                    MR:SetManagedWindowOpen("gatheringLocOpen", pendingGathering)
                end
                if pendingGathering and MR.ToggleGatheringLocations then
                    MR:ToggleGatheringLocations()
                elseif not pendingGathering and MR.HideGatheringLocations then
                    MR:HideGatheringLocations(false)
                end
            end

            MR:RefreshUI()
            if anyEnabled and MR.frame then
                MR.frame:Show()
                MR.db.char.panelOpen = true
                if MR.ClearManagedWindowsBundleHidden then
                    MR:ClearManagedWindowsBundleHidden()
                end
            end
        end)
    end)
    confirmBtn:SetScript("OnEnter", function()
        confirmBtn:SetBackdropColor(0.08, 0.32, 0.20, 1)
        confirmBtn:SetBackdropBorderColor(0.20, 1.00, 0.55, 1)
        confirmLbl:SetTextColor(1, 1, 1)
    end)
    confirmBtn:SetScript("OnLeave", function()
        confirmBtn:SetBackdropColor(0.05, 0.20, 0.12, 1)
        confirmBtn:SetBackdropBorderColor(0.15, 0.78, 0.42, 1)
        local r, g, b = hex("#00ff96")
        confirmLbl:SetTextColor(r, g, b)
    end)

    f:SetAlpha(0)
    local fadeEl = 0
    f:SetScript("OnUpdate", function(self, dt)
        fadeEl = fadeEl + dt
        local a = math.min(fadeEl / 0.4, 1)
        self:SetAlpha(a)
        if a >= 1 then self:SetScript("OnUpdate", nil) end
    end)

    return f
end

function MR:ShowWelcomeScreen()
    self._welcomePending = nil
    if self.welcomeFrame then
        self.welcomeFrame:Hide()
        self.welcomeFrame = nil
    end
    self.welcomeFrame = BuildWelcomeScreen()
    self.welcomeFrame:Show()
end

function MR:MaybeShowWelcomeScreen()
    if self.db.profile.welcomeSuppressed then return end
    if self.db.char.welcomeSeen then return end
    if self._welcomePending then return end
    if self.welcomeFrame and self.welcomeFrame:IsShown() then return end

    self._welcomePending = true
    local ticks = 0
    local checker = CreateFrame("Frame")
    checker:SetScript("OnUpdate", function(frame)
        ticks = ticks + 1
        if ticks >= 5 then
            frame:SetScript("OnUpdate", nil)
            frame:Hide()
            MR._welcomePending = nil
            if MR.db and MR.db.profile and not MR.db.profile.welcomeSuppressed
                and MR.db.char and not MR.db.char.welcomeSeen then
                MR:ShowWelcomeScreen()
                if MR.cfgShine and not MR.db.profile.firstSeen then
                    MR.cfgShine:Play()
                end
            end
        end
    end)
end

function MR:DismissFirstTimeGlow()
    if self.db and self.db.profile and not self.db.profile.firstSeen then
        self.db.profile.firstSeen = true
    end

    if self._firstSeenGlowTimer then
        self._firstSeenGlowTimer:Cancel()
        self._firstSeenGlowTimer = nil
    end

    if self.cfgShine then
        self.cfgShine:Stop()
    end
end
