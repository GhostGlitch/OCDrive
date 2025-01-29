local fs = require("filesystem")
local shell = require("shell")
local ev = require("event")
local term = require("term")
local gutil = require("ghostUtils")
local coro = require("coroutine")

local COFU
local COCO
local CODELAY_N = 0
local CODELAY_U = 1
local LIS_STOP_DELAY = .5
local genTracker = false
local listenerPath = "/tmp/ITListeners"

local lastX = 0
local lastY = 0
local lastL1 = ""
local lastL2 = ""
local lastFore = nil
local lastBack = nil
local function printBox(x, y, foreground, background, messageL1, messageL2)
    lastX, lastY = x,y
    lastL1, lastL2 = messageL1, messageL2
    lastFore, lastBack = foreground, background
    gutil.printBox(lastX, lastY,foreground,background, lastL1, lastL2)
end
local args, ops = shell.parse(...)
local isNew = (ops["new"] or ops["n"]) or not fs.exists("/itemTable.lua")
local function stopListeners()
    local file = io.open(listenerPath, "r")
    if file then
        for line in file:lines() do
            local listener = tonumber(line)
            if ev.cancel(listener) then
                printBox(1, 1, nil, nil, "Listener cancelled")
                os.sleep(LIS_STOP_DELAY)
            else
                printBox(1, 1, gutil.vibes.uneasy, nil, "Listener not found")
                os.sleep(LIS_STOP_DELAY)
            end
        end
        file:close()
    end
    fs.remove(listenerPath)
end

if ops["stop"] or ops["s"] then
    print("Stopping timers")
    stopListeners()
    return
end

local function redrawOnEnter(_, _, _, keycode)
    if keycode == 0x1C then
        --somehow more responsive than a direct call
        local function rebox(yadd)
            gutil.printBox(lastX, lastY + yadd,lastFore, lastBack, lastL1)
        end
        --print(lastX, lastY, lastL1)
        local tx, ty = term.getCursor()
        if ty == gutil.gpuY then
            rebox(1)
        end
    end
end

local function cocoDo()
    if COCO and coro.status(COCO) == "running" then
        printBox(1,1,gutil.vibes.angry, nil, "TOO FAST")
        return
    end
    if not COCO or coro.status(COCO) == "dead" then
        COCO = coro.create(COFU)
    end
    local stat, coVal, vibe = coro.resume(COCO)
    if not vibe then vibe = gutil.vibes.neutral end
    --print(stat, coVal)
    if coVal == "DONE" then
        if isNew then
            printBox(1,1, vibe, nil, "STOPPING")
            stopListeners()
            genTracker = true
        end
    end
    printBox(1, 1, vibe, nil, coVal)
end
local function startEnterListener()
    if not fs.exists("/tmp/ITEnLis") then
        local file = gutil.open("/tmp/ITEnLis", "w")
        file:write("true")
        file:close()
        ev.listen("key_down", redrawOnEnter)
    end
end

local function startCoro(req, codel)
    stopListeners()
    COFU = require(req)
    COCO = coro.create(COFU)
    local timer = ev.timer(codel, cocoDo, math.huge)
    startEnterListener()
    local file = gutil.open(listenerPath, "w")
    file:write(timer)
    file:close()
end
local function update()
    printBox(1, 1, gutil.vibes.uneasy, nil, "STARTING UPDATE")
    os.sleep(CODELAY_U)
    startCoro("ITUpdate", CODELAY_U)
end

local genTrackerTimer
local function checkForGenTracker()
    if genTracker then
        ev.cancel(genTrackerTimer)
        genTracker = false
        printBox(1, 1,gutil.vibes.neutral, nil, "Making ID Conversion Table")
        os.sleep(CODELAY_U)
        local make = require("makeIDToNMMem")
        make()
        isNew = false
        update()
    end
end
if isNew then
    genTrackerTimer = ev.timer(1, checkForGenTracker, math.huge)
    startCoro("parseItemsCo", CODELAY_N)
else
    update()
end