
local util = require "api/gutil"

local surfaceGen = {}



function surfaceGen.init()
    global.surfaceGen = {}
    global.surfaceGen.initSurfaces = {}
    global.surfaceGen.initSurfacesArgs = {}
    global.surfaceGen.deletedSurfaces = {}
end

function surfaceGen.createSurface(name, mapSettings, initChunks)
    if initChunks.genMessage then
        game.print(util.colorLocalizedString({"gridtorio.surface-generating", name}, "green"))
    end
    mapSettings.seed = math.random(0, 4000000000)
    global.surfaceGen.generatedChunks = {}
    global.surfaceGen.initSurfaces[name] = false
    initChunks.generatedChunks = {}
    initChunks.chunkGenCallback = initChunks.chunkGenCallback or function(surface, pos) end
    initChunks.finishedCallback = initChunks.finishedCallback or function(surface) end
    global.surfaceGen.initSurfacesArgs[name] = initChunks
    game.create_surface(name, mapSettings)
    game.surfaces[name].request_to_generate_chunks(initChunks.position, initChunks.radius)
end

function surfaceGen.onChunkGenerated(surface, pos)
    local args = global.surfaceGen.initSurfacesArgs[surface.name]
    if not args then return end
    if global.surfaceGen.initSurfaces[surface.name] then
        if args.voidOutside ~= false then -- make it so that nil is treated as true
            util.setTiles(surface, pos, "out-of-map", true, false)
        end
        return
    end
    if args.chunkGenCallback then
        args.chunkGenCallback(surface, pos)
    end
    if args.generatedChunks then
        args.generatedChunks[util.positionToString(pos)] = true
    end

    for y = args.position.y - args.radius, args.position.y + args.radius do
        for x = args.position.x - args.radius, args.position.x + args.radius do
            if not args.generatedChunks[util.positionToString({x = x, y = y})] then
                return
            end
        end
    end

    global.surfaceGen.initSurfaces[surface.name] = true
    if args.genMessage then
        game.print(util.colorLocalizedString({"gridtorio.surface-generated", surface.name}, "green"))
    end
    if args.finishedCallback then
        args.finishedCallback(surface)
    end
    args.generatedChunks = nil
    args.finishedCallback = nil
    args.chunkGenCallback = nil
end

function surfaceGen.isInit(name)
    return global.surfaceGen.initSurfaces[name] == true
end

function surfaceGen.deleteSurface(name, finishedCallback)
    finishedCallback = finishedCallback or function() end
    if game.surfaces[name] then
        log("deleted surface " .. name)
        game.delete_surface(game.surfaces[name])
        global.surfaceGen.deletedSurfaces[game.surfaces[name].index] = {finishedCallback = finishedCallback}
    else
        finishedCallback()
    end
end

function surfaceGen.onSurfaceDeleted(index)
    local args = global.surfaceGen.deletedSurfaces[index]
    if not args then return end
    args.finishedCallback()
end



return surfaceGen

