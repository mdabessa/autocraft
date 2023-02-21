Libs = require('libs/init')

Home.resetHome()
if Home.getHome() == nil then
    Home.createHome()
end

Crafting.craft('minecraft:furnace', 1)
log('Done!')

-- Miner.mine('minecraft:stone', 64)
