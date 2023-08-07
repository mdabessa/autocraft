Libs = require('libs/init')


local callback = function(status, err)
    if status == false and
        err ~= nil and
        err ~= 'Script was stopped'
    then
        local msg = Str.errorResume(err)
        local events = State.get('events')
        if events == nil then events = {} end

        table.insert(events, {
            user = 'Minecraft',
            message = msg,
            time = os.time(),
            type = 'error'
        })

        State.set('events', events)
    end
end

local last = nil
while true do
    Command.clearThreads()
    local commands = State.get('commands')
    if commands and #commands > 0 then
        if #Command.threads > 0 then
            local priority = 4
            if last ~= nil then
                priority = last
            end

            if tonumber(commands[1].priority) < priority then
                Command.execute(commands[1].command, callback)
                last = tonumber(commands[1].priority)
                table.remove(commands, 1)
            end
        else
            Command.execute(commands[1].command, callback)
            last = tonumber(commands[1].priority)
            table.remove(commands, 1)
        end
    end

    State.set('commands', commands)
    sleep(500)
end
