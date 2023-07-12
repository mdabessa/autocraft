Libs = require('libs/init')


local function craft(item, qtd, timeout)
    qtd = qtd or 1

    local results = {}
    local x, y = -10000, 0

    for i=1, qtd do
        say('/clear')
        sleep(200)
        say('/gamemode creative')
        if i%2==1 then x = x + 10000 else y = y + 10000 end
        say('/tp ' .. tostring(x) .. ' 300 ' .. tostring(y))
        sleep(1000)

        while true do
            local player = getPlayer()
            if player.fallDist < 1 then break end
        end
        say('/gamemode survival')

        local result = {
            ['status'] = true,
            ['error'] = nil
        }
        local start = os.time()
        local t = Command.execute('craft ' .. item, function (stt, err)
            result['status'] = stt
            if err ~= nil then
                result['error'] = Str.errorResume(err)
            end
        end)

        while true do
            if t.getStatus() == 'done' then break end
            if timeout ~= nil and os.time() - start > timeout then
                t:stop()
                sleep(200)
                result['error'] = 'Timeout'
                break
            end
        end
        local _end = os.time()

        result['timeTaken'] = _end - start
        result['timeStart'] = start
        result['timeEnd'] = _end

        table.insert(results, result)
    end
    Json.dump({['tests'] = results}, './test.json')
end


craft('minecraft:stick', 10, 30)

