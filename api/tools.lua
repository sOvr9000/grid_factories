
local util = require "api/gutil"
local markets = require "api/markets"
local tradeOverview = require "api/tradeOverview"
local styles = require "api/styles"
local coinBanks = require "api/coinBanks"
local history = require "api/history"

local tools = {}



function tools.init(player)
    local menuTabbedPane = player.gui.screen.menuFrame.menuTabbedPane

    local menuTabTools = menuTabbedPane.add{
        type = "tab",
        -- caption = {"gridtorio-gui.menu-tab-tools"},
        caption = {"gridtorio-gui.menu-tab-locked"},
        name = "menuTabTools",
    }
    local toolsFlow = menuTabbedPane.add{
        type = "frame",
        name = "toolsFlow",
        direction = "vertical",
    }
    toolsFlow.style.vertically_stretchable = true
    -- toolsFlow.style.maximal_height = 560

    tools.initToggleMarketAsBank(toolsFlow)
    tools.initMarketDeletion(toolsFlow)
    tools.initMarketUpgrade(toolsFlow)
    tools.addLine(toolsFlow)
    tools.initPatchPurification(toolsFlow)
    tools.addLine(toolsFlow)
    tools.initMarketRNG(toolsFlow)
    tools.initTradeUniqueness(toolsFlow)
    tools.initFreeRoboports(toolsFlow)
    tools.initMarketIOChests(toolsFlow)
    tools.initInfestedChunks(toolsFlow)
    tools.addLine(toolsFlow)
    tools.initAutomatedChunkUnlocking(toolsFlow)

    menuTabbedPane.add_tab(menuTabTools, toolsFlow)
    global.menuTabs[toolsFlow.name] = menuTabTools

    -- global.tools.deleteMarketCost = global.wallRemovalCost * 2

    menuTabTools.enabled = false
    toolsFlow.visible = false
end

function tools.addLine(toolsFlow)
    toolsFlow.add{type = "line"}
end

function tools.initToggleMarketAsBank(toolsFlow)
    local toggleMarketAsBankButton = toolsFlow.add{
        type = "button",
        name = "toggleMarketAsBankButton",
        caption = {"gridtorio-gui.tools-toggle-market-as-bank"},
    }
end

function tools.initMarketDeletion(toolsFlow)
    local marketDeletionFlow = toolsFlow.add{
        type = "flow",
        name = "marketDeletionFlow",
    }
    local featureLockedFrame = marketDeletionFlow.add{
        type = "frame",
        name = "featureLockedFrame",
    }
    local featureLockedLabel = featureLockedFrame.add{
        type = "label",
        name = "featureLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(featureLockedLabel, "featureLocked")
    local marketDeletionButton = marketDeletionFlow.add{
        type = "button",
        name = "marketDeletionButton",
        caption = {"gridtorio-gui.tools-delete-market-button", global.tools.deleteMarketCost},
    }
    marketDeletionButton.visible = false
    marketDeletionButton.tooltip = {"gridtorio-gui.tools-delete-market-button-tooltip"}
    local confirmationFlow = marketDeletionFlow.add{
        type = "flow",
        name = "confirmationFlow",
    }
    local confirmButton = confirmationFlow.add{
        type = "sprite-button",
        name = "confirmButton",
        sprite = "utility/check_mark_green",
    }
    local cancelButton = confirmationFlow.add{
        type = "sprite-button",
        name = "cancelButton",
        sprite = "utility/deconstruction_mark",
    }
    confirmationFlow.visible = false
end

function tools.initMarketUpgrade(toolsFlow)
    local marketUpgradeFlow = toolsFlow.add{
        type = "flow",
        name = "marketUpgradeFlow",
    }
    local featureLockedFrame = marketUpgradeFlow.add{
        type = "frame",
        name = "featureLockedFrame",
    }
    local featureLockedLabel = featureLockedFrame.add{
        type = "label",
        name = "featureLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(featureLockedLabel, "featureLocked")
    local marketUpgradeButton = marketUpgradeFlow.add{
        type = "button",
        name = "marketUpgradeButton",
        caption = {"gridtorio-gui.tools-upgrade-market-button"},
    }
    marketUpgradeButton.visible = false
end

function tools.initPatchPurification(toolsFlow)
    local patchPurificationLockedFrame = toolsFlow.add{
        type = "frame",
        name = "patchPurificationLockedFrame",
    }
    local patchPurificationLockedLabel = patchPurificationLockedFrame.add{
        type = "label",
        name = "patchPurificationLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    local patchPurificationFlow = toolsFlow.add{
        type = "flow",
        name = "patchPurificationFlow",
    }
    styles.applyStyle(patchPurificationLockedLabel, "featureLocked")
    patchPurificationFlow.visible = false
    local patchPurificationResource = patchPurificationFlow.add{
        type = "choose-elem-button",
        name = "patchPurificationResource",
        elem_type = "item",
        -- elem_filters = {{filter = "type", type = "armor"}},
        elem_filters = {{filter = "name", name = {"iron-ore", "copper-ore", "stone", "coal"}}},
    }
    local patchPurificationButton = patchPurificationFlow.add{
        type = "button",
        name = "patchPurificationButton",
        caption = {"gridtorio-gui.tools-obliviate-resource"},
    }
    styles.applyStyle(patchPurificationButton, "patchPurificationButton")
    local confirmationFlow = patchPurificationFlow.add{
        type = "flow",
        name = "confirmationFlow",
    }
    local costLabel = confirmationFlow.add{
        type = "label",
        name = "costLabel",
    }
    styles.applyStyle(costLabel, "patchPurificationCost")
    local confirmButton = confirmationFlow.add{
        type = "sprite-button",
        name = "confirmButton",
        sprite = "utility/check_mark_green",
    }
    local cancelButton = confirmationFlow.add{
        type = "sprite-button",
        name = "cancelButton",
        sprite = "utility/deconstruction_mark",
    }
    confirmationFlow.visible = false
end

function tools.initMarketRNG(toolsFlow)
    local marketRNGFlow = toolsFlow.add{
        type = "flow",
        name = "marketRNGFlow",
    }
    local featureLockedFrame = marketRNGFlow.add{
        type = "frame",
        name = "featureLockedFrame",
    }
    local featureLockedLabel = featureLockedFrame.add{
        type = "label",
        name = "featureLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(featureLockedLabel, "featureLocked")
    local enableMarketRNG = marketRNGFlow.add{
        type = "checkbox",
        name = "enableMarketRNG",
        state = true,
    }
    enableMarketRNG.visible = false
    styles.applyStyle(enableMarketRNG, "toggleButton")
    local enableMarketRNGLabel = marketRNGFlow.add{
        type = "label",
        name = "enableMarketRNGLabel",
        caption = {"gridtorio-gui.tools-toggle-market-rng"},
    }
    enableMarketRNGLabel.visible = false
    enableMarketRNGLabel.tooltip = {"gridtorio-gui.global-tools-tooltip"}
end

function tools.initTradeUniqueness(toolsFlow)
    local tradeUniquenessFlow = toolsFlow.add{
        type = "flow",
        name = "tradeUniquenessFlow",
    }
    local featureLockedFrame = tradeUniquenessFlow.add{
        type = "frame",
        name = "featureLockedFrame",
    }
    local featureLockedLabel = featureLockedFrame.add{
        type = "label",
        name = "featureLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(featureLockedLabel, "featureLocked")
    local enableTradeUniqueness = tradeUniquenessFlow.add{
        type = "checkbox",
        name = "enableTradeUniqueness",
        state = true,
    }
    enableTradeUniqueness.visible = false
    styles.applyStyle(enableTradeUniqueness, "toggleButton")
    local enableTradeUniquenessLabel = tradeUniquenessFlow.add{
        type = "label",
        name = "enableTradeUniquenessLabel",
        caption = {"gridtorio-gui.tools-toggle-trade-uniqueness"},
    }
    enableTradeUniquenessLabel.visible = false
    enableTradeUniquenessLabel.tooltip = {"gridtorio-gui.global-tools-tooltip"}
end

function tools.initFreeRoboports(toolsFlow)
    local freeRoboportsFlow = toolsFlow.add{
        type = "flow",
        name = "freeRoboportsFlow",
    }
    local featureLockedFrame = freeRoboportsFlow.add{
        type = "frame",
        name = "featureLockedFrame",
    }
    local featureLockedLabel = featureLockedFrame.add{
        type = "label",
        name = "featureLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(featureLockedLabel, "featureLocked")
    local enableFreeRoboports = freeRoboportsFlow.add{
        type = "checkbox",
        name = "enableFreeRoboports",
        state = true,
    }
    enableFreeRoboports.visible = false
    styles.applyStyle(enableFreeRoboports, "toggleButton")
    local enableFreeRoboportsLabel = freeRoboportsFlow.add{
        type = "label",
        name = "enableFreeRoboportsLabel",
        caption = {"gridtorio-gui.tools-toggle-free-roboports"},
    }
    enableFreeRoboportsLabel.visible = false
    enableFreeRoboportsLabel.tooltip = {"gridtorio-gui.global-tools-tooltip"}
end

function tools.initMarketIOChests(toolsFlow)
    local marketIOChestsFlow = toolsFlow.add{
        type = "flow",
        name = "marketIOChestsFlow",
    }
    local featureLockedFrame = marketIOChestsFlow.add{
        type = "frame",
        name = "featureLockedFrame",
    }
    local featureLockedLabel = featureLockedFrame.add{
        type = "label",
        name = "featureLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(featureLockedLabel, "featureLocked")
    local enableMarketIOChests = marketIOChestsFlow.add{
        type = "checkbox",
        name = "enableMarketIOChests",
        state = true,
    }
    enableMarketIOChests.visible = false
    styles.applyStyle(enableMarketIOChests, "toggleButton")
    local enableMarketIOChestsLabel = marketIOChestsFlow.add{
        type = "label",
        name = "enableMarketIOChestsLabel",
        caption = {"gridtorio-gui.tools-toggle-market-io-chests"},
    }
    enableMarketIOChestsLabel.visible = false
    enableMarketIOChestsLabel.tooltip = {"gridtorio-gui.global-tools-tooltip"}
end

function tools.initInfestedChunks(toolsFlow)
    local infestedChunksFlow = toolsFlow.add{
        type = "flow",
        name = "infestedChunksFlow",
    }
    local featureLockedFrame = infestedChunksFlow.add{
        type = "frame",
        name = "featureLockedFrame",
    }
    local featureLockedLabel = featureLockedFrame.add{
        type = "label",
        name = "featureLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(featureLockedLabel, "featureLocked")
    local enableInfestedChunks = infestedChunksFlow.add{
        type = "checkbox",
        name = "enableInfestedChunks",
        state = true,
    }
    enableInfestedChunks.visible = false
    styles.applyStyle(enableInfestedChunks, "toggleButton")
    local enableInfestedChunksLabel = infestedChunksFlow.add{
        type = "label",
        name = "enableInfestedChunksLabel",
        caption = {"gridtorio-gui.tools-toggle-infested-chunks"},
    }
    enableInfestedChunksLabel.visible = false
    enableInfestedChunksLabel.tooltip = {"gridtorio-gui.global-tools-tooltip"}
end

function tools.initAutomatedChunkUnlocking(toolsFlow)
    local automatedChunkUnlockingFlow = toolsFlow.add{
        type = "flow",
        name = "automatedChunkUnlockingFlow",
    }
    local featureLockedFrame = automatedChunkUnlockingFlow.add{
        type = "frame",
        name = "featureLockedFrame",
    }
    local featureLockedLabel = featureLockedFrame.add{
        type = "label",
        name = "featureLockedLabel",
        caption = {"gridtorio-gui.feature-locked"},
    }
    styles.applyStyle(featureLockedLabel, "featureLocked")
    local enableAutomatedChunkUnlocking = automatedChunkUnlockingFlow.add{
        type = "checkbox",
        name = "enableAutomatedChunkUnlocking",
        state = true,
    }
    enableAutomatedChunkUnlocking.visible = false
    styles.applyStyle(enableAutomatedChunkUnlocking, "toggleButton")
    local enableAutomatedChunkUnlockingLabel = automatedChunkUnlockingFlow.add{
        type = "label",
        name = "enableAutomatedChunkUnlockingLabel",
        caption = {"gridtorio-gui.tools-toggle-automated-chunk-unlocking"},
    }
    enableAutomatedChunkUnlockingLabel.visible = false
    enableAutomatedChunkUnlockingLabel.tooltip = {"gridtorio-gui.personal-tools-tooltip"}
end

function tools.refresh(player)
    local menuTabbedPane = player.gui.screen.menuFrame.menuTabbedPane
    local marketDeletionButton = menuTabbedPane.toolsFlow.marketDeletionFlow.marketDeletionButton
    marketDeletionButton.caption = {"gridtorio-gui.tools-delete-market-button", global.tools.deleteMarketCost}
end

function tools.onButtonClick(player, button, menuTab)
    if menuTab.name ~= "menuTabTools" then return end
    if button.name == "marketDeletionButton" then
        if coinBanks.hasCoins(global.tools.deleteMarketCost, player) then
            local marketGroupStr, marketGroup, closestDist
            for mgStr, mg in pairs(global.boughtMarkets) do
                if mg.market ~= global.starterMarket then
                    if not marketGroup then
                        marketGroupStr = mgStr
                        marketGroup = mg
                        closestDist = util.squareDistance(player.position, mg.market.position)
                    else
                        local dist = util.squareDistance(player.position, mg.market.position)
                        if dist < closestDist then
                            marketGroupStr = mgStr
                            marketGroup = mg
                            closestDist = dist
                        end
                    end
                end
            end
            if marketGroup then
                player.print({"", "[color=yellow]", {"gridtorio-gui.tools-delete-market-confirmation", "[gps=" .. marketGroup.market.position.x .. ", " .. marketGroup.market.position.y .. ",gridtorio]"}, "[.color]"})
                global.tools.marketToDelete[player.name] = marketGroupStr
                button.parent.confirmationFlow.visible = true
            else
                player.print({"", "[color=red]", {"gridtorio-gui.tools-delete-market-no-market"}, "[.color]"})
            end
        else
            player.print({"", "[color=red]", {"gridtorio-gui.tools-delete-market-cannot-afford", global.tools.deleteMarketCost}, "[.color]"})
        end
    elseif button.name == "marketUpgradeButton" then
        local marketGroupStr, marketGroup, closestDist
        for mgStr, mg in pairs(global.boughtMarkets) do
            if not mg.extraIO then
                if not marketGroup then
                    marketGroupStr = mgStr
                    marketGroup = mg
                    closestDist = util.squareDistance(player.position, mg.market.position)
                else
                    local dist = util.squareDistance(player.position, mg.market.position)
                    if dist < closestDist then
                        marketGroupStr = mgStr
                        marketGroup = mg
                        closestDist = dist
                    end
                end
            end
        end
        if marketGroup then
            marketGroup.extraIO = true
            local area = {
                left_top = {
                    x = marketGroup.market.position.x - 2,
                    y = marketGroup.market.position.y - 2,
                },
                right_bottom = {
                    x = marketGroup.market.position.x + 2,
                    y = marketGroup.market.position.y + 2,
                },
            }
            local entities = marketGroup.market.surface.find_entities_filtered{name = {"blue-chest", "red-chest"}, area = area}
            for _, entity in pairs(entities) do
                entity.destroy()
            end
            markets.generateIOChests(marketGroup)
            history.printAndLog(
                util.colorLocalizedString({"gridtorio.notification-upgraded-market", player.name, "[gps=" .. marketGroup.market.position.x .. ", " .. marketGroup.market.position.y .. ",gridtorio]"}, "blue"),
                "markets",
                global.config.notifications["market-upgrade"]
            )
        else
            player.print({"", "[color=red]", {"gridtorio-gui.tools-upgrade-market-no-market"}, "[.color]"})
        end
    elseif button.name == "patchPurificationButton" then
        -- find closest deposit
        local resource = button.parent.patchPurificationResource
        if resource.elem_value then
            local area = {
                left_top = {
                    x = player.position.x - 16,
                    y = player.position.y - 16,
                },
                right_bottom = {
                    x = player.position.x + 16,
                    y = player.position.y + 16,
                },
            }
            local entities = player.surface.find_entities_filtered{name = resource.elem_value, area = area}
            if #entities > 0 then
                local deposit, closestDist, dist
                for _, entity in pairs(entities) do
                    dist = util.squareDistance(player.position, entity.position)
                    if not closestDist or dist < closestDist then
                        closestDist = dist
                        deposit = entity
                    end
                    if dist < 2 then
                        break
                    end
                end
                if deposit then
                    -- find total in chunk
                    local chunkCoords = util.getChunkCoords(deposit.position)
                    local entitiesInChunk = player.surface.find_entities_filtered{type = "resource", area = {
                        left_top = {
                            x = chunkCoords.x * 32 + 1,
                            y = chunkCoords.y * 32 + 1,
                        },
                        right_bottom = {
                            x = chunkCoords.x * 32 + 32,
                            y = chunkCoords.y * 32 + 32,
                        },
                    }}
                    -- should tell the player early that the resource they selected is the most abundant in their closest deposit
                    local distribution = {}
                    local numEntities = 0
                    for _, entity in pairs(entitiesInChunk) do
                        distribution[entity.name] = (distribution[entity.name] or 0) + entity.amount
                        if entity.name == resource.elem_value then
                            numEntities = numEntities + 1
                        end
                    end
                    local mostAbundant = util.argmax(distribution)
                    if resource.elem_value ~= mostAbundant then
                        global.tools.patchPurificationChunk[player.name] = chunkCoords
                        global.tools.patchPurificationCost[player.name] = math.floor(0.5 + numEntities ^ 1.3 * 3)
                        button.parent.confirmationFlow.costLabel.caption = global.tools.patchPurificationCost[player.name] .. "x [item=coin]"
                        button.parent.confirmationFlow.visible = true
                        player.print({"", "[color=yellow]", {"gridtorio-gui.tools-obliviate-resource-confirmation", "[item=" .. resource.elem_value .. "]", "[gps=" .. deposit.position.x .. "," .. deposit.position.y .. "," .. player.surface.name .. "]", global.tools.patchPurificationCost[player.name]}, "[.color]"})
                    else
                        player.print({"", "[color=red]", {"gridtorio-gui.tools-resource-too-abundant"}, "[.color]"})
                    end
                else
                    button.parent.confirmationFlow.visible = false
                    player.print({"", "[color=red]", {"gridtorio-gui.tools-no-deposit"}, "[.color]"})
                end
            else
                button.parent.confirmationFlow.visible = false
                player.print({"", "[color=red]", {"gridtorio-gui.tools-no-deposit", "[item=" .. resource.elem_value .. "]"}, "[.color]"})
            end
        else
            button.parent.confirmationFlow.visible = false
            player.print({"", "[color=red]", {"gridtorio-gui.tools-no-resource-selected"}, "[.color]"})
        end
    elseif button.name == "confirmButton" then
        button.parent.visible = false
        if button.parent.parent.name == "marketDeletionFlow" then
            if coinBanks.hasCoins(global.tools.deleteMarketCost, player) then
                local marketGroupStr = global.tools.marketToDelete[player.name]
                if marketGroupStr then
                    local marketGroup = global.boughtMarkets[marketGroupStr]
                    if marketGroup then
                        for _, trade in pairs(marketGroup.trades) do
                            local str = util.tradeToString(trade)
                            if global.allTradeStrings[str] then
                                global.allTradeStrings[str] = global.allTradeStrings[str] - 1
                                if global.allTradeStrings[str] == 0 then
                                    global.allTradeStrings[str] = nil
                                end
                            end
                        end
                        local area = {
                            left_top = {
                                x = marketGroup.market.position.x - 2,
                                y = marketGroup.market.position.y - 2,
                            },
                            right_bottom = {
                                x = marketGroup.market.position.x + 2,
                                y = marketGroup.market.position.y + 2,
                            },
                        }
                        local chests = marketGroup.market.surface.find_entities_filtered{name = {"blue-chest", "red-chest"}, area = area}
                        for _, chest in pairs(chests) do
                            if not chest.minable then
                                chest.destroy()
                            end
                        end
                        global.boughtMarkets[marketGroupStr] = nil
                        global.tools.marketToDelete[marketGroupStr] = nil
                        for _, p in pairs(game.connected_players) do
                            tradeOverview.refresh(p)
                        end
                        coinBanks.deductCoins(global.tools.deleteMarketCost, player)

                        local tradesStr = "<"
                        for _, trade in pairs(marketGroup.trades) do
                            if tradesStr ~= "<" then
                                tradesStr = tradesStr .. " | "
                            end
                            tradesStr = tradesStr .. "[item=" .. trade.itemToGive .. "]" .. trade.amountToGive .. " → " .. trade.amountToReceive .. "[item=".. trade.itemToReceive .. "]"
                        end
                        tradesStr = tradesStr.. ">"

                        history.printAndLog(
                            util.colorLocalizedString(
                                {
                                    "gridtorio.market-deleted",
                                    player.name,
                                    "[gps=" .. marketGroup.market.position.x .. "," .. marketGroup.market.position.y .. ",gridtorio]",
                                    tradesStr,
                                },
                                "yellow"
                            ),
                            "markets",
                            global.config.notifications["deleted-market"]
                        )

                        marketGroup.market.destroy()
                    end
                end
            else
                player.print({"gridtorio-gui.tools-delete-market-cannot-afford", global.tools.deleteMarketCost})
            end
        elseif button.parent.parent.name == "patchPurificationFlow" then
            local resource = button.parent.parent.patchPurificationResource.elem_value
            if resource then
                if coinBanks.hasCoins(global.tools.patchPurificationCost[player.name], player) then
                    local chunkCoords = global.tools.patchPurificationChunk[player.name]
                    if chunkCoords then
                        local area = {
                            left_top = {
                                x = chunkCoords.x * 32 + 1,
                                y = chunkCoords.y * 32 + 1,
                            },
                            right_bottom = {
                                x = chunkCoords.x * 32 + 32,
                                y = chunkCoords.y * 32 + 32,
                            },
                        }
                        local entities = player.surface.find_entities_filtered{type = "resource", area = area}
                        -- Check for most abundant
                        local dist = {}
                        for _, entity in pairs(entities) do
                            dist[entity.name] = (dist[entity.name] or 0) + entity.amount
                        end
                        local mostAbundant = util.argmax(dist)
                        if resource ~= mostAbundant then
                            local tx, ty
                            for _, entity in pairs(entities) do
                                if entity.name == resource then
                                    player.surface.create_entity{
                                        name = mostAbundant,
                                        position = entity.position,
                                        amount = entity.amount,
                                    }
                                    tx = entity.position.x
                                    ty = entity.position.y
                                    entity.destroy()
                                end
                            end
                            coinBanks.deductCoins(global.tools.patchPurificationCost[player.name], player)
                            global.tools.patchPurificationChunk[player.name] = nil
                            global.tools.patchPurificationCost[player.name] = nil
                            button.parent.parent.patchPurificationResource.elem_value = nil
                            history.printAndLog(
                                util.colorLocalizedString({
                                    "gridtorio.patch-purified",
                                    player.name,
                                    "[gps=" .. tx.. ",".. ty.. ",gridtorio]",
                                    "[item=" .. mostAbundant .. "]",
                                }, "green"),
                                "purifiedPatches",
                                global.config.notifications["patch-purified"]
                            )
                        else
                            player.print({"", "[color=red]", {"gridtorio-gui.tools-resource-too-abundant"}, "[.color]"})
                        end
                    end
                else
                    player.print({"", "[color=red]", {"gridtorio-gui.tools-cannot-afford-obliviation", "[item=" .. resource .. "]", global.tools.patchPurificationCost[player.name]}, "[.color]"})
                end
            else
                player.print({"", "[color=red]", {"gridtorio-gui.tools-no-resource-selected"}, "[.color]"})
            end
        end
    elseif button.name == "toggleMarketAsBankButton" then
        local marketGroup, redChest, closestDist
        for _, mg in pairs(global.boughtMarkets) do
            for _, inv in pairs(markets.getRedInventories(mg, false)) do
                local chest = inv.entity_owner
                if chest then
                    if not marketGroup then
                        marketGroup = mg
                        redChest = chest
                        closestDist = util.squareDistance(player.position, chest.position)
                    else
                        local dist = util.squareDistance(player.position, chest.position)
                        if dist < closestDist then
                            marketGroup = mg
                            redChest = chest
                            closestDist = dist
                        end
                    end
                end
            end
        end
        if marketGroup then
            local flag = markets.toggleMarketBank(marketGroup, redChest)
            local str = "gridtorio.market-bank-enabled"
            if not flag then
                str = "gridtorio.market-bank-disabled"
            end
            history.printAndLog(
                util.colorLocalizedString(
                    {
                        str,
                        player.name,
                        "[gps=".. redChest.position.x.. ",".. redChest.position.y.. ",gridtorio]",
                    },
                    "green"
                ),
                "markets",
                global.config.notifications["market-bank-toggled"]
            )
        end
    elseif button.name == "cancelButton" then
        button.parent.visible = false
        local marketGroupStr = global.tools.marketToDelete[player.name]
        if marketGroupStr then
            global.tools.marketToDelete[marketGroupStr] = nil
        end
    end
end



return tools
