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

    if next(item) == nil then return false end
    local slot, _ = next(item)
    inv.swap(slot, map.hotbar[9])
    setHotbar(9)

    local player = getPlayer()
    local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
    local place = nil
    for dx = -1, 1 do
        for dy = -1, 0 do
            for dz = -1, 1 do
                local _pos = World.walkableBlock({pos[1]+dx, pos[2]+dy, pos[3]+dz}, pos, 1, 1)
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

    local pos_int = {math.floor(pos[1]), math.floor(pos[2]), math.floor(pos[3])}
    local ref =  {pos[1] - pos_int[1]-0.5, pos[3] - pos_int[3]-0.5}
    lookAt(place[1]+0.5, place[2], place[3]+0.5)

    sleep(100)
    sneak(200)
    if ref[1] > 0 then right(200) else left(200) end
    if ref[2] > 0 then forward(200) else back(200) end
    sleep(200)

    lookAt(place[1]+0.5, place[2], place[3]+0.5)

    local c = 0
    while true do
        local block = getBlock(place[1], place[2], place[3])
        if block ~= nil and block.id == 'minecraft:air' then break end
        if c > 5 then break end
        sleep(200)
        attack(100) -- break any flowers
        c = c + 1
    end

    sleep(500)
    use()
    sleep(500)
end
home.homePlace = function (pos)
    local block = getBlock(pos[1], pos[2] - 1, pos[3])
    for i = -1, 1 do
        for j = -1, 1 do
            local _pos = {pos[1]+i, pos[2], pos[3]+j}
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

home.createHome = function()
    local place = World.searchStructure(home.homePlace, 5)

    if place == nil then return false end

    local count = Inventory.countItems('minecraft:crafting_table')
    if count == 0 then Crafting.craft('minecraft:crafting_table') end

    local box = Calc.createBox(place, 4)
    Walk.walkTo(box, 50, 10)
    home.setHome(place[1], place[2], place[3])
    local s = home.buildWorkbench()
    if s == false then
        Crafting.craft('minecraft:crafting_table')
        Walk.walkTo(box, 50, 10)
        home.buildWorkbench()
    end
end

home.goHome = function()
    log('Going home')
    local homePos = home.getHome()
    local homeBox = Calc.createBox(homePos, 4)
    Walk.walkTo(homeBox, 50, 10)
end

return home
