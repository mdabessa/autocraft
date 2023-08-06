local logger = {}

logger.verbose = true
logger.callback = nil
logger.filepath = '../../logs/' .. Str.generateFileName() .. '.log'

logger.log = function (msg)
    if logger.verbose then
        log(msg)
    end
    if logger.callback ~= nil then
        logger.callback(msg)
    end

    if logger.filepath ~= nil then
        local file = io.open(logger.filepath, 'a')
        local date = os.date("%d-%m-%Y %H:%M:%S %z")

        file:write("[" .. date .. "] " .. msg .. "\n")
        file:close()
    end
end

return logger
