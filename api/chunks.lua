
local util = require "api/gutil"
local acu = require "api/acu"
local upgrades = require "api/upgrades"
local tools = require "api/tools"
local markets = require "api/markets"
local stats = require "api/stats"
local mazes = require "api/mazes"
local surfaceGen = require "api/surfaceGen"
local teleporters = require "api/teleporters"
local coinBanks = require "api/coinBanks"
local players = require "api/players"
local history = require "api/history"

local chunks = {}



function chunks.onChunkBought(player, surface, chunkCoords, direction)
    local newChunkCoords
    if direction == -1 then
        newChunkCoords = chunkCoords
    else
        newChunkCoords = util.offsetPosition(chunkCoords, direction)
    end

    local posStr = util.positionToString(newChunkCoords)

    -- Remove jutting walls, which extend between two bought chunks.
    local lower = 3
    if direction == -1 then
        lower = 2
    end
    for dir = lower, 5 do
        local d = (direction + dir) % 4
        local neighborChunk = util.offsetPosition(newChunkCoords, d)
        if global.boughtChunks[util.positionToString(neighborChunk)] then
            chunks.deleteWall(surface, newChunkCoords, d)
        end
    end

    -- Place exploredTile
    if global.config.exploredTile and global.config.exploredTile ~= "" then
        local ignoreVoid = global.dimensionalChunks[posStr] ~= nil
        if ignoreVoid then
            util.setTiles(surface, newChunkCoords, global.config.unexploredTile, true, false, true)
        end
        util.setTiles(surface, newChunkCoords, global.config.exploredTile, false, true, ignoreVoid)
    end

    -- Check for market
    local area = {
        left_top = {
            x = (newChunkCoords.x or newChunkCoords[1]) * 32,
            y = (newChunkCoords.y or newChunkCoords[2]) * 32,
        },
        right_bottom = {
            x = (newChunkCoords.x or newChunkCoords[1]) * 32 + 31,
            y = (newChunkCoords.y or newChunkCoords[2]) * 32 + 31,
        },
    }
    local entities = surface.find_entities_filtered{area = area, name = "market"}
    if #entities == 1 then
        local market = entities[1]
        markets.initMarket(market, global.superChunks[util.positionToString(newChunkCoords)])
    end

    if player then
        global.chunksUnlockedBy[player.name] = (global.chunksUnlockedBy[player.name] or 0) + 1
    end

    for _, p in pairs(game.connected_players) do
        upgrades.refresh(p)
    end

    -- Test for infestation
    if util.canChunkGetInfested(chunkCoords) then
        if not upgrades.isUpgradeEnabled "noMoreInfestedChunks" then
            if not global.ruinsChunks[posStr] then
                if math.random() < global.config.infestedChunkChance then
                    local s = {"biter-spawner", "spitter-spawner"}
                    local any = false
                    for i = 1, math.random(3, 8) do
                        local spawnerType = s[i%2+1]
                        local pos = surface.find_non_colliding_position_in_box(
                            spawnerType,
                            {
                                left_top = {x = newChunkCoords.x * 32, y = newChunkCoords.y * 32},
                                right_bottom = {x = newChunkCoords.x * 32 + 32, y = newChunkCoords.y * 32 + 32},
                            },
                            1
                        )
                        if pos then
                            local spawner = surface.create_entity{
                                name = spawnerType,
                                position = pos,
                            }
                            spawner.destructible = false
                            any = true
                        end
                    end
                    if any then
                        global.infestedChunks[posStr] = {chunkCoords = newChunkCoords}
                        game.print{"", "[color=yellow]", {"gridtorio.chunk-infested", "[gps=" .. (newChunkCoords.x * 32 + 16) .. ", " .. (newChunkCoords.y * 32 + 16) .. ",gridtorio]"}, "[.color]"}
                    end
                end
            end
        end
    end

    global.totalBoughtChunks = global.totalBoughtChunks + 1
    acu.updateAutoUnlockableChunks(newChunkCoords)

    if player then
        stats.refreshPersonal(player)
    end

    players.refreshGridtorioGUIs()

    -- if global.dimensionalChunks[posStr] then
    --     chunks.checkDimensionalChunkPurchase(player, chunkCoords)
    -- end
end

function chunks.onDimensionalChunkBought(player, chunkCoords, newChunkCoords)
    local mazeIndex = util.reservoirSample(global.mazes.predefined, function(_, maze)
        return maze.size.w == 15 and maze.size.h == 15
    end)
    if not mazeIndex then
        log("ERROR: No maze found for dimensional chunk purchase")
        return
    end
    local maze = global.mazes.predefined[mazeIndex]

    local reflect = math.random() < 0.5
    local rotate = math.random(0, 3)
    local tiles = {}
    for y = -14, 13 do
        for x = -14, 13 do
            local pos = {x = newChunkCoords.x * 32 + 17 + x, y = newChunkCoords.y * 32 + 17 + y}
            local mx = math.floor(x / 2)
            local my = math.floor(y / 2)
            if mazes.getMazeValue(maze, mx, my, reflect, rotate) == 1 then
                table.insert(tiles, {name = "out-of-map", position = pos})
            end
        end
    end

    game.surfaces.gridtorio.set_tiles(tiles)

    local dchunk = global.dimensionalChunks[util.positionToString(newChunkCoords)]
    if dchunk then
        dchunk.surfaceName = "void-" .. global.totalVoidDimensions
        local cfg = global.config.voidDimensionBiters[dchunk.satLevel]
        mazeIndex = util.reservoirSample(global.mazes.predefined, function(_, m)
            return m.size.w == 13 and m.size.h == 13
        end)
        if not mazeIndex then
            log("ERROR: No maze found for dimensional chunk purchase")
            return
        end
        maze = global.mazes.predefined[mazeIndex]
        reflect = math.random() < 0.5
        rotate = math.random(0, 3)
        dchunk.totalSpawners = 0
        dchunk.mazeIndex = mazeIndex
        dchunk.mazeReflection = reflect
        dchunk.mazeRotation = rotate
        local chunkGenCallback = function(surface, pos)
            local rocks = surface.find_entities_filtered{name = {"rock-big", "rock-huge"}, area = util.getChunkArea(pos)}
            for _, rock in pairs(rocks) do
                rock.destroy()
            end
            if mazes.getMazeValue(maze, pos.x, pos.y, reflect, rotate) == 0 then
                util.setTiles(surface, pos, global.config.voidTileAlt, true, false)
                util.setTiles(surface, pos, global.config.voidTile, true, true)
            else
                util.setTiles(surface, pos, "out-of-map", true, false)
            end
            local relPos = mazes.worldToRelative(maze, pos.x, pos.y, reflect, rotate)
            if relPos.x == maze.goal.x * 2 and relPos.y == maze.goal.y * 2 then
                -- if not global.highestInfinityItem then
                --     global.highestInfinityItem = "iron-gear-wheel" -- reset to beginning
                -- end
                -- local chest = surface.create_entity{name = "infinity-chest", position = {x = pos.x * 32 + 16, y = pos.y * 32 + 16}, force = "enemy"}
                -- chest.set_infinity_container_filter(1, {
                --     name = global.highestInfinityItem,
                --     count = 100,
                --     mode = "exactly",
                -- })
                -- chest.minable = false
                -- chest.destructible = false

                -- local positions = {
                --     {chest.position.x-1.5,chest.position.y},
                --     {chest.position.x,chest.position.y+1.5},
                --     {chest.position.x+1.5,chest.position.y},
                --     {chest.position.x,chest.position.y-1.5},
                -- }
                -- for d, _pos in pairs(positions) do
                --     local loader = surface.create_entity{name = "express-loader", position = _pos, force = "enemy", direction = (4 - 2 * d) % 8}
                --     loader.destructible = false
                --     loader.minable = false
                --     loader.loader_type = "output"
                -- end
            else
                if relPos.x ~= (maze.size.w - 1) / 2 or relPos.y ~= (maze.size.h - 1) / 2 then
                    local spawners = util.spawnBiterNest(surface, util.getChunkArea(pos), math.random(cfg.spawnersPerChunkMin, cfg.spawnersPerChunkMax), math.random(cfg.wormsPerChunkMin, cfg.spawnersPerChunkMax))
                    -- dchunk.totalSpawners = dchunk.totalSpawners + spawners
                else
                    local positions = {mazes.relativeToWorld(maze, (maze.size.w - 1) / 2, (maze.size.h - 1) / 2, reflect, rotate)}
                    positions[1].x = positions[1].x * 32 + 12
                    positions[1].y = positions[1].y * 32 + 16
                    positions[2] = util.deepcopy(positions[1])
                    positions[2].x = positions[2].x + 7
                    for _, p in pairs(positions) do
                        local chest = surface.create_entity{name = "blue-chest", position = p, force = "player"}
                        if chest then
                            chest.minable = false
                            chest.destructible = false
                            local inv = chest.get_inventory(defines.inventory.chest)
                            if inv then
                                table.insert(dchunk.voidInventories, inv)
                            end
                        end
                    end
                end
            end
        end
        local finishedCallback = function(surface)
            local size = {w = 0.5, h = 0.5}
            local pos = mazes.relativeToWorld(maze, (maze.size.w - 1) / 2, (maze.size.h - 1) / 2, reflect, rotate)
            pos.x = pos.x * 32 + 16
            pos.y = pos.y * 32 + 16
            teleporters.addTeleporter(
                "gridtorio", surface.name,
                {x = newChunkCoords.x * 32 + 17.5, y = newChunkCoords.y * 32 + 17.5}, pos,--{x = -16, y = -16},
                size, size,
                global.config.teleporters.tile
            )
            surface.daytime = 0.5
            surface.freeze_daytime = true
            for _, entity in pairs(surface.find_entities_filtered{name = {"biter-spawner", "spitter-spawner"}}) do
                dchunk.totalSpawners = dchunk.totalSpawners + 1
            end
            -- log("util.colorLocalizedString" .. tostring(util.colorLocalizedString))
            -- log("util.gpsToString" .. tostring(util.gpsToString))
            history.printAndLog(
                util.colorLocalizedString({"gridtorio.notification-dimension-purchased", player.name, util.gpsToString({newChunkCoords.x * 32 + 18, newChunkCoords.y * 32 + 18})}, "blue"),
                "voidDimensions",
                global.config.notifications["void-dimension-opened"]
            )
            -- history.printAndLog(
            --     util.colorLocalizedString({"gridtorio.void-dimension-secret"}, "yellow"),
            --     "voidDimensions",
            --     global.config.notifications["void-dimension-opened"]
            -- )
        end
        dchunk.inventories = {}
        dchunk.voidInventories = {}
        local area = util.getChunkArea(newChunkCoords)
        area.right_bottom.x = area.right_bottom.x + 1
        area.right_bottom.y = area.right_bottom.y + 1
        local entities = game.surfaces.gridtorio.find_entities_filtered{name = "blue-chest", area = area}
        for _, entity in pairs(entities) do
            local pos = entity.position
            entity.destroy()
            local chest = game.surfaces.gridtorio.create_entity{name = "red-chest", position = pos, force = "player"}
            if chest then
                chest.minable = false
                chest.destructible = false
                local inv = chest.get_inventory(defines.inventory.chest)
                if inv then
                    table.insert(dchunk.inventories, inv)
                end
            end
        end

        surfaceGen.createSurface(dchunk.surfaceName, global.config.voidDimensionMapGen, {position = {x = 0, y = 0}, radius = (maze.size.w + 3) / 2, genMessage = true, chunkGenCallback = chunkGenCallback, finishedCallback = finishedCallback})
        global.dchunksByDim[dchunk.surfaceName] = dchunk
        dchunk.serial = global.totalVoidDimensions
        global.totalVoidDimensions = global.totalVoidDimensions + 1
    else
        log("ERROR: No dimensional chunk data found for dimensional chunk purchase")
    end
end

function chunks.initChunk(surface, chunkCoords, area)
    local chance

    -- Compute distance from center of world, measured in tiles
    local dist = 32 * math.sqrt(chunkCoords.x * chunkCoords.x + chunkCoords.y * chunkCoords.y)

    -- Test for start chunk
    local isStartChunk = chunkCoords.x == 0 and chunkCoords.y == 0

    -- Test for void chunk
    local vcmc = global.config.voidChunks.maxChance
    if upgrades.isUpgradeUnlocked "reducedVoidChunkChance" then
        vcmc = global.config.voidChunks.upgradedMaxChance
    end
    chance = (dist - global.config.voidChunks.minDistance) / (global.config.voidChunks.maxDistance - global.config.voidChunks.minDistance)
    chance = chance * chance * (vcmc - global.config.voidChunks.minChance) + global.config.voidChunks.minChance
    chance = math.min(math.max(chance, global.config.voidChunks.minChance), vcmc)
    local isVoidChunk = not isStartChunk and dist >= global.config.voidChunks.minDistance and math.random() < chance

    -- Test for super chunk
    local isSuperChunk = not isStartChunk
    if isSuperChunk then
        if not upgrades.isUpgradeUnlocked "reducedVoidChunkChance" and dist >= global.config.greatRingOfSuperChunks.voidRadius and dist < global.config.greatRingOfSuperChunks.fadeInRadius then
            isSuperChunk = false
            isVoidChunk = true
        elseif dist >= global.config.greatRingOfSuperChunks.fadeInRadius and dist <= global.config.greatRingOfSuperChunks.fadeOutRadius then
            local t = util.multipleInterpolationInverse(dist, global.greatRingOfSuperChunksRadii)
            chance = 1
            if t > 3 then
                chance = util.lerp(1, vcmc, t - 3)
            elseif t < 1 then
                chance = util.lerp(vcmc, 1, t)
            end
            isSuperChunk = math.random() < chance
            isVoidChunk = not isSuperChunk
        else
            if isVoidChunk or dist < global.config.superChunks.minDistance then
                isSuperChunk = false
            else
                chance = (dist - global.config.superChunks.minDistance) / (global.config.superChunks.maxDistance - global.config.superChunks.minDistance)
                chance = chance * chance * (global.config.superChunks.maxChance - global.config.superChunks.minChance) + global.config.superChunks.minChance
                chance = math.min(math.max(chance, global.config.superChunks.minChance), global.config.superChunks.maxChance)
                if math.random() > chance then
                    isSuperChunk = false
                end
            end
        end
    end

    -- Test for biter spawn
    local isBiterChunk = not isVoidChunk and dist >= 64 and math.random() < global.config.biterChunkChance

    -- Test for ore spawn
    local isOreChunk = not isVoidChunk and (isStartChunk or isSuperChunk or dist < 64 or math.random() < global.config.baseOreChance)

    -- Test for market spawn
    local isMarketChunk = not isVoidChunk and (isStartChunk or isSuperChunk or math.random() < global.config.baseMarketChance)

    -- Test for ruins spawn
    local isRuinsChunk = not isVoidChunk and not (isMarketChunk or isOreChunk or isBiterChunk) and math.random() < global.config.ruinsChunkChance

    -- Handle void chunk
    if isVoidChunk then
        -- delete tiles
        util.setTiles(surface, chunkCoords, "out-of-map", true)
    end

    -- Construct indestructible walls
    local wall = surface.create_entity{name = "stone-wall", position = {x = area.left_top.x, y = area.left_top.y}, force = "neutral"}
    if wall then
        wall.destructible = false
        wall.minable = false
    end
    for n = 1, 31 do
        wall = surface.create_entity{name = "stone-wall", position = {x = area.left_top.x + n, y = area.left_top.y}, force = "neutral"}
        if wall then
            wall.destructible = false
            wall.minable = false
        end
        wall = surface.create_entity{name = "stone-wall", position = {x = area.left_top.x, y = area.left_top.y + n}, force = "neutral"}
        if wall then
            wall.destructible = false
            wall.minable = false
        end
    end

    if isVoidChunk then
        global.voidChunks[util.positionToString(chunkCoords)] = true
        return
    end

    -- Add floor tiles
    if not global.boughtChunks[util.positionToString(chunkCoords)] then
        if global.config.unexploredTile and global.config.unexploredTile ~= "" then
            util.setTiles(surface, chunkCoords, global.config.unexploredTile)
        end
    end
    
    -- Handle ore generation
    if isOreChunk then
        local richness = math.floor(global.config.oreRichnessOverDistance * dist) + global.config.baseOreRichness
        local size = global.config.baseOreSize
        if isBiterChunk then
            richness = richness * global.config.biterChunkOreRichnessMultiplier
            size = size + global.config.biterChunkOreSizeIncrement
        end
        if dist >= global.config.crudeOilMinDistance and math.random() < global.config.crudeOilChance then
            local amount = global.config.baseCrudeOilAmount
            if isBiterChunk then
                amount = amount + global.config.biterChunkCrudeOilAmountIncrement
            end
            if isSuperChunk then
                amount = amount + global.config.superChunkCrudeOilAmountIncrement
            end
            chunks.spawnCrudeOil(surface, area, amount, richness * 666)
        else
            local position = {x = area.left_top.x + math.random(2 + size, 30 - size), y = area.left_top.y + math.random(2 + size, 30 - size)}
            if isSuperChunk then
                position.x = area.left_top.x + 16
                position.y = area.left_top.y + 16
                size = 15
            end
            local biasStrength = 5
            local weights
            if global.config.oreMixture > 0 then
                biasStrength = biasStrength / math.max(0.5, global.config.oreMixture)
            else
                weights = {0, 0, 0, 0}
                weights[math.random(1, 4)] = 1
            end
            if isStartChunk then
                weights = {global.config.starterOresWeights["iron-ore"], global.config.starterOresWeights["copper-ore"], global.config.starterOresWeights["stone"], global.config.starterOresWeights["coal"]}
            end
            local canBeUranium = dist >= global.config.uraniumOreMinDistance
            chunks.spawnOre(surface, position, size, richness, biasStrength, weights, canBeUranium)
        end
    end

    -- Handle market generation
    if isMarketChunk then
        local x = area.left_top.x + math.random(3, 29)
        local y = area.left_top.y + math.random(3, 29)
        if not util.tileIsWater(surface, x, y, 1) then
            local market = surface.create_entity{name = "market", position = {x = x, y = y}, force = "player"}
            if market then
                market.destructible = false
                -- global.markets[chunkToString(chunkCoords)] = market
                if isStartChunk then
                    for _, offer in pairs(global.config.starterMarketOffers) do
                        local itemToReceive = offer[1]
                        local itemToGive = offer[2]
                        markets.addMarketOffer(market, itemToReceive, itemToGive)
                    end
                    markets.initMarket(market, isSuperChunk)
                    global.starterMarket = market
                end
            end
        end
    end

    -- Add biters
    if isBiterChunk then
        local wormTypes = {"small-worm-turret", "medium-worm-turret", "big-worm-turret", "behemoth-worm-turret"}
        local d = dist * global.config.wormEvolutionOverDistance

        local bcsc = global.config.biterChunkSpawnerChance
        local bcwc = global.config.biterChunkWormChance
        if isSuperChunk then
            bcsc = 0.25
            bcwc = 0.4
            d = d * 1.25
        end

        local wormWeights = {d ^ 0.5, d ^ 0.8, d ^ 1.1, d ^ 1.4}

        if dist <= global.config.behemothWormMinDistance then
            wormWeights[4] = 0
        end
        if dist <= global.config.bigWormMinDistance then
            wormWeights[3] = 0
        end

        local totalWormWeight = util.sum(wormWeights)

        for y = area.left_top.y + 4, area.right_bottom.y - 4, 5 do
            for x = area.left_top.x + 4, area.right_bottom.x - 4, 5 do
                if not util.tileIsWater(surface, x, y, 2) then
                    local biterType
                    if math.random() < bcsc then
                        if math.random() < 0.5 then
                            biterType = "spitter-spawner"
                        else
                            biterType = "biter-spawner"
                        end
                    elseif math.random() < bcwc then
                        biterType = util.weightedChoice(wormTypes, wormWeights, totalWormWeight)
                    end
                    if biterType then
                        surface.create_entity{name = biterType, position = {x = x, y = y}}
                    end
                end
            end
        end
    end

    -- Generate ruins
    if isRuinsChunk then
        global.ruinsChunks[util.positionToString(chunkCoords)] = true
        local lootValue = math.random(global.config.ruinsChestLootValueMin, global.config.ruinsChestLootValueMax) + global.config.ruinsChestLootValueOverDistance * dist
        local lootInventories = {}
        for _ = 1, math.random(global.config.ruinsChunkNumBuildingsMin, global.config.ruinsChunkNumBuildingsMax) do
            local position = {x = area.left_top.x + math.random(3, 28), y = area.left_top.y + math.random(3, 28)}
            if not util.tileIsWater(surface, position.x, position.y, 2) then
                local entityName = util.weightedChoice(global.ruinsChunkBuildingNames, global.ruinsChunkBuildingWeights, global.ruinsChunkBuildingTotalWeight)
                local nearbyEntities = surface.find_entities_filtered{
                    area = {
                        left_top = {
                            x = position.x - 3,
                            y = position.y - 3,
                        },
                        right_bottom = {
                            x = position.x + 3,
                            y = position.y + 3,
                        },
                    },
                    type = global.ruinsChunkBuildingNames,
                }
                if #nearbyEntities == 0 then
                    local force = "neutral"
                    if entityName == "laser-turret" or entityName == "gun-turret" or entityName == "flamethrower-turret" or entityName == "artillery-turret" then
                        lootValue = lootValue + global.config.ruinsChestLootValuePerTurret
                        force = "enemy"
                    end
                    local entity = surface.create_entity{name = entityName, position = position, force = force, direction = math.random(0, 3) * 2}
                    if entity.health then
                        local entityProt = game.entity_prototypes[entityName]
                        if entityProt and entityProt.max_health then
                            entity.health = 50 + math.random() * (entityProt.max_health - 50)
                        end
                    end
                    local inv = entity.get_inventory(defines.inventory.chest)
                    if inv then
                        table.insert(lootInventories, inv)
                    end
                    if entityName == "artillery-turret" then
                        if dist >= global.config.artilleryLoadShellDistance then
                            if math.random() < global.config.artilleryLoadShellChance then
                                inv = entity.get_inventory(defines.inventory.artillery_turret_ammo)
                                inv.insert{name="artillery-shell", count=15}
                            end
                        end
                    elseif entityName == "gun-turret" then
                        inv = entity.get_inventory(defines.inventory.turret_ammo)
                        inv.insert{name="uranium-rounds-magazine", count=200}
                    elseif entityName == "flamethrower-turret" then
                        entity.fluidbox[1] = {name="light-oil", amount=1000}
                    end
                end
            end
        end
        if #lootInventories > 0 then
            lootValue = lootValue / #lootInventories
            for _, inv in pairs(lootInventories) do
                util.addLootToInventory(inv, lootValue, global.config.ruinsChestLoot)
            end
        end
    end

    -- Register super chunk
    if isSuperChunk then
        global.superChunks[util.positionToString(chunkCoords)] = true
    end

    -- Check for adjacent void chunks that are isolated from other void chunks
    for d = 0, 3 do
        local adjPos = util.offsetPosition(chunkCoords, d)
        if chunks.isVoidChunk(adjPos) then
            local isDimensionalChunk = true
            for _d = 3, 5 do
                local d2 = (d + _d) % 4
                local adjPos2 = util.offsetPosition(adjPos, d2)
                if chunks.isVoidChunk(adjPos2) or not surface.is_chunk_generated(adjPos2) then
                    isDimensionalChunk = false
                end
            end
            if isDimensionalChunk then
                chunks.initDimensionalChunk(adjPos)
            end
        end
    end
end

function chunks.initDimensionalChunk(chunkCoords)
    local dchunk = {
        inventories = {},
        chunkCoords = chunkCoords,
    }

    -- For each side of the chunk, replace the middle wall with a blue chest.
    local positions = {
        {x = chunkCoords.x * 32 + 16, y = chunkCoords.y * 32},
        {x = chunkCoords.x * 32 + 16, y = chunkCoords.y * 32 + 32},
        {x = chunkCoords.x * 32, y = chunkCoords.y * 32 + 16},
        {x = chunkCoords.x * 32 + 32, y = chunkCoords.y * 32 + 16},
    }

    for _, pos in pairs(positions) do
        local realPos = {x = pos.x + 0.5, y = pos.y + 0.5}
        local wall = game.surfaces.gridtorio.find_entity("stone-wall", realPos)
        if wall then
            wall.destroy()
        end
        local chest = game.surfaces.gridtorio.create_entity{name = "blue-chest", position = realPos, force = "player"}
        chest.minable = false
        chest.destructible = false
        if chest then
            local inv = chest.get_inventory(defines.inventory.chest)
            if inv then
                table.insert(dchunk.inventories, inv)
            end
        end
    end

    global.dimensionalChunks[util.positionToString(chunkCoords)] = dchunk
end

function chunks.isVoidChunk(chunkCoords)
    return global.voidChunks[util.positionToString(chunkCoords)] == true
end

function chunks.tryUnlockDimensionalChunk(player, surface, chunkCoords, direction)
    local newChunkCoords = util.offsetPosition(chunkCoords, direction)
    local dchunk = global.dimensionalChunks[util.positionToString(newChunkCoords)]
    if not dchunk then return end

    if #dchunk.inventories ~= 4 then
        log("ERROR: there aren't four inventories at " .. util.positionToString(newChunkCoords) .. ", instead there are " .. #dchunk.inventories)
        return
    end

    local totalItemValue = 0
    local hadCoins = false
    for _, inv in pairs(dchunk.inventories) do
        for itemName, itemCount in pairs(inv.get_contents()) do
            if itemName == "coin" then
                hadCoins = true
                inv.remove{name = "coin", count = itemCount}
            else
                local v = global.itemValues[itemName]
                if v then
                    totalItemValue = totalItemValue + itemCount * v
                    inv.remove{name = itemName, count = itemCount}
                end
            end
        end
    end

    if totalItemValue == 0 then
        if hadCoins then
            player.print(util.colorLocalizedString({"upgrade-effects.coins-ignored"}, "red"))
        else
            player.print(util.colorLocalizedString({"gridtorio.error-nothing-offered"}, "red"))
        end
        return
    end

    local totalCoinValue = totalItemValue / global.itemValues["coin"]

    local satLevel = -1
    local satReq, satNextReq
    for slStr, req in pairs(global.config.dimChunkSatLevelRequirements) do
        if totalCoinValue >= req then
            if satLevel == -1 then
                satLevel = tonumber(slStr)
                satReq = req
            else
                if tonumber(slStr) > satLevel then
                    satLevel = tonumber(slStr)
                    satReq = req
                end
            end
        else
            satNextReq = math.min(satNextReq or req, req)
        end
    end

    if satLevel == -1 then
        log("ERROR: satisfaction level undetermined")
        return
    end

    dchunk.satLevel = satLevel

    if satLevel > 0 then
        local err = chunks.unlockChunk(player, surface, chunkCoords, direction, false)
        if not err then
            local satColors = {"orange", "green", "purple"}
            player.print(util.colorLocalizedString({"upgrade-effects.void-chunk-satisfaction-" .. satLevel}, satColors[satLevel]))
            chunks.onDimensionalChunkBought(player, chunkCoords, newChunkCoords)
        else
            player.print(util.colorLocalizedString(err, "red"))
        end
    else
        player.print(util.colorLocalizedString({"upgrade-effects.void-chunk-satisfaction-0"}, "red"))
    end

    if satNextReq then
        player.print(util.colorLocalizedString({"upgrade-effects.void-chunk-try-more", math.ceil(satNextReq - totalCoinValue)}, "yellow"))
    end

    if hadCoins then
        player.print(util.colorLocalizedString({"upgrade-effects.coins-ignored"}, "red"))
    end
end

function chunks.spawnOre(surface, position, size, amount, biasStrength, weights, canBeUranium)
    biasStrength = biasStrength or 3
    local ores = {"iron-ore", "copper-ore", "stone", "coal"}
    local totalWeight = 0
    if canBeUranium and math.random() < global.config.uraniumOreChance then
        ores = {"uranium-ore"}
        weights = {1}
        totalWeight = 1
    else
        if not weights then
            weights = {}
            for oreName, oreWeight in pairs(global.config.oreWeights) do
                table.insert(weights, math.exp(biasStrength * math.random()) * oreWeight)
                totalWeight = totalWeight + weights[#weights]
            end
        else
            for _, weight in pairs(weights) do
                totalWeight = totalWeight + weight
            end
        end
    end
    local tx, ty
    -- local lower = {x = position.x - math.floor(size, y = position.y - size}
    -- local upper = {x = position.x + size, y = position.y + size}
    for y = -size, size do
        ty = position.y + y
        for x = -size, size do
            tx = position.x + x
            if not util.tileIsWater(surface, tx, ty) then
                surface.create_entity{name = util.weightedChoice(ores, weights, totalWeight), position = {x = tx, y = ty}, amount = math.floor(util.rngModify(amount, 1.15))}
            end
        end
    end

    -- Remove decoratives over ores if setTiles() doesn't do it already.
    surface.destroy_decoratives{area = util.getChunkArea(util.getChunkCoords(position))}
end

function chunks.spawnCrudeOil(surface, area, amount, richness)
    local positions = {}
    for x = area.left_top.x + 3, area.right_bottom.x - 3, 6 do
        for y = area.left_top.y + 3, area.right_bottom.y - 3, 6 do
            if not util.tileIsWater(surface, x, y, 3) then
                table.insert(positions, {x = x, y = y})
            end
        end
    end
    local pos, index
    for i = 1, amount do
        if #positions == 0 then break end
        index = math.random(1, #positions)
        pos = positions[index]
        table.remove(positions, index)
        pos.x = pos.x + math.random(-1, 1)
        pos.y = pos.y + math.random(-1, 1)
        surface.create_entity{name = "crude-oil", position = pos, amount = math.floor(util.rngModify(richness, 1.15))}
    end
end

function chunks.checkWallCorners(surface, chunkCoords)
    local x, y, entity, iso, w
    for _, t in pairs{{0.5, 0.5}, {32.5, 0.5}, {0.5, 32.5}, {32.5, 32.5}} do
        x = chunkCoords.x * 32 + t[1]
        y = chunkCoords.y * 32 + t[2]
        entity = surface.find_entity("stone-wall", {x = x, y = y})
        if entity then
            -- Check walls around.  If none exist, then remove this entity.
            iso = true
            for _, t2 in pairs{{1, 0}, {0, 1}, {-1, 0}, {0, -1}} do
                w = surface.find_entity("stone-wall", {x = x + t2[1], y = y + t2[2]})
                if w and w.name == "stone-wall" and not w.destructible then
                    iso = false
                    break
                end
            end
            if iso then
                entity.destroy()
            end
        end
    end
end

function chunks.wallExists(surface, chunkCoords, direction)
    local dx = 1
    local dy = 0
    if direction % 2 == 0 then
        dx = 0
        dy = 1
    end
    local ox = 0
    local oy = 0
    if direction == 0 then
        ox = 32
    elseif direction == 1 then
        oy = 32
    end
    local area = {
        left_top = {
            x = chunkCoords.x * 32 + dx + ox,
            y = chunkCoords.y * 32 + dy + oy,
        },
        right_bottom = {
            x = chunkCoords.x * 32 + 31 * dx + ox + 1,
            y = chunkCoords.y * 32 + 31 * dy + oy + 1,
        },
    }
    local entities = surface.find_entities(area)
    for _, entity in pairs(entities) do
        if entity.name == "stone-wall" and not entity.destructible then
            return true
        end
    end
    return false
end

function chunks.deleteWall(surface, chunkCoords, direction)
    local dx = 1
    local dy = 0
    if direction % 2 == 0 then
        dx = 0
        dy = 1
    end
    local ox = 0
    local oy = 0
    if direction == 0 then
        ox = 32
    elseif direction == 1 then
        oy = 32
    end
    local area = {
        left_top = {
            x = chunkCoords.x * 32 + dx + ox,
            y = chunkCoords.y * 32 + dy + oy,
        },
        right_bottom = {
            x = chunkCoords.x * 32 + 31 * dx + ox + 1,
            y = chunkCoords.y * 32 + 31 * dy + oy + 1,
        },
    }
    local entities = surface.find_entities(area)
    for _, entity in pairs(entities) do
        if entity.name == "stone-wall" and not entity.destructible then
            entity.destroy()
        end
    end

    chunks.checkWallCorners(surface, chunkCoords)
end

function chunks.setChunkUnlockCost(newCost)
    global.chunkUnlockCost = math.min(global.config.chunkUnlockCostMax, newCost)
    global.tools.deleteMarketCost = global.chunkUnlockCost * 2
    local frame, label
    for _, player in pairs(game.connected_players) do
        frame = player.gui.top.NESWFrame
        if frame then
            label = frame.chunkUnlockCost
            if label then
                label.caption = {"gridtorio-gui.chunk-cost", global.chunkUnlockCost}
            end
        end
        tools.refresh(player)
    end
end

function chunks.unlockChunk(player, surface, chunkCoords, direction, notify)
    if notify == nil then notify = true end
    local err
    if not player or coinBanks.hasCoins(global.chunkUnlockCost, player) then
        if chunks.wallExists(surface, chunkCoords, direction) then
            local newChunkCoords
            if direction == -1 then
                newChunkCoords = chunkCoords
            else
                newChunkCoords = util.offsetPosition(chunkCoords, direction)
            end
            local s = util.positionToString(newChunkCoords)
            local prevBought = global.boughtChunks[s]
            if not prevBought then
                if direction ~= -1 then
                    chunks.deleteWall(surface, chunkCoords, direction)
                end
                if player then
                    coinBanks.deductCoins(global.chunkUnlockCost, player)
                end
                local cost = global.chunkUnlockCost
                chunks.setChunkUnlockCost(global.chunkUnlockCost + global.config.chunkUnlockCostIncrement)
                global.boughtChunks[s] = true
                chunks.onChunkBought(player, surface, chunkCoords, direction)
                if player and global.config.notifications["wall-purchase"] and notify then
                    history.printAndLog(
                        util.colorLocalizedString({"gridtorio.notification-wall-purchase", player.name, "[gps=" .. (newChunkCoords.x * 32 + 16) .. ", " .. (newChunkCoords.y * 32 + 16) .. ",gridtorio]", cost}, "green"),
                        "boughtChunks"
                    )
                end
                if upgrades.isUpgradeEnabled "freeRoboports" then
                    local pos = {x = newChunkCoords.x * 32 + 16, y = newChunkCoords.y * 32 + 16}
                    if not util.tileIsWater(surface, pos.x, pos.y, 3) then
                        local roboport = surface.create_entity{
                            name = "roboport",
                            position = pos,
                            force = "player",
                        }
                        pos = {x = roboport.position.x - 1, y = roboport.position.y - 3}
                        if not util.tileIsWater(surface, pos.x, pos.y, 1) then
                            surface.create_entity{
                                name = "big-electric-pole",
                                position = pos,
                                force = "player",
                            }
                        end
                        pos = {x = newChunkCoords.x * 32 + 31, y = newChunkCoords.y * 32 + 30}
                        if not util.tileIsWater(surface, pos.x, pos.y, 1) then
                            surface.create_entity{
                                name = "big-electric-pole",
                                position = pos,
                                force = "player",
                            }
                        end
                    end
                end
            else
                err = {"gridtorio.error-chunk-already-bought"}
            end
        else
            err = {"gridtorio.error-chunk-already-bought"}
        end
    else
        err = {"gridtorio.error-cannot-afford-chunk", global.chunkUnlockCost}
    end
    return err
end

function chunks.automateChunkUnlocking(player)
    local chunkCoordsDir = acu.getChunkToUnlock()
    if chunkCoordsDir then
        chunks.unlockChunk(player, game.surfaces.gridtorio, chunkCoordsDir.coords, chunkCoordsDir.d, false)
        if chunkCoordsDir.d ~= -1 then
            local newChunkCoords = util.offsetPosition(chunkCoordsDir.coords, chunkCoordsDir.d)
            game.forces.player.chart(game.surfaces.gridtorio, {
                left_top = {
                    x = newChunkCoords.x * 32 - 32,
                    y = newChunkCoords.y * 32 - 32,
                },
                right_bottom = {
                    x = newChunkCoords.x * 32 + 63,
                    y = newChunkCoords.y * 32 + 63,
                },
            })
            game.surfaces.gridtorio.request_to_generate_chunks({x = newChunkCoords.x * 32, y = newChunkCoords.y * 32}, 2)
        end
    else
        log("No chunk to unlock")
    end
end

function chunks.onDirectionButtonClicked(player, dirName)
    if player.surface ~= game.surfaces.gridtorio then
        log("player not on Gridtorio")
        return
    end
    local chunkCoords = util.getChunkCoordsOfPlayer(player)
    local err
    local color = "red"
    if global.boughtChunks[util.positionToString(chunkCoords)] then
        local direction
        if dirName == "north" then
            direction = 3
        elseif dirName == "east" then
            direction = 0
        elseif dirName == "south" then
            direction = 1
        elseif dirName == "west" then
            direction = 2
        end
        if direction then
            local newChunkCoords = util.offsetPosition(chunkCoords, direction)
            if not global.dimensionalChunks[util.positionToString(newChunkCoords)] then
                if not global.voidChunks[util.positionToString(newChunkCoords)] then
                    err = chunks.unlockChunk(player, player.surface, chunkCoords, direction)
                else
                    err = {"gridtorio.error-chunk-is-void"}
                end
            else
                if upgrades.isUpgradeUnlocked "dimensionalChunks" then
                    chunks.tryUnlockDimensionalChunk(player, player.surface, chunkCoords, direction)
                else
                    err = {"gridtorio.error-chunk-is-dimensional"}
                    color = "yellow"
                end
            end
        end
    else
        err = {"gridtorio.error-not-in-purchased-chunk"}
    end
    if err then
        player.print(util.colorLocalizedString(err, color))
    end
end

function chunks.processVoidDimension(dchunk)
    local totalInv = util.sumInventories{dchunk.voidInventories[1].get_contents(), dchunk.voidInventories[2].get_contents()}
    local toRemove = {}
    local buffer = {}
    local split2 = util.splitInventory(totalInv)
    for i = 1, 2 do
        local split4 = util.splitInventory(split2[i])
        for j = 1, 2 do
            local inv = dchunk.inventories[i*2+j-2]
            local partialInv = split4[j]
            for itemName, itemCount in pairs(partialInv) do
                local actualItemCount = itemCount + (buffer[itemName] or 0)
                local count = inv.insert{name = itemName, count = actualItemCount}
                if count > 0 then
                    toRemove[itemName] = (toRemove[itemName] or 0) + count
                end
                if count > itemCount then
                    buffer[itemName] = buffer[itemName] - (count - itemCount)
                end
                if count < actualItemCount then
                    buffer[itemName] = (buffer[itemName] or 0) + itemCount - count
                end
            end
        end
    end
    for itemName, itemCount in pairs(toRemove) do
        local removed = dchunk.voidInventories[1].remove{name = itemName, count = itemCount}
        if removed < itemCount then
            dchunk.voidInventories[2].remove{name = itemName, count = itemCount - removed}
        end
    end
end

function chunks.deleteNearestInfestedChunk(chunkCoords)
    local closest, closestDist
    for posStr, ic in pairs(global.infestedChunks) do
        if not closest then
            closest = posStr
            closestDist = util.squareDistance(ic.chunkCoords, chunkCoords)
        else
            local dist = util.squareDistance(ic.chunkCoords, chunkCoords)
            if dist < closestDist then
                closest = posStr
                closestDist = dist
            end
        end
    end
    if closest then
        local ic = global.infestedChunks[closest]
        local entities = game.surfaces.gridtorio.find_entities_filtered{name = {"biter-spawner", "spitter-spawner"}, area = util.getChunkArea(ic.chunkCoords)}
        for _, entity in pairs(entities) do
            if not entity.destructible then
                entity.destroy()
            end
        end
        game.print(util.colorLocalizedString({"gridtorio.infested-chunk-destroyed", util.gpsToString({x = ic.chunkCoords.x * 32 + 16, y = ic.chunkCoords.y * 32 + 16}, "gridtorio")}, "purple"))
        global.infestedChunks[closest] = nil
    end
end



return chunks
