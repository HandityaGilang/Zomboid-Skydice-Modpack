-- ************************************************************************
-- **                  ██  ██    ██ ██ ████████  █████                   **
-- **                ████  ██    ██ ██    ██   ██   ██                   **
-- **              ██  ██  ██    ██ ██    ██   ███████                   **
-- **                  ██   ██  ██  ██    ██   ██   ██                   **
-- **                  ██    ████   ██    ██   ██   ██                   **
-- **                https://steamcommunity.com/id/1vita                 **
-- ************************************************************************
-- **        The following content was crafted from the ground up,       **
-- **       writing my own lines, but also taking inspiration from       **
-- **       others' work to better understand the game's workflow.       **
-- **                So, as it should be with every mod,                 **
-- **                   >>> USE IT AS YOU PLEASE <<<                     **
-- ************************************************************************
-- **            Let's make Project Zomboid greater togheter!            **
-- ************************************************************************
-- **      This class was ported from ISEquippedItem using ChatGPT       **
-- ************************************************************************

require "ISUI/ISPanel"
require "ISUI/ISImage"
require "ISUI/ISLabel"

---@class VB_CS_GunStatsPanel : ISPanel
---@field instance VB_CS_GunStatsPanel?
---@field background boolean
---@field border boolean
---@field player IsoPlayer
---@field backgroundTex Texture
---@field alpha number
---@field supportedAmmoList supportedAmmoType[]
VB_CS_GunStatsPanel = ISPanel:derive("VB_CS_GunStatsPanel")

local STATIC_SCREEN_WIDTH = getCore():getScreenWidth()
local compatify = false
local compatifyIDs = { "Advanced_Trajectorys_Realistic_Overhaul" }

---@param v integer
---@return integer
local function adjustPixelsForResolution(v)
    return math.ceil(v * STATIC_SCREEN_WIDTH / 1920)
end

---@return Texture
local function getBackgroundTexture()
    if STATIC_SCREEN_WIDTH == 3840 then
        return getTexture("media/ui/falo_3840.png")
    elseif STATIC_SCREEN_WIDTH == 2560 then
        return getTexture("media/ui/falo_2560.png")
    else
        return getTexture("media/ui/falo_1920.png")
    end
end

---@param gun HandWeapon
local function onGunJammed(gun)
    local mainHand = ISEquippedItem.instance and ISEquippedItem.instance.mainHand
    if not mainHand then return end
    local a = mainHand.backgroundColor.a
    if gun:isJammed() then
        mainHand.background = true
        mainHand.backgroundColor = {r=1,g=0,b=0,a=a}
    else
        mainHand.background = false
        mainHand.backgroundColor = {r=1,g=1,b=1,a=a}
    end
end

---@return supportedAmmoType[]
local function fetchAllAmmoTypes()
    local allScriptItems = getScriptManager():getAllItems()
    local ammoWordBlacklist = { "Box", "Carton", "Clip", "Mold", }
    local supportedAmmoList = {}

    for i = 0, allScriptItems:size()-1 do
        local scriptItem = allScriptItems:get(i)
        local itemName = scriptItem:getFullName()

        if scriptItem:getItemType() == ItemType.NORMAL and scriptItem:getDisplayCategory() == "Ammo" then
            local invalid = false
            for _, blockedWord in ipairs(ammoWordBlacklist) do
                if string.find(itemName, blockedWord) then
                    invalid = true
                end
            end

            if not invalid then
                local textureData = scriptItem:getNormalTexture()
                local texture = nil

                if textureData then
                    local texName = textureData:getName()
                    if texName then
                        local textureString = tostring(textureData)
                        local pattern = "name:\"(.*)\""
                        local match = string.match(textureString, pattern)
                        if match then
                            texName = match:sub(1, -1)
                        end
                    end
                
                    texture = getTexture(texName)
                end

                local ammo = { type = itemName, texture = texture } --[[@class supportedAmmoType]]
                table.insert(supportedAmmoList, ammo)
            end
        end
    end
    return supportedAmmoList
end

---@param gun HandWeapon
function VB_CS_GunStatsPanel:updateAmmoTexture(gun)
    local tex = getTexture("Item_PistolAmmo")
    local ammoType = gun:getAmmoType():getItemKey()

    for _, ammo in ipairs(self.supportedAmmoList) do
        if ammo.type == ammoType then
            tex = ammo.texture or tex
            break
        end
    end
    self.ammoImage.texture = tex
end

---@param gun HandWeapon
---@return integer
function VB_CS_GunStatsPanel:getRemainingAmmoCount(gun)
    local inv = self.player:getInventory()
    local total = 0
    local magType = gun:getMagazineType()

    if magType then
        local items = inv:getItemsFromFullType(magType)
        for i = 0, items:size()-1 do
            local mag = items:get(i)
            if mag then total = total + mag:getCurrentAmmoCount() end
        end
    else
        local items = inv:getItemsFromFullType(gun:getAmmoType():getItemKey())
        if items then total = items:size() end
    end

    return total
end

---@param gun HandWeapon
function VB_CS_GunStatsPanel:updateAmmoCount(gun)
    local count = gun:getCurrentAmmoCount() or 0
    local chamber = gun:isRoundChambered() and 1 or 0
    local max = gun:getMaxAmmo() or 0

    self.loadedAmmoLabel:setName(string.format("%02d+%d/%d",count,chamber,max))

    local remaining = self:getRemainingAmmoCount(gun)
    self.remainingAmmoLabel:setName("("..remaining..")")

    local p = max > 0 and (count+chamber)/max or 0

    if p > .5 then
        self.loadedAmmoLabel:setColor(1,1,1)
    elseif p > .25 then
        self.loadedAmmoLabel:setColor(1,1,0)
    elseif p > 0 then
        self.loadedAmmoLabel:setColor(1,0,0)
    else
        self.loadedAmmoLabel:setColor(.7,0,0)
    end
    
    local m = remaining / max

    if m > 4 then
        self.remainingAmmoLabel:setColor(1,1,1)
    elseif m > 2 then
        self.remainingAmmoLabel:setColor(1,1,0)
    elseif m > 0 then
        self.remainingAmmoLabel:setColor(1,0,0)
    else
        self.remainingAmmoLabel:setColor(.7,0,0)
    end
end

function VB_CS_GunStatsPanel:updateChildrenPos()
    local s = adjustPixelsForResolution
    local x = 0 --[[@as number]]
    local y = 0 --[[@as number]]
    local m = 0 --margin
    local ammoTexWidth = self.ammoImage.texture 
        and self.ammoImage.texture:getWidth()
        or s(30)
    
    m = s(8)
    x = s(20)
    y = s(6)
    self.ammoImage:setX(x + m)
    self.ammoImage:setY(y)

    m = s(15)
    x = self.ammoImage.x + self.ammoImage.width + ammoTexWidth + m
    y = -s(9)
    self.loadedAmmoLabel:setX(x)
    self.loadedAmmoLabel:setY(y)

    m = s(10)
    x = self.loadedAmmoLabel.x + self.loadedAmmoLabel.width + m
    y = -s(9)
    self.remainingAmmoLabel:setX(x)
    self.remainingAmmoLabel:setY(y)
end

function VB_CS_GunStatsPanel:update()
    if not SandboxVars.CommonSense.GunStats or compatify then return end
    local gun = self.player:getPrimaryHandItem() --[[@as HandWeapon]]
    local mainHandVisible = ISEquippedItem.instance 
        and ISEquippedItem.instance:isVisible()
        and ISEquippedItem.instance.mainHand:isVisible()
    local showGunStats = gun and gun:IsWeapon() and gun:isRanged() and gun:getAmmoType()

    if mainHandVisible and showGunStats then
        onGunJammed(gun)
        self.backgroundImage.texture = self.backgroundTex
        self:updateAmmoTexture(gun)
        self:updateAmmoCount(gun)
        self:updateChildrenPos()
        self:setVisible(true)
    else
        self:setVisible(false)
    end
    ISPanel.update(self)
end

function VB_CS_GunStatsPanel:prerender()
    ISPanel.prerender(self)
end

function VB_CS_GunStatsPanel:initialise()

    local a = self.alpha
    local labelH = adjustPixelsForResolution(64)

    self.backgroundImage = ISImage:new(0,0,0,0,nil)
    self.backgroundImage.backgroundColor = {r=1,g=1,b=1,a=a}
    self.backgroundImage:initialise()
    self:addChild(self.backgroundImage)

    self.ammoImage = ISImage:new(0,0,0,0,nil)
    self.ammoImage.backgroundColor = {r=1,g=1,b=1,a=a}
    self.ammoImage:initialise()
    self:addChild(self.ammoImage)

    self.loadedAmmoLabel = ISLabel:new(
        0,0,labelH,"",
        1,1,1,a,
        UIFont.Medium,true
    )
    self.loadedAmmoLabel:initialise()
    self:addChild(self.loadedAmmoLabel)

    self.remainingAmmoLabel = ISLabel:new(
        0,0,labelH,"",
        1,1,1,a,
        UIFont.Medium,true
    )
    self.remainingAmmoLabel:initialise()
    self:addChild(self.remainingAmmoLabel)

    ISPanel.initialise(self)
end

--- Use [.create] to instantiate and initialise the UI
function VB_CS_GunStatsPanel:new()

    local x,y,w,h = 0,0,0,0
    
    local mh = ISEquippedItem.instance and ISEquippedItem.instance.mainHand
    if mh then
        ---@diagnostic disable: assign-type-mismatch
        x = mh:getX() + math.floor(mh:getWidth()/2) + 15
        y = mh:getY() + 12
        w = 0
        h = mh:getHeight()
    end
    
    ---@diagnostic disable: inject-field
    local o = ISPanel.new(self,x,y,w,h) --[[@as VB_CS_GunStatsPanel]]
    o.background = false
    o.backgroundTex = getBackgroundTexture()
    o.border = false
    o.alpha = .9
    o.player = getPlayer()
    o.supportedAmmoList = fetchAllAmmoTypes()
    return o
end

function VB_CS_GunStatsPanel.create()
    if not SandboxVars.CommonSense.GunStats or compatify then return end
    if VB_CS_GunStatsPanel.instance then
        VB_CS_GunStatsPanel.instance:removeFromUIManager()
        VB_CS_GunStatsPanel.instance:clearChildren()
    end
    VB_CS_GunStatsPanel.instance = VB_CS_GunStatsPanel:new()
    VB_CS_GunStatsPanel.instance:initialise()
    VB_CS_GunStatsPanel.instance:addToUIManager()
end

Events.OnInitGlobalModData.Add(function()
    compatify = BB_CS_Utils.needToCompatify(compatifyIDs)
end)
Events.OnGameStart.Add(VB_CS_GunStatsPanel.create)
Events.OnEquipPrimary.Add(function()
    if VB_CS_GunStatsPanel.instance then
        VB_CS_GunStatsPanel.instance:update() -- for faster update
    end
end)