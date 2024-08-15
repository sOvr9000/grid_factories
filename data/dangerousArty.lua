
-- WIP addon

local dangerousArty = {
    -- Any ruins chunk that has a loaded artillery turret will periodically shoot any of your built entities within range, including power poles, belts, and mining drills.
    enabled = false,

    -- Measured in seconds.  The time between each shot by enemy artillery.
    fireInterval = 60,
}

if dangerousArty.enabled then
    log("Addon \"dangerousArty\" is enabled.")
end

return dangerousArty
