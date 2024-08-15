
return {
    -- Distribution of ores in the starter chunk.
    starterOresWeights = {
        ["iron-ore"] = 5,
        ["copper-ore"] = 0, -- (as a small challenge, copper wires are initially obtained through market trades)
        ["stone"] = 1.5,
        ["coal"] = 3,
    },

    -- General distribution of ores in most chunks.
    oreWeights = {
        ["iron-ore"] = 6,
        ["copper-ore"] = 5,
        ["stone"] = 2,
        ["coal"] = 2.8,
        -- ["iron-ore"] = 1,
        -- ["copper-ore"] = 1,
        -- ["stone"] = 1,
        -- ["coal"] = 1,
    },

    -- Chance of a chunk to contain an ore deposit.
    baseOreChance = 0.25,

    -- Size of ore deposits.
    baseOreSize = 2.5,

    -- Initial number of crude oil nodes in a chunk if it has crude oil.
    baseCrudeOilAmount = 2,

    -- Initial ore richness.
    baseOreRichness = 190,

    -- Add this much to baseOreRichness for each unit of distance away from spawn.
    oreRichnessOverDistance = 3,

    -- Chance of any ore deposit to become uranium ore, unmixed with anything else.
    uraniumOreChance = 0.05,

    -- The distance from spawn at which chunks can have uranium ore.
    uraniumOreMinDistance = 256,

    -- Chance of any ore deposit to become crude oil.
    crudeOilChance = 0.05,

    -- The distance from spawn at which chunks can have crude oil.
    crudeOilMinDistance = 64,

    -- The degree to which ore deposits have mixed ores.  0 is unmixed (full bias towards one ore type), 1 is standard mixture, and higher numbers are more mixed.  Around 10 is approximately maximum mixture.
    -- Does not override mixture of starting chunk ore since that can make it impossible to escape the first chunk.
    oreMixture = 1.25,

    -- Super chunks add this amount to baseCrudeOilAmount.
    superChunkCrudeOilAmountIncrement = 5,

    -- Biter chunks add this amount to the baseOreSize.
    biterChunkOreSizeIncrement = 2,

    -- Biter chunks multiply the ore richness by this amount.
    biterChunkOreRichnessMultiplier = 3,

    -- Biter chunks add this amount to baseCrudeOilAmount.
    biterChunkCrudeOilAmountIncrement = 1,
}
