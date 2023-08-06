Libs = require('libs/init')
local args = {...}

local events = {}

events.Death = function (arg)
    return "You died"
end

events.PlayerJoin = function (arg)
    return "The player " .. arg[3] .. " joined the game"
end

events.PlayerLeave = function (arg)
    return "The player " .. arg[3] .. " left the game"
end

events.Weather = function (arg)
    return "The weather changed to " .. arg[3]
end

events.Respawn = function (arg)
    return "You respawned"
end

if events[args[2]] then
    local message = events[args[2]](args)
    Logger.log(message)
    Database.add_event(message)
end

