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

action.pickupNearbyItems = function(item_entity_id, distance, timeout)
    distance = distance or 5
    timeout = timeout or 1
    local entities = getEntityList()
    for i = 1, #entities do
        local entity = getEntity(entities[i].id)
        if entity ~= false and string.find(entity.name, item_entity_id) then
            local pos = entity.pos
            local player = getPlayer().pos
            if Calc.distance3d(pos, player) < distance then
                local box = Calc.createBox(pos, 1.2)
                Walk.walkTo(box, 50, {1, 5, timeout})
            end
        end
    end
end

action.lookAtBlock = function(x,y,z)
    local pos = {x, y, z}
    lookAt(pos[1]+0.5, pos[2]+0.5, pos[3]+0.5)
    sleep(100)
    local actual = getPlayer().lookingAt

    for i = 1, 3 do
        for j = -1, 1, 2 do
            local block = getBlock(pos[1], pos[2], pos[3])
            local _block = getBlock(actual[1], actual[2], actual[3])
            if block.id == _block.id then return end

            local _pos = {pos[1]+0.5, pos[2]+0.5, pos[3]+0.5}
            _pos[i] = _pos[i] + (0.5*j)
            lookAt(_pos[1], _pos[2], _pos[3])
            sleep(100)
            actual = getPlayer().lookingAt
        end
    end

end

action.blockIsVisible = function(x,y,z, resolution)
    resolution = resolution or 10 -- resolution is the number that multiplies the steps to check from the player to the block

    local obj = {x, y, z}
    local pos = {getPlayer().pos[1], getPlayer().pos[2]+1, getPlayer().pos[3]}
    local delta = {obj[1] - pos[1], obj[2] - pos[2], obj[3] - pos[3]}

    for i=1, 3 do
        local posL = {}
        for j = 1, 3 do
            if obj[j] > 0 then
                table.insert(posL, obj[j] +0.5)
            else
                table.insert(posL, obj[j] -0.5)
            end
        end

        if delta[i] == 0 then
            goto continue
        else
            local s1 = delta[i] / math.abs(delta[i])
            posL[i] = posL[i] - s1
        end

        local block = getBlock(posL[1], posL[2], posL[3])
        if block == nil or block == false or block.id ~= 'minecraft:air' then
            goto continue
        end

        local d = {posL[1] - pos[1], posL[2] - pos[2], posL[3] - pos[3]}
        local step = math.max(math.abs(d[1]), math.abs(d[2]), math.abs(d[3])) * resolution
        while true do
            pos = {pos[1] + d[1] / step, pos[2] + d[2] / step, pos[3] + d[3] / step}

            local matches = 0
            for j=1, 3 do
                if math.floor(pos[j]) == math.floor(posL[j]) then
                    matches = matches + 1
                end
            end
            if matches == 3 then break end

            block = getBlock(pos[1], pos[2], pos[3])
            if block == nil or block == false or block.id ~= 'minecraft:air' then
                goto continue
            end
        end
        do return true end
        :: continue ::
    end
    return false
end

return action
