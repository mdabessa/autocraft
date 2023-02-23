local inventory = {}

inventory.HOTBAR_MAP = {
    [1] = 'sword',
    [2] = 'pickaxe',
    [3] = 'axe',
    [4] = 'shovel',
    [5] = 'hoe',
    [6] = 'placeable',
    [7] = nil,
    [8] = nil,
    [9] = nil
}

inventory.countItems = function(item_id)
    local count = 0
    local inv = getInventory()
    for i = 1, #inv do
        local item = inv[i]
        if item ~= false and item.id == item_id then
            count = count + item.nbt.Count
        end
    end
    return count
end

inventory.findItem = function(item_id, map)
    local inv = openInventory()
    map = map or inv.mapping.inventory

    local items = {}
    for _, slot in pairs(map.main) do
        local item = inv.getSlot(slot)
        if item and item.id == item_id then
            items[slot] = item
        end
    end

    for _, slot in pairs(map.hotbar) do
        local item = inv.getSlot(slot)
        if item and item.id == item_id then
            items[slot] = item
        end
    end
    return items
end

inventory.getHotbarSlot = function(tool)
    local last_nil = 9
    for i = 1, #inventory.HOTBAR_MAP do
        if inventory.HOTBAR_MAP[i] == tool then return i end
        if inventory.HOTBAR_MAP[i] == nil then last_nil = i end
    end
    return last_nil
end

inventory.isTool = function(item, tool)
    if item == nil then return false end
    if type(item) ~= 'table' then return false end
    local strings = Str.split(item.id, '_')
    if strings[2] == tool then return true end -- minecraft:wooden_pickaxe -> pickaxe
end

inventory.findTools = function(tool)
    local inv = openInventory()
    local map = inv.mapping.inventory
    local tools = {}

    for i = 1, #map['hotbar'] do
        local slot = map['hotbar'][i]
        local item = inv.getSlot(slot)
        if item and inventory.isTool(item, tool) then
            item.slot = slot
            table.insert(tools, item)
        end
    end

    for i = 1, #map['main'] do
        local slot = map['main'][i]
        local item = inv.getSlot(slot)
        if item and inventory.isTool(item, tool) then
            item.slot = slot
            table.insert(tools, item)
        end
    end

    return tools
end

inventory.toolLevel = function(tool)
    if string.find(tool, 'wood') then return 1 end
    if string.find(tool, 'stone') then return 2 end
    if string.find(tool, 'iron') then return 3 end
    if string.find(tool, 'diamond') then return 4 end
    return -1
end

inventory.getToolIdFromLevel = function(tool, level)
    if level == 1 then return 'minecraft:wooden_' .. tool end
    if level == 2 then return 'minecraft:stone_' .. tool end
    if level == 3 then return 'minecraft:iron_' .. tool end
    if level == 4 then return 'minecraft:diamond_' .. tool end
end

inventory.sortHotbar = function()
    local inv = openInventory()
    local map = inv.mapping.inventory
    sleep(200)
    for i, item in pairs(inventory.HOTBAR_MAP) do
        if item ~= nil then
            local tools = inventory.findTools(item)
            table.sort(tools, function (a, b)
                return inventory.toolLevel(a.id) > inventory.toolLevel(b.id)
            end)

            if #tools > 0 then
                local slot = map['hotbar'][i]
                inv.swap(tools[1].slot, slot)
                sleep(200)
            end
        end
    end
end

return inventory
