
local util = require "api/gutil"
local upgrades = require "api/upgrades"
local players = require "api/players"
local teleporters = require "api/teleporters"



script.on_event(defines.events.on_player_created, function(event)
    -- single player, new game started
    if not event.player_index then return end
    local player = game.get_player(event.player_index)
    if not player then return end

    -- -- Find a random generated chunk with ore and a market in it.
    -- local chunk = util.reservoirSample(surface.get_chunks(), function(chunk)
    --     local entities = player.surface.find_entities(chunk.area)
    --     return util.entitiesHasOre(entities) and util.entitiesHasMarket(entities)
    -- end)

    -- -- Teleport the player to that chunk
    -- if not chunk then
    --     player.print("No chunk with both ore and a market found!")
    -- else
    --     player.teleport{chunk.x * 32 + 16, chunk.y * 32 + 16}
    -- end

    -- if player.surface.name == "nauvis" then
    --     players.initNauvis(player)
    -- end

    players.initGridtorio(player)
    if not global.setup then
        player.gui.top.menuButton.visible = false
        player.gui.top.NESWFrame.visible = false
    else
        players.teleportPlayer(player, {x = 16.5, y = 16.5}, game.surfaces.gridtorio)
    end

end)

script.on_event(defines.events.on_player_respawned, function(event)
    players.teleportPlayer(game.get_player(event.player_index), {x = 16.5, y = 16.5}, game.surfaces.gridtorio)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    if not player then return end

    upgrades.giveNewPlayerCurrentUpgrades(player)
end)

script.on_event(defines.events.on_player_changed_position, function(event)
    local player = game.players[event.player_index]
    teleporters.processPlayer(player)
    
    local chunkCoords = util.getChunkCoordsOfPlayer(player)
    if not global.players.lastChunkCoords[player.name] then
        global.players.lastChunkCoords[player.name] = chunkCoords
    else
        local prev = global.players.lastChunkCoords[player.name]
        if chunkCoords.x ~= prev.x or chunkCoords.y ~= prev.y then
            players.onPlayerChunkCoordsChanged(player, prev, chunkCoords)
        end
    end
end)

script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    local player = game.players[event.player_index]
    if players.didInvCoinChange(player) then
        players.refreshGridtorioGUI(player)
    end
end)
