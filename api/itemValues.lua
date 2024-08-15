
local util = require "api/gutil"

local itemValues = {}



function itemValues.isReady()
    return global.itemValues ~= nil and global.itemValuesReady == true
end

function itemValues.init()
    -- local breakdown = GetRecipeIngredientBreakdown("spidertron", {})
    -- log(breakdown)

    global.itemValues = {}

    -- Set raw item values
    for itemName, itemValue in pairs(global.config.itemValues.raw) do
        itemValues.setItemValue(itemName, itemValue)
    end

    global.itemValueCalculation = {processingItems = {}, processingRecipes = {}, failedCalculations = {}}

    itemValues.register("heavy-oil")
end

function itemValues.getItemValue(itemName)
    if not global.itemValues then
        log("ERROR: global.itemValues has not yet been initialized")
        return
    end
    return global.itemValues[itemName]
end

function itemValues.setItemValue(itemName, value)
    if not global.itemValues then
        log("ERROR: global.itemValues has not yet been initialized")
        return
    end
    if global.itemValues[itemName] then
        if value >= global.itemValues[itemName] then
            return
        end
        log("WARN: Overwriting " .. itemName .. " = " .. global.itemValues[itemName] .. " with " .. value)
    else
        if not value then
            log("WARN: Attempted to set item " .. itemName .. " = nil")
        end
        -- log("Setting " .. itemName .. " = " .. value)
    end
    if value >= 0 then
        global.itemValues[itemName] = value
    else
        if not itemValues.isFailedCalculation(itemName, value) then
            global.itemValueCalculation.failedCalculations[itemName .. tostring(value)] = true
            log("ERROR: Tried to set a negative value: " .. itemName .. " = " .. value)
        end
    end
end

function itemValues.isFailedCalculation(itemName, itemValue)
    return global.itemValueCalculation.failedCalculations[itemName .. tostring(itemValue)] == true
end

function itemValues.isDefined(itemName)
    if not global.itemValues then
        log("WARN: global.itemValues has not yet been initialized")
        return false
    end
    return global.itemValues[itemName] ~= nil
end

function itemValues.adjustItemValue(itemName, itemValue, recipe)
    itemValue = itemValue * (1 + math.min(global.config.itemValues.timeMultiplierMax, recipe.energy * global.config.itemValues.timeMultiplier)) * (1 + global.config.itemValues.complexityMultiplier * #recipe.ingredients) * (1 + (global.config.itemValues.multipliers[itemName] or 0))
    local hasItemInput = false
    local hasFluidInput = false
    for _, ingredient in pairs(recipe.ingredients) do
        if ingredient.type == "item" then
            hasItemInput = true
        elseif ingredient.type == "fluid" then
            hasFluidInput = true
        end
    end
    if hasItemInput and hasFluidInput then
        itemValue = itemValue * (1 + global.config.itemValues.itemFluidComplexityMultiplier)
    end
    return itemValue
end

function itemValues.register(itemName, final, depth)
    if global.itemValueCalculation.processingItems[itemName] then
        return
    end
    global.itemValueCalculation.processingItems[itemName] = true

    if itemValues.isDefined(itemName) then
        return
    end

    depth = depth or 0

    local calculatedValues = {}
    local changed = false

    local recipes = util.getRecipesForItem(itemName)
    for _, recipe in pairs(recipes) do
        if not global.itemValueCalculation.processingRecipes[recipe.name] then
            global.itemValueCalculation.processingRecipes[recipe.name] = true
            local netOutput
            for _, product in pairs(recipe.products) do
                if product.name == itemName then
                    netOutput = (product.amount or (product.amount_min + product.amount_max) * 0.5) * (product.probability or 1)
                    -- log("Set netOutput = " .. netOutput .. " for " .. itemName .. " in " .. recipe.name)
                    break
                end
            end
            if netOutput then
                for _, ingredient in pairs(recipe.ingredients) do
                    if ingredient.name == itemName then
                        netOutput = netOutput - ingredient.amount
                    end
                end

                if netOutput > 0 then
                    local totalItemValue = 0
                    for _, ingredient in pairs(recipe.ingredients) do
                        itemValues.register(ingredient.name, depth + 1)
                        local itemValue = itemValues.getItemValue(ingredient.name)
                        if not itemValue then
                            totalItemValue = -1
                            -- log("WARN: (depth " .. depth .. ") Skipping recipe " .. recipe.name .. " because of infinite loop")
                            break
                        end
                        totalItemValue = totalItemValue + itemValue * ingredient.amount
                    end

                    local numUndetermined = 0
                    if totalItemValue > 0 then
                        totalItemValue = itemValues.adjustItemValue(itemName, totalItemValue, recipe)
                        -- log("For recipe: " .. recipe.name)
                        -- log("(depth " .. depth .. ") Current value calculation pre-reduction: " .. itemName .. " = " .. totalItemValue)
                        -- If this recipe outputs more than one item, then deduct the other products' item values from totalItemValue
                        for _, product in pairs(recipe.products) do
                            if product.name ~= itemName then
                                itemValues.register(product.name, final, depth + 1)
                                local itemValue = itemValues.getItemValue(product.name)
                                if not itemValue then
                                    numUndetermined = numUndetermined + 1
                                    if final then
                                        -- This pass lets the algorithm make a more advanced calculation on the multiple-output recipes.
                                        -- For example, this might be where advanced-oil-processing calculates the value of heavy-oil and light-oil simultaneously.
                                        -- However, petroleum-gas is already calculated while final=false from the basic-oil-processing recipe, so only the other two derivatives need to be calculated.
                                    else
                                        totalItemValue = -1
                                        -- log("Skipping recipe " .. recipe.name .. " because of infinite loop.")
                                        -- log("WARN: YOU MIGHT NEED EXTRA LOGIC TO HANDLE THIS CASE HERE.  SET final=true")
                                        break
                                    end
                                else
                                    totalItemValue = totalItemValue - itemValue * (product.amount or (product.amount_min + product.amount_max) * 0.5) * (product.probability or 1)
                                    -- log("(depth " .. depth .. ") Subtracting " .. product.name .. " = " .. itemValue .. " from " .. itemName)
                                end
                            end
                        end
                        -- log("(depth " .. depth .. ") Current value calculation post-reduction: " .. itemName .. " = " .. totalItemValue)
                    end

                    if totalItemValue == -1 then
                        -- log("WARN: (depth " .. depth .. ") Infinite loop found for item " .. itemName .. " from parent item " .. itemName)
                    else
                        if totalItemValue == 0 then
                            -- log("WARN: (depth " .. depth .. ") Item " .. itemName .. " has a total ingredient value of 0, searched from recipe " .. recipe.name .. ".  This item needs to be skipped for now.")
                        else
                            if numUndetermined > 1 then
                                totalItemValue = totalItemValue / numUndetermined
                            end
                            -- Handle the case when final=true, where there's multiple outputs from the recipe with undetermined values.
                            if final or numUndetermined > 1 then
                                -- local divValue = totalItemValue / numUndetermined
                                for _, product in pairs(recipe.products) do
                                    if not itemValues.isDefined(product.name) then
                                        local itemValue = totalItemValue / ((product.amount or (product.amount_min + product.amount_max) * 0.5) * (product.probability or 1))
                                        -- itemValue = itemValues.adjustItemValue(product.name, itemValue, recipe)
                                        if not itemValues.isFailedCalculation(product.name, itemValue) then
                                            itemValues.setItemValue(product.name, itemValue)
                                            changed = true
                                        end
                                    end
                                end
                            else
                                local itemValue = totalItemValue / netOutput
                                -- itemValues.setItemValue(itemName, itemValue)
                                -- itemValue = itemValues.adjustItemValue(itemName, itemValue, recipe)
                                if not itemValues.isFailedCalculation(itemName, itemValue) then
                                    table.insert(calculatedValues, itemValue)
                                    -- log("Current values for item " .. itemName .. ":")
                                    -- for _, value in pairs(calculatedValues) do
                                    --     log("  " .. value)
                                    -- end
                                end
                            end
                        end
                    end
                else
                    -- log("netOutput is 0 or negative for item " .. itemName .. " from recipe " .. recipe.name)
                end
            else
                -- log("ERROR: (depth " .. depth .. ") No net output found for item " .. itemName .. "; this may be caused by a bug in util.getRecipesForItem()")
            end
        else
            -- log("Skipping recipe " .. recipe.name .. " because of infinite loop.")
        end
    end

    local itemValue = util.tableMin(calculatedValues)
    if itemValue then
        if not itemValues.isDefined(itemName) then
            itemValues.setItemValue(itemName, itemValue)
            changed = true
        end
    else
        -- log("WARN: (depth " .. depth .. ") No item value found for item " .. itemName)
    end

    return changed
end

function itemValues.registerAll()
    local done = false
    local final = false
    repeat
        local changed = false
        for _, recipe in pairs(game.recipe_prototypes) do
            for _, product in pairs(recipe.products) do
                -- log("Try register item for " .. product.name .. " with final=" .. tostring(final))
                global.itemValueCalculation.processingItems = {}
                global.itemValueCalculation.processingRecipes = {}
                if itemValues.register(product.name, final) then
                    changed = true
                end
            end
        end
        if not changed then
            if final then
                done = true
            else
                final = true
            end
        else
            final = false
        end
    until done

    local s = "\nItemValues:"
    for itemName, itemValue in pairs(global.itemValues) do
        s = s .. "\n" .. itemName .. " = " .. itemValue
    end
    log(s)

    local undetermined = {}
    local any = false
    for _, recipe in pairs(game.recipe_prototypes) do
        for _, product in pairs(recipe.products) do
            if not itemValues.isDefined(product.name) then
                undetermined[product.name] = true
                any = true
            end
        end
    end
    if any then
        log("WARN: Values left undetermined:")
        for itemName, _ in pairs(undetermined) do
            log("  " .. itemName .. " = ???")
        end
    end

    -- Set values for items that are not produced by any recipe (of the typical kinds), such as used-up-uranium-fuel-cell or space-science-pack.
    if itemValues.isDefined "uranium-238" then
        itemValues.setItemValue("used-up-uranium-fuel-cell", itemValues.getItemValue("uranium-238") * 5 / (1 + global.config.itemValues.complexityMultiplier))
    end
    if itemValues.isDefined "rocket-part" then
        itemValues.setItemValue("space-science-pack", itemValues.getItemValue("rocket-part") / 10 * (1 + global.config.itemValues.complexityMultiplier)) -- 1000x space science packs / 100 rocket parts = 10 packs / part, so one space science pack is worth 1/10 of a rocket part.
    end

    global.itemValues["electric-energy-interface"] = nil -- craftable with 2 iron plates and 5 green circuits, so just nuke it

    global.itemValuesReady = true
end


--[[

Algorithm outline:

For a given item `itemName`:

Iterate over each recipe that produces this item:
If there's an infinite loop, ignore this recipe.
If not, try to calculate all the other items that haven't been calculated yet (recursively).
If no infinite loop is found in doing this, then add the resulting item value for `itemName` to a table.

After iterating over all recipes that produce `itemName`, use the lowest item value calculated in the table.

]]


return itemValues
