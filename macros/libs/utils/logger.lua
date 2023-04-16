local logger = {}

logger.verbose = false

logger.log = function (msg)
    if logger.verbose then
        log(msg)
    end
end

return logger
