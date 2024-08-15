
local util = require "api/gutil"
local surfaceGen = require "api/surfaceGen"
local markets = require "api/markets"
local chunks = require "api/chunks"
local upgrades = require "api/upgrades"
local stats = require "api/stats"
local itemValuesGrad = require "api/itemValuesGrad"
local players = require "api/players"

require "events/setupNauvis"
require "events/setupGridtorio"



script.on_nth_tick(600, function(event)
    for _, marketGroup in pairs(global.boughtMarkets) do
        if marketGroup.extraIO and (marketGroup.sellInv[1].get_item_count() > 0 or marketGroup.sellInv[2].get_item_count() > 0) or not marketGroup.extraIO and marketGroup.sellInv.get_item_count() > 0 then
            markets.processMarketGroup(marketGroup)
        end
    end
    for _, dchunk in pairs(global.dimensionalChunks) do
        if dchunk.voidInventories and #dchunk.voidInventories > 0 then
            if dchunk.voidInventories[1].get_item_count() > 0 or dchunk.voidInventories[2].get_item_count() > 0 then
                chunks.processVoidDimension(dchunk)
            end
        end
    end
    for _, player in pairs(game.connected_players) do
        if upgrades.isUpgradeEnabled("automatedChunkUnlocking", player) then
            chunks.automateChunkUnlocking(player)
        end
    end
    players.refreshGridtorioGUIs()
end)

script.on_nth_tick(60, function(event)
    global.coinsProduced[event.tick / 60 % 240 + 1] = global.coinsProducedThisSecond
    global.coinsConsumed[event.tick / 60 % 240 + 1] = global.coinsConsumedThisSecond
    global.coinsProducedThisSecond = 0
    global.coinsConsumedThisSecond = 0

    stats.refreshGlobal()
end)

script.on_event(defines.events.on_tick, function(event)
    -- itemValuesGrad.update()

    if global.runs.enabled then
        if global.runs.nextGameTick ~= -1 then
            if game.tick >= global.runs.nextGameTick then
                game.reset_time_played()
                game.delete_surface("gridtorio")
                -- game.create_surface("gridtorio", global.config.mainMapGen)
                global.runs.nextGameTick = -1
            end
        end
    end

    if game.tick == 5 then
        util.printGameVersion()
        setupNauvis()
        -- surfaceGen.createSurface("gridtorio", global.config.mainMapGen, {position = {x = 0, y = 0}, radius = 2, voidOutside = false, genMessage = true, finishedCallback = function(surface)
        --     setupGridtorio()
        -- end})
    end
end)


