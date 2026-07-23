DCS_Identity = DCS_Identity or {}

function DCS_Identity.displayName(player)
    if not player then return "Unknown" end
    if not (DCS_Env and DCS_Env.isSP()) then
        local username = player:getUsername()
        if username and username ~= "" then return username end
    end
    local desc = player:getDescriptor()
    local first = (desc and desc:getForename()) or "Unknown"
    local last = (desc and desc:getSurname()) or ""
    return (last ~= "") and (first .. " " .. last) or first
end

return DCS_Identity
