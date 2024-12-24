local ser = require("serialization")

local gnet = {}
gnet.version = 0.5

if _VERSION == 5.2 then
    local compress = require("compression")

    function gnet.compressTable(table)
        local serialized = ser.serialize(table)
        return compress:Compress(serialized)
    end

    function gnet.decompressTable(str)
        local decompressed = compress:Decompress(str)
        return ser.unserialize(decompressed)
    end
end

function gnet.printSerializedSize(serialized, tblName)
    print(string.format("%s length: %d bytes", tblName, #serialized))
end

return gnet