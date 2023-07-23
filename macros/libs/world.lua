local world = {}

world.searchStructure = function(func, timeout, iterator, shape, step)
    timeout = timeout or 5
    local start = os.time()
    local player = getPlayer()

    local x = math.floor(player.pos[1])
    local y = math.floor(player.pos[2])
    local z = math.floor(player.pos[3])

    iterator = iterator or world.searchInRadius()
    while true do
        if os.time() - start > timeout then return nil end
        local pos = iterator()
        if pos == nil then return nil end
        pos = {pos[1] + x, pos[2] + y, pos[3] + z}
        local result = func(pos)

        if result == false then goto continue end
        if type(result) == 'table' then return result else return pos end

        :: continue ::
    end
end

world.searchBlock = function(block_id, timeout, iterator, shape, step)
    return world.searchStructure(function(pos)
        local block = getBlock(pos[1], pos[2], pos[3])
        if block ~= nil and block.id == block_id then
            return true
        end
        return false
    end, timeout, iterator, shape, step)
end

world.searchInRadius = function(shape, step)
    shape = shape or {16, 5, 16}
    step = step or 1
    if type(shape) == 'number' then shape = {shape, shape, shape} end
    if type(step) == 'number' then step = {step, step, step} end

    local max_layer = math.max(shape[1], shape[2], shape[3])

    local state = {}
    local loops = {
        {start = 1, stop = max_layer, step = 1, index = 1},
    }
    local function next()
        while true do
            if #loops == 0 then return nil end

            -- main
            if #loops == 1 then
                local axis = {
                    start = 1,
                    stop = 3,
                    step = 1,
                    index = 1,
                }
                table.insert(loops, axis)

                local loop = loops[1]
                -- reset axis iterating
                state["ranges"] = {{start = -loop.index, stop=loop.index, step=1, index= -loop.index},
                                    {start = -loop.index, stop=loop.index, step=1, index= -loop.index},
                                    {start = -loop.index, stop=loop.index, step=1, index= -loop.index}}

                state["border"] = loop.index
            end

            if #loops == 2 then
                local loop = loops[2]
                -- lock axis iterating only in the start and end
                for i=1, 3 do
                    if i == loop.index then
                        state["ranges"][i].step = (state["ranges"][i].stop * 2)
                    elseif i < loop.index then
                        state["ranges"][i].step = 1
                        -- skip edges to avoid duplicates
                        state["ranges"][i].start = (state["border"] - 1) * -1
                        state["ranges"][i].stop = state["border"] - 1
                        state["ranges"][i].index = state["ranges"][i].start
                    else
                        state["ranges"][i].step = 1
                    end
                end
                -- create x axis iteration
                table.insert(loops, Table.copy(state["ranges"][1]))
            end

            if #loops == 3 then
                -- create y axis iteration
                table.insert(loops, Table.copy(state["ranges"][2]))
            end

            if #loops == 4 then
                -- create z axis iteration
                table.insert(loops, Table.copy(state["ranges"][3]))
            end

            -- get current position
            local result = {
                loops[3].index,
                loops[4].index,
                loops[5].index,
            }

            -- increment and update loops
            loops[#loops].index = loops[#loops].index + loops[#loops].step
            for i=#loops, 1, -1 do
                if loops[i].index > loops[i].stop then
                    if i ~= 1 then
                        loops[i-1].index = loops[i-1].index + loops[i-1].step
                    end
                    table.remove(loops, i)
                end
            end


            -- validate position
            if result[1] % step[1] == 0 and result[2] % step[2] == 0 and result[3] % step[3] == 0 then
                if math.abs(result[1]) <= shape[1] and math.abs(result[2]) <= shape[2] and math.abs(result[3]) <= shape[3] then
                    return result
                end
            end
        end
    end
    return next
end

return world
