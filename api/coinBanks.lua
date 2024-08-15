
local markets  = require "api/markets"

local coinBanks = {}



-- Count coins in player inventory.
function coinBanks.playerCoins(player)
    local inv = player.get_inventory(defines.inventory.character_main)
    if not inv then return 0 end
    return inv.get_item_count "coin"
end

-- Count all coins in all red market chests that are part of the coin bank.
function coinBanks.redChestCoins()
    local count = 0
    for _, marketGroup in pairs(global.boughtMarkets) do
        local invs = markets.getRedInventories(marketGroup, true)
        for _, inv in pairs(invs) do
            count = count + inv.get_item_count "coin"
        end
    end
    return count
end

-- Return whether the total coins across player inventory and market red chests meet a requirement.
-- If player is nil, then only check red chests.
function coinBanks.hasCoins(coins, player)
    local count = 0
    if player then
        count = coinBanks.playerCoins(player)
        if count >= coins then
            return true
        end
        coins = coins - count
    end
    for _, marketGroup in pairs(global.boughtMarkets) do
        local invs = markets.getRedInventories(marketGroup, true)
        for _, inv in pairs(invs) do
            count = count + inv.get_item_count "coin"
            if count >= coins then
                return true
            end
        end
    end
    return false
end

-- Use player inventory coins first, and then use market red chests if necessary.
-- If player is nil, then only use market red chests.
function coinBanks.deductCoins(coins, player)
    local count
    if player then
        local inv = player.get_inventory(defines.inventory.character_main)
        if inv then
            count = inv.get_item_count "coin"
            if count >= coins then
                inv.remove{name = "coin", count = coins}
                return
            elseif count > 0 then
                coins = coins - count
                inv.remove{name = "coin", count = count}
            end
        end
    end
    for _, marketGroup in pairs(global.boughtMarkets) do
        local invs = markets.getRedInventories(marketGroup, true)
        for _, inv in pairs(invs) do
            count = inv.get_item_count "coin"
            if count >= coins then
                inv.remove{name = "coin", count = coins}
                return
            elseif count > 0 then
                coins = coins - count
                inv.remove{name = "coin", count = count}
            end
        end
    end
end

-- Count total coins in player inventory and market red chests.
-- If player is nil, then only check red chests.
function coinBanks.countCoins(player)
    local count = 0
    if player then
        count = coinBanks.playerCoins(player)
    end
    return count + coinBanks.redChestCoins()
end



return coinBanks
