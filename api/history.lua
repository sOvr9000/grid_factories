
local util = require "api/gutil"

local history = {}



function history.init(player)
    local menuTabbedPane = player.gui.screen.menuFrame.menuTabbedPane

    local menuTabHistory = menuTabbedPane.add{
        type = "tab",
        caption = {"gridtorio-gui.menu-tab-history"},
        name = "menuTabHistory",
    }
    local historyFlow = menuTabbedPane.add{
        type = "frame",
        name = "historyFlow",
    }
    historyFlow.style.vertically_stretchable = true

    local leftFrame = historyFlow.add{
        type = "list-box",
        name = "leftFrame",
    }
    -- leftFrame.style.maximal_width = 120
    leftFrame.style.vertically_stretchable = true
    local rightFrame = historyFlow.add{
        type = "frame",
        name = "rightFrame",
        direction = "vertical",
    }
    rightFrame.style.horizontally_stretchable = true
    rightFrame.style.vertically_stretchable = true

    for k, category in pairs{
        "all",
        "boughtChunks",
        "depletedResources",
        "discoveredAreas",
        "upgradesUnlocked",
        "markets",
        "purifiedPatches",
        "voidDimensions",
    } do
        history.setupCategory(historyFlow, category)
        global.history.categorySelectedIndexMap[category] = k
        global.history.selectedIndexCategoryMap[k] = category
    end

    menuTabbedPane.add_tab(menuTabHistory, historyFlow)
    global.menuTabs[historyFlow.name] = menuTabHistory
end

function history.setupCategory(historyFlow, category)
    historyFlow.leftFrame.add_item({"gridtorio-gui.history-" .. util.hyphenateName(category)})
    local scrollPane = historyFlow.rightFrame.add{
        type = "scroll-pane",
        name = category,
    }
    scrollPane.style.horizontally_stretchable = true
    scrollPane.style.vertically_stretchable = true
    scrollPane.visible = category == "all"
    local tbl = scrollPane.add{
        type = "table",
        name = "tbl",
        column_count = 2,
    }
    tbl.style.vertically_stretchable = false
    tbl.style.horizontally_stretchable = true
end

function history.printAndLog(str, category, printForPlayer)
    global.history.totalLogs = global.history.totalLogs + 1
    category = category or "misc"
    local categories
    if category == "all" then
        categories = {category}
    else
        categories = {category, "all"}
    end
    for _, player in pairs(game.players) do -- not just connected players because offline players should see what has happened while they were offline once they come back
        if (printForPlayer == nil or printForPlayer) and player.connected then
            player.print(str)
        end
        local historyFlow = player.gui.screen.menuFrame.menuTabbedPane.historyFlow
        local timestamp = util.getTimestamp()
        for _, c in pairs(categories) do
            log(c)
            local tbl = historyFlow.rightFrame[c].tbl
            local timestampLabel = tbl.add{
                type = "label",
                name = "ts" .. tostring(global.history.totalLogs),
                caption = timestamp,
            }
            timestampLabel.style.natural_width = 80
            -- tbl.add{
            --     type = "line",
            --     direction = "vertical",
            -- }
            local label = tbl.add{
                type = "label",
                name = "l" .. tostring(global.history.totalLogs),
                -- caption = {"", "| ", str},
                caption = str,
            }
            label.style.single_line = false
            label.style.horizontally_stretchable = true
            tbl.parent.scroll_to_bottom()
        end
    end
end

function history.onButtonClick(player, button, menuTab)
    -- if menuTab.name ~= "menuTabHistory" then return end
    -- if button.name:sub(-6) ~= "Button" then return end
    -- for _, btn in pairs(button.parent.children) do
    --     btn.style.color = {32, 30, 32}
    -- end
    -- button.style.color = {255, 191, 78}
    -- local category = button.name:sub(1, -7)
    -- local historyFlow = button.parent.parent
    -- for _, scrollPane in pairs(historyFlow.rightFrame.children) do
    --     scrollPane.visible = scrollPane.name == category
    -- end
end

function history.onCategorySelectionChanged(historyFlow, selectedIndex)
    if not selectedIndex then return end
    local category = global.history.selectedIndexCategoryMap[selectedIndex]
    if not category then return end
    for _, scrollPane in pairs(historyFlow.rightFrame.children) do
        scrollPane.visible = scrollPane.name == category
    end
end



return history
