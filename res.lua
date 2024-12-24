local fs = require("filesystem")
local comp = require("component")
local gutil = require("ghostUtils")
local gmath = require("ghostMath")
local serialization = require("serialization")

XSCALE = 2
YSCALE = 1
MULTOVERSHOOT = 1.1
RowsPerY = 16
ScrX, ScrY = comp.screen.getAspectRatio()
Multiplier = 1
 NewX = 0
 NewY = 0

 --correct for bezel and character size
local aspectX = ((ScrX  * 16) - 4) * XSCALE
local aspectY = ((ScrY * 16) - 4) * YSCALE

local maxX, maxY = comp.gpu.maxResolution()
--Ensure that the high "aspect" value is paired with the high "max" value
if aspectX < aspectY then
    maxX, maxY = maxY, maxX
end
if not fs.exists("/etc/screens") then
    fs.makeDirectory("/etc/screens")
end

local function normalizeRat(x, y)
    local tst = (RowsPerY * ScrY) / y
    y = tst * y
    x = tst * x
    return x, y
end

--print(aspectX, aspectY)
aspectX, aspectY = gmath.simplifyRat(aspectX, aspectY)
--print(aspectX, aspectY)
aspectX, aspectY = normalizeRat(aspectX, aspectY)
--print(aspectX, aspectY)

local function rescale()
    NewX = aspectX * Multiplier
    NewY = aspectY * Multiplier
end
local function scaleUp()
    Multiplier = Multiplier + 1
    rescale()
end
local function scaleDown(rate)
    Multiplier = Multiplier - rate
    rescale()
end

rescale()
while NewX * NewY < maxY * maxX * .9 and NewY < ScrY * RowsPerY do
        scaleUp()
        --print("too small")
end
while NewX * NewY > maxY * maxX * 1.1 or NewY > ScrY * RowsPerY do
    if Multiplier > 1 then

        scaleDown(.1)
        --print("too big")
    else
        break
    end
end

local status = false
local result
while true do
    local roundX = math.floor(NewX -0.1)
    local roundY = math.floor(NewY + .3)
    --print("Trying resolution: " .. roundX .. "x" .. roundY)
    status, result = pcall(comp.gpu.
    setResolution, roundX, roundY)
    if status then
        --print(NewY, roundY)
        --print("mult:" .. Multiplier)
        comp.gpu.setResolution(roundX, roundY)
        print("Resolution set to " .. roundX .. "x" .. roundY)

        config = fs.concat("/etc/screens", comp.screen.address)
        file = io.open(config, "w")
        file:write("-----Screen Config-----\n\n")
        file:write("Width=" .. ScrX.. "\n")
        file:write("Height=" .. ScrY.. "\n")
        file:write("X=" .. roundX .. "\n")
        file:write("Y=" .. roundY .. "\n")
        file:close()

        break
    end
    --gutil.waitForAny(false)
    --print("Too large, decreasing")
    scaleDown(.005)
end