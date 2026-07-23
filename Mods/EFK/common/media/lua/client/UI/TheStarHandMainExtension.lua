---
--- Mod: Weapon Condition Indicator
--- Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2619072426
--- Author: NoctisFalco
--- Profile: https://steamcommunity.com/id/NoctisFalco/
---
--- Redistribution of this mod without explicit permission from the original creator is prohibited
--- under any circumstances. This includes, but not limited to, uploading this mod to the Steam Workshop
--- or any other site, distribution as part of another mod or modpack, distribution of modified versions.
--- You are free to do whatever you want with the mod provided you do not upload any part of it anywhere.
---
--- The QualityStar_n.png icons are the property of The Indie Stone.
--- The mod overrides parts of the ISHotbar.lua, ISEquippedItem.lua files by The Indie Stone.
---

local getTimeInMillis = getTimeInMillis

TheStar = TheStar or {}
TheStar.HandMainExtension = TheStar.HandMainExtension or {}
TheStar.HandMainExtension.Ammo = TheStar.HandMainExtension.Ammo or {}
TheStar.HandMainExtension.Battery = TheStar.HandMainExtension.Battery or {}

TheStar.HandMainExtension.Ammo.tickInterval = 100
TheStar.HandMainExtension.Ammo.tickIntervalInventory = 500
TheStar.HandMainExtension.Battery.tickInterval = 500
local lastTick = nil

local function tickIntervalCheck(tickInterval)
    local now = getTimeInMillis()
    if lastTick and (now - lastTick) < tickInterval then
        return false
    end
    lastTick = now
    return true
end

local handMainExtensionUI

local function initUI()
    if ISEquippedItem.instance then
        handMainExtensionUI = ISEquippedItem.instance.handMainExtensionUI
    end
end

local function hideUI()
    if handMainExtensionUI then
        handMainExtensionUI:setVisible(false)
    end
end

-- ****************
-- Ammo

local inventoryAmmoLastTick = nil
local inventoryAmmoCached = 0
local inventoryAmmoTooltipCached

local function getInventoryAmmoCount(player, item)
    local inventory = player:getInventory()
    local ammoType = item:getAmmoType()
    local bulletsCount = inventory:getCountTypeRecurse(ammoType)

    local tooltip = " <SIZE:medium> " .. getText("Tooltip_TheStar_AmmoCount") .. " <SIZE:small> <LINE> <LINE> "
    tooltip = tooltip .. getItemNameFromFullType(ammoType) .. ": " .. bulletsCount

    local magazineType = item:getMagazineType()
    if magazineType then
        local bulletsInMagazines = 0
        local magazineCount = inventory:getCountTypeRecurse(magazineType)
        local magazines = inventory:getAllTypeRecurse(magazineType)
        for i = 0, magazines:size() - 1 do
            local magazineItem = magazines:get(i)
            bulletsInMagazines = bulletsInMagazines + magazineItem:getCurrentAmmoCount()
        end
        if bulletsInMagazines > 0 then
            tooltip = tooltip .. " <LINE> " .. getItemNameFromFullType(magazineType) .. ": " .. magazineCount
            tooltip = tooltip .. " (" .. bulletsInMagazines .. ")"

            bulletsCount = bulletsCount + bulletsInMagazines
        end
    end

    local boxType = item:getAmmoBox()
    if boxType then
        local boxCount = 0
        boxCount = inventory:getCountTypeRecurse(boxType)
        if boxCount > 0 then
            local boxBulletsCount = 0
            local boxItem = inventory:getFirstTypeRecurse(boxType)
            local containers = ArrayList.new()
            for _, v in ipairs(getPlayerInventory(player:getPlayerNum()).inventoryPane.inventoryPage.backpacks) do
                containers:add(v.inventory)
            end
            local recipes = RecipeManager.getUniqueRecipeItems(boxItem, player, containers)
            for i = 0, recipes:size() - 1 do
                local recipe = recipes:get(i)
                if not recipe:isKeep(boxItem:getFullType()) then
                    local result = recipe:getResult()
                    local resultType = result:getFullType()
                    if resultType == ammoType then
                        local resultCount = result:getCount()
                        local resultItem = getScriptManager():getItem(resultType)

                        boxBulletsCount = resultCount * resultItem:getCount()
                        break
                    end
                end
            end
            if boxBulletsCount > 0 then
                tooltip = tooltip .. " <LINE> " .. boxItem:getDisplayName() .. ": " .. boxCount
                tooltip = tooltip .. " (" .. boxCount * boxBulletsCount .. ")"

                bulletsCount = bulletsCount + boxCount * boxBulletsCount
            end
        end
    end

    tooltip = tooltip .. " <LINE> <LINE> <SIZE:medium> " .. getText("Tooltip_TheStar_AmmoCount_Total", bulletsCount)

    return bulletsCount, tooltip
end

local function cacheInventoryAmmoCount(player, item)
    local now = getTimeInMillis()
    if inventoryAmmoLastTick and (now - inventoryAmmoLastTick) < TheStar.HandMainExtension.Ammo.tickIntervalInventory then
        return
    end
    inventoryAmmoLastTick = now
    inventoryAmmoCached, inventoryAmmoTooltipCached = getInventoryAmmoCount(player, item)
end

function TheStar.HandMainExtension.Ammo.checkAmmo(player, item)
  if player:getVariableBoolean("Bandit") then return end;
  if player:isZombie() then return end;
  if not player or not player:isLocalPlayer() then return end

  if item and TheStar.Utils.isRangedWeapon(item) and player:isLocalPlayer() then
      -- if TheStar.Options.showAmmoCountInventory then
      if TheStarB42.Options:getOption("showAmmoCountInventory"):getValue() then
          cacheInventoryAmmoCount(player, item)
      end

      local format = item:haveChamber() and "IGUI_TheStar_AmmoCountChambered" or "IGUI_TheStar_AmmoCount"
      local chamber = item:haveChamber() and (item:isRoundChambered() and "1" or "0")
      local text = getText(format, item:getCurrentAmmoCount(), item:getMaxAmmo(), chamber)
      -- if TheStar.Options.showAmmoCountInventory then
      if TheStarB42.Options:getOption("showAmmoCountInventory"):getValue() then
          text = text .. " (" .. inventoryAmmoCached .. ")"
      else
          inventoryAmmoTooltipCached = nil
      end
      local reload = item:getCurrentAmmoCount() == 0 and not item:isRoundChambered()

      -- UI가 nil이 아닌지 확인한 후 setText 호출
      if handMainExtensionUI then
          handMainExtensionUI:setText(text, inventoryAmmoTooltipCached)
          handMainExtensionUI:setVisible(true)
          handMainExtensionUI:setBlink(item:isJammed())
          handMainExtensionUI:setChangeBackground(reload)
      end

      -- Avoid duplicated updates
      lastTick = getTimeInMillis()
  end
end

function TheStar.HandMainExtension.Ammo.onTick()
    if tickIntervalCheck(TheStar.HandMainExtension.Ammo.tickInterval) then
        TheStar.HandMainExtension.Ammo.checkAmmo(getPlayer(), getPlayer():getPrimaryHandItem())
    end
end

function TheStar.HandMainExtension.Ammo.onEquipPrimary(player, item)
  -- print("onEquipPrimary called with:", player, item) -- 디버깅용 로그
  if player:getVariableBoolean("Bandit") then return end;
  if player:isZombie() then return end;
  if not player or not player:isLocalPlayer() then return end

  -- UI 초기화 확인
  if not handMainExtensionUI then
      -- print("Initializing UI...")
      initUI()
  end

  -- UI 객체가 nil인 경우 처리
  if handMainExtensionUI then
      handMainExtensionUI:setBlink(false)
      handMainExtensionUI:setChangeBackground(false)
  else
      -- print("handMainExtensionUI is nil")
      return
  end

  -- 아이템이 유효한지 확인
  if item and TheStar.Utils.isRangedWeapon(item) then
      -- print("Ranged weapon detected")
      inventoryAmmoLastTick = nil
      TheStar.HandMainExtension.Ammo.checkAmmo(player, item)
      Events.OnTick.Add(TheStar.HandMainExtension.Ammo.onTick)
      return
  end

  if not item or not TheStar.Utils.isLightSource(item) then
      -- print("Hiding UI")
      hideUI()
  end
  Events.OnTick.Remove(TheStar.HandMainExtension.Ammo.onTick)
end


function TheStar.HandMainExtension.Ammo.init()
    local player = getPlayer()
    if TheStar.Options.showAmmoCountEquippedItem then
        initUI()
        Events.OnEquipPrimary.Add(TheStar.HandMainExtension.Ammo.onEquipPrimary)
        Events.OnPlayerAttackFinished.Add(TheStar.HandMainExtension.Ammo.checkAmmo)
        --[[
        The OnEquipPrimary event will only be triggered for an item that has been equipped only after the save has loaded,
        therefore the notification will not be displayed for an item that has already been equipped.
        --]]
        if player then
            TheStar.HandMainExtension.Ammo.onEquipPrimary(player, player:getPrimaryHandItem())
        end
    else
        local item = player:getPrimaryHandItem()
        if item and TheStar.Utils.isRangedWeapon(item) then
            hideUI()
        end
        Events.OnEquipPrimary.Remove(TheStar.HandMainExtension.Ammo.onEquipPrimary)
        Events.OnPlayerAttackFinished.Remove(TheStar.HandMainExtension.Ammo.checkAmmo)
        Events.OnTick.Remove(TheStar.HandMainExtension.Ammo.onTick)
    end
end

-- ****************
-- Battery

local function getRemainingCharge(item)
    local dayLength = getSandboxOptions():getDayLengthMinutes() / 60
    local usePerMinute = 150 * dayLength / item:getTicksPerEquipUse()

    local minutesLeft = item:getCurrentUses() / usePerMinute * 1.25
    local hours = math.floor(minutesLeft / 60)
    local minutes = math.floor(minutesLeft % 60)
    return getText("Tooltip_TheStar_BatteryCharge", hours, minutes)
end

function TheStar.HandMainExtension.Battery.checkBattery(player, item)
    if item and TheStar.Utils.isLightSource(item) and player:isLocalPlayer() then
        local text = TheStar.Utils.round(item:getCurrentUsesFloat() * 100) .. "%"
        local tooltip = getRemainingCharge(item)
        handMainExtensionUI:setText(text, tooltip)
        handMainExtensionUI:setVisible(true)
        lastTick = getTimeInMillis()
    end
end

function TheStar.HandMainExtension.Battery.onTick()
    if tickIntervalCheck(TheStar.HandMainExtension.Battery.tickInterval) then
        TheStar.HandMainExtension.Battery.checkBattery(getPlayer(), getPlayer():getPrimaryHandItem())
    end
end

function TheStar.HandMainExtension.Battery.onEquipPrimary(player, item)
    if player:getVariableBoolean("Bandit") then return end;
    if player:isZombie() then return end;
    if not player or not player:isLocalPlayer() then return end

    if item and TheStar.Utils.isLightSource(item) then
        TheStar.HandMainExtension.Battery.checkBattery(player, item)
        Events.OnTick.Add(TheStar.HandMainExtension.Battery.onTick)
        return
    end

    if not item or not TheStar.Utils.isRangedWeapon(item) then
        hideUI()
    end
    Events.OnTick.Remove(TheStar.HandMainExtension.Battery.onTick)
end

function TheStar.HandMainExtension.Battery.init()
    local player = getPlayer()
    if TheStar.Options.showBatteryChargeEquippedItem then
        initUI()
        Events.OnEquipPrimary.Add(TheStar.HandMainExtension.Battery.onEquipPrimary)
        --[[
        The OnEquipPrimary event will only be triggered for an item that has been equipped only after the save has loaded,
        therefore the notification will not be displayed for an item that has already been equipped.
        --]]
        if player then
            TheStar.HandMainExtension.Battery.onEquipPrimary(player, player:getPrimaryHandItem())
        end
    else
        local item = player:getPrimaryHandItem()
        if item and TheStar.Utils.isLightSource(item) then
            hideUI()
        end
        Events.OnEquipPrimary.Remove(TheStar.HandMainExtension.Battery.onEquipPrimary)
        Events.OnTick.Remove(TheStar.HandMainExtension.Battery.onTick)
    end
end

function TheStar.HandMainExtension.init()
    TheStar.HandMainExtension.Ammo.init()
    TheStar.HandMainExtension.Battery.init()
end

local function onCreatePlayer(id)
    if getCore():isDedicated() then return end

    local player = getSpecificPlayer(id)
    if not player or not player:isLocalPlayer() then return end

    TheStar.HandMainExtension.init()
    Events.OnJoypadActivate.Add(initUI)
end

local function onPlayerDeath(player)
    if player:getVariableBoolean("Bandit") then return end;
    if player:isZombie() then return end;
    if not player or not player:isLocalPlayer() then return end

    hideUI()
    Events.OnJoypadActivate.Remove(initUI)
    -- Ammo
    Events.OnEquipPrimary.Remove(TheStar.HandMainExtension.Ammo.onEquipPrimary)
    Events.OnPlayerAttackFinished.Remove(TheStar.HandMainExtension.Ammo.checkAmmo)
    Events.OnTick.Remove(TheStar.HandMainExtension.Ammo.onTick)
    -- Battery
    Events.OnEquipPrimary.Remove(TheStar.HandMainExtension.Battery.onEquipPrimary)
    Events.OnTick.Remove(TheStar.HandMainExtension.Battery.onTick)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerDeath.Add(onPlayerDeath)
