
local util = require "api/gutil"
local upgrades = require "api/upgrades"
local tradeOverview = require "api/tradeOverview"

local markets = {}



function markets.getTradesOfMarket(market)
    if not market or market.name ~= "market" then return {} end
    local offers = market.get_market_items()
    if not offers then return {} end
    local trades = {}
    for _, offer in pairs(offers) do
        table.insert(trades, {
            itemToGive = offer.price[1].name,
            amountToGive = offer.price[1].amount,
            itemToReceive = offer.offer.item,
            amountToReceive = offer.offer.count,
        })
    end
    return trades
end

function markets.getMarketTradeAmounts(itemToReceive, itemToGive)
    local itemValueReceive = global.itemValues[itemToReceive]
    local itemValueGive = global.itemValues[itemToGive]
    local rngFactor = 0.98
    if global.upgrades.unlocked.marketRng and global.upgrades.globallyEnabledUpgrades.marketRng then
        rngFactor = 0.95
    end
    itemValueReceive = util.rngModify(itemValueReceive, rngFactor)
    itemValueGive = util.rngModify(itemValueGive, rngFactor)
    local amountReceive, amountGive = util.rationalApproximation(itemValueReceive / itemValueGive, 10, 10)
    if not amountReceive or not amountGive or amountGive == 0 or amountReceive == 0 then
        if itemValueReceive > itemValueGive then
            amountGive = math.floor(0.5 + itemValueReceive / itemValueGive)
            amountReceive = 1
        else
            amountReceive = math.floor(0.5 + itemValueGive / itemValueReceive)
            amountGive = 1
        end
    end
    local ratio = itemValueGive * amountGive / (itemValueReceive * amountReceive)
    if ratio >= 2 or ratio <= 0.5 then
        -- Somehow the trade became unbalanced.  Reverse the amounts.
        amountGive, amountReceive = amountReceive, amountGive
    end
    -- log("itemToGive = " .. itemToGive .. ", itemToReceive = " .. itemToReceive .. ", amountGive = " .. amountGive .. ", amountReceive = " .. amountReceive)
    return amountReceive, amountGive
end

function markets.addMarketOffer(market, itemToReceive, itemToGive, amountReceive, amountGive)
    if not amountReceive or not amountGive then
        amountReceive, amountGive = markets.getMarketTradeAmounts(itemToReceive, itemToGive)
    end
    if amountReceive >= 65536 or amountGive >= 65536 then
        return
    end
    local trade = {
        price = {{name = itemToGive, amount = amountGive}},
        offer = {type = "give-item", item = itemToReceive, count = amountReceive},
    }
    local str = util.tradeToString(trade)
    global.allTradeStrings[str] = (global.allTradeStrings[str] or 0) + 1
    market.add_market_item(trade)
end

function markets.getRandomMarketTrade(currentMarketTrades)
    local itemToReceive, itemToGive, lowerValue, upperValue, amountReceive, amountGive
    local checkTU = global.upgrades.unlocked.tradeUniqueness and global.upgrades.globallyEnabledUpgrades.tradeUniqueness
    local canBeCoinTrade = true
    for _ = 1, 20 do
        if canBeCoinTrade and math.random() < global.config.chanceOfCoinTrade then
            local isSellTrade = math.random() < global.config.chanceOfSellTrade
            if not isSellTrade and currentMarketTrades.coin then
                isSellTrade = true
            end
            itemToGive = util.reservoirSample(global.itemValues, function(itemName, itemValue)
                -- must be an item and not a coin or rocket part
                if checkTU then
                    if isSellTrade and global.allTradeStrings[itemName .. ",coin"] then
                        return false
                    elseif not isSellTrade and global.allTradeStrings["coin," .. itemName] then
                        return false
                    end
                end
                if isSellTrade and currentMarketTrades[itemName] then
                    return false
                end
                return game.item_prototypes[itemName] and itemName ~= "coin" and itemName ~= "rocket-part"
            end)
            if itemToGive then
                itemToReceive = "coin"
                if not isSellTrade and not currentMarketTrades.coin then
                    if not checkTU or not global.allTradeStrings["coin," .. itemToGive] then
                        -- change to "buy" type
                        itemToReceive = itemToGive
                        itemToGive = "coin"
                    end
                end
                -- at this point, it's possible but rare that a "buy" trade failed, so we cannot add this if checkTU
                if checkTU and global.allTradeStrings[itemToGive .. "," .. itemToReceive] then
                    log("trade generation failed under uniqueness conditions")
                    return nil, nil
                end
                amountReceive, amountGive = markets.getMarketTradeAmounts(itemToReceive, itemToGive)
                if amountReceive <= 65535 and amountGive <= 65535 then
                    return itemToReceive, itemToGive
                end
            else
                canBeCoinTrade = false
            end
        else
            itemToGive = util.reservoirSample(global.itemValues, function(itemName, itemValue)
                -- must be an item and not previously selected
                return game.item_prototypes[itemName] and itemName ~= "rocket-part" and not currentMarketTrades[itemName] and itemName ~= "coin"
            end)
            lowerValue = global.itemValues[itemToGive] * global.config.tradeRelativeValueLower
            upperValue = global.itemValues[itemToGive] * global.config.tradeRelativeValueUpper
            itemToReceive = util.reservoirSample(global.itemValues, function(itemName, itemValue)
                if not game.item_prototypes[itemName] or itemName == itemToGive or itemName == "rocket-part" then
                    return false
                end
                if itemValue < lowerValue or itemValue > upperValue then
                    return false
                end
                local tradeStr = itemToGive .. "," .. itemName
                if checkTU and global.allTradeStrings[tradeStr] then
                    return false
                end
                return true
            end)
            if itemToGive and itemToReceive then
                if checkTU and global.allTradeStrings[itemToGive .. "," .. itemToReceive] then
                    log("trade generation failed under uniqueness conditions")
                    return nil, nil
                end
                amountReceive, amountGive = markets.getMarketTradeAmounts(itemToReceive, itemToGive)
                if amountReceive <= 65535 and amountGive <= 65535 then
                    return itemToReceive, itemToGive
                end
            end
        end
        log("Failed to find a market trade. Trying again.")
    end
    log("Could not find a market trade. Aborting.")
    return nil, nil
end

function markets.initMarket(market, isSuperChunk)
    if not market.get_market_items() then
        -- this is not the market in the starting chunk
        local numTrades = math.random(global.config.tradesPerMarketMin, global.config.tradesPerMarketMax)
        if isSuperChunk then
            numTrades = global.config.superChunkMarketTrades
        end
        local currentMarketTrades = {}
        for _ = 1, numTrades do
            local itemToReceive, itemToGive = markets.getRandomMarketTrade(currentMarketTrades)
            if not itemToReceive or not itemToGive then
                log("No market trade found for " .. util.positionToString(market.position) .. ". Market will have fewer trades than expected.")
            else
                currentMarketTrades[itemToGive] = true
                markets.addMarketOffer(market, itemToReceive, itemToGive)
            end
        end
    else
        -- this is the market in the starting chunk
        -- nothing to do for now
    end

    local marketGroup = {market = market, isBank = true}

    if upgrades.isUpgradeEnabled "marketIoChests" then
        marketGroup.extraIO = true
    end

    markets.generateIOChests(marketGroup)

    local posStr = util.positionToString{x = math.floor(market.position.x / 32), y = math.floor(market.position.y / 32)}
    global.boughtMarkets[posStr] = marketGroup

    for _, player in pairs(game.connected_players) do
        tradeOverview.refresh(player)
    end
end

function markets.processMarketGroup(marketGroup)
    -- For a single market, process the transactions between the sell chest and the buy chest.
    -- This function is only called on market groups where the sell chest has at least one item in it.
    
    -- Find matching trades
    local any = false
    for _, trade in pairs(marketGroup.trades) do
        local sellInvs = marketGroup.sellInv
        local buyInvs = marketGroup.buyInv
        if not marketGroup.extraIO then
            sellInvs = {sellInvs}
            buyInvs = {buyInvs}
        end
        for i = 1, #sellInvs do
            local sellInv = sellInvs[i]
            local buyInv = buyInvs[i]
            local count = sellInv.get_item_count(trade.itemToGive)
            if count >= trade.amountToGive then
                local ordersAvailable = math.floor(count / trade.amountToGive)
                local ordersPossible = math.floor(buyInv.get_insertable_count(trade.itemToReceive) / trade.amountToReceive)
                local orders = math.min(ordersAvailable, ordersPossible)
                if orders < ordersAvailable and not marketGroup.hasBeenOversupplied then
                    if buyInv.is_empty() and buyInv.get_bar() == 49 then
                        upgrades.incrementScore("oversuppliedBlueChests")
                        marketGroup.hasBeenOversupplied = true
                        any = true
                    end
                end
                if orders > 0 then
                    -- game.print("Processing ".. orders.. " orders of ".. trade.itemToGive.. " for ".. trade.itemToReceive.. ".")
                    local items = {
                        name = trade.itemToReceive,
                        count = trade.amountToReceive * orders,
                    }
                    if buyInv.can_insert(items) then
                        buyInv.insert(items)
                        sellInv.remove{name = trade.itemToGive, count = trade.amountToGive * orders}
                        if trade.itemToReceive == "coin" then
                            global.coinsProducedThisSecond = global.coinsProducedThisSecond + trade.amountToReceive * orders
                        elseif trade.itemToGive == "coin" then
                            global.coinsConsumedThisSecond = global.coinsConsumedThisSecond + trade.amountToGive * orders
                        end
                    end
                    upgrades.incrementScore("automatedTrades")
                    any = true
                end
            end
        end
    end
    if any then
        for _, p in pairs(game.connected_players) do
            upgrades.refresh(p)
        end
    end
end

function markets.generateIOChests(marketGroup)
    local market = marketGroup.market

    local pos1 = {x = market.position.x - 2, y = market.position.y}
    local pos2 = {x = market.position.x + 2, y = market.position.y}
    if marketGroup.extraIO then
        pos1 = {x = market.position.x + 2, y = market.position.y - 1}
        pos2 = {x = market.position.x - 1, y = market.position.y - 2}
    end

    local sellChest = market.surface.create_entity{name = "blue-chest", position = pos1, force = "player"}
    sellChest.destructible = false
    sellChest.minable = false
    local sellChestInventory = sellChest.get_inventory(defines.inventory.chest)
    local buyChest = market.surface.create_entity{name = "red-chest", position = pos2, force = "player"}
    buyChest.destructible = false
    buyChest.minable = false
    local buyChestInventory = buyChest.get_inventory(defines.inventory.chest)
    
    marketGroup.sellInv = sellChestInventory
    marketGroup.buyInv = buyChestInventory
    marketGroup.trades = markets.getTradesOfMarket(market)

    if marketGroup.extraIO then
        sellChest = market.surface.create_entity{name = "blue-chest", position = {x = market.position.x - 2, y = market.position.y + 1}, force = "player"}
        sellChest.destructible = false
        sellChest.minable = false
        sellChestInventory = sellChest.get_inventory(defines.inventory.chest)
        buyChest = market.surface.create_entity{name = "red-chest", position = {x = market.position.x + 1, y = market.position.y + 2}, force = "player"}
        buyChest.destructible = false
        buyChest.minable = false
        buyChestInventory = buyChest.get_inventory(defines.inventory.chest)

        marketGroup.sellInv = {marketGroup.sellInv, sellChestInventory}
        marketGroup.buyInv = {marketGroup.buyInv, buyChestInventory}

        marketGroup.isBank = {marketGroup.isBank, marketGroup.isBank}
    end
end

function markets.getRedInventories(marketGroup, bankOnly)
    if marketGroup.extraIO then
        if bankOnly then
            local invs = {}
            for i = 1, #marketGroup.buyInv do
                if marketGroup.isBank[i] then
                    table.insert(invs, marketGroup.buyInv[i])
                end
            end
            return invs
        end
        return marketGroup.buyInv
    end
    if bankOnly then
        if marketGroup.isBank then
            return {marketGroup.buyInv}
        end
        return {}
    end
    return {marketGroup.buyInv}
end

function markets.getBlueInventories(marketGroup)
    if marketGroup.extraIO then
        return marketGroup.sellInv
    end
    return {marketGroup.sellInv}
end

function markets.toggleMarketBank(marketGroup, chest)
    if marketGroup.extraIO then
        local invs = markets.getRedInventories(marketGroup, false)
        for i = 1, #invs do
            local inv = invs[i]
            local redChest = inv.entity_owner
            if redChest == chest then
                marketGroup.isBank[i] = not marketGroup.isBank[i]
                return marketGroup.isBank[i]
            end
        end
    else
        if chest == marketGroup.buyInv.entity_owner then
            marketGroup.isBank = not marketGroup.isBank
            return marketGroup.isBank
        end
    end
    log("ERROR: Could not find red chest")
end



return markets
