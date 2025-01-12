---@diagnostic disable: need-check-nil, undefined-field
--TODO: Test Headless mode
local MIN_GUTIL_VER = 1.3
local MIN_GCOMP_VER = 1.0
local ROLE = "NOROLE"
local SELF = "autorun.lua"

local term = require("term")
local comp = require("component")
local shell = require("shell")
local fs = require("filesystem")
local gutil = require("ghostUtils")
local event = require("event")
--required for certain setups to respect the command.
local function toRoot()
    shell.setWorkingDirectory("/")
end
event.timer(0,toRoot,1)
local function swithToRole(shouldPrint)
    if ROLE == "NOROLE" then
        gutil.printIf(shouldPrint, "Initialization complete.")
    else
        local RoleScript = shell.resolve(ROLE, "lua") or ("/" .. ROLE .. ".lua")
        if not fs.exists(RoleScript) then
            gutil.angryPrintIf(shouldPrint,
                "Error: Role \"" .. ROLE .. ".lua\" not found. What was I supposed to be doing?")
            os.exit()
        end
        gutil.printIf(shouldPrint, "Initialization complete. Transitioning to " .. ROLE)
        os.execute(RoleScript)
    end
    os.exit()
end

if not term.isAvailable() then
    swithToRole(false)
end

local gcomp = require("ghostComp")

if gutil.version == nil or gutil.version < MIN_GUTIL_VER then
    comp.gpu.setForeground(0xFF0000)
    print("Error: autorun.lua requires at least version " .. MIN_GUTIL_VER .. " of ghostUtils")
    comp.gpu.setForeground(0xFFFFFF)
    return
end

if not gutil.checkGVer(gcomp, MIN_GCOMP_VER, SELF, "ghostComp.lua") then
    return
end

local gpu = comp.gpu
local screen = comp.screen
local scrcfgPath = fs.concat("/etc/screens", screen.address)
local scrcfgBakPath = fs.concat("/etc/screens", screen.address .. ".bak")
local scrcfgBadBakPath = fs.concat("/etc/screens", screen.address .. ".borked")
local res = shell.resolve("res", "lua") or "/res.lua"
local angryPrint = gutil.angryPrint
local happyPrint = gutil.happyPrint
local uneasyPrint = gutil.uneasyPrint

local function setResFromCfg(cfgPath)
    if not fs.exists(cfgPath) then
        uneasyPrint("No previous config found.")
        return false
    end
    print("Previous config found.")
    
    local cfg = gutil.readFile(cfgPath)
    local x, xRaw, xLine = gutil.parseCfgVal(cfg, "X")
    local y, yRaw, yLine = gutil.parseCfgVal(cfg, "Y")
    local width, widthRaw, widthLine = gutil.parseCfgVal(cfg, "Width")
    local height, heightRaw, heightLine = gutil.parseCfgVal(cfg, "Height")

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

    local ScrX, ScrY = comp.screen.getAspectRatioSmart()
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


swithToRole(true)