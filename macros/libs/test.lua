Libs = require('libs/init')

local test = {}


test.craftTest = function(item, qtd, timeout)
    qtd = qtd or 1
    timeout = timeout or (60*5)
    qtd = tonumber(qtd)
    timeout = tonumber(timeout)

    local filename = Str.generateFileName() .. '.json'
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
        if result['error'] == nil then
            Logger.log('Success')
        else
            Logger.log('Error: ' .. result['error'])
        end

        result['endPos'] = getPlayer().pos
        result['timeTaken'] = _end - start
        result['timeStart'] = start
        result['timeEnd'] = _end

        table.insert(results, result)
        Logger.callback = nil

        local path ='.\\tests\\' .. filename
        Json.dump({
            ['tests'] = results,
            ['type'] = 'craft',
            ['item'] = item,
            ['qtd'] = qtd,
            ['timeout'] = timeout
        }, path)
    end
end


test.walkTest = function(max_tries)
    max_tries = max_tries or 1
    max_tries = tonumber(max_tries)

    local filename = Str.generateFileName() .. '.json'
    local results = {}

    -- Display HUD
    Hud.clear()
    local title_hud, _ = Hud.addText('Walk Test', 2, 2)
    title_hud.setTextSize(7)

    local pos_hud = Hud.addText('Pos: ', 2, 11)
    pos_hud.setTextSize(7)

    local last_dist_hud = Hud.addText('Last test distance: ', 2, 29)
    last_dist_hud.setTextSize(7)

    local test_hud = Hud.addText('Test: 0/' .. tostring(max_tries), 2, 38)
    test_hud.setTextSize(7)

    Hud.enable()
    local th = thread.new(function ()
        while true do
            local pos = getPlayer().pos
            pos_hud.setText('Pos: ' .. tostring(pos[1]) .. ' ' .. tostring(pos[2]) .. ' ' .. tostring(pos[3]))
            sleep(100)
        end
    end)

    th:start()

    for i=1, max_tries do
        test_hud.setText('Test: ' .. tostring(i) .. '/' .. tostring(max_tries))
        local result = {}
        local start = os.time()

        local pos = getPlayer().pos

        local box = Calc.createBox({29999999, 60, pos[3]}, {10, 255, 10})
        local status, err = pcall(function ()
            Walk.walkTo(box, 50)
        end)

        if status then
            result['error'] = nil
            result['traceback'] = nil
        else
            if Str.errorResume(err) == 'Script was stopped' then
                error('Script was stopped')
            end

            result['error'] = Str.errorResume(err)
            result['traceback'] = err
        end
        Logger.log(err)
        result['status'] = status
        result['startPos'] = pos
        result['endPos'] = getPlayer().pos
        result['timeTaken'] = os.time() - start
        result['timeStart'] = start
        result['timeEnd'] = os.time()

        local dist = Calc.distance3d(result['startPos'], result['endPos'])
        last_dist_hud.setText('Last test distance: ' .. tostring(dist))

        table.insert(results, result)
        local path ='.\\tests\\' .. filename
        Json.dump({
            ['tests'] = results,
            ['type'] = 'walk',
            ['max_tries'] = max_tries
        }, path)

        if i < max_tries then
            say('/clear')
            sleep(200)
            say('/gamemode creative')
            sleep(200)
            say('/tp 0 300 ' .. tostring(getPlayer().pos[3] + 10000))

            sleep(5000)
            while true do
                local player = getPlayer()
                if player.fallDist < 1 then break end
            end

            say('/gamemode survival')
        end
    end

    th:stop()
    Hud.clear()
end

return test
