local gstring = {}

gstring.version = 1.0

function gstring.removeQuotes(str)
    return str:match("^['\"](.*)['\"]$") or str
end

function gstring.extractLastSegDot(str)
    return str:match(".+%.(.+)") or str
end

function gstring.cutoutString(str, startIndex, endIndex)
    if not endIndex or endIndex < startIndex then
        return str
    end
    return str:sub(1, startIndex - 1) .. str:sub(endIndex + 1)
end

function gstring.stripIgnoreCase(str, pattern, fromStart, stripPre)
    local lowerStr = str:lower()
    local lowerPat = pattern:lower()
    if stripPre then
        lowerPat = ".*" .. lowerPat
    end
    if fromStart then
        lowerPat = "^" .. lowerPat
    end
    local firstIndex, lastIndex = str.find(lowerStr, lowerPat)

    return gstring.cutoutString(str, firstIndex, lastIndex)
end

function gstring.snakeToCamel(str)
    return str:gsub("_([%a])", function(match) return match:upper() end)
end
function gstring.shorten(str, len)
    if #str <= len then return str end
    local partLen = (len - 3) / 2
    return str:sub(1, math.ceil(partLen)) .. "..." .. str:sub(-math.floor(partLen))
end

function gstring.toLength(str, length, center)
    local strlen = #str
    length = math.floor(length)
    if strlen > length then
        return gstring.shorten(str, length)
    end
    if not (center == true or center == "center") then
        return str .. (" "):rep(length - strlen)
    else
        local padding = length - strlen
        local leftPad = (padding) // 2
        return (" "):rep(leftPad) .. str .. (" "):rep(padding - leftPad)
    end
end
return gstring