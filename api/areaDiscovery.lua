
local util = require "api/gutil"

local areaDiscovery = {}



function areaDiscovery.checkGreatRingOfSuperChunks(chunkCoords)
    -- local dist = 32 * math.sqrt(chunkCoords.x * chunkCoords.x + chunkCoords.y * chunkCoords.y)
    -- return dist >= util.lerp(global.config.voidChunkMinDistance, global.config.greatRingOfSuperChunksFadeInRadius, 0.84)
    local dist = util.getChunkDistance(chunkCoords)
    return dist >= global.config.greatRingOfSuperChunks.innerRadius
end

function areaDiscovery.isAreaDiscovered(area)
    return global.areaDiscovery.discovered[area] == true
end

function areaDiscovery.discover(area)
    global.areaDiscovery.discovered[area] = true
end



return areaDiscovery
