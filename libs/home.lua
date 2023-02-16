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
    local pos = getPlayer().pos
    pos = {math.floor(pos[1]), math.floor(pos[2]), math.floor(pos[3])}

    local inv = openInventory()
    local map = inv.mapping.inventory
    local item = Inventory.findItem('minecraft:crafting_table', map)

    if next(item) == nil then return false end
    local slot, _ = next(item)
    if slot > map.hotbar[1] and slot < map.hotbar[9] then
        inv.swap(slot, map.hotbar[9])
    end
    setHotbar(9)

    local place = {pos[1]+1, pos[2], pos[3]}
    lookAt(place[1]+0.5, place[2], place[3]+0.5)
    sleep(500)
    use()
    sleep(500)
end

home.createHome = function()
    local place = World.searchStructure(function (pos)
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
    Calc.walkTo(homeBox, 50, 10)
end

return home
