
return {
    -- Satisfaction levels from offers made to void chunks which are then turned into dimensional chunks if level > 0
    -- These requirements are measured in total coin value provided to the blue chests.
    dimChunkSatLevelRequirements = {
        ["0"] = 0, -- should leave this at zero, but it's here to help convey the idea of how this feature works
        ["1"] = 10000,
        ["2"] = 100000,
        ["3"] = 2000000,
    },

    initialInfinityLoot = "iron-gear-wheel",
}
