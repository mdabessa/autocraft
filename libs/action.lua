local action = {}

action.dig = function()
    local lookingPos = getPlayer().lookingAt
    local actualLookingPos = {lookingPos[1], lookingPos[2], lookingPos[3]}
    local block = getBlock(lookingPos[1], lookingPos[2], lookingPos[3])
    local tool_slot = Inventory.getHotbarSlot(block.harvestTool)
    setHotbar(tool_slot)

    attack(0)
    sleep(100)
    local start = os.clock()
    while Calc.compareArray(actualLookingPos, lookingPos) do
        attack(-1)
        actualLookingPos = getPlayer().lookingAt
        if os.clock() - start > 5 then
            attack(0)
            return false
        end
    end
    attack(0)
    return true
end

action.safeDig = function()
    local lookingPos = getPlayer().lookingAt

    for i=-1, 1, 2 do
        for j=1, 3 do
            local pos = {lookingPos[1], lookingPos[2], lookingPos[3]}
            pos[j] = pos[j] + i
            local block = getBlock(pos[1], pos[2], pos[3])
            if block == nil then return false end
            if block.id == 'minecraft:water' or block.id == 'minecraft:lava' then
                return false
            end
        end
    end
    return action.dig()
end

action.breakNearbyBlocks = function(block_id, timeout, range)
    timeout = timeout or 3
    range = range or 2
    if type(range) == 'number' then range = {range, range, range} end

    local player = getPlayer()
    local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
    local time = os.clock()
    local block_list = {}
    while true do
        if os.clock() - time > timeout then break end
        for i = -range[1], range[1] do
            for j=-range[2], range[2] do
                for k=-range[3], range[3] do
                    if block_list[{pos[1]+i, pos[2]+j, pos[3]+k}] then goto continue end

                    local block = getBlock(pos[1]+i, pos[2]+j, pos[3]+k)
                    if block ~= nil and block.id == block_id then
                        lookAt(pos[1]+i+0.5, pos[2]+j+0.5, pos[3]+k+0.5)
                        local s = Action.dig()
                        if s == false then
                            block_list[{pos[1]+i, pos[2]+j, pos[3]+k}] = true
                        end

                        time = os.clock()
                        goto continue
                    end
                end
            end
        end
        break
        :: continue ::
    end
end

action.pickupNearbyItems = function(item_entity_id, distance)
    distance = distance or 5
    local entities = getEntityList()
    for i = 1, #entities do
        local entity = getEntity(entities[i].id)
        if entity ~= false and string.find(entity.name, item_entity_id) then
            local pos = entity.pos
            local player = getPlayer().pos
            if Calc.distance3d(pos, player) < distance then
                local box = Calc.createBox(pos, 1.2)
                Walk.walkTo(box, 50, {1, 5, 1})
            end
        end
    end
end

return action
