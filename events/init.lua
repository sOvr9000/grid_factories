
local config = require "config/config"
local util = require "api/gutil"
local surfaceGen = require "api/surfaceGen"
local itemValues = require "api/itemValues"
local itemValuesGrad = require "api/itemValuesGrad"
local newGridtorio = require "api/newGridtorio"


require "interfaces"


global.menu = require "data/menu"
global.tradeOverview = require "data/tradeOverview"
global.tools = require "data/tools"
global.upgrades = require "data/upgrades"
global.itemValueCalculation = require "data/itemValues"
global.settingsGUI = require "data/settingsGUI"

global.acu = require "data/acu"
global.areaDiscovery = require "data/areaDiscovery"
global.mazes = require "data/mazes"
global.teleporters = require "data/teleporters"
global.history = require "data/history"
global.players = require "data/players"

global.colors = require "data/colors"
global.styles = require "data/styles"

global.siloBase = require "data/siloBase"
global.runs = require "data/runs"
global.dangerousArty = require "data/dangerousArty"



-- Use Nauvis' map generation settings to alter the gridtorio surface's generation settings, namely ore frequency, size, and richness, as well as biter settings.
local function applyNauvisMapSettings()
    local nauvis = game.surfaces.nauvis.map_gen_settings
    local freq = 0
    local size = 0
    local richness = 0
    for resource, tab in pairs(nauvis.autoplace_controls) do
        if resource ~= "trees" and resource ~= "enemy-base" then
            freq = freq + tab.frequency
            size = size + tab.size
            richness = richness + tab.richness
        end
    end
    local log_36e = 1 / math.log(36)
    freq = math.log(freq) * log_36e
    richness = math.log(richness) * log_36e
    -- freq and richness are now in the range [0, 1]
    if freq > 0.5 then
        global.config.baseOreChance = util.lerp(global.config.baseOreChance, 1, (freq - 0.5) * 2)
    elseif freq < 0.5 then
        global.config.baseOreChance = util.lerp(global.config.baseOreChance, 0.05, (0.5 - freq) * 2)
    end
    local rscale = richness + 0.5
    rscale = rscale * rscale
    rscale = rscale * rscale
    global.config.baseOreRichness = global.config.baseOreRichness * rscale
    global.config.oreRichnessOverDistance = global.config.oreRichnessOverDistance * rscale
    if size == 0 then
        global.config.baseOreChance = 0
    else
        size = math.log(size) * log_36e
        -- size is now in the range [0, 1]
        global.config.baseOreSize = math.max(1, math.min(15, global.config.baseOreSize * size * 2))
        global.config.biterChunkOreSizeIncrement = math.max(1, global.config.biterChunkOreSizeIncrement * size * 2)
        if global.config.baseOreSize + global.config.biterChunkOreSizeIncrement >= 15 then
            global.config.biterChunkOreSizeIncrement = 15 - global.config.baseOreSize
        end
    end
    -- log("freq: " .. freq)
    -- log("size: " .. size)
    -- log("richness: " .. richness)
    -- log("baseOreChance: " .. global.config.baseOreChance)
    -- log("baseOreRichness: " .. global.config.baseOreRichness)
    -- log("oreRichnessOverDistance: " .. global.config.oreRichnessOverDistance)
    -- log("rscale: " .. rscale)
    freq = (math.log(nauvis.autoplace_controls["enemy-base"].frequency, 6) + 1) * 0.5
    -- freq is now in the range [0, 1]
    if freq > 0.5 then
        global.config.biterChunkChance = util.lerp(global.config.biterChunkChance, 1, (freq - 0.5) * 2)
    elseif freq < 0.5 then
        global.config.biterChunkChance = util.lerp(global.config.biterChunkChance, 0.05, (0.5 - freq) * 2)
    end
    size = (math.log(nauvis.autoplace_controls["enemy-base"].size, 6) + 1) * 0.5
    if size > 0.5 then
        global.config.biterChunkSpawnerChance = util.lerp(global.config.biterChunkSpawnerChance, 0.75, (size - 0.5) * 2)
        global.config.biterChunkWormChance = util.lerp(global.config.biterChunkWormChance, 1, (size - 0.5) * 2)
    elseif size < 0.5 then
        global.config.biterChunkSpawnerChance = util.lerp(global.config.biterChunkSpawnerChance, 0.05, (0.5 - size) * 2)
        global.config.biterChunkWormChance = util.lerp(global.config.biterChunkWormChance, 0.05, (0.5 - size) * 2)
    end
end

-- local function endGame(args)
--     if args.silo then
--         game.print({"", "[color=yellow]", {"addon-silo-base.silo-destroyed"}, "[.color]"})
--     end
--     game.print({"addon-runs.restarting", global.runs.restartTime})
--     global.runs.nextGameTick = game.tick + 60 * global.runs.restartTime
-- end

script.on_init(function(event)
    config.init()
    global.configDefaults = util.deepcopy(global.config)

    game.map_settings.enemy_expansion.enabled = false

    global.error_messages = {}

    global.ruinsChunkBuildingNames = {}
    global.ruinsChunkBuildingWeights = {}
    local ruinsChunkBuildingTotalWeight = 0
    for entityName, weight in pairs(global.config.ruinsChunkBuildings) do
        table.insert(global.ruinsChunkBuildingNames, entityName)
        table.insert(global.ruinsChunkBuildingWeights, weight)
        ruinsChunkBuildingTotalWeight = ruinsChunkBuildingTotalWeight + weight
    end
    global.ruinsChunkBuildingTotalWeight = ruinsChunkBuildingTotalWeight
    
    global.chunkUnlockCost = global.config.chunkUnlockCostInitial

    newGridtorio.init()

    global.menuTabs = {}
    global.allTradeStrings = {}
    global.interpolatedVoidChunkMaxChance = global.config.voidChunks.maxChance
    global.greatRingOfSuperChunksRadii = {
        global.config.greatRingOfSuperChunks.fadeInRadius,
        global.config.greatRingOfSuperChunks.innerRadius,
        global.config.greatRingOfSuperChunks.outerRadius,
        global.config.greatRingOfSuperChunks.fadeOutRadius,
    }
    global.totalVoidDimensions = 0
    global.totalVoidDimensionsConquered = 0
    global.highestInfinityItem = global.config.initialInfinityLoot

    -- stats
    global.totalBoughtChunks = 0
    global.coinsProducedThisSecond = 0
    global.coinsProduced = {}
    global.coinsConsumedThisSecond = 0
    global.coinsConsumed = {}
    global.chunksUnlockedBy = {}

    applyNauvisMapSettings()

    surfaceGen.init()
    itemValues.init()
    itemValues.registerAll()
    itemValuesGrad.init()

end)

script.on_configuration_changed(function(changed)
    if changed.old_version then
        -- Mod updated
        game.reload_script()
    end
end)
