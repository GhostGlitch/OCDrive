local b32 = {}
function b32.band(a, b)
    return a & b
end
function b32.rshift(a, b)
    return a >> b
end
return b32