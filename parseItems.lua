
local fs = require("filesystem")
local gutil = require("ghostUtils")
local gstring = require("ghostString")
local serial = require("serialization")

local file = gutil.readFile("/item.csv"):gsub("\13", "")
local parsedCSV = gutil.parseCSV(file)
if not parsedCSV then
    gutil.angryPrint("Error parsing items.csv")
    return
end

local specialFixes = {
    modMappings = {
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

local function stripMod(str, mod, modmap)
    local modmask
    local lowerMod = mod:lower()
    if modmap then
        modmask = modmap[lowerMod] or lowerMod
    else
        modmask = mod
    end
    local stripStr = (modmask .. "[:%.]")
    str = gstring.stripIgnoreCase(str, stripStr, true, true)
    return str
end
-- Function to clean a string by removing all matching patterns
local function cleanName(name, mod)

    local namePatterns = {
        "^tile[s]?%.",    -- Remove "tile." at the start
        "^block[s]?%.",   -- Remove "block." at the start
        "^item[s]?%.",      -- Remove "item." at the start
        " %- this item is just used to mime fluids!"
    }    
    for _, pattern in ipairs(namePatterns) do
        name = gstring.stripIgnoreCase(name, pattern) -- Apply each pattern
    end

    local modprefixes = {
        HardcoreQuesting = "hqm",
        ComputerCraft = "cc",
    }
    name = stripMod(name, mod, specialFixes.modMappings.name)
    for _, pattern in ipairs(namePatterns) do
        name = gstring.stripIgnoreCase(name, pattern) -- Apply each pattern
    end
    if modprefixes[mod] then
        name = gstring.stripIgnoreCase(name, modprefixes[mod], true)
    end
    name = name:gsub("%.", "_")
    return name
end

local function cleanClass(class, mod)


    class = stripMod(class, mod, specialFixes.modMappings.class)
    if specialFixes.modMappings.classPassTwo[mod] then
        class = stripMod(class, specialFixes.modMappings.classPassTwo[mod])
    end
    class = class:gsub("iguanaman.", "")
    return class
end

local function fixNameFromType(oldName, item, mod)
    return oldName .. "_" .. item.type
end

local function fixNameFromClassCore(oldName, item, mod, tryPostfix)
    local class = item.class
    local newName
    local classFinal = gstring.extractLastSegDot(class)
    local prefix, number = oldName:match("(%a+)[_%.]?(%d+)")
    oldName = prefix or oldName
    if tryPostfix then
        local classPostfix = gstring.stripIgnoreCase(classFinal, oldName, true, true)
        if classPostfix ~= classFinal then
            newName = oldName .. classPostfix
            if number then
                newName = newName .. "_" .. number
            end
            goto fixClassEnd
        end
    end
    newName = gstring.stripIgnoreCase(classFinal, "[Bb]lock", true)
    newName = gstring.stripIgnoreCase(newName, "[Ii]tem", true)
    ::fixClassEnd::
    local modprefixes = {
        ["AppliedEnergistics"] = "AppEng",
        ["pamharvestcraft"] = "Pam",
        ["ExtraTrees"] = "ET"
    }
    if modprefixes[mod] then
        newName = gstring.stripIgnoreCase(newName, modprefixes[mod], true, true)
    end
    --print(class, newName)
    --os.sleep(.1)
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
local function hardcodedRenameEarly(name, class, mod, id)
    class = gstring.extractLastSegDot(class)
    local hardClass = specialFixes.hardcoded.byClass[mod]
    local hardNames = specialFixes.hardcoded.byName
    local hardIDs = specialFixes.hardcoded.byID
    if hardClass and hardClass[class] then
        name = hardClass[class]
    end

    if name == "null" then
        local item = {class = class}
        name = fixNameFromClassCore(name, item, mod, false)
    end

    if mod == "Minecraft" and (name == "water" or name == "lava") then
        if class == "block.BlockFlowing" then
            name = name .. "Flowing"
        end
        if class == "block.BlockStationary" then
            name = name .. "Stationary"
        end
    end
    if hardNames[mod] and hardNames[mod][name] then
        name = hardNames[mod][name]
    end

    if hardIDs[mod] and hardIDs[mod][id] then
        name = hardIDs[mod][id]
    end
    return name
end

local function fixCollisions(iTable, field, renameFunc)
    local refTable = gutil.cloneTable(iTable) -- make a copy of the itemTable to avoid modifying the same table that I am looping through.
    -- Check for same name, different fields
    for mod, names in pairs(refTable) do
        for name, items in pairs(names) do
            if name ~= "null" and #items > 1 then -- Only consider cases with multiple items
                local base = items[1][field]
                local hasDifference = false

                -- Check for differences in the specified field. (this is done rather than modifying the items as I find them to make it easier to remove the name from iTable, especially in instances where renameFunc resolves to the original name.
                for _, item in ipairs(items) do
                    if item[field] ~= base then
                        hasDifference = true
                        break
                    end
                end

                -- If multiple differences are present, adjust names
                if hasDifference then
                    iTable[mod][name] = nil
                    for _, item in ipairs(items) do
                        local newName = renameFunc(name, item, mod)
                
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
local function fixColType(iTable)
    fixCollisions(iTable, "type", fixNameFromType)
end

local function fixColClass(iTable)
    fixCollisions(iTable, "class", fixNameFromClass)
    fixCollisions(iTable, "class", fixNameFromClassPassTwo)
end

local itemTable = {}

for i, row in ipairs(parsedCSV) do
    local id = row[1]
    local type = row[2]
    local mod = row[3]:gsub(" ", "")
    local unlocalised = row[4]
    local class = row[5]

    if unlocalised ~= "tile.ForgeFiller" and id ~= "ID" then
        if mod == "crowley.skyblock" then
            mod = "exnihilo"
        end
        local parsedName = cleanName(unlocalised, mod)
        local parsedClass = cleanClass(class, mod)
        parsedName = hardcodedRenameEarly(parsedName, parsedClass, mod, id)

        -- Ensure the mod key exists in the nestedTable
        if not itemTable[mod] then
            itemTable[mod] = {}
        end
        if not itemTable[mod][parsedName] then
            itemTable[mod][parsedName] = {}
        end

        -- Add the ID entry under the mod key
        table.insert(itemTable[mod][parsedName], {
            ["id"] = id,
            ["type"] = type,
            ["class"] = parsedClass
        })
    end
    if i % 1024 == 0 then
        os.sleep(.001)
    end
end

fixColType(itemTable)
fixColClass(itemTable)
fixColType(itemTable)
local serfile = serial.serialize(itemTable)
serfile = serfile:gsub("}}},", "}}},\n"):gsub("}},", "}},\n")
local output = "local itemTable = " .. "\n\n" .. serfile .. "\n\n" .. "return itemTable"
gutil.strToFile("/itemTable.lua", output)

print("Item Table generated to \"/itemTable.lua\"")