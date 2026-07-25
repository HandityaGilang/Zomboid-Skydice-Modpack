ZScienceSkill = ZScienceSkill or {}
local logger = zdk.Logger.new("ZScienceSkill")

-- called from ZScienceSkill_printable_skillbooks.txt
function ZScienceSkill.OnTestPrintableSkillBooks()
    return ZScienceSkill.printableSkillBookRecipesReady
end

local function findItems(...)
    local items = {}
    for i = 1, select("#", ...) do
        local itemType = select(i, ...)
        if getItem(itemType) then
            items[#items + 1] = itemType
        end
    end
    return items
end

local function initPrintableSkillBooks()
    local printers  = findItems("MyComputer.ABHPrinter",         "SupportCorps.ABHPrinter")
    local computers = findItems("MyComputer.ABHPonderPadLaptop", "SupportCorps.ABHPonderPadLaptop")

    logger:info("Found %d printers and %d computers: %s; %s", #printers, #computers, printers, computers)
    if #printers == 0 or #computers == 0 then
        logger:warn("No compatible printers or computers found, printable skill books will not be available.")
        ZScienceSkill.printableSkillBookRecipesReady = false
        return
    end

    local nOK = 0
    for i = 1, 5 do
        local recipe_id = "ZScienceSkill.PrintScience" .. i
        local recipe = ScriptManager.instance:getCraftRecipe(recipe_id)
        if not recipe then return logger:error("recipe '%s' not found", recipe_id) end

        local addInputs = "{ inputs {\n" ..
            "  item 1 [" .. table.concat(printers,  ";") .. "] mode:keep,\n" ..
            "  item 1 [" .. table.concat(computers, ";") .. "] mode:keep,\n" ..
            "} }"

        logger:debug("Loading recipe '%s' with additional inputs:\n%s", recipe_id, addInputs)
        recipe:Load(recipe:getName(), addInputs)
        if recipe:getInputCount() == 4 then
            nOK = nOK + 1
        end
    end
    ZScienceSkill.printableSkillBookRecipesReady = (nOK == 5)
end

Events.OnGameBoot.Add(initPrintableSkillBooks)
