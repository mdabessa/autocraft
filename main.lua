Libs = require('libs/init')

Home.resetHome()
if Home.getHome() == nil then
    Home.createHome()
end

Crafting.craft('minecraft:iron_sword', 1)

log('Done!')
