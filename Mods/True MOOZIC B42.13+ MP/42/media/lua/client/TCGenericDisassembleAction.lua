-- TM - Unstable Addons: Generic Item Disassembly Action
-- Universal disassembly for ANY cassette or vinyl regardless of module

require "TimedActions/ISBaseTimedAction"
pcall(function() require "TCCassetteDisassembleLoot" end)

TCGenericDisassembleAction = ISBaseTimedAction:derive("TCGenericDisassembleAction")

local DEBUG = false
local function dlog(msg)
    if DEBUG then
        print(msg)
    end
end

local function stopDevicePlayback(player, item)
    if not item or not item.getModData then return end
    local md = item:getModData()
    if not md or not md.tcmusic then return end

    -- Mark device as not playing and turn it off.
    md.tcmusic.isPlaying = false
    if item.getDeviceData and item:getDeviceData() and item:getDeviceData().setIsTurnedOn then
        item:getDeviceData():setIsTurnedOn(false)
    end

    -- Stop local player emitter (inventory devices).
    if player and player.getEmitter and player.getModData then
        local pmd = player:getModData()
        if pmd and pmd.tcmusicid then
            player:getEmitter():stopSound(pmd.tcmusicid)
            pmd.tcmusicid = nil
        end
    end

    -- Clear global now_play entry so other clients stop hearing it.
    local musicId = nil
    if player then
        if isClient() and player.getOnlineID then
            musicId = tostring(player:getOnlineID())
        elseif player.getUsername then
            musicId = tostring(player:getUsername())
        end
    end
    if musicId then
        local trueMusicData = ModData.getOrCreate("trueMusicData")
        if trueMusicData and trueMusicData["now_play"] then
            trueMusicData["now_play"][musicId] = nil
        end
        if isClient() then
            ModData.transmit("trueMusicData")
        end
    end

    if item.transmitModData then
        item:transmitModData()
    end
end

function TCGenericDisassembleAction:isValid()
    return self.item and self.player:getInventory():contains(self.item)
end

function TCGenericDisassembleAction:start()
    self:setActionAnim("Loot")
    self.item:setJobType(getText("Disassembling"))
    self.item:setJobDelta(0.0)
    -- Stop any playback immediately when disassembly starts (prevents shove-cancel trick).
    stopDevicePlayback(self.character, self.item)
    self.soundName = "Dismantle"
    self.soundId = nil
    if self.character and self.character.playSound then
        self.soundId = self.character:playSound(self.soundName)
    end
    if self.character then
        if ISRadioWindow and ISRadioWindow.closeIfActive then
            ISRadioWindow.closeIfActive(self.character, self.item)
        end
        if ISTCBoomboxWindow and ISTCBoomboxWindow.closeIfActive then
            ISTCBoomboxWindow.closeIfActive(self.character, self.item)
        end
    end
end

function TCGenericDisassembleAction:stop()
    ISBaseTimedAction.stop(self)
    self.item:setJobDelta(0.0)
    if self.soundId and self.character and self.character.getEmitter then
        self.character:getEmitter():stopOrTriggerSound(self.soundId)
        self.soundId = nil
    end
    if self.character then
        if ISRadioWindow and ISRadioWindow.closeIfActive then
            ISRadioWindow.closeIfActive(self.character, self.item)
        end
        if ISTCBoomboxWindow and ISTCBoomboxWindow.closeIfActive then
            ISTCBoomboxWindow.closeIfActive(self.character, self.item)
        end
    end
end

function TCGenericDisassembleAction:perform()
    ISBaseTimedAction.perform(self)
    if self.soundId and self.character and self.character.getEmitter then
        self.character:getEmitter():stopOrTriggerSound(self.soundId)
        self.soundId = nil
    end
    
    local player = self.player
    local inventory = player:getInventory()
    if ISRadioWindow and ISRadioWindow.closeIfActive then
        ISRadioWindow.closeIfActive(player, self.item)
    end
    if ISTCBoomboxWindow and ISTCBoomboxWindow.closeIfActive then
        ISTCBoomboxWindow.closeIfActive(player, self.item)
    end
    -- If this is a multiplayer client, delegate authoritative changes to server
    if isClient() and not isServer() then
        if self.item and self.item.getID and self.item.getFullType and self.item.getType then
            sendClientCommand("TCCassetteDisassemble", "PerformDisassemble", { itemID = self.item:getID(), fullType = self.item:getFullType(), itemType = self.item:getType() })
            -- Attempt to remove the item locally from hands/inventory so it doesn't remain stuck in the player's hand.
            -- Use safe checks because on clients some inventory operations may not be authoritative.
            local inv = player and player.getInventory and player:getInventory()
            -- If the item is currently held in primary/secondary hand, clear those references if possible.
            if player and player.getPrimaryHandItem and player.setPrimaryHandItem then
                local primary = player:getPrimaryHandItem()
                if primary and primary == self.item then
                    player:setPrimaryHandItem(nil)
                end
            end

            if inv and inv.contains and inv:contains(self.item) and inv.Remove then
                inv:Remove(self.item)
            end
            self.item:setJobDelta(0.0)
            return
        else
            dlog("[TM Unstable Addons] ERROR: Cannot send disassemble command; item missing identification methods")
        end
    end

    -- Singleplayer path: handle failure/XP/loot locally
    local itemType = self.item.getType and self.item:getType() or nil
    local isElectronics = (itemType and (itemType:find("TCWalkman", 1, true) or itemType:find("TCBoombox", 1, true) or itemType:find("TCVinylplayer", 1, true))) or false

    -- Auto-eject media before disassembly (SP convenience)
    if self.item and itemType and (itemType:find("TCWalkman", 1, true) or itemType:find("TCBoombox", 1, true) or itemType:find("TCVinylplayer", 1, true)) then
        if TCCassetteDisassembleLoot and TCCassetteDisassembleLoot.DeviceHasMedia and TCCassetteDisassembleLoot.ReturnMediaToInventory then
            if TCCassetteDisassembleLoot.DeviceHasMedia(self.item) then
                TCCassetteDisassembleLoot.ReturnMediaToInventory(player, self.item)
            end
        end
    end

    -- Remove the item being disassembled (authoritative in SP)
    inventory:Remove(self.item)
    if TCCassetteDisassembleLoot and TCCassetteDisassembleLoot.AwardDisassemblyXP then
        TCCassetteDisassembleLoot.AwardDisassemblyXP(player, isElectronics)
    end
    if TCCassetteDisassembleLoot and TCCassetteDisassembleLoot.ApplyDisassemblyLoot then
        TCCassetteDisassembleLoot.ApplyDisassemblyLoot(player, self.item)
    end
    
    self.item:setJobDelta(0.0)
end

function TCGenericDisassembleAction:update()
    self.item:setJobDelta(self:getJobDelta())
    if self.soundId and self.character and self.character.getEmitter then
        local emitter = self.character:getEmitter()
        if emitter and not emitter:isPlaying(self.soundId) and self.character.playSound and self.soundName then
            self.soundId = self.character:playSound(self.soundName)
        end
    end
end

function TCGenericDisassembleAction:hasNearbyPlayers()
    if not isClient() and not isServer() then
        return false
    end
    
    local playerSquare = self.player:getSquare()
    if not playerSquare then return false end
    
    local playerRoom = playerSquare:getRoom()
    local playerX = self.player:getX()
    local playerY = self.player:getY()
    
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers then return false end
    
    for i = 0, onlinePlayers:size() - 1 do
        local otherPlayer = onlinePlayers:get(i)
        if otherPlayer ~= self.player then
            local otherSquare = otherPlayer:getSquare()
            if otherSquare then
                local otherRoom = otherSquare:getRoom()
                if playerRoom == otherRoom or (not playerRoom and not otherRoom) then
                    local distance = math.abs(otherPlayer:getX() - playerX) + math.abs(otherPlayer:getY() - playerY)
                    if distance <= 7 then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

function TCGenericDisassembleAction:new(player, item, time)
    local o = ISBaseTimedAction.new(self, player)
    o.player = player
    o.character = player
    o.item = item
    o.stopOnWalk = true
    o.stopOnRun = true
    -- TimedAction units: ~60 = 1 real second. Use ~5s base (300) if not supplied.
    o.maxTime = time or 300
    return o
end
