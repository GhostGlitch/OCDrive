--os.execute("librel")
local shell = require("shell")
local args, ops = shell.parse(...)
local event = require("event")
local coro = require("coroutine")
local cofu = require("ITUpdate")
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
    if coVal == "DONE" then
        --print("done")
        os.exit()
    end
    local x, y = term.getCursor()
    lastX, lastY = 1, 1
    lastL1 = coVal
    gutil.printBox(lastX, lastY, coVal)
end

local function startTime()
    local timer = ev.timer(0, coroDo, math.huge)
    local listener = ev.listen("key_down", redrawOnEnter)
    return timer, listener
end


local function stopEvents()
    file = io.open("timerID", "r")
    local timer = file:read("l")
    local listener = file:read("l")
    timer, listener = tonumber(timer), tonumber(listener)
    if event.cancel(timer) then
        print("timer canceled")
    else
        print("could not cancel timer")
    end
    if event.cancel(listener) then
        print("listener canceled")
    else
        print("could not cancel listener")
    end
    file:close()
end


if ops["stop"] or ops["s"] then
    print("stopping timer")
    stopEvents()
else
    stopEvents()
    timer, listener = startTime()
    file = io.open("timerID", "w")
    file:write(timer)
    file:write("\n")
    file:write(listener)
    file:close()
end
