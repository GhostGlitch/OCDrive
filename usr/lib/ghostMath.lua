local gmath = {}

function gmath.gcd(a, b)
    while b ~= 0 do
        a, b = b, a % b
    end
    return a
end

function gmath.simplifyRat(a, b)
    local divi = gmath.gcd(a, b)
    return a / divi, b / divi
end

function gmath.percToMCHex(percent)
    -- Scale the percentage to the 0-15 range
    return math.floor(percent *16/101)
end

return gmath