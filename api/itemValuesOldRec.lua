
local util = require "api/gutil"

local itemValues = {}



--[[
Generates the recipe tree `global.recipeTree` and unifies items and liquids under the same data structure.
The structure of `global.recipeTree` is as follows:
{
    recipe1 = {
        ingredients = {item1, item2, ...},
        results = {item1, item2, ...},
        time = float,
    },
    ...
}
And the structure of any item is as follows:
{
    name = string,
    count = int,
    probability = float,
}
--]]
function itemValues.init()
    -- Initialize itemValues table with raw values from config
    for item, value in pairs(global.config.itemValues.raw) do
        global.itemValueCalculation.calculatedItems[item] = value
    end

    -- for entityName, v in pairs(game.surfaces.nauvis.map_gen_settings.autoplace_controls) do
    --     if not util.tableContains({"iron-ore", "copper-ore", "stone", "coal"}, entityName) then
    --         local prot = game.entity_prototypes[entityName]
    --         if prot then
    --             if prot.mineable_properties.products then
    --                 for _, item in pairs(prot.mineable_properties.products) do
    --                     global.itemValueCalculation.calculatedItems[item.name] = global.config.itemValues.defaultItemValue
    --                 end
    --             end
    --         end
    --     end
    -- end

    -- Generate recipe tree
    for _, recipe in pairs(game.recipe_prototypes) do
        local recipeData = {
            name = recipe.name,
            ingredients = {},
            results = {},
            time = recipe.energy,
        }

        -- Process ingredients
        for _, ingredient in pairs(recipe.ingredients) do
            table.insert(recipeData.ingredients, {
                name = ingredient.name,
                count = ingredient.amount,
            })
        end

        -- Process results
        local results = recipe.products
        for _, result in pairs(results) do
            local res = {
                name = result.name,
                count = result.amount or (result.amount_min + result.amount_max) * 0.5,
                probability = result.probability or 1,
            }
            -- log("recipe = " .. recipe.name .. ", name = " .. result.name .. ", probability = " .. res.probability)
            res.actualCount = res.count * res.probability
            table.insert(recipeData.results, res)
        end

        global.itemValueCalculation.recipeTree[recipe.name] = recipeData
    end
end

function itemValues.registerAll()
    for itemName, _ in pairs(game.item_prototypes) do
        itemValues.register(itemName)
    end
    -- Put all calculatedItems into global.itemValues.
    global.itemValues = {}
    for itemName, itemValue in pairs(global.itemValueCalculation.calculatedItems) do
        log(itemName .. " = " .. itemValue)
        if itemValue ~= 0 then
            global.itemValues[itemName] = itemValue
        else
            log("WARN: itemValue is 0 for " .. itemName)
        end
    end
end

function itemValues.register(itemName)
    if global.itemValueCalculation.calculatedItems[itemName] then
        return global.itemValueCalculation.calculatedItems[itemName]
    end

    local recipes = util.getRecipesForItem(itemName)
    if #recipes == 0 then
        global.itemValueCalculation.calculatedItems[itemName] = 0
        return global.itemValueCalculation.calculatedItems[itemName]
    end

    local bestRecipe
    local bestValue = math.huge

    for _, recipe in pairs(recipes) do
        local totalInputValue = 0
        local canCalculate = true

        local hasItems = false
        local hasFluids = false

        for _, ingredient in pairs(recipe.ingredients) do
            if game.item_prototypes[ingredient.name] then
                hasItems = true
            elseif game.fluid_prototypes[ingredient.name] then
                hasFluids = true
            end
            if not global.itemValueCalculation.calculatedItems[ingredient.name] then
                if not global.itemValueCalculation.processingItems[ingredient.name] then
                    global.itemValueCalculation.processingItems[ingredient.name] = true
                    itemValues.register(ingredient.name)
                    global.itemValueCalculation.processingItems[ingredient.name] = nil
                else
                    -- Circular dependency detected, set a default value
                    -- global.itemValueCalculation.calculatedItems[ingredient.name] = global.config.itemValues.defaultItemValue

                    -- Instead of assuming a default value when there's an infinite loop, check for another recipe that produces this same item and infer values from there.
                    log("found infinite loop from " .. itemName .. " to " .. ingredient.name)
                    if itemName ~= "uranium-235" and itemName ~= "heavy-oil" and itemName:sub(-6) ~= "barrel" then
                        table.insert(global.error_messages, util.colorLocalizedString({"gridtorio.error-mod-adds-recipe-loop", itemName}, "yellow"))
                    end
                end
            end
            if global.itemValueCalculation.calculatedItems[ingredient.name] then
                totalInputValue = totalInputValue + global.itemValueCalculation.calculatedItems[ingredient.name] * ingredient.count
            else
                canCalculate = false
                break
            end
        end

        if hasFluids and hasItems then
            totalInputValue = totalInputValue * (1 + global.config.itemValues.itemFluidComplexityMultiplier)
        end

        -- Apply complexity multiplier to the result.
        totalInputValue = totalInputValue * (1 + global.config.itemValues.complexityMultiplier * #recipe.ingredients)

        -- Apply time multiplier to the result.
        totalInputValue = totalInputValue * (1 + math.min(global.config.itemValues.timeMultiplierMax, recipe.time * global.config.itemValues.timeMultiplier))

        if canCalculate then
            -- local totalOutputAmount = 0
            -- for _, result in pairs(recipe.results) do
            --     totalOutputAmount = totalOutputAmount + result.actualCount
            -- end

            -- local recipeValue = totalInputValue / totalOutputAmount
            local recipeValue = totalInputValue
            if recipeValue < bestValue then
                bestValue = recipeValue
                bestRecipe = recipe
            end
        end
    end

    if bestRecipe then
        log("calculating item value for " .. itemName .. " with recipe " .. bestRecipe.name)
        local totalOutputAmount = 0
        for _, result in pairs(bestRecipe.results) do
            totalOutputAmount = totalOutputAmount + result.actualCount
        end

        for _, result in pairs(bestRecipe.results) do
            -- log("itemValue = " .. bestValue .. ", result = " .. result.name .. ", result.actualCount = " .. result.actualCount .. ", totalOutputAmount = " .. totalOutputAmount)
            local itemValue = bestValue / (result.actualCount * totalOutputAmount)
            if itemValue > 0 then
                -- Apply item-specific multiplier to the result.
                if global.config.itemValues.multipliers[result.name] then
                    itemValue = itemValue * (1 + global.config.itemValues.multipliers[result.name])
                end

                if not global.itemValueCalculation.calculatedItems[result.name] then
                    log("calculated value for " .. result.name .. " = " .. itemValue)
                    global.itemValueCalculation.calculatedItems[result.name] = itemValue
                end
            end
        end
    else
        global.itemValueCalculation.calculatedItems[itemName] = global.config.itemValues.defaultItemValue
    end

    return global.itemValueCalculation.calculatedItems[itemName]
end



return itemValues
