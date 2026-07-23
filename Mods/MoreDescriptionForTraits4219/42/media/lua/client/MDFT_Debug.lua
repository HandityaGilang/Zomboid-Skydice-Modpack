function MDFT_PrintTable(tbl, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    
    if type(tbl) ~= "table" then
        print(prefix .. tostring(tbl))
        return
    end
    
    for key, value in pairs(tbl) do
        local keyStr = tostring(key)
        if type(value) == "table" then
            print(prefix .. keyStr .. " => {")
            MDFT_PrintTable(value, indent + 1)
            print(prefix .. "}")
        else
            print(prefix .. keyStr .. " => " .. tostring(value))
        end
    end
end


function MDFT_PrintTable2(tbl)
    for k, v in pairs(tbl) do
        print(tostring(k) .. " => " .. tostring(v))
    end
end

