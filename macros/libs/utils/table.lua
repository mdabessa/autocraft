local table_ = {}

table_.find = function(table, value)
    for k, v in pairs(table) do
        if type(v) == 'table' and type(value) == 'table' then
            if Calc.compareArray(v, value) then
                return k
            end
        elseif v == value then
            return k
        end
    end
    return nil
end

table_.copy = function (obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[table_.copy(k, s)] = table_.copy(v, s) end
    return res
end

return table_