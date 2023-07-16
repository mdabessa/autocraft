Libs = require('libs/init')


local function craft(item, qtd, timeout)
    qtd = qtd or 1

    local results = {}

    for i=1, qtd do
        Home.resetHome()
        Miner.resetMinePoints()
        local pos = getPlayer().pos
        local x = pos[1]
        local y = pos[3]

        say('/clear')
        sleep(200)
        say('/gamemode creative')
        if i%2==1 then x = x + math.random(5000, 10000) else y = y + math.random(5000, 10000) end
        say('/tp ' .. tostring(x) .. ' 300 ' .. tostring(y))
        sleep(1000)

        while true do
            local player = getPlayer()
            if player.fallDist < 1 then break end
        end
        say('/gamemode survival')

        local result = {
            ['status'] = true,
            ['startPos'] = {x,0,y},
            ['world'] = getWorld(),
            ['biome'] = getBiome(),
            ['error'] = nil,
            ['traceback'] = nil,
            ['log'] = {}
        }

        Logger.callback = function (msg)
            table.insert(result['log'], {['time'] = os.time(), ['message'] = msg})
        end

        local start = os.time()
        local t = Command.execute('craft ' .. item, function (stt, err)
            result['status'] = stt
            if err ~= nil then
                result['error'] = Str.errorResume(err)
                result['traceback'] = err
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

        result['endPos'] = getPlayer().pos
        result['timeTaken'] = _end - start
        result['timeStart'] = start
        result['timeEnd'] = _end

        table.insert(results, result)
        Logger.callback = nil
        Json.dump({['tests'] = results}, './test.json')
    end
end


craft('minecraft:stone_sword', 20, 60*3)

