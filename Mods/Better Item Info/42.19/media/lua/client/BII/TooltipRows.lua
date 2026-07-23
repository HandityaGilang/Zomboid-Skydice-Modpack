-- Backwards-compatible facade retained for older local test snippets.
local Providers = {
    require("BII/Providers/Food"),
    require("BII/Providers/Liquid"),
    require("BII/Providers/Weapon"),
    require("BII/Providers/Seed"),
    require("BII/Providers/Metal"),
    require("BII/Providers/Fuel"),
    require("BII/Providers/Electronics"),
    require("BII/Providers/Book"),
    require("BII/Providers/Remaining"),
}

local BII = _G.BII or {}
_G.BII = BII

function BII.getTooltipRows(item, ctx)
    if not item then return nil end

    local rows = {}
    ctx = ctx or { item = item }
    for _, provider in ipairs(Providers) do
        local providerRows = provider:getRows(ctx)
        if providerRows then
            for _, row in ipairs(providerRows) do
                table.insert(rows, row)
            end
        end
    end

    if #rows > 0 then return rows end
    return nil
end

return BII
