Libs = require('libs/init')

local state = {}

state.state = {}
state.path = "./state.json"

state.load = function()
    local sucess, result = pcall(Json.read, state.path)
    if sucess then
        state.state = result
    elseif Str.errorResume(result) == 'Script was stopped' then
        error('Script was stopped')
    end
end

state.save = function()
    Json.dump(state.state, state.path)
end

state.clear = function()
    state.state = {}
    state.save()
end

state.set = function(key, value)
    state.state[key] = value
    state.save()
end

state.get = function(key)
    return state.state[key]
end

state.load()

return state
