Libs = require('libs/init')

Home.resetHome()
if Home.getHome() == nil then
    Home.createHome()
end

-- Crafting.craft('minecraft:chest', 1)

Miner.mine('minecraft:cobblestone', 32)

log('Done!')