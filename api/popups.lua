
local popups = {}



function popups.show(player, text, title)
    if popups.isOpen(player) then return end

    local frame = player.gui.screen.add{
        type = "frame",
        name = "popupFrame",
        direction = "vertical",
        style = "frame",
        caption = title or "Popup",
    }
    frame.style.size = {500, 300}
    frame.style.left_padding = 25
    frame.style.right_padding = 25

    local content = frame.add{type = "text-box", name = "content", text = text}
    -- content.style.single_line = false
    content.style.natural_width = 450
    content.style.minimal_width = 450
    content.style.horizontally_stretchable = true
    content.style.vertically_stretchable = true

    player.opened = frame

    frame.force_auto_center()
    return frame
end

function popups.close(player)
    if player.gui.screen.popupFrame then
        player.gui.screen.popupFrame.destroy()
    end
end

function popups.isOpen(player)
    return player.gui.screen.popupFrame ~= nil
end



return popups
