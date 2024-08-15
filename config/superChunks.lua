
return {
    superChunks = {
        -- The chance of a super chunk generating when it's at its minimum distance from spawn.
        minChance = 0.01,

        -- The chance of a super chunk generating when it's at its maximum distance from spawn or farther.
        maxChance = 0.5,

        -- Minimum distance from spawn at which a super chunk can generate.
        -- This is where the chance of a super chunk is at its minimum.
        minDistance = 784,

        -- The distance at which the super chunk chance is at its maximum.
        maxDistance = 1300,
    },

    greatRingOfSuperChunks = {
        -- The distance a which void chunks are guaranteed to generate until the upgrade "Reduced Void Chunk Chance" is unlocked.
        voidRadius = 1250,

        -- The distance at which the great ring starts.
        fadeInRadius = 1300,

        -- The inner radius of The Great Ring of Super Chunks.
        innerRadius = 1350,

        -- The outer radius of The Great Ring of Super Chunks.
        outerRadius = 1400,

        -- The distance at which the great ring ends.
        fadeOutRadius = 1450,
    },
}
