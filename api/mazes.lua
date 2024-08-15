
local mazes = {}



function mazes.getMazeValue(maze, x, y, reflect, rotate)
    local relPos = mazes.worldToRelative(maze, x, y, reflect, rotate)
    if relPos.x < 0 or relPos.x >= maze.size.w or relPos.y < 0 or relPos.y >= maze.size.h then
        return 1
    end
    local index = relPos.y * maze.size.w + relPos.x
    return maze.grid[index + 1] -- Lua sucks
end

function mazes.worldToRelative(maze, x, y, reflect, rotate)
    if reflect then
        x = -x
    end
    if rotate then
        if rotate == 1 then
            local _x = x
            x = y
            y = -_x
        elseif rotate == 2 then
            x = -x
            y = -y
        elseif rotate == 3 then
            local _x = x
            x = -y
            y = _x
        end
    end
    return {x = x + (maze.size.w + 1) / 2, y = y + (maze.size.h + 1) / 2}
end

function mazes.relativeToWorld(maze, rx, ry, reflect, rotate)
    local x = rx - (maze.size.w + 1) / 2
    local y = ry - (maze.size.h + 1) / 2
    if rotate then
        if rotate == 1 then
            local _x = x
            x = -y
            y = _x
        elseif rotate == 2 then
            x = -x
            y = -y
        elseif rotate == 3 then
            local _x = x
            x = y
            y = -_x
        end
    end
    if reflect then
        x = -x
    end
    return {x = x, y = y}
end



return mazes
