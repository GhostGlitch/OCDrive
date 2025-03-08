local gutil = require("ghostUtils")
local iTable = require("itemTable")
function makeIDToNameModTable(outputPath)
    local idToNameMod = {}
    for mod, names in pairs(iTable) do
        for name, data in pairs(names) do
            local id = tonumber(data.id)
            if id then
                idToNameMod[id] = { name, mod }
            end
        end
    end

    local file = gutil.open(outputPath, "w")
    file:write("local idToNameMod = {\n")

    local sortedIds = gutil.sortKeys(idToNameMod)
    for _, id in ipairs(sortedIds) do
        local mapping = idToNameMod[id]
        file:write(string.format(
            "    [%d] = {name = %q, mod = %q},\n",
            id, mapping[1], mapping[2]
        ))
    end

    file:write("}\n\nreturn idToNameMod")
    file:close()
    gutil.happyPrint("ID-Name/Mod table saved to " .. outputPath)
end
return makeIDToNameModTable