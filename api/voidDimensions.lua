
local voidDimensions = {}



function voidDimensions.initPlayer(player)
    local conquestBar = player.gui.center.add{
        type = "progressbar",
        name = "conquestBar",
    }
    conquestBar.style.color = global.colors.red
    conquestBar.style.relative = {}
end



return voidDimensions
