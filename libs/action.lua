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
    local block = getBlock(pos[1], pos[2], pos[3])
    local actual = getPlayer().lookingAt
    local _block = getBlock(actual[1], actual[2], actual[3])

    local faces = action.blockFaces(pos)
    for i = 1, #faces do
        if block.id == _block.id then return true end

        local face = faces[i]
        lookAt(face.pos[1], face.pos[2], face.pos[3])
        sleep(100)

        actual = getPlayer().lookingAt
        _block = getBlock(actual[1], actual[2], actual[3])
    end

    return false
end

action.pointIsVisible = function (from, to, resolution)
    resolution = resolution or 10 -- resolution is the number that multiplies the distance to check from the player to the block
    local steps = Calc.distance3d(from, to) * resolution

    for i = 1, steps do
        local pos = {}
        for j = 1, 3 do
            pos[j] = from[j] + ((to[j] - from[j]) * (i / steps))
        end
        for j = 1, 3 do
            pos[j] = math.floor(pos[j])
        end
        local block = getBlock(pos[1], pos[2], pos[3])
        if not block then return false end
        if Walk.solidBlock(block.id) then return false end
    end
    return true
end

action.blockFaces = function(pos)
    local player_eyes = {getPlayer().pos[1], getPlayer().pos[2] + 1.62, getPlayer().pos[3]}
    local faces = {}
    for i=1, 3 do
        for j=-1, 1, 2 do
            local _pos = {pos[1], pos[2], pos[3]}
            _pos[i] = _pos[i] + j
            local block = getBlock(_pos[1], _pos[2], _pos[3])
            if not block then goto continue end

            local face = {pos[1], pos[2], pos[3]}

            for k=1, 3 do
                face[k] = face[k] + 0.5
            end

            face[i] = face[i] + (0.5*j)

            local is_player_side = false
            local d = player_eyes[i] - face[i]
            if d > 0 and j == 1 then is_player_side = true end
            if d < 0 and j == -1 then is_player_side = true end

            local is_visible = action.pointIsVisible(player_eyes, face)


            local face_ = {
                pos = face,
                neighbor = _pos,
                is_visible = is_visible,
                is_player_side = is_player_side
            }
            table.insert(faces, face_)

            :: continue ::
        end
    end
    return faces
end

action.blockIsVisible = function(x, y, z)
    local pos = {x, y, z}
    local faces = action.blockFaces(pos)
    for i=1, #faces do
        if faces[i].is_visible then
            return true end
    end
    return false
end

action.placeBlock = function(block_id, pos)
    local pos_ = getPlayer().pos

    if pos == nil then
        pos = {pos_[1], pos_[2], pos_[3]} -- temporary
    else
        if Calc.distance3d(pos_, pos) > 4 then return false end
    end

    -- walk away from block to have space to place it
    local box = Calc.createBox(pos, 2)
    if not Walk.walkTo(box, 50, {1, 1, 1}, true) then return false end

    local inv = openInventory()
    local map = inv.mapping.inventory
    local item = Inventory.findItem(block_id, map)

    if next(item) == nil then return false end
    local slot, _ = next(item)
    local hotbar_slot = Inventory.getHotbarSlot('placeable')
    if slot ~= map.hotbar[hotbar_slot] then
        inv.swap(slot, map.hotbar[hotbar_slot])
    end

    setHotbar(hotbar_slot)
    sleep(100)

    action.breakFlower(pos) -- break flower if there is one

    local faces = action.blockFaces(pos)
    local face = nil
    for i=1, #faces do
        if faces[i].is_visible and not faces[i].is_player_side then
            local neighbor = getBlock(faces[i].neighbor[1], faces[i].neighbor[2], faces[i].neighbor[3])
            if not Walk.solidBlock(neighbor.id) then goto continue end
            face = faces[i]
            break
        end
        :: continue ::
    end

    if face == nil then return false end
    lookAt(face.pos[1], face.pos[2], face.pos[3])
    sleep(100)
    use()
    sleep(100)

    local block = getBlock(pos[1], pos[2], pos[3])
    if not block or block.id ~= block_id then return false end
    return true
end

action.breakFlower = function (pos)
    local block = getBlock(pos[1], pos[2], pos[3])
    if block.id == 'minecraft:air' then return true end

    local steps = 3
    for i=1, steps do
        for j = 1, steps do
            for k = 1, steps do
                local look = {pos[1] + (i/steps), pos[2] + (j/steps), pos[3] + (k/steps)}
                lookAt(look[1], look[2], look[3])
                sleep(100)
                attack(100)
                sleep(100)

                block = getBlock(pos[1], pos[2], pos[3])
                if block == nil or block == false then return false end
                if block.id == 'minecraft:air' then return true end
            end
        end
    end
end

return action
