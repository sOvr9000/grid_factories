
local settingsGUI = require "api/settingsGUI"



function setupNauvis()
    for _, player in pairs(game.connected_players) do
        settingsGUI.initPlayer(player)
    end
end


