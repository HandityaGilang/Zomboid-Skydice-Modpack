local function replaceLiteral(text, token, replacement)
    local startAt = 1

    while true do
        local first, last = string.find(text, token, startAt, true)
        if not first then break; end
        text = string.sub(text, 1, first - 1) .. replacement .. string.sub(text, last + 1)
        startAt = first + string.len(replacement)
    end

    return text
end

function LSKFormatLocaleString(text, ...)
    local formatted = tostring(text or "")
    local args = {...}

    for index = 1, #args do
        formatted = replaceLiteral(formatted, "%" .. tostring(index), tostring(args[index]))
    end

    return formatted
end

function LSKFormatText(key, ...)
    return LSKFormatLocaleString(getText(key), ...)
end
