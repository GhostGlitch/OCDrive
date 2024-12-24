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

    return str.cutoutString(str, firstIndex, lastIndex)
end

return gstring