local gameNightDistro = require("gameNight-Distributions.lua")

local zombiesDropGames = {}

zombiesDropGames.distros = {["inventorymale"]="all",["inventoryfemale"]="all"}


function zombiesDropGames.distChange()

    local blackList = SandboxVars.GameNight.ZombiesDropLootWhiteBlackToggle==2
    local itemExceptionList = false
    local sandboxItemList = SandboxVars.GameNight.ZombiesDropLootList

    print("zombiesDropGames_blackList:", blackList)
    print("zombiesDropGames_",sandboxItemList)
    if sandboxItemList ~= "" then
        itemExceptionList = {}
        for itemID in string.gmatch(sandboxItemList, "([^,]+)") do itemExceptionList[itemID] = true end

        for k,v in pairs(itemExceptionList) do
            print("zombiesDropGames_"..k.."_")
        end
    end

    for distID,parentID in pairs(zombiesDropGames.distros) do
        local dist = parentID and SuburbsDistributions[parentID][distID].items or SuburbsDistributions[distID].items
        for itemID,_ in pairs(gameNightDistro.proceduralDistGameNight.itemsToAdd) do

            local valid = (not itemExceptionList)
            if itemExceptionList then
                if blackList then
                    valid = (not itemExceptionList[itemID])
                else
                    valid = itemExceptionList[itemID]
                end
            end

            if valid then
                ---make entire game boxes spawn much less
                local chance = (gameNightDistro.gameNightBoxes[itemID] and 0.01 or 0.2) * (SandboxVars.GameNight.ZombiesDropLootMultiplier or 0.01)

                table.insert(dist, itemID)
                table.insert(dist, chance)
            end
        end
    end
    ItemPickerJava.Parse()
end

return zombiesDropGames