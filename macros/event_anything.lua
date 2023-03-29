Libs = require('libs/init')
local args = {...}

local whitelist = {
    Death = true,
    PlayerJoin = true,
    PlayerLeave = true,
}

if whitelist[args[2]] then
    Database.add_event(args[1])
end

