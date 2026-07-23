local _, ns = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local T, S, WQ, WD, DMF, TR, Ref = ns.T, ns.S, ns.WQ, ns.WD, ns.DMF, ns.TR, ns.Ref
local DRAGONFLIGHT_CATCHUP_ITEM_ID = ns.DRAGONFLIGHT_CATCHUP_ITEM_ID

local DRAGONFLIGHT_EXPANSION = {
        key = "dragonflight",
        label = L["ProfKnowledge_LegacySection_Dragonflight"] or "Dragonflight",
        sharedCatchupItemID = DRAGONFLIGHT_CATCHUP_ITEM_ID,
        professions = {
            { key = "alchemy", label = L["Alchemy"], skillLine = 2823, weekly = {
                TR{ spellID = 383522, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
            }, treasures = {
                T{ questID = 70289, kp = 3, zone = 2022, x = 25.1, y = 73.3, label = "Well-Insulated Mug", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70274, kp = 3, zone = 2022, x = 55.0, y = 81.0, label = "Frostforged Potion", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70305, kp = 3, zone = 2023, x = 79.2, y = 83.8, label = "Canteen of Suspicious Water", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70208, kp = 3, zone = 2024, x = 16.4, y = 38.5, label = "Experimental Decay Sample", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70309, kp = 3, zone = 2024, x = 67.0, y = 13.2, label = "Firewater Powder Sample", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70278, kp = 3, zone = 2025, x = 55.2, y = 30.5, label = "Tasty Candy", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70301, kp = 3, zone = 2025, x = 59.5, y = 38.4, label = "Contraband Concoction", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75649, kp = 3, zone = 2133, x = 62.10, y = 41.12, label = "Marrow-Ripened Slime", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75646, kp = 3, zone = 2133, x = 52.68, y = 18.30, label = "Nutrient Diluted Protofluid", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75651, kp = 3, zone = 2133, x = 40.48, y = 59.18, label = "Suspicious Mold", note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Alchemist's Research", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Alchemist's Research", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Alchemist's Research", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "blacksmithing", label = L["Blacksmithing"], skillLine = 2822, weekly = {
                TR{ spellID = 383517, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
                WQ{ questID = 70589, kp = 2, note = L["ProfKnowledge_ServiceQuest"] },
            }, treasures = {
                T{ questID = 70232, kp = 3, zone = 2022, x = 56.4, y = 19.5, label = "Glimmer of Blacksmithing Wisdom", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70246, kp = 3, zone = 2022, x = 22.0, y = 87.0, label = "Ancient Monument", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70312, kp = 3, zone = 2022, x = 65.5, y = 25.7, label = "Curious Ingots", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70296, kp = 3, zone = 2022, x = 35.5, y = 64.3, label = "Molten Ingot", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70310, kp = 3, zone = 2022, x = 34.5, y = 67.1, label = "Qalashi Weapon Diagram", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70313, kp = 3, zone = 2023, x = 81.1, y = 37.9, label = "Ancient Spear Shards", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70353, kp = 3, zone = 2023, x = 50.9, y = 66.5, label = "Falconer Gauntlet Drawings", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70314, kp = 3, zone = 2024, x = 53.1, y = 65.3, label = "Spelltouched Tongs", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70311, kp = 3, zone = 2025, x = 52.2, y = 80.5, label = "Draconic Flux", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76079, kp = 3, zone = 2133, x = 48.30, y = 21.95, label = "Brimstone Rescue Ring", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76078, kp = 3, zone = 2133, x = 57.15, y = 54.64, label = "Well-Worn Kiln", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76080, kp = 3, zone = 2133, x = 27.53, y = 42.87, label = "Zaqali Elder Spear", note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Blacksmith's Diagrams", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Blacksmith's Diagrams", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Blacksmith's Diagrams", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "enchanting", label = L["Enchanting"], skillLine = 2825, weekly = {
                TR{ spellID = 383523, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
            }, treasures = {
                T{ questID = 70320, kp = 3, zone = 2022, x = 57.5, y = 83.6, label = "Flashfrozen Scroll", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70283, kp = 3, zone = 2022, x = 68.0, y = 26.8, label = "Lava-Infused Seed", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70272, kp = 3, zone = 2022, x = 57.5, y = 58.5, label = "Enchanted Debris", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70291, kp = 3, zone = 2023, x = 61.4, y = 67.6, label = "Stormbound Horn", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70336, kp = 3, zone = 2024, x = 38.5, y = 59.2, label = "Forgotten Arcane Tome", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70290, kp = 3, zone = 2024, x = 45.1, y = 61.2, label = "Faintly Enchanted Remains", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70298, kp = 3, zone = 2024, x = 21.0, y = 45.0, label = "Enriched Earthen Shard", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70342, kp = 3, zone = 2025, x = 59.9, y = 70.4, label = "Fractured Titanic Sphere", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75508, kp = 3, zone = 2133, x = 48.00, y = 17.00, label = "Lava-Drenched Shadow Crystal", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75510, kp = 3, zone = 2133, x = 36.66, y = 69.33, label = "Resonating Arcane Crystal", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75509, kp = 3, zone = 2133, x = 62.39, y = 53.80, label = "Shimmering Aqueous Orb", note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Enchanter's Research", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Enchanter's Research", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Enchanter's Research", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "engineering", label = L["Engineering"], skillLine = 2827, weekly = {
                TR{ spellID = 383844, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
            }, treasures = {
                T{ questID = 70270, kp = 3, zone = 2022, x = 56.0, y = 44.9, label = "Boomthyr Rocket", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70275, kp = 3, zone = 2022, x = 49.09, y = 77.54, label = "Intact Coil Capacitor", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75186, kp = 3, zone = 2133, x = 37.82, y = 58.83, label = "Busted Wyrmhole Generator", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75184, kp = 3, zone = 2133, x = 50.51, y = 47.93, label = "Defective Survival Pack", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75431, kp = 3, zone = 2133, x = 49.44, y = 79.01, label = "Discarded Dracothyst Drill", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75430, kp = 3, zone = 2133, x = 57.65, y = 73.94, label = "Handful of Khaz'gorite Bolts", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75183, kp = 3, zone = 2133, x = 48.17, y = 27.93, label = "Haphazardly Discarded Bomb", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75188, kp = 3, zone = 2133, x = 49.87, y = 59.25, label = "Inconspicuous Data Miner", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75180, kp = 3, zone = 2133, x = 48.48, y = 48.64, label = "Misplaced Aberrus Outflow Blueprints", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75433, kp = 3, zone = 2133, x = 48.10, y = 16.59, label = "Overclocked Determination Core", note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Engineer's Scribblings", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Engineer's Scribblings", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Engineer's Scribblings", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "herbalism", label = L["Herbalism"], skillLine = 2832, weekly = {
                TR{ spellID = 383515, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Herbalist's Notes", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Herbalist's Notes", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Herbalist's Notes", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "inscription", label = L["Inscription"], skillLine = 2828, weekly = {
                TR{ spellID = 383759, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
                WQ{ questID = 70592, kp = 2, note = L["ProfKnowledge_ServiceQuest"] },
            }, treasures = {
                T{ questID = 70306, kp = 3, zone = 2022, x = 67.87, y = 57.96, label = "Pulsing Earth Rune", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70307, kp = 3, zone = 2023, x = 85.7, y = 25.2, label = "Sign Language Reference Sheet", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70297, kp = 3, zone = 2024, x = 46.2, y = 23.9, label = "Dusty Darkmoon Card", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70293, kp = 3, zone = 2024, x = 43.7, y = 30.9, label = "Frosted Parchment", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70281, kp = 3, zone = 2112, x = 13.2, y = 63.68, label = "How to Train Your Whelpling", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70264, kp = 3, zone = 2025, x = 56.3, y = 41.2, label = "Forgetful Apprentice's Tome", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70248, kp = 3, zone = 2025, x = 47.24, y = 40.1, label = "Forgetful Apprentice's Tome", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70287, kp = 3, zone = 2025, x = 56.1, y = 40.9, label = "Counterfeit Darkmoon Deck", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76120, kp = 3, zone = 2133, x = 53.01, y = 74.27, label = "Hissing Rune Draft", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76121, kp = 3, zone = 2133, x = 54.57, y = 20.21, label = "Ancient Research", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76117, kp = 3, zone = 2133, x = 36.73, y = 46.32, label = "Intricate Zaqali Runes", note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Scribe's Runic Drawings", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Scribe's Runic Drawings", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Scribe's Runic Drawings", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "jewelcrafting", label = L["Jewelcrafting"], skillLine = 2829, weekly = {
                TR{ spellID = 383524, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
                WQ{ questID = 70593, kp = 2, note = L["ProfKnowledge_ServiceQuest"] },
            }, treasures = {
                T{ questID = 70292, kp = 3, zone = 2022, x = 50.4, y = 45.1, label = "Closely Guarded Shiny", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70273, kp = 3, zone = 2022, x = 33.9, y = 63.7, label = "Igneous Gem", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70282, kp = 3, zone = 2023, x = 25.2, y = 35.4, label = "Lofty Malygite", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70263, kp = 3, zone = 2023, x = 61.8, y = 13.0, label = "Fragmented Key", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70277, kp = 3, zone = 2024, x = 45.0, y = 61.3, label = "Crystalline Overgrowth", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70271, kp = 3, zone = 2024, x = 44.6, y = 61.2, label = "Harmonic Crystal Harmonizer", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70285, kp = 3, zone = 2025, x = 59.8, y = 65.2, label = "Alexstraszite Cluster", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70261, kp = 3, zone = 2025, x = 56.91, y = 43.72, label = "Painter's Pretty Jewel", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75654, kp = 3, zone = 2133, x = 54.41, y = 32.47, label = "Broken Barter Boulder", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75653, kp = 3, zone = 2133, x = 34.47, y = 45.43, label = "Gently Jostled Jewels", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75652, kp = 3, zone = 2133, x = 40.37, y = 80.66, label = "Snubbed Snail Shells", note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Jeweler's Illustrations", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Jeweler's Illustrations", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Jeweler's Illustrations", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "leatherworking", label = L["Leatherworking"], skillLine = 2830, weekly = {
                TR{ spellID = 383519, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
                WQ{ questID = 70594, kp = 2, note = L["ProfKnowledge_ServiceQuest"] },
            }, treasures = {
                T{ questID = 70308, kp = 3, zone = 2022, x = 39.0, y = 86.0, label = "Poacher's Pack", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70280, kp = 3, zone = 2022, x = 64.3, y = 25.4, label = "Spare Djaradin Tools", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70300, kp = 3, zone = 2023, x = 86.4, y = 53.7, label = "Wind-Blessed Hide", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70269, kp = 3, zone = 2024, x = 12.5, y = 49.4, label = "Well-Danced Drum", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70266, kp = 3, zone = 2024, x = 16.7, y = 38.8, label = "Decay-Infused Tanning Oil", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70286, kp = 3, zone = 2024, x = 57.5, y = 41.3, label = "Treated Hides", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70294, kp = 3, zone = 2025, x = 56.8, y = 30.5, label = "Decayed Scales", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75495, kp = 3, zone = 2133, x = 41.16, y = 48.81, label = "Flame-Infused Scale Oil", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75496, kp = 3, zone = 2133, x = 45.25, y = 21.12, label = "Lava-Forged Leatherworker's Knife", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75502, kp = 3, zone = 2133, x = 49.56, y = 54.80, label = "Sulfur-Soaked Skins", note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Leatherworker's Diagrams", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Leatherworker's Diagrams", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Leatherworker's Diagrams", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "mining", label = L["Mining"], skillLine = 2833, weekly = {
                TR{ spellID = 383516, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Miner's Notes", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Miner's Notes", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Miner's Notes", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "skinning", label = L["Skinning"], skillLine = 2834, weekly = {
                TR{ spellID = 392944, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Skinner's Notes", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Skinner's Notes", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Skinner's Notes", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
            { key = "tailoring", label = L["Tailoring"], skillLine = 2831, weekly = {
                TR{ spellID = 383520, kp = 1, note = L["ProfKnowledge_TreatiseNote"] },
                WQ{ questID = 70595, kp = 2, note = L["ProfKnowledge_ServiceQuest"] },
            }, treasures = {
                T{ questID = 70302, kp = 3, zone = 2022, x = 74.7, y = 37.9, label = "Mysterious Banner", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70304, kp = 3, zone = 2022, x = 24.9, y = 69.7, label = "Itinerant Singed Fabric", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70295, kp = 3, zone = 2023, x = 35.34, y = 40.12, label = "Noteworthy Scrap of Carpet", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70303, kp = 3, zone = 2023, x = 66.1, y = 52.9, label = "Silky Surprise", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70284, kp = 3, zone = 2024, x = 16.2, y = 38.8, label = "Decaying Brackenhide Blanket", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70267, kp = 3, zone = 2024, x = 40.7, y = 54.5, label = "Intriguing Bolt of Blue Cloth", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70288, kp = 3, zone = 2025, x = 60.4, y = 79.7, label = "Miniature Bronze Dragonflight Banner", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70372, kp = 3, zone = 2025, x = 58.6, y = 45.8, label = "Ancient Dragonweave Bolt", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76102, kp = 3, zone = 2133, x = 47.21, y = 48.55, label = "Abandoned Reserve Chute", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76116, kp = 3, zone = 2133, x = 44.52, y = 15.65, label = "Exquisitely Embroidered Banner", note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76110, kp = 3, zone = 2133, x = 59.11, y = 73.14, label = "Used Medical Wrap Kit", note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Dusty Tailor's Diagrams", note = "Rabul — Valdrakken (100 Artisan's Mettle, Preferred rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Rare Tailor's Diagrams", note = "Rabul — Valdrakken (150 Artisan's Mettle, Valued rep)" },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, label = "Ancient Tailor's Diagrams", note = "Rabul — Valdrakken (200 Artisan's Mettle, Esteemed rep)" },
            } },
        },
}

ns.RegisterLegacyExpansion(DRAGONFLIGHT_EXPANSION)
ns.RegisterProfessionWeeklyModules("dragonflight", DRAGONFLIGHT_EXPANSION.professions)
