local command = {}

command.execute = function(str)
    local content = Str.split(str, ' ')
    local cmd = content[1]
    local args = ''

    if #content > 1 then
        for i = 2, #content do
            args = args .. content[i] .. ' '
        end
        args = args:sub(1, -2)
    end

    if command.commands[cmd] ~= nil then

        local cmd_thread = thread.new( function ()
            pcall(command.commands[cmd], args)
        end)

        cmd_thread:start()
        return true
    end

    return false
end

command.commands = {}

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
        if entities[i].name == entity_name then
            entity = entities[i]
            break
        end
    end

    if entity == nil then
        log('Entity not found')
        return
    end

    local entity_id = entity.id
    local min_dist = 2

    if args[2] ~= nil then
        local num = tonumber(args[2])
        if num ~= nil then
            min_dist = num
        end
    end


    Walk.followEntity(entity_id, min_dist)
end

command.commands.say = function (args)
    say(args)
end

return command
