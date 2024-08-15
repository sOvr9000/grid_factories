
return {
    -- Chance for each chunk to be a biter nest.
    biterChunkChance = 0.23,

    -- The scaling on the probability that bigger worms will be spawned based on distance from spawn.
    wormEvolutionOverDistance = 0.0005,

    -- The minimum distance from spawn that a big worm will spawn.
    bigWormMinDistance = 160,

    -- The minimum distance from spawn that a behemoth worm will spawn.
    behemothWormMinDistance = 256,

    -- Chance for each position in a biter chunk to be a spawner.
    biterChunkSpawnerChance = 0.15,

    -- Chance for each position in a biter chunk to be a worm.  Spawners take precedence over worms.
    biterChunkWormChance = 0.18,

    -- Chance for each chunk to be secretly and permanently infested by biters.
    infestedChunkChance = 0.02,

    -- Minimum distance from spawn at which infested chunks can be generated.
    infestedChunkMinDistance = 320,

    -- Biter settings within void dimensions, based on satisfaction level met with the dimensional chunk purchase.
    voidDimensionBiters = {
        [1] = {
            spawnersPerChunkMin = 6,
            spawnersPerChunkMax = 10,
            wormsPerChunkMin = 3,
            wormsPerChunkMax = 4,
        },
        [2] = {
            spawnersPerChunkMin = 4,
            spawnersPerChunkMax = 8,
            wormsPerChunkMin = 2,
            wormsPerChunkMax = 3,
        },
        [3] = {
            spawnersPerChunkMin = 2,
            spawnersPerChunkMax = 2,
            wormsPerChunkMin = 1,
            wormsPerChunkMax = 1,
        },
    },
}
