
local util = require "api/gutil"
local chunks = require "api/chunks"
local popups = require "api/popups"



commands.add_command("add-coins", {"gridtorio.command-help-add-coins"}, function(command)
    if not command.player_index then return end
    local player = game.get_player(command.player_index)
    if not player then return end -- weird Factorio bug if this happens, but it's here just in case
    if not player.admin then return end
    local args = util.parseArgs(command.parameter)
    if #args == 1 then
        local coins = tonumber(args[1])
        if not coins then return end
        player.insert{name = "coin", count = coins}
    elseif #args == 0 then
        player.insert{name = "coin", count = 100000}
    end
end)

commands.add_command("item-value", {"gridtorio.command-help-item-value"}, function(command)
    if not command.player_index then return end
    local player = game.get_player(command.player_index)
    if not player then return end -- weird Factorio bug if this happens, but it's here just in case
    -- if not player.admin then return end
    local args = util.parseArgs(command.parameter)
    if #args == 0 then
        for name, value in pairs(global.itemValues) do
            if type(value) == "number" then
                player.print(name .. ": " .. value)
            end
        end
    elseif #args == 1 then
        local name = args[1]
        local value = global.itemValues[name]
        if value then
            player.print(name .. ": " .. (value / global.itemValues["coin"]) .. "x [item=coin]")
        else
            player.print({"gridtorio.error-command-item-value-unrecognized", name})
        end
    end
end)

commands.add_command("gridtorio-version", {"gridtorio.command-help-version"}, function(command)
    if not command.player_index then return end
    local player = game.get_player(command.player_index)
    if not player then return end -- weird Factorio bug if this happens, but it's here just in case
    util.printGameVersion(player)
end)

commands.add_command("recenter-menu", {"gridtorio.command-help-recenter-menu"}, function(command)
    if not command.player_index then return end
    local player = game.get_player(command.player_index)
    if not player then return end -- weird Factorio bug if this happens, but it's here just in case
    local menuFrame = player.gui.screen.menuFrame
    if menuFrame then
        menuFrame.force_auto_center()
    else
        log("ERROR: No menu frame found")
    end
end)

commands.add_command("debug-items", "", function(command)
    if not command.player_index then return end
    local player = game.get_player(command.player_index)
    if not player then return end -- weird Factorio bug if this happens, but it's here just in case
    if not player.admin then return end

    player.force.character_inventory_slots_bonus=1000
    player.force.research_all_technologies()

    player.insert{name="power-armor-mk2", count = 1}
    local p_armor = player.get_inventory(defines.inventory.character_armor)[1].grid
    if not p_armor then return end
	p_armor.put({name = "fusion-reactor-equipment"})
	p_armor.put({name = "fusion-reactor-equipment"})
	p_armor.put({name = "fusion-reactor-equipment"})
	p_armor.put({name = "exoskeleton-equipment"})
	p_armor.put({name = "exoskeleton-equipment"})
	p_armor.put({name = "exoskeleton-equipment"})
	p_armor.put({name = "exoskeleton-equipment"})
	p_armor.put({name = "energy-shield-mk2-equipment"})
	p_armor.put({name = "energy-shield-mk2-equipment"})
	p_armor.put({name = "personal-roboport-mk2-equipment"})
	p_armor.put({name = "night-vision-equipment"})
	p_armor.put({name = "battery-mk2-equipment"})
	p_armor.put({name = "battery-mk2-equipment"})

    player.insert{name = "coin", count = 500000}
    player.insert{name = "construction-robot", count = 25}
    player.insert{name = "submachine-gun", count = 1}
    player.insert{name = "uranium-rounds-magazine", count = 200}
    player.insert{name = "electric-energy-interface", count = 1}
    player.insert{name = "spidertron", count = 40}

    player.cheat_mode = true
    game.player.force.friendly_fire = false
end)

commands.add_command("unlock-chunks", "", function(command)
    local player = game.players[command.player_index]
    if not player then return end -- weird Factorio bug if this happens, but it's here just in case
    if not player.admin then return end
    for i = 1, 100 do
        chunks.automateChunkUnlocking(player)
        -- local chunk = acu.getChunkToUnlock()
        -- if not chunk then return end
        -- chunks.unlockChunk(player, player.surface, chunk.coords, chunk.d, false)
    end
end)

commands.add_command("export-trades", {"gridtorio.command-help-export-trades"}, function(command)
    local player = game.players[command.player_index]
    if not player then return end -- weird Factorio bug if this happens, but it's here just in case
    if not player.admin then return end

    local csv = "id,marketId,amountToGive,itemToGive,amountToReceive,itemToReceive,marketId\n"
    local k = 0
    local marketId = 0
    for _, marketGroup in pairs(global.boughtMarkets) do
        for _, trade in pairs(marketGroup.trades) do
            csv = csv .. k .. ",".. marketId .. "," .. trade.amountToGive .. "," .. trade.itemToGive .. "," .. trade.amountToReceive .. "," .. trade.itemToReceive .. "\n"
            k = k + 1
        end
        marketId = marketId + 1
    end

    popups.show(player, csv, {"gridtorio-gui.menu-tab-trade-overview"})
end)

commands.add_command("export-markets", {"gridtorio.command-help-export-markets"}, function(command)
    local player = game.players[command.player_index]
    if not player then return end -- weird Factorio bug if this happens, but it's here just in case
    if not player.admin then return end

    local csv = "id,x,y\n"
    local k = 0
    for _, marketGroup in pairs(global.boughtMarkets) do
        local market = marketGroup.market
        csv = csv .. k .. "," .. market.position.x .. "," .. market.position.y .. "\n"
        k = k + 1
    end

    popups.show(player, csv, {"gridtorio-gui.menu-tab-market-overview"})
end)

commands.add_command("export-values", {"gridtorio.command-help-export-values"}, function(command)
    local player = game.players[command.player_index]
    if not player then return end -- weird Factorio bug if this happens, but it's here just in case
    -- if not player.admin then return end

    local values = {}
    for name, value in pairs(global.itemValues) do
        table.insert(values, {name=name, value=value})
    end

    table.sort(values, function(a, b) return a.value > b.value end)

    local csv = "item,value\n"
    for _, t in pairs(values) do
        csv = csv .. t.name .. "," .. (t.value / global.itemValues["coin"]) .. "\n"
    end

    popups.show(player, csv, {"gridtorio-gui.item-values"})
end)
