local command = {}

command.threads = {}

command.alias = {
    ["goto"] = "goTo",
}

command.parseArguments = function (args)
    local result = {}
    local content = Str.split(args, ' ')
    local i = 1
    while i <= #content do
        local arg = content[i]
        local key, value = string.match(arg, "(%w+)=(%w+)")
        if key ~= nil and value ~= nil then
            result[key] = value
        else
            table.insert(result, arg)
        end
        i = i + 1
    end
    return result
end

command.clearThreads = function()
    for i = 1, #command.threads do
        if command.threads[i].getStatus() == 'done' then
            table.remove(command.threads, i)
        end
    end
end

command.resetPlayer = function ()
    local inv = openInventory()
    inv.close()
end

command.execute = function(str, callback)
    local content = Str.split(str, ' ')
    if #content == 0 then return nil end
    local cmd = string.lower(content[1])
    local args = ''

    if #content > 1 then
        for i = 2, #content do
            args = args .. content[i] .. ' '
        end
        args = args:sub(1, -2)
    end

    if cmd == 'stop' then
        for i = 1, #command.threads do
            command.threads[i]:stop()
        end
        command.threads = {}
        return nil
    end

    if command.alias[cmd] ~= nil then
        cmd = command.alias[cmd]
    end

    if command.commands[cmd] ~= nil then
        command.resetPlayer()
        local cmd_thread = thread.new( function ()
            local status, err = pcall(command.commands[cmd], args)
            if callback ~= nil then
                callback(status, err)
            end
        end)

        cmd_thread:start()

        table.insert(command.threads, cmd_thread)
        return cmd_thread
    end
end

command.commands = {}

command.commands.help = function (args)
    log('Available commands:')
    for k, v in pairs(command.commands) do
        log(k)
    end
    log('stop')
end

command.commands.follow = function (args)
    args = command.parseArguments(args)
    local entity_name = args[1] or args['entity']
    if entity_name == nil then
        error('Please specify an entity to follow')
        return
    end

    local entities = getEntityList()
    local entity = nil
    for i = 1, #entities do
        if string.lower(entities[i].name) == string.lower(entity_name) then
            entity = entities[i]
            break
        end
    end

    if entity == nil then
        error('Entity not found to follow')
        return
    end

    local entity_id = entity.id

    Walk.followEntity(entity_id, 2, true)
end

command.commands.goTo = function (args)
    args = command.parseArguments(args)

    local canPlace = args['canPlace'] or false
    if canPlace == 'true' then canPlace = true end

    local canBreak = args['canBreak'] or false
    if canBreak == 'true' then canBreak = true end

    if #args == 3 then
        local x = tonumber(args[1])
        local y = tonumber(args[2])
        local z = tonumber(args[3])

        local box = Calc.createBox({x, y, z}, 1)
        local s = Walk.walkTo(box, 50, {canPlace = canPlace, canBreak = canBreak})
        if s == false then
            error('Could not reach destination')
        end
    elseif #args == 1 then
        local entity_name = args[1]
        local entities = getEntityList()
        local entity = nil
        for i = 1, #entities do
            if string.lower(entities[i].name) == string.lower(entity_name) then
                entity = entities[i]
                break
            end
        end

        if entity == nil then
            error('Entity not found to go to')
            return
        end

        local entity_id = entity.id

        Walk.followEntity(entity_id, 2, false, {canPlace = canPlace, canBreak = canBreak})

        entity = getEntity(entity_id)
        lookAt(entity.pos[1], entity.pos[2]+entity.width-0.2, entity.pos[3])
    else
        error('Please specify a enity name or coordinates to go to')
    end

end

command.commands.say = function (args)
    say(args)
end

command.commands.craft = function (args)
    args = command.parseArguments(args)
    local item = args[1] or args['item']
    local amount = args[2] or args['amount'] or 1
    if item == nil then
        error('Please specify an item')
        return
    end

    if string.sub(item, 1, 10) ~= 'minecraft:' then
        error('A minecraft id must be specified')
    end

    Crafting.craft(item, amount)
end

command.commands.drop = function (args)
    args = command.parseArguments(args)
    local item = args[1] or args['item']
    if item == nil then
        error('Please specify an item')
        return
    end

    if string.sub(item, 1, 10) ~= 'minecraft:' then
        error('A minecraft id must be specified')
        return
    end

    item = Inventory.findItem(item)
    if next(item) == nil then
        error('Item not found in inventory')
        return
    end
    local slot, _ = next(item)
    local hotslot = Inventory.getHotbarSlot('placeable')
    local inventory = openInventory()
    local map = inventory.mapping.inventory
    inventory.swap(slot, map['hotbar'][hotslot])
    setHotbar(hotslot)
    sleep(100)
    drop(true)
end

command.commands.give = function (args)
    args = command.parseArguments(args)
    local item_name = args[1] or args['item']
    local entity_name = args[2] or args['entity']

    if #args ~= 2 then
        error('Please specify an item and an entity')
        return
    end

    entity_name = args[1]
    item_name = args[2]

    if string.sub(item_name, 1, 10) ~= 'minecraft:' then
        error('A minecraft id must be specified')
        return
    end

    local entities = getEntityList()
    local entity = nil
    for i = 1, #entities do
        if string.lower(entities[i].name) == string.lower(entity_name) then
            entity = entities[i]
            break
        end
    end

    if entity == nil then
        error('Entity not found')
        return
    end

    local entity_id = entity.id
    local item = Inventory.findItem(item_name)
    if next(item) == nil then
        Crafting.craft(item_name, 1)
        item = Inventory.findItem(item_name)
        if next(item) == nil then
            error('Could not craft item')
            return
        end
    end

    Walk.followEntity(entity_id, 2, false)
    entity = getEntity(entity_id)
    lookAt(entity.pos[1], entity.pos[2]+entity.width, entity.pos[3])
    sleep(300)

    local slot, _ = next(item)
    local hotslot = Inventory.getHotbarSlot('placeable')
    local inventory = openInventory()
    local map = inventory.mapping.inventory
    inventory.swap(slot, map['hotbar'][hotslot])
    setHotbar(hotslot)
    sleep(100)
    drop(true)
end

command.commands.test = function (args)
    args = command.parseArguments(args)
    local test = args[1] or args['test']
    local test_args = {}
    for i = 2, #args do table.insert(test_args, args[i]) end
    if test == nil then
        error('Please specify a test')
    end

    if Test[test] == nil then
        error('Test not found')
    end

    Test[test](table.unpack(test_args))
end

return command
