--parseCSV from libcsv by Fingercomp: https://github.com/OpenPrograms/Fingercomp-Programs/tree/master/libcsv

local ev = require("event")
local ser = require("serialization")
local fs = require("filesystem")
local comp = require("component")
local csv = require("libcsv")
local utils = {}

utils.version = 1.1
function utils.parseCSV(s)
    local result = {}
    local row = {}
    local cell = ""
    local quoted = false
    local prevQuote = false

    for i = 1, #s, 1 do
      local c = s:sub(i, i)
      if quoted then
        if c == '"' then
          prevQuote = true
          quoted = false
        else
          cell = cell .. c
        end
      else
        if c == '"' then
          if #cell == 0 then
            quoted = true
          else
            if prevQuote then
              cell = cell .. '"'
              quoted = true
              prevQuote = false
            else
              return false
            end
          end
        elseif c == "," then
          table.insert(row, cell)
          cell = ""
          prevQuote = false
        elseif c == "\n" then
          table.insert(row, cell)
          cell = ""
          table.insert(result, row)
          row = {}
          prevQuote = false
        else
          if prevQuote then
            return false
          end
          cell = cell .. c
        end
      end
    end

    if #cell ~= 0 then
      if quoted then
        return false
      end
      table.insert(row, cell)
      table.insert(result, row)
    end

    return result
end

function utils.sortKeys(list)
    local keys = {}
    for k in pairs(list) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end


function utils.waitForAny(useMessage)
    -- If printMessage is nil or true, it will print the message
    if useMessage ~= false then
        print("\n--- Press any key to continue ---\n")
    end
    ev.pull("key_down")
end

function utils.compareTables(table1, table2)
    -- Check if both have the same keys and values
    if ser.serialize(table1) ~= ser.serialize(table2) then
        return false
    end
    return true
end

function utils.cloneTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utils.cloneTable(orig_key)] = utils.cloneTable(orig_value)
        end
        setmetatable(copy, utils.cloneTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function utils.mergeTables(table1, table2)
    local merged = utils.cloneTable(table1)
    for key, value in pairs(table2) do
        merged[key] = value
    end
    return merged
end

function utils.strToFile(filePath, str)
    local file = fs.open(filePath, "w")
    file:write(str)
    file:close()
end

function utils.removeQuotes(str)
    return str:match("^['\"](.*)['\"]$") or str
end

function utils.parseCfgVal(content, key)
    -- get a substring begining with a newline character, and containing "key=" with any number of spaces in it, and ending with a newline.
    local rawLine = content:match("\n(%s*" .. key .. "%s*=[^\n]+)") or ""
    --remove all commas and whitespace including newlines.
    local line = string.gsub(rawLine, "[,%s]", "")
    -- get any characters after the "="
    local raw = line:match("=(.+)")
    -- try and read this as a number.
    local num = tonumber(raw)
    return num, raw, line
end

function utils.extractLastSegDot(str)
    return str:match(".+%.(.+)") or str
end

function utils.cutoutString(str, startIndex, endIndex)
    if not endIndex or endIndex < startIndex then
        return str
    end
    return str:sub(1, startIndex - 1) .. str:sub(endIndex + 1)
end

function utils.stripIgnoreCase(str, pattern, fromStart, stripPre)
    local lowerStr = str:lower()
    local lowerPat = pattern:lower()
    if stripPre then
        lowerPat = ".*" .. lowerPat
    end
    if fromStart then
        lowerPat = "^" .. lowerPat
    end
    local firstIndex, lastIndex = str.find(lowerStr, lowerPat)

    return utils.cutoutString(str, firstIndex, lastIndex)
end

function utils.readFile(path)
    local file = io.open(path, "r")
    local content = file:read("*all") -- Read the entire file content
    file:close()
    return content
end

function utils.colorPrint(message, color)
    local previous = comp.gpu.setForeground(color)
    print(message)
    comp.gpu.setForeground(previous)
end

function utils.angryPrint(message)
    utils.colorPrint(message, 0xFF0000)
end

function utils.happyPrint(message)
    utils.colorPrint(message, 0x00FF00)
end

function utils.uneasyPrint(message)
    utils.colorPrint(message, 0xFFFF00)
end


return utils