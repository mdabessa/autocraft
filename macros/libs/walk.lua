local walk = {}

walk.intangibleBlocks = {
    ['minecraft:air'] = true,
    ['minecraft:cave_air'] = true,
    ['minecraft:cobweb'] = true,
    ['minecraft:grass'] = true,
    ['minecraft:fern'] = true,
    ['minecraft:dead_bush'] = true,
    ['minecraft:sea_pickle'] = true,
    ['minecraft:dandelion'] = true,
    ['minecraft:poppy'] = true,
    ['minecraft:blue_orchid'] = true,
    ['minecraft:allium'] = true,
    ['minecraft:azure_bluet'] = true,
    ['minecraft:red_tulip'] = true,
    ['minecraft:orange_tulip'] = true,
    ['minecraft:white_tulip'] = true,
    ['minecraft:pink_tulip'] = true,
    ['minecraft:oxeye_daisy'] = true,
    ['minecraft:cornflower'] = true,
    ['minecraft:brown_mushroom'] = true,
    ['minecraft:red_mushroom'] = true,
    ['minecraft:torch'] = true,
    ['minecraft:ladder'] = true,
    ['minecraft:snow'] = true,
    ['minecraft:vine'] = true,
    ['minecraft:lily_pad'] = true,
    ['minecraft:sunflower'] = true,
    ['minecraft:lilac'] = true,
    ['minecraft:rose_bush'] = true,
    ['minecraft:tall_grass'] = true,
    ['minecraft:large_fern'] = true,
    ['minecraft:painting'] = true,
    ['minecraft:item_frame'] = true,
    ['minecraft:repeater'] = true,
    ['minecraft:comparator'] = true,

}

walk.placeableBlocks = {
    ['minecraft:dirt'] = true,
    ['minecraft:cobblestone'] = true,
    ['minecraft:planks'] = true, -- #TODO: convert with dictonary
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
    local id = Dictionary.getGroup(block.id)
    return id
end

walk.solidBlock = function(block_id)
    if walk.intangibleBlocks[block_id] then return false end

    if string.find(block_id, 'sapling') then return false end
    if string.find(block_id, 'carpet') then return false end
    if string.find(block_id, 'coral') then return false end
    if string.find(block_id, 'sign') then return false end
    if string.find(block_id, 'banner') then return false end
    if string.find(block_id, 'pressure_plate') then return false end
    if string.find(block_id, 'button') then return false end
    if string.find(block_id, 'rail') then return false end
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

walk.neighbors = function(current, max_jump, max_fall, canPlace, canBreak)
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
    if canPlace then
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
    end

    if canBreak then
        for i = -1, 1 do
            for j = -1, 1 do
                if (math.abs(i) + math.abs(j) == 2) or (i==0 and j==0) then goto continue end
                local pos = {current['pos'][1] + i, current['pos'][2], current['pos'][3] + j}
                local pos1 = {current['pos'][1] + i, current['pos'][2]+1, current['pos'][3] + j}
                local mask = {}
                for key, value in pairs(current['mask']) do mask[key] = value end
                mask[Calc.pointToStr(pos)] = 'minecraft:air'
                mask[Calc.pointToStr(pos1)] = 'minecraft:air'
                local block = walk.walkableBlock(pos, current['pos'], max_jump, max_fall, mask)
                if block ~= nil then
                    local node = {
                        ['pos'] = block,
                        ['mask'] = mask,
                        ['mask_length'] = current['mask_length'] + 2,
                        ['max_place'] = current['max_place'],
                        ['break'] = {
                            pos,
                            pos1
                        }
                    }
                    table.insert(neighbors, node)
                end
                ::continue::
            end
        end

        for i = -1, 1 do
            for j = -1, 1 do
                if (math.abs(i) + math.abs(j) == 2) or (i==0 and j==0) then goto continue end
                local pos = {current['pos'][1] + i, current['pos'][2], current['pos'][3] + j}
                local pos1 = {current['pos'][1] + i, current['pos'][2]+1, current['pos'][3] + j}
                local pos2 = {current['pos'][1] + i, current['pos'][2]-1, current['pos'][3] + j}
                local mask = {}
                for key, value in pairs(current['mask']) do mask[key] = value end
                mask[Calc.pointToStr(pos)] = 'minecraft:air'
                mask[Calc.pointToStr(pos1)] = 'minecraft:air'
                mask[Calc.pointToStr(pos2)] = 'minecraft:air'

                local block = walk.walkableBlock(pos, current['pos'], max_jump, max_fall, mask)
                if block ~= nil then
                    local node = {
                        ['pos'] = block,
                        ['mask'] = mask,
                        ['mask_length'] = current['mask_length'] + 3,
                        ['max_place'] = current['max_place'],
                        ['break'] = {
                            pos,
                            pos1,
                            pos2
                        }
                    }
                    table.insert(neighbors, node)
                end
                ::continue::
            end
        end
    end
    return neighbors
end

walk.heuristic = function(point1, point2)
    return Calc.distance3d(point1, point2)
end

walk.pathFinder = function(objective, pathFinderConfig)
    pathFinderConfig = pathFinderConfig or {}
    local maxJump = pathFinderConfig.maxJump or 1
    local maxFall = pathFinderConfig.maxFall or 5
    local pathFinderTimeout = pathFinderConfig.pathFinderTimeout or 10
    local reverse = pathFinderConfig.reverse or false
    local weightMask = pathFinderConfig.weightMask or 1
    if pathFinderConfig.canPlace == nil then pathFinderConfig.canPlace = true end
    if pathFinderConfig.canBreak == nil then pathFinderConfig.canBreak = true end
    local canPlace = pathFinderConfig.canPlace
    local canBreak = pathFinderConfig.canBreak

    local start = os.time()

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
        if os.time() - start > pathFinderTimeout then return nil end
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

        local neighbors_ = walk.neighbors(current, maxJump, maxFall, canPlace, canBreak)
        for _, neighbor in pairs(neighbors_) do
            if pathFinderConfig.denylist_positions[Calc.pointToStr(neighbor['pos'])] ~= nil then goto continue end
            if list_open_ref[Calc.pointToStr(neighbor['pos'])] == nil and
                list_closed[Calc.pointToStr(neighbor['pos'])] == nil then

                local weight = walk.heuristic(neighbor['pos'], end_pos)
                if reverse then weight = -weight end
                weight = weight + (neighbor['mask_length'] * weightMask)

                neighbor['heuristic'] = weight
                neighbor['parent'] = current

                local index = Calc.binary_search(list_open, neighbor, function(x) return x['heuristic'] end)
                table.insert(list_open, index, neighbor)

                list_open_ref[Calc.pointToStr(neighbor['pos'])] = true
            end
            ::continue::
        end

        list_closed[Calc.pointToStr(current['pos'])] = true
    end
    Logger.log("Path not found")
end

walk.move = function(node)
    local player = getPlayer()
    local time = os.time()

    local to = node['pos']

    if node['place'] ~= nil then
        local face = node['place']['face']
        local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}

        lookAt(face[1], face[2], face[3])
        sleep(200)

        local block = walk.getBlockId(face)
        if block ~= 'minecraft:air' and walk.solidBlock(block) == false then
            lookAt(face[1]+0.5, face[2], face[3]+0.5)
            sleep(200)
            Action.dig()
        end

        if pos[1] - face[1] == 0 and pos[2] - face[2] == 0 and pos[3] - face[3] == 0 then
            while true do
                jump(1)
                lookAt(face[1]+0.5, face[2], face[3]+0.5)

                walk.fastPlace()

                block = walk.getBlockId(face)
                if block ~= 'minecraft:air' then break end
                sleep(100)
                if os.time() - time > 3 then
                    error("Player taking too long to place blocks")
                end
            end

        else
            walk.fastPlace()
        end
    end

    if node['break'] ~= nil then
        local blocks = node['break']
        for i = 1, #blocks do
            local pos = blocks[i]
            while true do
                local block = getBlock(pos[1], pos[2], pos[3])
                if walk.solidBlock(block.id) == false then break end
                if Miner.checkPickaxeLevel(block.id) == false then
                    Inventory.sortHotbar()
                end

                lookAt(pos[1]+0.5, pos[2]+0.5, pos[3]+0.5)
                Action.dig()
                sleep(100)

                if os.time() - time > (3*#blocks) then
                    error("Player taking too long to break blocks")
                end
            end
        end
    end

    time = os.time()
    while true do
        local now = os.time()
        if now - time > 3 then
            error("Player stuck")
        end

        player = getPlayer()
        local from = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
        if Calc.compareArray(from, to) then
            return
        end

        local block = getBlock(from[1], from[2], from[3])
        if block ~= nil and block.id == 'minecraft:water' then
            key("SPACE", 1)
        end

        if to[2] > player.pos[2] then jump(1) end

        local yaw = math.atan2((to[3]+0.5) - player.pos[3], (to[1]+0.5) - player.pos[1]) * 180 / math.pi - 90
        local old_yaw = player.yaw

        local step = (yaw - old_yaw)/20
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
    while #path > 0 do
        if #path > 2 then
            local dx = math.abs(path[1]["pos"][1] - path[3]["pos"][1])
            local dy = math.abs(path[1]["pos"][2] - path[2]["pos"][2])
            local dz = math.abs(path[1]["pos"][3] - path[3]["pos"][3])

            if ((dx==0 or dz==0) or (dx==2 and dz==2)) and dy==0 then
                sprint(true)
            end
        end
        walk.move(path[1])
        sprint(false)
        table.remove(path, 1)
    end
end

walk.walkTo = function(to, steps, pathFinderConfig)
    steps = steps or 50
    pathFinderConfig = pathFinderConfig or {}
    pathFinderConfig.denylist_positions = pathFinderConfig.denylist_positions or {}
    local reverse = pathFinderConfig.reverse or false

    local errors_count = 0
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

        local path = walk.pathFinder(box, pathFinderConfig)
        if path == nil then
            error('Walk: Cannot find a valid path to the objective')
        else
            local status, err = pcall(walk.followPath, path)
            if not status then
                errors_count = errors_count + 1
                if errors_count >= 3 then
                    error(Str.errorResume(err))
                elseif errors_count == 2 then
                    local _pos = path[1]["pos"]
                    pathFinderConfig.denylist_positions[Calc.pointToStr(_pos)] = true
                end
            else
                errors_count = 0
            end
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
    pathFinderArgs = pathFinderArgs or {}
    pathFinderArgs['canPlace'] = false
    pathFinderArgs['canBreak'] = false
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
