local walk = {}

walk.heuristic = function(point1, point2)
    return Calc.distance3d(point1, point2)
end

walk.pathFinder = function(objective, pathFinderTimeout)
    pathFinderTimeout = pathFinderTimeout or 10
    local start = os.clock()

    local pos = getPlayer().pos
    local start_pos = {math.floor(pos[1]), math.floor(pos[2]), math.floor(pos[3])}
    local end_pos = Calc.centerBox(objective)

    if Calc.inBox(start_pos, objective) then return {} end

    local list_open = { start_pos }
    local list_closed = {}
    local grid = {}

    while #list_open > 0 do
        if os.clock() - start > pathFinderTimeout then return nil end
        local current = table.remove(list_open, 1)

        if Calc.inBox(current, objective) then
            local path = {}
            local cell = {current[1], current[2], current[3]}
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

        local neighbors_ = World.neighbors(current)
        for _, neighbor in pairs(neighbors_) do
            if not Calc.arrayContainsArray(list_open, neighbor) and
                not Calc.arrayContainsArray(list_closed, neighbor) then

                table.insert(list_open, neighbor)
                grid[Calc.pointToStr(neighbor)] = {current[1], current[2], current[3]}
            end
        end

        table.insert(list_closed, current)
        table.sort(list_open, function(a, b)
            return walk.heuristic(a, end_pos) < walk.heuristic(b, end_pos)
        end)
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

walk.walkTo = function(to, steps, pathFinderTimeout)
    steps = steps or 50
    pathFinderTimeout = pathFinderTimeout or 10

    while true do
        local player = getPlayer()
        local pos = {math.floor(player.pos[1]), math.floor(player.pos[2]), math.floor(player.pos[3])}
        local box = to
        local center = Calc.centerBox(to)
        local dist = Calc.distance3d(player.pos, center)

        if Calc.inBox(pos, box) then return true end

        if dist > steps then
            local angle = Calc.direction(pos, center)
            local new_point = Calc.directionToPoint(pos, angle, steps)
            box = Calc.createBox(new_point, 60)
            box[1][2] = 0
            box[2][2] = 255
        end

        local path = walk.pathFinder(box, pathFinderTimeout)
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

return walk
