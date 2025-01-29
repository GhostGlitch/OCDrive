local fs = require("filesystem")
local shell = require("shell")
local ev = require("event")
local args, ops = shell.parse(...)
local isNew = (ops["new"] or ops["n"]) or not fs.exists("/itemTable.lua")
local function notNew()
    print("notNew")
    local test = require("test")
    test()
end
local function aftert4()
    print("AT4")
    local make = require("makeIDToNameModTable")
    make("ITConTest")
    notNew()
end
--os.execute("librel")
local event = require("event")
local coro = require("coroutine")
local cofu = require("parseItemsCo")
print(cofu)
local ev = require("event")
local term = require("term")
local gutil = require("ghostUtils")

local coco =  coro.create(cofu)
local lastX = 0
local lastY = 0
local lastL1 = ""
local lastL2 = ""
local maxCur = 0

local function redrawOnEnter(_, _, _, keycode)
    if keycode == 0x1C then

        --somehow more responsive than a direct call
        local function rebox(yadd)
            gutil.printBox(lastX, lastY + yadd, lastL1)
        end
        --rebox(1)
        local tx, ty = term.getCursor()
        if ty == gutil.gpuY then
            rebox(1)
        end
        --rebox()
    end
end

local function stopEvents()
    file = io.open("timerID", "r")
    if file then
        for line in file:lines() do
            local listener = tonumber(line)
            if event.cancel(listener) then
                print("Listener cancelled")
            else
                print("Listener not found")
            end
        end

        file:close()
    end
end
local CTIME
local function coroDo()
    if coco and coro.status(coco) == "running" then
        print("TOO FAST")
        return
    end
    if not coco or coro.status(coco) == "dead" then
        --os.exit()
        coco = coro.create(cofu)
    end
    --local a, b = table.unpack(resumeTable[coVal])
    stat, coVal = coro.resume(coco)
    if coVal == "DONE"  then
        print("stop")
        stopEvents()
        file = gutil.open("TableMade", "w")
        file:write("true")
        file:close()
    end
    local x, y = term.getCursor()
    lastX, lastY = 1, 1
    lastL1 = coVal
    gutil.printBox(lastX, lastY, coVal)
end

local function startTime()
    local timer = ev.timer(0, coroDo, math.huge)
    CTIME = timer
    --local listener = ev.listen("key_down", redrawOnEnter)
    return timer--, listener
end

function test4()
    if ops["stop"] or ops["s"] then
        print("stopping timer")
        stopEvents()
    else
        stopEvents()
        timer, listener = startTime()
        file = io.open("timerID", "w")
        file:write(timer)
        --file:write("\n")
        --file:write(listener)
        file:close()
    end
end
local garbageTimer
local function checkForGarbage()
    if fs.exists("/TableMade") then
        print("table is good")
        ev.cancel(garbageTimer)
        fs.remove("/TableMade")
        aftert4()
    end
end
if true or isNew then
    garbageTimer = ev.timer(1, checkForGarbage, math.huge)
    test4()
else
    notNew()
end