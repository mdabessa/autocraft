local home = {}

home.HOME = nil

home.resetHome = function()
    home.HOME = nil
end

home.getHome = function()
    return home.HOME
end

home.setHome = function(x, y, z)
    home.HOME = {x, y, z}
end

home.buildWorkbench = function()
    local inv = openInventory()
    local map = inv.mapping.inventory
    local item = Inventory.findItem('minecraft:crafting_table', map)

    if next(item) == nil then
        Crafting.craft('minecraft:crafting_table', 1)
        item = Inventory.findItem('minecraft:crafting_table', map)
        if next(item) == nil then return false end
    end

    local place = World.searchStructure(
        function(pos)
            local block = getBlock(pos[1], pos[2], pos[3])
            if Walk.solidBlock(block.id) == true then return false end
            local _block = getBlock(pos[1], pos[2]-1, pos[3])
            if Walk.solidBlock(_block.id) == false then return false end
            return true
        end,
        5
    )

    if place == nil then return false end

    local box = Calc.createBox(place, 1.2)
    local s = Walk.walkTo(box, 50)
    if s == false then return false end

    return Action.placeBlock('minecraft:crafting_table', place)
end

home.buildFurnace = function()
    local inv = openInventory()
    local map = inv.mapping.inventory
    local item = Inventory.findItem('minecraft:furnace', map)

    if next(item) == nil then
        Crafting.craft('minecraft:furnace', 1)
        item = Inventory.findItem('minecraft:furnace', map)
        if next(item) == nil then return false end
    end

    local place = World.searchStructure(
        function(pos)
            local block = getBlock(pos[1], pos[2], pos[3])
            if Walk.solidBlock(block.id) == true then return false end
            local _block = getBlock(pos[1], pos[2]-1, pos[3])
            if Walk.solidBlock(_block.id) == false then return false end
            return true
        end,
        5
    )

    if place == nil then return false end

    local box = Calc.createBox(place, 1.2)
    local s = Walk.walkTo(box, 50)
    if s == false then return false end

    return Action.placeBlock('minecraft:furnace', place)
end

home.homePlace = function (pos)
    local block = getBlock(pos[1], pos[2], pos[3])

    if block.id == 'minecraft:air' then return false end
    if block.id == 'minecraft:water' then return false end

    for i = -1, 1 do
        for j = -1, 1 do
            local _pos = {pos[1]+i, pos[2]+1, pos[3]+j}
            if Walk.walkableBlock(pos, _pos) == false then return false end
        end
    end

    for i = 1, 10 do -- 10 blocks above
        local _pos = {pos[1], pos[2] + i, pos[3]}
        block = getBlock(_pos[1], _pos[2], _pos[3])
        if block ~= nil and block.id ~= 'minecraft:air' then return false end
    end
    return true
end

home.createHome = function()
    local place = World.searchStructure(home.homePlace, 5)
    if place == false then return false end
    home.setHome(place[1], place[2]+1, place[3])
end

home.goHome = function()
    Logger.log('Going home')
    local homePos = home.getHome()
    local homeBox = Calc.createBox(homePos, 2)
    Walk.walkTo(homeBox, 50)
end

return home
