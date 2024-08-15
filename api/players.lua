
local util = require "api/gutil"
local menu = require "api/menu"
local tools = require "api/tools"
local tradeOverview = require "api/tradeOverview"
local upgrades = require "api/upgrades"
local stats = require "api/stats"
local history = require "api/history"
local coinBanks = require "api/coinBanks"

local players = {}



function players.teleportPlayer(player, position, surface, displayedSurfaceName)
    if player.surface ~= surface then
        displayedSurfaceName = displayedSurfaceName or surface.name
        player.print({"gridtorio.teleport-cross-surface", displayedSurfaceName})
    end

    local pos = surface.find_non_colliding_position(
        "character",
        position,
        15, -- radius
        0.5 -- precision
    )
    if pos then
        player.teleport(pos, surface)
    else
        log("Could not teleport player; no open space found")
    end
    -- player.teleport(position, surface)
    -- This single line works too, but it risks players getting stuck inside something, such as another player.  The other code above doesn't work yet since the gridtorio surface isn't completely generated when it tries to find an open position.  It's WIP.
end

function players.initGridtorio(player)
    for _, items in pairs(global.config.starterItems) do
        player.insert{name = items[1], count = items[2]}
    end

    menu.init(player)
    history.init(player)
    stats.init(player)
    upgrades.init(player)
    tradeOverview.init(player)
    tools.init(player)
    menu.toggleVisibility(player)
    player.gui.screen.menuFrame.force_auto_center()

    local dirFrame = player.gui.top.add{
        type = "frame",
        name = "NESWFrame",
        direction = "vertical",
    }

    local chunkUnlockCost = dirFrame.add{
        type = "label",
        name = "chunkUnlockCost",
    }
    chunkUnlockCost.style.font_color = {212, 169, 19}

    local availableCoins = dirFrame.add{
        type = "label",
        name = "availableCoins",
        caption = {"gridtorio-gui.available-coins", 0},
    }
    availableCoins.style.font_color = {212, 169, 19}

    if global.chunkUnlockCost then
        chunkUnlockCost.caption = {"gridtorio-gui.chunk-cost", global.chunkUnlockCost}
    end

    dirFrame.add{type = "line"}

    local dirButtonsFrame = dirFrame.add{
        type = "table",
        name = "NESWTable",
        column_count = 3,
    }

    dirButtonsFrame.add{
        type = "empty-widget",
        name = "NESWplaceholder00",
    }

    dirButtonsFrame.add{
        type = "button",
        name = "north",
        caption = "↑",
        style = "slot_sized_button",
    }

    dirButtonsFrame.add{
        type = "empty-widget",
        name = "NESWplaceholder20",
    }

    dirButtonsFrame.add{
        type = "button",
        name = "west",
        caption = "←",
        style = "slot_sized_button",
    }

    dirButtonsFrame.add{
        type = "sprite",
        name = "NESWCharacter",
        sprite = "entity/character",
    }.style.left_margin = 8

    -- dirButtonsFrame.add{
    --     type = "empty-widget",
    --     name = "NESWplaceholder11",
    -- }

    dirButtonsFrame.add{
        type = "button",
        name = "east",
        caption = "→",
        style = "slot_sized_button",
    }

    dirButtonsFrame.add{
        type = "empty-widget",
        name = "NESWplaceholder02",
    }

    dirButtonsFrame.add{
        type = "button",
        name = "south",
        caption = "↓",
        style = "slot_sized_button",
    }

    dirButtonsFrame.add{
        type = "empty-widget",
        name = "NESWplaceholder22",
    }

    local menuButton = player.gui.top.add{
        type = "button",
        name = "menuButton",
        caption = {"gridtorio-gui.menu-button"},
    }
    menuButton.style.font = "compilatron-message-font"

    upgrades.giveNewPlayerCurrentUpgrades(player)

end

function players.refreshGridtorioGUI(player, redChestCoins)
    redChestCoins = redChestCoins or coinBanks.redChestCoins()
    local totalCoins = redChestCoins + coinBanks.playerCoins(player)
    local dirFrame = player.gui.top.NESWFrame
    local availableCoins = dirFrame.availableCoins
    availableCoins.caption = {"gridtorio-gui.available-coins", totalCoins}

    local enable = totalCoins >= global.chunkUnlockCost
    global.players.missingCoinsForChunk[player.name] = global.chunkUnlockCost - totalCoins
    for _, dir in pairs{"north", "east", "south", "west"} do
        local button = dirFrame.NESWTable[dir]
        button.enabled = enable
        if enable then
            button.tooltip = ""
        else
            button.tooltip = {"gridtorio.need-more-coins-for-chunk", global.players.missingCoinsForChunk[player.name]}
        end
    end
end

function players.refreshGridtorioGUIs()
    local marketChestCoins = coinBanks.countCoins()
    for _, p in pairs(game.connected_players) do
        players.refreshGridtorioGUI(p, marketChestCoins)
    end
end

function players.onPlayerChunkCoordsChanged(player, prevChunkCoords, newChunkCoords)
    players.refreshGridtorioGUI(player)

    local dirs = {"east", "south", "west", "north"}
    local dirArrows = {"→", "↓", "←", "↑"}
    global.players.dangerousDirections[player.name] = {false, false, false, false}
    for d = 0, 3 do
        local adjCoords = util.offsetPosition(newChunkCoords, d)
        if not upgrades.isUpgradeUnlocked "noMoreInfestedChunks" and util.canChunkGetInfested(adjCoords) then
            global.players.dangerousDirections[player.name][d + 1] = true
        end
    end
    for d = 0, 3 do
        local dir = dirs[d + 1]
        local button = player.gui.top.NESWFrame.NESWTable[dir]
        local s = util.colorLocalizedString({"gridtorio.dangerous-chunk"}, "red")
        if global.players.dangerousDirections[player.name][d + 1] then
            button.caption = "[color=yellow]⚠[.color]"
            if not button.enabled then
                button.tooltip = {"", {"gridtorio.need-more-coins-for-chunk", global.players.missingCoinsForChunk[player.name]}, "\n", s}
            else
                button.tooltip = s
            end
        else
            local arrow = dirArrows[d + 1]
            button.caption = arrow
            if not button.enabled then
                button.tooltip = {"gridtorio.need-more-coins-for-chunk", global.players.missingCoinsForChunk[player.name]}
            else
                button.tooltip = ""
            end
        end
    end
end

-- Return whether the player's count of coins in their main inventory has changed since this function was last called.
function players.didInvCoinChange(player)
    local inv = player.get_inventory(defines.inventory.character_main)
    if not inv then return end
    local newCount = inv.get_item_count "coin"
    local original = global.players.prevCoinCount[player.name]
    global.players.prevCoinCount[player.name] = newCount
    return newCount ~= original
end



return players
