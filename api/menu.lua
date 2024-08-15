
local styles = require "styles"

local menu = {}



function menu.init(player)
    local menuFrame = player.gui.screen.add{
        type = "frame",
        name = "menuFrame",
        direction = "vertical",
        caption = {"gridtorio-gui.menu-frame-title"},
        style = "frame",
    }

    local joinDiscordFlow = menuFrame.add{
        type = "flow",
        name = "joinDiscordFlow",
    }
    local closeButton = joinDiscordFlow.add{
        type = "sprite-button",
        name = "closeButton",
        sprite = "utility/close_white",
    }
    local vertFlow = joinDiscordFlow.add{
        type = "flow",
        name = "vertFlow",
        direction = "vertical",
    }
    local joinDiscordLabel = vertFlow.add{
        type = "label",
        caption = {"gridtorio-gui.join-discord"},
    }
    local joinDiscordLink = vertFlow.add{
        type = "textfield",
        name = "joinDiscordLink",
        text = "https://discord.gg/huJY7QK6UG"
    }
    styles.applyStyle(joinDiscordLabel, "joinDiscord")

    local tabbedPane = menuFrame.add{
        type = "tabbed-pane",
        name = "menuTabbedPane"
    }

    menuFrame.style.natural_height = global.config.gui.menu.height
    menuFrame.style.natural_width = global.config.gui.menu.width
    menuFrame.style.maximal_height = global.config.gui.menu.height
    menuFrame.style.maximal_width = global.config.gui.menu.width

    tabbedPane.selected_tab_index = 3
end

function menu.toggleVisibility(player)
    if not player then return end
    local frame = player.gui.screen.menuFrame
    if not frame then
        menu.init(player)
        return
    end
    if frame.visible then
        frame.visible = false
    else
        frame.visible = true
        player.opened = frame
    end
end

function menu.getTabAboveElement(player, element)
    if not element then return end
    if not element.parent then return end
    if element.parent == player.gui then return end
    if element.parent.type == "tabbed-pane" then
        local tab = global.menuTabs[element.name]
        if tab then return tab end
    end
    return menu.getTabAboveElement(player, element.parent)
end



return menu
