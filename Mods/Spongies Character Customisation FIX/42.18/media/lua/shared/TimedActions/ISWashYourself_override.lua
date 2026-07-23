
function ISWashYourself:complete()
    local visual = self.character:getHumanVisual()
    local waterUsed = 0

    for i = 1, BloodBodyPartType.MAX:index() do
        local part = BloodBodyPartType.FromIndex(i - 1)

        if self:washPart(visual, part) then
            waterUsed = waterUsed + 1

            -- Using soap provides a modest happiness boost.
            if self.soaps then
                self.character:getStats():remove(CharacterStat.UNHAPPINESS, 2)
            end

            if waterUsed >= self.sink:getFluidAmount() then
                break
            end
        end
    end

    if SandboxVars.SPNCharCustom.WashMakeup then
        self:removeAllMakeup()
    end

    sendHumanVisual(self.character)

    if instanceof(self.sink, "IsoWorldInventoryObject") then
        self.sink:useFluid(waterUsed)
    else
        if self.sink:useFluid(waterUsed) > 0 then
            self.sink:transmitModData()
        end
    end

    local FaceManager_Shared = require("CharacterCustomisation/FaceManager_Shared")
    local bodyVisualSnapshot = FaceManager_Shared.BuildBloodAndDirtSnapshot(visual)

    if not isClient() and not isServer() then
        local FaceManager_Local = require("CharacterCustomisation/FaceManager_Local")
        FaceManager_Local.SyncBlood(self.character, bodyVisualSnapshot)
    elseif isClient() then
        sendClientCommand(self.character, "SPNCC", "SyncBlood", {
            bodyVisual = bodyVisualSnapshot,
        })
    else
        local FaceManager_Server = require("CharacterCustomisation/FaceManager_Server")
        FaceManager_Server.SyncBlood(self.character, bodyVisualSnapshot)
    end

    return true
end

-- function ISWashYourself:perform()
-- 	self:stopSound()
-- 	self.character:resetModelNextFrame();
-- 	triggerEvent("OnClothingUpdated", self.character)
-- 	-- needed to remove from queue / start next.
-- 	ISBaseTimedAction.perform(self);
-- end

