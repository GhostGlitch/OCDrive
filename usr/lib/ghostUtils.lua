--parseCSV from libcsv by Fingercomp: https://github.com/OpenPrograms/Fingercomp-Programs/tree/master/libcsv

local ev = require("event")
local ser = require("serialization")
local fs = require("filesystem")
local comp = require("component")
local term = require("term")
local gutil = {}

gutil.version = 1.4
function gutil.parseCSV(s)
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

function gutil.sortKeys(list)
    local keys = {}
    for k in pairs(list) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end


function gutil.waitForAny(useMessage)
    -- If printMessage is nil or true, it will print the message
    if useMessage ~= false then
        print("\n--- Press any key to continue ---\n")
    end
    ev.pull("key_down")
end

function gutil.compareTables(table1, table2)
    -- Check if both have the same keys and values
    if ser.serialize(table1) ~= ser.serialize(table2) then
        return false
    end
    return true
end

function gutil.cloneTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[gutil.cloneTable(orig_key)] = gutil.cloneTable(orig_value)
        end
        setmetatable(copy, gutil.cloneTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function gutil.mergeTables(table1, table2)
    local merged = gutil.cloneTable(table1)
    for key, value in pairs(table2) do
        merged[key] = value
    end
    return merged
end

function gutil.strToFile(filePath, str)
    local file, err = fs.open(filePath, "w")
    if err then error("Error: unable to open file " .. filePath .. " Reason: " .. err) end
    file:write(str)
    file:close()
end

function gutil.parseCfgVal(content, key)
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

function gutil.readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local content = file:read("*all") -- Read the entire file content
    file:close()
    return content
end

function gutil.colorPrint(message, color)
    local previous = comp.gpu.setForeground(color)
    print(message)
    comp.gpu.setForeground(previous)
end

function gutil.angryPrint(message)
    gutil.colorPrint(message, 0xFF0000)
end

function gutil.happyPrint(message)
    gutil.colorPrint(message, 0x00FF00)
end

function gutil.uneasyPrint(message)
    gutil.colorPrint(message, 0xFFFF00)
end

function gutil.isNative()
    return not comp.isAvailable("ocemu")
end

function gutil.checkGVer(lib, minVer, caller, libname)
    print(lib)
    if lib.version == nil or lib.version < minVer then
        gutil.angryPrint("Error: " .. caller .. " requires at least version " .. minVer .. " of " .. libname)
        return false
    end
    return true
end

function gutil.open(path, mode)
    path = path:gsub("|", "_")
    local file, err = io.open(path, mode)
    if not file then
        error("Error: unable to open file " .. path .. " Reason: " .. err)
    end
    return file
end

function gutil.writeColor(str, color, wrap)
  local oldColor = comp.gpu.setForeground(color)
  term.write(str, wrap)
  return oldColor
end

return gutil