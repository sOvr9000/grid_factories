
return {

    -- Chance of a ruins chunk generating.  These chunks have no ore coverage and no market trades, but they have random, damaged buildings inside them and usually loot chests but also turrets that can kill you.
    ruinsChunkChance = 0.1,

    -- Number of buildings generated per ruins chunk.
    ruinsChunkNumBuildingsMin = 4,
    ruinsChunkNumBuildingsMax = 40,

    -- Possible buildings to be generated in a ruins chunk.
    -- If a chest is generated, then it will have loot.
    -- The numbers associated with each building are the relative weights on the probability for each building to be generated.
    ruinsChunkBuildings = {
        ["solar-panel"] = 5,
        ["accumulator"] = 4,
        ["gun-turret"] = 1,
        ["laser-turret"] = 0.5,
        ["roboport"] = 0.1,
        ["steel-chest"] = 1,
        ["storage-tank"] = 0.5,
        ["radar"] = 0.25,
        ["centrifuge"] = 0.15,
        ["beacon"] = 0.15,
        ["substation"] = 1,
        ["artillery-turret"] = 0.25,
        ["flamethrower-turret"] = 0.5,
    },

    -- Possible loot to be generated in a ruins chest.  The probabilities for each item are derived from itemValues (basically their coin values), which results in balanced loot generation on average.
    ruinsChestLoot = {
        "iron-plate",
        "copper-plate",
        "steel-plate",
        "iron-gear-wheel",
        "copper-cable",
        "electronic-circuit",
        "locomotive",
        "cargo-wagon",
        "fluid-wagon",
        "rail",
        "rail-signal",
        "rail-chain-signal",
        "train-stop",
        "electric-mining-drill",
        "pumpjack",
        "productivity-module",
        "speed-module",
        "fast-transport-belt",
        "fast-underground-belt",
        "fast-splitter",
        "inserter",
        "fast-inserter",
        "stack-inserter",
        "long-handed-inserter",
        "advanced-circuit",
        "low-density-structure",
        "engine-unit",
        "electric-engine-unit",
        "pump",
        "steel-chest",
        "assembling-machine-2",
        "small-lamp",
        "medium-electric-pole",
        "big-electric-pole",
        "substation",
        "piercing-rounds-magazine",
        "uranium-rounds-magazine",
        "roboport",
        "solar-panel",
        "accumulator",
        "loader",
        "fast-loader",
    },

    -- The total value of items in a ruins chunk.  Each chest shares this "budget", so two loot chests add to the same value as one alone.
    ruinsChestLootValueMin = 4000,
    ruinsChestLootValueMax = 10000,

    -- Additional value of loot in each ruins chunk for each turret added to the ruins chunk (which adds difficulty to obtaining it).
    ruinsChestLootValuePerTurret = 2500,

    -- Additional value of loot in each ruins chunk for each unit of distance away from spawn.
    ruinsChestLootValueOverDistance = 48,

    -- global.ruinsChestLootVariation = "varied"        -- Chests have more types of items but less of each type.
    ruinsChestLootVariation = "unchanged",
    -- global.ruinsChestLootVariation = "unvaried"      -- Chests have fewer types of items but more of each type.

    -- The distance from spawn at which artillery turrets in ruins chunks are loaded with artillery shells.  This lets you build a starter base but makes you be careful as you expand.
    artilleryLoadShellDistance = 280,

    -- Chance of artillery turrets in ruins chunks being loaded with artillery shells.
    artilleryLoadShellChance = 0.5,
}
