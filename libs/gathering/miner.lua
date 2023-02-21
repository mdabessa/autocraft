local miner = {}

miner.ORES_HARVEST_LEVEL = {
    ["minecraft:stone"] = 1,
    ["minecraft:cobblestone"] = 1,
    ["minecraft:granite"] = 1,
    ["minecraft:diorite"] = 1,
    ["minecraft:andesite"] = 1,
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

miner.assertPickaxeLevel = function(block)
    Inventory.sortHotbar()
    local inv = openInventory()
    local map = inv.mapping.inventory
    local pickaxe_level = miner.ORES_HARVEST_LEVEL[block] or 1
    local slot = Inventory.getToolSlot('pickaxe')
    local item = inv.getSlot(map['hotbar'][slot])
    if not Inventory.isTool(item, 'pickaxe') or Inventory.toolLevel(item.id) < pickaxe_level then
        local pickaxe = Inventory.getToolIdFromLevel('pickaxe', pickaxe_level)
        Crafting.craft(pickaxe, 1)
        Inventory.sortHotbar()
    end
end

miner.minePlace = function(pos)
    local home = Home.getHome() or {0, 0, 0}
    if Calc.distance3d(pos, home) < 10 then return false end
    local block = getBlock(pos[1], pos[2] - 1, pos[3])
    if block ~= nil and block.id ~= 'minecraft:grass' then return false end
    for i = -1, 1 do
        for j = -1, 1 do
            local _pos = {pos[1]+i, pos[2], pos[3]+j}
            if block == nil or World.walkableBlock(pos, _pos) == false then return false end
        end
    end
    return true
end

miner.mineDown = function(direction)
    local player = getPlayer()
    local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
    local inv = openInventory()
    local map = inv.mapping.inventory
    local slot = Inventory.getToolSlot('pickaxe')
    while true do
        local complete = 0
        for i = 0, 3 do
            complete = complete + 1
            local layer = i
            if i == 3 then layer = -1 end

            local item = inv.getSlot(map['hotbar'][slot])
            if not Inventory.isTool(item, 'pickaxe') then break end

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

    local box = Calc.createBox({pos[1] + direction[1], pos[2] - 1, pos[3]+direction[2]}, 1)
    return Walk.walkTo(box, 50, 2)
end

miner.mine = function(objective, quantity)
    local count = Inventory.countItems(objective)
    local goal = count + quantity
    miner.assertPickaxeLevel(objective)

    local place = World.searchStructure(miner.minePlace, 5)

    local box = Calc.createBox(place, 1)
    --Walk.walkTo(box, 50, 10)
    local directions = {{1,0}, {0,1}, {-1,0}, {0,-1}}
    local direction_index = 1
    while count < goal do
        local s = miner.mineDown(directions[direction_index])
        if s == false then
            direction_index = direction_index + 1
            if direction_index > 4 then direction_index = 1 end
        end
        count = Inventory.countItems(objective)
    end
end

return miner
