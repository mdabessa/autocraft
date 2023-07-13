local logger = {}

logger.verbose = true
logger.callback = nil

logger.log = function (msg)
    if logger.verbose then
        log(msg)
    end
    if logger.callback ~= nil then
        logger.callback(msg)
    end
end

return logger
