require "TimedActions/ISBaseTimedAction"

ISInsertMagazine = ISBaseTimedAction:derive("ISInsertMagazine")

function ISInsertMagazine:isValid()
	print("DEBUG [ISInsertMagazine:isValid]: Checking validity")
	
	if not isClient() and not self.loadFinished then
		if self.gun and self.gun:isContainsClip() then
			print("DEBUG [ISInsertMagazine:isValid]: Gun already has a clip")
			return false
		end
		if self.magazine then
			if self.character and self.character:getInventory() and not self.character:getInventory():contains(self.magazine) then
				print("DEBUG [ISInsertMagazine:isValid]: Magazine not in inventory")
				return false
			end
		end
	end
	
	local result = self.character and self.gun and self.character:getPrimaryHandItem() == self.gun
	print("DEBUG [ISInsertMagazine:isValid]: Result = " .. tostring(result))
	return result
end

function ISInsertMagazine:start()
	print("DEBUG [ISInsertMagazine:start]: Starting insert magazine action")
	print("DEBUG [ISInsertMagazine:start]: isClient = " .. tostring(isClient()))
	print("DEBUG [ISInsertMagazine:start]: isServer = " .. tostring(isServer()))
	
	-- RE-OBTER O CARREGADOR PELO ID EM TODOS OS CONTEXTOS
	if self.magazine then
		local success, magazineID = pcall(function() return self.magazine:getID() end)
		if success and magazineID then
			self.magazineID = magazineID
			print("DEBUG [ISInsertMagazine:start]: Magazine ID = " .. tostring(magazineID))
			
			-- Re-obter o carregador do inventário
			if self.character then
				local inventory = self.character:getInventory()
				if inventory then
					local freshMagazine = inventory:getItemById(magazineID)
					if freshMagazine then
						self.magazine = freshMagazine
						self.savedMagazineAmmo = freshMagazine:getCurrentAmmoCount() or 0
						print("DEBUG [ISInsertMagazine:start]: Fresh magazine has " .. self.savedMagazineAmmo .. " rounds")
					else
						print("DEBUG [ISInsertMagazine:start]: WARNING - Could not re-obtain magazine from inventory!")
						self.savedMagazineAmmo = self.magazine:getCurrentAmmoCount() or 0
					end
				end
			end
		else
			print("DEBUG [ISInsertMagazine:start]: WARNING - Could not get magazine ID")
			self.savedMagazineAmmo = self.magazine:getCurrentAmmoCount() or 0
		end
	else
		print("DEBUG [ISInsertMagazine:start]: WARNING - Magazine is nil!")
		self.savedMagazineAmmo = 0
	end
	
	if self.gun then
		self:setAnimVariable("WeaponReloadType", self.gun:getWeaponReloadType())
	end
	self:setAnimVariable("isLoading", true)
	if self.gun then
		self:setOverrideHandModels(self.gun, nil)
	end
	self:setActionAnim(CharacterActionAnims.Reload)
	if self.character then
		self.character:reportEvent("EventReloading")
	end
	self:initVars()
end

function ISInsertMagazine:update()
	if self.gun then
		self.gun:setJobDelta(self:getJobDelta())
	end
	if self.magazine then
		self.magazine:setJobDelta(self:getJobDelta())
	end
end

function ISInsertMagazine:initVars()
	if ISReloadWeaponAction and ISReloadWeaponAction.setReloadSpeed and self.character then
		ISReloadWeaponAction.setReloadSpeed(self.character, false)
	end
end

function ISInsertMagazine:loadAmmo()
	print("DEBUG [ISInsertMagazine:loadAmmo]: ===== STARTING LOAD AMMO =====")
	print("DEBUG [ISInsertMagazine:loadAmmo]: isClient = " .. tostring(isClient()))
	print("DEBUG [ISInsertMagazine:loadAmmo]: isServer = " .. tostring(isServer()))
	
	-- PROTEÇÃO CONTRA NIL - CRITICAL
	if not self.character then
		print("DEBUG [ISInsertMagazine:loadAmmo]: ERROR - Character is nil!")
		return
	end
	
	if not self.gun then
		print("DEBUG [ISInsertMagazine:loadAmmo]: ERROR - Gun is nil!")
		return
	end
	
	-- RE-OBTER O CARREGADOR SE NECESSÁRIO
	local magazine = self.magazine
	if self.magazineID and self.character then
		local inventory = self.character:getInventory()
		if inventory then
			local freshMagazine = inventory:getItemById(self.magazineID)
			if freshMagazine then
				magazine = freshMagazine
				print("DEBUG [ISInsertMagazine:loadAmmo]: Re-obtained magazine from inventory")
			else
				print("DEBUG [ISInsertMagazine:loadAmmo]: WARNING - Could not re-obtain magazine, using cached")
			end
		end
	end
	
	if not magazine then
		print("DEBUG [ISInsertMagazine:loadAmmo]: ERROR - Magazine is nil!")
		return
	end
	
	-- USAR MÚLTIPLAS FONTES PARA OBTER A MUNIÇÃO
	local ammoCount = self.savedMagazineAmmo or 0
	if ammoCount <= 0 then
		local success, currentAmmo = pcall(function() return magazine:getCurrentAmmoCount() end)
		if success and currentAmmo then
			ammoCount = currentAmmo
			print("DEBUG [ISInsertMagazine:loadAmmo]: Using magazine current ammo: " .. ammoCount)
		else
			print("DEBUG [ISInsertMagazine:loadAmmo]: ERROR - Could not get current ammo count")
			ammoCount = 0
		end
	else
		print("DEBUG [ISInsertMagazine:loadAmmo]: Using saved ammo: " .. ammoCount)
	end
	
	print("DEBUG [ISInsertMagazine:loadAmmo]: Final ammo count to load: " .. ammoCount)
	print("DEBUG [ISInsertMagazine:loadAmmo]: Gun current ammo before: " .. tostring(self.gun:getCurrentAmmoCount()))
	
	-- Remove o carregador do inventário
	local inventory = self.character:getInventory()
	if inventory and magazine then
		if inventory:contains(magazine) then
			inventory:Remove(magazine)
			print("DEBUG [ISInsertMagazine:loadAmmo]: Magazine removed from inventory")
		else
			print("DEBUG [ISInsertMagazine:loadAmmo]: WARNING - Magazine not in inventory!")
		end
	end
	
	-- Remover das mãos com proteção
	if self.character and self.character.removeFromHands then
		local success, err = pcall(function()
			self.character:removeFromHands(magazine)
		end)
		if not success then
			print("DEBUG [ISInsertMagazine:loadAmmo]: WARNING - removeFromHands failed: " .. tostring(err))
		end
	end
	
	-- SETAR A MUNIÇÃO NA ARMA COM PROTEÇÃO
	if self.gun then
		local success1, err1 = pcall(function()
			self.gun:setCurrentAmmoCount(ammoCount)
		end)
		if not success1 then
			print("DEBUG [ISInsertMagazine:loadAmmo]: ERROR - setCurrentAmmoCount failed: " .. tostring(err1))
		end
		
		local success2, err2 = pcall(function()
			self.gun:setContainsClip(true)
		end)
		if not success2 then
			print("DEBUG [ISInsertMagazine:loadAmmo]: ERROR - setContainsClip failed: " .. tostring(err2))
		end
		
		print("DEBUG [ISInsertMagazine:loadAmmo]: Gun current ammo after: " .. tostring(self.gun:getCurrentAmmoCount()))
		print("DEBUG [ISInsertMagazine:loadAmmo]: Gun contains clip: " .. tostring(self.gun:isContainsClip()))
	end
	
	if self.character then
		self.character:clearVariable("isLoading")
	end

	-- we rack only if no round is chambered
	if not isServer() and not isClient() and self.gun and self.character then
		if not self.gun:isRoundChambered() and self.gun:getCurrentAmmoCount() >= self.gun:getAmmoPerShoot() then
			print("DEBUG [ISInsertMagazine:loadAmmo]: Adding rack action")
			if ISRackFirearm then
				ISTimedActionQueue.addAfter(self, ISRackFirearm:new(self.character, self.gun))
			end
		end
	end

	-- Sincronizar com o servidor - CRITICAL! COM PROTEÇÃO
	if sendRemoveItemFromContainer and inventory and magazine then
		local success, err = pcall(function()
			sendRemoveItemFromContainer(inventory, magazine)
		end)
		if success then
			print("DEBUG [ISInsertMagazine:loadAmmo]: Sent remove item to server")
		else
			print("DEBUG [ISInsertMagazine:loadAmmo]: ERROR - sendRemoveItemFromContainer failed: " .. tostring(err))
		end
	end
	
	if syncHandWeaponFields and self.character and self.gun then
		local success, err = pcall(function()
			syncHandWeaponFields(self.character, self.gun)
		end)
		if success then
			print("DEBUG [ISInsertMagazine:loadAmmo]: Synced weapon fields")
		else
			print("DEBUG [ISInsertMagazine:loadAmmo]: ERROR - syncHandWeaponFields failed: " .. tostring(err))
		end
	end
	
	-- FORÇAR ATUALIZAÇÃO DO ESTADO DA ARMA COM PROTEÇÃO
	if (isClient() or isServer()) and self.gun and self.gun.syncReload and self.character then
		local success, err = pcall(function()
			self.gun:syncReload(self.character:getPlayerNum())
		end)
		if success then
			print("DEBUG [ISInsertMagazine:loadAmmo]: Forced gun sync")
		else
			print("DEBUG [ISInsertMagazine:loadAmmo]: WARNING - syncReload failed: " .. tostring(err))
		end
	end
	
	print("DEBUG [ISInsertMagazine:loadAmmo]: ===== LOAD AMMO COMPLETE =====")
end

function ISInsertMagazine:serverStart()
	print("DEBUG [ISInsertMagazine:serverStart]: Server starting")
	self:initVars()
	
	-- RE-OBTER E SALVAR MUNIÇÃO NO SERVIDOR
	if self.magazine then
		local success, magazineID = pcall(function() return self.magazine:getID() end)
		if success and magazineID then
			self.magazineID = magazineID
			
			if self.character then
				local inventory = self.character:getInventory()
				if inventory then
					local freshMagazine = inventory:getItemById(magazineID)
					if freshMagazine then
						self.magazine = freshMagazine
						self.savedMagazineAmmo = freshMagazine:getCurrentAmmoCount() or 0
						print("DEBUG [ISInsertMagazine:serverStart]: Server saved magazine ammo: " .. self.savedMagazineAmmo)
					else
						print("DEBUG [ISInsertMagazine:serverStart]: WARNING - Could not obtain magazine on server")
						self.savedMagazineAmmo = self.magazine:getCurrentAmmoCount() or 0
					end
				end
			end
		else
			print("DEBUG [ISInsertMagazine:serverStart]: WARNING - Could not get magazine ID")
			self.savedMagazineAmmo = 0
		end
	end
	
	if emulateAnimEventOnce and self.netAction then
		emulateAnimEventOnce(self.netAction, 1500, "loadFinished", nil)
	end
end

function ISInsertMagazine:getDuration()
	return -1
end

function ISInsertMagazine:complete()
	return true
end

function ISInsertMagazine:animEvent(event, parameter)
	print("DEBUG [ISInsertMagazine:animEvent]: Event = " .. tostring(event))
	
	-- Loading clip is done, we're moving to racking if needed
	if event == 'loadFinished' then
		print("DEBUG [ISInsertMagazine:animEvent]: loadFinished triggered")
		self.loadFinished = true
		
		if not isClient() then
			print("DEBUG [ISInsertMagazine:animEvent]: Calling loadAmmo (not client)")
			
			if self.character then
				local chance = 3
				local xp = 1
				if self.character:getPerkLevel(Perks.Reloading) < 5 then
					chance = 1
					xp = 4
				end
				if ZombRand(chance) == 0 then
					addXp(self.character, Perks.Reloading, xp)
				end
			end
			
			-- CHAMAR LOADAMMO COM PROTEÇÃO
			local success, err = pcall(function()
				self:loadAmmo()
			end)
			
			if not success then
				print("DEBUG [ISInsertMagazine:animEvent]: ERROR - loadAmmo failed: " .. tostring(err))
			end
		else
			print("DEBUG [ISInsertMagazine:animEvent]: Skipping loadAmmo (is client)")
		end
		
		if isServer() then
			print("DEBUG [ISInsertMagazine:animEvent]: Forcing complete on server")
			if self.netAction and self.netAction.forceComplete then
				self.netAction:forceComplete()
			end
		else
			print("DEBUG [ISInsertMagazine:animEvent]: Forcing complete on client")
			if self.forceComplete then
				self:forceComplete()
			end
		end
	end
	
	if event == 'playReloadSound' then
		if self.gun and self.character then
			if parameter == 'load' then
				if self.gun:getInsertAmmoSound() and self.gun:getCurrentAmmoCount() < self.gun:getMaxAmmo() then
					self.character:playSound(self.gun:getInsertAmmoSound())
				end
			elseif parameter == 'insertAmmoStart' then
				if self.gun:getInsertAmmoStartSound() then
					self.character:playSound(self.gun:getInsertAmmoStartSound())
				end
			end
		end
	end
end

function ISInsertMagazine:stop()
	print("DEBUG [ISInsertMagazine:stop]: Action stopped")
	if self.gun and self.gun:getInsertAmmoStopSound() and self.character then
		self.character:playSound(self.gun:getInsertAmmoStopSound())
	end
	if self.gun then
		self.gun:setJobDelta(0.0)
	end
	if self.magazine then
		self.magazine:setJobDelta(0.0)
	end
	if self.character then
		self.character:clearVariable("isLoading")
		self.character:clearVariable("WeaponReloadType")
	end
	ISBaseTimedAction.stop(self)
end

function ISInsertMagazine:perform()
	print("DEBUG [ISInsertMagazine:perform]: Performing action")
	if self.gun and self.gun:getInsertAmmoStopSound() and self.character then
		self.character:playSound(self.gun:getInsertAmmoStopSound())
	end
	if self.gun then
		self.gun:setJobDelta(0.0)
	end
	if self.magazine then
		self.magazine:setJobDelta(0.0)
	end
	if self.character then
		self.character:clearVariable("isLoading")
		self.character:clearVariable("WeaponReloadType")
	end

	if isClient() then
		print("DEBUG [ISInsertMagazine:perform]: Client - checking rack needed")
		-- we rack only if no round is chambered
		if self.gun and self.character and not self.gun:isRoundChambered() and self.gun:getCurrentAmmoCount() >= self.gun:getAmmoPerShoot() then
			print("DEBUG [ISInsertMagazine:perform]: Adding rack action")
			if ISRackFirearm then
				ISTimedActionQueue.addAfter(self, ISRackFirearm:new(self.character, self.gun))
			end
		end
	end

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISInsertMagazine:new(character, gun, magazine)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = false
	o.stopOnRun = true
	o.stopOnAim = false
	o.maxTime = o:getDuration()
	o.useProgressBar = false
	o.gun = gun
	o.magazine = magazine
	o.loadFinished = false
	o.savedMagazineAmmo = 0
	o.magazineID = nil
	
	print("DEBUG [ISInsertMagazine:new]: Creating new insert magazine action")
	if magazine then
		local success, ammo = pcall(function() return magazine:getCurrentAmmoCount() end)
		if success then
			print("DEBUG [ISInsertMagazine:new]: Magazine ammo: " .. tostring(ammo))
		end
	end
	if gun then
		local success, ammo = pcall(function() return gun:getCurrentAmmoCount() end)
		if success then
			print("DEBUG [ISInsertMagazine:new]: Gun ammo: " .. tostring(ammo))
		end
	end
	
	return o
end