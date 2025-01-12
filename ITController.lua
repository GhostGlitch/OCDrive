local fs = require("filesystem")
local shell = require("shell")
local ev = require("event")
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
coup = coroutine.create(update)
local bad = false
local function upup()

    a, b, c, d, e = coroutine.resume(coup)
    if a then
        print(a,b,c,d,e)
    elseif not bad then
        print(a,b,c,d,e)
        bad = true
    end
    --update()
    --print("update")
end
--upup()
ev.timer(0, upup, 100000)