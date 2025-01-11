local fs = require("filesystem")
local io = require("io")
local serialization = require("serialization")

local itemFilePath = "/itemGTNHoriginal.csv"
local blockFilePath = "/blockGTNH.csv"
local outputFilePath = "/itemGTNH.csv"
local maxID = 0
-- Parse CSV into a table by ID
local function parseCSV(filePath)
    local data = {}
    if not fs.exists(filePath) then return data end

    local file = io.open(filePath, "r")
    for line in file:lines() do
        local columns = {}
        for value in string.gmatch(line, "([^,]+)") do
            table.insert(columns, value)
        end
        local id = tonumber(columns[2])

        if #columns >= 6 and columns[2] ~= "ID" then -- Skip header
            local entry = {
                Name = columns[1],
                ID = id,
                HasItem = columns[3],
                Mod = columns[4],
                Class = columns[5],
                DisplayName = columns[6]
            }
            data[id] = entry
            if id > maxID then maxID = id end
        end
    end
    file:close()
    return data
end

-- Extract mod from name if mod is not provided
local function extractModFromName(name)
    return string.match(name, "^(.-):") or "unknown"
end

-- Merge item and block data
local function mergeData(itemData, blockData)
    local outputData = {}
    for id=0, maxID do
        if itemData[id] and blockData[id] then
            -- Item exists in both files, take Class from block, others from item
            local itemEntry = itemData[id]
            local blockEntry = blockData[id]
            table.insert(outputData, {
                ID = id,
                ["Block/Item"] = "Both",
                Mod = itemEntry.Mod,
                ["Unlocalised name"] = (itemEntry.DisplayName == "Unnamed Block, report to mod author.") and "null" or itemEntry.Name,
                Class = blockEntry.Class
            })

        elseif blockData[id] then
            -- Exists only in block file
            local blockEntry = blockData[id]
            local mod = blockEntry.Name:match( "^(.-):")
            if mod ~= "minecraft" then mod = "unknown" end

            table.insert(outputData, {
                ID = id,
                ["Block/Item"] = "Block",
                Mod = mod,
                ["Unlocalised name"] = (blockEntry.DisplayName == "Unnamed Block, report to mod author.") and "null" or blockEntry.Name,
                Class = blockEntry.Class
            })
        elseif itemData[id] then
            local itemEntry = itemData[id]
            -- Exists only in item file
            table.insert(outputData, {
                ID = id,
                ["Block/Item"] = "Item",
                Mod = itemEntry.Mod,
                ["Unlocalised name"] = (itemEntry.DisplayName == "Unnamed Block, report to mod author.") and "null" or itemEntry.Name,
                Class = itemEntry.Class
            })
        end
    end
    return outputData
end

-- Function to write a table to CSV
local function writeCSV(file, data)
    for _, row in ipairs(data) do
        file:write(string.format("%s,%s,%s,%s,%s\n", row.ID, row["Block/Item"], row.Mod, row["Unlocalised name"], row.Class))
    end
end

-- Main program
local function transformCSV()
    -- Parse both files
    local itemData = parseCSV(itemFilePath)
    local blockData = parseCSV(blockFilePath)

    -- Merge data
    local mergedData = mergeData(itemData, blockData)

    -- Write to output
    local outputFile = io.open(outputFilePath, "w")
    outputFile:write("ID,Block/Item,Mod,Unlocalised name,Class\n") -- Write header
    writeCSV(outputFile, mergedData)
    outputFile:close()

    print("Transformation complete. Output saved to: " .. outputFilePath)
end

transformCSV()
