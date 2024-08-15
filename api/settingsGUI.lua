
local util = require "api/gutil"
local styles = require "api/styles"
local players = require "api/players"
local surfaceGen = require "api/surfaceGen"
local newGridtorio = require "api/newGridtorio"

local settingsGUI = {}



function settingsGUI.initPlayer(player)
    local settingsFrame = player.gui.screen.add{
        type = "frame",
        name = "settingsFrame",
        direction = "vertical",
        style = "frame",
        caption = {"gridtorio-gui.scenario-settings"},
    }
    styles.applyStyle(settingsFrame, "settingsFrame")
    local topFlow = settingsFrame.add{
        type = "flow",
        name = "topFlow",
    }
    local randomize = topFlow.add{
        type = "button",
        name = "randomize",
        caption = {"gridtorio-gui.randomize"},
    }
    local play = topFlow.add{
        type = "button",
        name = "play",
        caption = {"gridtorio-gui.play"},
        style = "confirm_button_without_tooltip",
    }
    local bottomFlow = settingsFrame.add{
        type = "flow",
        name = "bottomFlow",
    }
    local leftFrame = bottomFlow.add{
        type = "frame",
        name = "leftFrame",
        direction = "vertical",
    }
    leftFrame.style.horizontally_stretchable = false
    leftFrame.style.natural_width = 275
    leftFrame.style.minimal_width = 275
    local scrollPane = leftFrame.add{
        type = "scroll-pane",
        name = "scrollPane",
        direction = "vertical",
    }
    scrollPane.style.horizontally_stretchable = false
    scrollPane.style.natural_width = 275
    scrollPane.style.minimal_width = 275
    local rightFrame = bottomFlow.add{
        type = "frame",
        name = "rightFrame",
    }
    local camera = rightFrame.add{
        type = "camera",
        name = "preview",
        position = {x = 16, y = 16},
        surface_index = 1,
        zoom = 0.18,
        style = "camera",
    }
    camera.style.horizontally_stretchable = true
    camera.style.vertically_stretchable = true
    -- camera.style.natural_width = 800
    -- camera.style.natural_height = 800

    for settingName, settingObj in pairs(global.config) do
        settingsGUI.addSettingGUI(player, {}, settingName, settingObj)
    end

    settingsGUI.refresh(player)

    settingsGUI.randomize(player)
    settingsFrame.force_auto_center()
end

function settingsGUI.refresh(player)
    settingsGUI.refreshLeftFrame(player)
    settingsGUI.refreshRightFrame(player)
end

function settingsGUI.refreshLeftFrame(player, filter)
    filter = filter or {}
    -- util.guiMap(player.gui.screen.settingsFrame.bottomFlow.leftFrame, function(element)
    --     if element.type == "frame" then
    --         if element.name:find(filter.name) then
    --             element.visible = false
    --         end
    --     end
    -- end)
    -- util.guiMap(player.gui.screen.settingsFrame.bottomFlow.leftFrame, function(element)
        
    -- end)
end

function settingsGUI.refreshRightFrame(player)
    -- nothing to be done yet
end

function settingsGUI.addSettingGUI(player, path, settingName, settingObj)
    if settingName == "gui" or settingName == "itemValues" or settingName == "mainMapGen" or settingName == "voidDimensionMapGen" then return end
    local t = type(settingObj)
    local parent = player.gui.screen.settingsFrame.bottomFlow.leftFrame.scrollPane
    for _, s in pairs(path) do
        parent = parent[s]
    end
    log(table.concat(path, ".") .. "." .. settingName)
    local displayName = settingName
    if parent[settingName] then
        settingName = "_" .. settingName
    end
    if t == "number" then
        local flow = parent.add{
            type = "flow",
            name = settingName,
        }
        -- flow.style.maximal_width = 250
        local revert = flow.add{
            type = "sprite-button",
            name = "revert",
            sprite = "utility/reset",
            style = "mini_tool_button_red",
        }
        revert.tooltip = {"gridtorio-gui.revert-setting"}
        revert.style.top_margin = 7
        local label = flow.add{
            type = "label",
            name = "label",
            caption = displayName,
        }
        label.style.top_margin = 4
        flow.add{type = "line"}
        local field = flow.add{
            type = "textfield",
            name = "textfield",
            text = settingObj,
            numeric = true,
            allow_decimal = settingObj % 1 ~= 0,
            -- anchor = {gui = defines.relative_gui_type.server_config_gui, position = defines.relative_gui_position.right},
        }
    elseif t == "string" then
        local flow = parent.add{
            type = "flow",
            name = settingName,
        }
        -- flow.style.maximal_width = 250
        local revert = flow.add{
            type = "sprite-button",
            name = "revert",
            sprite = "utility/reset",
            style = "mini_tool_button_red",
        }
        revert.tooltip = {"gridtorio-gui.revert-setting"}
        revert.style.top_margin = 7
        local label = flow.add{
            type = "label",
            name = "label",
            caption = displayName,
        }
        label.style.top_margin = 4
        flow.add{type = "line"}
        if global.settingsGUI.configWithColoredTileDropdown[settingName] then
            local dropdown = flow.add{
                type = "drop-down",
                name = "dropdown",
                items = global.settingsGUI.coloredTileDropdown,
                selected_index = util.indexOf(global.settingsGUI.coloredTileDropdown, settingObj),
            }
        else
            local field = flow.add{
                type = "textfield",
                name = "textfield",
                text = settingObj,
                numeric = false,
                -- anchor = {gui = defines.relative_gui_type.server_config_gui, position = defines.relative_gui_position.right},
            }
        end
    elseif t == "boolean" then
        local flow = parent.add{
            type = "flow",
            name = settingName,
        }
        -- flow.style.maximal_width = 250
        local revert = flow.add{
            type = "sprite-button",
            name = "revert",
            sprite = "utility/reset",
            style = "mini_tool_button_red",
        }
        revert.tooltip = {"gridtorio-gui.revert-setting"}
        revert.style.top_margin = 7
        local toggle = flow.add{
            type = "checkbox",
            name = "checkbox",
            state = settingObj,
        }
        local label = flow.add{
            type = "label",
            name = "label",
            caption = displayName,
        }
        label.style.top_margin = 4
    elseif t == "table" then
        local sNames = {}
        for sName, sObj in pairs(settingObj) do
            if type(sName) == "string" then
                table.insert(sNames, sName)
            end
        end
        if #sNames > 0 then
            local newPath = util.deepcopy(path)
            newPath[#newPath + 1] = settingName
            local frame = parent.add{
                type = "frame",
                name = settingName,
                direction = "vertical",
                style = "frame",
                caption = displayName,
            }
            -- frame.style.maximal_width = 250
            for _, sName in pairs(sNames) do
                local sObj = settingObj[sName]
                settingsGUI.addSettingGUI(player, newPath, sName, sObj)
            end
        end
    end
end

function settingsGUI.randomize(player)
    player.gui.screen.settingsFrame.bottomFlow.rightFrame.preview.surface_index = 1
    player.gui.screen.settingsFrame.topFlow.play.enabled = false
    surfaceGen.deleteSurface("gridtorio", function()
        newGridtorio.init()
        surfaceGen.createSurface("gridtorio", global.config.mainMapGen, {position = {x = 0, y = 0}, radius = 2, voidOutside = false, genMessage = true, finishedCallback = function(surface)
            setupGridtorio()
            player.gui.screen.settingsFrame.bottomFlow.rightFrame.preview.surface_index = game.surfaces.gridtorio.index
            player.gui.screen.settingsFrame.topFlow.play.enabled = true
        end})
    end)
end

function settingsGUI.onButtonClick(player, button)
    if button.name == "revert" then
        local path = settingsGUI.getPathToElement(button)
        local settingName = path[#path]
        local settingObj = global.configDefaults
        for _, s in pairs(path) do
            settingObj = settingObj[s]
        end
        if type(settingObj) == "string" then
            if button.parent.dropdown then
                button.parent.dropdown.selected_index = util.indexOf(global.settingsGUI.coloredTileDropdown, settingObj)
            else
                button.parent.textfield.text = settingObj
            end
        elseif type(settingObj) == "number" then
            button.parent.textfield.text = tostring(settingObj)
        elseif type(settingObj) == "boolean" then
            button.parent.checkbox.state = settingObj
        end
        settingsGUI.randomize(player)
    elseif button.name == "randomize" then
        settingsGUI.randomize(button)
    elseif button.name == "play" then
        global.setup = true
        for _, player in pairs(game.connected_players) do
            players.teleportPlayer(player, {x = 16, y = 16}, game.surfaces.gridtorio, {"", "Gridtorio"})
            player.gui.top.menuButton.visible = true
            player.gui.top.NESWFrame.visible = true
            player.gui.screen.settingsFrame.destroy()
        end
    end
end

function settingsGUI.getPathToElement(element)
    local path = {}
    local e = element
    repeat
        e = e.parent
        table.insert(path, 1, e.name)
    until e.parent.name == "scrollPane"
    return path
end

function settingsGUI.onCheckboxChanged(player, checkbox)
    local path = settingsGUI.getPathToElement(checkbox)
    -- log(table.concat(path, "."))
    local settingObj = global.config
    for i = 1, #path - 1 do
        s = path[i]
        settingObj = settingObj[s]
        log(s)
    end
    -- log("Setting global.config." .. table.concat(path, ".") .. " = " .. tostring(checkbox.state))
    local t = type(settingObj[path[#path]])
    settingObj[path[#path]] = checkbox.state
    settingsGUI.randomize(player)
end

function settingsGUI.onTextChanged(player, textfield)
    if textfield.text == "" then return end
    local path = settingsGUI.getPathToElement(textfield)
    -- log(table.concat(path, "."))
    local settingObj = global.config
    for i = 1, #path - 1 do
        s = path[i]
        settingObj = settingObj[s]
        log(s)
    end
    -- log("Setting global.config." .. table.concat(path, ".") .. " = " .. textfield.text)
    local t = type(settingObj[path[#path]])
    if t == "number" then
        settingObj[path[#path]] = tonumber(textfield.text)
    else
        settingObj[path[#path]] = textfield.text
    end
    settingsGUI.randomize(player)
end

function settingsGUI.onDropdownChanged(player, dropdown)
    local path = settingsGUI.getPathToElement(dropdown)
    log(table.concat(path, "."))
    local settingObj = global.config
    for i = 1, #path - 1 do
        s = path[i]
        settingObj = settingObj[s]
        log(s)
    end
    local tile = global.settingsGUI.coloredTileDropdown[dropdown.selected_index]
    log("Setting global.config." .. table.concat(path, ".") .. " = " .. tile)
    local t = type(settingObj[path[#path]])
    settingObj[path[#path]] = tile
    settingsGUI.randomize(player)
end



return settingsGUI
