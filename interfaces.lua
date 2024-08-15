
local api = {}

for _, apiName in pairs{
    "acu",
    "areaDiscovery",
    "chunks",
    "gutil",
    "history",
    "itemValues",
    "markets",
    "mazes",
    "menu",
    "newGridtorio",
    "players",
    "settingsGUI",
    "stats",
    "styles",
    "surfaceGen",
    "teleporters",
    "tools",
    "tradeOverview",
    "upgrades",
    "voidDimensions",
} do
    api[apiName] = require("api/" .. apiName)
end

for apiName, apiFuncs in pairs(api) do
    local interface = {}
    for funcName, func in pairs(apiFuncs) do
        interface[funcName] = func
    end
    remote.add_interface("gridtorio-" .. apiName, interface)
end
-- remote.add_interface("gridtorio-gutil", {isGameReady = gutil.isGameReady})
-- remote.add_interface("gridtorio-itemValues", {getItemValue = itemValues.getItemValue, isReady = itemValues.isReady, isDefined = itemValues.isDefined})
-- remote.add_interface("gridtorio-markets", {getMarketTradeAmounts = markets.getMarketTradeAmounts, addMarketOffer = markets.addMarketOffer})


