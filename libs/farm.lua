local farm = {}

farm.collect = {}

farm.collect['minecraft:log'] = Wood.collectTree
farm.collect['minecraft:cobblestone'] = function (quantity) Miner.mine('minecraft:cobblestone', quantity) end

return farm
