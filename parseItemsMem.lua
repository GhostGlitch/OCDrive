local fs = require("filesystem")
local gutil = require("ghostUtils")
local gstring = require("ghostString")
local puter = require("computer")
local shell = require("shell")
local args, ops = shell.parse(...)
if puter.totalMemory() < 27000 then
    error("Craft or Download more RAM")
end

local VERBOSE = false
if ops["v"] or ops["verbose"] then
    VERBOSE = true
end

local SrcCsvPath = args[1] or "/item.csv"
local TempOutputDir = "/temp/ghost/parseItems"
local ModCSVDir = fs.concat(TempOutputDir, "modcsv/")
local FinalItemTablePath = "/itemTable.lua"
--local ModCSVBufferSize = 30
local gpu = require("component").gpu

local curMod = nil
local modList = {}
local collisionFilePath = "/itemTableCollisions.txt"

local parsePatterns = {
    modAliases = {
        ["crowley.skyblock"] = "exnihilo",
        AWWayofTime = "BloodMagic"
    },
    generalNamespaces = {
        name = {
            "tile[s]?",    -- Remove "tile." at the start
            "block[s]?",   -- Remove "block." at the start
            "item[s]?",  -- Remove "item." at the start
            "tool[s]?",
            "armo[u]?r",
        },
        class = {
           ".*iguanaman",
            "core",
            "common",
            "shared",
            "base",
            "item[s]?",
            "block[s]?",
        }
    },
    modNamespaces = {
        --for mods which use a different name for their identifier, and in item names.
        name = {
            AppliedEnergistics     = {"appeng"},
            BloodMagic             = {"AWWayofTime"},
            exnihilo               = {"crowley%.skyblock"},
            ExtraUtilities         = {"extrautils"},
            Forestry               = {"for"},
            ForgeMicroblock        = {"microblock"},
            HungerOverhaul         = {"pamharvestcraft"},
            IguanaTweaksTConstruct = {"tconstruct"},
            MineFactoryReloaded    = {"mfr"},
            OpenComputers          = { "oc" },
            TConstruct             = {"decoration"}
        },
        --for mods which use a different name for their identifier, and in class paths.
        class = {
            AppliedEnergistics     = {"appeng"},
            BloodMagic             = {"alchemicalwizardry"},
            ExtraUtilities         = {"extrautils"},
            ForgeMicroblock        = {"microblock"},
            JABBA                  = {"betterbarrels"},
            OpenComputers          = {"oc"},
            OpenPeripheral         = {"openperipheral%.addons"},
            gendustry              = {"gendustry", "bdew"},
            ThermalExpansion       = {"thermalexpansion", "cofh"},
            BinnieCore             = {"binnie%.core"},
            ChickenChunks          = {"codechicken%.chunkloader"},
            PluginsforForestry     = {"plugins"},
            asielib                = {"asie%.lib"}
        },

    },
    modPrefixes = {
        name = {
            HardcoreQuesting = {"hqm"},
            ComputerCraft = {"cc"},
            BigReactors = {"br", "blockBR"},
            BiblioCraft = {"Biblio"},
        },
        classAsName = {
            AppliedEnergistics = {"AppEng"},
            pamharvestcraft = {"BlockPam","ItemPam"},
            ExtraTrees = {"BlockET","ItemET"},
            BigReactors = {"BR"}
        },
    },
    generalSubs = {
        pressureplate = "pressurePlate",
    },
    modSubs = {
        name = {
            TConstruct = {
                ["metal.molten"] = "molten"
            },
            extracells = {
                [" %- this item is just used to mime fluids!"] = ""
            }
        }
    },
    hardcoded = {
        byName = {
            Minecraft = {
                ["tile.mycel"] = "mycelium",
                ["tile.lightgem"] = "glowstone",
                ["tile.musicBlock"] = "noteBlock",
            },
            BiblioCraft = {
                ["tile.Bibliotheca"] = "Bookcase",
            },
        },
        byClass = {
            extracells = {
                ItemSecureStoragePhysicalEncrypted = "SecureStorageEncrypted",
                ItemSecureStoragePhysicalDecrypted = "SecureStorageDecrypted",
            },
            ExtraTrees = {
                ItemMothDatabase = "mothDatabase"
            }
        },
        byID = {
            HungerOverhaul = { ["105"] = "melonStem" },
            Minecraft = {
                ["8"] = "waterFlowing",
                ["9"] = "waterStill",
                ["10"] = "lavaFlowing",
                ["11"] = "lavaStill",
                ["39"] = "mushroomBrown",
                ["40"] = "mushroomRed",
                ["43"] = "stoneSlabDouble",
                ["61"] = "furnaceOff",
                ["62"] = "furnaceOn",
                ["63"] = "signStanding",
                ["68"] = "signWall",
                ["70"] = "pressurePlateStone",
                ["72"] = "pressurePlateWood",
                ["73"] = "redstoneOreOff",
                ["74"] = "redstoneOreOn",
                ["75"] = "redstoneTorchOff",
                ["76"] = "redstoneTorchOn",
                ["99"] = "mushroomBlockBrown",
                ["100"] = "mushroomBlockRed",
                ["105"] = "melonStem",
                ["93"] = "repeaterOff",
                ["94"] = "repeaterOn",
                ["123"] = "redstoneLampOff",
                ["124"] = "redstoneLampOn",
                ["125"] = "woodSlabDouble",
                ["149"] = "comparatorOff",
                ["150"] = "comparatorOn",
            }
        }
    }
}
local currentRenameMod = nil
local renameWidth = gpu.getResolution()
renameWidth = math.min(math.floor((renameWidth - 12) / 3), 30)


local function printPrettyRename(oldName, newName, contextType, context)
    local white = 0xFFFFFF
    local reference
    local sep = " | "
    oldName = gstring.toLength(oldName, renameWidth)
    newName = gstring.toLength(newName, renameWidth)
    if not context then
        reference = gstring.toLength("", renameWidth)
    else
        context = gstring.shorten(context, (renameWidth-(#contextType+5)))
        reference = gstring.toLength (contextType .. ": '" .. context .. "'", renameWidth)
    end

    if currentRenameMod ~= curMod then
        print("Renaming")
        print(" | " ..
        gstring.toLength("Original Name", renameWidth, "center") .. " | " ..
        gstring.toLength("New Name", renameWidth, "center") .. " | " ..
        gstring.toLength("Reference", renameWidth, "center") .. " |")
        currentRenameMod = curMod
    end
    if gpu.getDepth == 1 then
        print(sep .. oldName .. sep .. newName .. sep .. reference .. " |\n")
        return
    end

    local oldColor = gutil.writeColor(sep, white)
    gutil.writeColor(oldName, 0xFF0080)
    gutil.writeColor(sep, white)
    gutil.writeColor(newName, 0x22EEFF)
    gutil.writeColor(sep, white)
    gutil.writeColor(reference, 0xff8000)
    gutil.writeColor(" |\n", white)
    gpu.setForeground(oldColor)
end

local function printIfRename(name, newName, contextType, context)
    if name ~= newName and VERBOSE then
        printPrettyRename(name, newName, contextType, context)
    end
end

local function modFromLine(line)
    local id, type, mod, unlocalised, class = line:match("(.*),(.*),(.*),(.*),(.*)")
    mod = mod:gsub("%s", "")

    mod = parsePatterns.modAliases[mod] or mod
    if unlocalised == "tile.ForgeFiller" or id == "ID" then return nil end
    return mod
end
local function saveBuffer(buffer, outputDir, mod)
    print("Saving lines for " .. mod)
    local filePath = fs.concat(outputDir, mod .. ".csv")
    local file = gutil.open(filePath, "a")
    for _, bufferedLine in ipairs(buffer) do
        file:write(bufferedLine .. "\n")
    end
    file:close()
end
local function freeMemOverTimeMax()
    local maxFreeMemory = 0
    for _ = 1, 5 do
        local currentFreeMemory = puter.freeMemory()
        maxFreeMemory = math.max(maxFreeMemory, currentFreeMemory)
        os.sleep(.1)
    end

    return maxFreeMemory
end
local ModCSVBufferSize = math.floor(freeMemOverTimeMax() / 8192)
if VERBOSE then
    print("Using buffer size of " .. ModCSVBufferSize)
end

local function splitByModBuffered(csvPath, outputDir, bufferSize)
    if fs.isDirectory(outputDir) then
        fs.remove(outputDir)
    end
    fs.makeDirectory(outputDir)
    local csv = gutil.open(csvPath, "r")

    local buffers = {} -- Buffers for mod data
    local lineCount = 0

    -- Read the file line by line
    for line in csv:lines() do
        local mod = modFromLine(line)
        if mod then
            if not modList[mod] then
                modList[mod] = true -- Use the table as a set
            end
            -- Add the line to the buffer
            if not buffers[mod] then
                buffers[mod] = {}
            end
            table.insert(buffers[mod], line)
            if #buffers[mod] >= bufferSize then
                gutil.uneasyPrint("BUFFER FULL. DUMPING DATA")
                saveBuffer(buffers[mod], outputDir, mod)
                buffers[mod] = {} -- Clear the buffer
            end
        end

        lineCount = lineCount + 1
        if lineCount % 50 == 0 then
            os.sleep(0)
        end
    end
    gutil.uneasyPrint("READ DONE. DUMPING REMAINING")

    -- Write remaining data in buffers
    for mod, buffer in pairs(buffers) do
        if #buffer > 0 then
            saveBuffer(buffer, outputDir, mod)
        end
    end
    csv:close()
    if VERBOSE then
        print("Processed " .. lineCount .. " lines and split into mod-specific files.")
    end
end

local function stripNamespace(str, namespace, fromAnywhere)
    namespace = namespace:lower()
    local stripStr = (namespace .. "[:%.]")
    return gstring.stripIgnoreCase(str, stripStr, true, fromAnywhere)
end
local function stripEachNamespace(str, namespaceTable, fromAnywhere)
    for _, namespace in ipairs(namespaceTable) do
        str = stripNamespace(str, namespace, fromAnywhere)
    end
    return str
end
local function stripModNamespace(str, modPatterns)
    if modPatterns[curMod] then
        str = stripEachNamespace(str, modPatterns[curMod], true)
    end
        str = stripNamespace(str, curMod, true)
    return str
end
local function stripPre(str, prefixTable)
    if prefixTable[curMod] then
        for _, pattern in ipairs(prefixTable[curMod]) do
            str = gstring.stripIgnoreCase(str, pattern, true) -- Apply each pattern
        end
    end
    return str
end


local function stripNamespacesName(name)
    local newName = stripEachNamespace(name, parsePatterns.generalNamespaces.name)
    newName = stripModNamespace(newName, parsePatterns.modNamespaces.name)
    return stripEachNamespace(newName, parsePatterns.generalNamespaces.name)
end

local function cleanName(name)
    local newName = stripPre(name, parsePatterns.modPrefixes.name)

    local lowername = newName:lower()
    if lowername ~= "item" and lowername ~= "cheatyitem"
        and lowername ~= "multiitem" and lowername ~= "cheatitem"
        and lowername ~= "baseitem" then
        newName = gstring.stripIgnoreCase(newName, "Item$")
    end

    if parsePatterns.modSubs.name[curMod] then
        for from, to in pairs(parsePatterns.modSubs.name[curMod]) do
            newName = newName:gsub(from, to)
        end
    end

    newName = newName:gsub("[_%./](.)", function(match) return match:upper() end)
    for pattern, replacement in pairs(parsePatterns.generalSubs) do
        newName = newName:gsub(pattern, replacement)
    end
    return newName
end

local function cleanClass(class)
    class = class:gsub("%s", "")
    class = stripModNamespace(class, parsePatterns.modNamespaces.class)


    class = stripEachNamespace(class, parsePatterns.generalNamespaces.class)
    return class
end
local function standardizeName(name)
    local newName = name
    if newName ~= newName:upper() then
        newName = newName:gsub("^%a", string.lower)
    end
    local prefix, number = newName:match("(%a+[^T_%d*])(%d+)")
    if number and not prefix:match("Tier$") then
        newName = prefix .. "_" .. number
    end
    newName = newName:gsub(" ", "_"):gsub("%'", ""):gsub("%(", "_"):gsub("%)", "_"):gsub("%-", "_")
    return newName
end
local function finalClean(name)
    local StorageBlocks = {
        "iron", "gold", "lapis",
        "diamond", "coal", "redstone",
        "emerald", "copper", "tin",
        "lead", "silver",
    }
    local tmp = gstring.stripIgnoreCase(name, "block", true)
    local newName = name
    if tmp ~= "" then
        for _, ingot in ipairs(StorageBlocks) do
            if ingot == tmp:lower() then
                tmp = tmp .. "Block"
                break
            end
        end
        newName = tmp
    end
    tmp = gstring.stripIgnoreCase(newName, "item", true)
    if tmp ~= "" and tmp ~= "s" then
        newName = tmp
    end
    newName = standardizeName(newName)
    return newName
end

local function fixNameFromType(oldName, item, _)
    if item.type == "Block" then
        return oldName .. "Block"
    end
    return oldName
end

local function fixNameFromClassCore(oldName, item, tryPostfix)
    local classFinal = gstring.extractLastSegDot(item.class)
    local newName = classFinal
    local prefix, number = oldName:match("(%a+)[_%.]?(%d+)")
    oldName = prefix or oldName
    if tryPostfix then
        local classPostfix = gstring.stripIgnoreCase(classFinal, oldName, true, true)
        if classPostfix ~= classFinal then
            newName = oldName .. classPostfix
        end
    end
    newName = stripPre(newName, parsePatterns.modPrefixes.classAsName)
    if number then
        newName = newName .. "_" .. number
    end
    newName = finalClean(newName)
    return newName
end
local function fixNameFromClass(oldName, item)
    return fixNameFromClassCore(oldName, item, true)
end
local function fixNameFromClassPassTwo(oldName, item)
    return fixNameFromClassCore(oldName, item, false)
end

local function fixNameFromIndex(oldName, _, index)
    return oldName .. "_" .. index
end

local function fixCollisions(mTable,  field, renameFunc)
    -- make a copy of the itemTable to avoid modifying the same table that I am looping through.
    -- Check for same name, different fields
    --local refNames = gutil.cloneTable(mTable)
    local collisions = {}
    for name, items in pairs(mTable) do
        if #items > 1 then -- Only consider cases with multiple items
            local base = items[1][field]
            if field == "id" then
                table.sort(items, function(a, b)
                    return tonumber(a.id) < tonumber(b.id)
                end)
                collisions[name] = items
            else
                -- Check for differences in the specified field.
                -- (this is done rather than modifying the items as I find them to
                -- make it easier to remove the name from mTable,
                -- especially in instances where renameFunc resolves to the original name.)
                for _, item in ipairs(items) do
                    if item[field] ~= base then
                        collisions[name] = items
                        break
                    end
                end
            end
        end
    end
    -- If multiple differences are present, adjust names
    for name, items in pairs(collisions) do
        mTable[name] = nil
        for index, item in ipairs(items) do
            local newName = renameFunc(name, item, index)
            printIfRename(name, newName, field, item[field])
            -- Ensure the new name exists under the mod
            if not mTable[newName] then
                mTable[newName] = {}
            end

            -- Move the item to the new name
            table.insert(mTable[newName], item)
        end
    end
end




local function tryGetHardcodedName(name, class, id)
    class = gstring.extractLastSegDot(class)
    local newName = nil
    local function getName(hardTable, field)
        if hardTable[curMod] and hardTable[curMod][field] then
            newName = hardTable[curMod][field]
        end
    end
    getName(parsePatterns.hardcoded.byClass, class)
    getName(parsePatterns.hardcoded.byID, id)
    getName(parsePatterns.hardcoded.byName, name)
    return newName
end


local function parseName(name, class, id)
    local hardName = tryGetHardcodedName(name, class, id)
    local simpleName = stripNamespacesName(name)
    local newName
    if hardName then
        newName = standardizeName(hardName)
    elseif simpleName == "null" then
        local item = { class = class }
        newName = fixNameFromClassCore(simpleName, item, false)
    else
        newName = cleanName(simpleName)
        newName = finalClean(newName)
    end
    printIfRename(simpleName, newName)
    return newName
end

local function testCollisions(mTable)
    --probably should add to table and concat at end, but eh.
    local collisions = ""

    -- Iterate through all mods
    for name, entries in pairs(mTable) do
        -- Check if there is more than one entry under this name
        if #entries > 1 then
            -- Write the mod and name to the file
            collisions = collisions .. (string.format("Mod: %s, Name: %s\n", curMod, name))
            -- Write each entry's details
            for i, item in ipairs(entries) do
                collisions = collisions .. (string.format("  Entry %d:\n", i))
                collisions = collisions .. (string.format("    ID: %s\n", item.id or "N/A"))
                collisions = collisions .. (string.format("    Type: %s\n", item.type or "N/A"))
                collisions = collisions .. (string.format("    Class: %s\n", item.class or "N/A"))
            end
            collisions = collisions .. "\n" -- Add an extra line for readability
        end
    end
    return collisions
end



local function constructModTable()
    local mTable = {}
    local path = fs.concat(ModCSVDir, curMod .. ".csv")
    local csv = gutil.open(path, "r")
    for line in csv:lines() do
        line = line:gsub("[\13\n\r]", "")
        local id, type, _, unlocalised, class = line:match("(.*),(.*),(.*),(.*),(.*)")
        local parsedClass = cleanClass(class)
        local parsedName = parseName(unlocalised, parsedClass, id)

        if not mTable[parsedName] then
            mTable[parsedName] = {}
        end

        -- Add the ID entry under the mod key
        table.insert(mTable[parsedName], {
            ["id"] = id,
            ["type"] = type,
            ["class"] = parsedClass,
            ["unlocalised"] = unlocalised
        })
    end
    csv:close()
    fs.remove(path)
    return mTable
end

local function saveMod(mTable, outputPath)
    gutil.happyPrint("saving " .. curMod)
    local file = gutil.open(outputPath, "a")
    file:write(string.format('    %s={\n', curMod))
    local nameKeys = {}
    for name in pairs(mTable) do
        table.insert(nameKeys, name)
    end
    table.sort(nameKeys, function(a, b)
        return tonumber(mTable[a].id) < tonumber(mTable[b].id)
    end)
    for _, name in ipairs(nameKeys) do
        local data = mTable[name]
        file:write(string.format(
            '        %s={id="%s", type="%s", unlocalised="%s", class="%s"},\n',
            name, data.id, data.type, data.unlocalised, data.class
        ))
    end
    file:write("    },\n")
    file:close()
end

local Fucked = false
--lazy way to clear file contents
local colfile = gutil.open(collisionFilePath, "w")
colfile:close()
--------------  MAIN  --------------

splitByModBuffered(SrcCsvPath, ModCSVDir, ModCSVBufferSize)
if not fs.isDirectory( TempOutputDir) then
    fs.makeDirectory( TempOutputDir)
end
local tempOutputPath = fs.concat(TempOutputDir, "/itemTable.lua")
local file = gutil.open(tempOutputPath, "w")

file:write("local itemTable={\n")
file:close()
local modNames = gutil.sortKeys(modList)

-- Iterate alphabetically
for _, mod in ipairs(modNames) do
    curMod = mod
    gutil.uneasyPrint("Processing " .. mod)
    local modTable = constructModTable()
    fixCollisions(modTable, "type", fixNameFromType)
    fixCollisions(modTable, "class", fixNameFromClass)
    fixCollisions(modTable, "class", fixNameFromClassPassTwo)
    fixCollisions(modTable, "type", fixNameFromType)
    fixCollisions(modTable, "id", fixNameFromIndex)

    local collisionStr = testCollisions(modTable)
    if collisionStr ~= "" then
        if VERBOSE then
            gutil.angryPrint("Not all collisions fixed for " .. curMod)
        end
        colfile = gutil.open(collisionFilePath, "a")
        colfile:write(collisionStr)
        colfile:close()
        Fucked = true
    end
    if not Fucked then
        for name, items in pairs(modTable) do
            -- Replace the list with a flat structure
            modTable[name] = items[1]
        end


        --normalizeNames(modTable)
        saveMod(modTable, tempOutputPath)
        os.sleep(.001)
    end
end

if not Fucked then
    file = gutil.open(tempOutputPath, "a")
    file:write("}\n\nreturn itemTable")
    file:close()
    fs.remove(FinalItemTablePath)
    fs.rename(tempOutputPath, FinalItemTablePath)
    print("Item Table generated to \"" .. FinalItemTablePath .. "\"")
else
    gutil.angryPrint("Item Table generation failed due to unresolved collisions, see " .. collisionFilePath)
end

fs.remove(TempOutputDir)

