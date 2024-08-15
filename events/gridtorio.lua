
local util = require "api/gutil"
local upgrades = require "api/upgrades"
local surfaceGen = require "api/surfaceGen"
local chunks = require "api/chunks"
local areaDiscovery = require "api/areaDiscovery"
local players = require "api/players"
local history = require "api/history"
local infinityChests = require "api/infinityChests"
local mazes = require "api/mazes"
local stats = require "api/stats"



script.on_event(defines.events.on_entity_died, function(event)
    if event.cause then
        if (event.entity.name == "small-biter" or event.entity.name == "medium-biter") and (event.cause.name == "car" or event.cause.name == "tank") then
            upgrades.incrementScore "rammedBiters"
        end
    end
    if event.entity == global.siloBase.silo then
        -- Game over
        if global.runs.enabled then
            -- endGame{silo=true}
        end
    elseif event.entity.name == "biter-spawner" or event.entity.name == "spitter-spawner" then
        -- Update upgrade data
        upgrades.incrementScore "killedSpawners"
        -- Update autoUnlockableChunks
        if event.entity.surface.name == "gridtorio" then
            local chunkCoords = event.entity.position
            local area = {
                left_top = {x = chunkCoords.x * 32 + 1, y = chunkCoords.y * 32 + 1},
                right_bottom = {x = chunkCoords.x * 32 + 32, y = chunkCoords.y * 32 + 32},
            }
            local entities = game.surfaces.gridtorio.find_entities_filtered{name = {"biter-spawner", "spitter-spawner"}, area = area}
            if #entities == 0 then
                global.acu.autoUnlockableChunks[util.positionToString(chunkCoords)] = {coords = chunkCoords, d = -1}
            end
        elseif event.entity.surface.name:sub(1, 4) == "void" then
            local dchunk = global.dchunksByDim[event.entity.surface.name]
            if not dchunk.conquered then
                dchunk.totalSpawners = dchunk.totalSpawners - 1
                if dchunk.totalSpawners <= 0 then
                    global.totalVoidDimensionsConquered = global.totalVoidDimensionsConquered + 1
                    dchunk.conquered = true
                    dchunk.loot = global.highestInfinityItem
                    chunks.deleteNearestInfestedChunk(dchunk.chunkCoords)

                    local maze = global.mazes.predefined[dchunk.mazeIndex]
                    local chestPos = mazes.relativeToWorld(maze, maze.goal.x * 2, maze.goal.y * 2, dchunk.mazeReflection, dchunk.mazeRotation)
                    chestPos = {x = chestPos.x * 32 + 16, y = chestPos.y * 32 + 16}
                    infinityChests.spawn(event.entity.surface, chestPos, global.highestInfinityItem)

                    stats.addInfinityLootItem(dchunk.loot)

                    global.highestInfinityItem = util.nextHighestItemByValue(global.highestInfinityItem)
                    if not global.highestInfinityItem then
                        global.highestInfinityItem = global.config.initialInfinityLoot -- reset to beginning
                    end

                    history.printAndLog(
                        util.colorLocalizedString({"gridtorio.void-conquered"}, "cyan"),
                        "voidDimensions",
                        global.config.notifications["void-dimension-conquered"]
                    )
                    history.printAndLog(
                        util.colorLocalizedString({"gridtorio.void-conquered-better-loot"}, "purple"),
                        "voidDimensions",
                        global.config.notifications["void-dimension-conquered"]
                    )
                    history.printAndLog(
                        "[gps=" .. util.positionToString(chestPos) .. "," .. event.entity.surface.name .. "]",
                        "voidDimensions",
                        true
                    )
                end
            end
        end
    elseif event.entity.name == "market" then
        upgrades.incrementScore "deletedMarkets"
    else
        if event.entity.force == game.forces.player then
            -- Update upgrade data
            upgrades.decrementBuiltEntityCount(event.entity.name)
        end
    end
end)

script.on_event(defines.events.on_chunk_generated, function(event)
    surfaceGen.onChunkGenerated(event.surface, event.position)
    if event.surface.name == "gridtorio" then
        chunks.initChunk(event.surface, event.position, event.area)
        if event.position.x == 0 and event.position.y == 0 then
            if global.siloBase.enabled then
                local pos = game.surfaces.gridtorio.find_non_colliding_position(
                    "rocket-silo",
                    {x = 16, y = 16},
                    12, -- radius
                    0.5 -- precision
                )
                if pos then
                    global.siloBase.silo = game.surfaces.gridtorio.create_entity{name = "rocket-silo", position = pos}
                    global.siloBase.silo.minable = false
                else
                    log("siloBase: No position found for rocket silo")
                end
            end
        end
    end
end)

script.on_event(defines.events.on_built_entity, function(event)
    if event.item then
        upgrades.incrementBuiltEntityCount(event.created_entity.name)
    end
end)

script.on_event(defines.events.on_player_mined_entity, function(event)
    upgrades.decrementBuiltEntityCount(event.entity.name)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
    upgrades.incrementBuiltEntityCount(event.created_entity.name)
end)

script.on_event(defines.events.on_robot_mined_entity, function(event)
    upgrades.decrementBuiltEntityCount(event.entity.name)
end)

script.on_event(defines.events.on_resource_depleted, function(event)
    if event.entity.surface ~= game.surfaces.gridtorio then return end
    local chunkCoords = util.getChunkCoords(event.entity.position)
    local area = util.getChunkArea(chunkCoords)
    local entities = game.surfaces.gridtorio.find_entities_filtered{type = "resource", area = area}
    if #entities == 1 then -- 1 instead of 0 because the resource entity is not yet destroyed
        upgrades.incrementScore "depletedResources"
        history.printAndLog(
            util.colorLocalizedString(
                {"gridtorio.notification-depleted-resources", "[gps=" .. event.entity.position.x .. "," .. event.entity.position.y .. ",gridtorio]"},
                "yellow"
            ),
            "depletedResources",
            global.config.notifications["depleted-resources"]
        )
    end
end)

script.on_event(defines.events.on_chunk_charted, function(event)
    if game.surfaces[event.surface_index].name == "gridtorio" then
        if not areaDiscovery.isAreaDiscovered "greatRingOfSuperChunks" then
            if areaDiscovery.checkGreatRingOfSuperChunks(event.position) then
                areaDiscovery.discover "greatRingOfSuperChunks"
                history.printAndLog(
                    util.colorLocalizedString({"gridtorio.notification-area-discovered", {"area-discovery.great-ring-of-super-chunks"}}, "blue"),
                    "discoveredAreas",
                    global.config.notifications["area-discovered"]
                )
            end
        end
    end
end)

script.on_event(defines.events.on_surface_deleted, function(event)
    surfaceGen.onSurfaceDeleted(event.surface_index)
end)

script.on_event(defines.events.on_market_item_purchased, function(event)
    players.refreshGridtorioGUI(game.players[event.player_index])
end)
