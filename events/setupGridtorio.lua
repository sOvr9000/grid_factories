
local util = require "api/gutil"
local chunks = require "api/chunks"
local acu = require "api/acu"
local players = require "api/players"



function setupGridtorio()
    chunks.setChunkUnlockCost(global.config.chunkUnlockCostInitial)

    local chunkCoords = {x = 0, y = 0}
    global.boughtChunks[util.positionToString(chunkCoords)] = true
    chunks.onChunkBought(nil, game.surfaces.gridtorio, chunkCoords, -1)

    acu.updateAutoUnlockableChunks(chunkCoords)

    global.totalBoughtChunks = 0

    for _, msg in pairs(global.error_messages) do
        game.print(msg)
    end

    item = "iron-gear-wheel"
    repeat
        log(item)
        item = util.nextHighestItemByValue(item)
    until not item

    -- for _, player in pairs(game.connected_players) do
    --     players.teleportPlayer(player, {x=16, y=16}, game.surfaces.gridtorio, {"", "Gridtorio"})
    -- end
end


