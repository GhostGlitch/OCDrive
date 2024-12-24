local itemTable = require("itemTable")

-- Open a file to write the results
local outputFilePath = "/output_file.txt"
local outputFile = io.open(outputFilePath, "w")

-- Iterate through all mods
for mod, names in pairs(itemTable) do
    -- Iterate through all names for the current mod
    for name, entries in pairs(names) do
        -- Check if there is more than one entry under this name
        if #entries > 1 then
            -- Write the mod and name to the file
            outputFile:write(string.format("Mod: %s, Name: %s\n", mod, name))
            -- Write each entry's details
            for i, item in ipairs(entries) do
                outputFile:write(string.format("  Entry %d:\n", i))
                outputFile:write(string.format("    ID: %s\n", item.ID or "N/A"))
                outputFile:write(string.format("    Type: %s\n", item.Type or "N/A"))
                outputFile:write(string.format("    Class: %s\n", item.Class or "N/A"))
            end
            outputFile:write("\n") -- Add an extra line for readability
        end
    end
end

-- Close the output file
outputFile:close()

print("Results written to " .. outputFilePath)
