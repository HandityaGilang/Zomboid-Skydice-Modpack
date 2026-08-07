require('AutoTailoring_Shared')


local genuine_ISRepairClothing_stop = ISRepairClothing.stop;
function ISRepairClothing:stop()
    if AutoTailoring.OPTIONS.Verbose then print ("Debug ISRepairClothing:stop call."); end
    genuine_ISRepairClothing_stop(self);
    if AutoTailoring.actionStarted then
        if AutoTailoring.OPTIONS.Verbose then print ("ISRemovePatch:stop calls AutoTailoring_sto"); end
        AutoTailoring_stop();
    end
end


local genuine_ISRepairClothing_perform = ISRepairClothing.perform;
function ISRepairClothing:perform()
    if AutoTailoring.OPTIONS.Verbose then print ("Debug ISRepairClothing:perform call."); end
    local returnVal = genuine_ISRepairClothing_perform(self);
    if AutoTailoring.actionStarted and isClient() then--let's do it after to ensure the patch is applied in MP
        ISGarmentUI.autoSewing(self.character, self.clothing, self.part)
        if AutoTailoring.OPTIONS.Verbose then print ("ISRepairClothing:perform calls ISGarmentUI.autoSewing"); end
    end
    return returnVal
end

local genuine_ISRepairClothing_complete = ISRepairClothing.complete;
function ISRepairClothing:complete()
    if AutoTailoring.OPTIONS.Verbose then print ("Debug ISRepairClothing:complete call."); end
    local returnVal = genuine_ISRepairClothing_complete(self);
    if AutoTailoring.actionStarted then--let's do it after to ensure the patch is applied in solo
        ISGarmentUI.autoSewing(self.character, self.clothing, self.part)
        if AutoTailoring.OPTIONS.Verbose then print ("ISRepairClothing:complete calls ISGarmentUI.autoSewing"); end
    end
    return returnVal
end

local genuine_ISRemovePatch_stop = ISRemovePatch.stop;
function ISRemovePatch:stop()
    if AutoTailoring.OPTIONS.Verbose then print ("Debug ISRemovePatch:stop stuff "..tostring(self.clothing)..' '..tostring(self.part)); end
    if AutoTailoring.OPTIONS.Verbose and self.clothing and self.part then print ("Debug ISRemovePatch:stop type "..tostring(self.clothing:getPatchType(self.part))); end
    genuine_ISRemovePatch_stop(self);
    if AutoTailoring.actionStarted then
        if AutoTailoring.OPTIONS.Verbose then print ("ISRemovePatch:stop calls AutoTailoring_sto"); end
        AutoTailoring_stop();
    end
end

--temporary bug patch remove the removal from complete. it is also in perform
local genuine_ISRemovePatch_perform = ISRemovePatch.perform;
function ISRemovePatch:perform()
    if AutoTailoring.OPTIONS.Verbose then print ("Debug ISRemovePatch:perform stuff "..tostring(self.clothing)..' '..tostring(self.part)); end
    self.lastPatch = self.clothing:getPatchType(self.part);
    genuine_ISRemovePatch_perform(self);
    
    ---my own auto stuff:
    if AutoTailoring.actionStarted and isClient() then--let's do it after to ensure the patch is removed and maybe reuse the patch in MP
        ISGarmentUI.autoSewing(self.character, self.clothing, self.part)
        if AutoTailoring.OPTIONS.Verbose then print ("ISRemovePatch:perform calls ISGarmentUI.autoSewing"); end
    end
end



local genuine_ISRemovePatch_complete = ISRemovePatch.complete;
function ISRemovePatch:complete()
    if AutoTailoring.OPTIONS.Verbose then print ("Debug ISRemovePatch:complete stuff "..tostring(self.clothing)..' '..tostring(self.part)); end
    if AutoTailoring.OPTIONS.Verbose and self.clothing and self.part then print ("Debug ISRemovePatch:complete type "..tostring(self.clothing:getPatchType(self.part))); end

    local completed = genuine_ISRemovePatch_complete(self)
    
    ---my own auto stuff:
    if AutoTailoring.actionStarted then--let's do it after to ensure the patch is removed and maybe reuse the patch in solo
        ISGarmentUI.autoSewing(self.character, self.clothing, self.part)
        if AutoTailoring.OPTIONS.Verbose then print ("ISRemovePatch:complete calls ISGarmentUI.autoSewing"); end
    end

    return true;
end

