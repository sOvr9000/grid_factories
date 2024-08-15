
local colors = require "data/colors"

return {
    joinDiscord = {
        font_color = colors.purple,
        single_line = false,
    },
    upgradeBackgroundSlot = {
        natural_width = 40,
        natural_height = 40,
        padding = 0,
        margin = 0,
    },
    upgradeButton = {
        -- size = {40, 40},
        -- padding = 0,
    },
    upgradeTreeBackground = {
        
    },
    inspectRequirementComplete = {
        font_color = colors.lightGreen,
    },
    inspectRequirementIncomplete = {
        font_color = colors.lightRed,
    },
    featureLocked = {
        font_color = colors.gray,
    },
    patchPurificationButton = {
        top_margin = 5,
    },
    patchPurificationCost = {
        font = "heading-1",
        top_padding = 4,
    },
    toggleButton = {
        top_margin = 3,
    },
    header = {
        font = "heading-1",
    },
    smallHeader = {
        font = "heading-2",
    },
    settingsFrame = {
        natural_width = 1200,
        natural_height = 800,
        maximal_width = 1200,
        maximal_height = 800,
    },
}
