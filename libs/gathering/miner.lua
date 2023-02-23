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
    ["minecraft:lapis_ore"] = 3,
    ["minecraft:nether_quartz_ore"] = 3,
    ["minecraft:obsidian"] = 4
}

miner.minePlace = {['place'] = nil, ['direction'] = nil}

miner.getMinePlace = function ()
    if miner.minePlace['place'] == nil then
        local place = World.searchStructure(miner.minePlaceFinder, 5)
        if place == nil then error('No place to mine') end
        miner.setMinePlace({place[1], place[2]+1, place[3]})
    end
    return miner.minePlace['place']
end

miner.setMinePlace = function (place)
    miner.minePlace['place'] = place
end

miner.setMineDirection = function (direction)
    miner.minePlace['direction'] = direction
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

miner.assertPickaxeLevel = function(block)
    Inventory.sortHotbar()
    local inv = openInventory()
    local map = inv.mapping.inventory
    local pickaxe_level = miner.ORES_HARVEST_LEVEL[block] or 1
    local slot = Inventory.getHotbarSlot('pickaxe')
    local item = inv.getSlot(map['hotbar'][slot])
    if not Inventory.isTool(item, 'pickaxe') or Inventory.toolLevel(item.id) < pickaxe_level then
        local pickaxe = Inventory.getToolIdFromLevel('pickaxe', pickaxe_level)
        Crafting.craft(pickaxe, 1)
        Inventory.sortHotbar()
    end
end

miner.minePlaceFinder = function(pos)
    local home = Home.getHome() or {0, 0, 0}
    if Calc.distance3d(pos, home) < 10 then return false end
    local block = getBlock(pos[1], pos[2] - 1, pos[3])
    for i = -1, 1 do
        for j = -1, 1 do
            local _pos = {pos[1]+i, pos[2], pos[3]+j}
            local _block = getBlock(_pos[1], _pos[2], _pos[3])
            if _block ~= nil and block.id == 'minecraft:water' then return false end
            if block == nil or World.walkableBlock(pos, _pos) == false then return false end
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
    local inv = openInventory()
    local map = inv.mapping.inventory
    local slot = Inventory.getHotbarSlot('pickaxe')
    local light = getLight(pos[1], pos[2]+1, pos[3])
    if light < 4 then miner.placeTorch() end
    while true do
        local complete = 0
        for i = 0, 3 do
            complete = complete + 1
            local layer = i
            if i == 3 then layer = -1 end

            local item = inv.getSlot(map['hotbar'][slot])
            if not Inventory.isTool(item, 'pickaxe') then return nil end

            local _pos = {pos[1]+direction[1], pos[2] + layer, pos[3]+direction[2]}
            local block = getBlock(_pos[1], _pos[2], _pos[3])
            if block ~= nil and block.id ~= 'minecraft:air' then
                lookAt(_pos[1]+ 0.5, _pos[2], _pos[3]+0.5)
                Action.dig()
                complete = 0
            end
        end
        if complete == 4 then break end
    end

    return {pos[1] + direction[1], pos[2] - 1, pos[3]+direction[2]}
end


miner.mine = function(objective, quantity)
    local count = Inventory.countItems(objective)
    local goal = count + quantity
    local place = miner.getMinePlace()
    local directions = {{1,0}, {0,1}, {-1,0}, {0,-1}}
    local possible_directions = {}

    for i = 1, #directions do table.insert(possible_directions, directions[i]) end
    local direction_index = math.random(1, #possible_directions)
    local direction = Miner.minePlace['direction'] or table.remove(possible_directions, direction_index)
    local opposite_direction_index = Table.find(possible_directions, {direction[1] * -1, direction[2] * -1})
    table.remove(possible_directions, opposite_direction_index)

    while count < goal do
        miner.assertPickaxeLevel(objective)
        local box = Calc.createBox(place, 1)
        box = Calc.createBox(place, 1)
        if Walk.walkTo(box, 50, 5) == false then
            if #possible_directions == 0 then return false end
            direction = table.remove(possible_directions, math.random(1, #possible_directions))
        else
            for i = 1, #directions do table.insert(possible_directions, directions[i]) end
            direction_index = Table.find(possible_directions, direction)
            table.remove(possible_directions, direction_index)
            opposite_direction_index = Table.find(possible_directions, {direction[1] * -1, direction[2] * -1})
            table.remove(possible_directions, opposite_direction_index)
        end
        miner.setMinePlace(place)
        miner.setMineDirection(direction)
        local next_pos = miner.mineDown(direction)
        if next_pos ~= nil then place = next_pos end
        count = Inventory.countItems(objective)
        log('Mining ' .. objective .. ' ' .. count .. '/' .. goal)
        ::continue::
    end
end

return miner
