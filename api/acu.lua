
local util = require "api/gutil"

local acu = {}



function acu.getChunkToUnlock()
    local posStr = util.reservoirSample(global.acu.autoUnlockableChunks)
    if posStr then
        return global.acu.autoUnlockableChunks[posStr]
    end
end

function acu.updateAutoUnlockableChunks(chunkCoords)
    -- log("update " .. util.positionToString(chunkCoords))
    local posStr = util.positionToString(chunkCoords)
    if global.acu.autoUnlockableChunks[posStr] then
        global.acu.autoUnlockableChunks[posStr] = nil
    end
    for d = 0, 3 do
        local adjChunkCoords = util.offsetPosition(chunkCoords, d)
        local adjPosStr = util.positionToString(adjChunkCoords)
        if not global.acu.autoUnlockableChunks[adjPosStr] and not global.boughtChunks[adjPosStr] then
            -- search for biters
            local area = {
                left_top = {
                    x = adjChunkCoords.x * 32 + 1,
                    y = adjChunkCoords.y * 32 + 1,
                },
                right_bottom = {
                    x = adjChunkCoords.x * 32 + 32,
                    y = adjChunkCoords.y * 32 + 32,
                },
            }
            local entities = game.surfaces.gridtorio.find_entities_filtered{name = {"biter-spawner", "spitter-spawner"}, area = area}
            if #entities == 0 then
                if not global.voidChunks[adjPosStr] then
                    global.acu.autoUnlockableChunks[adjPosStr] = {coords = chunkCoords, d = d}
                end
            end
        end
    end
    -- log("new chunks: " .. util.tableLength(global.acu.autoUnlockableChunks))
    -- for _, chunk in pairs(global.acu.autoUnlockableChunks) do
    --     log(util.positionToString(chunk.coords).. " " .. chunk.d)
    -- end
end



return acu
