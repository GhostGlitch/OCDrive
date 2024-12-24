---@diagnostic disable: need-check-nil, undefined-field
local MIN_GUTILS_VER = 1
local ROLE = "test"


local fs = require("filesystem")
local comp = require("component")
local shell = require("shell")
local term = require("term")


local gutils = require("ghostUtils")
if gutils.version == nil or gutils.version < MIN_GUTILS_VER then
    comp.gpu.setForeground(0xFF0000)
    print("Error: autorun.lua requires at least version" .. MIN_GUTILS_VER .. "of ghostUtils")
    comp.gpu.setForeground(0xFFFFFF)
    return
end
local RoleScript = shell.resolve(ROLE, "lua") or ("/" .. ROLE .. ".lua")
if not comp.isAvailable("gpu") or not comp.isAvailable("screen") then
    os.execute(RoleScript)
    return
end

local gpu = comp.gpu
local screen = comp.screen
local scrcfgPath = fs.concat("/etc/screens", screen.address)
local scrcfgBakPath = fs.concat("/etc/screens", screen.address .. ".bak")
local scrcfgBadBakPath = fs.concat("/etc/screens", screen.address .. ".borked")
local res = shell.resolve("res", "lua") or "/res.lua"
local angryPrint = gutils.angryPrint
local happyPrint = gutils.happyPrint
local uneasyPrint = gutils.uneasyPrint

local function setResFromCfg(cfgPath)
    if not fs.exists(cfgPath) then
        uneasyPrint("No previous config found.")
        return false
    end
    print("Previous config found.")
    
    local cfg = gutils.readFile(cfgPath)
    local x, xRaw, xLine = gutils.parseCfgVal(cfg, "X")
    local y, yRaw, yLine = gutils.parseCfgVal(cfg, "Y")
    local width, widthRaw, widthLine = gutils.parseCfgVal(cfg, "Width")
    local height, heightRaw, heightLine = gutils.parseCfgVal(cfg, "Height")

    if xLine == "" or yLine == "" or widthLine == "" or heightLine == "" then
        angryPrint("Some Keys not found... What did you do??")
        return false
    end
    if not (xRaw and yRaw and widthRaw and heightRaw) then
        angryPrint("Why did you delete values from the config? *sigh*")
        return false
    end
    if not (x and y and width and height) then
        angryPrint("Some values in config are not numbers...")
        return false
    end
    if width < 1 or height < 1 or x < 1 or y < 1 then
        angryPrint("Some values are too small or negative..")
        return false
    end
    local ScrX, ScrY = comp.screen.getAspectRatio()
    if width ~= ScrX or height ~= ScrY then
        angryPrint("Screen size has changed since last boot.")
        return false
    end
    local status, _ = pcall(gpu.setResolution, x, y)
    if not status then
        angryPrint("Config resolution too large.")
        return false
    end
    happyPrint("Resolution set to " .. x .. "x" .. y)
    return true
end

local function fixScrCfg()
    local function generate()
        gpu.setForeground(0x00FF00)
        os.execute(res)
        gpu.setForeground(0xFFFFFF)
    end

    if not fs.exists(scrcfgPath) then
        print("Generating.")
        generate()
        return
    end

    uneasyPrint("saving backup of bad config to " .. screen.address .. ".borked")
    fs.copy(scrcfgPath, scrcfgBadBakPath)

    if not fs.exists(scrcfgBakPath) then
        uneasyPrint("Regenerating")
        generate()
        return
    end

    gpu.setForeground(0xFFFF00)
    print("Trying from backup config.")
    
    if setResFromCfg(scrcfgBakPath) then
        print("Backup was good, restoring as config file")
        fs.copy(scrcfgBakPath, scrcfgPath)
        gpu.setForeground(0xFFFFFF)
        return
    end
    gpu.setForeground(0xFF0000)
    print("...")
    print("REALLY? You messed up the backup too???")
    print("Regenerating")
    gpu.setForeground(0xFFFF00)
    os.execute(res)
end

--os.sleep(.01)
term.clear()
if not fs.exists(res) then
    error("Error: res.lua not found. Ensure it is installed as it is required for autorun.lua to function")
    os.sleep(3)
    return
end
print("Fixing Resolution")
if not setResFromCfg(scrcfgPath) then
    fixScrCfg()
else
    print("Saving backup of config to " .. screen.address .. ".bak")
    fs.copy(scrcfgPath, scrcfgBakPath)
end
--os.sleep(1)

if not fs.exists(RoleScript) then
    angryPrint("Error: Role \"" .. ROLE .. ".lua\" not found. What was I supposed to be doing?")
    return
end

print("Initialization complete. Transitioning to " .. ROLE)
os.execute(RoleScript)