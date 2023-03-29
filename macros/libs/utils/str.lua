local str = {}

str.split = function(_str, sep)
    sep = sep or ","
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)

    _str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

return str
