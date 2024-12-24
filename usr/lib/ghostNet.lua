local compress = require("compression")
local ser = require("serialization")

local gnet = {}
function gnet.compressTable(table)
    local serialized = ser.serialize(table)
    return compress:Compress(serialized)
end

function gnet.decompressTable(str)
    local decompressed = compress:Decompress(str)
    return ser.unserialize(decompressed)
end

function gnet.printSerializedSize(serialized, tblName)
    print(string.format("%s length: %d bytes", tblName, #serialized))
end

return gnet