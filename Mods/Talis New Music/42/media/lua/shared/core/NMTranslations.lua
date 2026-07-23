NMTranslations = NMTranslations or {}

local function trim(value)
    local text = tostring(value or "")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end

function NMTranslations.text(key, fallback)
    local lookupKey = tostring(key or "")
    if lookupKey ~= "" and type(getText) == "function" then
        local ok, resolved = pcall(getText, lookupKey)
        local candidate = tostring(resolved or "")
        if ok and candidate ~= "" and candidate ~= lookupKey then
            return candidate
        end
    end
    return tostring(fallback or lookupKey)
end

function NMTranslations.ui(suffix, fallback)
    return NMTranslations.text("UI_NM_" .. tostring(suffix or ""), fallback)
end

function NMTranslations.igui(suffix, fallback)
    return NMTranslations.text("IGUI_NM_" .. tostring(suffix or ""), fallback)
end

function NMTranslations.itemName(fullType, fallback)
    local ft = trim(fullType)
    if ft == "" then
        return tostring(fallback or "")
    end
    return NMTranslations.text("ItemName_" .. tostring((ft:gsub("%.", "_"))), fallback or ft)
end

-- Child-pack labels may already be translation keys; resolve those without touching literal labels.
function NMTranslations.trackLabel(label, fallback)
    local text = tostring(label or "")
    if text == "" then
        return tostring(fallback or "")
    end
    if string.sub(text, 1, 3) == "UI_" then
        return NMTranslations.text(text, fallback or text)
    end
    return text
end

function NMTranslations.numberedTrackLabel(rowOrLabel, fallback, trackNumber)
    local rawLabel = rowOrLabel
    local rawFallback = fallback
    local rawTrackNumber = trackNumber
    if type(rowOrLabel) == "table" then
        rawLabel = rowOrLabel.label or rowOrLabel.sound
        rawFallback = fallback or rowOrLabel.sound
        rawTrackNumber = rowOrLabel.trackNumber
    end

    local label = tostring(NMTranslations.trackLabel(rawLabel, rawFallback) or "")
    if label == "" then
        return label
    end

    local numericTrackNumber = tonumber(rawTrackNumber)
    if not numericTrackNumber or numericTrackNumber < 1 then
        return label
    end

    return string.format("%02d. %s", math.floor(numericTrackNumber), label)
end

return NMTranslations
