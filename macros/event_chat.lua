Libs = require('libs/init')
local args = {...}


local function callback(status, err)
    if not status then
        Logger.log(err)
    end
end


pcall(function()
    local chat = Str.split(args[4], '>')
    local user = string.sub(chat[1], 2, -1)

    if string.sub(chat[2], 2, 2) == '!' then -- 2 because of the space
        local cmd = string.sub(chat[2], 3, -1)
        Command.execute(cmd, callback)

    elseif user ~= 'Ailicia' then
        local events = State.get('events')
        if events == nil then events = {} end

        table.insert(events, {
            user = user,
            message = chat[2],
            time = os.time(),
            type = 'chat'
        })

        State.set('events', events)
    end
end)

return args[4]
