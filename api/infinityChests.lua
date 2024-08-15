

local infinityChests = {}



function infinityChests.spawn(surface, position, items)
    items = items or {global.config.initialInfinityLoot}
    if type(items) == "string" then
        items = {items}
    end

    local chest = surface.create_entity{name = "infinity-chest", position = position, force = "enemy"}

    for i, item in pairs(items) do
        chest.set_infinity_container_filter(i, {
            name = item,
            count = 100,
            mode = "exactly",
        })
    end
    chest.minable = false
    chest.destructible = false

    local positions = {
        {chest.position.x-1.5,chest.position.y},
        {chest.position.x,chest.position.y+1.5},
        {chest.position.x+1.5,chest.position.y},
        {chest.position.x,chest.position.y-1.5},
    }
    for d, _pos in pairs(positions) do
        local loader = surface.create_entity{name = "express-loader", position = _pos, force = "enemy", direction = (4 - 2 * d) % 8}
        loader.destructible = false
        loader.minable = false
        loader.loader_type = "output"
    end
end



return infinityChests
