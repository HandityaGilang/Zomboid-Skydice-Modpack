require "TimedActions/ISBaseTimedAction"

ISRemoveWeaponUpgrade = ISBaseTimedAction:derive("ISRemoveWeaponUpgrade");

local function predicateNotBroken(item)
    return not item:isBroken()
end

function ISRemoveWeaponUpgrade:isValid()
    if not self.character then return false end
    if not self.weapon then return false end
    
    local inventory = self.character:getInventory()
    if not inventory then return false end
    
    -- No multiplayer, re-obter o item pelo ID
    if isClient() then
        local weapon = inventory:getItemById(self.weaponID)
        if not weapon then return false end
        self.weapon = weapon
        return true
    end
    
    if not inventory:contains(self.weapon) then return false end
    
    local part = self.weapon:getWeaponPart(self.partType)
    return part ~= nil and part:canDetach(self.character, self.weapon)
end

function ISRemoveWeaponUpgrade:update()
    if self.character then
        self.character:setMetabolicTarget(Metabolics.LightDomestic)
    end
end

function ISRemoveWeaponUpgrade:start()
    -- Re-obter a arma no inicio da acao para garantir referencia valida
    if isClient() and self.weaponID and self.character then
        local inventory = self.character:getInventory()
        if inventory then
            local weapon = inventory:getItemById(self.weaponID)
            if weapon then
                self.weapon = weapon
            end
        end
    end
end

function ISRemoveWeaponUpgrade:stop()
    if ISBaseTimedAction.stop then
        ISBaseTimedAction.stop(self)
    end
end

function ISRemoveWeaponUpgrade:perform()
    if ISBaseTimedAction.perform then
        ISBaseTimedAction.perform(self)
    end
end

function ISRemoveWeaponUpgrade:complete()
    -- Verificacoes de seguranca
    if not self then return false end
    if not self.character then return false end
    
    local inventory = self.character:getInventory()
    if not inventory then return false end
    
    -- Re-obter a arma pelo ID para garantir referencia valida no servidor
    local weapon = self.weapon
    if self.weaponID then
        local weaponById = inventory:getItemById(self.weaponID)
        if weaponById then
            weapon = weaponById
        end
    end
    
    -- Verificar se a arma existe
    if not weapon then return false end
    
    -- Verificar se o metodo existe
    if not weapon.getWeaponPart then return false end
    
    -- Obter a parte com seguranca
    local part = nil
    local success, result = pcall(function()
        return weapon:getWeaponPart(self.partType)
    end)
    
    if success and result then
        part = result
    else
        return false
    end
    
    if not part then return false end
    
    -- Verificar se pode desanexar
    if part.canDetach then
        local canDetach = false
        local detachSuccess, detachResult = pcall(function()
            return part:canDetach(self.character, weapon)
        end)
        if detachSuccess then
            canDetach = detachResult
        end
        if not canDetach then return false end
    end
    
    -- Desanexar a parte com seguranca
    local detachOk = pcall(function()
        weapon:detachWeaponPart(self.character, part)
    end)
    
    if not detachOk then return false end
    
    -- Sincronizar campos da arma
    if syncHandWeaponFields then
        pcall(function()
            syncHandWeaponFields(self.character, weapon)
        end)
    end
    
    -- Adicionar a parte ao inventario
    local addSuccess = pcall(function()
        inventory:AddItem(part)
    end)
    
    if not addSuccess then return false end
    
    -- Sincronizar no multiplayer
    if sendAddItemToContainer then
        pcall(function()
            sendAddItemToContainer(inventory, part)
        end)
    end
    
    return true
end

function ISRemoveWeaponUpgrade:getDuration()
    if self.character and self.character:isTimedActionInstant() then
        return 1
    end
    return 50
end

function ISRemoveWeaponUpgrade:new(character, weapon, partType)
    local o = ISBaseTimedAction.new(self, character)
    o.weapon = weapon
    o.partType = partType
    o.weaponID = nil
    
    -- Armazenar o ID da arma para re-obter no servidor
    if weapon and weapon.getID then
        local success, id = pcall(function() return weapon:getID() end)
        if success and id then
            o.weaponID = id
        end
    end
    
    o.maxTime = o:getDuration()
    return o
end
