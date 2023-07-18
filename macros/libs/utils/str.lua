local str = {}

str.split = function(_str, sep)
    sep = sep or ","
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)

    _str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

str.errorResume = function(err)
    local msg = str.split(err, '\n')
    msg = msg[1]
    msg = str.split(msg, ':')
    local res = ''
    for i = 3, #msg do
        res = res .. msg[i] .. ':'
    end
    res = res:sub(1, -2)

    local first_space = res:find(' ')
    res = res:sub(first_space + 1, -1)
    return res
end

str.join = function(t, sep, start, finish)
    start = start or 1
    finish = finish or #t
    sep = sep or ','

    local res = ''
    for i = start, finish do
        res = res .. t[i] .. sep
    end
    res = res:sub(1, -2)
    return res
end

return str
