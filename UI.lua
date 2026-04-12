local _, ns = ...
local MR = ns.MR

local cfgFrame
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

local ROW_HEIGHT    = 18
local HEADER_HEIGHT = 18
local PADDING       = 6
local SECTION_GAP   = 6
local BuildModuleStatsCache
local GetModuleStats
local IsMainTextOnlyMode

local GetWindowLayoutValue
local SetWindowLayoutValue
local countColor

local function GetFontSize()
    if type(ns.GetFontSize) == "function" then
        return ns.GetFontSize()
    end

    if MR and MR.db and MR.db.profile and MR.db.profile.fontSize then
        return MR.db.profile.fontSize
    end

    return 11
end

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
        return
    end

    FONT_ROWS = ns.FONT_ROWS or FONT_ROWS or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    FONT_HEADERS = ns.FONT_HEADERS or FONT_HEADERS or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

local function GetMainHeaderHeight()
    return math.max(24, GetFontSize() + 11)
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
        if MR._titleAccent then MR._titleAccent:SetAlpha(v) end
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

IsMainTextOnlyMode = function()
    if not (MR and MR.db and MR.db.profile) then
        return false
    end

    if MR.db.profile.transparentMode then
        return true
    end

    return (MR.db.profile.frameAlpha or 1.0) <= 0.01
end

local function GetTextOnlyHeaderAlpha()
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

local function ShouldShowIcons()
    if not (MR and MR.db and MR.db.profile) then
        return false
    end

    return MR.db.profile.keepIconsVisibleInTextMode ~= false
end

local function ShouldShowSectionHeaders()
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

local function ShouldShowModuleHeaderIcon(modKey)
    if type(modKey) == "string" and modKey:match("^story_campaign_") then
        return true
    end

    return MODULE_HEADER_ICON_KEYS[modKey] == true
end

local function GetModuleFallbackIconInfo(modKey)
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
}

local function NormalizeIconInfo(info)
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

local function GetRowIconInfo(mod, row)
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

local function GetModuleIconInfo(mod)
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

local function ApplyIconToTexture(texture, info, fallbackTexCoord)
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
    label:SetFont(FONT_ROWS, opts.fontSize or 8, "OUTLINE")
    label:SetPoint("LEFT", btn, "LEFT", 8, 1)
    label:SetPoint("RIGHT", btn, "RIGHT", -20, 1)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.76, 0.97, 0.94)
    btn._label = label

    local caret = btn:CreateFontString(nil, "OVERLAY")
    caret:SetFont(FONT_HEADERS, 10, "OUTLINE")
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
            self._label:SetFont(FONT_ROWS, labelSize, "OUTLINE")
        end
        if self._caret then
            self._caret:SetFont(FONT_HEADERS, caretSize, "OUTLINE")
        end

        for _, row in ipairs(popup.buttons) do
            if row._label then
                row._label:SetFont(FONT_ROWS, labelSize, "OUTLINE")
            end
            if row._check then
                row._check:SetFont(FONT_HEADERS, caretSize, "OUTLINE")
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
        row._label:SetFont(FONT_ROWS, opts.fontSize or 8, "OUTLINE")
        row._label:SetPoint("LEFT", row, "LEFT", 8, 1)
        row._label:SetPoint("RIGHT", row, "RIGHT", -22, 1)
        row._label:SetJustifyH("LEFT")

        row._check = row:CreateFontString(nil, "OVERLAY")
        row._check:SetFont(FONT_HEADERS, 10, "OUTLINE")
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

local function WBConcentrationLabel()
    return rawget(L, "Concentration") or "Concentration"
end

local function WBAltLoginPrompt()
    return L["AltBoard_LoginAltPrompt"] or "Log into an alt for it to show here."
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

function MR:RefreshWarbandBoard()
    local frame = self.altBoardFrame
    if not frame then return end
    frame:SetScale(self.db.profile.scale or 1)
    local expansionInfo = GetExpansionDisplayInfo(true)

    if frame.titleText then
        frame.titleText:SetText(L["AltBoard_Title"] or "Alt Weekly Board")
    end
    if frame.expansionDropdown and frame.expansionDropdown.Update then
        frame.expansionDropdown:Update()
    end

    if frame.summarySub then
        frame.summarySub:ClearAllPoints()
        frame.summarySub:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -46)
    end
    if frame.leftPane then
        frame.leftPane:ClearAllPoints()
        frame.leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -66)
        frame.leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 12)
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

    frame.summaryValue:SetText(string.format("%d / %d", totalDone, totalRows))
    frame.summaryValue:SetTextColor(countColor(totalDone, math.max(totalRows, 1)))

    if #data <= 1 then
        frame.summarySub:SetText(string.format("%s  |  %s", expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key, WBAltLoginPrompt()))
    else
        frame.summarySub:SetText(string.format("%s  |  " .. (L["AltBoard_CharactersTracked"] or "%d characters tracked"), expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key, #data))
    end

    if frame.showHiddenBtn and frame.showHiddenBtn._label then
        frame.showHiddenBtn._label:SetText(MR.db.profile.altBoardShowHidden and (L["AltBoard_HideHidden"] or "Hide Hidden") or (L["AltBoard_ShowHidden"] or "Show Hidden"))
    end

    if not selected then
        frame.heroName:SetText(L["AltBoard_NoTrackedCharacters"] or "No tracked characters yet")
        frame.heroMeta:SetText(WBAltLoginPrompt())
        frame.heroStatus:SetText("")
        WBReleaseWidgets(frame.heroConcentrationWidgets)
        if frame.concentrationPane then
            frame.concentrationPane:SetHeight(42)
        end
        if frame.concentrationStatus then
            frame.concentrationStatus:SetText(WBAltLoginPrompt())
            frame.concentrationStatus:SetTextColor(0.68, 0.74, 0.84)
        end
        frame.detailContent:SetHeight(1)
        return
    end

    for index, entry in ipairs(data) do
        local btn = CreateFrame("Button", nil, frame.charRail, "BackdropTemplate")
        btn:SetSize(194, 46)
        btn:SetPoint("TOPLEFT", frame.charRail, "TOPLEFT", 0, -((index - 1) * 50))
        btn:SetBackdrop(MakeBackdrop())

        local isSelected = (selected.key == entry.key)
        local sr, sg, sb = WBClassColor(entry)
        if isSelected then
            btn:SetBackdropColor(0.08, 0.16, 0.28, 0.98)
            btn:SetBackdropBorderColor(sr, sg, sb, 1)
        else
            btn:SetBackdropColor(0.04, 0.08, 0.15, 0.94)
            btn:SetBackdropBorderColor(0.12, 0.22, 0.30, 0.90)
        end

        local accent = btn:CreateTexture(nil, "ARTWORK")
        accent:SetPoint("TOPLEFT")
        accent:SetPoint("BOTTOMLEFT")
        accent:SetWidth(3)
        accent:SetColorTexture(sr, sg, sb, 1)

        local name = btn:CreateFontString(nil, "OVERLAY")
        name:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), "OUTLINE")
        name:SetPoint("TOPLEFT", btn, "TOPLEFT", 10, -7)
        name:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -34, -7)
        name:SetJustifyH("LEFT")
        name:SetText(entry.isCurrent and (entry.name .. "  |cff7ce7d8" .. (L["AltBoard_Current"] or "Current") .. "|r") or entry.name)

        local meta = btn:CreateFontString(nil, "OVERLAY")
        meta:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), "OUTLINE")
        meta:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
        meta:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -34, -3)
        meta:SetJustifyH("LEFT")
        meta:SetText(string.format("%s  |  %d/%d", entry.realm ~= "" and entry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"), entry.doneRows, entry.totalRows))
        meta:SetTextColor(0.72, 0.79, 0.86)

        local hideBtn = CreateFrame("Button", nil, btn, "BackdropTemplate")
        hideBtn:SetSize(18, 18)
        hideBtn:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
        hideBtn:SetBackdrop(MakeBackdrop())
        hideBtn:SetBackdropColor(0.07, 0.12, 0.18, 0.95)
        hideBtn:SetBackdropBorderColor(0.18, 0.30, 0.36, 0.95)

        local hideLabel = hideBtn:CreateFontString(nil, "OVERLAY")
        hideLabel:SetFont(FONT_HEADERS, 10, "OUTLINE")
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
                selfBtn:SetBackdropColor(0.06, 0.12, 0.20, 0.98)
                selfBtn:SetBackdropBorderColor(sr, sg, sb, 1)
            end
        end)
        btn:SetScript("OnLeave", function(selfBtn)
            if not isSelected then
                selfBtn:SetBackdropColor(0.04, 0.08, 0.15, 0.94)
                selfBtn:SetBackdropBorderColor(0.12, 0.22, 0.30, 0.90)
            end
        end)

        table.insert(frame.charButtons, btn)
    end

    frame.charRail:SetHeight(math.max(#data * 50, 1))
    if frame.leftScrollUpdate then
        frame.leftScrollUpdate()
    end

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
        local rowHeight = 24
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
            chip:SetBackdropColor(rr * 0.14, rg * 0.14, rb * 0.14, 0.96)
            chip:SetBackdropBorderColor(rr * 0.75, rg * 0.75, rb * 0.75, 1)

            local chipGlow = chip:CreateTexture(nil, "BACKGROUND")
            chipGlow:SetAllPoints()
            chipGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
            chipGlow:SetColorTexture(rr, rg, rb, 0.08)

            local dot = chip:CreateTexture(nil, "ARTWORK")
            dot:SetSize(8, 8)
            dot:SetPoint("LEFT", chip, "LEFT", 8, 0)
            dot:SetColorTexture(rr, rg, rb, 1)

            local label = chip:CreateFontString(nil, "OVERLAY")
            label:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), "OUTLINE")
            label:SetPoint("LEFT", dot, "RIGHT", 6, 0)
            label:SetPoint("RIGHT", chip, "RIGHT", -78, 0)
            label:SetJustifyH("LEFT")
            label:SetText(labelText)
            label:SetTextColor(0.84, 0.89, 0.96)

            local value = chip:CreateFontString(nil, "OVERLAY")
            value:SetFont(FONT_HEADERS, math.max(9, GetFontSize() - 1), "OUTLINE")
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

    for _, moduleEntry in ipairs(selected.modules) do
        local card = CreateFrame("Frame", nil, frame.detailContent, "BackdropTemplate")
        card:SetPoint("TOPLEFT", frame.detailContent, "TOPLEFT", 0, -yOff)
        card:SetSize(1, 1)
        card:SetWidth(detailWidth)
        card:SetBackdrop(MakeBackdrop())
        card:SetBackdropColor(0.03, 0.06, 0.11, 0.96)
        card:SetBackdropBorderColor(0.10, 0.18, 0.25, 1)

        local mr, mg, mb = WBHexColor(moduleEntry.color, 1, 1, 1)
        local collapsedModules = (MR.db and MR.db.profile and MR.db.profile.altBoardCollapsedModules) or {}
        local isCollapsed = collapsedModules[moduleEntry.key] == true
        local topAccent = card:CreateTexture(nil, "ARTWORK")
        topAccent:SetPoint("TOPLEFT")
        topAccent:SetPoint("TOPRIGHT")
        topAccent:SetHeight(2)
        topAccent:SetColorTexture(mr, mg, mb, 1)

        local headerBtn = CreateFrame("Button", nil, card)
        headerBtn:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
        headerBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
        headerBtn:SetHeight(32)

        local headerHover = headerBtn:CreateTexture(nil, "BACKGROUND")
        headerHover:SetAllPoints()
        headerHover:SetColorTexture(1, 1, 1, 0)

        local arrow = headerBtn:CreateFontString(nil, "OVERLAY")
        arrow:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), "OUTLINE")
        arrow:SetPoint("LEFT", headerBtn, "LEFT", 12, 0)
        arrow:SetText(isCollapsed and "+" or "-")
        arrow:SetTextColor(0.78, 0.88, 0.92)

        local title = headerBtn:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), "OUTLINE")
        title:SetPoint("LEFT", arrow, "RIGHT", 6, 0)
        title:SetPoint("RIGHT", headerBtn, "RIGHT", -120, 0)
        title:SetJustifyH("LEFT")
        title:SetText(moduleEntry.label)
        title:SetTextColor(mr, mg, mb)

        local progress = card:CreateFontString(nil, "OVERLAY")
        progress:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), "OUTLINE")
        progress:SetPoint("RIGHT", card, "RIGHT", -12, 0)
        progress:SetPoint("TOP", headerBtn, "TOP", 0, -10)
        progress:SetText(string.format("%d / %d", moduleEntry.doneRows, moduleEntry.totalRows))
        progress:SetTextColor(countColor(moduleEntry.doneRows, math.max(moduleEntry.totalRows, 1)))

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

        local moduleY = 34
        if not isCollapsed then
            for _, rowEntry in ipairs(moduleEntry.rows) do
                local row = CreateFrame("Frame", nil, card)
                row:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -moduleY)
                row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -moduleY)
                row:SetHeight(22)

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
                dot:SetSize(7, 7)
                dot:SetPoint("LEFT", row, "LEFT", 2, 0)
                dot:SetColorTexture(rr, rg, rb, 1)

                local label = row:CreateFontString(nil, "OVERLAY")
                label:SetFont(FONT_ROWS, GetFontSize(), "OUTLINE")
                label:SetPoint("LEFT", row, "LEFT", 16, 0)
                label:SetPoint("RIGHT", row, "RIGHT", -120, 0)
                label:SetJustifyH("LEFT")
                label:SetText(rowEntry.label)
                label:SetTextColor(0.90, 0.93, 0.97)

                local value = row:CreateFontString(nil, "OVERLAY")
                value:SetFont(FONT_ROWS, GetFontSize(), "OUTLINE")
                value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                value:SetJustifyH("RIGHT")
                value:SetText(selected.stale and (L["AltBoard_AwaitingRefresh"] or "Awaiting refresh") or rowEntry.displayValue)
                value:SetTextColor(rr, rg, rb)

                if rowEntry.accentLabel then
                    local accent = row:CreateFontString(nil, "OVERLAY")
                    accent:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), "OUTLINE")
                    accent:SetPoint("RIGHT", value, "LEFT", -8, 0)
                    accent:SetJustifyH("RIGHT")
                    accent:SetText(WBClean(rowEntry.accentLabel))
                    accent:SetTextColor(WBHexColor(rowEntry.accentColor, 0.78, 0.82, 0.95))
                end

                table.insert(frame.detailWidgets, row)
                moduleY = moduleY + 23
            end
        end

        card:SetHeight(moduleY + 10)
        table.insert(frame.detailWidgets, card)
        yOff = yOff + moduleY + 18
    end

    frame.detailContent:SetHeight(math.max(yOff, 1))
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
        frame:SetSize(760, 620)
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

        local titleBar = TitleBar(frame, 36)
        titleBar:SetBackdropColor(0.04, 0.11, 0.20, 1)
        titleBar:SetScript("OnDragStart", function()
            frame:StartMoving()
        end)
        titleBar:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            local pt, _, rp, x, y = frame:GetPoint()
            SetWindowLayoutValue("warbandBoardPosition", { point = pt, relPoint = rp, x = x, y = y })
        end)
        LeftAccent(titleBar, 0.15, 0.85, 0.80)

        local title = titleBar:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_HEADERS, math.max(12, GetFontSize() + 2), "OUTLINE")
        title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
        title:SetPoint("RIGHT", titleBar, "RIGHT", -150, 0)
        title:SetJustifyH("LEFT")
        title:SetText(L["AltBoard_Title"] or "Alt Weekly Board")
        title:SetTextColor(0.92, 0.97, 1.0)

        local summaryValue = titleBar:CreateFontString(nil, "OVERLAY")
        summaryValue:SetFont(FONT_HEADERS, math.max(11, GetFontSize() + 1), "OUTLINE")
        summaryValue:SetPoint("RIGHT", titleBar, "RIGHT", -28, 0)
        summaryValue:SetText("0 / 0")

        local summarySub = frame:CreateFontString(nil, "OVERLAY")
        summarySub:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), "OUTLINE")
        summarySub:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -66)
        summarySub:SetTextColor(0.62, 0.71, 0.79)
        summarySub:SetText("")

        CloseButton(titleBar, function() frame:Hide() end)

        local expansionDropdown = BuildExpansionDropdown(frame, true, {
            width = 160,
            height = 18,
        })
        expansionDropdown:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -4, 0)

        local leftPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -66)
        leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 12)
        leftPane:SetWidth(210)
        leftPane:SetBackdrop(MakeBackdrop())
        leftPane:SetBackdropColor(0.03, 0.07, 0.13, 0.95)
        leftPane:SetBackdropBorderColor(0.10, 0.18, 0.25, 1)

        local leftLabel = leftPane:CreateFontString(nil, "OVERLAY")
        leftLabel:SetFont(FONT_ROWS, math.max(9, GetFontSize()), "OUTLINE")
        leftLabel:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 10, -10)
        leftLabel:SetText(L["AltBoard_Characters"] or "Characters")
        leftLabel:SetTextColor(0.74, 0.86, 0.89)

        local showHiddenBtn = CreateFrame("Button", nil, leftPane, "BackdropTemplate")
        showHiddenBtn:SetSize(96, 18)
        showHiddenBtn:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", -8, -8)
        showHiddenBtn:SetBackdrop(MakeBackdrop())
        showHiddenBtn:SetBackdropColor(0.05, 0.10, 0.18, 0.95)
        showHiddenBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

        local showHiddenLabel = showHiddenBtn:CreateFontString(nil, "OVERLAY")
        showHiddenLabel:SetFont(FONT_ROWS, 9, "OUTLINE")
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
            selfBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            selfBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            showHiddenLabel:SetTextColor(1, 1, 1)
        end)
        showHiddenBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.05, 0.10, 0.18, 0.95)
            selfBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
            showHiddenLabel:SetTextColor(0.70, 0.88, 0.85)
        end)

        local leftScroll, charRail, leftScrollUpdate = WBCreateScrollArea(
            leftPane,
            { "TOPLEFT", leftPane, "TOPLEFT", 8, -30 },
            { "BOTTOMRIGHT", leftPane, "BOTTOMRIGHT", -12, 8 }
        )

        local rightPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        rightPane:SetPoint("TOPLEFT", leftPane, "TOPRIGHT", 12, 0)
        rightPane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
        rightPane:SetBackdrop(MakeBackdrop())
        rightPane:SetBackdropColor(0.02, 0.05, 0.10, 0.96)
        rightPane:SetBackdropBorderColor(0.10, 0.18, 0.25, 1)

        local hero = CreateFrame("Frame", nil, rightPane, "BackdropTemplate")
        hero:SetPoint("TOPLEFT", rightPane, "TOPLEFT", 12, -12)
        hero:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -12, -12)
        hero:SetHeight(74)
        hero:SetBackdrop(MakeBackdrop())
        hero:SetBackdropColor(0.05, 0.11, 0.20, 0.98)
        hero:SetBackdropBorderColor(0.12, 0.28, 0.35, 1)

        local heroGlow = hero:CreateTexture(nil, "BACKGROUND")
        heroGlow:SetPoint("TOPLEFT")
        heroGlow:SetPoint("BOTTOMRIGHT")
        heroGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
        heroGlow:SetColorTexture(0.08, 0.20, 0.28, 0.22)

        local heroName = hero:CreateFontString(nil, "OVERLAY")
        heroName:SetFont(FONT_HEADERS, math.max(13, GetFontSize() + 3), "OUTLINE")
        heroName:SetPoint("TOPLEFT", hero, "TOPLEFT", 14, -12)
        heroName:SetTextColor(0.96, 0.99, 1.00)

        local heroMeta = hero:CreateFontString(nil, "OVERLAY")
        heroMeta:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), "OUTLINE")
        heroMeta:SetPoint("TOPLEFT", heroName, "BOTTOMLEFT", 0, -6)
        heroMeta:SetTextColor(0.70, 0.78, 0.86)

        local heroStatus = hero:CreateFontString(nil, "OVERLAY")
        heroStatus:SetFont(FONT_ROWS, math.max(10, GetFontSize()), "OUTLINE")
        heroStatus:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 14, 12)

        local concentrationPane = CreateFrame("Frame", nil, rightPane, "BackdropTemplate")
        concentrationPane:SetPoint("TOPLEFT", hero, "BOTTOMLEFT", 0, -12)
        concentrationPane:SetPoint("TOPRIGHT", hero, "BOTTOMRIGHT", 0, -12)
        concentrationPane:SetHeight(42)
        concentrationPane:SetBackdrop(MakeBackdrop())
        concentrationPane:SetBackdropColor(0.04, 0.08, 0.16, 0.96)
        concentrationPane:SetBackdropBorderColor(0.18, 0.22, 0.34, 1)

        local concentrationAccent = concentrationPane:CreateTexture(nil, "ARTWORK")
        concentrationAccent:SetPoint("TOPLEFT")
        concentrationAccent:SetPoint("TOPRIGHT")
        concentrationAccent:SetHeight(2)
        concentrationAccent:SetColorTexture(0.76, 0.62, 0.98, 1)

        local concentrationTitle = concentrationPane:CreateFontString(nil, "OVERLAY")
        concentrationTitle:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), "OUTLINE")
        concentrationTitle:SetPoint("TOPLEFT", concentrationPane, "TOPLEFT", 14, -10)
        concentrationTitle:SetText(WBConcentrationLabel())
        concentrationTitle:SetTextColor(0.88, 0.82, 1.00)

        local concentrationStatus = concentrationPane:CreateFontString(nil, "OVERLAY")
        concentrationStatus:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), "OUTLINE")
        concentrationStatus:SetPoint("TOPLEFT", concentrationTitle, "BOTTOMLEFT", 0, -8)
        concentrationStatus:SetPoint("RIGHT", concentrationPane, "RIGHT", -12, 0)
        concentrationStatus:SetJustifyH("LEFT")
        concentrationStatus:SetTextColor(0.70, 0.78, 0.88)

        local detailScroll, detailContent, detailScrollUpdate = WBCreateScrollArea(
            rightPane,
            { "TOPLEFT", concentrationPane, "BOTTOMLEFT", 0, -12 },
            { "BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", -10, 10 }
        )
        detailContent:SetSize(520, 1)

        frame.charButtons = {}
        frame.detailWidgets = {}
        frame.charRail = charRail
        frame.leftScroll = leftScroll
        frame.leftScrollUpdate = leftScrollUpdate
        frame.detailScroll = detailScroll
        frame.detailScrollUpdate = detailScrollUpdate
        frame.detailContent = detailContent
        frame.summaryValue = summaryValue
        frame.summarySub = summarySub
        frame.expansionDropdown = expansionDropdown
        frame.hero = hero
        frame.heroConcentrationWidgets = {}
        frame.concentrationPane = concentrationPane
        frame.concentrationTitle = concentrationTitle
        frame.concentrationStatus = concentrationStatus
        frame.leftPane = leftPane
        frame.showHiddenBtn = showHiddenBtn
        frame.heroName = heroName
        frame.heroMeta = heroMeta
        frame.heroStatus = heroStatus
        frame.titleText = title
        frame.leftLabel = leftLabel
        frame.showHiddenLabel = showHiddenLabel

        self.altBoardFrame = frame
    end

    self.altBoardFrame:SetScale(self.db.profile.scale or 1)
    self.altBoardFrame:Show()
    self:RefreshWarbandBoard()
end

local function GetModuleWindowTitle(mod)
    local cleanLabel = mod.label:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
    return cleanLabel
end

local function ApplyWidth(newW)
    newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, math.floor(newW)))
    MR.db.profile.width = newW
    if MR.frame then MR.frame:SetWidth(newW) end
    MR:RefreshUI()
end
MR.ApplyWidth = ApplyWidth

local function ApplyHeight(newH)
    newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, math.floor(newH)))
    MR.db.profile.height = newH
    if MR.frame then MR.frame:SetHeight(newH) end
    MR:RefreshUI()
end
MR.ApplyHeight = ApplyHeight

local function ApplyFontSize(newSize)
    newSize = math.max(FONT_SIZE_MIN, math.min(FONT_SIZE_MAX, math.floor(newSize)))
    MR.db.profile.fontSize = newSize
    RecalcLayout()
    if MR.ApplySharedMediaSettings then
        MR:ApplySharedMediaSettings()
    else
        MR:RefreshUI()
    end
end
MR.ApplyFontSize = ApplyFontSize

local WC = WrapColor
countColor = ns.CountColor

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

local function CaptureMainFrameAnchor(frame, anchorMode)
    if not frame then
        return nil
    end

    local left, top, bottom = frame:GetLeft(), frame:GetTop(), frame:GetBottom()
    if not left then
        return GetWindowLayoutValue("position")
    end

    if anchorMode == "bottom" and bottom then
        return { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = left, y = bottom }
    end

    if top then
        return { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = left, y = top }
    end

    return GetWindowLayoutValue("position")
end

local function ApplyMainFrameAnchor(frame, anchorMode, preserveScreenPosition)
    if not frame then
        return
    end

    local pos = preserveScreenPosition and CaptureMainFrameAnchor(frame, anchorMode) or GetWindowLayoutValue("position")
    if not pos or not pos.point then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    SetWindowLayoutValue("position", {
        point = pos.point,
        relPoint = pos.relPoint or pos.point,
        x = pos.x or 0,
        y = pos.y or 0,
    })
end

local function ApplyExplicitMainFrameAnchor(frame, pos)
    if not frame or not pos or not pos.point then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
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

local function ApplyMainFrameLayout(frame)
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

    ApplyMainFrameAnchor(frame, GetMainHeaderPosition(), true)
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
    local elapsed = 0
    local duration = math.min(0.18, math.max(0.06, math.abs(delta) / 1600))
    mainFrameAnimator:SetScript("OnUpdate", function(_, dt)
        if not MR or not MR.frame then
            StopMainFrameAnimation()
            return
        end

        elapsed = elapsed + (dt or 0)
        local progress = math.min(elapsed / duration, 1)
        local eased = 1 - ((1 - progress) * (1 - progress) * (1 - progress))
        frame:SetHeight(startHeight + (delta * eased))
        if progress >= 1 then
            frame:SetHeight(targetHeight)
            StopMainFrameAnimation()
            if onFinished then onFinished() end
        end
    end)
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

    local p = (MR.db.profile.minimized and GetStoredMainFrameCollapsedAnchor()) or GetWindowLayoutValue("position")
    if p and p.point then
        f:SetPoint(p.point, UIParent, p.relPoint or p.point, p.x or 0, p.y or 0)
    else
        f:SetPoint("CENTER")
    end
    f:SetScale(MR.db.profile.scale or 1)
    self.frame = f

    f:SetScript("OnShow", function()
        MR:Scan()
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
        if not MR.db.profile.locked then f:StartMoving() end
    end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local pos = CaptureMainFrameAnchor(f, GetMainHeaderPosition())
        if pos then
            if MR.db.profile.minimized then
                SetStoredMainFrameCollapsedAnchor(pos)
            else
                SetWindowLayoutValue("position", pos)
                if IsMainHeaderAtBottom() then
                    MR._mainFrameMovedSinceExpand = true
                end
            end
        end
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
    title:SetFont(FONT_HEADERS, math.max(8, GetFontSize() - 2), "OUTLINE")
    title:SetPoint("LEFT", titleIcon, "RIGHT", 5, 0)
    title:SetPoint("RIGHT", titleBar, "RIGHT", -110, 0)
    title:SetJustifyH("LEFT")
    title:SetText(L["Title"])
    self.titleText = title

    local titleCount = titleBar:CreateFontString(nil, "OVERLAY")
    titleCount:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), "OUTLINE")
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
            lbl:SetFont(FONT_HEADERS, 11, "OUTLINE")
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

        if collapsed and IsMainHeaderAtBottom() then
            local collapsedPos = GetBottomHeaderCollapseTarget(f)
            ApplyExplicitMainFrameAnchor(f, collapsedPos)
        elseif not collapsed and IsMainHeaderAtBottom() then
            local collapsedPos = GetStoredMainFrameCollapsedAnchor()
            if collapsedPos and collapsedPos.point then
                MR._mainCollapsedAnchorBeforeExpand = collapsedPos
                MR._mainFrameMovedSinceExpand = false
                ApplyExplicitMainFrameAnchor(f, collapsedPos)
            end
        end

        ApplyMainFrameLayout(f)
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
    warbandText:SetFont(FONT_HEADERS, 9, "OUTLINE")
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
            closeBtn._lbl:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 1), "OUTLINE")
        end
        if minBtn._lbl then
            minBtn._lbl:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 1), "OUTLINE")
        end
        title:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 2), "OUTLINE")
        titleCount:SetFont(FONT_ROWS, math.max(8, metrics.fontSize - 2), "OUTLINE")
        warbandText:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 2), "OUTLINE")
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
    self.detachedFrames[mod.key] = frame
    return frame
end

function MR:RefreshUI()
    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("refreshUI") then
        return
    end

    if not self.frame or not self.content then return end

    RecalcLayout()
    self._moduleStatsCache = BuildModuleStatsCache(self)
    local expansionInfo = GetExpansionDisplayInfo(false)

    if self.titleText then
        self.titleText:SetText(L["Title"] or "Routine")
    end
    if self.expansionDropdown and self.expansionDropdown.Update then
        self.expansionDropdown:Update()
    end
    ApplyMainFrameLayout(self.frame)

    for _, w in ipairs(self.widgets or {}) do
        w:Hide(); w:SetParent(nil)
    end
    self.widgets         = {}
    self.sectionRegistry = {}
    self._timerRows      = {}

    local allDone, allTotal = 0, 0

    local frameW   = MR.db.profile.width or 260
    local usableW  = frameW - 9
    local MIN_COL  = 200
    local numCols  = math.max(1, math.floor(usableW / MIN_COL))
    local colW     = math.floor(usableW / numCols)

    local visibleMods = {}
    for _, mod in ipairs(MR:GetOrderedModules()) do
        local modVisible = not mod.isVisible or mod:isVisible()
        if MR:IsModuleEnabled(mod.key) and modVisible and not MR:IsModuleDetached(mod.key) then
            local stats = GetModuleStats(self, mod)
            local totalRows = stats and stats.totalRows or 0
            local doneRows = stats and stats.doneRows or 0
            local shownRows = stats and stats.shownRows or 0
            if shownRows > 0 then
                local h = stats and stats.height or 0
                table.insert(visibleMods, { mod = mod, h = h })
                allTotal = allTotal + shownRows
                allDone = allDone + math.min(doneRows, shownRows)
            end
        end
    end

    local cols = {}
    for i = 1, numCols do cols[i] = 0 end

    local totalModH = 0
    for _, entry in ipairs(visibleMods) do totalModH = totalModH + entry.h end

    local modColAssign = {}
    local curCol = 1
    for _, entry in ipairs(visibleMods) do
        if curCol < numCols and cols[curCol] >= totalModH / numCols then
            curCol = curCol + 1
        end
        table.insert(modColAssign, { mod = entry.mod, col = curCol, yOff = cols[curCol] })
        cols[curCol] = cols[curCol] + entry.h
    end

    for _, assign in ipairs(modColAssign) do
        local xOff = (assign.col - 1) * colW
        self:BuildSection(assign.mod, assign.yOff, xOff, colW, assign.col)
    end

    for c = 2, numCols do
        local sep = CreateFrame("Frame", nil, self.content)
        sep:SetWidth(1)
        sep:SetPoint("TOPLEFT",    self.content, "TOPLEFT",    (c - 1) * colW, 0)
        sep:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", (c - 1) * colW, 0)
        local sepTex = sep:CreateTexture(nil, "ARTWORK")
        sepTex:SetAllPoints()
        sepTex:SetColorTexture(1, 1, 1, 0.08)
        table.insert(self.widgets, sep)
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

    self.detachedFrames = self.detachedFrames or {}
    local seenDetached = {}
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
            for _, w in ipairs(frame._widgets or {}) do
                w:Hide()
                w:SetParent(nil)
            end
            frame._widgets = {}

            local scrollWidth = frame.scroll and frame.scroll:GetWidth() or (frame:GetWidth() - 8)
            frame.content:SetWidth(math.max(scrollWidth, 1))
            local sectionHeight = self:BuildSection(mod, 0, 0, math.max(scrollWidth, 1), 1, frame.content, frame._widgets, { detached = true })
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

            if not self._instanceFramesHidden and not self:IsManagedWindowsBundleHidden() then
                frame:Show()
            end
        elseif frame then
            frame:Hide()
        end
    end

    for key, frame in pairs(self.detachedFrames) do
        if not seenDetached[key] then
            frame:Hide()
        end
    end

    if self.altBoardFrame and self.altBoardFrame:IsShown() and self.RefreshWarbandBoard then
        self:RefreshWarbandBoard()
    end

    self._moduleStatsCache = nil
end

function MR:ApplySharedMediaSettings()
    if ns.ApplySharedMedia then
        ns.ApplySharedMedia(self.GetActiveMediaSettings and self:GetActiveMediaSettings() or (self.db and self.db.profile))
    end

    RefreshFonts()
    local fontSize = GetFontSize()
    if self.titleText then
        self.titleText:SetFont(FONT_HEADERS, math.max(8, fontSize - 2), "OUTLINE")
    end
    if self.titleCount then
        self.titleCount:SetFont(FONT_ROWS, math.max(8, fontSize - 1), "OUTLINE")
    end
    if self.warbandBtnText then
        self.warbandBtnText:SetFont(FONT_HEADERS, 9, "OUTLINE")
    end
    if self.expansionDropdown and self.expansionDropdown.ApplyFonts then
        self.expansionDropdown:ApplyFonts()
    end
    if self.altBoardFrame then
        local frame = self.altBoardFrame
        if frame.titleText then
            frame.titleText:SetFont(FONT_HEADERS, math.max(12, fontSize + 2), "OUTLINE")
        end
        if frame.summaryValue then
            frame.summaryValue:SetFont(FONT_HEADERS, math.max(11, fontSize + 1), "OUTLINE")
        end
        if frame.summarySub then
            frame.summarySub:SetFont(FONT_ROWS, math.max(8, fontSize - 1), "OUTLINE")
        end
        if frame.leftLabel then
            frame.leftLabel:SetFont(FONT_ROWS, math.max(9, fontSize), "OUTLINE")
        end
        if frame.showHiddenLabel then
            frame.showHiddenLabel:SetFont(FONT_ROWS, 9, "OUTLINE")
        end
        if frame.heroName then
            frame.heroName:SetFont(FONT_HEADERS, math.max(13, fontSize + 3), "OUTLINE")
        end
        if frame.heroMeta then
            frame.heroMeta:SetFont(FONT_ROWS, math.max(8, fontSize - 1), "OUTLINE")
        end
        if frame.heroStatus then
            frame.heroStatus:SetFont(FONT_ROWS, math.max(10, fontSize), "OUTLINE")
        end
        if frame.expansionDropdown and frame.expansionDropdown.ApplyFonts then
            frame.expansionDropdown:ApplyFonts()
        end
    end
    ApplyTheme()
    local configWasShown = cfgFrame and cfgFrame:IsShown() or false
    if cfgFrame then
        cfgFrame:Hide()
        cfgFrame = nil
    end
    if self.frame and ns.RefreshFrameBackground then
        ns.RefreshFrameBackground(self.frame)
    end
    if self._titleBar and ns.RefreshFrameBackground then
        ns.RefreshFrameBackground(self._titleBar)
    end
    if self.RefreshMainHeaderChrome then
        self:RefreshMainHeaderChrome()
    end
    self:RefreshUI()

    if self.RebuildRaresFrame then self:RebuildRaresFrame() end
    if self.RebuildGatheringLocationsFrame then self:RebuildGatheringLocationsFrame() end
    if self.RebuildRenownFrame then self:RebuildRenownFrame() end
    if self.RepopulateRaresConfig then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig then self:RepopulateGatheringConfig() end
    if self.RepopulateRenownConfig then self:RepopulateRenownConfig() end
    if configWasShown then
        cfgFrame = self:BuildConfigFrame()
        self:PopulateConfigFrame(cfgFrame)
        cfgFrame:Show()
    elseif cfgFrame and cfgFrame:IsShown() then
        self:PopulateConfigFrame(cfgFrame)
    end
end

function MR:IsRowComplete(mod, row, done)
    if row.completeFunc then
        return row.completeFunc(done, row, mod) == true
    end
    return row.max and not row.noMax and done >= row.max
end

BuildModuleStatsCache = function(self)
    local cache = {}

    for _, mod in ipairs(MR:GetOrderedModules()) do
        local hideComplete = MR:IsModuleHideComplete(mod.key)
        local isOpen = MR:IsModuleOpen(mod.key)
        local totalRows, doneRows, shownRows = 0, 0, 0
        local height = HEADER_HEIGHT + 1 + SECTION_GAP

        for _, row in ipairs(mod.rows) do
            local rowVisible = not row.isVisible or row.isVisible()
            if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
                totalRows = totalRows + 1

                local done = MR:GetProgress(mod.key, row.key)
                local isComplete = self:IsRowComplete(mod, row, done)
                if isComplete then
                    doneRows = doneRows + 1
                end

                if not (hideComplete and isComplete) then
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

        cache[mod.key] = {
            doneRows = doneRows,
            height = height,
            hideComplete = hideComplete,
            isOpen = isOpen,
            shownRows = shownRows,
            totalRows = totalRows,
        }
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
    lbl:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), "OUTLINE")
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
    cnt:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), "OUTLINE")
    cnt:SetPoint("RIGHT", hdrFrame, "RIGHT", -18, 0)
    cnt:SetText(string.format("%d / %d complete", secDone, secTotal))
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
        if button == "LeftButton" then
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            MR:RefreshUI()
        elseif button == "RightButton" then
            MR:SetModuleDetached(mod.key, not opts.detached)
            MR:RefreshUI()
        end
        hdrFrame._pressed = false
    end)
    hdrFrame:SetScript("OnEnter", function()
        hdrHover:SetColorTexture(1, 1, 1, transparent and (0.10 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.05 or 0) * frameAlpha))
        GameTooltip:SetOwner(hdrFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(mod.label, 1, 1, 1)
        GameTooltip:AddLine(L["Tooltip_ExpandCollapse"], 0.5, 0.5, 0.5)
        GameTooltip:AddLine(opts.detached and "Right-click to dock back" or "Right-click to detach", 0.5, 0.8, 1)
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
                if not (hideComplete and isComplete) then
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
        or (row.questIds ~= nil)
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
              if row.liveKey or row.autoTracked or (row.currencyId and row.noBlizzardTooltip) then
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

    local statusBtn = CreateFrame(isAutoTracked and not row.noMax and "Button" or "Frame", nil, rowFrame, "BackdropTemplate")
    statusBtn:SetSize(14, 14)
    statusBtn:SetPoint("LEFT", rowFrame, "LEFT", PADDING + 2, 0)
    statusBtn:SetBackdrop(MakeBackdrop())

    local statusFill = statusBtn:CreateTexture(nil, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBtn, "TOPLEFT", 2, -2)
    statusFill:SetPoint("BOTTOMRIGHT", statusBtn, "BOTTOMRIGHT", -2, 2)

    local statusCheck = statusBtn:CreateFontString(nil, "OVERLAY")
    statusCheck:SetFont(FONT_HEADERS, 9, "OUTLINE")
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

    if statusBtn:GetObjectType() == "Button" then
        statusBtn:SetScript("OnClick", function()
            local cur = MR:GetManualOverride(mod.key, row.key)
            MR:SetManualOverride(mod.key, row.key, cur >= row.max and 0 or row.max, row.max)
        end)
        statusBtn:SetScript("OnEnter", function()
            hover:SetColorTexture(1, 1, 1, transparent and 0 or (0.04 * frameAlpha))
            local mo = MR:GetManualOverride(mod.key, row.key)
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
    local showRowIcon = showIcons and isCurrencyModule
    local rowIconInfo = showRowIcon and GetRowIconInfo(mod, row) or nil
    local iconSize = math.max(ROW_HEIGHT - 8, 12)
    local rowIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    rowIcon:SetSize(iconSize, iconSize)
    rowIcon:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
    local hasRowIcon = ApplyIconToTexture(rowIcon, rowIconInfo)
    if isComplete and hasRowIcon then
        rowIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    end

    local isCurrencyRow = row.currencyId and row.max and row.max > 0 and not row.noMax
    local hasCoordText  = hasWaypoint
    local lblRightOff   = isCurrencyRow and -96 or (hasCoordText and -128 or -52)

    local lbl = rowFrame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_ROWS, GetFontSize(), "OUTLINE")
    if hasRowIcon then
        lbl:SetPoint("LEFT", rowIcon, "RIGHT", 8, 0)
    else
        lbl:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
    end
    lbl:SetPoint("RIGHT", rowFrame, "RIGHT", lblRightOff, 0)
    lbl:SetJustifyH("LEFT")

    local rowCustom    = MR:GetRowColor(mod.key, row.key)
    local headerCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local effectiveColor = rowCustom or headerCustom

    if isComplete then
        local cleanLabel = CleanLabelText(row.label)
        lbl:SetText(cleanLabel)
        if effectiveColor then
            local cr, cg, cb = hex(effectiveColor)
            lbl:SetTextColor(cr * 0.45, cg * 0.45, cb * 0.45)
        else
            lbl:SetTextColor(0.38, 0.38, 0.38)
        end
    elseif effectiveColor then
        local cleanLabel = CleanLabelText(row.label)
        lbl:SetText(cleanLabel)
        lbl:SetTextColor(hex(effectiveColor))
    else
        lbl:SetText(row.label)
    end

    local countFS = rowFrame:CreateFontString(nil, "OVERLAY")
    countFS:SetFont(FONT_ROWS, GetFontSize(), "OUTLINE")
    countFS:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
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
        walletFS:SetFont(FONT_ROWS, GetFontSize(), "OUTLINE")
        walletFS:SetPoint("RIGHT", countFS, "LEFT", -5, 0)
        walletFS:SetJustifyH("RIGHT")
        walletFS:SetText(string.format("|cffaaaaaa(%d)|r", wallet))
    else
        countFS:SetText(row.noMax and tostring(done) or string.format("%d / %d", done, row.max))
        if row.noMax then
            countFS:SetTextColor(0.8, 0.8, 0.8)
        else
            countFS:SetTextColor(countColor(done, row.max))
        end
    end

    if hasCoordText then
        local coordsFS = rowFrame:CreateFontString(nil, "OVERLAY")
        coordsFS:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 1), "OUTLINE")
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
        vl:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), "OUTLINE")
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
    ttitle:SetFont(FONT_HEADERS, 11, "OUTLINE")
    ttitle:SetText(L["Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    f.titleText = ttitle
    f.titleBar = tbar

    local closeBtn = CloseButton(tbar, function() f:Hide() end)

    return f
end

function MR:PopulateConfigFrame(f)
    if f.body then
        local children = { f.body:GetChildren() }
        for _, child in ipairs(children) do
            local grandchildren = { child:GetChildren() }
            for _, gc in ipairs(grandchildren) do
                if gc:GetObjectType() == "Button" then
                    gc:SetScript("OnClick", nil)
                    gc:SetScript("OnEnter", nil)
                    gc:SetScript("OnLeave", nil)
                end
                gc:EnableMouse(false)
                gc:Hide()
            end
            if child:GetObjectType() == "Button" then
                child:SetScript("OnClick", nil)
                child:SetScript("OnEnter", nil)
                child:SetScript("OnLeave", nil)
            end
            child:EnableMouse(false)
            child:Hide()
        end
        f.body:Hide()
        f.body:SetParent(UIParent)
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
    local function MediaSelector(label, kind, getVal, setVal)
        local sharedMedia = ns.GetSharedMedia and ns.GetSharedMedia()
        local defaultLabel = kind == "font" and "Game Default" or "Midnight Default"
        local options = { defaultLabel }
        local seen = { [options[1]] = true }
        if ns.GetSharedMediaList then
            for _, name in ipairs(ns.GetSharedMediaList(kind)) do
                if type(name) == "string" and name ~= "" and not seen[name] then
                    options[#options + 1] = name
                    seen[name] = true
                end
            end
        end

        local current = getVal()
        if current == ns.MEDIA_DEFAULT_TOKEN or current == nil then
            current = options[1]
        end
        local currentIndex = 1
        for index, name in ipairs(options) do
            if name == current then
                currentIndex = index
                break
            end
        end

        local caption = body:CreateFontString(nil, "OVERLAY")
        caption:SetFont(FONT_ROWS, cfgFs, "OUTLINE")
        caption:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        caption:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
        caption:SetJustifyH("LEFT")
        caption:SetWordWrap(false)
        caption:SetText("|cff888888" .. label .. "|r")

        yOff = yOff - 14

        local row = CreateFrame("Frame", nil, body)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        row:SetSize(contentW, 20)

        local function BuildArrow(text, anchor, rel, xOff)
            local btn = CreateFrame("Button", nil, row, "BackdropTemplate")
            btn:SetSize(20, 20)
            btn:SetPoint(anchor, rel, anchor, xOff, 0)
            btn:SetBackdrop(MakeBackdrop())
            btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

            local fs = btn:CreateFontString(nil, "OVERLAY")
            fs:SetFont(FONT_HEADERS, 10, "OUTLINE")
            fs:SetPoint("CENTER")
            fs:SetText(text)
            fs:SetTextColor(0.70, 0.88, 0.85)

            btn:SetScript("OnEnter", function()
                btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                btn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                fs:SetTextColor(1, 1, 1)
            end)
            btn:SetScript("OnLeave", function()
                btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
                fs:SetTextColor(0.70, 0.88, 0.85)
            end)

            return btn
        end

        local prev = BuildArrow("<", "LEFT", row, 0)

        local valueBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        valueBtn:SetSize(math.max(140, contentW - 72), 20)
        valueBtn:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        valueBtn:SetBackdrop(MakeBackdrop())
        valueBtn:SetBackdropColor(0.03, 0.06, 0.11, 1)
        valueBtn:SetBackdropBorderColor(0.16, 0.30, 0.34, 1)

        local valueText = valueBtn:CreateFontString(nil, "OVERLAY")
        valueText:SetFont(FONT_ROWS, cfgFs, "OUTLINE")
        valueText:SetPoint("LEFT", valueBtn, "LEFT", 6, 0)
        valueText:SetPoint("RIGHT", valueBtn, "RIGHT", -6, 0)
        valueText:SetJustifyH("LEFT")
        valueText:SetWordWrap(false)

        local nextBtn = BuildArrow(">", "LEFT", valueBtn, valueBtn:GetWidth() + 4)

        local resetBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        resetBtn:SetSize(20, 20)
        resetBtn:SetPoint("LEFT", nextBtn, "RIGHT", 4, 0)
        resetBtn:SetBackdrop(MakeBackdrop())
        resetBtn:SetBackdropColor(0.12, 0.04, 0.04, 1)
        resetBtn:SetBackdropBorderColor(0.45, 0.12, 0.12, 1)

        local resetText = resetBtn:CreateFontString(nil, "OVERLAY")
        resetText:SetFont(FONT_HEADERS, 10, "OUTLINE")
        resetText:SetPoint("CENTER", resetBtn, "CENTER", 0, 1)
        resetText:SetText("x")
        resetText:SetTextColor(0.75, 0.28, 0.28)

        local function ApplySelection(index, commit)
            currentIndex = index
            local selected = options[currentIndex] or options[1]
            valueText:SetText(selected)
            if commit ~= false then
                local isDefault = selected == options[1]
                local name = isDefault and ns.MEDIA_DEFAULT_TOKEN or selected
                local path
                if name and name ~= ns.MEDIA_DEFAULT_TOKEN and sharedMedia then
                    local mediaType = kind == "font" and sharedMedia.MediaType.FONT or sharedMedia.MediaType.BACKGROUND
                    path = sharedMedia:Fetch(mediaType, name, true)
                end
                if isDefault and kind == "font" and ns.GetDefaultFontTexture then
                    path = ns.GetDefaultFontTexture()
                elseif isDefault and kind == "background" and ns.GetDefaultBackgroundTexture then
                    path = ns.GetDefaultBackgroundTexture()
                end
                setVal(name, path)
            end
        end

        prev:SetScript("OnClick", function()
            local nextIndex = currentIndex - 1
            if nextIndex < 1 then
                nextIndex = #options
            end
            ApplySelection(nextIndex, true)
        end)
        nextBtn:SetScript("OnClick", function()
            local nextIndex = currentIndex + 1
            if nextIndex > #options then
                nextIndex = 1
            end
            ApplySelection(nextIndex, true)
        end)
        valueBtn:SetScript("OnClick", function()
            local nextIndex = currentIndex + 1
            if nextIndex > #options then
                nextIndex = 1
            end
            ApplySelection(nextIndex, true)
        end)
        resetBtn:SetScript("OnClick", function()
            ApplySelection(1, true)
        end)

        ApplySelection(currentIndex, false)
        yOff = yOff - 26
    end
    local function SetLayoutMode(enabled)
        MR.db.profile.characterWindowLayout = enabled
        if MR.ApplySharedMediaSettings then
            MR:ApplySharedMediaSettings()
        end
        MR:RefreshUI()
        if MR.frame then
            MR.frame:ClearAllPoints()
            local p = GetWindowLayoutValue("position")
            if p and p.point then
                MR.frame:SetPoint(p.point, UIParent, p.relPoint or p.point, p.x or 0, p.y or 0)
            else
                MR.frame:SetPoint("CENTER")
            end
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
            lbl:SetFont(FONT_ROWS, cfgFs, "OUTLINE")
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
                MR:RefreshUI()
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
            lbl:SetFont(FONT_ROWS, cfgFs, "OUTLINE")
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
            function(v) ApplyWidth(v); MR:PopulateConfigFrame(f) end,
            0.16, 0.78, 0.75, 8, nil, cfgFs)

        Gap(6)
        yOff = OptionsSlider(body, yOff, L["HEIGHT"], PANEL_MIN_HEIGHT, PANEL_MAX_HEIGHT, 10,
            function() return MR.db.profile.height or 400 end,
            function(v) ApplyHeight(v); MR:PopulateConfigFrame(f) end,
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
            lbl:SetFont(FONT_ROWS, cfgFs, "OUTLINE")
            lbl:SetPoint("CENTER")
            lbl:SetText(label)
            lbl:SetTextColor(active and 0.92 or 0.70, active and 1.0 or 0.78, active and 0.94 or 0.74)

            btn:SetScript("OnClick", function()
                if GetMainHeaderPosition() == value then
                    return
                end
                SetWindowLayoutValue("mainHeaderPosition", value)
                ApplyMainFrameLayout(MR.frame)
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
                MR:PopulateConfigFrame(f)
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
            pfs:SetFont(FONT_ROWS, cfgFs, "OUTLINE")
            pfs:SetPoint("CENTER")
            pfs:SetText(p[1])
            pfs:SetTextColor(isActive and 0.2 or 0.6, isActive and 0.95 or 0.75, isActive and 0.75 or 0.65)
            pb:SetScript("OnClick", function()
                if MR.db.profile.syncWindowFontSize then
                    MR:ApplyFontSizeToAll(p[2])
                else
                    ApplyFontSize(p[2])
                end
                MR:PopulateConfigFrame(f)
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

    local function BuildHideCompleteBtn(parent, key, anchorRight)
        local hideActive = MR:IsModuleHideComplete(key)
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
        fs:SetFont(FONT_ROWS, 8, "OUTLINE")
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        fs:SetText(hideActive and "H" or "S")
        fs:SetTextColor(hideActive and 0.45 or 0.55, hideActive and 0.75 or 0.25, hideActive and 0.70 or 0.25)
        btn:SetScript("OnClick", function()
            MR:SetModuleHideComplete(key, not MR:IsModuleHideComplete(key))
            MR:PopulateConfigFrame(f)
        end)
        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            btn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            fs:SetTextColor(1, 1, 1)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(MR:IsModuleHideComplete(key) and L["Config_RowsCollapsed"] or L["Config_RowsShown"], 1, 1, 1)
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
    dragGhostLbl:SetFont(FONT_HEADERS, 10, "OUTLINE")
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
                gripLbl:SetFont(FONT_HEADERS, 13, "OUTLINE")
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
                    MR:SetModuleEnabled(key, s:GetChecked())
                end)

                local hideBtn = BuildHideCompleteBtn(headerFr, key, headerFr)
                local bgSwatch = BuildHeaderBackgroundSwatch(headerFr, key, hideBtn)
                local colorSwatch = BuildColorSwatch(headerFr, key, mod, bgSwatch)

                local lbl = headerFr:CreateFontString(nil, "OVERLAY")
                lbl:SetFont(FONT_ROWS, 10, "OUTLINE")
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
                MR:SetModuleEnabled(key, s:GetChecked())
            end)

            local isExp = MR._cfgExpanded[key]
            local arrowBtn = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
            arrowBtn:SetSize(16, 16)
            arrowBtn:SetPoint("RIGHT", headerFr, "RIGHT", 0, 0)
            arrowBtn:SetBackdrop(MakeBackdrop())
            arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
            local arrowLbl = arrowBtn:CreateFontString(nil, "OVERLAY")
            arrowLbl:SetFont(FONT_HEADERS, 10, "OUTLINE")
            arrowLbl:SetPoint("CENTER", arrowBtn, "CENTER", 0, 1)
            arrowLbl:SetText(isExp and "v" or ">")
            arrowLbl:SetTextColor(0.45, 0.75, 0.70)
            arrowBtn:SetScript("OnClick", function()
                MR._cfgExpanded[key] = not MR._cfgExpanded[key]
                MR:PopulateConfigFrame(f)
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
            gripLbl:SetFont(FONT_HEADERS, 13, "OUTLINE")
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
            lbl:SetFont(FONT_ROWS, 10, "OUTLINE")
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
                    rlbl:SetFont(FONT_ROWS, 9, "OUTLINE")
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
                    eyeLbl:SetFont(FONT_ROWS, 9, "OUTLINE")
                    eyeLbl:SetPoint("CENTER", eyeBtn, "CENTER", 0, 0)
                    eyeLbl:SetText(enabled and "o" or "-")
                    eyeLbl:SetTextColor(
                        enabled and 0.25 or 0.55,
                        enabled and 0.85 or 0.25,
                        enabled and 0.70 or 0.25)

                    eyeBtn:SetScript("OnClick", function()
                        MR:SetRowEnabled(key, rkey, not MR:IsRowEnabled(key, rkey))
                        MR:RefreshUI()
                        MR:PopulateConfigFrame(f)
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
                        eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                        eyeBtn:SetBackdropBorderColor(
                            enabled and 0.15 or 0.35,
                            enabled and 0.32 or 0.12,
                            enabled and 0.38 or 0.12, 1)
                        eyeLbl:SetTextColor(
                            enabled and 0.25 or 0.55,
                            enabled and 0.85 or 0.25,
                            enabled and 0.70 or 0.25)
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

                guide:SetPoint("TOPLEFT",    body, "TOPLEFT", 14, guideTopY)
                guide:SetPoint("BOTTOMLEFT", body, "TOPLEFT", 14, yOff + 4)

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

function MR:RepopulateConfigFrame()
    if cfgFrame and cfgFrame:IsShown() then
        self:PopulateConfigFrame(cfgFrame)
    end
end
