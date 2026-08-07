local Sorter = {
    condition = {
        [1] = function (a, b) return a:getCondition() > b:getCondition() end,
        [2] = function (a, b) return a:getCondition() < b:getCondition() end
    },
    uses = {
        [1] = function (a, b) return a:getCurrentUses() > b:getCurrentUses() end,
        [2] = function (a, b) return a:getCurrentUses() < b:getCurrentUses() end
    },
    ammo = {
        [1] = function (a, b) return a:getCurrentAmmoCount() > b:getCurrentAmmoCount() end,
        [2] = function (a, b) return a:getCurrentAmmoCount() < b:getCurrentAmmoCount() end
    },
    attachments = {
        [1] = function (a, b) return (a:getAllWeaponParts():size() + (a:isContainsClip() and 1 or 0)) > (b:getAllWeaponParts():size() + (b:isContainsClip() and 1 or 0)) end,
        [2] = function (a, b) return (a:getAllWeaponParts():size() + (a:isContainsClip() and 1 or 0)) < (b:getAllWeaponParts():size() + (b:isContainsClip() and 1 or 0)) end
    },
    hunger = {
        [1] = function (a, b) return a:getHungerChange() < b:getHungerChange() end,
        [2] = function (a, b) return a:getHungerChange() > b:getHungerChange() end
    },
    fluid = {
        [1] = function (a, b) return (a:getFluidContainer() or a:getWorldItem():getFluidContainer()):getAmount() > (b:getFluidContainer() or b:getWorldItem():getFluidContainer()):getAmount() end,
        [2] = function (a, b) return (a:getFluidContainer() or a:getWorldItem():getFluidContainer()):getAmount() < (b:getFluidContainer() or b:getWorldItem():getFluidContainer()):getAmount() end
    },
    clothes = {
        [1] = function (a, b) return a:getCondition() == b:getCondition() and a:getHolesNumber() > b:getHolesNumber() or a:getCondition() > b:getCondition() end,
        [2] = function (a, b) return a:getCondition() == b:getCondition() and a:getHolesNumber() < b:getHolesNumber() or a:getCondition() < b:getCondition() end
    },
    tools = {
        [1] =
        function (a, b)
            if a:getCondition() == b:getCondition() then
                if a:hasHeadCondition() and a:getHeadCondition() ~= b:getHeadCondition() then return a:getHeadCondition() > b:getHeadCondition() end
                if a:hasSharpness() and a:getSharpness() ~= b:getSharpness() then return a:getSharpness() > b:getSharpness() end
                return false
            end
            return a:getCondition() > b:getCondition()
        end,
        [2] =
        function (a, b)
            if a:getCondition() == b:getCondition() then
                if a:hasHeadCondition() and a:getHeadCondition() ~= b:getHeadCondition() then return a:getHeadCondition() < b:getHeadCondition() end
                if a:hasSharpness() and a:getSharpness() ~= b:getSharpness() then return a:getSharpness() < b:getSharpness() end
                return false
            end
            return a:getCondition() < b:getCondition()
        end
    },
    weapon = {
        [1] =
        function (a, b)
            if a:getCondition() == b:getCondition() then
                if a:getMaxAmmo() > 0 then
                    if (a:getCurrentAmmoCount() + (a:isRoundChambered() and 1 or 0)) == (b:getCurrentAmmoCount() + (b:isRoundChambered() and 1 or 0)) then
                        return (a:getAllWeaponParts():size() + (a:isContainsClip() and 1 or 0)) > (b:getAllWeaponParts():size() + (b:isContainsClip() and 1 or 0))
                    else
                        return (a:getCurrentAmmoCount() + (a:isRoundChambered() and 1 or 0)) > (b:getCurrentAmmoCount() + (b:isRoundChambered() and 1 or 0))
                    end
                else
                    if a:hasHeadCondition() and a:getHeadCondition() ~= b:getHeadCondition() then return a:getHeadCondition() > b:getHeadCondition() end
                    if a:hasSharpness() and a:getSharpness() ~= b:getSharpness() then return a:getSharpness() > b:getSharpness() end
                    return false
                end
            else
                return a:getCondition() > b:getCondition()
            end
        end,
        [2] =
        function (a, b)
            if a:getCondition() == b:getCondition() then
                if a:getMaxAmmo() > 0 then
                    if (a:getCurrentAmmoCount() + (a:isRoundChambered() and 1 or 0)) == (b:getCurrentAmmoCount() + (b:isRoundChambered() and 1 or 0)) then
                        return (a:getAllWeaponParts():size() + (a:isContainsClip() and 1 or 0)) < (b:getAllWeaponParts():size() + (b:isContainsClip() and 1 or 0))
                    else
                        return (a:getCurrentAmmoCount() + (a:isRoundChambered() and 1 or 0)) < (b:getCurrentAmmoCount() + (b:isRoundChambered() and 1 or 0))
                    end
                else
                    if a:hasHeadCondition() and a:getHeadCondition() ~= b:getHeadCondition() then return a:getHeadCondition() < b:getHeadCondition() end
                    if a:hasSharpness() and a:getSharpness() ~= b:getSharpness() then return a:getSharpness() < b:getSharpness() end
                    return false
                end
            else
                return a:getCondition() < b:getCondition()
            end
        end
    },
}

return Sorter