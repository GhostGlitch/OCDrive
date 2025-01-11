local comp = require("component")
local serial = require("serialization")
local gdbg = {}

gdbg.version = 0.1

local debugFunctions = {
    printIf = function(bool, ...)
        if bool then
            print(...)
        end
    end,
    isNative = function()
        return not comp.isAvailable("ocemu")
    end,
    printIfDelay = function(bool, delay, ...)
        if bool then
            print(...)
            os.sleep(delay)
        end
    end,
    printTable = function(table, pretty)
        print(serial.serialize(table, pretty))
    end,
    librel = function()
        os.execute("librel")
    end,
}

local noOpFunctions = {
    printIf = function(...) end,
    isNative = function(...) return true end,
    printIfDelay = function(...) end,
    librel = function(...) end,
    printTable = function (...) end
}

function gdbg.getDebug(isDebug, shouldLibrel)
    if isDebug then
        if shouldLibrel then
            debugFunctions.librel()
            return require("ghostDebug").getDebug(true, false)
        else
            return debugFunctions
        end
    else
        return noOpFunctions
    end
end

return gdbg