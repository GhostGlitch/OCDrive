local gstring = require("ghostString")
local gutil = require("ghostUtils")
local idk = {}

idk.parsePatterns = {
    modAliases = {
        AWWayofTime = "BloodMagic",
        ["crowley.skyblock"] = "exnihilo"
    },
    generalNamespaces = {
        name = {
            "tile[s]?",    -- Remove "tile." at the start
            "block[s]?",   -- Remove "block." at the start
            "item[s]?",  -- Remove "item." at the start
            "tool[s]?",
            "armo[u]?r",
        },
        class = {
           ".*iguanaman",
            "core",
            "common",
            "shared",
            "base",
            "item[s]?",
            "block[s]?",
        }
    },
    generalNamespaceSufixes = {
        "name",
    },
    modNamespaces = {
        --for mods which use a different name for their identifier, and in item names.
        name = {
            AppliedEnergistics     = {"appeng"},
            BloodMagic             = {"AWWayofTime"},
            exnihilo               = {"crowley%.skyblock"},
            ExtraUtilities         = {"extrautils"},
            Forestry               = {"for"},
            ForgeMicroblock        = {"microblock"},
            HungerOverhaul         = {"pamharvestcraft"},
            IguanaTweaksTConstruct = {"tconstruct" },
            Minecraft              = {"iguanatweakstconstruct"},
            MineFactoryReloaded    = {"mfr"},
            OpenComputers          = { "oc" },
            TConstruct             = {"decoration"}
        },
        --for mods which use a different name for their identifier, and in class paths.
        class = {
            AppliedEnergistics     = {"appeng"},
            asielib                = {"asie%.lib"},
            BloodMagic             = {"alchemicalwizardry"},
            BinnieCore             = {"binnie%.core"},
            ChickenChunks          = {"codechicken%.chunkloader"},
            ExtraUtilities         = {"extrautils"},
            ForgeMicroblock        = {"microblock"},
            gendustry              = {"bdew"},
            JABBA                  = {"betterbarrels"},
            OpenComputers          = {"oc"},
            OpenPeripheral         = {"openperipheral%.addons"},
            PluginsforForestry     = {"plugins"},
            ThermalExpansion       = {"thermalexpansion", "cofh"},
        },

    },
    modPrefixes = {
        name = {
            HardcoreQuesting = {"hqm"},
            ComputerCraft = {"cc"},
            BigReactors = {"br", "blockBR"},
            BiblioCraft = {"Biblio"},
        },
        classAsName = {
            AppliedEnergistics = {"AppEng"},
            pamharvestcraft = {"BlockPam","ItemPam"},
            ExtraTrees = {"BlockET","ItemET"},
            BigReactors = {"BR"}
        },
    },
    generalSubs = {
        pressureplate = "pressurePlate",
    },
    modSubs = {
        name = {
            extracells = {
                [" %- this item is just used to mime fluids!"] = ""
            },
            Minecraft = {
                ["hatchet"] = "axe"
            },
            TConstruct = {
                ["metal.molten"] = "molten"
            }
        }
    },
    hardcoded = {
        byName = {
            BiblioCraft = {
                ["tile.Bibliotheca"] = "Bookcase",
            },
            Minecraft = {
                ["tile.mycel"] = "mycelium",
                ["tile.lightgem"] = "glowstone",
                ["tile.musicBlock"] = "noteBlock",
                ["item.dyePowder"] = "dye",
                ["item.monsterPlacer"] = "spawnEgg",
                ["item.skull"] = "head",
                ["item.sulphur"] = "gunpowder",
                ["item.helmetCloth"] = "helmetLeather",
                ["item.chestplateCloth"] = "chestplateLeather",
                ["item.leggingsCloth"] = "leggingsLeather",
                ["item.bootsCloth"] = "bootsLeather",
                ["item.yellowDust"] = "glowstoneDust",
                ["item.diode"] = "repeaterItem"
            },
        },
        byClass = {
            BigReactors = {
                BlockBRMetal = "metalBlock"
            },
            extracells = {
                ItemSecureStoragePhysicalEncrypted = "SecureStorageEncrypted",
                ItemSecureStoragePhysicalDecrypted = "SecureStorageDecrypted",
            },
            ExtraTrees = {
                ItemMothDatabase = "mothDatabase"
            },
        },
        byID = {
            HungerOverhaul = { [105] = "melonStem" },
            MineFactoryReloaded = {[335] = "bucketMilk"},
            Minecraft = {
                [8] = "waterFlowing",
                [9] = "waterStill",
                [10] = "lavaFlowing",
                [11] = "lavaStill",
                [39] = "mushroomBrown",
                [40] = "mushroomRed",
                [43] = "stoneSlabDouble",
                [61] = "furnaceOff",
                [62] = "furnaceOn",
                [63] = "signStanding",
                [68] = "signWall",
                [70] = "pressurePlateStone",
                [72] = "pressurePlateWood",
                [73] = "redstoneOreOff",
                [74] = "redstoneOreOn",
                [75] = "redstoneTorchOff",
                [76] = "redstoneTorchOn",
                [93] = "repeaterOff",
                [94] = "repeaterOn",
                [99] = "mushroomBlockBrown",
                [100] = "mushroomBlockRed",
                [105] = "melonStem",
                [123] = "redstoneLampOff",
                [124] = "redstoneLampOn",
                [125] = "woodSlabDouble",
                [149] = "comparatorOff",
                [150] = "comparatorOn",
                [335] = "bucketMilk",
                [2256] = "record13",
                [2257] = "recordCat",
                [2258] = "recordBlocks",
                [2259] = "recordChirp",
                [2260] = "recordFar",
                [2261] = "recordMall",
                [2262] = "recordMellohi",
                [2263] = "recordStal",
                [2264] = "recordStrad",
                [2265] = "recordWard",
                [2266] = "record11",
                [2267] = "recordWait",
            }
        }
    }
}
function idk.stripNamespace(str, namespace, fromAnywhere)
    namespace = namespace:lower()
    local stripStr = (namespace .. "[:%.]")
    return gstring.stripIgnoreCase(str, stripStr, true, fromAnywhere)
end
function idk.stripNamespaceSuffix(str, namespace)
    namespace = namespace:lower()
    local stripStr = ("[:%.]" .. namespace .. "$")
    return gstring.stripIgnoreCase(str, stripStr)
end
function idk.stripEachNamespace(str, namespaceTable, fromAnywhere)
    for _, namespace in ipairs(namespaceTable) do
        str = idk.stripNamespace(str, namespace, fromAnywhere)
    end
    return str
end
function idk.stripEachNamespaceSuffix(str, namespaceTable)
    for _, namespace in ipairs(namespaceTable) do
        str = idk.stripNamespaceSuffix(str, namespace)
    end
    return str
end
function idk.stripModNamespace(str, modPatterns, curMod)
    if modPatterns[curMod] then
        str = idk.stripEachNamespace(str, modPatterns[curMod], true)
    end
        str = idk.stripNamespace(str, curMod, true)
    return str
end
function idk.stripPre(str, prefixTable, curMod)
    if prefixTable[curMod] then
        for _, pattern in ipairs(prefixTable[curMod]) do
            str = gstring.stripIgnoreCase(str, pattern, true) -- Apply each pattern
        end
    end
    return str
end

function idk.stripNamespacesName(name, curMod)
    local newName = idk.stripEachNamespace(name, idk.parsePatterns.generalNamespaces.name)
    newName = idk.stripModNamespace(newName, idk.parsePatterns.modNamespaces.name, curMod)
    newName = idk.stripEachNamespace(newName, idk.parsePatterns.generalNamespaces.name)
    return idk.stripEachNamespaceSuffix(newName, idk.parsePatterns.generalNamespaceSufixes)
end


function idk.cleanName(name, curMod)
    local newName = idk.stripPre(name, idk.parsePatterns.modPrefixes.name, curMod)

    local lowername = newName:lower()
    if lowername ~= "item" and lowername ~= "cheatyitem"
        and lowername ~= "multiitem" and lowername ~= "cheatitem"
        and lowername ~= "baseitem" then
        newName = gstring.stripIgnoreCase(newName, "Item$")
    end

    if idk.parsePatterns.modSubs.name[curMod] then
        for from, to in pairs(idk.parsePatterns.modSubs.name[curMod]) do
            newName = newName:gsub(from, to)
        end
    end


    return newName
end

function idk.cleanClass(class, curMod)
    class = class:gsub("%s", "")
    class = idk.stripModNamespace(class, idk.parsePatterns.modNamespaces.class, curMod)


    class = idk.stripEachNamespace(class, idk.parsePatterns.generalNamespaces.class)
    return class
end
function idk.standardizeName(name)

    local newName = name:gsub("[_%./](.)", function(match) return match:upper() end)
    for pattern, replacement in pairs(idk.parsePatterns.generalSubs) do
        newName = newName:gsub(pattern, replacement)
    end
    if newName ~= newName:upper() then
        newName = newName:gsub("^%a", string.lower)
    end
    local prefix, number = newName:match("(%a+[^T_%d*])(%d+)$")
    if number and not prefix:match("Tier$") then
        newName = prefix .. "_" .. number
    end
    newName = newName:gsub(" ", "_"):gsub("%'", ""):gsub("%(", "_"):gsub("%)", "_"):gsub("%-", "_")
    if newName:match("^%d") then
        newName = "_" .. newName
    end
    return newName
end
function idk.finalClean(name)
    local StorageBlocks = {
        "iron", "gold", "lapis",
        "diamond", "coal", "redstone",
        "emerald", "copper", "tin",
        "lead", "silver",
    }
    local newName = name
    local tmp
    if name:match("^[Bb]lock") then
        tmp = gstring.stripIgnoreCase(name, "block", true)
        if tmp ~= "" then
            for _, ingot in ipairs(StorageBlocks) do
                if ingot == tmp:lower() then
                    tmp = tmp .. "Block"
                    break
                end
            end
            newName = tmp
        end
    end
    tmp = gstring.stripIgnoreCase(newName, "item", true)
    if tmp ~= "" and tmp ~= "s" then
        newName = tmp
    end
    newName = idk.standardizeName(newName)
    return newName
end
function idk.tryGetHardcodedName(name, id, curMod, class)
    class = gstring.extractLastSegDot(class)
    local newName = nil
    local function getName(hardTable, field)
        if hardTable[curMod] and hardTable[curMod][field] then
            newName = hardTable[curMod][field]
        end
    end
    id = tonumber(id)
    getName(idk.parsePatterns.hardcoded.byClass, class)
    getName(idk.parsePatterns.hardcoded.byID, id)
    getName(idk.parsePatterns.hardcoded.byName, name)
    return newName
end
function idk.fixNameFromClassCore(oldName, item, curMod, tryPostfix)
    local classFinal = gstring.extractLastSegDot(item.class)
    local newName = classFinal
    local prefix, number = oldName:match("(%a+)[_%.]?(%d+)$")
    oldName = prefix or oldName
    if tryPostfix then
        local classPostfix = gstring.stripIgnoreCase(classFinal, oldName, true, true)
        if classPostfix ~= classFinal then
            newName = oldName .. classPostfix
        end
    end
    newName = idk.stripPre(newName, idk.parsePatterns.modPrefixes.classAsName, curMod)
    if number then
        newName = newName .. "_" .. number
    end
    newName = idk.finalClean(newName)
    return newName
end
function idk.parseName(name, class, id, curMod, hardcodedNameFunc)
    local hardName = hardcodedNameFunc(name, id, curMod, class)
    local simpleName = idk.stripNamespacesName(name, curMod)
    local newName
    if hardName then
        newName = idk.standardizeName(hardName)
    elseif simpleName == "null" then
        local item = { class = class }
        newName = idk.fixNameFromClassCore(simpleName, item, curMod, false)
    else
        newName = idk.cleanName(simpleName, curMod)
        newName = idk.finalClean(newName)
    end
    --idk.printIfRename(simpleName, newName)
    return newName
end

return idk