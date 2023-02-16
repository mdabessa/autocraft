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

miner.mineDown = function()
    local player = getPlayer()
    for i = 1, 4 do
        local pos = {player.pos[1] + i, player.pos[2] - 1, player.pos[3]}
        local block = getBlock(pos[1], pos[2], pos[3])
        if block ~= nil and block.id ~= 'minecraft:air' then
            lookAt(pos[1]+ 0.5, pos[2], pos[3])
            Action.dig()
        end
    end
    local box = Calc.createBox({player.pos[1]+1, player.pos[2] - 1, player.pos[3]}, 1)
    Walk.walkTo(box, 50, 2)
end

miner.mine = function(objective, quantity)
    local count = Inventory.countItems(objective)
    local goal = count + quantity
    miner.assertPickaxeLevel(objective)

    local place = World.searchStructure(function (pos)
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
    end, 5)

    local box = Calc.createBox(place, 1)
    Walk.walkTo(box, 50, 10)

    while count < goal do
        miner.mineDown()
        count = Inventory.countItems(objective)
    end
end

return miner
