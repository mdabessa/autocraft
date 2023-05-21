local miner = {}

miner.ORES_HARVEST_LEVEL = {
    ["minecraft:stone"] = 1,
    ["minecraft:cobblestone"] = 1,
    ["minecraft:coal_ore"] = 1,
    ["minecraft:iron_ore"] = 2,
    ["minecraft:gold_ore"] = 2,
    ["minecraft:redstone_ore"] = 3,
    ["minecraft:emerald_ore"] = 3,
    ["minecraft:diamond_ore"] = 3,
    ["minecraft:diamond"] = 3,
    ["minecraft:lapis_ore"] = 3,
    ["minecraft:nether_quartz_ore"] = 3,
    ["minecraft:obsidian"] = 4
}

miner.getMinePoints = function ()
    local s, points = pcall(Json.read, './miner.json')
    if s == false then
        return {}
    elseif points['points'] == nil then
        return {}
    else
        return points['points']
    end
end

miner.addMinePoints = function (point)
    local points = miner.getMinePoints()
    table.insert(points, point)
    Json.dump({['points'] = points}, './miner.json')
end

miner.resetMinePoints = function ()
    Json.dump({}, './miner.json')
end

miner.goToMinePlace = function ()
    local points = miner.getMinePoints()
    if #points == 0 then
        Home.goHome()
        local place = World.searchStructure(miner.minePlaceFinder, 5)
        if place == nil then error('No place to mine') end
        miner.addMinePoints({place[1], place[2]+1, place[3]})
        points = miner.getMinePoints()
    end
    local pos = getPlayer().pos

    local closer = 1
    local closer_distance = Calc.distance3d(pos, points[1])
    for i = 2, #points do
        local distance = Calc.distance3d(pos, points[i])
        if distance < closer_distance then
            closer = i
            closer_distance = distance
        end
    end
    for i = closer, #points do
        local box = Calc.createBox(points[i], {5,5,5})
        if Walk.walkTo(box, 50, {['pathFinderTimeout'] = 5}) == false then
            error('Miner: Cannot reach mine place')
        end
    end
end

miner.leaveMinePlace = function ()
    local points = miner.getMinePoints()
    local pos = getPlayer().pos

    local closer = 1
    local closer_distance = Calc.distance3d(pos, points[1])
    for i = 2, #points do
        local distance = Calc.distance3d(pos, points[i])
        if distance < closer_distance then
            closer = i
            closer_distance = distance
        end
    end

    for i = closer, 1, -1 do
        local box = Calc.createBox(points[i], {5,5,5})
        if Walk.walkTo(box, 50, {['pathFinderTimeout'] = 5}) == false then
            error('Miner: Cannot leave mine place')
        end
    end
end

miner.placeTorch = function ()
    local count_torch = Inventory.countItems('minecraft:torch')
    if count_torch == 0 then
        Crafting.fastCraft('minecraft:torch', 1)
        count_torch = Inventory.countItems('minecraft:torch')
    end
    local torch = Inventory.findItem('minecraft:torch')
    if next(torch) ~= nil then
        local inv = openInventory()
        local slot, _ = next(torch)
        local torch_slot = Inventory.getHotbarSlot('placeable')
        inv.swap(slot, inv.mapping.inventory['hotbar'][torch_slot])
        sleep(300)
        setHotbar(torch_slot)

        local pos = getPlayer().pos
        lookAt(pos[1], pos[2], pos[3])
        sleep(200)
        use()
        sleep(200)
    end
end

miner.checkPickaxeLevel = function(block_id)
    local slot = Inventory.getHotbarSlot('pickaxe')
    local inv = openInventory()
    local map = inv.mapping.inventory
    local item = inv.getSlot(map['hotbar'][slot])
    local level = miner.ORES_HARVEST_LEVEL[block_id] or 1

    if not Inventory.isTool(item, 'pickaxe') then return false end
    if Inventory.toolLevel(item.id) < level then return false end
    return true
end

-- #TODO: Ao craftar uma picareta nova voltar para o ponto de mineração
-- #TODO: Ao craftar uma picareta nova ir para home usando o leaveMinePlace
miner.assertPickaxeLevel = function(block, min_durability)
    min_durability = min_durability or 0
    if miner.checkPickaxeLevel(block) and Inventory.toolsDurability('pickaxe') >= min_durability then return end -- Fast check
    Inventory.sortHotbar()
    local inv = openInventory()
    local map = inv.mapping.inventory
    local pickaxe_level = miner.ORES_HARVEST_LEVEL[block] or 1
    local slot = Inventory.getHotbarSlot('pickaxe')
    local item = inv.getSlot(map['hotbar'][slot])
    if (not Inventory.isTool(item, 'pickaxe') or Inventory.toolLevel(item.id) < pickaxe_level ) or
        (Inventory.toolsDurability('pickaxe') < min_durability) then
        local pickaxe = Inventory.getToolIdFromLevel('pickaxe', pickaxe_level)
        Crafting.craft(pickaxe, 1)
        Inventory.sortHotbar()
    end
end

miner.minePlaceFinder = function(pos)
    local home = Home.getHome() or {0, 0, 0}
    if Calc.distance3d(pos, home) < 10 then return false end
    local block = getBlock(pos[1], pos[2] - 1, pos[3])
    if block == nil then return false end
    for i = -1, 1 do
        for j = -1, 1 do
            local _pos = {pos[1]+i, pos[2], pos[3]+j}
            local _block = getBlock(_pos[1], _pos[2], _pos[3])
            if _block == nil then return false end
            if _block.id == 'minecraft:water' then return false end
            if _block.id == 'minecraft:air' then return false end
            if _block.id == 'minecraft:lava' then return false end
            if _block.id == 'minecraft:leaves' then return false end
            if Walk.walkableBlock({pos[1], pos[2]+1, pos[3]}, {_pos[1], _pos[2]+1, _pos[3]})
                == false then return false end
        end
    end
    for i = 1, 10 do -- 10 blocks above
        local _pos = {pos[1], pos[2] + i, pos[3]}
        block = getBlock(_pos[1], _pos[2], _pos[3])
        if block ~= nil and block.id ~= 'minecraft:air' then return false end
    end
    return true
end

miner.mineDown = function(direction)
    local player = getPlayer()
    local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
    local light = getLight(pos[1], pos[2]+1, pos[3])

    if light < 6 then miner.placeTorch() end
    miner.assertPickaxeLevel('minecraft:stone', 15)

    local point = {pos[1]+(direction[1]*5), pos[2]-5, pos[3]+(direction[2]*5)}
    local box = Calc.createBox(point, {3, 1, 3})

    local config = {['pathFinderTimeout'] = 10, ['weightMask'] = 0, ['maxFall'] = 3}
    if Walk.walkTo(box, 50, config) == false then error('Miner: Cannot walk to box') end
end

miner.mineForward = function(direction)
    local player = getPlayer()
    local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
    local light = getLight(pos[1], pos[2]+1, pos[3])
    if light < 4 then miner.placeTorch() end
    while true do
        local complete = 0
        for i = 0, 1 do
            complete = complete + 1

            if miner.checkPickaxeLevel('minecraft:stone') == false then return nil end

            local _pos = {pos[1]+direction[1], pos[2] + i, pos[3]+direction[2]}
            local block = getBlock(_pos[1], _pos[2], _pos[3])
            if block ~= nil and block.id ~= 'minecraft:air' then
                lookAt(_pos[1]+ 0.5, _pos[2], _pos[3]+0.5)
                if Action.safeDig() then
                    complete = 0
                end
            end
        end
        if complete == 2 then break end
    end

    return {pos[1] + direction[1], pos[2], pos[3]+direction[2]}
end

miner.mineOres = function (direction)
    local range = 3
    local pos = getPlayer().pos
    pos = {math.floor(pos[1]), math.floor(pos[2]), math.floor(pos[3])}

    while true do
        local dug = false
        for i=-range, range do
            for j=-range, range do
                for k=-range, range do
                    local dx = i
                    local dy = j
                    local dz = k

                    if direction[1] == 0 then dx = i- math.floor(range/2) end
                    if direction[2] == 0 then dz = k- math.floor(range/2) end

                    local _pos = {pos[1]+dx, pos[2]+dy, pos[3]+dz}
                    local block = getBlock(_pos[1], _pos[2], _pos[3])

                    if block ~= nil and string.find(block.id, 'ore') then
                        if Action.blockIsVisible(_pos[1], _pos[2], _pos[3]) == false then goto continue end
                        if miner.checkPickaxeLevel(block.id) == false then goto continue end

                        local box = Calc.createBox(_pos, {2, 6, 2})
                        if Walk.walkTo(box, 50, {nil, nil, 0.1}) == false then goto continue end
                        lookAt(_pos[1]+ 0.5, _pos[2], _pos[3]+0.5)
                        if Action.safeDig() then
                            dug = true
                        end
                    end
                    ::continue::
                end
            end
        end
        Action.pickupNearbyItems('item', 5, 0.1)
        if dug == false then break end
    end
end

miner.mine = function(objective, quantity)
    miner.assertPickaxeLevel(objective)
    local count = Inventory.countItems(objective)
    local goal = count + quantity

    miner.goToMinePlace()

    local directions = {{1,0}, {0,1}, {-1,0}, {0,-1}}
    local direction_index = math.random(1, #directions)
    local direction = table.remove(directions, direction_index)
    local opposite_direction_index = Table.find(directions, {direction[1] * -1, direction[2] * -1})
    table.remove(directions, opposite_direction_index)

    local c = 0
    while count < goal do
        miner.assertPickaxeLevel(objective)

        local f = miner.mineDown
        if getPlayer().pos[2] <= 11 then
            f = miner.mineForward
        end
        local s, err = pcall(f, direction)
        if s == false then
            if string.find(err, 'Miner: Cannot walk to box') then
                if #directions == 0 then error('Miner: Cannot find a place to mine') end
                direction_index = math.random(1, #directions)
                direction = table.remove(directions, direction_index)
                goto continue
            else
                error(err)
            end
        end

        if #directions < 2 then -- reset directions
            directions = {{1,0}, {0,1}, {-1,0}, {0,-1}}
            direction_index = Table.find(directions, direction)
            table.remove(directions, direction_index)
            opposite_direction_index = Table.find(directions, {direction[1] * -1, direction[2] * -1})
            table.remove(directions, opposite_direction_index)
        end

        if c % 5 == 0 then
            local pos = getPlayer().pos
            miner.addMinePoints({pos[1], pos[2], pos[3]})
        end

        miner.mineOres(direction)
        count = Inventory.countItems(objective)
        Logger.log('Mining ' .. objective .. ' ' .. count .. '/' .. goal)
        c = c + 1
        ::continue::
    end
    miner.leaveMinePlace()
end

return miner
