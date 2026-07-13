local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local PROF_HUB = {
    crafting = { zone = 2393, x = 45.0, y = 55.2 },
    treatise = { zone = 2393, x = 45.0, y = 55.6 },
    enchanting = { zone = 2393, x = 47.8, y = 53.8 },
    herbalism = { zone = 2393, x = 48.3, y = 51.4 },
    mining = { zone = 2393, x = 42.6, y = 52.8 },
    skinning = { zone = 2393, x = 43.2, y = 55.6 },
}

MR:RegisterModule({
    key           = "prof_alchemy",
    profSkillLine = 2906,
    label         = L["Alchemy"],
    labelColor    = "#33bbff",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "alch_notebook", questIds = { 93690 }, label = L["Alch_Quest"], max = 1, note = L["Prof_Note_ServiceQuest"], zone = PROF_HUB.crafting.zone, x = PROF_HUB.crafting.x, y = PROF_HUB.crafting.y },
        { key = "alch_drops",    questIds = { 93528, 93529 }, label = L["Alch_Drops"], max = 2, note = L["Prof_Note_CraftingDrops"] },
        { key = "alch_treatise", questIds = { 95127 }, label = L["Alch_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "alch_dmf",      questIds = { 29506 }, label = L["DMF_Alch_Label"], note = L["DMF_Alch_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3189, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
	},
})

MR:RegisterModule({
    key           = "prof_blacksmithing",
    profSkillLine = 2907,
    label         = L["Blacksmithing"],
    labelColor    = "#aaaaaa",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "bs_notebook", questIds = { 93691 }, label = L["BS_Quest"], max = 1, note = L["Prof_Note_ServiceQuest"], zone = PROF_HUB.crafting.zone, x = PROF_HUB.crafting.x, y = PROF_HUB.crafting.y },
        { key = "bs_drops",    questIds = { 93530, 93531 }, label = L["BS_Drops"], max = 2, note = L["Prof_Note_CraftingDrops"] },
        { key = "bs_treatise", questIds = { 95128 }, label = L["BS_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "bs_dmf",      questIds = { 29508 }, label = L["DMF_BS_Label"], note = L["DMF_BS_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3199, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})

MR:RegisterModule({
    key           = "prof_enchanting",
    profSkillLine = 2909,
    label         = L["Enchanting"],
    labelColor    = "#bb77ff",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "ench_notebook",   questIds = { 93697, 93698, 93699 }, label = L["Ench_Quest"], max = 1, note = L["Prof_Note_TrainerQuest"], zone = PROF_HUB.enchanting.zone, x = PROF_HUB.enchanting.x, y = PROF_HUB.enchanting.y },
        { key = "ench_drops",      questIds = { 93532, 93533 }, label = L["Ench_Drops"], max = 2, note = L["Prof_Note_CraftingDrops"] },
        { key = "ench_de_essence", questIds = { 95048, 95049, 95050, 95051, 95052 }, label = L["Ench_DE_Essence"], max = 5, note = L["Prof_Note_EnchantingFive"] },
        { key = "ench_de_shard",   questIds = { 95053 }, label = L["Ench_DE_Shard"], max = 1, note = L["Prof_Note_EnchantingBonus"] },
        { key = "ench_treatise",   questIds = { 95129 }, label = L["Ench_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "ench_dmf",        questIds = { 29510 }, label = L["DMF_Ench_Label"], note = L["DMF_Ench_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup",    currencyId = 3198, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})

MR:RegisterModule({
    key           = "prof_engineering",
    profSkillLine = 2910,
    label         = L["Engineering"],
    labelColor    = "#ffcc44",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "eng_notebook", questIds = { 93692 }, label = L["Eng_Quest"], max = 1, note = L["Prof_Note_ServiceQuest"], zone = PROF_HUB.crafting.zone, x = PROF_HUB.crafting.x, y = PROF_HUB.crafting.y },
        { key = "eng_drops",    questIds = { 93534, 93535 }, label = L["Eng_Drops"], max = 2, note = L["Prof_Note_CraftingDrops"] },
        { key = "eng_treatise", questIds = { 95138 }, label = L["Eng_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "eng_dmf",      questIds = { 29511 }, label = L["DMF_Eng_Label"], note = L["DMF_Eng_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3197, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})

MR:RegisterModule({
    key           = "prof_herbalism",
    profSkillLine = 2912,
    label         = L["Herbalism"],
    labelColor    = "#55cc44",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "herb_notebook", questIds = { 93700, 93701, 93702, 93703, 93704 }, label = L["Herb_Quest"], max = 1, note = L["Prof_Note_TrainerQuest"], zone = PROF_HUB.herbalism.zone, x = PROF_HUB.herbalism.x, y = PROF_HUB.herbalism.y },
        { key = "herb_drops",    questIds = { 81425, 81426, 81427, 81428, 81429 }, label = L["Herb_Plumes"], max = 5, note = L["Prof_Note_HerbalismFive"] },
        { key = "herb_tail",     questIds = { 81430 }, label = L["Herb_Tail"], max = 1, note = L["Prof_Note_HerbalismBonus"] },
        { key = "herb_treatise", questIds = { 95130 }, label = L["Herb_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "herb_dmf",      questIds = { 29514 }, label = L["DMF_Herb_Label"], note = L["DMF_Herb_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3196, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})

MR:RegisterModule({
    key           = "prof_inscription",
    profSkillLine = 2913,
    label         = L["Inscription"],
    labelColor    = "#44ddaa",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "insc_notebook", questIds = { 93693 }, label = L["Insc_Quest"], max = 1, note = L["Prof_Note_ServiceQuest"], zone = PROF_HUB.crafting.zone, x = PROF_HUB.crafting.x, y = PROF_HUB.crafting.y },
        { key = "insc_drops",    questIds = { 93536, 93537 }, label = L["Insc_Drops"], max = 2, note = L["Prof_Note_CraftingDrops"] },
        { key = "insc_treatise", questIds = { 95131 }, label = L["Insc_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "insc_dmf",      questIds = { 29515 }, label = L["DMF_Insc_Label"], note = L["DMF_Insc_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3195, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})

MR:RegisterModule({
    key           = "prof_jewelcrafting",
    profSkillLine = 2914,
    label         = L["Jewelcrafting"],
    labelColor    = "#ff7799",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "jc_notebook", questIds = { 93694 }, label = L["JC_Quest"], max = 1, note = L["Prof_Note_ServiceQuest"], zone = PROF_HUB.crafting.zone, x = PROF_HUB.crafting.x, y = PROF_HUB.crafting.y },
        { key = "jc_drops",    questIds = { 93538, 93539 }, label = L["JC_Drops"], max = 2, note = L["Prof_Note_CraftingDrops"] },
        { key = "jc_treatise", questIds = { 95133 }, label = L["JC_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "jc_dmf",      questIds = { 29516 }, label = L["DMF_JC_Label"], note = L["DMF_JC_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3194, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})

MR:RegisterModule({
    key           = "prof_leatherworking",
    profSkillLine = 2915,
    label         = L["Leatherworking"],
    labelColor    = "#cc8833",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "lw_notebook", questIds = { 93695 }, label = L["LW_Quest"], max = 1, note = L["Prof_Note_ServiceQuest"], zone = PROF_HUB.crafting.zone, x = PROF_HUB.crafting.x, y = PROF_HUB.crafting.y },
        { key = "lw_drops",    questIds = { 93540, 93541 }, label = L["LW_Drops"], max = 2, note = L["Prof_Note_CraftingDrops"] },
        { key = "lw_treatise", questIds = { 95134 }, label = L["LW_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "lw_dmf",      questIds = { 29517 }, label = L["DMF_LW_Label"], note = L["DMF_LW_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3193, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})

MR:RegisterModule({
    key           = "prof_mining",
    profSkillLine = 2916,
    label         = L["Mining"],
    labelColor    = "#cccccc",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "mine_notebook", questIds = { 93705, 93706, 93707, 93708, 93709 }, label = L["Mine_Quest"], max = 1, note = L["Prof_Note_TrainerQuest"], zone = PROF_HUB.mining.zone, x = PROF_HUB.mining.x, y = PROF_HUB.mining.y },
        { key = "mine_rock",     questIds = { 88673, 88674, 88675, 88676, 88677 }, label = L["Mine_Rock"], max = 5, note = L["Prof_Note_MiningFive"] },
        { key = "mine_nodule",   questIds = { 88678 }, label = L["Mine_Nodule"], max = 1, note = L["Prof_Note_MiningBonus"] },
        { key = "mine_treatise", questIds = { 95135 }, label = L["Mine_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "mine_dmf",      questIds = { 29518 }, label = L["DMF_Mine_Label"], note = L["DMF_Mine_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3192, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})

MR:RegisterModule({
    key           = "prof_skinning",
    profSkillLine = 2917,
    label         = L["Skinning"],
    labelColor    = "#c8a060",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "skin_notebook", questIds = { 93710, 93711, 93712, 93713, 93714 }, label = L["Skin_Quest"], max = 1, note = L["Prof_Note_TrainerQuest"], zone = PROF_HUB.skinning.zone, x = PROF_HUB.skinning.x, y = PROF_HUB.skinning.y },
        { key = "skin_drops",    questIds = { 88534, 88549, 88536, 88537, 88530 }, label = L["Skin_Drops"], max = 5, note = L["Prof_Note_SkinningFive"] },
        { key = "skin_bone",     questIds = { 88529 }, label = L["Skin_Bone"], max = 1, note = L["Prof_Note_SkinningBonus"] },
        { key = "skin_treatise", questIds = { 95136 }, label = L["Skin_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "skin_dmf",      questIds = { 29519 }, label = L["DMF_Skin_Label"], note = L["DMF_Skin_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3191, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})

local LURE_ITEM_ZULAMAN   = 238653
local LURE_ITEM_HARANDAR  = 238654
local LURE_ITEM_VOIDSTORM = 238655
local LURE_ITEM_GRAND     = 238656
local LURE_QUEST_EVERSONG = 88545
local LURE_QUEST_ZULAMAN  = 88526
local LURE_QUEST_HARANDAR = 88531
local LURE_QUEST_VOIDSTORM = 88532
local LURE_QUEST_GRAND    = 88524

local function KnowsLureRecipe(itemID)
    if not itemID then return true end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfoForItemID then
        return C_TradeSkillUI.GetRecipeInfoForItemID(itemID) ~= nil
    end
    return true
end

MR:RegisterModule({
    key           = "skin_lures",
    profSkillLine = 2917,
    label         = L["Skin_Lures_Title"],
    labelColor    = "#c8a060",
    resetType     = "daily",
    defaultOpen   = false,
    rows = {
        {
            key   = "lure_eversong",
            label = L["Skin_Lure_Eversong"],
            questIds = { LURE_QUEST_EVERSONG },
            zone  = 2395,
            x     = 41.95,
            y     = 80.05,
            waypointTitle = "Eversong (Ghostclaw Elder)",
            max   = 1,
            note  = L["Skin_Lure_Eversong_Note"],
        },
        {
            key       = "lure_zulaman",
            label     = L["Skin_Lure_Zulaman"],
            questIds  = { LURE_QUEST_ZULAMAN },
            zone      = 2437,
            x         = 47.69,
            y         = 53.25,
            waypointTitle = "Zul'Aman (Silverscale)",
            max       = 1,
            note      = L["Skin_Lure_Zulaman_Note"],
            isVisible = function() return KnowsLureRecipe(LURE_ITEM_ZULAMAN) end,
        },
        {
            key       = "lure_harandar",
            label     = L["Skin_Lure_Harandar"],
            questIds  = { LURE_QUEST_HARANDAR },
            zone      = 2413,
            x         = 66.28,
            y         = 47.91,
            waypointTitle = "Harandar (Lumenfin)",
            max       = 1,
            note      = L["Skin_Lure_Harandar_Note"],
            isVisible = function() return KnowsLureRecipe(LURE_ITEM_HARANDAR) end,
        },
        {
            key       = "lure_voidstorm",
            label     = L["Skin_Lure_Voidstorm"],
            questIds  = { LURE_QUEST_VOIDSTORM },
            zone      = 2405,
            x         = 54.60,
            y         = 65.80,
            waypointTitle = "Voidstorm (Umbrafang)",
            max       = 1,
            note      = L["Skin_Lure_Voidstorm_Note"],
            isVisible = function() return KnowsLureRecipe(LURE_ITEM_VOIDSTORM) end,
        },
        {
            key       = "lure_grand",
            label     = L["Skin_Lure_Grand"],
            questIds  = { LURE_QUEST_GRAND },
            zone      = 2405,
            x         = 43.25,
            y         = 82.75,
            waypointTitle = "Voidstorm - Grand Beast Lure (Netherscythe)",
            max       = 1,
            note      = L["Skin_Lure_Grand_Note"],
            isVisible = function() return KnowsLureRecipe(LURE_ITEM_GRAND) end,
        },
    },
})

MR:RegisterModule({
    key           = "prof_tailoring",
    profSkillLine = 2918,
    label         = L["Tailoring"],
    labelColor    = "#ffaadd",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "tail_notebook", questIds = { 93696 }, label = L["Tail_Quest"], max = 1, note = L["Prof_Note_ServiceQuest"], zone = PROF_HUB.crafting.zone, x = PROF_HUB.crafting.x, y = PROF_HUB.crafting.y },
        { key = "tail_drops",    questIds = { 93542, 93543 }, label = L["Tail_Drops"], max = 2, note = L["Prof_Note_CraftingDrops"] },
        { key = "tail_treatise", questIds = { 95137 }, label = L["Tail_Treatise"], max = 1, note = L["Prof_Note_Treatise"], zone = PROF_HUB.treatise.zone, x = PROF_HUB.treatise.x, y = PROF_HUB.treatise.y },
        { key = "tail_dmf",      questIds = { 29520 }, label = L["DMF_Tail_Label"], note = L["DMF_Tail_Note"], max = 1, isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end },
        { key = "prof_catchup", currencyId = 3190, noBlizzardTooltip = true, hideWallet = true, label = L["Prof_Catchup"], note = L["Prof_Catchup_Note"], max = 0 },
    },
})
