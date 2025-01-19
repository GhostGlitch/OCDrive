local fs = require("filesystem")
local shell = require("shell")
local ev = require("event")
local args, ops = shell.parse(...)
local isNew = (ops["new"] or ops["n"]) or not fs.exists("/itemTable.lua")
local function notNew()
    print("notNew")
    t = require("test")
    t()
end
local function aftert4()
    print("AT4")
    make = require("makeIDToNameModTable")
    make()
    notNew()
end
if true or isNew then
    t4 = require("test4")
    t4()

    ev.listen("itable_made", aftert4)
else
    notNew()
end