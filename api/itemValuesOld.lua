
local util = require "api/gutil"

-- -- Define value of crafting time, in percentage points per second.
-- -- For example, a recipe has a total product value of 10, and timeMultiplier = 0.0125, and the recipe takes 8 seconds to craft, then its value is incremented by 10%, so its final value is 11.
-- local timeMultiplier = 0.025 -- 1 second
-- local timeMultiplierMax = 0.25 -- Cap out the bonus at this value (e.g. +50% bonus is 0.5).  This keeps modules from getting way too valuable.

-- -- Apply multipliers to values of items if the item requires both fluids and items to produce.
-- -- This bonus also applies to the increment of the value of uranium ore by sulfuric acid's value, but this is the only exception.
-- local itemFluidComplexityMultiplier = 0.25 -- e.g. +10% bonus = 0.1

-- -- Apply multipliers to values of items for each ingredient in the recipe to product the item(s).
-- local complexityMultiplier = 0.14 -- e.g. +5% bonus = 0.05

-- -- Scale the value of coins up or down.  A lower number means items will cost and sell for more coins.  Inversely, a higher number means items will cost and sell for fewer coins.
-- -- This does not affect item-to-item trading, where coins are not used.
-- local coinScaling = 120

local itemValues = {
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
    ["express-loader"] = 1500,

    ["coin"] = coinScaling,
}

local itemValueMultipliers = {
    -- add extra value to items like requester and buffer chests because they are relatively useful for their crafting recipe
    ["logistic-chest-requester"] = 0.25,
    ["logistic-chest-buffer"] = 0.25,
    ["artillery-turret"] = 0.15,
    ["artillery-wagon"] = 0.2, -- can hold more shells and is portable and is cheaper to craft than the turret, so its value is much higher than its material cost implies
    ["artillery-shell"] = 0.25,
    ["roboport"] = 0.1,
    ["spidertron"] = 0.35,
    ["atomic-bomb"] = 0.2,
}

function itemValues.get(name, registerAll)
    local value = itemValues[name]
    if not value then
        if registerAll then
            itemValues.registerAll()
        else
            log("Unknown item name: " .. name)
        end
    end
    return value
end

function itemValues.set(name, value)
    itemValues[name] = value
    -- log("Set item value: " .. name .. " = " .. value)
end

function itemValues.exists(name)
    return itemValues[name] ~= nil
end

function itemValues.remove(name)
    itemValues[name] = nil
end

local recipeOrder = {
    -- Wood, ore, and oil derivatives, and misc recipes (depth 1 recipes)
    "wooden-chest",
    "iron-plate",
    "copper-plate",
    "advanced-oil-processing",
    "stone-brick",
    "landfill",
    "stone-furnace",
    
    -- Depth 2 recipes
    "iron-chest",
    "iron-gear-wheel",
    "iron-stick",
    "copper-cable",
    "steel-plate",
    "plastic-bar",
    "pipe",
    "sulfur",
    "lubricant",
    "concrete",
    "grenade",
    "solid-fuel-from-petroleum-gas", -- the one that's likely to be used in the game
    "firearm-magazine",
    "stone-wall",
    "pistol",
    "shotgun-shell",
    "light-armor",

    -- Depth 3 recipes
    "steel-chest",
    "storage-tank",
    "transport-belt",
    "burner-inserter",
    "electronic-circuit",
    "small-electric-pole",
    "medium-electric-pole",
    "big-electric-pole",
    "pipe-to-ground",
    "engine-unit",
    "rail",
    "cargo-wagon",
    "sulfuric-acid",
    "low-density-structure",
    "hazard-concrete",
    "refined-concrete",
    "empty-barrel",
    "explosives",
    "boiler",
    "steam-engine",
    "heat-pipe",
    "heat-exchanger",
    "steam-turbine",
    "burner-mining-drill",
    "steel-furnace",
    "rocket-fuel",
    "automation-science-pack",
    "piercing-rounds-magazine",
    "submachine-gun",
    "shotgun",
    "combat-shotgun",
    "flamethrower",
    "piercing-shotgun-shell",
    "flamethrower-ammo",
    "heavy-armor",
    "gun-turret",
    
    -- Depth 4 recipes
    "fast-transport-belt",
    "underground-belt",
    "splitter",
    "inserter",
    "advanced-circuit",
    "pump",
    "train-stop",
    "rail-signal",
    "rail-chain-signal",
    "locomotive",
    "fluid-wagon",
    "car",
    "electric-engine-unit",
    "radar",
    "rocket-launcher",
    "battery",
    "small-lamp",
    "red-wire",
    "green-wire",
    "arithmetic-combinator",
    "decider-combinator",
    "constant-combinator",
    "power-switch",
    "programmable-speaker",
    "refined-hazard-concrete",
    "cliff-explosives",
    "repair-pack",
    "solar-panel",
    "electric-mining-drill",
    "offshore-pump",
    "pumpjack",
    "assembling-machine-1",
    "oil-refinery",
    "chemical-plant",
    "lab",
    "uranium-processing", -- uranium ore needs sulfuric acid to mine, so this is technically after sulfuric acid even though the recipe alone takes only uranium ore
    "military-science-pack",
    "land-mine",
    "cannon-shell",
    "explosive-cannon-shell",
    "rocket",
    "cluster-grenade",
    "poison-capsule",
    "slowdown-capsule",
    "defender-capsule",
    "discharge-defense-remote",
    "gate",
    "flamethrower-turret",

    -- Depth 5 recipes
    "express-transport-belt",
    "fast-underground-belt",
    "fast-splitter",
    "long-handed-inserter",
    "substation",
    "artillery-wagon",
    "tank",
    "effectivity-module",
    "processing-unit",
    "speed-module",
    "flying-robot-frame",
    "logistic-chest-active-provider",
    "logistic-chest-passive-provider",
    "logistic-chest-storage",
    "logistic-chest-buffer",
    "logistic-chest-requester",
    "roboport",
    "accumulator",
    "nuclear-reactor",
    "electric-furnace",
    "assembling-machine-2",
    "centrifuge",
    "beacon",
    "productivity-module",
    "nuclear-fuel",
    "uranium-fuel-cell",
    "logistic-science-pack",
    "chemical-science-pack",
    "uranium-rounds-magazine",
    "uranium-cannon-shell",
    "explosive-uranium-cannon-shell",
    "artillery-shell",
    "explosive-rocket",
    "distractor-capsule",
    "modular-armor",
    "solar-panel-equipment",
    "battery-equipment",
    "belt-immunity-equipment",
    "personal-roboport-equipment",
    "night-vision-equipment",
    "energy-shield-equipment",
    "laser-turret",
    "artillery-turret",

    -- Depth 6 recipes
    "express-underground-belt",
    "express-splitter",
    "fast-inserter",
    "effectivity-module-2",
    "exoskeleton-equipment",
    "fusion-reactor-equipment",
    "rocket-control-unit",
    "logistic-robot",
    "construction-robot",
    "assembling-machine-3",
    "speed-module-2",
    "productivity-module-2",
    "rocket-silo",
    "satellite",
    "production-science-pack",
    "utility-science-pack",
    "destroyer-capsule",
    "battery-mk2-equipment",
    "personal-roboport-mk2-equipment",
    "energy-shield-mk2-equipment",
    "personal-laser-defense-equipment",
    "discharge-defense-equipment",
    "artillery-targeting-remote",

    -- Depth 7 recipes
    "filter-inserter",
    "stack-inserter",
    "effectivity-module-3",
    "spidertron-remote",
    "speed-module-3",
    "productivity-module-3",
    "rocket-part", -- needed to calculate space science pack value
    "atomic-bomb",
    "power-armor-mk2",

    -- Depth 8 recipes
    "stack-filter-inserter",
    "spidertron",
}

function itemValues.registerAll()
    local prot, totalValue, totalAmount, timeMult, complexityMult, resultValue, resultAmount, itemValue
    for _, recipeName in pairs(recipeOrder) do
        prot = game.recipe_prototypes[recipeName]

        if not prot then
            log("ERROR: Recipe ".. recipeName.. " does not exist.")
        end

        -- Retrieve the item values of all ingredients.
        totalValue = 0
        -- log("Registering recipe: " .. prot.name)
        for _, ingredient in pairs(prot.ingredients) do
            if not itemValues.exists(ingredient.name) then
                log("Bad order for recipes.  Need to register item value for " .. ingredient.name .. " in order to register " .. prot.name)
            else
                totalValue = totalValue + itemValues.get(ingredient.name) * ingredient.amount
            end
        end

        -- Determine the item values of all results.
        totalAmount = 0
        -- local products = util.getRecipeProducts(prot)
        for _, result in pairs(prot.products) do
            if not itemValues.exists(result.name) then
                local totalAmountInc = 0
                if result.type == "fluid" then
                    totalAmountInc = result.amount / 1000
                else
                    totalAmountInc = result.amount
                end
                if result.probability then
                    totalAmountInc = totalAmountInc * result.probability
                end
                -- log("Recipe: " .. prot.name.. " total amount incremented by " .. totalAmountInc.. " from ".. result.name)
                totalAmount = totalAmount + totalAmountInc
            end
        end
        if totalAmount <= 0 or #prot.products <= 0 then
            log("Something unexpected occurred.  Calculated total value of results in recipe " .. prot.name .. " is not positive, or all products are already calculated.")
            return
        end

        -- Now update the values and apply the multipliers.
        -- For example, if the recipe is advanced-oil-processing and 1x crude-oil = 0.008 and one second = 0.5 and 1x water = 0:
        -- 5s + 100x crude-oil + 50x water -> 25x heavy-oil + 45x light-oil + 55x petroleum-gas
        -- 2.5 + 0.8 + 0 -> 25x heavy-oil + 45x light-oil + 55x petroleum-gas
        -- 3.3 -> 25x heavy-oil + 45x light-oil + 55x petroleum-gas
        -- So 3.3 / 3 = 1.1, meaning 25x heavy-oil = 1.1, etc.
        -- Then:
        -- 1x heavy-oil = 1.1 / 25 = 0.044
        -- 1x light-oil = 1.1 / 45 = 0.0244444...
        -- 1x petroleum-gas = 1.1 / 55 = 0.02
        -- And then adjust by complexity multiplier, which is 10% in this case:
        -- 1x heavy-oil = 1.1 / 25 * 1.1 = 0.0484
        -- 1x light-oil = 1.1 / 45 * 1.1 = 0.0268888...
        -- 1x petroleum-gas = 1.1 / 55 * 1.1 = 0.022
        
        timeMult = 1 + math.min(prot.energy * timeMultiplier, timeMultiplierMax)
        complexityMult = 1 + #prot.ingredients * complexityMultiplier
        if util.ingredientsHasItem(prot.ingredients) and util.ingredientsHasFluid(prot.ingredients) then
            complexityMult = complexityMult * (1 + itemFluidComplexityMultiplier) -- Gain 10% value for items that take both fluids and items to produce (e.g. processing units, express transport belts, plastic bars, etc).
        end

        resultValue = totalValue * timeMult * complexityMult / #prot.products

        if itemValueMultipliers[prot.name] then
            resultValue = resultValue * (1 + itemValueMultipliers[prot.name])
        end

        for _, result in pairs(prot.products) do
            resultAmount = result.amount
            if result.probability then
                resultAmount = resultAmount * result.probability -- this drastically distinguishes U-235 from U-238
            end
            itemValue = resultValue / resultAmount
            itemValues.set(result.name, itemValue)
            if result.name == "sulfuric-acid" then
                -- 1x uranium ore requires 1x sulfuric acid to mine (assuming zero productivity, which is unlikely in most games at the stage of mining uranium ore,
                -- but excluding productivity keeps this algorithm simple and allows productivity to retain its purpose in the game as far as coin "farming" goes).
                itemValues.set("uranium-ore", itemValues.get("uranium-ore") + itemValue * (1 + itemFluidComplexityMultiplier))
            end
        end
    end

    -- Set values for items that are not produced by any recipe (of the typical kinds), such as used-up-uranium-fuel-cell or space-science-pack.
    itemValues.set("used-up-uranium-fuel-cell", itemValues.get("uranium-238") * 5 / (1 + complexityMultiplier))
    itemValues.set("space-science-pack", itemValues.get("rocket-part") / 20 * (1 + complexityMultiplier)) -- 2000x space science packs / 100 rocket parts = 20 packs / part, so one space science pack is worth 1/20 of a rocket part.
end

return itemValues
