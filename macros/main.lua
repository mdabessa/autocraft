Libs = require('libs/init')

Logger.log('Start!')

Home.resetHome()
if Home.getHome() == nil then
    Home.createHome()
end

Crafting.craft('minecraft:iron_sword', 1)
Inventory.sortHotbar()

Logger.log('Done!')
