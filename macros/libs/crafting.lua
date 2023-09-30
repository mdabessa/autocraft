local crafting = {}

crafting.fuels = {
    ["minecraft:coal"] = true,
    ["minecraft:planks"] = true
}

crafting.denylist = {
    "_wood",
    "stripped_",
}

crafting.isDenylisted = function (item_id)
    for _, word in pairs(crafting.denylist) do
        if string.find(item_id, word) then
            return true
        end
    end
    return false
end

crafting.shape = function (obj)
    if type(obj) ~= "table" then return nil end
    if obj[1] == nil then return nil end

    local len = #obj
    local next = crafting.shape(obj[1])
    if next == nil then
        return {len}
    end

    local shape = {len}
    for i=1, #next do
        table.insert(shape, next[i])
    end
    return shape
end

crafting.getRecipes = function (item_id)
    local _recipes = getRecipes(item_id)
    if _recipes == nil then return nil end
    local notValid = {}

    for i=1, #_recipes['crafting'] do
        local status, err = pcall(function ()
            local id = _recipes['crafting'][i]['out']['id']
            if id ~= item_id then
                table.insert(notValid, i)
            end
    
            -- normalize shape
            -- collumns[ rows[ item_variation[ item ] ] ]
            -- 3 x 3 x n or 2 x 2 x n
            local shape = crafting.shape(_recipes['crafting'][i]['in'])
            if #shape == 2 and shape[2] > 1 then
                -- 1 x 1 with n variations
                local new_recipe = {
                    {{}, {}},
                    {{}, {}}
                }
                new_recipe[1][1] = _recipes['crafting'][i]['in'][1]
                _recipes['crafting'][i]['in'] = new_recipe
    
            elseif #shape == 2 then
                -- 2x2 with 1 variation
                local new_recipe = {
                    {{}, {}},
                    {{}, {}}
                }
    
                for j=1, #_recipes['crafting'][i]['in'] do
                    for k=1, #_recipes['crafting'][i]['in'][j] do
                        local item = _recipes['crafting'][i]['in'][j][k]
                        new_recipe[j][k] = {item}
                    end
                end
                _recipes['crafting'][i]['in'] = new_recipe
    
            elseif #shape == 3 then
                -- 2x2 or 3x3 with n variations
    
                local new_recipe = {}
                if shape[1] < 3 and shape[2] < 3 then
                    new_recipe = {
                        {{}, {}},
                        {{}, {}}
                    }
                else
                    new_recipe = {
                        {{}, {}, {}},
                        {{}, {}, {}},
                        {{}, {}, {}}
                    }
                end
    
                for j=1, #_recipes['crafting'][i]['in'] do
                    for k=1, #_recipes['crafting'][i]['in'][j] do
                        local items = _recipes['crafting'][i]['in'][j][k]
                        if items[1] == nil then items = {items} end
                        new_recipe[j][k] = items
                    end
                end
                _recipes['crafting'][i]['in'] = new_recipe
            else
                table.insert(notValid, i)
            end
        end
        )

        if not status then
            if Str.errorResume(err) == "Script was stopped" then
                error("Script was stopped")
            end

            table.insert(notValid, i)
        end

    end

    for i=#notValid, 1, -1 do
        table.remove(_recipes['crafting'], notValid[i])
    end
    return _recipes
end

crafting.getValidRecipes = function (recipe_id)
    local ids = Dictionary.getGroupItems(recipe_id)
    local all_recipes = {['crafting'] = {}}
    for _, id in pairs(ids) do
        local recipes = crafting.getRecipes(id)
        if recipes == nil then goto continue end

        for _, method in pairs(recipes) do
            if method ~= "crafting" then
                all_recipes[method] = recipes[method]
            end
        end
        -- validate crafting recipes
        if #recipes['crafting'] == 0 then goto continue end
        for _, recipe in pairs(recipes['crafting']) do
            local valid = true
            for i=1, #recipe['in'] do
                for j=1, #recipe['in'][i] do
                    if #recipe['in'][i][j] > 0 then
                        local valid_itens = {}
                        for _, item in pairs(recipe['in'][i][j]) do
                            local _recipe = crafting.getRecipes(item.id)
                            if _recipe ~= nil and #_recipe['crafting'] > 0 then
                                local count = crafting.countRecipeItems(_recipe['crafting'][1])
                                if count[recipe_id] == nil and crafting.isDenylisted(item.id) == false then
                                    table.insert(valid_itens, item)
                                end
                            else
                                if crafting.isDenylisted(item.id) == false then
                                    table.insert(valid_itens, item)
                                end
                            end
                        end

                        if #valid_itens == 0 then
                            valid = false
                            break
                        end

                        recipe['in'][i][j] = valid_itens
                    elseif next(recipe['in'][i][j]) ~= nil then
                        if crafting.isDenylisted(recipe['in'][i][j].id) then
                            valid = false
                            break
                        end
                    end
                end
            end
            if valid then
                table.insert(all_recipes['crafting'], recipe)
            end
        end

        :: continue ::
    end
    return all_recipes
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
    for i = 1, #recipe['in'] do
        for j = 1, #recipe['in'][i] do
            local item = recipe['in'][i][j][1]
            if item ~= nil and next(item) ~= nil then
                if items[item.id] == nil then items[item.id] = 0 end
                items[item.id] = items[item.id] + 1
            end
        end
    end
    return items
end

crafting.recipeToStr = function (recipe)
    local str = ''
    for i = 1, #recipe['in'] do
        for j = 1, #recipe['in'][i] do
            local item = recipe['in'][j][i][1]
            if item ~= nil and next(item) ~= nil then
                str = str .. item.id .. '    '
            else
                str = str .. 'nil    '
            end
        end
        str = str .. '\n'
    end
    return str
end

crafting.setRecipe = function(recipe, map)
    local inv = openInventory()
    for i=1, #recipe['in'] do
        for j=1, #recipe['in'][i] do
            local items = recipe['in'][i][j]
            local sucess = false
            if #items == 0 or next(items[1]) == nil then sucess = true end
            for _, possible_item in pairs(items) do
                local id = Dictionary.getGroup(possible_item.id)
                local slot = Inventory.findItem(id, map)
                if slot == nil or next(slot) == nil then goto continue end
                slot, _ = next(slot)
                inv.click(slot)
                sleep(200)
                local dim = 2
                if #map.craftingIn == 9 then dim = 3 end
                local s = i + (j - 1) * dim
                inv.click(map.craftingIn[s], inv.RMB)
                sleep(200)
                inv.click(slot)
                sleep(200)
                sucess = true
                break
                ::continue::
            end
            if not sucess then
                Logger.log('Failed to place item in slot ' .. i .. ' ' .. j)
                inv.close()
                return false
            end
        end
    end
    return true
end

crafting.canCraftInHand = function(recipe)
    local shape = crafting.shape(recipe['in'])
    if shape == nil then return false end
    return shape[1] == 2
end

crafting.handCraft = function(recipe)
    local inv = openInventory()
    local map = inv.mapping.inventory
    local s = crafting.setRecipe(recipe, map)
    if s then
        sleep(200)
        inv.quick(map.craftingOut)
        sleep(200)
    end
    inv.close()
    return s
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
    crafting.setRecipe(recipe, map)
    sleep(1000)
    inv.quick(map.craftOut)
    sleep(1000)
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
    item_id = Dictionary.getGroup(item_id)
    if crafting.isDenylisted(item_id) then error('Item is denylisted') end

    if Farm.collect[item_id] ~= nil then
        Farm.collect[item_id](quantity)
        return
    end

    local recipes = crafting.getValidRecipes(item_id)
    if recipes['crafting'] ~= nil and #recipes['crafting'] > 0 then
        for i, recipe in pairs(recipes['crafting']) do
            Logger.log('Try crafting ' .. item_id .. ' with recipe ' .. tostring(recipe['out']['id']) .. ' [' .. tostring(i) .. '/' .. tostring(#recipes['crafting']) .. ']')
            local items = crafting.countRecipeItems(recipe)
            while true do
                local hasAllItems = true
                for id, count in pairs(items) do
                    id = Dictionary.getGroup(id)
                    local itemsOnInventory = Inventory.countItems(id)
                    if itemsOnInventory > count then goto continue end
                    if itemsOnInventory < count then
                        local status, err = pcall(crafting.craft, id, count - itemsOnInventory)

                        if not status and Str.errorResume(err) == "Script was stopped" then
                            error("Script was stopped")
                        end

                        if not status and err and
                            (string.find(err, 'No recipe or gathering method found for') or
                            string.find(err, 'Item is denylist')) then
                            goto next_recipe
                        end

                        if not status then
                            error(err)
                        end

                        hasAllItems = false
                    end
                    ::continue::
                end
                if hasAllItems then break end
            end

            local itemsOnInventory = Inventory.countItems(item_id)
            local goal = quantity + itemsOnInventory
            if crafting.canCraftInHand(recipe) then
                Logger.log('crafting in hand: ' .. item_id)
                crafting.handCraft(recipe)
            else
                Logger.log('crafting in table: ' .. item_id)
                crafting.craftingTable(recipe)
            end

            itemsOnInventory = Inventory.countItems(item_id)
            Logger.log('OnInventory: ' .. itemsOnInventory .. ' Goal: ' .. goal)
            Logger.log('Created ' .. item_id)
            if itemsOnInventory < goal then
                crafting.craft(item_id, goal - itemsOnInventory)
            end
            do return end
            :: next_recipe ::
        end

    elseif recipes['furnace'] ~= nil and #recipes['furnace'] > 0 then
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

        Logger.log('crafting in furnace: ' .. item_id)
        crafting.furnaceCraft(_recipe)

        itemsOnInventory = Inventory.countItems(item_id)
        Logger.log('OnInventory: ' .. itemsOnInventory .. ' Goal: ' .. goal)
        Logger.log('Created ' .. item_id)
        if itemsOnInventory < goal then
            crafting.craft(item_id, goal - itemsOnInventory)
        end
        return
    end
    error('No recipe or gathering method found for ' .. item_id)
end

crafting.fastCraft = function (item_id)
    local recipes = crafting.getValidRecipes(item_id)
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
