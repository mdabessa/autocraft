local command = {}

command.threads = {}

command.alias = {
    ["goto"] = "goTo",
}

command.thread_cleanup = function()
    for i = 1, #command.threads do
        if command.threads[i].getStatus() == 'done' then
            table.remove(command.threads, i)
        end
    end
end

command.execute = function(str, callback)
    local content = Str.split(str, ' ')
    if #content == 0 then return false end
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
        return true
    end

    if command.alias[cmd] ~= nil then
        cmd = command.alias[cmd]
    end

    if command.commands[cmd] ~= nil then

        local cmd_thread = thread.new( function ()
            local status, err = pcall(command.commands[cmd], args)
            if callback ~= nil then
                callback(status, err)
            end
        end)

        cmd_thread:start()

        table.insert(command.threads, cmd_thread)
        return true
    end

    return false
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
    args = Str.split(args, ' ')
    local entity_name = args[1]
    if entity_name == nil then
        log('Please specify a enity')
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
        log('Entity not found')
        return
    end

    local entity_id = entity.id

    Walk.followEntity(entity_id, 2, true)
end

command.commands.goTo = function (args)
    args = Str.split(args, ' ')
    local entity_name = args[1]
    if entity_name == nil then
        log('Please specify a enity name')
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
        log('Entity not found')
        return
    end

    local entity_id = entity.id

    Walk.followEntity(entity_id, 2, false)

    entity = getEntity(entity_id)
    lookAt(entity.pos[1], entity.pos[2]+entity.width-0.2, entity.pos[3])


end

command.commands.say = function (args)
    say(args)
end

command.commands.craft = function (args)
    local item = args
    if item == nil then
        log('Please specify an item')
        return
    end

    if string.sub(item, 1, 10) ~= 'minecraft:' then
        log('A minecraft id must be specified')
    end

    Crafting.craft(item, 1)
end

command.commands.drop = function (args)
    local item = args
    if item == nil then
        log('Please specify an item')
        return
    end

    if string.sub(item, 1, 10) ~= 'minecraft:' then
        log('A minecraft id must be specified')
        return
    end

    item = Inventory.findItem(item)
    if next(item) == nil then
        log('Item not found')
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
    local item_name = nil
    local entity_name = nil

    args = Str.split(args, ' ')
    if #args ~= 2 then
        log('Please specify an item and an entity')
        return
    end

    entity_name = args[1]
    item_name = args[2]

    if string.sub(item_name, 1, 10) ~= 'minecraft:' then
        log('A minecraft id must be specified')
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
        log('Entity not found')
        return
    end

    local entity_id = entity.id
    local item = Inventory.findItem(item_name)
    if next(item) == nil then
        Crafting.craft(item_name, 1)
        item = Inventory.findItem(item_name)
        if next(item) == nil then
            log('Could not craft item')
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

return command
