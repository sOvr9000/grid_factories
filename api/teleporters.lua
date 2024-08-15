
local util = require "api/gutil"
local players = require "api/players"

local teleporters = {}



function teleporters.addTiles(surface1, surface2, pos1, pos2, size1, size2, tileName, tpdata)
    -- Set tiles for first pad
    local s = game.surfaces[surface1]
    if not s then
        log("ERROR: Could not find surface " .. surface1)
        return
    end
    local tiles = {}
    for y = pos1.y - size1.h, pos1.y + size1.h do
        local ty = math.floor(y) + .5
        for x = pos1.x - size1.w, pos1.x + size1.w do
            local tx = math.floor(x) + .5
            local pos = {x = tx, y = ty}
            table.insert(tiles, {name = tileName, position = pos})
            teleporters.setTeleporterData(surface1, pos, tpdata)
        end
    end
    s.set_tiles(tiles)

    -- Set tiles for second pad
    s = game.surfaces[surface2]
    if not s then
        log("ERROR: Could not find surface " .. surface2)
        return
    end
    tiles = {}
    for y = pos2.y - size2.h, pos2.y + size2.h do
        local ty = math.floor(y) + .5
        for x = pos2.x - size2.w, pos2.x + size2.w do
            local tx = math.floor(x) + .5
            local pos = {x = tx, y = ty}
            table.insert(tiles, {name = tileName, position = pos})
            teleporters.setTeleporterData(surface2, pos, tpdata)
        end
    end
    s.set_tiles(tiles)
end

function teleporters.addTeleporter(surface1, surface2, pos1, pos2, size1, size2, tileName)
    local tpdata = {
        surface1 = surface1,
        surface2 = surface2,
        pos1 = pos1,
        pos2 = pos2,
        size1 = size1,
        size2 = size2,
        tileName = tileName,
    }

    teleporters.addTiles(surface1, surface2, pos1, pos2, size1, size2, tileName, tpdata)
end

function teleporters.processPlayer(player)
    if player.vehicle then return end
    local tx = math.floor(player.position.x) + .5
    local ty = math.floor(player.position.y) + .5
    local pos = {x = tx, y = ty}
    local tile = player.surface.get_tile(tx, ty)
    if not tile or not tile.valid then return end -- This keep SE from crashing
    if not global.teleporters.prevTileName[player.name] then
        global.teleporters.prevTileName[player.name] = tile.name
    else
        if global.teleporters.prevTileName[player.name] ~= tile.name then
            if global.teleporters.lastTeleported[player.name] ~= game.tick then
                global.teleporters.lastTeleported[player.name] = game.tick
                global.teleporters.prevTileName[player.name] = tile.name
                local tpdata = teleporters.getTeleporterData(player.surface.name, pos)
                if tpdata then
                    if player.surface.name == tpdata.surface1 then
                        local displayedSurfaceName
                        if tpdata.surface2:sub(1, 4) == "void" then
                            local dchunk = global.dimensionalChunks[util.positionToString(util.getChunkCoords(tpdata.pos1))]
                            if dchunk then
                                displayedSurfaceName = {"gridtorio.void-dimension", dchunk.serial}
                            end
                        end
                        teleporters.addTiles(tpdata.surface1, tpdata.surface2, tpdata.pos1, tpdata.pos2, tpdata.size1, tpdata.size2, tpdata.tileName, tpdata)
                        players.teleportPlayer(player, tpdata.pos2, game.surfaces[tpdata.surface2], displayedSurfaceName)
                    elseif player.surface.name == tpdata.surface2 then
                        teleporters.addTiles(tpdata.surface1, tpdata.surface2, tpdata.pos1, tpdata.pos2, tpdata.size1, tpdata.size2, tpdata.tileName, tpdata)
                        players.teleportPlayer(player, tpdata.pos1, game.surfaces[tpdata.surface1])
                    end
                end
            end
        end
    end
end

function teleporters.getTeleporterData(surfaceName, pos)
    local surfaceTPData = global.teleporters.positions[surfaceName]
    if not surfaceTPData then
        surfaceTPData = {}
        global.teleporters.positions[surfaceName] = surfaceTPData
    else
        return surfaceTPData[util.positionToString(pos)]
    end
end

function teleporters.setTeleporterData(surfaceName, pos, tpdata)
    local surfaceTPData = global.teleporters.positions[surfaceName]
    if not surfaceTPData then
        surfaceTPData = {}
        global.teleporters.positions[surfaceName] = surfaceTPData
    end
    surfaceTPData[util.positionToString(pos)] = tpdata
end



return teleporters
