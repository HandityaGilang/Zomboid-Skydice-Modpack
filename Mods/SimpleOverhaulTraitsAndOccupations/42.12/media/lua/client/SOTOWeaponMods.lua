-----------------------------------------------------
--           Weapon Mods by Star and Hea           --
--   Using this code in your mods is not allowed   --
--     Simple Overhaul: Traits and Occupations     --
--            Steam Workshop 2023-2025             --
-----------------------------------------------------

local function SetSOTOWeaponMods(set_doordamage, set_endurancemod, set_attackwle)
    if not _mhweapon then
        return
    end
    if not _mhweapon:isEquipped() then
        -- print('WARN: not equipped')
    end

    local txt = _mhweapon:getScriptItem()
    if txt then
        local txt_endurancemod = txt:getEnduranceMod()
        local txt_doordamage = txt:getDoorDamage()
        local txt_attackwle = txt:isCantAttackWithLowestEndurance()

        if set_doordamage then
            _mhweapon:setDoorDamage(set_doordamage)
            _mhweapon:setCantAttackWithLowestEndurance(set_attackwle)
            _mhweapon:setEnduranceMod(set_endurancemod)
        else
            _mhweapon:setDoorDamage(txt_doordamage)
            _mhweapon:setCantAttackWithLowestEndurance(txt_attackwle)
            _mhweapon:setEnduranceMod(txt_endurancemod)
            _mhweapon = nil
        end
    end
end

-- HEAVY BLUNT ON EQUIP
local function SOTOWeaponMods()
    local player = getPlayer()
    if not player then return end

    local mhweapon = player:getPrimaryHandItem()
    if not mhweapon then
        -- print("No weapon in primary hand")
        return
    end

    local scriptItem = mhweapon:getScriptItem()
    if not scriptItem then
        -- print("Script item is nil")
        return
    end

	--local categories = scriptItem:getWeaponCategory()
    local swingAnim = scriptItem:getSwingAnim()

	_mhweapon = mhweapon
	local txt = scriptItem		
	local txt_endurancemod = txt:getEnduranceMod()	
	local txt_doordamage = txt:getDoorDamage()	
	local txt_attackwle = txt:isCantAttackWithLowestEndurance()
	
	local ADoorDamage = txt_doordamage
	local AEnduranceMod = txt_endurancemod
	local ACantAttackWithLowestEndurance = txt_attackwle
	
    if player:HasTrait("DemoStrongGrip") and swingAnim and scriptItem:containsWeaponCategory("Blunt") and swingAnim == "Heavy" then
		-- print("Heavy Blunt - OK")

		AEnduranceMod = 1
		ACantAttackWithLowestEndurance = false

        SetSOTOWeaponMods(ADoorDamage, AEnduranceMod, ACantAttackWithLowestEndurance)		
	end

    if player:HasTrait("HeavyAxeMyBeloved") and swingAnim and scriptItem:containsWeaponCategory("Axe") and swingAnim == "Heavy" then
		-- print("Heavy Axe - OK")
		
		AEnduranceMod = 1

        SetSOTOWeaponMods(ADoorDamage, AEnduranceMod, ACantAttackWithLowestEndurance)		
	end
		
    if player:HasTrait("BreakinTechnique") and scriptItem:containsWeaponCategory("Axe") then
		-- print("Axe - OK")
		ADoorDamage = txt_doordamage * 1.5
        SetSOTOWeaponMods(ADoorDamage, AEnduranceMod, ACantAttackWithLowestEndurance)		
	end		

	-- print("AEnduranceMod: " .. AEnduranceMod)
	-- print("ADoorDamage: " .. ADoorDamage)
	-- print("ACantAttackWithLowestEndurance: " .. tostring(ACantAttackWithLowestEndurance))
	
end

Events.OnEquipPrimary.Add(SOTOWeaponMods)
Events.OnEquipSecondary.Add(SOTOWeaponMods)
Events.OnGameStart.Add(SOTOWeaponMods);
Events.LevelPerk.Add(SOTOWeaponMods);
Events.OnCreatePlayer.Add(SOTOWeaponMods);
Events.OnCreateLivingCharacter.Add(SOTOWeaponMods);
