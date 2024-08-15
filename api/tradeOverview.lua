
local menu = require "menu"
local styles = require "styles"
local upgrades = require "api/upgrades"

local tradeOverview = {}



function tradeOverview.init(player)
    local menuTabbedPane = player.gui.screen.menuFrame.menuTabbedPane

    local menuTabTradeOverview = menuTabbedPane.add{
        type = "tab",
        -- caption = {"gridtorio-gui.menu-tab-trade-overview"},
        caption = {"gridtorio-gui.menu-tab-locked"},
        name = "menuTabTradeOverview",
    }
    local TOFlow = menuTabbedPane.add{
        type = "frame",
        name = "TOFlow",
        direction = "vertical",
    }
    TOFlow.style.vertically_stretchable = true
    -- TOFlow.style.maximal_height = 560

    local TOTopFlow = TOFlow.add{
        type = "flow",
        name = "TOTopFlow",
    }
    local tradeFilterFrame = TOTopFlow.add{
        type = "frame",
        name = "tradeFilterFrame",
    }
    local tradeFilterLocked = tradeFilterFrame.add{
        type = "label",
        name = "tradeFilterLocked",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(tradeFilterLocked, "featureLocked")
    local tradeFilter = tradeFilterFrame.add{
        type = "choose-elem-button",
        name = "tradeFilter",
        elem_type = "item",
    }
    tradeFilter.visible = false
    local tradeFilterFlow = tradeFilterFrame.add{
        type = "flow",
        name = "tradeFilterFlow",
        direction = "vertical",
    }
    tradeFilterFlow.visible = false
    local tradeFilterLabel = tradeFilterFlow.add{
        type = "label",
        name = "tradeFilterLabel",
        caption = {"gridtorio-gui.trade-overview-filter"},
    }
    local buySellSwitch = tradeFilterFlow.add{
        type = "switch",
        name = "buySellSwitch",
        switch_state = "none",
        allow_none_state = true,
        left_label_caption = {"gridtorio-gui.trade-overview-search-switch-buy"},
        left_label_tooltip = {"gridtorio-gui.trade-overview-search-switch-buy-tooltip"},
        right_label_caption = {"gridtorio-gui.trade-overview-search-switch-sell"},
        right_label_tooltip = {"gridtorio-gui.trade-overview-search-switch-sell-tooltip"},
    }
    local extraFrame = TOTopFlow.add{
        type = "frame",
        name = "extraFrame",
        direction = "vertical",
    }
    local enableQualityLocked = extraFrame.add{
        type = "label",
        name = "enableQualityLocked",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(enableQualityLocked, "featureLocked")
    local qualityFlow = extraFrame.add{
        type = "flow",
        name = "qualityFlow",
        direction = "vertical",
    }
    local enableQualityFlow = qualityFlow.add{
        type = "flow",
        name = "enableQualityFlow",
    }
    local enableQuality = enableQualityFlow.add{
        type = "checkbox",
        name = "enableQuality",
        state = true,
    }
    local enableQualityLabel = enableQualityFlow.add{
        type = "label",
        name = "enableQualityLabel",
        caption = {"gridtorio-gui.trade-overview-enable-quality"},
    }
    local sliderFlow = qualityFlow.add{
        type = "flow",
        name = "sliderFlow",
    }
    local sliderMinLabel = sliderFlow.add{
        type = "label",
        name = "sliderMinLabel",
        caption = "-0.01",
    }
    local qualitySlider = sliderFlow.add{
        type = "slider",
        name = "qualitySlider",
        minimum_value = -0.01,
        maximum_value = 0.01,
        value = -0.01,
        value_step = 0.001,
        discrete_slider = true,
    }
    local sliderMaxLabel = sliderFlow.add{
        type = "label",
        name = "sliderMaxLabel",
        caption = "0.01",
    }
    qualityFlow.visible = false
    TOFlow.add{
        type = "line",
    }
    local TOScrollFrame = TOFlow.add{
        type = "scroll-pane",
        name = "TOScrollFrame",
    }
    TOScrollFrame.style.vertically_stretchable = true
    TOScrollFrame.style.horizontally_stretchable = true

    menuTabbedPane.add_tab(menuTabTradeOverview, TOFlow)
    global.menuTabs[TOFlow.name] = menuTabTradeOverview

    -- tradeOverview.refresh(player)
    menuTabTradeOverview.enabled = false
end

function tradeOverview.refresh(player)
    local TOFlow = player.gui.screen.menuFrame.menuTabbedPane.TOFlow
    local TOScrollFrame = TOFlow.TOScrollFrame
    local tradeFilter = TOFlow.TOTopFlow.tradeFilterFrame.tradeFilter
    local buySellSwitch = TOFlow.TOTopFlow.tradeFilterFrame.tradeFilterFlow.buySellSwitch
    local enableQuality = TOFlow.TOTopFlow.extraFrame.qualityFlow.enableQualityFlow.enableQuality
    local qualitySlider = TOFlow.TOTopFlow.extraFrame.qualityFlow.sliderFlow.qualitySlider
    local sliderMinLabel = TOFlow.TOTopFlow.extraFrame.qualityFlow.sliderFlow.sliderMinLabel
    local sliderMaxLabel = TOFlow.TOTopFlow.extraFrame.qualityFlow.sliderFlow.sliderMaxLabel
    TOScrollFrame.clear()
    local i = 0
    local qualityFilter = function(trade)
        if not enableQuality.state or trade.quality > qualitySlider.slider_value then
            return true
        end
        return false
    end
    local getEffStr = function(q)
        local eff = q + 1
        local effStr = string.format("%.1f", eff * 100 - 100)
        if eff >= 1 then
            if eff >= 1.12 then
                effStr = "[color=purple]" .. effStr .. "%[.color]"
            elseif eff >= 1.08 then
                effStr = "[color=blue]+" .. effStr .. "%[.color]"
            else
                effStr = "[color=green]+" .. effStr .. "%[.color]"
            end
        else
            if eff <= 0.92 then
                effStr = "[color=black]" .. effStr .. "%[.color]"
            elseif eff <= 0.95 then
                effStr = "[color=red]" .. effStr .. "%[.color]"
            else
                effStr = "[color=orange]" .. effStr .. "%[.color]"
            end
        end
        return effStr
    end
    for _, marketGroup in pairs(global.boughtMarkets) do
        local filteredTrades = {}
        for _, trade in pairs(marketGroup.trades) do
            local t = {
                trade = trade,
                quality = global.itemValues[trade.itemToReceive] * trade.amountToReceive / (global.itemValues[trade.itemToGive] * trade.amountToGive) - 1,
            }
            local m = qualitySlider.get_slider_minimum()
            local M = qualitySlider.get_slider_maximum()
            local q = math.floor(t.quality * 1000) / 1000
            if q < m then
                if qualitySlider.slider_value == m then
                    qualitySlider.slider_value = q
                end
                qualitySlider.set_slider_minimum_maximum(q, M)
                sliderMinLabel.caption = getEffStr(q)
            end
            if q > M then
                if qualitySlider.slider_value == M then
                    qualitySlider.slider_value = q
                end
                qualitySlider.set_slider_minimum_maximum(m, q)
                sliderMaxLabel.caption = getEffStr(q)
            end
            if buySellSwitch.switch_state == "none" then
                if not tradeFilter.elem_value or trade.itemToGive == tradeFilter.elem_value or trade.itemToReceive == tradeFilter.elem_value then
                    if qualityFilter(t) then
                        table.insert(filteredTrades, t)
                    end
                end
            else
                if buySellSwitch.switch_state == "left" and trade.itemToGive == "coin" then -- "buy" trades
                    if not tradeFilter.elem_value or trade.itemToReceive == tradeFilter.elem_value then
                        if qualityFilter(t) then
                            table.insert(filteredTrades, t)
                        end
                    end
                elseif buySellSwitch.switch_state == "right" and trade.itemToReceive == "coin" then -- "sell" trades
                    if not tradeFilter.elem_value or trade.itemToGive == tradeFilter.elem_value then
                        if qualityFilter(t) then
                            table.insert(filteredTrades, t)
                        end
                    end
                end
            end
        end
        if #filteredTrades > 0 then
            local posStr = marketGroup.market.position.x .. ", " .. marketGroup.market.position.y
            local marketFrame = TOScrollFrame.add{
                type = "flow",
                name = "TOFrame" .. i,
            }
            local marketDescFrame = marketFrame.add{
                type = "flow",
                name = "marketDescFrame",
            }
            marketFrame.add{type = "line", direction="vertical"}
            local pingButton = marketDescFrame.add{
                type = "button",
                name = "pingButton",
                caption = "[gps=" .. posStr .. ",gridtorio]",
                style = "slot_sized_button",
            }
            pingButton.tooltip = {"gridtorio-gui.exclusive-ping"}
            -- local marketDescLabel = marketDescFrame.add{
            --     type = "label",
            --     name = "marketDescLabel",
            --     caption = {"gridtorio-gui.trade-overview-market-desc", posStr},
            -- }
            local tradesTable = marketFrame.add{
                type = "table",
                name = "trades",
                column_count = global.config.gui.tradeOverview.columnsPerMarket,
            }
            local j = 0
            for _, t in pairs(filteredTrades) do
                -- local tradeStr = trade.amountToGive .. "x [item=" .. trade.itemToGive .. "] → " .. trade.amountToReceive .. "x [item=" .. trade.itemToReceive .. "]"
                local trade = t.trade
                local effStr = getEffStr(t.quality)
                local tradeFrame = tradesTable.add{
                    type = "frame",
                    name = "trade" .. j,
                }
                tradeFrame.style.natural_width = 150
                tradeOverview.addItemSprite(tradeFrame, "itemToGive", trade.itemToGive)
                local conversionFlow = tradeFrame.add{
                    type = "flow",
                    direction = "vertical",
                }
                conversionFlow.add{
                    type = "label",
                    name = "conversion",
                    caption = trade.amountToGive .. " → " .. trade.amountToReceive,
                }
                if global.upgrades.unlocked.tradeOverviewQuality and enableQuality.state then
                    conversionFlow.add{
                        type = "label",
                        name = "efficiency",
                        caption = effStr,
                    }
                end
                tradeOverview.addItemSprite(tradeFrame, "itemToReceive", trade.itemToReceive)

                i = i + 1
                j = j + 1
            end
        end
    end
end

function tradeOverview.addItemSprite(frame, name, item)
    local sprite = frame.add{
        type = "sprite",
        name = name,
        sprite = "item/" .. item,
    }
    if game.item_prototypes[item] then
        sprite.tooltip = game.item_prototypes[item].localised_name
    end
end

function tradeOverview.onButtonClick(player, button, menuTab)
    if menuTab.name ~= "menuTabTradeOverview" then return end
    if button.name == "pingButton" then
        player.print(button.caption)
        menu.toggleVisibility(player)
    end
end

function tradeOverview.onSpriteClicked(player, sprite)
    if upgrades.isUpgradeUnlocked "tradeOverviewFilter" then
        local itemName = sprite.sprite:sub(6)
        if game.item_prototypes[itemName] then
            player.gui.screen.menuFrame.menuTabbedPane.TOFlow.TOTopFlow.tradeFilterFrame.tradeFilter.elem_value = itemName
            tradeOverview.refresh(player)
        end
    end
end

function tradeOverview.onSliderValueChanged(player, slider)
    global.tradeOverview.minQuality = slider.slider_value
    tradeOverview.refresh(player)
end



return tradeOverview
