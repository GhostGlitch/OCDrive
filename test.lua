local function createIdMapping(inputPath, outputPath)
    -- Load the itemTable
    local ok, itemTable = pcall(require, inputPath)
    if not ok or not itemTable then
        error("Failed to load itemTable from " .. inputPath)
    end

    -- Create the new mapping table
    local idMapping = {}

    -- Iterate over mods and names
    for mod, names in pairs(itemTable) do
        if not idMapping[mod] then
            idMapping[mod] = {}
        end
        for name, data in pairs(names) do
            idMapping[mod][name] = data.id
        end
    end

    -- Save the new table to the specified output path
    local file = io.open(outputPath, "w")
    if not file then
        error("Failed to open file for writing: " .. outputPath)
    end

    file:write("local idMapping = {\n")
    for mod, names in pairs(idMapping) do
        file:write(string.format("    %s = {\n", mod))
        for name, id in pairs(names) do
            file:write(string.format("        %s = %q,\n", name, id))
        end
        file:write("    },\n")
    end
    file:write("}\n\nreturn idMapping")
    file:close()

    print("ID mapping table saved to " .. outputPath)
end

-- Example usage
createIdMapping("/itemTable", "/idMapping.lua")


local function createIdToNameModMapping(inputPath, outputPath)
    -- Load the itemTable
    local ok, itemTable = pcall(require, inputPath)
    if not ok or not itemTable then
        error("Failed to load itemTable from " .. inputPath)
    end

    -- Create the ID-to-name-mod mapping table
    local idToNameModMapping = {}

    -- Iterate over mods and names
    for mod, names in pairs(itemTable) do
        for name, data in pairs(names) do
            local id = tonumber(data.id) -- Convert ID to a number
            if id then
                idToNameModMapping[id] = {name, mod}
            end
        end
    end

    -- Get a sorted list of IDs
    local sortedIds = {}
    for id in pairs(idToNameModMapping) do
        table.insert(sortedIds, id)
    end
    table.sort(sortedIds) -- Sort the IDs in ascending order

    -- Save the new table to the specified output path
    local file = io.open(outputPath, "w")
    if not file then
        error("Failed to open file for writing: " .. outputPath)
    end

    file:write("local idToNameModMapping = {\n")
    for _, id in ipairs(sortedIds) do
        local mapping = idToNameModMapping[id]
        file:write(string.format(
            "    [%d] = {name = %q, mod = %q},\n",
            id, mapping[1], mapping[2]
        ))
    end
    file:write("}\n\nreturn idToNameModMapping")
    file:close()

    print("ID-to-Name-Mod mapping table saved to " .. outputPath)
end

-- Example usage
createIdToNameModMapping("/itemTable", "/idToNameModMapping.lua")


local function itemTableToCSV(inputPath, outputPath)
    -- Load the itemTable
    local ok, itemTable = pcall(require, inputPath)
    if not ok or not itemTable then
        error("Failed to load itemTable from " .. inputPath)
    end

    -- Create a temporary list to store all items with their IDs
    local itemList = {}

    -- Iterate over mods and names
    for mod, names in pairs(itemTable) do
        for name, data in pairs(names) do
            local id = tonumber(data.id) -- Convert ID to a number
            if id then
                table.insert(itemList, {
                    id = id,
                    type = data.type,
                    mod = mod,
                    unlocalised = name,
                    class = data.class
                })
            end
        end
    end

    -- Sort the items by ID
    table.sort(itemList, function(a, b)
        return a.id < b.id
    end)

    -- Write the sorted data to a CSV file
    local file = io.open(outputPath, "w")
    if not file then
        error("Failed to open file for writing: " .. outputPath)
    end

    -- Write the header line
    file:write("ID,Type,Mod,Unlocalised,Class\n")

    -- Write each item
    for _, item in ipairs(itemList) do
        file:write(string.format(
            "%d,%s,%s,%s,%s\n",
            item.id,
            item.type,
            item.mod,
            item.unlocalised,
            item.class
        ))
    end

    file:close()
    print("CSV file saved to " .. outputPath)
end

-- Example usage
itemTableToCSV("/itemTable", "/itemTable.csv")



local function createUnlocalIdToNameModMapping(inputPath, outputPath)
    -- Load the itemTable
    local ok, itemTable = pcall(require, inputPath)
    if not ok or not itemTable then
        error("Failed to load itemTable from " .. inputPath)
    end

    -- Create the ID-to-name-mod mapping table
    local idToNameModMapping = {}

    -- Iterate over mods and names
    for mod, names in pairs(itemTable) do
        for name, data in pairs(names) do
            local id = tonumber(data.id) -- Convert ID to a number
            if id then
                idToNameModMapping[id] = data.unlocalised
            end
        end
    end

    -- Get a sorted list of IDs
    local sortedIds = {}
    for id in pairs(idToNameModMapping) do
        table.insert(sortedIds, id)
    end
    table.sort(sortedIds) -- Sort the IDs in ascending order

    -- Save the new table to the specified output path
    local file = io.open(outputPath, "w")
    if not file then
        error("Failed to open file for writing: " .. outputPath)
    end

    file:write("local idToNameModMapping = {\n")
    for _, id in ipairs(sortedIds) do
        local mapping = idToNameModMapping[id]
        file:write(string.format(
            "    [%d] = %q,\n",
            id, mapping
        ))
    end
    file:write("}\n\nreturn idToNameModMapping")
    file:close()

    print("ID-to-Name-Mod mapping table saved to " .. outputPath)
end

-- Example usage
createUnlocalIdToNameModMapping("/itemTable", "/IDToNameUnlocal.lua")

local function createUnlocalIdMapping(inputPath, outputPath)
    -- Load the itemTable
    local ok, idToNameTable = pcall(require, inputPath)
    if not ok or not idToNameTable then
        error("Failed to load idTable from " .. inputPath)
    end

    -- Save the new table to the specified output path
    local file = io.open(outputPath, "w")
    if not file then
        error("Failed to open file for writing: " .. outputPath)
    end

    file:write("local idMapping = {\n")
    --for mod, names in pairs(idMapping) do
        --file:write(string.format("    %s = {\n", mod))
    for id, name in pairs(idToNameTable) do
        file:write(string.format("    [%q] = %q,\n", name, id))
    end
    file:write("}\n\nreturn idMapping")
    file:close()

    print("ID mapping table saved to " .. outputPath)
end

-- Example usage
createUnlocalIdMapping("/IDToNameUnlocal", "/nameToIDUnlocal.lua")