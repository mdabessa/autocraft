local crafting = {}


crafting.countRecipeItems = function(recipe)
    local items = {}
    for i = 1, #recipe do
        for j = 1, #recipe[i] do
            local item = recipe[i][j][1]
            if item ~= nil and next(item) ~= nil then
                if items[item.id] == nil then items[item.id] = 0 end
                items[item.id] = items[item.id] + 1
            end
        end
    end
    return items
end

crafting.setRecipe = function(recipe, inv, map)
    for i=1, #recipe do
        for j=1, #recipe[i] do
            local item = recipe[i][j][1]
            if item ~= nil and next(item) ~= nil then
                local slot = Inventory.findItem(item.id, map)
                if slot == nil or next(slot) == nil then return false end
                slot, _ = next(slot)
                inv.click(slot)
                sleep(200)
                local dim = 2
                if #map.craftingIn == 9 then dim = 3 end
                local s = i + (j - 1) * dim
                inv.click(map.craftingIn[s], inv.RMB)
                inv.click(slot)
            end
        end
    end
end

crafting.listItems = function(recipe)
    local items = {}
    for i = 1, #recipe do
        for j = 1, #recipe[i] do
            local item = recipe[i][j][1]
            if item ~= nil and next(item) ~= nil then
                if items[item.id] == nil then items[item.id] = 0 end
                items[item.id] = items[item.id] + 1
            end
        end
    end
    return items
end

crafting.canCraftInHand = function(recipe)
    if recipe[3] ~= nil then return false end

    for i = 1, 2 do
        if recipe[i] ~= nil and recipe[i][3] ~= nil then return false end
    end

    return true
end

crafting.handCraft = function(recipe)
    local inv = openInventory()
    local map = inv.mapping.inventory
    crafting.setRecipe(recipe, inv, map)
    sleep(200)

    inv.quick(map.craftingOut)
    sleep(200)

    inv.close()
end

crafting.craftingTable = function(recipe)
    Home.goHome()

    local inv = openInventory()
    local map = inv.mapping.inventory

    local crafting_table = World.searchStructure(function (pos)
        local block = getBlock(pos[1], pos[2], pos[3])
        if block ~= nil and block.id == 'minecraft:crafting_table' then return true end
        return false
    end
    ,10)

    if crafting_table == nil then error('No crafting table found') end


    local box = Calc.createBox(crafting_table, 2)
    Walk.walkTo(box, 50, {nil, nil, 2})
    lookAt(crafting_table[1]+0.5, crafting_table[2]+0.5, crafting_table[3]+0.5)
    sleep(1000)

    use()
    sleep(1000)

    map = inv.mapping['crafting table']
    crafting.setRecipe(recipe, inv, map)
    sleep(1000)

    inv.quick(map.craftingOut)
    sleep(2000)
    inv.close()
end

crafting.craft = function(item_id, quantity)
    if quantity == nil then quantity = 1 end

    if Farm.collect[item_id] ~= nil then
        Farm.collect[item_id](quantity)
        return
    end

    local recipes = getRecipes(item_id)
    if #recipes['crafting'] > 0 then
        local _recipe = recipes['crafting'][1]
        local items = crafting.listItems(_recipe)
        while true do
            local hasAllItems = true
            for id, count in pairs(items) do
                local itemsOnInventory = Inventory.countItems(id)
                if itemsOnInventory > count then goto continue end
                if itemsOnInventory < count then
                    crafting.craft(id, count - itemsOnInventory)
                    hasAllItems = false
                end
                ::continue::
            end
            if hasAllItems then break end
        end

        local itemsOnInventory = Inventory.countItems(item_id)
        local goal = quantity + itemsOnInventory
        if crafting.canCraftInHand(_recipe) then
            log('crafting in hand: ' .. item_id)
            crafting.handCraft(_recipe)
        else
            log('crafting in table: ' .. item_id)
            crafting.craftingTable(_recipe)
        end

        itemsOnInventory = Inventory.countItems(item_id)
        log('OnInventory: ' .. itemsOnInventory .. ' Goal: ' .. goal)
        log('Created ' .. item_id)
        if itemsOnInventory < goal then
            crafting.craft(item_id, goal - itemsOnInventory)
        end
        return

    elseif #recipes['furnace'] > 0 then
        local _recipe = recipes['furnace'][1]
        error('Furnace crafting not implemented yet')
    end
    error('No recipe or gathering method found for ' .. item_id)
end

crafting.fastCraft = function (item_id)
    local recipes = getRecipes(item_id)
    if recipes['crafting'] == 0 then return false end

    local recipe = recipes['crafting'][1]
    if not crafting.canCraftInHand(recipe) then return false end

    local items = crafting.countRecipeItems(recipe)
    for id, count in pairs(items) do
        local itemsOnInventory = Inventory.countItems(id)
        if itemsOnInventory < count then return false end
    end

    crafting.handCraft(recipe)
    return true
end


return crafting
