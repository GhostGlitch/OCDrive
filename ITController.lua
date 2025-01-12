local fs = require("filesystem")
local shell = require("shell")
local args, ops = shell.parse(...)
local isNew = (ops["new"] or ops["n"]) or not fs.exists("/itemTable.lua")
if isNew then
    os.execute("parseItemsMem.lua")
end
local idk = require("idk")
local itemTable = require("itemTable")
if isNew then
    idk.makeIDToNameModTable(itemTable, "/idToNameMod.lua")
end
local update = require("ITUpdate")
