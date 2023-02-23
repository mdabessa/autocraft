local calc = {}

calc.distance3d = function(point1, point2)
    local x = point1[1] - point2[1]
    local y = point1[2] - point2[2]
    local z = point1[3] - point2[3]
    return math.sqrt(x * x + y * y + z * z)
end

calc.direction = function(point1, point2)
    local dx = point2[1] - point1[1]
    local dz = point2[3] - point1[3]
    local angle = math.atan2(dx, dz)
    return angle
end

calc.directionToPoint = function(from, angle, distance)
    local x = from[1] + math.sin(angle) * distance
    local z = from[3] + math.cos(angle) * distance
    return {math.floor(x), from[2], math.floor(z)}
end

calc.createBox = function(point, shape)
    shape = shape or 1
    if type(shape) == "number" then shape = {shape, shape, shape} end

    local x, y, z = point[1], point[2], point[3]
    local dx, dy, dz = shape[1]/2, shape[2]/2, shape[3]/2
    local x1, y1, z1 = x - dx, y - dy, z - dz
    local x2, y2, z2 = x + dx, y + dy, z + dz

    return {
        {x1, y1, z1},
        {x2, y2, z2},
    }
end

calc.pointToStr = function(point)
    return point[1] .. ',' .. point[2] .. ',' .. point[3]
end

calc.compareArray = function(array1, array2)
    if #array1 ~= #array2 then return false end
    for i = 1, #array1 do
        if type(array1[i]) == "table" then
            if not calc.compareArray(array1[i], array2[i]) then return false end
        elseif array1[i] ~= array2[i] then return false end
    end
    return true
end

calc.arrayContainsArray = function(array, value)
    for i = 1, #array do
        if calc.compareArray(array[i], value) then return true end
    end
    return false
end

calc.regionToBox = function(box)
    local minPoint = {
        math.min(box[1][1], box[2][1]),
        math.min(box[1][2], box[2][2]),
        math.min(box[1][3], box[2][3]),
    }
    local maxPoint = {
        math.max(box[1][1], box[2][1]),
        math.max(box[1][2], box[2][2]),
        math.max(box[1][3], box[2][3]),
    }
    return {minPoint, maxPoint}
end

calc.inBox = function(point, box)
    box = calc.regionToBox(box)
    local x, y, z = point[1], point[2], point[3]
    local x1, y1, z1 = box[1][1], box[1][2], box[1][3]
    local x2, y2, z2 = box[2][1], box[2][2], box[2][3]
    return x >= x1 and x <= x2 and y >= y1 and y <= y2 and z >= z1 and z <= z2
end

calc.centerBox = function(box)
    box = calc.regionToBox(box)
    local x1, y1, z1 = box[1][1], box[1][2], box[1][3]
    local x2, y2, z2 = box[2][1], box[2][2], box[2][3]

    local centerPoint = {
        math.floor(x1 + (x2 - x1) / 2),
        math.floor(y1 + (y2 - y1) / 2),
        math.floor(z1 + (z2 - z1) / 2),
    }
    return centerPoint
end

return calc
