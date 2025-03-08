local gutil = require("ghostUtils")
local fs = require("filesystem")
local gtemp = "/temp/ghost"
local tempFileReq = fs.concat(gtemp, "JumbledIDToNM")
local tempFile = tempFileReq .. ".lua"
local mod = ""
function makeTemp(outputPath)
    local file = io.open("/itemTable.lua", "rb")
    local fileout = gutil.open(tempFile, "w")

    fileout:write("local tab = {\r\n")
    for line in file:lines() do
        local temp = line:match("    (.+)={$")
        --print(mod)
        if temp then
            mod = temp
        end
        local name, id = line:match("        (.+)={id=\"(%d+)")
        if name then
            fileout:write(string.format("[%d]={mod=%q,name=%q}, \r\n", id, mod, name))
        end
    end
    fileout:write("}\r\n return tab")
    fileout:close()
end

local function main()
    if not fs.exists(gtemp) then
        fs.makeDirectory(gtemp)
    end
    makeTemp()
    local trash = require(tempFileReq)
    fs.remove(tempFile)
    local sorttrash = gutil.sortKeys(trash)
    local file = gutil.open("/idToNameModMapping.lua", "w")
    file:write("local idToNameMod = {\r\n")
    for _, id in ipairs(sorttrash) do
        local mod = trash[id].mod
        local name = trash[id].name
        file:write(string.format("[%d]={mod=%q,name=%q}, \r\n", id, trash[id].mod, name))
    end
    file:write("}\r\n return idToNameMod")
    file:close()
end
return main
