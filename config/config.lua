
local util = require "api/gutil"
local itemValues = require "itemValues"
local biters = require "biters"
local chunks = require "chunks"
local markets = require "markets"
local ore = require "ore"
local players = require "players"
local upgrades = require "upgrades"
local ruinsChunks = require "ruinsChunks"
local voidChunks = require "voidChunks"
local superChunks = require "superChunks"
local dimensionalChunks = require "dimensionalChunks"
local teleporters = require "teleporters"
local gui = require "gui"

local config = {}



function config.init()
    global.config = {
        notifications = {
            ["wall-purchase"] = true, -- Notify all players when a chunk gets purchased by anyone.  In the endgame, we tend to see chat get spammed by chunk purchases every now and then.  It's nice to turn it off at some point, but it's difficult to algorithmically detect when that point in the game has been reached so that it's turned off automatically.
            ["upgrade-unlock"] = true, -- Notify all players when someone unlocks an upgrade.
            ["depleted-resources"] = true, -- Notify all players when a chunk is depleted of its resources.
            ["area-discovered"] = true, -- Notify all players when a new area is discovered.
            ["surface-generation"] = true, -- Notify the player (who caused the surface generation) about when generation starts and ends.
            ["patch-purified"] = true, -- Notify all players when someone obliviates a resource from a deposit.
            ["deleted-market"] = true, -- Notify all players when a market is deleted.
            ["void-dimension-opened"] = true, -- Notify all players when a void dimension is opened.
            ["void-dimension-conquered"] = true, -- Notify all players when a void dimension is conquered.
            ["market-bank-toggled"] = true, -- Notify all players when a market bank is toggled.
        },

        -- Settings used for map generation.
        mainMapGen = {
            terrain_segmentation = 2,
            water = 0.5,
            starting_points = {{x = 16, y = 16}},
            width = 2000000,
            height = 2000000,
            starting_area = 1,
            peaceful_mode = false,
        
            autoplace_controls = {
                -- These are only defined to disable the natural ore and biter base generation. (size = 0)
                -- This scenario generates its own ores and biter bases.
                ["iron-ore"] = {frequency = 1, size = 0, richness = 1},
                ["copper-ore"] = {frequency = 1, size = 0, richness = 1},
                ["stone"]= {frequency = 1, size = 0, richness = 1},
                ["coal"] = {frequency = 1, size = 0, richness = 1},
                ["uranium-ore"]= {frequency = 1, size = 0, richness = 1},
                ["crude-oil"] = {frequency = 1, size = 0, richness = 1},
                ["trees"]= {frequency = 1, size = 0, richness = 1},
                ["enemy-base"] = {frequency = 1, size = 0, richness = 1},
            },
        
            cliff_settings = {
                name = "cliff",
                cliff_elevation_0 = 10,
                cliff_elevation_interval = 40,
                richness = 0, -- disables cliffs
            },
        },
    }

    global.config.voidDimensionMapGen = util.deepcopy(global.config.mainMapGen)
    global.config.voidDimensionMapGen.water = 0 -- disable water generation

    util.tableExtend(global.config, biters)
    util.tableExtend(global.config, itemValues)
    util.tableExtend(global.config, chunks)
    util.tableExtend(global.config, markets)
    util.tableExtend(global.config, ore)
    util.tableExtend(global.config, players)
    util.tableExtend(global.config, upgrades)
    util.tableExtend(global.config, ruinsChunks)
    util.tableExtend(global.config, voidChunks)
    util.tableExtend(global.config, superChunks)
    util.tableExtend(global.config, dimensionalChunks)
    util.tableExtend(global.config, teleporters)
    util.tableExtend(global.config, gui)

end



return config
