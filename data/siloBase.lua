
-- WIP addon

local siloBase = {
    -- Your base is a rocket silo.  If biters destroy it, the run ends and a new one begins.
    enabled = false,
}

if siloBase.enabled then
    log("Addon \"siloBase\" is enabled.")
end

return siloBase
