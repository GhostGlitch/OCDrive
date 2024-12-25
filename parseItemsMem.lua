
local fs = require("filesystem")
local gutil = require("ghostUtils")
local gstring = require("ghostString")
local serial = require("serialization")


local collisionFilePath = "/itemTableCollisions.txt"
local function splitFile(path)
    local file = fs.open(path, "r")
    local lines = {}
end

local specialFixes = {
    generalPat = {
        name = {
            "^tile[s]?%.",    -- Remove "tile." at the start
            "^block[s]?%.",   -- Remove "block." at the start
            "^item[s]?%.",      -- Remove "item." at the start
            " %- this item is just used to mime fluids!"
        }
    },
    modAliases = {
        --for mods which use a different name for their identifier, and in item names. MUST be lowercase.
        name = {
            hungeroverhaul = "pamharvestcraft",
            opencomputers = "oc",
            forgemicroblock = "microblock",
            extrautilities = "extrautils",
            iguanatweakstconstruct = "tconstruct",
            minefactoryreloaded = "mfr",
            exnihilo = "crowley%.skyblock",
            appliedenergistics = "appeng",
        },
        --for mods which use a different name for their identifier, and in class paths. MUST be lowercase.
        class = {
            awwayoftime = "alchemicalwizardry",
            appliedenergistics = "appeng",
            jabba = "betterbarrels",
            opencomputers = "oc",
            openperipheral = "openperipheral.addons",
            extrautilities = "extrautils",
            forgemicroblock = "microblock"
        },
        --for mods which use two different names in class paths. MUST be lowercase.
        classPassTwo = {
            gendustry = "bdew",
        },
    },
    hardcoded = {
        byName = {
            Minecraft = {
                mycel = "mycelium",
                lightgem = "glowstone",
                musicBlock = "noteBlock",
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
                ["9"] = "waterStationary",
                ["10"] = "lavaFlowing",
                ["11"] = "lavaStationary",
                ["39"] = "mushroomBrown",
                ["40"] = "mushroomRed",
                ["43"] = "stoneSlabDouble",
                ["61"] = "furnaceOff",
                ["62"] = "furnaceOn",
                ["63"] = "signStanding",
                ["68"] = "signWall",
                ["70"] = "pressurePlateStone",
                ["72"] = "pressurePlanteWood",
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


local function stripMod(str, mod, modAliases)
    local modmask
    local lowerMod = mod:lower()
    if modAliases then
        modmask = modAliases[lowerMod] or lowerMod
    else
        modmask = lowerMod
    end
    local stripStr = (modmask .. "[:%.]")
    str = gstring.stripIgnoreCase(str, stripStr, true, true)
    return str
end
-- Function to clean a string by removing all matching patterns
local function cleanName(name, mod)
    local modprefixes = {
        HardcoreQuesting = "hqm",
        ComputerCraft = "cc",
        BigReactors = "br"
    }
    for _, pattern in ipairs(specialFixes.generalPat.name) do
        name = gstring.stripIgnoreCase(name, pattern) -- Apply each pattern
    end

    name = stripMod(name, mod, specialFixes.modAliases.name)
    for _, pattern in ipairs(specialFixes.generalPat.name) do
        name = gstring.stripIgnoreCase(name, pattern) -- Apply each pattern
    end
    if modprefixes[mod] then
        name = gstring.stripIgnoreCase(name, modprefixes[mod], true)
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
    class = class:gsub("iguanaman.", "")
    return class
end



local function fixNameFromType(oldName, item, mod)
    return oldName .. "_" .. item.type
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
    newName = gstring.stripIgnoreCase(newName, "[Bb]lock", true)
    if newName ~= "item" and newName ~= "items" then
    newName = gstring.stripIgnoreCase(newName, "[Ii]tem", true)
    end
    local modprefixes = {
        AppliedEnergistics = "AppEng",
        pamharvestcraft = "Pam",
        ExtraTrees = "ET",
        BigReactors = "BR"
    }
    if modprefixes[mod] then
        newName = gstring.stripIgnoreCase(newName, modprefixes[mod], true)
    end
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

local function fixNameFromIndex(oldName, item, mod, index)
    return oldName .. "_" .. index
end



local function fixCollisions(iTable, field, renameFunc)
    --local refTable = gutil.cloneTable(iTable) -- make a copy of the itemTable to avoid modifying the same table that I am looping through.
    -- Check for same name, different fields
    for mod, names in pairs(iTable) do
        local refNames = gutil.cloneTable(names)
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
                    -- Check for differences in the specified field. (this is done rather than modifying the items as I find them to make it easier to remove the name from iTable, especially in instances where renameFunc resolves to the original name.
                    for _, item in ipairs(items) do
                        if item[field] ~= base then
                            hasDifference = true
                            break
                        end
                    end
                end
                -- If multiple differences are present, adjust names
                if hasDifference then
                    iTable[mod][name] = nil
                    for index, item in ipairs(items) do
                        local newName = renameFunc(name, item, mod, index)
                        print(string.format("Renaming item with %s '%s' from '%s' to '%s.%s'", field, item[field], name, mod, newName))
                        -- Ensure the new name exists under the mod
                        if not iTable[mod][newName] then
                            iTable[mod][newName] = {}
                        end

                        -- Move the item to the new name
                        table.insert(iTable[mod][newName], item)
                    end
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

local function testCollisions(iTable)
    local collisions = ""

    -- Iterate through all mods
    for mod, names in pairs(iTable) do
        -- Iterate through all names for the current mod
        for name, entries in pairs(names) do
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
    end
    return collisions
end

local itemTable = {}
local function constructTable(iTable)
    local csv = io.open("/item.csv", "r")
    if not csv then
        error("Could not open item.csv for reading")
    end
    while true do
        local line = csv:read("*l")
        if not line then
            break
        end
        line = line:gsub("\13", ""):gsub("\n", ""):gsub("\r", "")
        local id, type, mod, unlocalised, class = line:match("(.*),(.*),(.*),(.*),(.*)")
            mod = mod:gsub("%s", "")


            if unlocalised ~= "tile.ForgeFiller" and id ~= "ID" then
                if mod == "crowley.skyblock" then
                    mod = "exnihilo"
                end
                local parsedName = cleanName(unlocalised, mod)
                local parsedClass = cleanClass(class, mod)
                parsedName = hardcodedRenameEarly(parsedName, parsedClass, mod, id)

                -- Ensure the mod key exists in the nestedTable
                if not iTable[mod] then
                    iTable[mod] = {}
                end
                if not iTable[mod][parsedName] then
                    iTable[mod][parsedName] = {}
                end

                -- Add the ID entry under the mod key
                table.insert(iTable[mod][parsedName], {
                    ["id"] = id,
                    ["type"] = type,
                    ["class"] = parsedClass
                })
            end

        end
    csv:close()
end
local function test(iTable, field, renameFunc)
    --local refTable = gutil.cloneTable(iTable) -- make a copy of the itemTable to avoid modifying the same table that I am looping through.
    -- Check for same name, different fields
    for mod, names in pairs(iTable) do
        local refNames = gutil.cloneTable(names)
        for name, items in pairs(refNames) do
            -- If multiple differences are present, adjust names
            iTable[mod][name] = nil
            for index, item in ipairs(items) do
                local tmp = gstring.stripIgnoreCase(name, "block", true)
                if tmp ~= "" then 
                    newName = tmp
                end

                tmp = gstring.stripIgnoreCase(newName, "item", true)
                if tmp ~= "" and tmp ~= "s" then 
                    newName = tmp
                end

                tmp = gstring.stripIgnoreCase(newName, "tool[s]?_", true)
                if tmp ~= "" then 
                    newName = tmp
                end
                if mod == "TConstruct" then
                    newName = newName:gsub("metal_molten", "molten")
                end

                if not iTable[mod][newName] then
                    iTable[mod][newName] = {}
                end

                -- Move the item to the new name
                table.insert(iTable[mod][newName], item)
            end
        end
    end
end
local function serializeChunked(iTable, filePath)
    print("saving")
    local file = io.open(filePath, "w")
    file:write("local itemTable={\n")

    for mod, names in pairs(iTable) do
        file:write(string.format('    %s={\n', mod))
        for name, data in pairs(names) do
            file:write(string.format(
                '        %s={id="%s", type="%s", class="%s"},\n',
                name, data.id, data.type, data.class
            ))
        end
        file:write("    },\n")
    end

    file:write("}\n\nreturn itemTable")
    file:close()
end
constructTable(itemTable)
fixCollisions(itemTable, "type", fixNameFromType)
fixCollisions(itemTable, "class", fixNameFromClass)
--fixCollisions(itemTable, "class", fixNameFromClassPassTwo)

test(itemTable)
fixCollisions(itemTable, "type", fixNameFromType)
fixCollisions(itemTable, "id", fixNameFromIndex)
local serfile
local tablePath
local collisionStr = testCollisions(itemTable)
if collisionStr ~= "" then
    gutil.angryPrint("Not all collisions fixed!, see " .. collisionFilePath)
    gutil.strToFile(collisionFilePath, collisionStr)
    serfile = serial.serialize(itemTable)
    serfile = serfile:gsub("}}},", "}}},\n"):gsub("}},", "}},\n")
    tablePath = "/itemTableBAD.lua"
else
    fs.remove(collisionFilePath)
    for mod, names in pairs(itemTable) do
        for name, items in pairs(names) do
            -- Extract the single item
            local item = items[1]
            -- Replace the list with a flat structure
            itemTable[mod][name] = {
                id = items[1].id,
                type = items[1].type,
                class = items[1].class
            }
        end
    end

    tablePath = "/itemTable.lua"
    serializeChunked(itemTable, tablePath)
end



print("Item Table generated to \"" .. tablePath .. "\"")