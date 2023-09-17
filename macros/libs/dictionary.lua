local dictionary = {}


dictionary.ids = {
    ["minecraft:log"] = {
        "minecraft:oak_log",
        "minecraft:spruce_log",
        "minecraft:birch_log",
        "minecraft:jungle_log",
        "minecraft:acacia_log",
        "minecraft:dark_oak_log",
        "minecraft:stripped_oak_log",
        "minecraft:stripped_spruce_log",
        "minecraft:stripped_birch_log",
        "minecraft:stripped_jungle_log",
        "minecraft:stripped_acacia_log",
        "minecraft:stripped_dark_oak_log",
    },
    ["minecraft:planks"] = {
        "minecraft:oak_planks",
        "minecraft:spruce_planks",
        "minecraft:birch_planks",
        "minecraft:jungle_planks",
        "minecraft:acacia_planks",
        "minecraft:dark_oak_planks"
    },
    ["minecraft:air"] = {
        "minecraft:air",
        "minecraft:cave_air"
    },
    ["minecraft:leaves"] = {
        "minecraft:oak_leaves",
        "minecraft:spruce_leaves",
        "minecraft:birch_leaves",
        "minecraft:jungle_leaves",
        "minecraft:acacia_leaves",
        "minecraft:dark_oak_leaves"
    }
}

dictionary.getGroup = function(id)
    for k, v in pairs(dictionary.ids) do
        for _, v2 in pairs(v) do
            if v2 == id then
                return k
            end
        end
    end
    return id
end

dictionary.getGroupItems = function(group)
    return dictionary.ids[group] or {group}
end

return dictionary
