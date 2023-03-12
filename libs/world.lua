local world = {}

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

    local m = math.max(shape[1], shape[2], shape[3])

    for i = 1, m do
        local ranges = {
            Calc.range(-i, i),
            Calc.range(-i, i),
            Calc.range(-i, i)
        }

        for axis = 1, 3 do
            ranges[axis] = {-i, i}
            for _, x in ipairs(ranges[1]) do
                if x > shape[1] or x < -shape[1] then goto continue1 end
                for _, y in ipairs(ranges[2]) do
                    if y > shape[2] or y < -shape[2] then goto continue2 end
                    for _, z in ipairs(ranges[3]) do
                        if z > shape[3] or z < -shape[3] then goto continue3 end
                        if x % step[1] == 0 and y % step[2] == 0 and z % step[3] == 0 then
                            coroutine.yield({x, y, z})
                        end
                        ::continue3::
                    end
                    ::continue2::
                end
                ::continue1::
            end
            ranges[axis] = Calc.range(-i+1, i-1) -- remove duplicates corners
        end
    end
end

return world
