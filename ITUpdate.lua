local gdebug = require("ghostDebug").getDebug(true, false)
--gdebug = require("ghostDebug").getDebug(true)
local comp = require("component")
local serial = require("serialization")
local fs = require("filesystem")
local itemTable = require("ITTest")
local idTable = require("idToNameMod")
local gstring = require("ghostString")
local idk = require("idk")
local gutil = require("ghostUtils")
local gmath = require("ghostMath")
local b32 = gmath.bit32

local availableTable = {}
if gutil.isNative() then
    local cont = comp.appeng_blocks_controller
    availableTable = cont.getAvailableItems()
else
    local availableFile = io.open("Available.txt", "r")
    availableTable = serial.unserialize(availableFile:read("*a"))
end
--local availableFile = gutil.open("Available.txt", "w")

local function pfnPotion(id)
    local StrongBit = 0x20
    local LongBit = 0x40
    local DrinkBit = 0x2000
    local SplashBit = 0x4000
    local basePotions = {
        [0] = "water",
        [1] = "regeneration",
        [2] = "swiftness",
        [3] = "fireResistance",
        [4] = "poison",
        [5] = "healing",
        [6] = "nightVision",
        [7] = "clear",
        [8] = "weakness",
        [9] = "strength",
        [10] = "slowness",
        [11] = "diffuse",
        [12] = "harming",
        [13] = "artless",
        [14] = "invisibility",
        [15] = "thin",
        [16] = "awkward",
        [23] = "bungling",
        [27] = "smooth",
        [29] = "suave",
        [31] = "debonair",
        [32] = "thick",
        [39] = "charming",
        [43] = "refined",
        [45] = "cordial",
        [47] = "sparkling",
        [48] = "potent",
        [55] = "rank",
        [59] = "acrid",
        [61] = "gross",
        [63] = "stinky",
        [64] = "mundane",
    }
    local function getExtraNum(id, isUnfinished)
        local sixteenth = b32.band(id, 0x10)
        local extracted = b32.band(id, 0x1F80)
        local output = 0
        if isUnfinished then
            output = b32.rshift(extracted, 7) + (b32.rshift(id, 15) * 0x40)
        else
            output = b32.rshift(extracted, 6) + b32.rshift(sixteenth, 4) + (b32.rshift(id, 15) * 0x80)
        end
        if output == 0 then
            return nil
        end
        return output
    end

    local isUnfinished = false
    local isMundane = false
    --pare down to potion type
    local baseID = id % 64
    --handle unfinished
    if baseID == 0 and id ~= 0 then
        baseID = 64
        isMundane = true
    end
    local baseIDMod = baseID % 16
    if baseIDMod == 0 or baseIDMod == 7 or baseIDMod == 11 or baseIDMod == 13 or baseIDMod == 15 then
        isUnfinished = true
    else
        baseID = baseIDMod
    end
    local name = basePotions[baseID]
    local suffixes = {}
    if gmath.checkForBits(id, StrongBit) and not isUnfinished then
        table.insert(suffixes, "L2")
    end
    if gmath.checkForBits(id, LongBit) then
        if not isMundane then
            table.insert(suffixes, "Long")
        end
    elseif isMundane then
        table.insert(suffixes, "Short")
    end
    local isNotDrink = not gmath.checkForBits(id, DrinkBit)
    if gmath.checkForBits(id, SplashBit) then
        if isNotDrink then
            table.insert(suffixes, "Splash")
        else
            table.insert(suffixes, "Splink")
        end
    else
        if isNotDrink then
            if not isUnfinished then
                table.insert(suffixes, "NoDrink")
            end
        elseif isUnfinished then
            table.insert(suffixes, "High")
        end
    end

    local extraNum = getExtraNum(id, isUnfinished)
    if extraNum then
        table.insert(suffixes, "_" .. extraNum)
    end
    return name .. table.concat(suffixes)
end
local function pfnMarkRoman(name, index)
    local roman = gmath.toRoman(index)
    --print(name, index, roman)
    return "MK" .. roman
end
local function pfnLXNumber(name, index)
    return "LX" .. index
end
local abstractPP = {
    singleDouble = {
        [0] = "single",
        [1] = "double",
        [2] = "triple",
        [3] = "quadruple",
        [4] = "quintuple",
        [5] = "sextuple",
        [6] = "septuple",
        [7] = "octuple"
    },
}

local subnameParsePats = {
    niceNameAliases = {
        exnihilo = {
            siftingTable = "sieve",
        },
        Natura = {
            berryBush = "bushBerry",
            berrybushNether = "bushBerry",
            netherfood = "foodNether"
        },
        TConstruct = {
            metalblock = "storageMetals"
        },
        TSteelworks = {
            dustblock = "storageDust"
        },
        Minecraft = {
            buttonStone = "button",
            buttonWood = "button",
            dye = "dyepowder",
            furnaceOff = "furnace",
            glowstone = "lightgem",
            head = "skull",
            mushroomBrown = "mushroom",
            mushroomRed = "mushroom",
            mycelium = "mycel",
            noteBlock = "musicBlock",
            redstoneTorchOn = "notGate",
            snowBlock = "snow",
            spawnEgg = "monsterPlacer",
            recordBlocks="record",
            recordCat="record",
            recordChirp="record",
            recordFar="record",
            recordMall="record",
            recordMellohi="record",
            recordStal="record",
            recordStrad="record",
            recordWait="record",
            recordWard="record",
            repeaterItem = "diode",
            coal = "",
            brickBlock="brick",
            clayBlock = "clay",
            glowstoneDust="yellowDust",
            gunpowder="sulphur",
        },
    },
    hardcoded = {
        byNameNum = {
            BigReactors = {
                ["tile.brMetal"] = {
                    [0] ="yellorium",
                    [1] = "cyanite",
                    [2] = "graphite",
                    [3] = "blutonium"
                },
                ["tile.blockReactorPart"] ={
                    [0] = "casing",
                    [1] = "controller",
                    [2] = "powerTap",
                    [3] = "accessPort",
                    [4] = "rednetPort",
                    [5] = "computerPort",
                    [6] = "coolantPort",
                },
            },
            ComputerCraft = {
                ["item.cccomputer"] = "basic"
            },
            ExtraUtilities = {
                ["tile.extrautils:decorativeBlock1"] = {[9] ="sandyGlass"},
                ["tile.extrautils:generator"] = {[4] = "heatedRedstone"},
                ["tile.extrautils:cobblestone_compressed"] = abstractPP.singleDouble
            },
            Forestry = {
                ["tile.beehives"] ={
                    [0] = "forest",
                    [1] = "meadows",
                    [2] = "modest",
                    [3] = "tropical",
                    [6] = "wintry",
                    [7]  = "marshy",
                },
                ["tile.for.factory"] ={
                    [0] = "bottler",
                    [1] = "carpenter",
                    [2] = "centrifuge",
                    [3] = "fermenter",
                    [4] = "moistener",
                    [5] = "squeezer",
                    [6] = "still",
                    [7] = "rainmaker",
                },
            },
            JABBA = {
                ["item.upgrade.structural"] = pfnMarkRoman,
            },
            Minecraft = {
                ["item.skull.char"] = "player",
            },
            MineFactoryReloaded = {
                ["tile.mfr.cable.redstone"] = "basic",
                ["item.mfr.upgrade.logic"] = pfnLXNumber,
            },
            simplyjetpacks = {
                ["item.simplyjetpacks.components"] ={
                    [0] = "thrusterLeadstone",
                    [1] = "thrusterHardened",
                    [2] = "thrusterRedstone",
                    [3] = "thrusterResonant",
                    [4] = "leatherStrap",
                    [5] = "platingIron",
                    [6] = "platingTinkers",
                    [7] = "platingInvar",
                    [8] = "platingEnderium"
                },
            },
            Thaumcraft = {
                ["tile.blockCustomOre"] = {
                    [0] = "cinnabar",
                    [1] = "air",
                    [2] = "fire",
                    [3] = "water",
                    [4] = "earth",
                    [5] = "order",
                    [6] = "entropy",
                    [7] = "amber",
                },
                ["tile.blockCustomPlant"] ={
                    [0]= "greatwoodSapling",
                    [1] = "silverwoodSapling",
                    [2] = "shimmerleaf",
                    [3] = "cinderpearl",
                    [4] = "etherialBloom",
                },
                ["item.ItemEssence"] = {
                    [0] = "empty",
                    [1] = "full",
                },
                ["tile.blockMetalDevice"] = {
                    [0] ="crucible",
                    [1] = "alembic",
                    [5] = "grate",
                    [7] = "arcaneLamp",
                    [8] = "growthLamp",
                    [9] = "alchemicalConstruct",
                    [12] = "mneumonicMatrix",
                    [13] = "fertilityLamp",
                },
                ["item.ItemNugget"] = {
                    [0] ="iron",
                    [1] = "copper",
                    [2] = "tin",
                    [3] = "silver",
                    [4] = "lead",
                    [5] = "quicksilver",
                    [6] = "thaumium",
                },
                ["item.ItemResource"] = {
                    [0]= "alumentum",
                    [1] = "nitor",
                    [2] = "thaumiumIngot",
                    [3] = "quicksilver",
                    [4] = "magicTallow",
                    [5] = "zombieBrain",
                    [6] = "amber",
                    [7] = "enchantedFabric",
                    [8] = "visFilter",
                    [9] = "knowledgeFragment",
                    [10] = "mirroredGlass",
                    [11] = "taintedGoo",
                    [12] = "taintTendril",
                    [13] = "jarLabel",
                    [14] = "salisMundus",
                    [15] = "primalCharm",
                },
                ["item.ItemShard"] ={
                    [0] = "air",
                    [1] = "fire",
                    [2] = "water",
                    [3] = "earth",
                    [4] = "order",
                    [5] = "entropy",
                },
                ["tile.blockTaint"] ={
                    [0]= "crushed",
                    [1] = "soil",
                    [2] = "fleshBlock",
                },
            }
        },
        byDamage = {
            AppliedEnergistics = {
                ["AppEng.Blocks.Cable"] = {
                    [10] = "cableBlack",
                    [11] = "cableWhite",
                    [12] = "cableBrown",
                    [13] = "cableRed",
                    [14] = "cableYellow",
                    [15] = "cableGreen",
                }
            },
            Enchiridion = {["item.items"] = { [1] = "bookBinder "}},
            ForgeMicroblock = {
                ["item.microblock"] = {
                    [1] = "cover",
                    [2] = "panel",
                    [4] = "slab",
                    [513] = "nook",
                    [514] = "corner",
                    [516] = "notch",
                    [769] = "strip",
                    [770] = "post",
                    [772] = "pillar",
                }
            },
            Forestry = {
                ["item.thermionicTubes"] = {
                    [0] = "copper",
                    [1] = "tin",
                    [2] = "bronze",
                    [3] = "iron",
                    [4] = "gold",
                    [5] = "diamond",
                    [6] = "obsidian",
                    [7] = "blaze",
                    [8] = "rubberized",
                    [9] = "emerald",
                    [10] = "apatite",
                    [11] = "lapis"
                }
            },
            Mariculture = {
                ["item.fishyFood"] = {
                    [0] = "codRaw",
                    [1] = "perchRaw",
                    [2] = "tunaRaw",
                    [3] = "netherfishRaw",
                    [4] = "glowfishRaw",
                    [5] = "blazefishRaw",
                    [6] = "nightfishRaw",
                    [7] = "enderfishRaw",
                    [8] = "dragonfishRaw",
                    [9] = "minnowRaw",
                    [10] = "salmonRaw",
                    [11] = "bassRaw",
                    [12] = "tetraRaw",
                    [13] = "catfishRaw",
                    [14] = "piranhaRaw",
                    [15] = "stingRayRaw",
                    [16] = "mantaRayRaw",
                    [17] = "electricRayRaw",
                    [18] = "damselfishRaw",
                    [19] = "angelfishRaw",
                    [20] = "pufferfishRaw",
                    [21] = "squidRaw",
                    [22] = "jellyfishRaw",
                    [23] = "manOWarRaw",
                    [24] = "goldfishRaw",
                    [25] = "siameseFightinFishRaw",
                    [26] = "KoiRaw",
                    [27] = "butterflyFishRaw",
                    [28] = "blueTangRaw",
                    [29] = "clownfishRaw",
                    [30] = "silverStripeBlaasopRaw",
                    [31] = "whitemarginStargazerRaw",
                    [32] = "lampreyRaw",
                    [33] = "spiderFishRaw",
                    [34] = "undeadFishRaw",
                    [35] = "bonelessFishRaw",
                    [36] = "anglerfishRaw",
                    [37] = "rainbowTroutRaw",
                    [38] = "redHerringRaw",
                    [39] = "minecraftFishRaw",
                },
            },
            Minecraft = {
                ["item.potion"] = pfnPotion,
                ["item.monsterPlacer"] = {
                    [0] = "blizz",
                    [4] = "highGolem",
                    [50] = "creeper",
                    [51] = "skeleton",
                    [52] = "spider",
                    [54] = "zombie",
                    [55] = "slime",
                    [56] = "ghast",
                    [57] = "pigman",
                    [58] = "enderman",
                    [59] = "caveSpider",
                    [60] = "silverfish",
                    [61] = "blaze",
                    [62] = "magmaCube",
                    [63] = "bat",
                    [64] = "witch",
                    [90] = "pig",
                    [91] = "sheep",
                    [92] = "cow",
                    [93] = "chicken",
                    [94] = "squid",
                    [95] = "wolf",
                    [96] = "mooshroom",
                    [97] = "snowGolem",
                    [98] = "ocelot",
                    [99] = "ironGolem",
                    [100] = "horse",
                    [120] = "villager",
                },
        },
            Natura = {
                ["tile.bloodwood"] = {
                    [0] = "corner",
                    [15] = "single",
                }
            },
            OpenBlocks = {
                ["tile.openblocks.trophy"] = {
                    [16] = "slime"
                }
            },
            OpenComputers = {
                ["oc:item.FloppyDisk"] = {
                    [47] = "floppyDiskPreload",
                    [60] = "floppyDiskOpenOs"
                }
            }
        }
    },
    toolPatterns = {
        "AppEng%.Tools",
        "item%.microblock:saw",
        "thermalexpansion%.armor",
        "thermalexpansion%.tool",
        "^item%.alchemyFlask$",
        "^hammer_stone$",
        "^hammer_diamond$",
        "^crook$",
        "^item%.flintAndSteel",
        "^item%.bow$",
        "NaturaBow$",
        "chisel$",
        "^item.hatchet",
        "^item%.pickaxe",
        "^item%.shovel",
        "^item%.sword",
    },
}

local function tryGetHardcodedSubName(name, damage, curMod)
    local newName = nil
    local function getName(hardTable, inname, index)
        --gdebug.printIf(curMod == "ComputerCraft", inname, partname, index)
        --gdebug.printIf(curMod == "Minecraft", inname, damage)
        if hardTable[curMod] and hardTable[curMod][inname] then
            --gdebug.printIf(curMod == "Minecraft", inname, damage)
            if type(hardTable[curMod][inname]) == "function" then

                newName = hardTable[curMod][inname](damage, index)
            elseif hardTable[curMod][inname][index] then
                newName = hardTable[curMod][inname][index]
            elseif type(hardTable[curMod][inname]) ~= "table" then
                newName = hardTable[curMod][inname]
            end
        end
    end
    local partname, index = name:match("(.+)[_%.](%d+)$")
    if not partname then partname = name end
    index = tonumber(index)
    --gdebug.printIfDelay(curMod == "MineFactoryReloaded", 0, name, partname, index)
    getName(subnameParsePats.hardcoded.byNameNum, partname, index)
    getName(subnameParsePats.hardcoded.byDamage, name, damage)
    return newName
end
local function cleanSubName(subname, niceName, damage, curMod)
    if subnameParsePats.niceNameAliases[curMod] and subnameParsePats.niceNameAliases[curMod][niceName] then
        niceName = subnameParsePats.niceNameAliases[curMod][niceName]
    end
    local newName = gstring.stripIgnoreCase(subname, niceName, true)
    if niceName:match("%d$")  then
        niceName = niceName:match("(.+[^_%d*])_?(%d+)$")
    end
    --newName = gstring.stripIgnoreCase(newName, niceName, true)
    newName = gstring.stripIgnoreCase(newName, niceName, true)
    newName = gstring.stripIgnoreCase(newName, niceName .. "$")
    if niceName:match("Generic$") then
        niceName = niceName:match("(.+)Generic")
        --newName = gstring.stripIgnoreCase(newName, niceName, true)
        newName = gstring.stripIgnoreCase(newName, niceName, true)
        newName = gstring.stripIgnoreCase(newName, niceName .. "$")
    end
    local num = tonumber(newName:match("^_?(%d+)$"))
    --gdebug.printIf(niceName == "cosmeticOpaque", niceName, newName)
    newName = idk.standardizeName(newName)
    if newName == "" or tostring(newName) == tostring(damage) or num == damage then
        newName = "damage_" .. damage
    end
    return newName
end
local function parseSubName(subName, curMod, niceName, damage)
    if subName == "null" or subName == nil then
        subName = "damage_" .. damage
    end
    --gdebug.printIfDelay(curMod == "nil", .1, name)
    local newName = idk.parseName(subName, nil, damage, curMod, tryGetHardcodedSubName)
    newName = cleanSubName(newName, niceName, damage, curMod)
    --idk.printIfRename(simpleName, newName)
    return newName
end
local function stripBadEntries(subTable)
    local removals = {}
    for mod, names in pairs(subTable) do
        --print(serial.serialize(names, "pretty"))
        --os.sleep(20)
        for name, items in pairs(names) do
            local count = 0
            for _ in pairs(items) do
                count = count + 1
                if count == 2 then break end
            end
            --gdebug.printIf(name == "lavaTank_1", name, "count", count)
            if count == 1 then
                local hasOthers = false
                for _, subitem in pairs(itemTable[mod][name]) do
                    --gdebug.printIf(name == "lavaTank_1", subitem, subitem.damage)
                    if subitem.damage and subitem.damage ~= 0 then
                        hasOthers = true
                        break
                    end
                end
                --print(serial.serialize(items))
                if not hasOthers and items[0] and items[0].subname == "damage_0" then
                    --print(serial.serialize(item))
                    --gdebug.printIf(name == "lavaTank_1", "removing", items[0], items[0].damage)
                    table.insert(removals, { mod = mod, name = name })
                end
            end
        end
        coroutine.yield("cleaned ".. mod, gutil.vibes.happy)
    end
    for _, keys in ipairs(removals) do
        subTable[keys.mod][keys.name] = nil
    end
    for mod in pairs(subTable) do
        if not next(subTable[mod]) then
            subTable[mod] = nil
        end
    end
    return subTable
end
local function makeNewTable(iTable)
    local newTable = {}
    for i = 1, availableTable["n"] do
        if i%64 == 0 then
            coroutine.yield("Parsed "..i.." items in inventory")
        end
        local item = availableTable[i]
        local ignore = false
        for _, pattern in ipairs(subnameParsePats.toolPatterns) do
            if item.name:match(pattern) then
                ignore = true
                break
            end
        end
        if not ignore then
            local alreadyExists = false
            local id = item.id
            local damage = item.damage
            local oldData = idTable[id]
            local unlocalSub = item.name
            local subname
            local niceName
            local mod
            if oldData then
                mod = oldData.mod
                niceName = oldData.name
                if iTable[mod] and iTable[mod][niceName] then
                    for _, subItem in pairs(iTable[mod][niceName]) do
                        if tonumber(subItem.damage) == tonumber(damage) then
                            alreadyExists = true
                            break
                        end
                    end
                end
            else
                if id <= 421 or (id >= 2256 and id <= 2267) then
                    mod = "Minecraft"
                else
                    mod = "UNKNOWNMOD"
                end
                niceName = "UNKNOWNITEM"
            end
            subname = parseSubName(unlocalSub, mod, niceName, damage)
            if subname and not alreadyExists then
                if not newTable[mod] then
                    newTable[mod] = {}
                end
                if not newTable[mod][niceName] then
                    newTable[mod][niceName] = {}
                end
                if not newTable[mod][niceName][damage] then
                    newTable[mod][niceName][damage] = {
                        ["subname"] = subname,
                        ["damage"] = item.damage,
                        ["unlocalised"] = unlocalSub
                    }
                    if mod == "UNKNOWNMOD" then
                        newTable[mod][niceName][damage][id] = item.id
                    end
                end
            end
        end
    end
    return newTable
end

local function updateIT(newTable, iTable)
    for mod, names in pairs(newTable) do
        for name, subitems in pairs(names) do
            for _, subItem in pairs(subitems) do
                local topItem = iTable[mod][name]
                local subname = subItem.subname
                if not iTable[mod][name][subname] then
                    iTable[mod][name][subname] = {
                        ["id"] = topItem.id,
                        ["type"] = topItem.type,
                        ["class"] = topItem.class,
                        ["unlocalised"] = subItem.unlocalised,
                        ["damage"] = subItem.damage,
                    }
                else
                    local alreadyItem = iTable[mod][name][subname]
                    if alreadyItem ~= "AMBIGUOUSNAME" then
                        local alreadyName = subname .. "_" .. alreadyItem.damage
                        iTable[mod][name][alreadyName] = {
                            ["id"] = alreadyItem.id,
                            ["type"] = alreadyItem.type,
                            ["class"] = alreadyItem.class,
                            ["unlocalised"] = alreadyItem.unlocalised,
                            ["damage"] = alreadyItem.damage,
                        }
                        iTable[mod][name][subname] = "AMBIGUOUSNAME"
                    end
                    subname = subname .. "_" .. subItem.damage
                    if not iTable[mod][name][subname] then
                        iTable[mod][name][subname] = {
                            ["id"] = topItem.id,
                            ["type"] = topItem.type,
                            ["class"] = topItem.class,
                            ["unlocalised"] = subItem.unlocalised,
                            ["damage"] = subItem.damage,
                        }
                    end
                    --gdebug.printIf(name == "lavaTank_1", subname, subItem.damage)
                end
            end
        end
        coroutine.yield("Subitems added to " .. mod, gutil.vibes.happy)
    end
return iTable
end

local function saveItemTable(iTable, outputPath)

    --gutil.happyPrint("Saving entire item table")
    
    -- Open the file in write mode to overwrite existing content
    local file = gutil.open(outputPath, "w")
    file:write("local itemTable = {\n") -- Start the Lua table
    -- Process each mod
    for mod, mTable in pairs(iTable) do
        --gutil.happyPrint("Saving mod: " .. mod)
        file:write(string.format('    %s={\n', mod))

        -- Collect and sort item names by ID
        local nameKeys = idk.sortKeysByID(mTable)

        -- Process each item
        for i, name in ipairs(nameKeys) do
            local data = mTable[name]
            file:write(string.format(
                '        %s={id="%s", type="%s", unlocalised="%s", class="%s"',
                name, data.id, data.type, data.unlocalised, data.class
            ))

            -- Check for and write subitems
            local sortedSubnames = {}
            local AmbiguousSubnames = {}
            for key, value in pairs(data) do
                if value == "AMBIGUOUSNAME" then
                    table.insert(AmbiguousSubnames, key)
                elseif key ~= "id" and key ~= "type" and key ~= "class" and key ~= "unlocalised" then
                    table.insert(sortedSubnames, key)
                end
            end
            table.sort(sortedSubnames, function(a, b)
                return tonumber(mTable[name][a].damage) < tonumber(mTable[name][b].damage)
            end)

            for _, subname in ipairs(sortedSubnames) do
                local subdata = data[subname]
                if type(subdata) == "table" and subdata.id and subdata.damage then
                    file:write(string.format(
                        ',\n                %s={id="%s", damage="%s", type="%s", unlocalised="%s", class="%s"}',
                        subname, subdata.id, subdata.damage, subdata.type, subdata.unlocalised, subdata.class
                    ))
                end
            end
            for _, subname in ipairs(AmbiguousSubnames) do
                local subdata = data[subname]
                file:write(string.format(
                    ',\n                %s=%q',
                    subname, subdata
                ))
            end
            file:write("},\n")        -- Close item definition
        end
        file:write("    },\n") -- Close mod table
        --coroutine.yield("Saved " .. mod)
    end
    file:write("}\nreturn itemTable") -- Close the Lua table
    file:close()

    coroutine.yield("Item table saved to " .. outputPath, gutil.vibes.happy)
    fs.rename(outputPath, "/ITTestDone.lua")
end

function main()
    --print("start")
    local newTable = makeNewTable(itemTable)
    coroutine.yield("tableMade", gutil.vibes.happy)
    newTable = stripBadEntries(newTable)
    coroutine.yield("bad stripped", gutil.vibes.happy)
    iTable = updateIT(newTable, itemTable)
    coroutine.yield("ITable updated", gutil.vibes.happy)
    saveItemTable(iTable, "./ItTest.lua")
    coroutine.yield("DONE", gutil.vibes.happy)
end
--coco = coroutine.create(main)
--function dod()
 --   while true do
--        print(coroutine.resume(coco))
--        os.sleep(.01)
--    end
--end
return main