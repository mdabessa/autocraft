local wood = {}

wood.isTree = function(pos)
    local block = getBlock(pos[1], pos[2], pos[3])
    if block == nil or block.id ~= 'minecraft:log' then return false end

    local floor = getBlock(pos[1], pos[2]-1, pos[3])
    if floor == nil or floor.id ~= 'minecraft:dirt' then return false end

    return true
end

wood.cutTree = function(pos, timeout)
    local treeBox = Calc.createBox(pos, {2, 2, 2})
    local success = Walk.walkTo(treeBox, 50)
    if success == false then return false end

    Inventory.sortHotbar()
    Action.breakNearbyBlocks('minecraft:log', timeout, {2, 2, 2})

    treeBox = Calc.createBox(pos, {1, 2, 1})
    success = Walk.walkTo(treeBox, 50)
    if success == false then return false end
    Action.breakNearbyBlocks('minecraft:log', timeout, {2, 5, 2})
end

wood.collectTree = function(quantity)
    quantity = quantity or 4
    local count = Inventory.countItems('minecraft:log')
    local goal = count + quantity
    while count < goal do
        local tree = World.searchStructure(wood.isTree, 7)
        if tree == nil then return false end

        wood.cutTree(tree)

        local entities = getEntityList()
        for i = 1, #entities do
            local entity = getEntity(entities[i].id)
            if entity ~= false and string.find(entity.name, 'item.tile.log') then
                local pos = entity.pos
                local box = Calc.createBox(pos, 1.2)
                Walk.walkTo(box, 50)
            end
        end
        count = Inventory.countItems('minecraft:log')
    end
    return true
end

return wood
