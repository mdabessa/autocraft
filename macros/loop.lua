Libs = require('libs/init')

local last = nil
while true do
    Command.thread_cleanup()
    local command = Database.get_command()
    if #command > 0 then
        if #Command.threads > 0 then
            local priority = 4
            if last ~= nil then
                priority = last
            end

            if tonumber(command[1].priority) < priority then
                Command.execute(command[1].command)
                last = tonumber(command[1].priority)
                Database.delete_command(command[1].id)
            end
        else
            Command.execute(command[1].command)
            last = tonumber(command[1].priority)
            Database.delete_command(command[1].id)
        end
    end
    sleep(500)
end
