--parseCSV from libcsv by Fingercomp: https://github.com/OpenPrograms/Fingercomp-Programs/tree/master/libcsv

local ev = require("event")
local ser = require("serialization")
local fs = require("filesystem")
local comp = require("component")
local term = require("term")
local unicode = require("unicode")
local gutil = {}

gutil.version = 1.6
gutil.vibes = {
    angry = 0xFF0000,
    happy = 0x00FF00,
    uneasy = 0xFFFF00
}
gutil.gpuX, gutil.gpuY = comp.gpu.getResolution()

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

function gutil.open(path, mode)
  local file, err = io.open(path, mode)
  if err or not file then
      error("Error: unable to open file " .. path .. " Reason: " .. err)
  end
  return file
end

function gutil.strToFile(path, str)
    local file = gutil.open(path, "w")
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

function gutil.colorPrint(color, ...)
    local previous = comp.gpu.setForeground(color)
    print(...)
    comp.gpu.setForeground(previous)
end

function gutil.angryPrint(...)
    gutil.colorPrint(gutil.vibes.angry, ...)
end

function gutil.happyPrint(...)
    gutil.colorPrint(gutil.vibes.happy, ...)
end

function gutil.uneasyPrint(...)
    gutil.colorPrint(gutil.vibes.uneasy, ...)
end


function gutil.printIf(bool, ...)
  if bool then
    print(...)
  end
end

function gutil.colorPrintIf(bool, color, ...)
    if bool then
        gutil.colorPrint(color, ...)
    end
end

function gutil.angryPrintIf(bool, ...)
    gutil.colorPrintIf(bool, gutil.vibes.angry, ...)
end

function gutil.happyPrintIf(bool, ...)
    gutil.colorPrintIf(bool, gutil.vibes.happy, ...)
end

function gutil.uneasyPrintIf(bool, ...)
    gutil.colorPrintIf(bool, gutil.vibes.uneasy, ...)
end

function gutil.isNative()
    return not comp.isAvailable("ocemu")
end

function gutil.checkGVer(lib, minVer, caller, libname)
    if lib.version == nil or lib.version < minVer then
        gutil.angryPrint("Error: " .. caller .. " requires at least version " .. minVer .. " of " .. libname)
        return false
    end
    return true
end
function gutil.replaceLineAtPos(x, y, str)
  term.setCursor(x, y)
  term.clearLine()
  comp.gpu.set(x,y,str)
end
function gutil.printBox(x, y, ...)
  local oldBlink = term.getCursorBlink()
  term.setCursorBlink(false)
  local oldCurX, oldCurY = term.getCursor()


  --term.setCursor(x, y)
  local width = 0
  local args = { ... }
  local height = #args
  local lines = {}
  for i = 1, #args do
      local arg = args[i]
      if arg == nil then arg = "nil" end
      width = math.max(#arg + 1, width)
      table.insert(lines, arg)
  end
  local bordersDef = { { unicode.char(0x2552), unicode.char(0x2550), unicode.char(0x2555) },
      { unicode.char(0x2502), nil,                  unicode.char(0x2502) },
      { unicode.char(0x2514), unicode.char(0x2500), unicode.char(0x2518) } }
  local borders = bordersDef
    if x < 2 then
        borders[1][1] = ""
        borders[2][1] = ""
        borders[3][1] = ""
        x = x + 1
    end
    x=x-1
  if y > 1 then
      local lowestBottom = 1
      if y + height <= gutil.gpuY then
          for i = y + height, 1, -1 do
              char = comp.gpu.get(x + 2, i)
              if char == borders[3][2] then
                  lowestBottom = i
                  local dif = y + height - lowestBottom
                  local tx, ty = term.getCursor()
                    comp.gpu.copy(1, lowestBottom + 1, 200, dif, 0, -height - 2)
                  if ty >= lowestBottom +1 and ty <= lowestBottom+1+dif then
                    comp.gpu.set(tx,ty-height-2, " ")
                  end
                  break
              end
          end
      end
      gutil.replaceLineAtPos(x, y - 1, borders[1][1].. string.rep(borders[1][2], width).. borders[1][3])
  end
  local ind = 0
  for i, line in ipairs(lines) do

        gutil.replaceLineAtPos(x, y + ind, borders[2][1] .. line .. (" "):rep(width - #line) .. borders[2][3])
        ind = ind + 1
        if y  + ind > gutil.gpuY then
          break
      end
  end
  if y+ind<=gutil.gpuY then
  gutil.replaceLineAtPos(x, y + ind, borders[3][1] .. string.rep(borders[3][2], width) .. borders[3][3])
  end
  term.setCursor(oldCurX, oldCurY)
  term.setCursorBlink(oldBlink)
end

function gutil.writeColor(str, color, wrap)
  local oldColor = comp.gpu.setForeground(color)
  term.write(str, wrap)
  return oldColor
end

return gutil