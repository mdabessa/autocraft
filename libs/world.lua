local world = {}

world.intangibleBlocks = {
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

world.solidBlock = function(block)
    if block == nil then return true end
    local block_id = block.id
    if world.intangibleBlocks[block_id] then return false end

    if string.find(block_id, 'double_slab') then return true end
    if string.find(block_id, 'slab') then return false end

    return true
end

world.walkableBlock = function(pos, from, max_jump, max_fall)
    -- Check if the position is walkable and return the position.
    -- If it is a position that has to be make a extra moviment, like jumping or falling,
    -- it will be necessary to return the position that the player will be after the moviment.
    -- If the position is not walkable, return nil

    max_fall = max_fall or 5
    max_jump = max_jump or 1
    for i = -max_fall, max_jump do
        if getBlock(pos[1], pos[2]+i-1, pos[3]).id == 'minecraft:water' then
            local c = i-1
            while true do
                c = c + 1
                if getBlock(pos[1], pos[2]+c, pos[3]).id == 'minecraft:water' then
                    goto inner_continue
                end
                if getBlock(pos[1], pos[2]+c, pos[3]).id == 'minecraft:air' then
                    return {pos[1], pos[2]+c-1, pos[3]}
                end
                do return nil end
                ::inner_continue::
            end
        end

        --has space?
        if world.solidBlock(getBlock(pos[1], pos[2]+i, pos[3])) then goto continue end
        if world.solidBlock(getBlock(pos[1], pos[2]+i+1, pos[3])) then goto continue end
        -- is diagonal?
        if pos[1] ~= from[1] and pos[3] ~= from[3] then
            if world.solidBlock(getBlock(pos[1], from[2], from[3])) then goto continue end
            if world.solidBlock(getBlock(pos[1], from[2]+1, from[3])) then goto continue end

            if world.solidBlock(getBlock(from[1], from[2], pos[3])) then goto continue end
            if world.solidBlock(getBlock(from[1], from[2]+1, pos[3])) then goto continue end
        end

        if i < 0 then
            for j = i, 0 do -- space to fall
                if world.solidBlock(getBlock(pos[1], pos[2]+j+1, pos[3])) then goto continue end
            end
        elseif i > 0 then
            for j = 0, i do -- space to jump
                if world.solidBlock(getBlock(pos[1], pos[2]+j+i, pos[3])) then goto continue end
                if world.solidBlock(getBlock(from[1], from[2]+j+i, from[3])) then goto continue end
            end
        end

        --has floor?
        if getBlock(pos[1], pos[2]+i-1, pos[3]) == nil then goto continue end
        if not world.solidBlock(getBlock(pos[1], pos[2]+i-1, pos[3])) then goto continue end
        if getBlock(pos[1], pos[2]+i-1, pos[3]).id == 'minecraft:lava' then goto continue end

        do return {pos[1], pos[2]+i, pos[3]} end
        :: continue ::
    end
end

world.neighbors = function(current, max_jump, max_fall)
    local neighbors = {}
    for i = -1, 1 do
        for j = -1, 1 do
            if i == 0 and j == 0 then goto continue end -- No self

            local pos = {current[1] + i, current[2], current[3] + j}
            local block = world.walkableBlock(pos, current, max_jump, max_fall)
            if block ~= nil then
                table.insert(neighbors, block)
            end
            :: continue ::
        end
    end
    return neighbors
end

world.searchStructure = function(func, timeout, iterator, shape, step)
    timeout = timeout or 5
    local start = os.clock()
    local player = getPlayer()

    local x = math.floor(player.pos[1])
    local y = math.floor(player.pos[2])
    local z = math.floor(player.pos[3])

    iterator = iterator or world.searchInRadius
    iterator = coroutine.wrap(iterator)
    while true do
        if os.clock() - start > timeout then return nil end
        local pos = iterator(shape, step)
        if pos == nil then return nil end
        pos = {pos[1] + x, pos[2] + y, pos[3] + z}
        local result = func(pos)
        if result then return pos end
    end
end

world.searchInRadius = function(shape, step)
    shape = shape or {16, 5, 16}
    step = step or 1
    if type(shape) == 'number' then shape = {shape, shape, shape} end
    if type(step) == 'number' then step = {step, step, step} end

    local m = math.max(shape[1], shape[2], shape[3])
    for i = 0, m do
        for j = -i, i do
            if j > shape[1] or j < -shape[1] then
                goto continue1
            end
            for k = -i, i do
                if k > shape[2] or k < -shape[2] then
                    goto continue2
                end
                for l = -i, i do
                    if l > shape[3] or l < -shape[3] then
                        goto continue3
                    end

                    coroutine.yield({j, k, l})

                    ::continue3::
                end
                ::continue2::
            end
            ::continue1::
        end

        for j = -i+1, i do
            if j > shape[1] or j < -shape[1] then
                goto continue1
            end
            for k = -i, i do
                if k > shape[2] or k < -shape[2] then
                    goto continue2
                end
                for l = -i, i do
                    if l > shape[3] or l < -shape[3] then
                        goto continue3
                    end

                    coroutine.yield({j, k, l})

                    ::continue3::
                end
                ::continue2::
            end
            ::continue1::
        end

        for j = -i+1, i do
            if j > shape[1] or j < -shape[1] then
                goto continue1
            end
            for k = -i+1, i do
                if k > shape[2] or k < -shape[2] then
                    goto continue2
                end
                for l = -i, i do
                    if l > shape[3] or l < -shape[3] then
                        goto continue3
                    end

                    coroutine.yield({j, k, l})

                    ::continue3::
                end
                ::continue2::
            end
            ::continue1::
        end
    end
    return nil
end

return world
