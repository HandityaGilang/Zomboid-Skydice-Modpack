
WPUtils = WPUtils or {}

WPUtils.Coords2Id = function(x, y, z)
    local id = x .. "-" .. y .. "-" .. z
    return id
end

WPUtils.Id2Coords = function(inputstr)

    local t = {}
    for str in string.gmatch(inputstr, "([^-]+)") do
        table.insert(t, str)
    end
    return tonumber(t[1]), tonumber(t[2]), tonumber(t[3])
end

WPUtils.GetTextColor = function(v)
    if v <= 10 then
        return " <RGB:1,0,0> "
    elseif v <= 50 then
        return " <RGB:1,1,0> "
    else
        return " <RGB:0,1,0> "
    end
end

WPUtils.SplitIntToParts = function(num, parts)
  
    local ret = {}
    local rem = num % parts
    local div = (num - rem) / parts

    for i=1, parts do
        if i > parts - rem then
            table.insert(ret, div+1)
        else
            table.insert(ret, div)  
        end
    end
    return ret
end