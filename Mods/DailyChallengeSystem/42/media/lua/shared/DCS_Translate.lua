DCS_Translate = {}

function DCS_Translate.get(key, ...)
    local result = getText(key, ...)
    if result == key then return key end
    return result
end

local function fmtCount(n)
    return tostring(n or 1) .. "x"
end

local function addCountX(title)
    title = title or ""
    local withArticle, n = title:gsub("^(%a+) a[n]? ", "%1 1x ", 1)
    if n > 0 then return withArticle end
    return (title:gsub("(%d+)", "%1x", 1))
end
DCS_Translate.addCountX = addCountX

function DCS_Translate.challengeTitle(ch)
    if not ch then return "" end
    local t = ch.type

    if t == "killZombies" then
        return DCS_Translate.get("IGUI_DCS_Challenge_Kill_Zombies", ch.target)

    elseif t == "killWithCategory" then
        local catKey = "IGUI_DCS_WeaponCategory_" .. (ch.weaponType or "")
        local catName = DCS_Translate.get(catKey, ch.weaponType or "")
        return DCS_Translate.get("IGUI_DCS_Challenge_Kill_WithCategory", ch.target, catName)

    elseif t == "killWithWeapon" then
        local weaponName = ch.weaponType or "Weapon"
        local displayName = getItemNameFromFullType("Base." .. weaponName)
        if displayName and displayName ~= "" then
            weaponName = displayName
        end
        return DCS_Translate.get("IGUI_DCS_Challenge_Kill_WithWeapon", ch.target, weaponName)

    elseif t == "eat" then
        if ch.targetFoods and #ch.targetFoods > 0 then
            local itemName = getItemNameFromFullType(ch.targetFoods[1]) or ch.targetFoods[1]
            return DCS_Translate.get("IGUI_DCS_Challenge_Eat_Item", fmtCount(ch.target), itemName)
        else
            return addCountX(ch.title)
        end

    elseif t == "drink" then
        local fluids = ch.targetFluids or (ch.targetFluid and {ch.targetFluid} or nil)
        if fluids and #fluids > 0 then
            local fluidName = ch.fluidLabel or (fluids[1]:gsub("(%l)(%u)", "%1 %2"))
            return DCS_Translate.get("IGUI_DCS_Challenge_Drink_Item", fmtCount(ch.target), fluidName)
        else
            return addCountX(ch.title)
        end

    elseif t == "fishing" then
        if ch.targetFish then
            local fishName = getItemNameFromFullType(ch.targetFish) or ch.targetFish
            return DCS_Translate.get("IGUI_DCS_Challenge_Fish_Catch", fmtCount(ch.target), fishName)
        else
            return DCS_Translate.get("IGUI_DCS_Challenge_Fish_CatchAny", ch.target)
        end

    elseif t == "hunting" then
        if ch.targetAnimal then
            local animalKey = "IGUI_DCS_Animal_" .. ch.targetAnimal
            local animalName = DCS_Translate.get(animalKey, ch.targetAnimal)
            return DCS_Translate.get("IGUI_DCS_Challenge_Hunt_Animals", fmtCount(ch.target), animalName)
        else
            return DCS_Translate.get("IGUI_DCS_Challenge_Hunt_AnyAnimals", ch.target)
        end

    elseif t == "forage" then
        if ch.targetCategory then
            local catNames = { Junk = "Junk", JunkFood = "Junk Food" }
            local catName = catNames[ch.targetCategory] or ch.targetCategory
            return DCS_Translate.get("IGUI_DCS_Challenge_Forage_Category", fmtCount(ch.target), catName)
        elseif ch.targetItem then
            local itemName = getItemNameFromFullType(ch.targetItem) or ch.targetItem
            return DCS_Translate.get("IGUI_DCS_Challenge_Forage_Item", fmtCount(ch.target), itemName)
        else
            return DCS_Translate.get("IGUI_DCS_Challenge_Forage_Items", fmtCount(ch.target))
        end

    elseif t == "craft" or t == "build" then
        return addCountX(ch.title)

    elseif t == "visitLocation" then
        local barney = "Barney the Gnome"
        if ch.title then
            local found = ch.title:match("^Find (.+) at ")
            if found then barney = found end
        end
        return DCS_Translate.get("IGUI_DCS_Challenge_Visit_Find", barney, ch.locName or "")

    elseif t == "questDeliver" then
        return DCS_Translate.get("IGUI_DCS_Challenge_Quest_Deposit", addCountX(ch.itemName or ""), ch.destName or "")
    end

    return ch.title or ch.id or ""
end

return DCS_Translate
