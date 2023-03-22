Libs = require('libs/init')
local args = {...}


local chat = Str.split(args[4], " ")

local content = ''
for i = 2, #chat do
    content = content .. chat[i] .. ' '
end

local s = false
if content:sub(1, 1) == '.' then
    content = content:sub(2, -1)
    s = Command.execute(content)
end


if s == false then
    return args[4]
end

return false -- Don't send the message to the server
