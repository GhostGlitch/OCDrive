
local fs = require("filesystem")
local gutil = require("ghostUtils")
local gstring = require("ghostString")
local term = require("term")
local serial = require("serialization")

local SrcCsvPath = "/item.csv"
local TempOutputDir = "/temp/ghost"
local ModCSVDir = fs.concat(TempOutputDir, "modcsv/")
local FinalItemTablePath = "/itemTable.lua"
local ModCSVBufferSize = 128
local gpu = require("component").gpu

local currentMod = nil
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
            exnihilo               = {"crowley%.skyblock"},
            ExtraUtilities         = {"extrautils"},
            Forestry               = {"for"},
            ForgeMicroblock        = {"microblock"},
            HungerOverhaul         = {"pamharvestcraft"},
            IguanaTweaksTConstruct = {"tconstruct"},
            MineFactoryReloaded    = {"mfr"},
            OpenComputers          = {"oc"},
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
renameWidth = math.min((renameWidth - 12) // 3, 30)
local renameHeader = " | " ..
    gstring.toLength("Original Name", renameWidth, "center") .. " | " ..
    gstring.toLength("New Name", renameWidth, "center") .. " | " ..
    gstring.toLength("Reference", renameWidth, "center") .. " |"

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

    if currentRenameMod ~= currentMod then
        print("Renaming")
        print(renameHeader)
        currentRenameMod = currentMod
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
    if name ~= newName then
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

            -- Write to file if buffer exceeds bufferSize
            if #buffers[mod] >= bufferSize then
                gutil.uneasyPrint("BUFFER FULL. DUMPING DATA")
                saveBuffer(buffers[mod], outputDir, mod)
                buffers[mod] = {} -- Clear the buffer
            end
        end
        lineCount = lineCount + 1
    end
    gutil.uneasyPrint("READ DONE. DUMPING REMAINING")

    -- Write remaining data in buffers
    for mod, buffer in pairs(buffers) do
        if #buffer > 0 then
            saveBuffer(buffer, outputDir, mod)
        end
    end
    csv:close()
    print("Processed " .. lineCount .. " lines and split into mod-specific files.")
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
    if modPatterns[currentMod] then
        str = stripEachNamespace(str, modPatterns[currentMod], true)
    else
        str = stripNamespace(str, currentMod, true)
    end
    return str
end
local function stripPre(str, prefixTable)
    if prefixTable[currentMod] then
        for _, pattern in ipairs(prefixTable[currentMod]) do
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
        and lowername ~= "multiitem" and lowername ~= "cheatitem" then
        newName = gstring.stripIgnoreCase(newName, "Item$")
    end

    if parsePatterns.modSubs.name[currentMod] then
        for from, to in pairs(parsePatterns.modSubs.name[currentMod]) do
            newName = newName:gsub(from, to)
        end
    end

    newName = newName:gsub("[_%./](.)", function(match) return match:upper() end)
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
    local refNames = gutil.cloneTable(mTable)
    for name, items in pairs(refNames) do
        if #items > 1 then -- Only consider cases with multiple items
            local base = items[1][field]
            local hasDifference = false

            if field == "id" then
                table.sort(items, function(a, b)
                    return tonumber(a.id) < tonumber(b.id)
                end)
                hasDifference = true
            else
                -- Check for differences in the specified field.
                -- (this is done rather than modifying the items as I find them to
                -- make it easier to remove the name from mTable,
                -- especially in instances where renameFunc resolves to the original name.)
                for _, item in ipairs(items) do
                    if item[field] ~= base then
                        hasDifference = true
                        break
                    end
                end
            end
            -- If multiple differences are present, adjust names
            if hasDifference then
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
    end
end



local function tryGetHardcodedName(name, class, id)
    class = gstring.extractLastSegDot(class)
    local newName = nil
    local function getName(hardTable, field)
        if hardTable[currentMod] and hardTable[currentMod][field] then
            newName = hardTable[currentMod][field]
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
    local collisions = ""

    -- Iterate through all mods
    for name, entries in pairs(mTable) do
        -- Check if there is more than one entry under this name
        if #entries > 1 then
            -- Write the mod and name to the file
            collisions = collisions .. (string.format("Mod: %s, Name: %s\n", currentMod, name))
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
    local path = fs.concat(ModCSVDir, currentMod .. ".csv")
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
            ["class"] = parsedClass
        })
    end
    csv:close()
    fs.remove(path)
    return mTable
end

local function saveMod(mTable, outputPath)
    gutil.happyPrint("saving " .. currentMod)
    local file = gutil.open(outputPath, "a")
    file:write(string.format('    %s={\n', currentMod))
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
            '        %s={id="%s", type="%s", class="%s"},\n',
            name, data.id, data.type, data.class
        ))
    end
    file:write("    },\n")
    file:close()
end


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
    currentMod = mod
    gutil.uneasyPrint("Processing " .. mod)
    local modTable = constructModTable()
    fixCollisions(modTable, "type", fixNameFromType)
    fixCollisions(modTable, "class", fixNameFromClass)
    fixCollisions(modTable, "class", fixNameFromClassPassTwo)
    fixCollisions(modTable, "type", fixNameFromType)
    fixCollisions(modTable, "id", fixNameFromIndex)

    local collisionStr = testCollisions(modTable)
    if collisionStr ~= "" then
        -- needs improvement
        gutil.angryPrint("Not all collisions fixed!, see " .. collisionFilePath)
        gutil.strToFile(collisionFilePath, collisionStr)
    end
    for name, items in pairs(modTable) do
        -- Replace the list with a flat structure
        modTable[name] = items[1]
    end


    --normalizeNames(modTable)
    saveMod(modTable, tempOutputPath)
    os.sleep(.001)
end


file = gutil.open(tempOutputPath, "a")

file:write("}\n\nreturn itemTable")
file:close()

fs.remove(FinalItemTablePath)
fs.rename(tempOutputPath, FinalItemTablePath)
fs.remove(TempOutputDir)

print("Item Table generated to \"" .. FinalItemTablePath .. "\"")