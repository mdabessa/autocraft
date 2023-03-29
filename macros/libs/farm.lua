local farm = {}

farm.collect = {}

farm.collect['minecraft:log'] = Wood.collectTree
farm.collect['minecraft:cobblestone'] = function (quantity) Miner.mine('minecraft:cobblestone', quantity) end
farm.collect['minecraft:iron_ore'] = function (quantity) Miner.mine('minecraft:iron_ore', quantity) end

return farm
