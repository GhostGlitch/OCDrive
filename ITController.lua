local fs = require("filesystem")
local shell = require("shell")
local args, ops = shell.parse(...)
local isNew = (ops["new"] or ops["n"]) or not fs.exists("/itemTable.lua")
if isNew then
    os.execute("parseItemsMem.lua")
    os.execute("makeIDToNameModTable")
end
os.execute("test.lua")