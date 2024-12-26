
local fs = require("filesystem")
local gutil = require("ghostUtils")
local gstring = require("ghostString")

local SrcCsvPath = "/item.csv"
local ModCSVPath = "/temp/ghost/modcsv/"
local tempOutputDir = "/temp/ghost"
local itemTablePath = "/itemTable.lua"
local ModCSVBufferSize = 128

local modList = {}
local collisionFilePath = "/itemTableCollisions.txt"

local specialFixes = {
    generalPat = {
        name = {
            "^tile[s]?%.",    -- Remove "tile." at the start
            "^block[s]?%.",   -- Remove "block." at the start
            "^item[s]?%.",  -- Remove "item." at the start
            "^tool[s]?%.",
            "^armo[u]?r%.",
        },
        class = {
           "iguanaman.",
            "^core%.",
            "^common%.",
            "^shared%.",
            "^base%.",
            "item[s]%.",
            "block[s]%.",
        }
    },
    modAliases = {
        general = {
            ["crowley.skyblock"] = "exnihilo",
            AWWayofTime = "BloodMagic"
        },
        --for mods which use a different name for their identifier, and in item names.
        name = {
            AppliedEnergistics     = "appeng",
            exnihilo               = "crowley%.skyblock",
            ExtraUtilities         = "extrautils",
            Forestry               = "for",
            ForgeMicroblock        = "microblock",
            HungerOverhaul         = "pamharvestcraft",
            IguanaTweaksTConstruct = "tconstruct",
            MineFactoryReloaded    = "mfr",
            OpenComputers          = "oc",
        },
        --for mods which use a different name for their identifier, and in class paths.
        class = {
            AppliedEnergistics     = "appeng",
            BloodMagic             = "alchemicalwizardry",
            ExtraUtilities         = "extrautils",
            ForgeMicroblock        = "microblock",
            JABBA                  = "betterbarrels",
            OpenComputers          = "oc",
            OpenPeripheral         = "openperipheral%.addons"
        },
        --for mods which use two different names in class paths.
        classPassTwo = {
            gendustry = "bdew",
            ThermalExpansion = "cofh"
        },
    },
    modPrefixes = {
        name = {
            first = {
                HardcoreQuesting = "hqm",
                ComputerCraft = "cc",
                BigReactors = "br",
                BiblioCraft = "Biblio"
            },
            second = {
                BigReactors = "blockBR"
            },
        },
        classAsName = {
            first = {
                AppliedEnergistics = "AppEng",
                pamharvestcraft = "BlockPam",
                ExtraTrees = "BlockET",
                BigReactors = "BR"
            },
            second = {
                pamharvestcraft = "ItemPam",
                ExtraTrees = "ItemET",
            }
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
                mycel = "mycelium",
                lightgem = "glowstone",
                musicBlock = "noteBlock",
            },
            BiblioCraft = {
                theca = "Bookcase",
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


local function modFromLine(line)
    local id, type, mod, unlocalised, class = line:match("(.*),(.*),(.*),(.*),(.*)")
    mod = mod:gsub("%s", "")

    mod = specialFixes.modAliases.general[mod] or mod
    if unlocalised == "tile.ForgeFiller" or id == "ID" then return nil end
    return mod
end
local function saveBuffer(buffer, outputDir, mod)
    print(mod)
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


local function stripMod(str, mod, modAliases)
    local modmask
    if modAliases then
        modmask = modAliases[mod] or mod
    else
        modmask = mod
    end
    modmask = modmask:lower()
    local stripStr = (modmask .. "[:%.]")
    return gstring.stripIgnoreCase(str, stripStr, true, true)
end
local function stripPre(str, mod, prefixTable)
    if prefixTable.first[mod] then
        str = gstring.stripIgnoreCase(str, prefixTable.first[mod], true)
    end
    if prefixTable.second[mod] then
        str = gstring.stripIgnoreCase(str, prefixTable.second[mod], true)
    end
    return str
end

-- Function to clean a string by removing all matching patterns
local function cleanName(name, mod)
    for _, pattern in ipairs(specialFixes.generalPat.name) do
        name = gstring.stripIgnoreCase(name, pattern) -- Apply each pattern
    end

    name = stripMod(name, mod, specialFixes.modAliases.name)
    for _, pattern in ipairs(specialFixes.generalPat.name) do
        name = gstring.stripIgnoreCase(name, pattern) -- Apply each pattern
    end
    name = stripPre(name, mod, specialFixes.modPrefixes.name)

    local lowername = name:lower()
    if lowername ~= "item" and lowername ~= "cheatyitem"
        and lowername ~= "multiitem" and lowername ~= "cheatitem" then
        name = gstring.stripIgnoreCase(name, "Item$")
    end

    if specialFixes.modSubs.name[mod] then
        for from, to in pairs(specialFixes.modSubs.name[mod]) do
            name = name:gsub(from, to)
        end
    end

    name = name:gsub("[%/%.]", "_")
    return name
end

local function cleanClass(class, mod)
    class = class:gsub("%s", "")
    class = stripMod(class, mod, specialFixes.modAliases.class)
    if specialFixes.modAliases.classPassTwo[mod] then
        class = stripMod(class, specialFixes.modAliases.classPassTwo[mod])
    end
    for _, pattern in ipairs(specialFixes.generalPat.class) do
        class = gstring.stripIgnoreCase(class, pattern) -- Apply each pattern
    end
    class = class:gsub("^item[s]?%.Item", "Item")
    class = class:gsub("^block[s]?%.Block", "Block")
    return class
end


local function fixNameFromType(oldName, item, _)
    if item.type == "Block" then
        return oldName .. "Block"
    end
    return oldName
end

local function fixNameFromClassCore(oldName, item, mod, tryPostfix)
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
    newName = stripPre(newName, mod, specialFixes.modPrefixes.classAsName)
    if number then
        newName = newName .. "_" .. number
    end
    return newName
end
local function fixNameFromClass(oldName, item, mod)
    return fixNameFromClassCore(oldName, item, mod, true)
end
local function fixNameFromClassPassTwo(oldName, item, mod)
    return fixNameFromClassCore(oldName, item, mod, false)
end

local function fixNameFromIndex(oldName, _, _, index)
    return oldName .. "_" .. index
end



local function fixCollisions(mTable, mod,  field, renameFunc)
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
                    local newName = renameFunc(name, item, mod, index)
                    print(string.format("Renaming item with %s '%s' from '%s' to '%s.%s'", field, item[field], name, mod, newName))
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

local function hardcodedRenameEarly(name, class, mod, id)
    class = gstring.extractLastSegDot(class)
    local hardClass = specialFixes.hardcoded.byClass[mod]
    local hardName = specialFixes.hardcoded.byName[mod]
    local hardID = specialFixes.hardcoded.byID[mod]
    if hardClass and hardClass[class] then
        name = hardClass[class]
    end
    if name == "null" then
        local item = { class = class }
        name = fixNameFromClassCore(name, item, mod, false)
    end
    if hardName and hardName[name] then
        name = hardName[name]
    end
    if hardID and hardID[id] then
        name = hardID[id]
    end
    return name
end

local function testCollisions(mTable, mod)
    local collisions = ""

    -- Iterate through all mods
    for name, entries in pairs(mTable) do
        -- Check if there is more than one entry under this name
        if #entries > 1 then
            -- Write the mod and name to the file
            collisions = collisions .. (string.format("Mod: %s, Name: %s\n", mod, name))
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

local function constructModTable(mod)
    local mTable = {}
    local path = fs.concat(ModCSVPath, mod .. ".csv")
    print(path)
    local csv = gutil.open(path, "r")
    for line in csv:lines() do
        line = line:gsub("[\13\n\r]", "")
        local id, type, _, unlocalised, class = line:match("(.*),(.*),(.*),(.*),(.*)")
        local parsedName = cleanName(unlocalised, mod)
        local parsedClass = cleanClass(class, mod)
        parsedName = hardcodedRenameEarly(parsedName, parsedClass, mod, id)

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
local function finalPass(mTable, mod)
    -- make a copy of the itemTable to avoid modifying the same table that I am looping through.
    -- Check for same name, different fields
    local refNames = gutil.cloneTable(mTable)
    for name, items in pairs(refNames) do
        -- If multiple differences are present, adjust names
        mTable[name] = nil
        local StorageBlocks = {
            "iron", "gold", "lapis",
            "diamond", "coal", "redstone",
            "emerald", "copper", "tin",
            "lead", "silver",
        }
        for _, item in ipairs(items) do

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

            if not mTable[newName] then
                mTable[newName] = {}
            end

            -- Move the item to the new name
            table.insert(mTable[newName], item)
        end
    end
end
local function normalizeNames(mTable)
    local refNames = gutil.cloneTable(mTable)
    for name in pairs(refNames) do
        local newName = name
        if name ~= name:upper() then
            newName = name:gsub("^%a", string.lower)
        end
        newName = gstring.snakeToCamel(newName)
        local prefix, number = newName:match("(%a+[^T_])(%d+)")
        if number and not prefix:match("Tier$") then
            newName = prefix .. "_" .. number
        end
        mTable[name] = nil
        mTable[newName] = refNames[name]
    end
end
local function saveMod(mTable, mod, outputPath)
    gutil.happyPrint("saving " .. mod)
    local file = gutil.open(outputPath, "a")
    file:write(string.format('    %s={\n', mod))
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

splitByModBuffered(SrcCsvPath, ModCSVPath, ModCSVBufferSize)
if not fs.isDirectory( tempOutputDir) then
    fs.makeDirectory( tempOutputDir)
end
local tempOutputPath = fs.concat(tempOutputDir, "/itemTable.lua")
local file = gutil.open(tempOutputPath, "w")

file:write("local itemTable={\n")
file:close()
local modNames = gutil.sortKeys(modList)

-- Iterate alphabetically
for _, mod in ipairs(modNames) do
    print(mod)
    local modTable = constructModTable(mod)
    fixCollisions(modTable, mod, "type", fixNameFromType)
    fixCollisions(modTable, mod, "class", fixNameFromClass)
    fixCollisions(modTable, mod, "class", fixNameFromClassPassTwo)

    finalPass(modTable, mod)
    fixCollisions(modTable, mod, "type", fixNameFromType)
    fixCollisions(modTable, mod, "class", fixNameFromClass)
    fixCollisions(modTable, mod, "class", fixNameFromClassPassTwo)
    fixCollisions(modTable, mod, "type", fixNameFromType)
    fixCollisions(modTable, mod, "id", fixNameFromIndex)

    local collisionStr = testCollisions(modTable, mod)
    if collisionStr ~= "" then
        -- needs improvement
        gutil.angryPrint("Not all collisions fixed!, see " .. collisionFilePath)
        gutil.strToFile(collisionFilePath, collisionStr)
    end
    for name, items in pairs(modTable) do
        -- Replace the list with a flat structure
        modTable[name] = items[1]
    end


    normalizeNames(modTable)
    saveMod(modTable, mod, tempOutputPath)
        os.sleep(.001)
end


file = gutil.open(tempOutputPath, "a")

file:write("}\n\nreturn itemTable")
file:close()

fs.remove(itemTablePath)
fs.rename(tempOutputPath, itemTablePath)
fs.remove(tempOutputDir)

print("Item Table generated to \"" .. itemTablePath .. "\"")