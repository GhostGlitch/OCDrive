
local fs = require("filesystem")
local gutil = require("ghostUtils")
local serial = require("serialization")

local file = gutil.readFile("/item.csv"):gsub("\13", "")
local parsedCSV = gutil.parseCSV(file)
if not parsedCSV then
    gutil.angryPrint("Error parsing items.csv")
    return
end



local function stripMod(str, mod, modmap)
    local lowerMod = mod:lower()
    local modmask = modmap[lowerMod] or lowerMod
    local stripStr = (modmask .. "[:%.]")
    str = gutil.stripIgnoreCase(str, stripStr, true, true)
    return str
end
-- Function to clean a string by removing all matching patterns
local function cleanName(name, mod)
    local namePatterns = {
        "^tile%.",    -- Remove "tile." at the start
        "^block%.",   -- Remove "block." at the start
        "^item%.",  -- Remove "item." at the start
        " %- this item is just used to mime fluids!"
    }    
    for _, pattern in ipairs(namePatterns) do
        name = name:gsub(pattern, "") -- Apply each pattern
    end
    local modMappings = {
        ["hungeroverhaul"] = "pamharvestcraft",
        ["opencomputers"] = "oc",
        ["forgemicroblock"] = "microblock",
        ["extrautilities"] = "extrautils",
        ["iguanatweakstconstruct"] = "tconstruct",
        ["minefactoryreloaded"] = "mfr",
        ["exnihilo"] = "crowley.skyblock"
    }
    name = stripMod(name, mod, modMappings)
    name = name:gsub("%.", "_")
    return name
end

local function cleanClass(class, mod)
    local modMappings = {
        ["awwayoftime"] = "alchemicalwizardry",
    }
    class = stripMod(class, mod, modMappings)
    return class
end

local function renameFromType(oldName, item)
    return oldName .. "_" .. item.type
end

local function renameFromClass(oldName, item)
    local class = item.class
    local id = item.id
    local tmp = gutil.extractLastSegDot(class)
    local idk = gutil.stripIgnoreCase(tmp, oldName, true, true)
    if idk ~= tmp then
        tmp = oldName .. idk
        --print(class, tmp, id)
        os.sleep(.1)
        return tmp
    end
    tmp = gutil.stripIgnoreCase(tmp, "block", true)
    tmp = gutil.stripIgnoreCase(tmp, "item", true)

    --print(class, tmp)
    --os.sleep(.1)
    return tmp
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
                        local newName = renameFunc(name, item)
                
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
    fixCollisions(iTable, "type", renameFromType)
end

local function fixColClass(iTable)
    fixCollisions(iTable, "class", renameFromClass)
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

        if parsedName == "null" then
            parsedName = gutil.extractLastSegDot(parsedClass)
        end


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
serfile = serial.serialize(itemTable)
serfile = serfile:gsub("}}},", "}}},\n")
serfile = serfile:gsub("}},", "}},\n")
local output = "itemTable = " .. serfile .. "\n" .. "return itemTable"
gutil.strToFile("/itemTable.lua", output)

print("Item Table generated to \"/itemTable.lua\"")