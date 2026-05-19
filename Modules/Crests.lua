local _, ns = ...
local MR = ns.MR

local CREST_CAP = 100
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local crestRows

local function PlainLabel(text, default)
    local value = text or default or ""
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub(":$","")
    if value == "" then
        return default or ""
    end
    return value
end

local function ItemLabel(itemID, fallback, color)
    local itemName = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    return string.format("|cff%s%s:|r", color or "e8c96e", itemName or fallback or ("Item " .. tostring(itemID)))
end

local function CurrencyLabel(currencyID, fallback, color)
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
    local currencyName = info and info.name
    return string.format("|cff%s%s:|r", color or "e8c96e", currencyName or fallback or ("Currency " .. tostring(currencyID)))
end

local function RefreshCrestItemLabels()
    if not crestRows then return end
    local dirty = false
    for _, row in ipairs(crestRows) do
        if row.itemId then
            local nextLabel = ItemLabel(row.itemId, row.fallbackLabel, row.labelColorHex)
            if row.label ~= nextLabel then
                row.label = nextLabel
                dirty = true
            end
        end
    end
    if dirty and MR.RefreshUI then
        MR:RefreshUI()
    end
end

crestRows = {
    {
        key = "crest_adventurer",
        currencyId = 3383,
        -- max = CREST_CAP, caps where removed
		noMax = true,
        label = CurrencyLabel(3383, nil, "b7b7b7"),
    },
    {
        key = "crest_veteran",
        currencyId = 3341,
        noMax = true,
        label = CurrencyLabel(3341, nil, "1eff00"),
    },
    {
        key = "crest_champion",
        currencyId = 3343,
        noMax = true,
        label = CurrencyLabel(3343, nil, "f1c232"),
    },
    {
        key = "crest_hero",
        currencyId = 3345,
        noMax = true,
        label = CurrencyLabel(3345, nil, "0070dd"),
    },
    {
        key = "crest_myth",
        currencyId = 3347,
        noMax = true,
        label = CurrencyLabel(3347, nil, "ff8000"),
    },
	{
		key = "field_accolade",
		currencyId = 3405,
		noMax = true,
        label = CurrencyLabel(3405, nil),
	},
    {
        key = "manaflux",
        currencyId = 3378,
        noMax = true,
        label = CurrencyLabel(3378, nil),
    },
    {
        key = "untainted_mana_crystals",
        currencyId = 3356,
        noMax = true,
        label = CurrencyLabel(3356, nil),
    },
    {
        key = "voidlight_marl",
        currencyId = 3316,
        noMax = true,
        label = CurrencyLabel(3316, nil),
    },
    {
        key = "shards",
        currencyId = 3310,
        max = 600,
        label = CurrencyLabel(3310, nil),
    },
    {
        key = "restored_coffer_key",
        currencyId = 3028,
        noMax = true,
        label = CurrencyLabel(3028),
    },
    {
        key = "spark_radiance",
        itemId = 232875,
        noMax = true,
        fallbackLabel = PlainLabel(L["Currency_SparkRadiance_Label"], "Spark of Radiance"),
        labelColorHex = "e8c96e",
    },
    {
        key = "undercoin",
        currencyId = 2803,
        noMax = true,
        label = CurrencyLabel(2803, nil),
    },
    {
        key = "shard_dundun",
        currencyId = 3376,
        noMax = true,
        label = CurrencyLabel(3376, nil),
    },
    {
        key = "nebulous_voidcore",
        currencyId = 3418,
        label = CurrencyLabel(3418, "Nebulous Voidcore"),
    },
}

RefreshCrestItemLabels()

MR:RegisterModule({
    key         = "currencies",
    label       = L["Currencies"],
    labelColor  = "#f1c232",
    resetType   = "weekly",
    defaultOpen = true,
    rows = crestRows,
})

local itemCacheFrame = CreateFrame("Frame")
itemCacheFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemCacheFrame:SetScript("OnEvent", function(_, _, itemID)
    if itemID ~= 232875 then return end
    RefreshCrestItemLabels()
end)
