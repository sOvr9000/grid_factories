
local itemValues = require "api/itemValues"

local itemValuesGrad = {}



function itemValuesGrad.init()
    global.grad = {}
    global.grad.tentativeItemValues = {}
    global.grad.tentativeItemValuesSum = {}
    global.grad.recipesToCalculate = {}
    global.grad.recipeCounts = {}
    
    global.grad.velocity = {}
    global.grad.speed = 0
    global.grad.currentRecipeIndex = 1
    global.grad.done = false

    for _, recipe in pairs(game.recipe_prototypes) do
        for _, item in pairs(recipe.products) do
            if not global.itemValues[item.name] then
                table.insert(global.grad.recipesToCalculate, recipe)
                global.grad.recipeCounts[item.name] = (global.grad.recipeCounts[item.name] or 0) + 1
                global.grad.tentativeItemValues[item.name] = 0
                global.grad.tentativeItemValuesSum[item.name] = 0
            end
        end
    end
end

function itemValuesGrad.getItemValue(itemName)
    if itemValues.isDefined(itemName) then
        return itemValues.getItemValue(itemName)
    end
    return global.grad.tentativeItemValues[itemName] or 0
end

function itemValuesGrad.processNextRecipe()
    local recipe = global.grad.recipesToCalculate[global.grad.currentRecipeIndex]
    local totalItemValue = 0
    for _, ingredient in pairs(recipe.ingredients) do
        totalItemValue = totalItemValue + itemValuesGrad.getItemValue(ingredient.name) * ingredient.amount
    end
    for _, p in pairs(recipe.products) do
        if itemValues.isDefined(p.name) then
            totalItemValue = totalItemValue - itemValues.getItemValue(p.name) * p.amount
        end
    end
    totalItemValue = totalItemValue / #recipe.products
    for _, product in pairs(recipe.products) do
        if not itemValues.isDefined(product.name) then
            local actualItemValue = totalItemValue
            for _, ingredient in pairs(recipe.ingredients) do
                if ingredient.name == product.name then
                    actualItemValue = actualItemValue - itemValuesGrad.getItemValue(ingredient.name) * ingredient.amount
                end
            end
            actualItemValue = itemValues.adjustItemValue(product.name, actualItemValue, recipe)
            local prodAmount = product.amount
            for _, ingredient in pairs(recipe.ingredients) do
                if ingredient.name == product.name then
                    prodAmount = prodAmount - ingredient.amount
                end
            end
            if prodAmount > 0 then
                global.grad.tentativeItemValuesSum[product.name] = (global.grad.tentativeItemValuesSum[product.name] or 0) + actualItemValue
            end
        end
    end

    if global.grad.currentRecipeIndex == #global.grad.recipesToCalculate then
        global.grad.currentRecipeIndex = 1
        itemValuesGrad.applyGradients()
        if global.grad.speed < 0.0001 then
            itemValuesGrad.finish()
            global.grad.done = true
        end
    else
        global.grad.currentRecipeIndex = global.grad.currentRecipeIndex + 1
    end
end

function itemValuesGrad.update()
    if global.grad.done then return end

    for _ = 1, 50 do
        itemValuesGrad.processNextRecipe()
        if global.grad.done then return end
    end
end

function itemValuesGrad.applyGradients()
    for itemName, itemValue in pairs(global.grad.tentativeItemValues) do
        local mean = global.grad.tentativeItemValuesSum[itemName] / global.grad.recipeCounts[itemName]
        local delta = mean - itemValue
        local v = (global.grad.velocity[itemName] or 0) + delta * 0.01
        global.grad.velocity[itemName] = v
        global.grad.speed = global.grad.speed + delta * delta
        global.grad.tentativeItemValues[itemName] = itemValue + v * 0.01
        global.grad.tentativeItemValuesSum[itemName] = 0
    end
    global.grad.speed = math.sqrt(global.grad.speed)
    log("Current speed: " .. global.grad.speed)
end

function itemValuesGrad.finish()
    -- Push tentative item values to itemValues
    for itemName, itemValue in pairs(global.grad.tentativeItemValues) do
        itemValues.setItemValue(itemName, itemValue)
    end
end



return itemValuesGrad

