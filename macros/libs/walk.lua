local walk = {}

walk.intangibleBlocks = {
    ['minecraft:air'] = true,
    ['minecraft:sapling'] = true,
    ['minecraft:web'] = true,
    ['minecraft:tallgrass'] = true,
    ['minecraft:deadbush'] = true,
    ['minecraft:yellow_flower'] = true,
    ['minecraft:red_flower'] = true,
    ['minecraft:brown_mushroom'] = true,
    ['minecraft:red_mushroom'] = true,
    ['minecraft:torch'] = true,
    ['minecraft:snow_layer'] = true,
    ['minecraft:carpet'] = true,
    ['minecraft:double_plant'] = true,
    ['minecraft:painting'] = true,
    ['minecraft:sign'] = true,
    ['minecraft:item_frame'] = true,
    ['minecraft:flower_pot'] = true,
    ['minecraft:skull'] = true,
    ['minecraft:banner'] = true,
    ['minecraft:lever'] = true,
    ['minecraft:stone_pressure_plate'] = true,
    ['minecraft:wooden_pressure_plate'] = true,
    ['minecraft:redstone_torch'] = true,
    ['minecraft:stone_button'] = true,
    ['minecraft:tripwire_hook'] = true,
    ['minecraft:wooden_button'] = true,
    ['minecraft:light_weighted_pressure_plate'] = true,
    ['minecraft:heavy_weighted_pressure_plate'] = true,
    ['minecraft:daylight_detector'] = true,
    ['minecraft:redstone_wire'] = true,
    ['minecraft:repeater'] = true,
    ['minecraft:unpowered_comparator'] = true,
    ['minecraft:powered_comparator'] = true,
    ['minecraft:golden_rail'] = true,
    ['minecraft:detector_rail'] = true,
    ['minecraft:rail'] = true,
    ['minecraft:activator_rail'] = true,
    ['minecraft:tripwire'] = true,
    ['minecraft:wheat'] = true,
    ['minecraft:potatoes'] = true,
    ['minecraft:carrots'] = true,
    ['minecraft:beetroots'] = true,
    ['minecraft:melon_stem'] = true,
    ['minecraft:pumpkin_stem'] = true,
    ['minecraft:attached_melon_stem'] = true,
    ['minecraft:attached_pumpkin_stem'] = true,
    ['minecraft:reeds'] = true
}

walk.placeableBlocks = {
    ['minecraft:dirt'] = true,
    ['minecraft:cobblestone'] = true,
    ['minecraft:planks'] = true,
}

walk.fastPlace = function ()
    local inv = openInventory()
    local map = inv.mapping.inventory
    local slot = map.hotbar[Inventory.getHotbarSlot('placeable')]
    local item = inv.getSlot(slot)

    if not walk.placeableBlocks[item] then
        local success = false
        for i, _ in pairs(walk.placeableBlocks) do
            item = Inventory.findItem(i)
            if next(item) ~= nil then
                local _slot, _ = next(item)
                inv.swap(slot, _slot)
                setHotbar(Inventory.getHotbarSlot('placeable'))
                sleep(100)
                success = true
                break
            end
        end
        if not success then return false end
    end
    use()
    sleep(100)
    return true
end

walk.getBlockId = function(pos, mask)
    if mask == nil then mask = {} end

    if mask[Calc.pointToStr(pos)] ~= nil then
        return mask[Calc.pointToStr(pos)]
    end

    local block = getBlock(pos[1], pos[2], pos[3])
    if block == nil then return nil end
    return block.id
end

walk.solidBlock = function(block_id)
    if walk.intangibleBlocks[block_id] then return false end

    if string.find(block_id, 'double_slab') then return true end
    if string.find(block_id, 'slab') then return false end

    return true
end

walk.walkableBlock = function(pos, from, max_jump, max_fall, mask)
    -- Check if the position is walkable and return the position.
    -- If it is a position that has to be make a extra moviment, like jumping or falling,
    -- it will be necessary to return the position that the player will be after the moviment.
    -- If the position is not walkable, return nil

    max_fall = max_fall or 5
    max_jump = max_jump or 1
    for i = -max_fall, max_jump do
        -- water
        if walk.getBlockId({pos[1], pos[2]+i-1, pos[3]}, mask) == 'minecraft:water' then
            local c = i-1
            while true do
                c = c + 1
                if walk.getBlockId({pos[1], pos[2]+c, pos[3]}, mask) == 'minecraft:water' then
                    goto inner_continue
                end
                if walk.getBlockId({pos[1], pos[2]+c, pos[3]}, mask) == 'minecraft:air' then
                    return {pos[1], pos[2]+c-1, pos[3]}
                end
                do return nil end
                ::inner_continue::
            end
        end

        -- space to walk
        if walk.solidBlock(walk.getBlockId({pos[1], pos[2]+i, pos[3]}, mask)) then goto continue end
        if walk.solidBlock(walk.getBlockId({pos[1], pos[2]+i+1, pos[3]}, mask)) then goto continue end

        -- diagonal
        if pos[1] ~= from[1] and pos[3] ~= from[3] then
            if walk.solidBlock(walk.getBlockId({pos[1], from[2], from[3]}, mask)) then goto continue end
            if walk.solidBlock(walk.getBlockId({pos[1], from[2]+1, from[3]}, mask)) then goto continue end

            if walk.solidBlock(walk.getBlockId({from[1], from[2], pos[3]}, mask)) then goto continue end
            if walk.solidBlock(walk.getBlockId({from[1], from[2]+1, pos[3]}, mask)) then goto continue end
        end

        if i < 0 then
            for j = i, 0 do -- space to fall
                if walk.solidBlock(walk.getBlockId({pos[1], pos[2]+j+1, pos[3]}, mask)) then goto continue end
            end
        elseif i > 0 then
            for j = 0, i do -- space to jump
                if walk.solidBlock(walk.getBlockId({pos[1], pos[2]+j+i, pos[3]}, mask)) then goto continue end
                if walk.solidBlock(walk.getBlockId({from[1], from[2]+j+i, from[3]}, mask)) then goto continue end
            end
        end

        -- floor to walk
        if walk.getBlockId({pos[1], pos[2]+i-1, pos[3]}, mask) == nil then goto continue end
        if not walk.solidBlock(walk.getBlockId({pos[1], pos[2]+i-1, pos[3]}, mask)) then goto continue end
        if walk.getBlockId({pos[1], pos[2]+i-1, pos[3]}, mask) == 'minecraft:lava' then goto continue end

        do return {pos[1], pos[2]+i, pos[3]} end
        :: continue ::
    end
end

walk.neighbors = function(current, max_jump, max_fall)
    local neighbors = {}
    for i = -1, 1 do
        for j = -1, 1 do
            if i == 0 and j == 0 then goto continue end -- No self

            local pos = {current['pos'][1] + i, current['pos'][2], current['pos'][3] + j}
            local block = walk.walkableBlock(pos, current['pos'], max_jump, max_fall, current['mask'])
            if block ~= nil then
                local node = {
                    ['pos'] = block,
                    ['mask'] = current['mask'],
                    ['mask_length'] = current['mask_length'],
                    ['max_place'] = current['max_place'],
                }
                table.insert(neighbors, node)
            end
            :: continue ::
        end
    end

    -- place blocks
    if current['max_place'] > 0 then
        local mask = {}
        for k, v in pairs(current['mask']) do mask[k] = v end
        mask[Calc.pointToStr(current['pos'])] = 'minecraft:cobblestone'

        local pos = {current['pos'][1], current['pos'][2]+1, current['pos'][3]}
        local block = walk.walkableBlock(pos, current['pos'], max_jump, max_fall, mask)
        if block ~= nil then
            local node = {
                ['pos'] = block,
                ['mask'] = mask,
                ['mask_length'] = current['mask_length'] + 1,
                ['place'] = {
                    ['pos'] = pos,
                    ['face'] = {current['pos'][1], current['pos'][2], current['pos'][3]},
                },
                ['max_place'] = current['max_place'] - 1,
            }
            table.insert(neighbors, node)
        end
    end

    return neighbors
end

walk.heuristic = function(point1, point2)
    return Calc.distance3d(point1, point2)
end

walk.pathFinder = function(objective, max_jump, max_fall, pathFinderTimeout, reverse)
    pathFinderTimeout = pathFinderTimeout or 10
    local start = os.clock()

    local pos = getPlayer().pos
    local start_pos = {math.floor(pos[1]), math.floor(pos[2]), math.floor(pos[3])}
    local end_pos = Calc.centerBox(objective)

    local max_place = 0
    for key, value in pairs(walk.placeableBlocks) do
        max_place = max_place + Inventory.countItems(key)
    end

    if Calc.inBox(start_pos, objective) and not reverse then return {} end
    if not Calc.inBox(start_pos, objective) and reverse then return {} end

    local h = walk.heuristic(start_pos, end_pos)
    if reverse then h = -h end

    local list_open = {
        {
            ['pos'] = {start_pos[1], start_pos[2], start_pos[3]},
            ['heuristic'] = h,
            ['mask'] = {},
            ['mask_length'] = 0,
            ['max_place'] = max_place,
            ['parent'] = nil
        }
    }
    local list_closed = {}
    local list_open_ref = {}

    while #list_open > 0 do
        if os.clock() - start > pathFinderTimeout then return nil end
        local current = table.remove(list_open, 1)

        if (Calc.inBox(current['pos'], objective) and not reverse) or
            (not Calc.inBox(current['pos'], objective) and reverse) then
            local path = {}
            local cell = current
            while Calc.compareArray(cell['pos'], start_pos) == false do
                table.insert(path, cell)
                cell = cell['parent']
            end

            local path_ = {}
            for i = #path, 1, -1 do
                table.insert(path_, path[i])
            end
            return path_
        end

        local neighbors_ = walk.neighbors(current, max_jump, max_fall)
        for _, neighbor in pairs(neighbors_) do
            if list_open_ref[Calc.pointToStr(neighbor['pos'])] == nil and
                list_closed[Calc.pointToStr(neighbor['pos'])] == nil then

                local weight = walk.heuristic(neighbor['pos'], end_pos)
                if reverse then weight = -weight end
                weight = weight + (neighbor['mask_length'] *3)

                neighbor['heuristic'] = weight
                neighbor['parent'] = current

                local index = Calc.binary_search(list_open, neighbor, function(x) return x['heuristic'] end)
                table.insert(list_open, index, neighbor)

                list_open_ref[Calc.pointToStr(neighbor['pos'])] = true
            end
        end

        list_closed[Calc.pointToStr(current['pos'])] = true
    end
    log("Path not found")
end

walk.move = function(node)
    local player = getPlayer()
    local time = os.clock()

    local to = node['pos']

    if node['place'] ~= nil then
        local face = node['place']['face']
        local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}

        lookAt(face[1], face[2], face[3])
        sleep(200)

        if pos[1] - face[1] == 0 and pos[2] - face[2] == 0 and pos[3] - face[3] == 0 then
            while true do
                jump(1)
                lookAt(face[1]+0.5, face[2], face[3]+0.5)

                walk.fastPlace()

                local block = getBlock(face[1], face[2], face[3])
                if block ~= nil and block.id ~= 'minecraft:air' then break end
                sleep(100)
                if os.clock() - time > 3 then return false end
            end

        else
            walk.fastPlace()
        end
    end

    while true do
        local now = os.clock()
        if now - time > 3 then -- player stuck
            return false
        end

        player = getPlayer()
        local from = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
        if Calc.compareArray(from, to) then
            return true
        end

        local block = getBlock(from[1], from[2], from[3])
        if block ~= nil and block.id == 'minecraft:water' then
            key("SPACE", 1)
        end

        if to[2] > player.pos[2] then jump(1) end

        local yaw = math.atan2((to[3]+0.5) - player.pos[3], (to[1]+0.5) - player.pos[1]) * 180 / math.pi - 90
        local old_yaw = player.yaw

        local step = (yaw - old_yaw)/10
        local next = old_yaw + step
        if yaw - next < 1 then next = yaw end

        local diff = yaw - next

        if not Calc.compareArray({from[1], from[3]}, {to[1], to[3]}) then
            look(next, 0)
        end

        if (diff  < 90 and diff > -90) then
            forward(1)
        else
            back(1)
        end

        if (diff > 45 and diff < 135)then
            right(1)
        elseif (diff < -45 and diff > -135)then
            left(1)
        end
    end
end

walk.followPath = function(path)
    for i = 1, #path do
        local success = walk.move(path[i])
        if not success then
            return false
        end
    end
    return true
end

walk.walkTo = function(to, steps, pathFinderArgs, reverse)
    steps = steps or 50
    pathFinderArgs = pathFinderArgs or {1, 5, 10} -- max_jump, max_fall, pathFinderTimeout
    reverse = reverse or false

    while true do
        local player = getPlayer()
        local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
        local box = to
        local center = Calc.centerBox(to)
        center[2] = pos[2]
        local dist = Calc.distance3d(player.pos, center)

        if Calc.inBox(pos, box) and not reverse then return true end
        if not Calc.inBox(pos, box) and reverse then return true end

        if dist > steps and not reverse then
            local angle = Calc.direction(pos, center)
            local new_point = Calc.directionToPoint(pos, angle, steps)
            box = Calc.createBox(new_point, 10)
            box[1][2] = 0
            box[2][2] = 255
        end

        local path = walk.pathFinder(box, pathFinderArgs[1], pathFinderArgs[2], pathFinderArgs[3], reverse)
        if path == nil then
            return false
        else
            if #path/steps < 0.6 then -- if the path is simple, sprint
                sprint(true)
            end
            walk.followPath(path)
            sprint(false)
        end
    end
end

walk.walkAway = function (distance, angle)
    distance = distance or 50
    local player = getPlayer()

    angle = angle or math.random(0, 360)
    local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
    local new_point = Calc.directionToPoint(pos, angle, distance)
    local box = Calc.createBox(new_point, 10)
    box[1][2] = 0
    box[2][2] = 255

    return walk.walkTo(box)
end

walk.followEntity = function(entity_id, min_dist, continue, pathFinderArgs)
    min_dist = min_dist or 5
    continue = continue or false
    pathFinderArgs = pathFinderArgs or {1, 5, 10} -- max_jump, max_fall, pathFinderTimeout

    while true do
        local player = getPlayer()
        local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
        local entity = getEntity(entity_id)
        if entity == nil then return true end
        local entity_pos = {math.floor(entity.pos[1]), math.floor(entity.pos[2]), math.floor(entity.pos[3])}
        local dist = Calc.distance3d(pos, entity_pos)
        if dist < min_dist then
            if continue then
                goto continue
            else
                return true
            end
        end
        local box = Calc.createBox(entity_pos, min_dist)
        walk.walkTo(box, 50, pathFinderArgs)
        :: continue ::
    end
end

return walk
