Libs = require('libs/init')
local args = {...}

pcall(function()
    local chat = Str.split(args[4], '>')
    if string.sub(chat[2], 2, 2) == '!' then -- 2 because of the space
        local cmd = string.sub(chat[2], 3, -1)
        Command.execute(cmd)
    else
        Database.add_event(args[4])
    end
end)

return args[4]
