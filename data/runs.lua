
-- WIP addon

local runs = {
    -- When the game ends in any way, a new one begins, starting a new run.
    enabled = false,

    -- Measured in seconds.  The time it takes for a new game to start after the current one has ended.
    restartTime = 15,

    nextGameTick = -1,
}

if runs.enabled then
    log("Addon \"runs\" is enabled.")
end

return runs
