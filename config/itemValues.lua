
return {
    itemValues = {
        -- Define value of crafting time, in percentage points per second.
        -- For example, a recipe has a total product value of 10, and timeMultiplier = 0.0125, and the recipe takes 8 seconds to craft, then its value is incremented by 10%, so its final value is 11.
        timeMultiplier = 0.025, -- 1 second
        timeMultiplierMax = 0.25, -- Cap out the bonus at this value (e.g. +50% bonus is 0.5).  This keeps modules from getting way too valuable.

        -- Apply multipliers to values of items if the item requires both fluids and items to produce.
        -- This bonus also applies to the increment of the value of uranium ore by sulfuric acid's value, but this is the only exception.
        itemFluidComplexityMultiplier = 0.25, -- e.g. +10% bonus = 0.1

        -- Apply multipliers to values of items for each ingredient in the recipe to product the item(s).
        complexityMultiplier = 0.14, -- e.g. +5% bonus = 0.05

        defaultItemValue = 1, -- If a raw item is not found in the lookup table, this is the default value to use.

        raw = {
            -- Raw materials
            ["wood"] = 4,
            ["iron-ore"] = 6,
            ["copper-ore"] = 5,
            ["stone"] = 2,
            ["coal"] = 2.4,
            ["uranium-ore"] = 12, -- later gets incremented by sulfuric acid value
            ["water"] = 0, -- requires no power to extract and is infinite in supply
            ["crude-oil"] = 0.25,
            ["raw-fish"] = 8,
            ["steam"] = 0.001, -- can be produced by heat exchangers, requiring very little fuel for massive amounts of steam

            ["loader"] = 250,
            ["fast-loader"] = 600,
            ["express-loader"] = 2000,

            -- Scale the value of coins up or down.  A lower number means items will cost and sell for more coins.  Inversely, a higher number means items will cost and sell for fewer coins.
            -- This does not affect item-to-item trading, where coins are not used.
            ["coin"] = 120,
        },

        multipliers = {
            -- add extra value to items like requester and buffer chests because they are relatively useful for their crafting recipe
            ["logistic-chest-requester"] = 0.25,
            ["logistic-chest-buffer"] = 0.25,
            ["artillery-turret"] = 0.15,
            ["artillery-wagon"] = 0.2, -- can hold more shells and is portable and is cheaper to craft than the turret, so its value is much higher than its material cost implies
            ["artillery-shell"] = 0.25,
            ["roboport"] = 0.1,
            ["spidertron"] = 0.35,
            ["atomic-bomb"] = 0.2,
        },
    }
}
