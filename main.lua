Libs = require('libs/init')

Home.resetHome()
if Home.getHome() == nil then
    Home.createHome()
end

Crafting.craft('minecraft:furnace', 2)
log('Done!')