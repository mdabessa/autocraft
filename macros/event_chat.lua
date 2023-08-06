Libs = require('libs/init')
local args = {...}


local function callback(status, err)
    if not status then
        log(err)
    end
end


pcall(function()
    local chat = Str.split(args[4], '>')
    local user = string.sub(chat[1], 2, -1)
    if string.sub(chat[2], 2, 2) == '!' then -- 2 because of the space
        local cmd = string.sub(chat[2], 3, -1)
        Command.execute(cmd, callback)
    elseif user ~= 'Ailicia' and Database ~= nil then
        Database.add_event(args[4])
        Logger.log('Added event: ' .. args[4])
    end
end)

return args[4]
