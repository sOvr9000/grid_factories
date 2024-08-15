
local util = require "api/gutil"
local styles = require "api/styles"
local history = require "api/history"

local upgrades = {}



function upgrades.init(player)
    global.upgrades.viewedUpgrade[player.name] = "tradeOverview"
    global.upgrades.enabledUpgrades[player.name] = {}

    for _, upgrade in pairs(global.upgrades.upgradeTree) do
        global.upgrades.upgradeTreeIndexed[upgrade.name] = upgrade
        global.upgrades.upgradeTreeIndexed[util.positionToString(upgrade.position)] = upgrade
        if upgrade.sprite then
            global.upgrades.upgradeTreeIndexed[upgrade.sprite] = upgrade
        end
    end

    local menuTabbedPane = player.gui.screen.menuFrame.menuTabbedPane

    local menuTabUpgrades = menuTabbedPane.add{
        type = "tab",
        caption = {"gridtorio-gui.menu-tab-upgrades"},
        name = "menuTabUpgrades",
    }
    local upgradesFlow = menuTabbedPane.add{
        type = "flow",
        name = "upgradesFlow",
        direction = "vertical",
    }
    upgradesFlow.style.vertically_stretchable = true
    -- upgradesFlow.style.maximal_height = 560
    local panelsFlow = upgradesFlow.add{
        type = "flow",
        name = "panelsFlow",
    }

    upgrades.generateTreeFrame(panelsFlow)
    upgrades.generateInspectFrame(panelsFlow)

    menuTabbedPane.add_tab(menuTabUpgrades, upgradesFlow)
    global.menuTabs[upgradesFlow.name] = menuTabUpgrades

    upgrades.refresh(player)
end

function upgrades.generateTreeFrame(panelsFlow)
    local minx, miny, maxx, maxy = util.getBoundingBox(global.upgrades.upgradeTree, function(k, v) return v.position end)
    local treeWidth = maxx - minx + 1
    local treeHeight = maxy - miny + 1

    local treeFrame = panelsFlow.add{
        type = "frame",
        name = "treeFrame",
    }
    treeFrame.style.natural_width = 196
    treeFrame.style.natural_height = 196
    styles.applyStyle(treeFrame, "upgradeTreeBackground")
    local treeTable = treeFrame.add{
        type = "table",
        name = "treeTable",
        column_count = treeWidth,
    }

    for y = treeHeight, 1, -1 do
        for x = 1, treeWidth do
            -- local relativePos = {x = x, y = y}
            local pos = {x = x + minx - 1, y = y + miny - 1}
            local posStr = util.positionToString(pos)
            local upgrade = global.upgrades.upgradeTreeIndexed[posStr]
            local upgradeFrame = treeTable.add{
                type = "flow",
                name = posStr,
            }
            styles.applyStyle(upgradeFrame, "upgradeBackgroundSlot")
            if upgrade and not upgrade.prerequisite then
                upgrades.generateUpgradeButton(upgradeFrame, upgrade)
            end
        end
    end

end

function upgrades.generateInspectFrame(panelsFlow)
    local inspectFrame = panelsFlow.add{
        type = "frame",
        name = "inspectFrame",
        direction = "vertical",
    }
    inspectFrame.style.maximal_width = 320
    local inspectTopFlow = inspectFrame.add{
        type = "flow",
        name = "inspectTopFlow",
    }
    local inspectTitle = inspectTopFlow.add{
        type = "label",
        name = "inspectTitle",
    }
    inspectTitle.style.font = "heading-1"
    inspectTitle.style.single_line = false
    local unlockButton = inspectTopFlow.add{
        type = "button",
        name = "unlockButton",
        caption = {"gridtorio-gui.upgrades-unlock"},
        style = "confirm_button_without_tooltip",
    }
    local inspectDescription = inspectFrame.add{
        type = "label",
        name = "inspectDescription",
    }
    -- inspectDescription.style.maximal_width = 212
    inspectDescription.style.single_line = false
    local isToggleable = inspectFrame.add{
        type = "label",
        name = "isToggleable",
        caption = {"gridtorio-gui.upgrades-can-be-toggled"},
    }
    isToggleable.style.font_color = global.colors.yellow -- "yellow"
    local inspectLine = inspectFrame.add{
        type = "line",
        name = "inspectLine",
    }
    local inspectRequirementFlow = inspectFrame.add{
        type = "flow",
        name = "inspectRequirementFlow",
    }
    local inspectRequirementCheck = inspectRequirementFlow.add{
        type = "label",
        name = "inspectRequirementCheck",
    }
    -- styles.applyStyle(inspectRequirementCheck, styles.inspectRequirementCheck)
    local inspectRequirement = inspectRequirementFlow.add{
        type = "label",
        name = "inspectRequirement",
    }
    inspectRequirement.style.single_line = false
    local inspectProgress = inspectFrame.add{
        type = "progressbar",
        name = "inspectProgress",
    }
    inspectProgress.style.natural_width = 260
    inspectProgress.style.color = global.colors.orange
end

function upgrades.generateUpgradeButton(upgradeFrame, upgrade)
    if upgradeFrame.upgradeButton then return end
    if upgrade.wip then return end
    local upgradeButton = upgradeFrame.add{
        type = "sprite-button",
        name = "upgradeButton",
        sprite = upgrade.sprite,
    }
    styles.applyStyle(upgradeButton, "upgradeButton")
end

function upgrades.decrementBuiltEntityCount(name)
    if global.upgrades.builtEntities[name] then
        global.upgrades.builtEntities[name] = math.max(0, global.upgrades.builtEntities[name] - 1)
    end
    for _, player in pairs(game.connected_players) do
        upgrades.refresh(player)
    end
end

function upgrades.incrementBuiltEntityCount(name)
    if global.upgrades.builtEntities[name] then
        global.upgrades.builtEntities[name] = global.upgrades.builtEntities[name] + 1
    end
    for _, player in pairs(game.connected_players) do
        upgrades.refresh(player)
    end
end

function upgrades.incrementScore(key)
    if global.upgrades[key] then
        global.upgrades[key] = global.upgrades[key] + 1
        for _, player in pairs(game.connected_players) do
            upgrades.refresh(player)
        end
        upgrades.onScoreChanged(key)
    end
end

function upgrades.countAvailableMarkets()
    local s = -1 -- don't count the starting market, which always exists
    for _, _ in pairs(global.boughtMarkets) do
        s = s + 1
    end
    return s
end

function upgrades.countBoughtChunks()
    -- local s = -1 -- you didn't buy the spawn chunk you loser
    -- for _, _ in pairs(global.boughtChunks) do
    --     s = s + 1
    -- end
    -- return s
    return global.totalBoughtChunks
end

function upgrades.onUpgradeUnlocked(player, upgrade, unlockedBy)
    -- player unlocked upgrade of name "name", but the upgrade effect is universal
    -- player.print("unlocked upgrade " .. upgrade.name)

    if unlockedBy then
        history.printAndLog(
            util.colorLocalizedString(
                {"gridtorio.notification-upgrade-unlock", unlockedBy.name, {"gridtorio-upgrades." .. util.hyphenateName(upgrade.name) .. "-title"}},
                "blue"
            ),
            "upgradesUnlocked",
            global.config.notifications["upgrade-unlock"]
        )
    end

    local menuTabbedPane = player.gui.screen.menuFrame.menuTabbedPane

    for _, upg in pairs(global.upgrades.upgradeTree) do
        if upg.prerequisite == upgrade.name then
            upgrades.generateUpgradeButton(menuTabbedPane.upgradesFlow.panelsFlow.treeFrame.treeTable[util.positionToString(upg.position)], upg)
        end
    end

    if upgrade.name == "tradeOverview" then
        menuTabbedPane.menuTabTradeOverview.enabled = true
        menuTabbedPane.menuTabTradeOverview.caption = {"gridtorio-gui.menu-tab-trade-overview"}
    elseif upgrade.name == "marketDeletion" then
        menuTabbedPane.menuTabTools.enabled = true
        menuTabbedPane.menuTabTools.caption = {"gridtorio-gui.menu-tab-tools"}
        menuTabbedPane.toolsFlow.visible = true
        menuTabbedPane.toolsFlow.marketDeletionFlow.featureLockedFrame.visible = false
        menuTabbedPane.toolsFlow.marketDeletionFlow.marketDeletionButton.visible = true
    elseif upgrade.name == "tradeOverviewQuality" then
        menuTabbedPane.TOFlow.TOTopFlow.extraFrame.enableQualityLocked.visible = false
        menuTabbedPane.TOFlow.TOTopFlow.extraFrame.qualityFlow.visible = true
    elseif upgrade.name == "patchPurification" then
        menuTabbedPane.toolsFlow.patchPurificationLockedFrame.visible = false
        menuTabbedPane.toolsFlow.patchPurificationFlow.visible = true
    elseif upgrade.name == "tradeOverviewFilter" then
        menuTabbedPane.TOFlow.TOTopFlow.tradeFilterFrame.tradeFilterLocked.visible = false
        menuTabbedPane.TOFlow.TOTopFlow.tradeFilterFrame.tradeFilter.visible = true
        menuTabbedPane.TOFlow.TOTopFlow.tradeFilterFrame.tradeFilterFlow.visible = true
    elseif upgrade.name == "marketRng" then
        menuTabbedPane.toolsFlow.marketRNGFlow.featureLockedFrame.visible = false
        menuTabbedPane.toolsFlow.marketRNGFlow.enableMarketRNG.visible = true
        menuTabbedPane.toolsFlow.marketRNGFlow.enableMarketRNGLabel.visible = true
        menuTabbedPane.toolsFlow.marketRNGFlow.enableMarketRNG.state = global.upgrades.globallyEnabledUpgrades.marketRng
    elseif upgrade.name == "tradeUniqueness" then
        menuTabbedPane.toolsFlow.tradeUniquenessFlow.featureLockedFrame.visible = false
        menuTabbedPane.toolsFlow.tradeUniquenessFlow.enableTradeUniqueness.visible = true
        menuTabbedPane.toolsFlow.tradeUniquenessFlow.enableTradeUniquenessLabel.visible = true
        menuTabbedPane.toolsFlow.tradeUniquenessFlow.enableTradeUniqueness.state = global.upgrades.globallyEnabledUpgrades.tradeUniqueness
    elseif upgrade.name == "freeRoboports" then
        menuTabbedPane.toolsFlow.freeRoboportsFlow.featureLockedFrame.visible = false
        menuTabbedPane.toolsFlow.freeRoboportsFlow.enableFreeRoboports.visible = true
        menuTabbedPane.toolsFlow.freeRoboportsFlow.enableFreeRoboportsLabel.visible = true
        menuTabbedPane.toolsFlow.freeRoboportsFlow.enableFreeRoboports.state = global.upgrades.globallyEnabledUpgrades.freeRoboports
    elseif upgrade.name == "marketIoChests" then
        menuTabbedPane.toolsFlow.marketIOChestsFlow.featureLockedFrame.visible = false
        menuTabbedPane.toolsFlow.marketIOChestsFlow.enableMarketIOChests.visible = true
        menuTabbedPane.toolsFlow.marketIOChestsFlow.enableMarketIOChestsLabel.visible = true
        menuTabbedPane.toolsFlow.marketIOChestsFlow.enableMarketIOChests.state = global.upgrades.globallyEnabledUpgrades.marketIoChests
        menuTabbedPane.toolsFlow.marketUpgradeFlow.featureLockedFrame.visible = false
        menuTabbedPane.toolsFlow.marketUpgradeFlow.marketUpgradeButton.visible = true
    elseif upgrade.name == "automatedChunkUnlocking" then
        menuTabbedPane.menuTabTools.enabled = true
        menuTabbedPane.menuTabTools.caption = {"gridtorio-gui.menu-tab-tools"}
        menuTabbedPane.toolsFlow.visible = true
        menuTabbedPane.toolsFlow.automatedChunkUnlockingFlow.featureLockedFrame.visible = false
        menuTabbedPane.toolsFlow.automatedChunkUnlockingFlow.enableAutomatedChunkUnlocking.visible = true
        menuTabbedPane.toolsFlow.automatedChunkUnlockingFlow.enableAutomatedChunkUnlockingLabel.visible = true
    elseif upgrade.name == "dimensionalChunks" then
        menuTabbedPane.statsFlow.featureLockedFrame.visible = false
        menuTabbedPane.statsFlow.voidDimensionsFlow.visible = true
    elseif upgrade.name == "noMoreInfestedChunks" then
        menuTabbedPane.toolsFlow.infestedChunksFlow.featureLockedFrame.visible = false
        menuTabbedPane.toolsFlow.infestedChunksFlow.enableInfestedChunks.visible = true
        menuTabbedPane.toolsFlow.infestedChunksFlow.enableInfestedChunksLabel.visible = true
        menuTabbedPane.toolsFlow.infestedChunksFlow.enableInfestedChunks.state = global.upgrades.globallyEnabledUpgrades.noMoreInfestedChunks
    end
end

function upgrades.giveNewPlayerCurrentUpgrades(player)
    for upgradeName, unlocked in pairs(global.upgrades.unlocked) do
        if unlocked then
            local upgrade = global.upgrades.upgradeTreeIndexed[upgradeName]
            upgrades.onUpgradeUnlocked(player, upgrade, nil)
        end
    end
end

function upgrades.onButtonClick(player, button, menuTab)
    if menuTab.name ~= "menuTabUpgrades" then return end
    if button.name == "upgradeButton" then
        local upgrade = global.upgrades.upgradeTreeIndexed[button.parent.name]
        if upgrade then
            global.upgrades.viewedUpgrade[player.name] = upgrade.name
            upgrades.refresh(player)
        end
    elseif button.name == "unlockButton" then
        local upgrade = global.upgrades.upgradeTreeIndexed[global.upgrades.viewedUpgrade[player.name]]
        if upgrade then
            local inspectProgress = button.parent.parent.inspectProgress
            if inspectProgress.value == 1 or global.freeUnlocks then
                global.upgrades.unlocked[upgrade.name] = true
                for _, p in pairs(game.connected_players) do
                    if upgrade.canToggle then
                        if upgrade.isGlobalToggle then
                            global.upgrades.globallyEnabledUpgrades[upgrade.name] = true
                        else
                            global.upgrades.enabledUpgrades[p.name][upgrade.name] = true
                        end
                    end
                    upgrades.onUpgradeUnlocked(p, upgrade, player)
                    upgrades.refresh(p)
                end
            else
                player.print({"", "[color=red]", {"gridtorio-gui.upgrade-requirement-not-met"}, "[.color]"})
            end
        end
    end
end

function upgrades.refresh(player)
    local menuTabbedPane = player.gui.screen.menuFrame.menuTabbedPane
    local upgradesFlow = menuTabbedPane.upgradesFlow
    local panelsFlow = upgradesFlow.panelsFlow
    local inspectFrame = panelsFlow.inspectFrame

    local upgrade = global.upgrades.upgradeTreeIndexed[global.upgrades.viewedUpgrade[player.name]]

    local inspectTitle = inspectFrame.inspectTopFlow.inspectTitle
    local unlockButton = inspectFrame.inspectTopFlow.unlockButton
    local inspectDescription = inspectFrame.inspectDescription
    local inspectRequirement = inspectFrame.inspectRequirementFlow.inspectRequirement
    local inspectRequirementCheck = inspectFrame.inspectRequirementFlow.inspectRequirementCheck
    local inspectProgress = inspectFrame.inspectProgress
    local isToggleable = inspectFrame.isToggleable

    local requirementParams = upgrades.getRequirementsParameters(upgrade.requirement)

    inspectTitle.caption = {"gridtorio-upgrades." .. util.hyphenateName(upgrade.name) .. "-title"}
    inspectDescription.caption = {"gridtorio-upgrades." .. util.hyphenateName(upgrade.name) .. "-effect"}
    inspectRequirement.caption = {"upgrade-requirements." .. util.hyphenateName(upgrade.requirement.type), table.unpack(requirementParams)}

    isToggleable.visible = upgrade.canToggle

    if global.upgrades.unlocked[upgrade.name] then
        unlockButton.caption = {"gridtorio-gui.upgrades-unlocked"}
        unlockButton.enabled = false
        inspectProgress.visible = false
        inspectRequirement.tooltip = ""
        inspectRequirementCheck.visible = true
        inspectRequirementCheck.caption = "[virtual-signal=signal-check]"
        styles.applyStyle(inspectRequirement, "inspectRequirementComplete")
    else
        unlockButton.caption = {"gridtorio-gui.upgrades-unlock"}
        unlockButton.enabled = true
        local prog = upgrades.getRequirementProgress(upgrade)
        if prog then
            inspectProgress.value = prog
            if upgrade.requirement.value then
                local current = math.floor(0.5 + inspectProgress.value * upgrade.requirement.value)
                inspectProgress.visible = true
                inspectProgress.tooltip = current .. " / " .. upgrade.requirement.value
                inspectRequirement.tooltip = inspectProgress.tooltip
            else
                inspectProgress.visible = false
                inspectProgress.tooltip = ""
                inspectRequirement.tooltip = ""
            end
        else
            log("No progress calculated for " .. upgrade.name)
        end
        inspectRequirementCheck.visible = false
        styles.applyStyle(inspectRequirement, "inspectRequirementIncomplete")
    end
end

function upgrades.getRequirementsParameters(requirement)
    if requirement.type == "buildEntity" then
        return {requirement.value, "[entity=" .. requirement.entity .. "]"}
    elseif requirement.type == "discoverArea" then
        return {{"area-discovery." .. util.hyphenateName(requirement.area)}}
    else
        return {requirement.value}
    end
end

function upgrades.getRequirementProgress(upgrade)
    local v
    if upgrade.requirement.type == "buildEntity" then
        v = global.upgrades.builtEntities[upgrade.requirement.entity]
    elseif upgrade.requirement.type == "killSpawners" then
        v = global.upgrades.killedSpawners
    elseif upgrade.requirement.type == "deleteMarkets" then
        v = global.upgrades.deletedMarkets
    elseif upgrade.requirement.type == "automatedTrades" then
        v = global.upgrades.automatedTrades
    elseif upgrade.requirement.type == "oversupplyBlueChests" then
        v = global.upgrades.oversuppliedBlueChests
    elseif upgrade.requirement.type == "ramBiters" then
        v = global.upgrades.rammedBiters
    elseif upgrade.requirement.type == "depleteResources" then
        v = global.upgrades.depletedResources
    elseif upgrade.requirement.type == "discoverArea" then
        if global.areaDiscovery.discovered[upgrade.requirement.area] then
            return 1
        end
        return 0
    elseif upgrade.requirement.type == "availableMarkets" then
        v = upgrades.countAvailableMarkets()
    elseif upgrade.requirement.type == "unlockChunks" then
        v = upgrades.countBoughtChunks()
    end
    if v then
        return math.max(0, math.min(1, v / upgrade.requirement.value))
    end
    log("no progress found")
end

function upgrades.isUpgradeEnabled(upgradeName, player)
    if not upgrades.isUpgradeUnlocked(upgradeName) then
        return false
    end
    if not player then
        return global.upgrades.globallyEnabledUpgrades[upgradeName] == true
    end
    return global.upgrades.enabledUpgrades[player.name][upgradeName] == true
end

function upgrades.isUpgradeUnlocked(upgradeName)
    return global.upgrades.unlocked[upgradeName] == true
end

function upgrades.onScoreChanged(key)
    -- if key == "depletedResources" then
    --     local prog = global.upgrades.depletedResources / global.config.requiredDepletedResourcesForRVCC
    --     -- global.config.voidChunkMaxChance = global.config.upgradedVoidChunkMaxChance + (global.config.voidChunkMaxChance - global.config.upgradedVoidChunkMaxChance) * prog
    --     global.upgradedVoidChunkMaxChance = util.lerp(global.config.voidChunkMaxChance, global.config.upgradedVoidChunkMaxChance, prog)
    -- end
end



return upgrades
