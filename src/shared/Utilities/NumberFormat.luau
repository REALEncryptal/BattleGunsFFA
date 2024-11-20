return function (n)
    local Suffixes = {
        {1000000000000000000, "Q"},
        {1000000000000000, "q"},
        {1000000000000, "t"},
        {1000000000, "b"},
        {1000000, "m"},
        {1000, "k"}
    }

    if n < 1000 then return tostring(n) end
    for _, Suffix in ipairs(Suffixes) do
        if n >= Suffix[1] then
            return string.format("%.2f", n / Suffix[1]) .. Suffix[2]
        end
    end
end