Libs = require('libs/init')

while true do
    local command = Database.pop_command()
    if #command > 0 then
        Command.execute(command[1].command)
    end
    sleep(500)
end
