
local util = require "api/gutil"
local chunks = require "api/chunks"
local menu = require "api/menu"
local tradeOverview = require "api/tradeOverview"
local tools = require "api/tools"
local upgrades = require "api/upgrades"
local settingsGUI = require "api/settingsGUI"
local stats = require "api/stats"
local history = require "api/history"
local popups = require "api/popups"



script.on_event(defines.events.on_gui_click, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local root = util.getRootPlayerGUI(event.element)
    if root and root.name == "settingsFrame" then
        -- Handle settings
        settingsGUI.onButtonClick(player, event.element)
        return
    end

    -- Handle "History" tab ping clicks
    if event.element.type == "label" and event.element.parent and event.element.parent.name == "tbl" then
        -- for now, this is making the assumption that this actually is in the history tab, but it's possible that a feature implemented later could use the same GUI structure and naming scheme
        local gps = util.findGPSSubstring(event.element.caption)
        if gps then
            player.print(gps)
        end
    end

    -- Handle popups
    if event.element.name == "popup_confirm" then
        popups.close(game.get_player(event.player_index))
        return
    end

    -- Handle chunk unlocking
    if util.tableContains({"north", "east", "south", "west"}, event.element.name) then
        chunks.onDirectionButtonClicked(player, event.element.name)
        return
    end

    -- Handle trade overview
    if event.element.type == "sprite" then
        if event.element.parent and event.element.parent.name:sub(1, 5) == "trade" then
            tradeOverview.onSpriteClicked(player, event.element)
            return
        end
    end

    -- Handle void loot buttons in stats tab
    if event.element.type == "sprite-button" and event.element.parent and event.element.parent.name == "voidLootTable" then
        stats.onVoidLootButtonPressed(player, event.element)
    end

    -- Handle menu
    if event.element.name == "menuButton" then
        player.gui.screen.menuFrame.visible = true
        player.opened = player.gui.screen.menuFrame
    elseif event.element.type == "button" or event.element.type == "sprite-button" then
        if event.element.name == "closeButton" and event.element.parent.name == "joinDiscordFlow" then
            event.element.parent.destroy()
        else
            local menuTab = menu.getTabAboveElement(player, event.element)
            if menuTab then
                tradeOverview.onButtonClick(player, event.element, menuTab)
                tools.onButtonClick(player, event.element, menuTab)
                upgrades.onButtonClick(player, event.element, menuTab)
                history.onButtonClick(player, event.element, menuTab)
            end
        end
    elseif event.element.type == "tab" then
        if event.element.name == "menuTabTradeOverview" then
            tradeOverview.refresh(player)
        elseif event.element.name == "menuTabTools" then
            tools.refresh(player)
        elseif event.element.name == "menuTabUpgrades" then
            upgrades.refresh(player)
        elseif event.element.name == "menuTabStats" then
            stats.refreshPersonal(player)
        end
    end

end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if event.element.name == "tradeFilter" then
        tradeOverview.refresh(player)
    elseif event.element.name == "patchPurificationResource" then
        player.gui.screen.menuFrame.menuTabbedPane.toolsFlow.patchPurificationFlow.confirmationFlow.visible = false
    end
end)

script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if event.element.name == "buySellSwitch" then
        tradeOverview.refresh(player)
    end
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local root = util.getRootPlayerGUI(event.element)
    if root and root.name == "settingsFrame" then
        settingsGUI.onCheckboxChanged(player, event.element)
        return
    end

    if event.element.name == "enableQuality" then
        tradeOverview.refresh(player)
    elseif event.element.name == "enableTradeUniqueness" then
        global.upgrades.globallyEnabledUpgrades.tradeUniqueness = event.element.state
        for _, p in pairs(game.players) do
            p.gui.screen.menuFrame.menuTabbedPane.toolsFlow.tradeUniquenessFlow.enableTradeUniqueness.state = event.element.state
        end
    elseif event.element.name == "enableMarketRNG" then
        global.upgrades.globallyEnabledUpgrades.marketRng = event.element.state
        for _, p in pairs(game.players) do
            p.gui.screen.menuFrame.menuTabbedPane.toolsFlow.marketRNGFlow.enableMarketRNG.state = event.element.state
        end
    elseif event.element.name == "enableFreeRoboports" then
        global.upgrades.globallyEnabledUpgrades.freeRoboports = event.element.state
        for _, p in pairs(game.players) do
            p.gui.screen.menuFrame.menuTabbedPane.toolsFlow.freeRoboportsFlow.enableFreeRoboports.state = event.element.state
        end
    elseif event.element.name == "enableMarketIOChests" then
        global.upgrades.globallyEnabledUpgrades.marketIoChests = event.element.state
        for _, p in pairs(game.players) do
            p.gui.screen.menuFrame.menuTabbedPane.toolsFlow.marketIOChestsFlow.enableMarketIOChests.state = event.element.state
        end
    elseif event.element.name == "enableInfestedChunks" then
        global.upgrades.globallyEnabledUpgrades.noMoreInfestedChunks = event.element.state
        for _, p in pairs(game.players) do
            p.gui.screen.menuFrame.menuTabbedPane.toolsFlow.infestedChunksFlow.enableInfestedChunks.state = event.element.state
        end
    elseif event.element.name == "enableAutomatedChunkUnlocking" then
        global.upgrades.enabledUpgrades[player.name].automatedChunkUnlocking = event.element.state
    end
end)

script.on_event(defines.events.on_gui_closed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if event.element and event.element.name == "popupFrame" then
        popups.close(player)
        return
    end
    if event.element and event.element.name == "menuFrame" then
        menu.toggleVisibility(player)
    else
        if player.opened ~= player.gui.screen.menuFrame and player.gui.screen.menuFrame.visible then
            player.gui.screen.menuFrame.visible = false
        end
    end
end)

script.on_event(defines.events.on_gui_confirmed, function(event)
    local root = util.getRootPlayerGUI(event.element)
    if root and root.name == "settingsFrame" then
        if event.element.type == "textfield" then
            settingsGUI.onTextChanged(game.players[event.player_index], event.element)
        end
    end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    local root = util.getRootPlayerGUI(event.element)
    if root and root.name == "settingsFrame" then
        if event.element.type == "textfield" then
            if event.element.text ~= "" then
                settingsGUI.onTextChanged(game.players[event.player_index], event.element)
            end
        end
    end
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    local root = util.getRootPlayerGUI(event.element)
    if root and root.name == "settingsFrame" then
        settingsGUI.onDropdownChanged(game.players[event.player_index], event.element)
        return
    end
    if event.element.name == "leftFrame" then
        log("history!")
        history.onCategorySelectionChanged(event.element.parent, event.element.selected_index)
    end
end)

script.on_event(defines.events.on_gui_value_changed, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local root = util.getRootPlayerGUI(event.element)
    if root then
        if root.name == "settingsFrame" then
            -- nothing for now
        elseif root.name == "menuFrame" then
            if event.element.type == "slider" then
                tradeOverview.onSliderValueChanged(player, event.element)
            end
        end
    end
end)
