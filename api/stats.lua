
local util = require "api/gutil"
local styles = require "api/styles"

local stats = {}



function stats.init(player)
    local menuTabbedPane = player.gui.screen.menuFrame.menuTabbedPane

    local menuTabStats = menuTabbedPane.add{
        type = "tab",
        caption = {"gridtorio-gui.menu-tab-stats"},
        name = "menuTabStats",
    }
    local statsFlow = menuTabbedPane.add{
        type = "frame",
        name = "statsFlow",
        direction = "vertical",
    }
    statsFlow.style.vertically_stretchable = true
    -- statsFlow.style.maximal_height = 560

    stats.initGlobal(statsFlow)
    statsFlow.add{type = "line"}
    stats.initPersonal(statsFlow)

    menuTabbedPane.add_tab(menuTabStats, statsFlow)
    global.menuTabs[statsFlow.name] = menuTabStats
end

function stats.initGlobal(statsFlow)
    local globalHeader = statsFlow.add{
        type = "label",
        name = "globalHeader",
        caption = {"gridtorio-gui.stats-global-header"},
    }
    styles.applyStyle(globalHeader, "header")
    local coinProductionLabel = statsFlow.add{
        type = "label",
        name = "coinProductionLabel",
        caption = {"stats-tab.coin-production", 0},
    }
    local coinConsumptionLabel = statsFlow.add{
        type = "label",
        name = "coinConsumptionLabel",
        caption = {"stats-tab.coin-consumption", 0},
    }
    local chunksUnlockedGlobalLabel = statsFlow.add{
        type = "label",
        name = "chunksUnlockedGlobalLabel",
        caption = {"stats-tab.chunks-unlocked", 0},
    }
    local featureLockedFrame = statsFlow.add{
        type = "frame",
        name = "featureLockedFrame",
    }
    local featureLockedLabel = featureLockedFrame.add{
        type = "label",
        name = "featureLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(featureLockedLabel, "featureLocked")
    local voidDimensionsFlow = statsFlow.add{
        type = "flow",
        name = "voidDimensionsFlow",
        direction = "vertical",
    }
    local dimensionsConqueredLabel = voidDimensionsFlow.add{
        type = "label",
        name = "dimensionsConqueredLabel",
        caption = {"stats-tab.void-dimensions-conquered", 0},
    }
    local voidLootFrame = voidDimensionsFlow.add{
        type = "frame",
        name = "voidLootFrame",
        direction = "vertical",
    }
    local voidLootLabel = voidLootFrame.add{
        type = "label",
        name = "voidLootLabel",
        caption = {"stats-tab.void-loot"},
    }
    styles.applyStyle(voidLootLabel, "smallHeader")
    local voidLootTable = voidLootFrame.add{
        type = "table",
        name = "voidLootTable",
        column_count = 10,
    }
    voidDimensionsFlow.visible = false
end

function stats.initPersonal(statsFlow)
    local personalHeader = statsFlow.add{
        type = "label",
        name = "personalHeader",
        caption = {"gridtorio-gui.stats-personal-header"},
    }
    styles.applyStyle(personalHeader, "header")
    local chunksUnlockedPersonalLabel = statsFlow.add{
        type = "label",
        name = "chunksUnlockedPersonalLabel",
        caption = {"stats-tab.chunks-unlocked", 0},
    }
end

function stats.refreshGlobal()
    local coinsProduction = util.sum(global.coinsProduced) * .25
    local coinsConsumption = util.sum(global.coinsConsumed) * .25
    for _, player in pairs(game.connected_players) do
        local statsFlow = player.gui.screen.menuFrame.menuTabbedPane.statsFlow
        statsFlow.coinProductionLabel.caption = {"stats-tab.coin-production", coinsProduction}
        statsFlow.coinConsumptionLabel.caption = {"stats-tab.coin-consumption", coinsConsumption}
        statsFlow.chunksUnlockedGlobalLabel.caption = {"stats-tab.chunks-unlocked", global.totalBoughtChunks}
        statsFlow.voidDimensionsFlow.dimensionsConqueredLabel.caption = {"stats-tab.void-dimensions-conquered", global.totalVoidDimensionsConquered}
    end
end

function stats.refreshPersonal(player)
    local statsFlow = player.gui.screen.menuFrame.menuTabbedPane.statsFlow
    statsFlow.chunksUnlockedPersonalLabel.caption = {"stats-tab.chunks-unlocked", global.chunksUnlockedBy[player.name] or 0}
end

function stats.addInfinityLootItem(itemName)
    for _, player in pairs(game.players) do
        local menuTabbedPane = player.gui.screen.menuFrame.menuTabbedPane
        local statsFlow = menuTabbedPane.statsFlow
        local voidLootTable = statsFlow.voidDimensionsFlow.voidLootFrame.voidLootTable
        local sprite = voidLootTable.add{
            type = "sprite-button",
            name = "sprite" .. #voidLootTable.children,
            sprite = "item/" .. itemName,
        }
    end
end

function stats.onVoidLootButtonPressed(player, button)
    for _, dchunk in pairs(global.dimensionalChunks) do
        if dchunk.loot == button.sprite:sub(6) then
            player.print(util.gpsToString({x=dchunk.chunkCoords.x*32+16, y=dchunk.chunkCoords.y*32+16}, "gridtorio"))
            break
        end
    end
end



return stats
