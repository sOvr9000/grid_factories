
local gutil = {}



-- Return whether the Gridtorio scenario is fully initialized.
function gutil.isGameReady()
    return global.setup == true
end

-- Return an element from a table given relative weights for the probability of each element being returned.
function gutil.weightedChoice(choices, weights, totalWeight)
    if not totalWeight then
        totalWeight = 0
        for _, weight in pairs(weights) do
            totalWeight = totalWeight + weight
        end
    end
    local random = math.random() * totalWeight
    local currentWeight = 0
    for choice, weight in pairs(weights) do
        currentWeight = currentWeight + weight
        if currentWeight >= random then
            return choices[choice]
        end
    end
    return choices[#choices]
end

function gutil.getRecipeForProduct(productName, blacklistedRecipes)
    log("Finding recipe for product: " .. productName)
    blacklistedRecipes = blacklistedRecipes or {}
    local results
    for name, recipe in pairs(game.recipe_prototypes) do
        if not blacklistedRecipes[name] then
            results = recipe.products
            for _, result in pairs(results) do
                if result.name == productName then
                    return recipe
                end
            end
        end
    end
    log("No recipe found for product: " .. productName)
end

function gutil.getRecipesWithIngredient(ingredientName, blacklistedRecipes)
    log("Finding recipes with ingredient: " .. ingredientName)
    blacklistedRecipes = blacklistedRecipes or {}
    local results = {}
    for name, recipe in pairs(game.recipe_prototypes) do
        if not blacklistedRecipes[name] then
            results = recipe.ingredients 
            for _, ingredient in pairs(results) do
                if ingredient.name == ingredientName then
                    table.insert(results, recipe)
                    break
                end
            end
        end
    end
    return results
end

function gutil.getRecipesForItem(itemName)
    local recipes = {}
    for _, recipePrototype in pairs(game.recipe_prototypes) do
        for _, result in pairs(recipePrototype.products) do
            if result.name == itemName then
                table.insert(recipes, recipePrototype)
            end
        end
    end
    -- for _, recipe in pairs(global.itemValueCalculation.recipeTree) do
    --     for _, item in pairs(recipe.results) do
    --         if item.name == itemName then
    --             table.insert(recipes, recipe)
    --         end
    --     end
    -- end
    return recipes
end

function gutil.ingredientsHasItem(ingredients)
    for _, ingredient in pairs(ingredients) do
        if not ingredient.type or ingredient.type == "item" then
            return true
        end
    end
    return false
end

function gutil.ingredientsHasFluid(ingredients)
    for _, ingredient in pairs(ingredients) do
        if ingredient.type == "fluid" then
            return true
        end
    end
end

-- Check if a table contains a value.
function gutil.tableContains(tab, value)
    for _, v in pairs(tab) do
        if v == value then
            return true
        end
    end
    return false
end

function gutil.tableLength(tab)
    local length = 0
    for _, _ in pairs(tab) do
        length = length + 1
    end
    return length
end

-- Return a new table that is a combined set of the two given tables, where duplicates are removed.
function gutil.setAdd(tab1, tab2)
    local newTab = {}
    for _, v in pairs(tab1) do
        if not gutil.tableContains(newTab, v) then
            table.insert(newTab, v)
        end
    end
    for _, v in pairs(tab2) do
        if not gutil.tableContains(newTab, v) then
            table.insert(newTab, v)
        end
    end
    return newTab
end

-- Same as setAdd, but modifies tab1 in place and assume that tab1 does NOT have duplicates.
function gutil.setAddModify(tab1, tab2)
    for _, v in pairs(tab2) do
        if not gutil.tableContains(tab1, v) then
            table.insert(tab1, v)
        end
    end
end

-- Return the min value of a table, ignoring values indexed by non-integer indices.  Return nil when no items are found.
function gutil.tableMin(tab)
    if #tab == 0 then return end
    local m = tab[1]
    for i = 2, #tab do
        m = math.min(m, tab[i])
    end
    return m
end

-- Return the max value of a table, ignoring values indexed by non-integer indices.  Return nil when no items are found.
function gutil.tableMax(tab)
    if #tab == 0 then return end
    local m = tab[1]
    for i = 2, #tab do
        m = math.max(m, tab[i])
    end
    return m
end

-- Return the sum of all values in a table.
function gutil.sum(tab)
    local sum = 0
    for _, v in pairs(tab) do
        if type(v) == "number" then
            sum = sum + v
        end
    end
    return sum
end

-- Return a table of strings that are the "words" separated by spaces in the given string.
function gutil.parseArgs(argsString)
    local args = {}
    if not argsString then
        return args
    end
    for arg in argsString:gmatch("%S+") do
        table.insert(args, arg)
    end
    return args
end

--[[
Return a random value between meanValue * ratio and meanValue / ratio.
weight defines how strongly the returned values are weighed toward meanValue.

For example, if meanValue = 10 and ratio = 0.5, then the returned value will be between 5 and 20, not uniformly distributed.
There's always a 50% chance that the returned value will be below meanValue (or above), even though in the example above the range from the min value to the mean value is *half* of the range from the mean value to the max value.
This makes it so that the RNG is fair, giving and taking equally on average.

A great example of why this is better RNG than a simple linear interpolation is this:
Imagine ore that generates with some kind of richness but with a random modification on how much is actually sitting there.
If you want it to possibly generate up to 3x the mean value, a simple linear interpolation would select from -1x to 3x, which means ore amounts could be negative, and even if that was accounted for (where negative amounts are ignored and set to 0), the RNG would then not be uniformly distributed and leading to an actual mean value that is greater than intended.
Instead, if you want it to generate up to 3x the mean value, this function will select from 1/3x to 3x, where there's a 50% chance that the RNG gives either less or more than the mean value.

If weight = 0, then the function returns either the minimum value or the maximum value with equal probability.
If weight = 1, then the standard rational curve is applied.
If weight = 2, then the curve is weighed extra toward meanValue.
If weight is between 0 and 1, then the curve is weighed toward the extrema.
]]
function gutil.rngModify(meanValue, ratio, weight)
    weight = weight or 1
    ratio = ratio or 0.95
    if ratio > 1 then
        ratio = 1 / ratio
    end
    if ratio <= 0 then
        log("Ratio must be greater than 0.")
    end
    if math.random() < 0.5 then
        ratio = 1 / ratio
    end
    -- The nonlinearity comes from dividing by a uniformly (or non-uniformly if weighted) distributed value.
    return meanValue / (math.random() ^ weight * (ratio - 1) + 1)
end

-- Collapse a list of simple continued fraction coefficients into a single fraction as a numerator and denominator.
function gutil.collapseContinuedFraction(coefficients)
    if #coefficients == 0 then
        return 0, 1
    elseif #coefficients == 1 then
        return coefficients[1], 1
    end
    local num = 1
    local den = coefficients[#coefficients]
    for i = #coefficients - 1, 1, -1 do
        num = num + coefficients[i] * den
        num, den = den, num
    end
    return num, den
end

--[[
Rationally approximate any fractional number.
For example:

    0.5 = 1/2
    0.3333333333333333 = 1/3
    ...
]]
function gutil.rationalApproximation(value, maxNumerator, maxDenominator)
    -- This function is used to find interesting market trades that aren't too extreme.  Typically, it's nice to see numbers less than 10 or 20 on trades.
    maxNumerator = maxNumerator or math.huge
    maxDenominator = maxDenominator or math.huge
    local coefficients = {}
    local v = value
    local num, den, pnum, pden, f
    repeat
        f = math.floor(v)
        table.insert(coefficients, f)
        v = 1 / (v - f)
        pnum = num
        pden = den
        num, den = gutil.collapseContinuedFraction(coefficients)
    until num > maxNumerator or den > maxDenominator or math.abs(num / den - value) < 0.00001
    if not pnum or not pden then
        if maxNumerator == math.huge or maxDenominator == math.huge then
            log("Could not rationally approximate " .. value .. " with a max numerator of " .. maxNumerator .. " and a max denominator of " .. maxDenominator)
        end
    end
    return pnum, pden
end

-- function gutil.reservoirSample(iter, filter)
--     -- Randomly select an element from an iterator which passes the given filter.
--     -- Returns nil if no elements pass the filter.
--     local best, random
--     local bestRandom = -1
--     for v in iter do
--         if filter(v) then
--             random = math.random()
--             if random > bestRandom then
--                 best = v
--                 bestRandom = random
--             end
--         end
--     end
--     return best
-- end

--[[
Randomly select a key from a table which passes the given filter on key-value pairs.

If no filter is provided, then no filter is applied and all elements are considered.

Returns nil if no key-value pairs pass the filter.
]]
function gutil.reservoirSample(tab, filter)
    -- I can't understand how to work with iterators correctly in Lua so I'm just going to use tables.
    filter = filter or function(k, v) return true end
    local best, random
    local bestRandom = -1
    for k, v in pairs(tab) do
        if filter(k, v) then
            random = math.random()
            if random > bestRandom then
                best = k
                bestRandom = random
            end
        end
    end
    return best
end

-- function gutil.entitiesHasOre(entities)
--     for _, entity in pairs(entities) do
--         if entity.name == "iron-ore" or entity.name == "copper-ore" or entity.name == "stone" or entity.name == "coal" then
--             return true
--         end
--     end
--     return false
-- end

-- function gutil.entitiesHasMarket(entities)
--     for _, entity in pairs(entities) do
--         if entity.name == "market" then
--             return true
--         end
--     end
--     return false
-- end

function gutil.tileIsWater(surface, x, y, radius)
    if radius then
        for dx = -radius, radius do
            for dy = -radius, radius do
                if gutil.tileIsWater(surface, x + dx, y + dy) then
                    return true
                end
            end
        end
        return false
    end
    local tileName = surface.get_tile(x, y).name
    return tileName == "water" or tileName == "deepwater"
end

function gutil.tileIsOutOfMap(surface, x, y)
    return surface.get_tile(x, y).name == "out-of-map"
end

function gutil.getChunkCoords(pos)
    -- minus 0.5 from both x and y because a player can stand at the edge of a wall and technically be inside the next chunk over even though the wall is there to keep them from going into that chunk
    return {
        x = math.floor((pos.x - 0.5) / 32),
        y = math.floor((pos.y - 0.5) / 32),
    }
end

function gutil.getChunkCoordsOfPlayer(player)
    return gutil.getChunkCoords(player.position)
end

function gutil.offsetPosition(position, direction)
    if direction == 0 then
        return {x = (position.x or position[1]) + 1, y = position.y or position[2]}
    elseif direction == 1 then
        return {x = position.x or position[1], y = (position.y or position[2]) + 1}
    elseif direction == 2 then
        return {x = (position.x or position[1]) - 1, y = position.y or position[2]}
    elseif direction == 3 then
        return {x = position.x or position[1], y = (position.y or position[2]) - 1}
    else
        log("Unexpected direction: " .. direction)
    end
end

function gutil.positionToString(position)
    return (position.x or position[1]) .. ", " .. (position.y or position[2])
end

function gutil.tradeToString(trade, giveOnly)
    if trade.itemToGive then
        -- cached, reformatted type
        if giveOnly then
            return trade.itemToGive
        else
            return trade.itemToGive .. "," .. trade.itemToReceive
        end
    else
        -- built-in type, which is of the form {offer = ..., price = ...}
        local itemToGive = trade.price[1].name
        if giveOnly then
            return itemToGive
        else
            return itemToGive .. "," .. trade.offer.item
        end
    end
end

function gutil.getChunkBoundingBox(chunkCoords)
    return {
        left_top = {x = chunkCoords.x * 32, y = chunkCoords.y * 32},
        right_bottom = {x = chunkCoords.x * 32 + 32, y = chunkCoords.y * 32 + 32},
    }
end

function gutil.lerp(a, b, t)
    return a + (b - a) * t
end

function gutil.squareDistance(pos1, pos2)
    return (pos1.x - pos2.x) * (pos1.x - pos2.x) + (pos1.y - pos2.y) * (pos1.y - pos2.y)
end

function gutil.getBoundingBox(tab, key)
    key = key or function(k, v) return (v.x or v[1] or 0), (v.y or v[2] or 0) end
    local minx
    local miny
    local maxx
    local maxy
    local pos
    for k, v in pairs(tab) do
        pos = key(k, v)
        if not minx then
            minx = pos.x or pos[1] or 0
            miny = pos.y or pos[2] or 0
            maxx = minx
            maxy = miny
        else
            minx = math.min(minx, pos.x or pos[1])
            miny = math.min(miny, pos.y or pos[2])
            maxx = math.max(maxx, pos.x or pos[1])
            maxy = math.max(maxy, pos.y or pos[2])
        end
    end
    return minx, miny, maxx, maxy
end

-- Convert camelCase to hyphenated-case
function gutil.hyphenateName(name)
    return name:gsub("([A-Z])", "-%1"):lower()
end

function gutil.argmax(tab)
    local arg
    local max = -math.huge
    for k, v in pairs(tab) do
        if v > max then
            arg = k
            max = v
        end
    end
    return arg
end

-- Shallow copy contents from tab2 into tab1.
function gutil.tableExtend(tab1, tab2)
    for k, v in pairs(tab2) do
        tab1[k] = v
    end
end

function gutil.printGameVersion(player)
    (player or game).print("[color=blue]Gridtorio " .. global.VERSION .. "[.color]")
end

-- Add loot to an inventory.
function gutil.addLootToInventory(inv, maxTotalValue, lootChoices)
    local choices = {}
    for k, v in pairs(lootChoices) do
        choices[k] = v
    end
    local tries = 0
    repeat
        tries = tries + 1
        local lootIndex = math.random(1, #choices)
        local lootItem = choices[lootIndex]
        local itemValue = global.itemValues[lootItem]
        if itemValue and itemValue <= maxTotalValue then
            local portion
            if global.config.ruinsChestLootVariation == "varied" then
                portion = 0.01
            elseif global.config.ruinsChestLootVariation == "unvaried" then
                portion = 0.99
            else
                portion = math.random()
            end
            local lootValue = math.max(maxTotalValue * portion, itemValue)
            local itemAmount = math.floor(lootValue / itemValue)
            if itemAmount > 0 and itemAmount < 100 then
                inv.insert{name = lootItem, count = itemAmount}
                maxTotalValue = maxTotalValue - itemAmount * itemValue
            end
        else
            table.remove(choices, lootIndex)
        end
    until #choices == 0 or tries >= 20 or maxTotalValue <= 0
end

function gutil.setTiles(surface, chunkCoords, tileName, ignoreWater, detailed, ignoreVoid)
    chunkCoords.x = chunkCoords.x or chunkCoords[1]
    chunkCoords.y = chunkCoords.y or chunkCoords[2]
    local tiles = {}
    for _y = 0, 31 do
        local y = chunkCoords.y * 32 + _y
        for _x = 0, 31 do
            local x = chunkCoords.x * 32 + _x
            if (ignoreVoid or not gutil.tileIsOutOfMap(surface, x, y)) and (ignoreWater or not gutil.tileIsWater(surface, x, y)) then
                local s = _x + _y
                if not detailed or not (s == 8 or s == 56 or _y == 24 + _x or _x == 24 + _y or (_x >= 8 and _x <= 24 or _y >= 8 and _y <= 24) and (_x == 0 or _y == 0)) then
                    table.insert(tiles, {name = tileName, position = {x = x, y = y}})
                end
            end
        end
    end
    surface.set_tiles(tiles)
    surface.destroy_decoratives{area = {
        left_top = {
            x = (chunkCoords.x or chunkCoords[1]) * 32,
            y = (chunkCoords.y or chunkCoords[2]) * 32,
        },
        right_bottom = {
            x = (chunkCoords.x or chunkCoords[1]) * 32 + 31,
            y = (chunkCoords.y or chunkCoords[2]) * 32 + 31,
        },
    }}
end

function gutil.getChunkArea(chunkCoords)
    return {
        left_top = {
            x = (chunkCoords.x or chunkCoords[1]) * 32,
            y = (chunkCoords.y or chunkCoords[2]) * 32,
        },
        right_bottom = {
            x = (chunkCoords.x or chunkCoords[1]) * 32 + 32,
            y = (chunkCoords.y or chunkCoords[2]) * 32 + 32,
        },
    }
end

function gutil.multipleInterpolationInverse(x, points)
    if #points <= 1 then
        log("Not enough interpolation points")
        return
    end
    if x < points[1] then
        return 0
    end
    for k, v in pairs(points) do
        if k == #points then
            return 1
        end
        if x >= v then
            return (x - v) / (points[k + 1] - v) + k - 1
        end
    end
end

function gutil.multipleInterpolation(t, points)
    if #points <= 1 then
        log("Not enough interpolation points")
        return
    end
    if t <= 0 then
        return points[1]
    elseif t >= #points then
        return points[#points]
    end
    local r = math.floor(t)
    local s = t - r
    return gutil.lerp(points[r], points[r + 1], s)
end

-- Convert a serial-indexed array to a string.
function gutil.arrayToString(array, useBrackets, sep)
    sep = sep or ","
    local string = ""
    for _, v in pairs(array) do
        string = string .. tostring(tostring(v)) .. sep
    end
    if useBrackets then
        string = "{" .. string .. "}"
    end
    return string
end

function gutil.colorLocalizedString(text, color)
    if color then
        return {"", "[color=" .. color .. "]", text, "[.color]"}
    end
    return text
end

function gutil.gpsToString(pos, surfaceName)
    surfaceName = surfaceName or "gridtorio"
    return "[gps=" .. (pos.x or pos[1]) .. ", " .. (pos.y or pos[2]) .. "," .. surfaceName .. "]"
end

function gutil.spawnBiterNest(surface, area, spawners, worms)
    local spawner = true
    local spitter = false
    local totalSpawners = 0
    repeat
        local entityName
        if worms == 0 then
            spawner = true
        elseif spawners == 0 then
            spawner = false
        end
        if spawner then
            if spitter then
                entityName = "spitter-spawner"
                spitter = false
            else
                entityName = "biter-spawner"
                spitter = true
            end
            spawners = spawners - 1
            spawner = false
        else
            entityName = "behemoth-worm-turret"
            worms = worms - 1
            spawner = true
        end
        local pos = surface.find_non_colliding_position_in_box(entityName, area, 1)
        if pos then
            if surface.create_entity{name = entityName, position = pos} and spawner then
                totalSpawners = totalSpawners + 1
            end
        end
    until spawners == 0 and worms == 0
    return totalSpawners
end

-- Return a deep copy of the given table.
function gutil.deepcopy(tab)
    if type(tab) ~= "table" then
        return tab
    end
    local copy = {}
    for k, v in pairs(tab) do
        if type(v) == "table" then
            copy[k] = gutil.deepcopy(v)
        else
            copy[k] = v
        end
    end
    setmetatable(copy, getmetatable(tab)) -- likely not needed but it's here just in case
    return copy
end

function gutil.splitInventory(invItems)
    local halves = {{}, {}}
    for itemName, itemCount in pairs(invItems) do
        if itemCount > 0 then
            halves[1][itemName] = math.floor(itemCount / 2)
            halves[2][itemName] = itemCount - halves[1][itemName]
            if halves[1][itemName] == 0 then
                halves[1][itemName] = nil
            end
        end
    end
    return halves
end

function gutil.sumInventories(invs)
    local totalInv = {}
    for _, inv in pairs(invs) do
        for itemName, itemCount in pairs(inv) do
            totalInv[itemName] = (totalInv[itemName] or 0) + itemCount
        end
    end
    return totalInv
end

function gutil.nextHighestItemByValue(itemName)
    local itemValue = global.itemValues[itemName]
    local closestItemValue = 0
    local closestItem
    for name, value in pairs(global.itemValues) do
        if name ~= "rocket-part" then
            if value > itemValue then
                if not closestItem then
                    closestItem = name
                    closestItemValue = value
                else
                    if value < closestItemValue then
                        closestItem = name
                        closestItemValue = value
                    end
                end
            end
        end
    end
    return closestItem
end

function gutil.getRootPlayerGUI(element)
    local e = element
    repeat
        e = e.parent
    until not e or not e.parent or e.parent.name == "screen" or e.parent.name == "center" or e.parent.name == "left" or e.parent.name == "top"
    return e
end

-- function gutil.hasVisibleChildren(element)
--     for _, child in pairs(element) do
--         if child.visible then
--             return true
--         end
--         if gutil.hasVisibleChildren(child) then
--             return true
--         end
--     end
--     return false
-- end

-- function gutil.guiMap(element, func)
--     func(element)
--     for _, child in pairs(element) do
--         gutil.guiMap(child, func)
--     end
-- end

function gutil.indexOf(tab, value)
    for i, v in pairs(tab) do
        if v == value then
            return i
        end
    end
end

function gutil.parsePlayTime(ticks)
    local t = ticks % 60
    local s = math.floor(ticks / 60) % 60
    local m = math.floor(ticks / 3600) % 60
    local h = math.floor(ticks / 216000) % 24
    local d = math.floor(ticks / 5184000)
    return t, s, m, h, d
end

function gutil.getTimestamp()
    if not game then
        return "0d 00h 00m 00s 00t"
    end
    local t, s, m, h, d = gutil.parsePlayTime(game.tick)
    local str = string.format("%02dm %02ds %02dt", m, s, t)
    if h > 0 or d > 0 then
        str = string.format("%02dh %s", h, str)
    else
        str = string.format("--- %s", str)
    end
    if d > 0 then
        str = string.format("%dd %s", d, str)
    else
        str = string.format("-- %s", str)
    end
    return str
end

function gutil.getChunkDistance(chunkCoords)
    return 32 * math.sqrt(chunkCoords.x * chunkCoords.x + chunkCoords.y * chunkCoords.y)
end

function gutil.canChunkGetInfested(chunkCoords)
    local dist = gutil.getChunkDistance(chunkCoords)
    return dist >= global.config.infestedChunkMinDistance
end

-- Find and return the first substring of str that is a GPS rich text string.
-- e.g. `gutil.findGPSSubstring("Ping here [gps=123,456,gridtorio]")` returns `"[gps=123,456,gridtorio]"`
function gutil.findGPSSubstring(str)
    if type(str) == "string" then
        local txt, _ = str:match "(%[gps=([^%]]+)%])"
        return txt
    end
    -- This is likely a LocalisedString.
    for _, param in pairs(str) do
        local txt = gutil.findGPSSubstring(param)
        if txt then
            return txt
        end
    end
end



return gutil
