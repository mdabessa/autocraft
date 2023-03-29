local wood = {}

wood.isTree = function(pos)
    local block = getBlock(pos[1], pos[2], pos[3])
    if block == nil then return false end
    if block.id ~= 'minecraft:log' and block.id ~= 'minecraft:leaves' then return false end

    -- search for the root of the tree
    for dx = -2, 2 do
        for dy = -5, 0 do
            for dz = -2, 2 do
                local _block = getBlock(pos[1]+dx, pos[2]+dy, pos[3]+dz)
                if _block == nil or _block.id ~= 'minecraft:log' then goto continue end

                local ground = getBlock(pos[1]+dx, pos[2]+dy-1, pos[3]+dz)
                if ground == nil or ground.id == 'minecraft:air'
                    or ground.id == 'minecraft:log' or ground.id == 'minecraft:leaves'
                    then goto continue end
                do return {pos[1]+dx, pos[2]+dy, pos[3]+dz} end
                ::continue::
            end
        end
    end
    return false
end

wood.cutTree = function(pos, timeout)
    local treeBox = Calc.createBox(pos, {3, 2, 3})
    local success = Walk.walkTo(treeBox, 50)
    if success == false then return false end

    Inventory.sortHotbar()
    Action.breakNearbyBlocks('minecraft:log', timeout, {2, 2, 2})

    treeBox = Calc.createBox(pos, {1, 6, 1})
    success = Walk.walkTo(treeBox, 50)
    if success == false then return false end
    Action.breakNearbyBlocks('minecraft:log', timeout, {2, 5, 2})
end

wood.collectTree = function(quantity)
    quantity = quantity or 4
    local count = Inventory.countItems('minecraft:log')
    local goal = count + quantity
    while count < goal do
        local tree = World.searchStructure(wood.isTree, 7, nil, {30, 10, 30}, 3)
        if tree == nil then
            Walk.walkAway()
            goto continue
        end
        wood.cutTree(tree)

        Action.pickupNearbyItems('item.tile.log')

        count = Inventory.countItems('minecraft:log')
        ::continue::
    end
    return true
end

return wood
