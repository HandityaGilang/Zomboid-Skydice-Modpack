require "TimedActions/ISBaseTimedAction"
require "GIPT/GIPT_Constants"
require "GIPT/GIPT_Storage"

local function setTransferAnimation(action, fluidType)
    -- Build 42.19's native Fluid transfer action uses MixFluids. Keep the
    -- established tap animation for clean water and use the vanilla generic
    -- liquid-transfer node for gasoline and propane adapter actions.
    if fluidType == GIPT.FLUID_WATER then
        action:setActionAnim("fill_container_tap")
    else
        action:setActionAnim("MixFluids")
    end
end

GIPT_FillAction=ISBaseTimedAction:derive("GIPT_FillAction")
function GIPT_FillAction:isValid()
    if not self.item or not self.item:getContainer() or not GIPT.distanceOkay(self.character,self.x,self.y,self.z) then return false end
    local obj=GIPT.resolveTankObject(self.x,self.y,self.z); local data=obj and GIPT.ensureTankData(obj)
    return data and GIPT.calculateTransfer(self.item,data)~=nil
end
function GIPT_FillAction:waitToStart() self.character:faceLocation(self.x,self.y); return self.character:shouldBeTurning() end
function GIPT_FillAction:update() self.item:setJobDelta(self:getJobDelta()); self.character:faceLocation(self.x,self.y); self.character:setMetabolicTarget(Metabolics.LightWork) end
function GIPT_FillAction:start() setTransferAnimation(self, self.fluidType); self.item:setJobType("Filling from industrial fluid station"); self.item:setJobDelta(0) end
function GIPT_FillAction:stop()
    local progress=GIPT.clamp(self:getJobDelta() or 0,0,1); if self.item then self.item:setJobDelta(0) end
    if isClient() and self.transactionID then sendClientCommand(self.character,GIPT.MODULE,"CommitFill",{transactionID=self.transactionID,progress=progress,interrupted=true})
    elseif progress>=0.01 then local partial=(tonumber(self.maxTransfer) or 0)*progress; GIPT.commitTransfer(self.character,self.x,self.y,self.z,self.item,self.installationID,partial) end
    ISBaseTimedAction.stop(self)
end
function GIPT_FillAction:perform()
    self.item:setJobDelta(0)
    if isClient() then sendClientCommand(self.character,GIPT.MODULE,"CommitFill",{transactionID=self.transactionID,progress=1}) else GIPT.commitTransfer(self.character,self.x,self.y,self.z,self.item,self.installationID,self.maxTransfer) end
    ISBaseTimedAction.perform(self)
end
function GIPT_FillAction:new(character,x,y,z,item,transactionID,installationID,maxTransfer,duration,fluidType)
    local o=ISBaseTimedAction.new(self,character); o.x,o.y,o.z,o.item=x,y,z,item; o.transactionID,o.installationID,o.maxTransfer=transactionID,installationID,maxTransfer; o.fluidType=fluidType; o.maxTime=duration or 120; o.stopOnWalk,o.stopOnRun=true,true; return o
end

GIPT_DepositAction=ISBaseTimedAction:derive("GIPT_DepositAction")
function GIPT_DepositAction:isValid()
    if not self.item or not self.item:getContainer() or not GIPT.distanceOkay(self.character,self.x,self.y,self.z) then return false end
    local obj=GIPT.resolveTankObject(self.x,self.y,self.z); local data=obj and GIPT.ensureTankData(obj)
    return data and GIPT.calculateDeposit(self.item,data)~=nil
end
function GIPT_DepositAction:waitToStart() self.character:faceLocation(self.x,self.y); return self.character:shouldBeTurning() end
function GIPT_DepositAction:update() self.item:setJobDelta(self:getJobDelta()); self.character:faceLocation(self.x,self.y); self.character:setMetabolicTarget(Metabolics.LightWork) end
function GIPT_DepositAction:start() setTransferAnimation(self, self.fluidType); self.item:setJobType("Transferring to industrial storage tank"); self.item:setJobDelta(0) end
function GIPT_DepositAction:stop()
    local progress=GIPT.clamp(self:getJobDelta() or 0,0,1); if self.item then self.item:setJobDelta(0) end
    if isClient() and self.transactionID then sendClientCommand(self.character,GIPT.MODULE,"CommitDeposit",{transactionID=self.transactionID,progress=progress,interrupted=true})
    elseif progress>=0.01 then GIPT.commitDeposit(self.character,self.x,self.y,self.z,self.item,self.installationID,(tonumber(self.maxTransfer) or 0)*progress) end
    ISBaseTimedAction.stop(self)
end
function GIPT_DepositAction:perform()
    self.item:setJobDelta(0)
    if isClient() then sendClientCommand(self.character,GIPT.MODULE,"CommitDeposit",{transactionID=self.transactionID,progress=1}) else GIPT.commitDeposit(self.character,self.x,self.y,self.z,self.item,self.installationID,self.maxTransfer) end
    ISBaseTimedAction.perform(self)
end
function GIPT_DepositAction:new(character,x,y,z,item,transactionID,installationID,maxTransfer,duration,fluidType)
    local o=ISBaseTimedAction.new(self,character); o.x,o.y,o.z,o.item=x,y,z,item; o.transactionID,o.installationID,o.maxTransfer=transactionID,installationID,maxTransfer; o.fluidType=fluidType; o.maxTime=duration or 120; o.stopOnWalk,o.stopOnRun=true,true; return o
end
