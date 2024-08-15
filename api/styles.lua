
local styles = {}



function styles.applyStyle(element, style)
    if type(style) == "string" then
        style = global.styles[style]
    end
    for k, v in pairs(style) do
        element.style[k] = v
    end
end



return styles
