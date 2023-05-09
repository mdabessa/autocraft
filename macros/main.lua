Libs = require('libs/init')

local function main()
    Home.resetHome()
    if Home.getHome() == nil then
        Home.createHome()
    end

    local counter = 0
    while true do
        if #Command.threads==0 then
            counter = counter + 1
            if counter == 5 then
                counter = 0
                log('Crafting diamond')
                Command.execute('craft minecraft:diamond')
            end
        else
            counter = 0
        end

        sleep(1000)
    end
end

pcall(main)
