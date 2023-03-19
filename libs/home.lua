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

    local player = getPlayer()
    local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
    local place = nil
    for dx = -1, 1 do
        for dy = -1, 0 do
            for dz = -1, 1 do
                local _pos = Walk.walkableBlock({pos[1]+dx, pos[2]+dy, pos[3]+dz}, pos, 1, 1)
                if _pos ~= nil and Calc.compareArray(_pos, pos) == false then
                    place = _pos
                    break
                end
            end
            if place ~= nil then break end
        end
    end

    if place == nil then return false end

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
    local slot, _ = next(item)
    inv.swap(slot, map.hotbar[9])
    setHotbar(9)

    local player = getPlayer()
    local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
    local place = nil
    for dx = -1, 1 do
        for dy = -1, 0 do
            for dz = -1, 1 do
                local _pos = Walk.walkableBlock({pos[1]+dx, pos[2]+dy, pos[3]+dz}, pos, 1, 1)
                if _pos ~= nil and Calc.compareArray(_pos, pos) == false then
                    place = _pos
                    break
                end
                ::continue::
            end
            if place ~= nil then break end
        end
    end

    if place == nil then return false end

    return Action.placeBlock('minecraft:furnace', place)
end

home.homePlace = function (pos)
    local block = getBlock(pos[1], pos[2] - 1, pos[3])
    for i = -1, 1 do
        for j = -1, 1 do
            local _pos = {pos[1]+i, pos[2], pos[3]+j}
            local _block = getBlock(_pos[1], _pos[2], _pos[3])
            if _block ~= nil and block.id == 'minecraft:water' then return false end
            if block == nil or Walk.walkableBlock(pos, _pos) == false then return false end
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

    if place == nil then return false end

    local count = Inventory.countItems('minecraft:crafting_table')
    if count == 0 then Crafting.craft('minecraft:crafting_table') end

    local box = Calc.createBox(place, 4)
    Walk.walkTo(box, 50)
    home.setHome(place[1], place[2], place[3])
end

home.goHome = function()
    log('Going home')
    local homePos = home.getHome()
    local homeBox = Calc.createBox(homePos, 4)
    Walk.walkTo(homeBox, 50)
end

return home
