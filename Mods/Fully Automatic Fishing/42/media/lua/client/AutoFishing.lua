-- AutoFishing.lua (Build 42 Native) v6.1
-- 国际化：所有 UI/Log 文本替换为 getText 接口
-- 功能：保持 v5.9 的所有逻辑不变 (自动收线 + 简化版打断检测)
-- 兼容性：适配 Accelerate All Action Mod (防止钓鱼动作过快)

local AutoFishing = {}
AutoFishing.isEnabled = false
AutoFishing.delayTimer = 0
AutoFishing.tickCounter = 0 
AutoFishing.debug = true
AutoFishing.targetWaterSquare = nil 
AutoFishing.fishingStateWaitTimer = 0
AutoFishing.forceResetTimer = 0

local FishingState = zombie.ai.states.FishingState
local FishManagerInstance = nil -- Cache for FishSchoolManager instance

local function log(msg)
    if AutoFishing.debug then
        print("[AutoFishing] " .. tostring(msg))
    end
end

-- ====================================================================
-- Helper: Add Action with Tag
-- ====================================================================
local function addTimedAction(action)
    if action then
        action.isAutoFishingAction = true
        ISTimedActionQueue.add(action)
    end
end

-- ====================================================================
-- 强制停止 (包含清理动作和 UI)
-- ====================================================================
local function forceStop(player, reason)
    log("Force stopping AutoFishing: " .. reason)
    AutoFishing.isEnabled = false
    
    -- 1. 强制关闭钓鱼 UI (遍历 UIManager 确保关闭)
    local uis = UIManager.getUI()
    if uis then
        for i=0, uis:size()-1 do
            local ui = uis:get(i)
            -- 尝试通过类名或字符串匹配找到钓鱼 UI
            if ui and (ui.Type == "ISFishingUI" or (ui.toString and string.find(tostring(ui), "ISFishingUI"))) then
                if ui.close then ui:close() end
                if ui.setVisible then ui:setVisible(false) end
                if ui.removeFromUIManager then ui:removeFromUIManager() end
            end
        end
    end

    -- 备用：通过全局实例关闭
    if ISFishingUI and ISFishingUI.instance then
        if ISFishingUI.instance.close then
            ISFishingUI.instance:close()
        end
        if ISFishingUI.instance.setVisible then
            ISFishingUI.instance:setVisible(false)
        end
        if ISFishingUI.instance.removeFromUIManager then
            ISFishingUI.instance:removeFromUIManager()
        end
    end
    
    -- 2. 停止当前的钓鱼动作
    local queue = ISTimedActionQueue.getTimedActionQueue(player)
    if queue and queue.queue and #queue.queue > 0 then
        local currentAction = queue.queue[1]
        
        local shouldStop = false
        if currentAction.isAutoFishingAction then
            shouldStop = true
        elseif currentAction.Type == "FishingAction" then 
            shouldStop = true
        end
        
        if shouldStop then
             log("Stopping current fishing action...")
             if currentAction.forceStop then
                 currentAction:forceStop()
             elseif currentAction.stop then
                 currentAction:stop()
             end
        end
    end
    
    -- 3. 清理 Manager 状态 (销毁鱼漂)
    local playerIndex = isMultiplayer() and player:getUsername() or player:getPlayerNum()
    if Fishing.ManagerInstances then
        local manager = Fishing.ManagerInstances[playerIndex]
        if manager then
            -- 尝试销毁鱼漂
            if manager.fishingRod and manager.fishingRod.bobber then
                pcall(function() manager.fishingRod.bobber:destroy() end)
            end
            
            if manager.changeState then
                manager:changeState("Idle")
            end
            manager.fishingRod = nil
        end
    end
    
    -- 4. 强制退出 AI State
    player:setVariable("FishingFinished", true)
    player:setVariable("FishingStage", "")
    player:setVariable("FishingTarget", nil)
    
    player:Say(getText("IGUI_AutoFish_Msg_Stopped", reason))
end

-- ====================================================================
-- 打断检测 (Ultra Safe)
-- ====================================================================
local function checkInterruption(player)
    -- 0. 如果正在收获鱼，暂时忽略打断检测 (防止自我打断)
    local playerIndex = isMultiplayer() and player:getUsername() or player:getPlayerNum()
    if Fishing.ManagerInstances then
        local manager = Fishing.ManagerInstances[playerIndex]
        if manager and manager.state then
            local state = manager.state
            local stateName = "Unknown"
            if manager.states then
                for k, v in pairs(manager.states) do
                     if v == state then stateName = k; break end
                end
            end
            
            -- 如果处于捡鱼阶段，视为正常流程，不打断
            if stateName == "PickupFish" or stateName == "Catch" then
                return false
            end
        end
    end

    -- 1. 移动/奔跑检测
    if player:isPlayerMoving() or player:isRunning() or player:isSprinting() then
        forceStop(player, getText("IGUI_AutoFish_Reason_Moved"))
        return true
    end
    
    -- 2. 攻击检测
    if player:isAttacking() then
        forceStop(player, "Attacking")
        return true
    end

    -- 3. 受击检测
    local hit = player:getHitReaction()
    if hit and hit ~= "" and hit ~= "None" then
        forceStop(player, "Player Hit")
        return true
    end

    -- 4. 车辆检测 (In Vehicle)
    if player:getVehicle() then
        forceStop(player, getText("IGUI_AutoFish_Reason_Vehicle"))
        return true
    end

    -- 5. TimedAction 检测 (用户动作)
    local queue = ISTimedActionQueue.getTimedActionQueue(player)
    if queue and queue.queue and #queue.queue > 0 then
        for _, action in ipairs(queue.queue) do
            -- 如果发现了未标记的动作，且该动作不是钓鱼动作本身 (FishingAction)
            if not action.isAutoFishingAction then
                -- 简单的白名单检查，避免误判当前的钓鱼动作
                local isFishing = false
                if action.Type == "FishingAction" then isFishing = true end
                
                if not isFishing then
                    forceStop(player, "User Action")
                    return true
                end
            end
        end
    end
    
    return false
end

-- ====================================================================
-- Hook 系统
-- ====================================================================
local function installHooks()
    if AutoFishing.hooksInstalled then return end
    if not Fishing or not Fishing.FishingRod or not Fishing.Utils then return end

    -- 1. Hook getSpawnBobberCoords
    local oldGetSpawnCoords = Fishing.FishingRod.getSpawnBobberCoords
    Fishing.FishingRod.getSpawnBobberCoords = function(self)
        if AutoFishing.isEnabled and AutoFishing.targetWaterSquare then
            return AutoFishing.targetWaterSquare:getX() + 0.5, AutoFishing.targetWaterSquare:getY() + 0.5
        end
        return oldGetSpawnCoords(self)
    end

    -- 2. Hook FishingRod: 自动收线
    local originalIsReel = Fishing.FishingRod.isReel
    Fishing.FishingRod.isReel = function(self)
        if originalIsReel(self) then return true end
        if AutoFishing.isEnabled and self.bobber and self.bobber.fish then
            local tension = self:getTension()
            if tension <= 0.8 then return true end
        end
        return false
    end

    local originalIsReleaseLine = Fishing.FishingRod.isReleaseLine
    Fishing.FishingRod.isReleaseLine = function(self)
        if originalIsReleaseLine(self) then return true end
        if AutoFishing.isEnabled and self.bobber and self.bobber.fish then
            local tension = self:getTension()
            if tension > 0.8 then return true end
        end
        return false
    end
    
    local originalUpdateLineMoveCoeff = Fishing.FishingRod.updateLineMoveCoeff
    Fishing.FishingRod.updateLineMoveCoeff = function(self)
        originalUpdateLineMoveCoeff(self)
        if AutoFishing.isEnabled and self.bobber and self.bobber.fish then
            self.lineMoveCoeff = 1.2
            self.bobber.catchFishStarted = true
        end
    end
    
    -- 3. Hook getAimCoords (解决鼠标必须指水问题)
    -- 修正：必须返回 x, y, z (多返回值)，而不是 table，否则会导致 FishingZones.lua 崩溃 (__le not defined)
    local oldGetAimCoords = Fishing.Utils.getAimCoords
    Fishing.Utils.getAimCoords = function(player)
        if AutoFishing.isEnabled and AutoFishing.targetWaterSquare then
             local sq = AutoFishing.targetWaterSquare
             return sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ()
        end
        return oldGetAimCoords(player)
    end

    AutoFishing.hooksInstalled = true
    log("Hooks installed (v5.5).")
end

-- ====================================================================
-- 辅助函数
-- ====================================================================
local function isFishingRod(item)
    if not item then return false end
    if type(item) ~= "userdata" then return false end

    local typeName = nil
    local ok = pcall(function() typeName = item:getType() end)
    
    if not ok or not typeName then return false end
    
    if string.find(typeName, "Break") or string.find(typeName, "Broken") then
        return false 
    end
    
    local broken = false
    pcall(function() broken = item:isBroken() end)
    if broken then return false end

    if string.find(typeName, "FishingRod") then 
        return true 
    end
    
    return false
end

-- 寻找背包中最佳的鱼饵
local function getBestBait(player)
    if not player then return nil end
    local inv = player:getInventory()
    if not inv then return nil end
    
    local items = inv:getItems()
    for i=0, items:size()-1 do
        local item = items:get(i)
        
        -- 1. 使用 Build 42 原生 API: Fishing.IsLure(fullType)
        local isLure = false
        if Fishing and Fishing.IsLure then
             isLure = Fishing.IsLure(item:getFullType())
        end
        
        -- 过滤煮熟的食物 (参考 ISInventoryPaneContextMenu)
        if isLure and instanceof(item, "Food") and item:isCooked() then
            isLure = false
        end

        if isLure then return item end
    end
    
    return nil
end

-- Polyfill for AIAttachLureAction if missing
if not AIAttachLureAction then
    AIAttachLureAction = ISBaseTimedAction:derive("AIAttachLureAction")
    function AIAttachLureAction:isValid()
        return self.character:getInventory():contains(self.lure) and 
               self.character:getPrimaryHandItem() == self.rod and
               self.character:getSecondaryHandItem() == self.lure
    end
    function AIAttachLureAction:update()
        self.rod:setJobType(getText("ContextMenu_Add_Bait"))
        self.rod:setJobDelta(self:getJobDelta())
        self.lure:setJobType(getText("ContextMenu_Add_Bait"))
        self.lure:setJobDelta(self:getJobDelta())
    end
    function AIAttachLureAction:start()
        self:setActionAnim("AttachItem")
        self:setOverrideHandModels(self.rod, self.lure)
    end
    function AIAttachLureAction:stop()
        ISBaseTimedAction.stop(self)
    end
    function AIAttachLureAction:new(character, rod, lure)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o.character = character
        o.rod = rod
        o.lure = lure
        o.stopOnWalk = true
        o.stopOnRun = true
        o.maxTime = 100
        return o
    end
    log("Polyfilled AIAttachLureAction")
end

-- Fix for NPE Crash (BodyLocationGroup.isExclusive)
-- Ensure item is unequipped from hands before being removed from inventory
local original_perform = AIAttachLureAction.perform
function AIAttachLureAction:perform()
    if self.character then
        -- Force unequip from hands to prevent Render Thread accessing it
        if self.character:getPrimaryHandItem() == self.lure then
            self.character:setPrimaryHandItem(nil)
        end
        if self.character:getSecondaryHandItem() == self.lure then
            self.character:setSecondaryHandItem(nil)
        end
        -- Remove from worn items if present
        local worn = self.character:getWornItems()
        if worn and worn:contains(self.lure) then
            worn:remove(self.lure)
        end
    end

    -- Execute standard logic
    if original_perform then
        original_perform(self)
    else
        -- Fallback logic
        self.rod:getModData().fishing_Lure = self.lure:getFullType()
        self.character:getInventory():Remove(self.lure)
        self.character:playSound("EquipItem")
        ISBaseTimedAction.perform(self)
    end
end

-- 检查并自动安装鱼饵
local function checkAndAttachBait(player, rod)
    if not rod then return false end
    
    -- 检查当前是否有鱼饵
    local modData = rod:getModData()
    local currentLure = modData.fishing_Lure
    
    -- 如果已有鱼饵 (且不是 None)，则无需操作
    if currentLure and currentLure ~= "UI_None" and currentLure ~= "" then
        return false
    end
    
    -- 检查是否正在执行动作，避免重复
    local queue = ISTimedActionQueue.getTimedActionQueue(player)
    if queue and queue.queue and #queue.queue > 0 then
        return true -- 正在忙，视为“正在处理”，阻止抛竿
    end
    
    log("Rod has no bait. Searching for bait...")
    
    local bait = getBestBait(player)
    if bait then
        log("Found bait: " .. bait:getName() .. ". Attaching...")
        
        -- 按游戏原生逻辑：先装备鱼饵到副手，再装备鱼竿到主手，然后执行 AttachLureAction
        addTimedAction(ISEquipWeaponAction:new(player, bait, 50, false)) -- 副手
        addTimedAction(ISEquipWeaponAction:new(player, rod, 50, true))   -- 主手
        addTimedAction(AIAttachLureAction:new(player, rod, bait))
        
        getPlayer():Say(getText("IGUI_AutoFish_Msg_Baited", bait:getDisplayName())) -- "Auto-Baited: "
        return true -- 动作已开始，阻止后续抛竿
    else
        log("No bait found in inventory.")
    end
    return false
end

local function getFishManager()
    if FishManagerInstance then return FishManagerInstance end
    if FishSchoolManager then
        FishManagerInstance = FishSchoolManager.getInstance()
    elseif zombie.iso.FishSchoolManager then
        FishManagerInstance = zombie.iso.FishSchoolManager.getInstance()
    end
    return FishManagerInstance
end

local function findTargetWaterSquare(player)
    local cell = getCell()
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    
    local waterSquares = {}
    local scoredSquares = {}
    local fishManager = getFishManager()

    -- 搜索范围
    for r = 12, 5, -1 do
        for x = -r, r do
            for y = -r, r do
                if math.abs(x) == r or math.abs(y) == r then
                    if x % 2 == 0 and y % 2 == 0 then
                        local sq = cell:getGridSquare(px + x, py + y, pz)
                        if sq and sq:getProperties():has(IsoFlagType.water) then
                            table.insert(waterSquares, sq)
                            
                            local score = 0
                            
                            -- 1. 视觉特效 (Splash)
                            local objects = sq:getObjects()
                            for i=0, objects:size()-1 do
                                local obj = objects:get(i)
                                local objName = obj:getObjectName()
                                if objName == "RainSplashes" or objName == "WaterSplash" then
                                    score = score + 100 -- 视觉可见的鱼点，优先级最高
                                    break
                                end
                            end
                            
                            -- 2. 鱼群丰富度 (Java API)
                            if fishManager then
                                local abundance = 0
                                local ok = pcall(function() abundance = fishManager:getFishAbundance(sq:getX(), sq:getY()) end)
                                if ok and abundance > 0 then
                                    score = score + (abundance * 10)
                                end
                            end
                            
                            -- 3. 距离惩罚 (稍微偏好近处)
                            score = score - (r * 0.1)
                            
                            if score > 0 then
                                table.insert(scoredSquares, {sq = sq, score = score})
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 优先级 1: 高分鱼点
    if #scoredSquares > 0 then
        table.sort(scoredSquares, function(a, b) return a.score > b.score end)
        -- 从前3名中随机选择，增加自然感
        local topN = math.min(#scoredSquares, 3)
        local choice = scoredSquares[ZombRand(topN) + 1]
        log("Found target with score: " .. string.format("%.2f", choice.score))
        return choice.sq
    end
    
    -- 优先级 2: 随机水域
    if #waterSquares > 0 then
        log("No fish spots found, using random water square.")
        return waterSquares[ZombRand(#waterSquares) + 1]
    end
    
    return nil
end

-- ====================================================================
-- 主循环
-- ====================================================================
local function onTick()
    if not AutoFishing.isEnabled then return end
    
    AutoFishing.tickCounter = AutoFishing.tickCounter + 1
    if AutoFishing.tickCounter < 5 then return end
    AutoFishing.tickCounter = 0

    local player = getPlayer()
    if not player or player:isDead() then 
        AutoFishing.isEnabled = false
        return 
    end

    -- 打断检测
    local interrupted = checkInterruption(player)
    if interrupted then
        return
    end

    -- 1. 装备检查
    local primary = player:getPrimaryHandItem()
    if not isFishingRod(primary) then
        local inv = player:getInventory()
        local rod = nil
        local items = inv:getItems()
        for i=0, items:size()-1 do
            local item = items:get(i)
            if isFishingRod(item) then rod = item; break; end
        end
        if rod then
            addTimedAction(ISEquipWeaponAction:new(player, rod, 50, true))
            return 
        else
            player:Say(getText("IGUI_AutoFish_Msg_NoRod")) -- "AutoFish: No Rod!"
            AutoFishing.isEnabled = false
            return
        end
    end
    
    -- 等待装备动作完成
    if player:getVariable("IsEquipping") == "true" or player:getVariable("IsEquipping") == true then
        return 
    end

    -- 2. 获取 Manager
    local playerIndex = isMultiplayer() and player:getUsername() or player:getPlayerNum()
    local manager = Fishing.ManagerInstances[playerIndex]
    
    if not manager then
        Fishing.ManagerInstances[playerIndex] = Fishing.FishingManager:new(player, player:getJoypadBind())
        manager = Fishing.ManagerInstances[playerIndex]
        if not manager then return end
    end

    -- 3. 寻找并锁定水源 (每次抛竿前重新寻找，以支持随机化)
    local state = manager.state
    local stateName = "Unknown"
    for k, v in pairs(manager.states) do
        if v == state then stateName = k; break end
    end

    -- 只有在 Idle/None 状态且没有目标时，才寻找新目标
    if (stateName == "None" or stateName == "Idle") and not AutoFishing.targetWaterSquare then
        AutoFishing.targetWaterSquare = findTargetWaterSquare(player)
        if not AutoFishing.targetWaterSquare then
            player:Say(getText("IGUI_AutoFish_Msg_NoWater")) -- "AutoFish: No Water Nearby!"
            AutoFishing.isEnabled = false
            return
        end
        player:faceLocation(AutoFishing.targetWaterSquare:getX(), AutoFishing.targetWaterSquare:getY())
    end

    -- 4. 状态机驱动
    if stateName == "None" or stateName == "Idle" then
        local currentState = player:getCurrentState()
        local isFishingState = (currentState == FishingState.instance())
        
        if not isFishingState then
            -- 尝试触发事件
            player:reportEvent("EventFishing")
            player:faceLocation(AutoFishing.targetWaterSquare:getX(), AutoFishing.targetWaterSquare:getY())
            
            AutoFishing.fishingStateWaitTimer = AutoFishing.fishingStateWaitTimer + 1
            
            -- 卡住检测
            if AutoFishing.fishingStateWaitTimer > 20 then
                player:setVariable("FishingFinished", false)
                player:setVariable("FishingStage", "")
                player:setVariable("FishingTarget", nil)
                player:reportEvent("EventFishing")
                AutoFishing.fishingStateWaitTimer = 0
            end
            return
        end
        
        -- 已进入 FishingState
        AutoFishing.fishingStateWaitTimer = 0
        if not manager.fishingRod then
            manager.fishingRod = Fishing.FishingRod:new(player, player:getJoypadBind())
        end
        
        -- 在抛竿前检查并安装鱼饵
        local primary = player:getPrimaryHandItem()
        if isFishingRod(primary) then
            if checkAndAttachBait(player, primary) then
                return
            end
        end
        
        player:faceLocation(AutoFishing.targetWaterSquare:getX(), AutoFishing.targetWaterSquare:getY())
        manager:changeState("Cast")
        
    elseif stateName == "Cast" or stateName == "Wait" or stateName == "ReelIn" or stateName == "ReelOut" then
        -- 钓鱼中
    elseif stateName == "PickupFish" then
        -- 捡鱼中，清空目标，以便下次重新随机寻找
        AutoFishing.targetWaterSquare = nil
    end
end

-- ====================================================================
-- 初始化
-- ====================================================================
function AutoFishing.toggle()
    AutoFishing.isEnabled = not AutoFishing.isEnabled
    local status = AutoFishing.isEnabled and getText("IGUI_AutoFish_Status_ON") or getText("IGUI_AutoFish_Status_OFF")
    getPlayer():Say(getText("IGUI_AutoFish_Msg_Toggle", status)) -- "AutoFish: ON/OFF"
    if AutoFishing.isEnabled then 
        installHooks() 
        local p = getPlayer()
        ISTimedActionQueue.clear(p)
        AutoFishing.targetWaterSquare = nil 
        AutoFishing.tickCounter = 0
        AutoFishing.fishingStateWaitTimer = 0
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    
    local primary = playerObj:getPrimaryHandItem()
    if isFishingRod(primary) or AutoFishing.isEnabled then
        local status = AutoFishing.isEnabled and getText("IGUI_AutoFish_Status_ON") or getText("IGUI_AutoFish_Status_OFF")
        context:addOption(getText("IGUI_AutoFish_ContextMenu", "v6.1", status), nil, AutoFishing.toggle)
    end
end

-- ====================================================================
-- 兼容性补丁 (Accelerate All Action / VacMod15)
-- ====================================================================
local function installCompatibilityPatch()
    if AutoFishing.patchInstalled then return end
    
    -- Hook ISTimedActionQueue.add 以拦截并保护钓鱼动作
    if ISTimedActionQueue and ISTimedActionQueue.add then
        local original_add = ISTimedActionQueue.add
        ISTimedActionQueue.add = function(action)
            if action then
                -- 识别钓鱼相关动作
                local isFishingAction = false
                
                -- 1. AutoFishing 标记的动作
                if action.isAutoFishingAction then 
                    isFishingAction = true 
                end
                
                -- 2. 游戏原生的 FishingAction
                if action.Type == "FishingAction" then 
                    isFishingAction = true 
                end
                
                -- 3. 状态名检测 (额外保险)
                if not isFishingAction and action.statename and string.find(tostring(action.statename), "Fish") then
                    isFishingAction = true
                end
                
                if isFishingAction then
                    -- 强制覆盖 getDuration，直接返回 maxTime
                    -- 这将绕过 Accelerate All Action 修改过的 getDuration 逻辑
                    if action.maxTime then
                        action.getDuration = function(self)
                            return self.maxTime
                        end
                    else
                        -- 如果没有 maxTime (虽然不应该)，尝试不修改，或者设为默认值
                        -- 对于原生 Java Action，可能没有 maxTime 字段，但通常不受 Lua Hook 影响
                        -- 如果受影响了，说明它是 Lua 实现的
                    end
                    -- log("Protected action from acceleration: " .. tostring(action.Type))
                end
            end
            original_add(action)
        end
        log("Compatibility patch installed: Protected fishing actions from acceleration.")
    end
    
    AutoFishing.patchInstalled = true
end

local function init()
    installCompatibilityPatch() -- 优先安装补丁
    
    Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
    Events.OnTick.Add(onTick)
    log("Loaded Build 42 Version v6.1 (Compatibility Patch)")
end

Events.OnGameStart.Add(init)

return AutoFishing