local walk = {}

walk.heuristic = function(point1, point2)
    return Calc.distance3d(point1, point2)
end

walk.pathFinder = function(objective, max_jump, max_fall, pathFinderTimeout)
    pathFinderTimeout = pathFinderTimeout or 10
    local start = os.clock()

    local pos = getPlayer().pos
    local start_pos = {math.floor(pos[1]), math.floor(pos[2]), math.floor(pos[3])}
    local end_pos = Calc.centerBox(objective)

    if Calc.inBox(start_pos, objective) then return {} end

    local list_open = {
        {
            ['pos'] = {start_pos[1], start_pos[2], start_pos[3]},
            ['heuristic'] = walk.heuristic(start_pos, end_pos)
        }
    }
    local list_closed = {}
    local list_open_ref = {}

    local grid = {}

    while #list_open > 0 do
        if os.clock() - start > pathFinderTimeout then return nil end
        local current = table.remove(list_open, 1)

        if Calc.inBox(current['pos'], objective) then
            local path = {}
            local cell = {current['pos'][1], current['pos'][2], current['pos'][3]}
            while Calc.compareArray(cell, start_pos) == false do
                table.insert(path, cell)
                cell = grid[Calc.pointToStr(cell)]
            end

            local path_ = {}
            for i = #path, 1, -1 do
                table.insert(path_, path[i])
            end
            return path_
        end

        local neighbors_ = World.neighbors(current['pos'], max_jump, max_fall)
        for _, neighbor in pairs(neighbors_) do
            if list_open_ref[Calc.pointToStr(neighbor)] == nil and
                list_closed[Calc.pointToStr(neighbor)] == nil then

                local weight = walk.heuristic(neighbor, end_pos)
                local node = {['pos'] = neighbor, ['heuristic'] = weight}

                local index = Calc.binary_search(list_open, node, function(x) return x['heuristic'] end)
                table.insert(list_open, index, node)

                list_open_ref[Calc.pointToStr(neighbor)] = true
                grid[Calc.pointToStr(neighbor)] = {current['pos'][1], current['pos'][2], current['pos'][3]}
            end
        end

        list_closed[Calc.pointToStr(current['pos'])] = true
    end
    log("Path not found")
end

walk.move = function(to)
    local player = getPlayer()
    local time = os.clock()

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

walk.walkTo = function(to, steps, pathFinderArgs)
    steps = steps or 50
    pathFinderArgs = pathFinderArgs or {1, 5, 10} -- max_jump, max_fall, pathFinderTimeout

    while true do
        local player = getPlayer()
        local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
        local box = to
        local center = Calc.centerBox(to)
        center[2] = pos[2]
        local dist = Calc.distance3d(player.pos, center)

        if Calc.inBox(pos, box) then return true end

        if dist > steps then
            local angle = Calc.direction(pos, center)
            local new_point = Calc.directionToPoint(pos, angle, steps)
            box = Calc.createBox(new_point, 10)
            box[1][2] = 0
            box[2][2] = 255
        end

        local path = walk.pathFinder(box, pathFinderArgs[1], pathFinderArgs[2], pathFinderArgs[3])
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

return walk
