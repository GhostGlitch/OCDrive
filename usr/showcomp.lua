local comp = require("component")
local ev = require("event")
local gcomp = require("ghostComp")
local gutil = require("ghostUtils")
local ser = require("serialization")
local fs = require("filesystem")
output = fs.open("compList.txt", "w")
local function log(message)
    print(message) -- Print to console
    output:write(message .. "\n") -- Write to file
end


local function printMethods(methods)
    for methodName, isDirect in pairs(methods) do
        log(string.format("        %s (direct: %s)", methodName, tostring(isDirect)))
    end
end
local function printGroupedType(groups, type)
    for groupIn, group in ipairs(groups) do
        if #groups ~= 1 then
            log("  Group #" .. groupIn .. ":")
        end
        for _, address in ipairs(group.addresses) do
            log("    " .. address)
        end
        printMethods(group.methods)
    end
end
local function scrubOwnAddress(compList,sortedTypes)
    if #compList["computer"] == 1 then
        compList["computer"] = nil
        for i = #sortedTypes, 1, -1 do
            if sortedTypes[i] == "computer" then
                table.remove(sortedTypes, i)
                break
            end
        end
        return
    end
    for _, address in pairs(compList["computer"]) do
        if address == computer.address then
            table.remove(compList["computer"], address)
        end
    end
end

-- MAIN
-- Iterate through each type and print addresses and methods
local compList = gcomp.getAll()
local sortedTypes = gutil.sortKeys(compList)
scrubOwnAddress(compList, sortedTypes)
for index, compType in pairs(sortedTypes) do
    log(compType .. ":")
    local groups = gcomp.groupTypeByMethods(compList[compType])
    printGroupedType(groups, compType)
    if index < #sortedTypes then
    gutil.waitForAny(false)
    end
end