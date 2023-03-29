local crafting = {}

crafting.fuels = {
    ["minecraft:coal"] = true,
    ["minecraft:planks"] = true
}

crafting.getValidRecipe = function (recipe_id)
    local recipes = getRecipes(recipe_id)
    local notValid = {}
    for i=1, #recipes['crafting'] do
        for j=1, #recipes['crafting'][i] do
            for k=1, #recipes['crafting'][i][j] do
                local item = recipes['crafting'][i][j][k][1]
                if item ~= nil and next(item) ~= nil then
                    local _recipe = getRecipes(item.id)
                    if _recipe['crafting'][1] == nil then goto inner_continue end
                    local count = crafting.countRecipeItems(_recipe['crafting'][1])
                    if count[recipe_id] ~= nil then
                        table.insert(notValid, i)
                        goto outter_continue
                    end
                end
                ::inner_continue::
            end
        end
        ::outter_continue::
    end
    for i = #notValid, 1, -1 do
        table.remove(recipes['crafting'], notValid[i])
    end
    return recipes
end

crafting.listFuels = function()
    local items = {}
    for id, _ in pairs(crafting.fuels) do
        local count = Inventory.countItems(id)
        if count > 0 then
            items[id] = count
        end
    end
    return items
end

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

    local crafting_table = World.searchBlock('minecraft:crafting_table', 2)

    if crafting_table == nil then
        Home.buildWorkbench()
        crafting_table = World.searchBlock('minecraft:crafting_table', 2)
        if crafting_table == nil then error('No crafting table found') end
        return
    end


    local box = Calc.createBox(crafting_table, 2)
    Walk.walkTo(box, 50, {nil, nil, 2})
    Action.lookAtBlock(crafting_table[1], crafting_table[2], crafting_table[3])
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

crafting.furnaceCraft = function(recipe)
    Home.goHome()

    local furnace = World.searchBlock('minecraft:furnace', 1) or World.searchBlock('minecraft:lit_furnace', 1)

    if furnace == nil then
        Home.buildFurnace()
        furnace = World.searchBlock('minecraft:furnace', 1) or World.searchBlock('minecraft:lit_furnace', 1)

        if furnace == nil then error('No furnace found') end
    end

    local box = Calc.createBox(furnace, 2)
    local inv = openInventory()
    local map = inv.mapping.furnace

    Walk.walkTo(box, 50, {nil, nil, 2})

    Action.lookAtBlock(furnace[1], furnace[2], furnace[3])
    sleep(1000)
    use()
    sleep(1000)

    local item = Inventory.findItem(recipe[1].id, map)
    if item == nil or next(item) == nil then error('No item found') end
    local slot, _ = next(item)

    if not inv.getSlot(map.fuel) then
        local fuel = crafting.listFuels()
        if next(fuel) == nil then error('No fuel found') end
        local id, _ = next(fuel)
        local fuel_slot = Inventory.findItem(id, map)
        if fuel_slot == nil or next(fuel_slot) == nil then error('No fuel found') end
        local slot_fuel, _ = next(fuel_slot)

        inv.click(slot_fuel)
        sleep(200)
        inv.click(map.fuel,  inv.RMB)
        sleep(200)
        inv.click(slot_fuel)
        sleep(200)
    end

    inv.click(slot)
    sleep(200)
    inv.click(map.input,  inv.RMB)
    sleep(200)
    inv.click(slot)
    sleep(200)

    sleep(10000)
    inv.quick(map.output)

    sleep(2000)
    inv.close()
end

crafting.craft = function(item_id, quantity)
    if quantity == nil then quantity = 1 end

    if Farm.collect[item_id] ~= nil then
        Farm.collect[item_id](quantity)
        return
    end

    local recipes = crafting.getValidRecipe(item_id)
    if #recipes['crafting'] > 0 then
        local _recipe = recipes['crafting'][1]
        log('crafting: ' .. item_id)
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
        local items = {[_recipe[1].id] = 1}
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

        local fuel = crafting.listFuels()
        if next(fuel) == nil then
            crafting.craft('minecraft:planks', 1)
        end

        log('crafting in furnace: ' .. item_id)
        crafting.furnaceCraft(_recipe)

        itemsOnInventory = Inventory.countItems(item_id)
        log('OnInventory: ' .. itemsOnInventory .. ' Goal: ' .. goal)
        log('Created ' .. item_id)
        if itemsOnInventory < goal then
            crafting.craft(item_id, goal - itemsOnInventory)
        end
        return
    end
    error('No recipe or gathering method found for ' .. item_id)
end

crafting.fastCraft = function (item_id)
    local recipes = crafting.getValidRecipe(item_id)
    if #recipes['crafting'] == 0 then return false end

    local recipe = recipes['crafting'][1]
    if not crafting.canCraftInHand(recipe) then return false end

    while true do
        local items = crafting.countRecipeItems(recipe)
        local complete = true
        for id, count in pairs(items) do
            local itemsOnInventory = Inventory.countItems(id)
            if itemsOnInventory < count then
                local result = crafting.fastCraft(id)
                if not result then return false end
                complete = false
            end
        end
        if complete then break end
    end

    crafting.handCraft(recipe)
    return true
end


return crafting
