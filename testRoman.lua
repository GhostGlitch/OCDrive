local RomanArabic = {
    I = 1,
    V = 5,
    X = 10,
    L = 50,
    C = 100,
    D = 500,
    M = 1000,
}

local function fromRoman(str)
    if str == nil then error("NIHILO") end
    str = str:upper()
    if str == "" or str == "NULLA" or str == "NIHILO" then return 0 end
    if str == "INFINITUM" then return math.huge end
    local result = 0
    local i = 1
    while i <= str:len() do
    --for i = 1, s:len() do
        local char = str:sub(i, i)
        if char ~= " " then -- allow spaces
            local num = RomanArabic[char] or error("IGNOTUS NUMERUS: '" .. char .. "'")

            local next = str:sub(i + 1, i + 1)
            local nextNum = RomanArabic[next]

            if next and nextNum then
                if nextNum > num then
                -- This is used instead of programming in IV = 4, IX = 9, etc, because it is
                -- more flexible and possibly more efficient
                    result = result + (nextNum - num)
                    i = i + 1
                else
                    result = result + num
                end
            else
                result = result + num
            end
        end
        i = i + 1
    end
    return result
end

--roman numerals possible based on order (placement in number - units, tens, hundreds)
local RNumsOrder = { { "I", "V", "X" }, { "X", "L", "C" }, { "C", "D", "M" }}

local function toRoman(str)
    if str==nil then error("NIHILO") end
    str = tonumber(str)
    if not str or str ~= str then error("MALUS NUMERUS") end
    if str == math.huge then return "INFINITUM" end
    if str > 1000000 then error("INGENS NUMERUS") end
    str = math.floor(str)
    if str < 0 then error("NUMERUS NEGATIVUS") end
    if str == 0 then return "NULLA" end
    str = tostring(str)
    local result = ""
    local strLen = string.len(str)
    for i = 1, strLen do
        local letterPos = strLen - i + 1
        local letter = string.sub(str, letterPos, letterPos)
        local digit = tonumber(letter)
        local resPrefix = ""

        local symbolReps = 0           --num of times symbol has repeated (must not be > 3)
        local substSymbol = 1          --symbol to substitute with (from roman_nums_order table)
        local substSymbolInc = 1 --can be 1 or 2, depending if we are before 5 or after 5 (e.g. if we need to use V or X)
        if i >= 4 then --special case for thousands
            local thousands = tonumber(str:sub(1, strLen - i + 1))
            resPrefix = string.rep("M", thousands)
            result = resPrefix .. result
            break
        end
        local j = 1
        while j <= digit do
            resPrefix = resPrefix .. RNumsOrder[i][substSymbol]
            symbolReps = symbolReps + 1
            if symbolReps > 3 then
                resPrefix = RNumsOrder[i][substSymbol]
                substSymbol = substSymbol + substSymbolInc
                resPrefix = resPrefix .. RNumsOrder[i][substSymbol]
                symbolReps = 0
                --check if next digit exists in advance  -> to remove substraction possibility
                if j + 1 <= digit then
                    resPrefix = RNumsOrder[i][substSymbol]
                    j = j + 1                                        --go to next numeral ( e.g. IV -> V )
                    substSymbol = substSymbol - substSymbolInc --go back to small units
                    substSymbolInc = substSymbolInc + 1
                end
            end
            j = j + 1
        end
        result = resPrefix .. result
        end
    return result
end


local function test()
    for i = 0, 100000 do
        local rn = toRoman(i)
        local n = fromRoman(rn)
        assert(n == i, "RNToNumber Fail: " .. n .. " != " .. i)
        if i % 10000 == 0 then
            os.sleep(0)
        end
    end
    local rn = toRoman(math.huge)
    assert(rn == "INFINITUM", "RNToNumber Fail: " .. rn .. " != INFINITUM")
    local n = fromRoman(rn)
    assert(n == math.huge, "RNToNumber Fail: " .. n .. " != math.huge")
    local function assertError(func, input, expectedError)
        local status, err = pcall(func, input)
        assert(not status and err:find(expectedError), "Expected error: " .. expectedError .. ", but got: " .. (err or "no error"))
    end

    -- Test fromRoman errors
    assertError(fromRoman, nil, "NIHILO")
    assertError(fromRoman, "INVALID", "IGNOTUS NUMERUS")

    -- Test toRoman errors
    assertError(toRoman, nil, "NIHILO")
    assertError(toRoman, "not a number", "MALUS NUMERUS")
    assertError(toRoman, -1, "NUMERUS NEGATIVUS")
    assertError(toRoman, 1000001, "INGENS NUMERUS")
    print("Test passed")

end
test()