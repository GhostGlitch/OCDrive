local comp = require("component")
local gutil = require("ghostUtils")
local gcomp = {}
gcomp.version = 1.0

function gcomp.getAll()
    local tList = {}
    for address, compType in comp.list() do
        if not tList[compType] then
            tList[compType] = {}
        end
        table.insert(tList[compType], address)
    end
    return tList
end

function gcomp.getAllType(type)
    local tList = {}
    for address, _ in comp.list(type) do
        table.insert(tList, address)
    end
    return tList
end

function gcomp.groupTypeByMethods(compList)
    local groups = {}

    for _, address in ipairs(compList) do
        local methods = comp.methods(address)
        local matchedGroup = nil

        -- Check if the methods match an existing group
        for _, group in ipairs(groups) do
            if gutil.compareTables(group.methods, methods) then
                matchedGroup = group
                break
            end
        end

        -- If no group matches, create a new one
        if not matchedGroup then
            matchedGroup = { methods = methods, addresses = {} }
            table.insert(groups, matchedGroup)
        end

        -- Add the address to the matched group
        table.insert(matchedGroup.addresses, address)
    end

    return groups
end
if comp.isAvailable("thermalexpansion_energycell_resonant_name") then

    --should generalize to all resonant cells, not just the primary.
    resonantList = gcomp.getAllType("thermalexpansion_energycell_resonant_name")
    for i, address in ipairs(resonantList) do
        resonant = comp.proxy(address)
        function resonant.getEnergyPercent()
            local current = resonant.getEnergyStored()
            local max = resonant.getMaxEnergyStored()
            return (current / max) * 100
        end
    end

    gcomp.resonant=comp.thermalexpansion_energycell_resonant_name
end

if comp.isAvailable("screen") then
    --should generalize to all resonant cells, not just the primary.
    screenList = gcomp.getAllType("screen")
    for i, address in ipairs(screenList) do
        screen = comp.proxy(address)
        function screen.getAspectRatioSmart()
            local x,y
            if gutil.isNative() then
                x, y = comp.screen.getAspectRatio()
            else
                x, y = 16, 9
            end
            return x,y
        end
    end

    gcomp.screen = comp.screen
end

return gcomp