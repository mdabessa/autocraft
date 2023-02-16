local world = {}

world.solidBlock = function(block)
    if block == nil then return true end
    local block_id = block.id

    if block_id == 'minecraft:air' then return false end
    if block_id == 'minecraft:sapling' then return false end
    if block_id == 'minecraft:web' then return false end
    if block_id == 'minecraft:tallgrass' then return false end
    if block_id == 'minecraft:deadbush' then return false end
    if block_id == 'minecraft:yellow_flower' then return false end
    if block_id == 'minecraft:red_flower' then return false end
    if block_id == 'minecraft:brown_mushroom' then return false end
    if block_id == 'minecraft:red_mushroom' then return false end
    if block_id == 'minecraft:torch' then return false end
    if block_id == 'minecraft:snow_layer' then return false end
    if block_id == 'minecraft:carpet' then return false end
    if block_id == 'minecraft:double_plant' then return false end
    if block_id == 'minecraft:painting' then return false end
    if block_id == 'minecraft:sign' then return false end
    if block_id == 'minecraft:item_frame' then return false end
    if block_id == 'minecraft:flower_pot' then return false end
    if block_id == 'minecraft:skull' then return false end
    if block_id == 'minecraft:banner' then return false end
    if block_id == 'minecraft:lever' then return false end
    if block_id == 'minecraft:stone_pressure_plate' then return false end
    if block_id == 'minecraft:wooden_pressure_plate' then return false end
    if block_id == 'minecraft:redstone_torch' then return false end
    if block_id == 'minecraft:stone_button' then return false end
    if block_id == 'minecraft:tripwire_hook' then return false end
    if block_id == 'minecraft:wooden_button' then return false end
    if block_id == 'minecraft:light_weighted_pressure_plate' then return false end
    if block_id == 'minecraft:heavy_weighted_pressure_plate' then return false end
    if block_id == 'minecraft:daylight_detector' then return false end
    if block_id == 'minecraft:redstone_wire' then return false end
    if block_id == 'minecraft:repeater' then return false end
    if block_id == 'minecraft:unpowered_comparator' then return false end
    if block_id == 'minecraft:powered_comparator' then return false end
    if block_id == 'minecraft:golden_rail' then return false end
    if block_id == 'minecraft:detector_rail' then return false end
    if block_id == 'minecraft:rail' then return false end
    if block_id == 'minecraft:activator_rail' then return false end
    if block_id == 'minecraft:tripwire' then return false end
    if block_id == 'minecraft:wheat' then return false end
    if block_id == 'minecraft:potatoes' then return false end
    if block_id == 'minecraft:carrots' then return false end
    if block_id == 'minecraft:beetroots' then return false end
    if block_id == 'minecraft:melon_stem' then return false end
    if block_id == 'minecraft:pumpkin_stem' then return false end
    if block_id == 'minecraft:attached_melon_stem' then return false end
    if block_id == 'minecraft:attached_pumpkin_stem' then return false end
    if block_id == 'minecraft:reeds' then return false end

    if string.find(block_id, 'double_slab') then return true end
    if string.find(block_id, 'slab') then return false end

    return true
end

world.walkableBlock = function(pos, from)
    -- Check if the position is walkable and return the position.
    -- If it is a position that has to be make a extra moviment, like jumping or falling,
    -- it will be necessary to return the position that the player will be after the moviment.
    -- If the position is not walkable, return nil

    local max_fall = 5
    local max_jump = 1
    for i = -max_fall, max_jump do
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
        if getBlock(pos[1], pos[2]+i-1, pos[3]).id == 'minecraft:water' then
            return {pos[1], pos[2]+i-1, pos[3]}
        end
        if not world.solidBlock(getBlock(pos[1], pos[2]+i-1, pos[3])) then goto continue end
        if getBlock(pos[1], pos[2]+i-1, pos[3]).id == 'minecraft:lava' then goto continue end

        do return {pos[1], pos[2]+i, pos[3]} end
        :: continue ::
    end
end

world.neighbors = function(current)
    local neighbors = {}
    for i = -1, 1 do
        for j = -1, 1 do
            if i == 0 and j == 0 then goto continue end -- No self

            local pos = {current[1] + i, current[2], current[3] + j}
            local block = world.walkableBlock(pos, current)
            if block ~= nil then
                table.insert(neighbors, block)
            end
            :: continue ::
        end
    end
    return neighbors
end

world.searchStructure = function(func, timeout, box)
    timeout = timeout or 5
    local start = os.clock()
    local player = getPlayer()

    local x = math.floor(player.pos[1])
    local y = math.floor(player.pos[2])
    local z = math.floor(player.pos[3])
    box = box or Calc.createBox({x, y, z}, 20)

    while true do
        if os.clock() - start > timeout then return nil end
        for i = box[1][1], box[2][1] do
            for j = box[1][2], box[2][2] do
                for k = box[1][3], box[2][3] do
                    local result = func({i, j, k})
                    if result then return {i, j, k} end
                end
            end
        end
    end
end

world.breakNearbyBlocks = function(block_id, timeout, range)
    timeout = timeout or 3
    range = range or 2

    local player = getPlayer()
    local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
    local time = os.clock()
    local block_list = {}
    while true do
        if os.clock() - time > timeout then break end
        for i = -range, range do
            for j=-range, range do
                for k=-range, range do
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

return world
