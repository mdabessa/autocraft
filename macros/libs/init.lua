Str = require('utils/str')

function script_path()
    local str = Str.split(debug.getinfo(1, "S").source, "\\")
    table.remove(str, #str)
    return table.concat(str, "\\")
end

function evalfile(filename, env)
    local f = assert(loadfile(filename))
    return f()
end

function eval(text)
    local f = assert(load(text))
    return f()
end

function errorhandler(err)
    return debug.traceback(err)
end

function include(filename)
    filename = script_path() .. '\\' .. filename .. '.lua'
    local success, result = xpcall(evalfile, errorhandler, filename)
    if not success then
        print("[ERROR]\n",result,"[/ERROR]\n")
    end
    return result
end

function include_noerror(filename)
    filename = script_path() .. '\\' .. filename .. '.lua'
    local success, result = xpcall(evalfile, errorhandler, filename)
    --print(string.format("success=%s filename=%s\n", success, filename))
end

Calc = include('utils/calc')
Str = include('utils/str')
Table = include('utils/table')
Logger = include('utils/logger')
Json = include('utils/json')
Dictionary = include('dictionary')
Hud = include('hud')
Inventory = include('inventory')
World = include('world')
Action = include('action')
Walk = include('walk')
Home = include('home')
Miner = include('gathering/miner')
Wood = include('gathering/wood')
Farm = include('farm')
Crafting = include('crafting')
Command = include('command')
Database = include('db')
Test = include('test')
