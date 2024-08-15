
return {
    -- Starting cost of removing a wall in coins.
    chunkUnlockCostInitial = 4,

    -- Increment of the wall removal cost as each wall is removed.
    chunkUnlockCostIncrement = 1,

    -- Maximum wall removal cost.  Does not increase any higher than this.
    chunkUnlockCostMax = 500,

    -- The tile to be placed in all unreached chunks.
    unexploredTile = "black-refined-concrete",

    -- The tile to be placed in all reached chunks.  When a wall is removed, this tile covers the newly reached chunk.
    exploredTile = "refined-concrete",

    -- The tile to be placed in all chunks within the void dimensions.
    voidTile = "brown-refined-concrete",

    -- The negative space tile in the void dimensions.
    voidTileAlt = "red-refined-concrete",
}
