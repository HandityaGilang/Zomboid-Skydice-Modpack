----------------------------------------------------------------
-----  ▄▄▄   ▄    ▄   ▄  ▄▄▄▄▄   ▄▄▄   ▄   ▄   ▄▄▄    ▄▄▄  -----
----- █   ▀  █    █▄▄▄█    █    █   ▀  █▄▄▄█  ▀  ▄█  █ ▄▄▀ -----
----- █  ▀█  █      █      █    █   ▄  █   █  ▄   █  █   █ -----
-----  ▀▀▀▀  ▀▀▀▀   ▀      ▀     ▀▀▀   ▀   ▀   ▀▀▀   ▀   ▀ -----
----------------------------------------------------------------
--                                                            --
--   Project Zomboid Modding Commissions                      --
--   https://steamcommunity.com/id/glytch3r/myworkshopfiles   --
--                                                            --
--   ▫ Discord  ꞉   glytch3r                                  --
--   ▫ Support  ꞉   https://ko-fi.com/glytch3r                --
--   ▫ Youtube  ꞉   https://www.youtube.com/@glytch3r         --
--   ▫ Github   ꞉   https://github.com/Glytch3r               --
--                                                            --
----------------------------------------------------------------
----- ▄   ▄   ▄▄▄   ▄   ▄   ▄▄▄     ▄      ▄   ▄▄▄▄  ▄▄▄▄  -----
----- █   █  █   ▀  █   █  ▀   █    █      █      █  █▄  █ -----
----- ▄▀▀ █  █▀  ▄  █▀▀▀█  ▄   █    █    █▀▀▀█    █  ▄   █ -----
-----  ▀▀▀    ▀▀▀   ▀   ▀   ▀▀▀   ▀▀▀▀▀  ▀   ▀    ▀   ▀▀▀  -----
----------------------------------------------------------------


SurvivalBag = SurvivalBag or {}

-- this will half the chance every roll

--sample if you have 4 rollChances and your chance is set to 60
--if you started with 60 
--then next roll is 30
--then 15
--then 7.5




--how many books you might spawn 
SurvivalBag.rollChances = 3

-- if youre in debug mode then it will change the spawn chance to 100%
SurvivalBag.chance = 80


SurvivalBag.defaultItemToSpawn = "Base.BookNimble4"

-----------------------            ---------------------------
 --percent we decrease after each roll
SurvivalBag.decrementMultiplier = 50

-- i  could have just used float but i had to make this for you so you would better understand the setting

local function percentConvert(percent, num) 
    return num * (percent / 100)
end

function SurvivalBag.bookSpawner(bag)
	if not instanceof(bag, "InventoryContainer") then return end
	local itemCont = bag:getItemContainer()
	if not itemCont then return end

	local chance = math.min(100, math.max(0, SurvivalBag.chance))
	local curRate = chance
    local dec = SurvivalBag.decrementMultiplier
	for i = 1, SurvivalBag.rollChances do
		if SurvivalBag.doRoll(curRate) then
			local toSpawn = SurvivalBag.getBookToSpawn() or SurvivalBag.defaultItemToSpawn    
			local spawned = itemCont:AddItem(toSpawn)

			if spawned and getCore():getDebug() then  
				local fType = spawned:getFullType()
				print(fType.." Spawned by Glytch3r")
				spawned:setTooltip("SPAWNED by Glytch3r\nThis tooltip is for debug mode only")
				bag:setName('THE CODE 100% WORKS!')
			end
		end

		-- decrease nxt roll by whatever percent u set  SurvivalBag.decrementMultiplier
		curRate = percentConvert(dec, curRate)
        -- we do this to limit the thing from going below 0 or above 100
		curRate = math.min(100, math.max(0, curRate))
	end
end


-----------------------            ---------------------------


--[[ 
-function SurvivalBag.test()
-    local pl = getPlayer()
-    local inv = pl:getInventory()
-    local item = inv:AddItem("BookSneaking1")
-    return item
-end
-function SurvivalBag.spawn(pl)
-    pl = pl or getPlayer()
-    local x, y, z = round(pl:getX()),  round(pl:getY()),  pl:getZ() or 0
-    local zed = addZombiesInOutfit(x, y, z, 1, "Survivalist", 100, false, false, false, false, false, false, 2, false);
-
-    return zed
-end
 ]]

function SurvivalBag.init()
    if  getCore():getDebug() then 
        SurvivalBag.chance = 100
        print('DEBUG MODE DETECTED\nSurvivalBag.chance is set to: '..SurvivalBag.chance)
    --you have to comment this if you commented out the function cuz its calling a function that foesnt exist, that will cause error
    --[[ 
        local item = SurvivalBag.test() 
        if item then
            item:setTooltip("SPAWNED by Glytch3r")            
        end 
        ]]
        --SurvivalBag.spawn(pl)
    end   
end
Events.OnCreatePlayer.Add(SurvivalBag.init)

--use lowercase only these are the words that will get checked if the item contains that word as part of its fulltype 
--then it will not use that item to spawn the books
--sample "Base.KeyRing" -- it will actually get flagged twice cuz we blacklisted both key and ring
--instead of removing from the list i intentionally arranged it per line so that you can just choose to comment out what you want to re enable


SurvivalBag.blacklist = {
    
    "ammo",
    "box",
    "bullet",
    "carton",
    "case",
    "cigar",
    "cooler",
    "corpse",
    "fanny", 
    "holster",
    "key",
    "kid",
    "kit",
    "packet",
    "parcel",
    "pencil",
    "pocket",
    "present",
    "puch",
    "ring",
    "sack",
    "satchel",
    "sewing",
    "shell",
    "sling",
    "small",
    "strap",
    "tarp",
    "wallet",

}


--SurvivalBag.zedList = {   
--    ["Survivalist"] =true,
--    ["Survivalist02"] =true,
--    ["Survivalist03"] =true,
--	["Survivalist04"] =true,
--	["Survivalist05"] =true,
--	["Survivalist_Mid"] =true,
--	["Survivalist02_Mid"] =true,
--	["Survivalist03_Mid"] =true,
--	["Survivalist04_Mid"] =true,
--	["Survivalist05_Mid"] =true,
--	["Survivalist_Late"] =true,
--	["Survivalist02_Late"] =true,
--	["Survivalist03_Late"] =true,
--	["Survivalist04_Late"] =true,
--	["Survivalist05_Late"] =true,
--}




SurvivalBag.bookList = {
    "BookNimble1",
    "BookNimble2",
	"BookNimble3",
	"BookNimble4",
	"BookNimble5",
    "BookSneaking1",
	"BookSneaking2",
	"BookSneaking3",
	"BookSneaking4",
	"BookSneaking5",
    "BookLightfooted1",
	"BookLightfooted2",
	"BookLightfooted3",
	"BookLightfooted4",
	"BookLightfooted5",
    "BookSprinting1",
	"BookSprinting2",
	"BookSprinting3",
	"BookSprinting4",
	"BookSprinting5",
    "BookBlunt1",
	"BookBlunt2",
	"BookBlunt3",
	"BookBlunt4",
	"BookBlunt5",
	"BookSmallBlunt1",
	"BookSmallBlunt2",
	"BookSmallBlunt3",
	"BookSmallBlunt4",
	"BookSmallBlunt5",
	"BookSmallBlade1",
	"BookSmallBlade2",
	"BookSmallBlade3",
	"BookSmallBlade4",
	"BookSmallBlade5",
	"BookAxe1",
	"BookAxe2",
	"BookAxe3",
	"BookAxe4",
	"BookAxe5",
	"BookSpear1",
	"BookSpear2",
	"BookSpear3",
	"BookSpear4",
	"BookSpear5",
	"BookFitness1",
	"BookFitness2",
	"BookFitness3",
	"BookFitness4",
	"BookFitness5",
	"BookStrength1",
	"BookStrength2",
	"BookStrength3",
	"BookStrength4",
	"BookStrength5",
}


-----------------------         ---------------------------


function SurvivalBag.getBookToSpawn()   
    local items = SurvivalBag.bookList
    local toSpawn = items[ZombRand(1, #items + 1)]
    return toSpawn
end

function SurvivalBag.doRoll(percent)
    --if getCore():getDebug() then return true end
    if percent <= 0 then return false end
    if percent >= 100 then return true end
    return percent >= ZombRand(1, 101)
end

--backup incase you want to revert to old version
--[[ 
function SurvivalBag.bookSpawner(bag)
    if not SurvivalBag.doRoll(SurvivalBag.chance) then        
        return
    end
    local toSpawn = SurvivalBag.getBookToSpawn() or SurvivalBag.defaultItemToSpawn    
    if instanceof(bag, "InventoryContainer") then
        local itemCont = bag:getItemContainer()
        if itemCont then
            local spawned = itemCont:AddItem(toSpawn)
            local fType =  spawned:getFullType()
            if getCore():getDebug() then  
                print(fType.." Spawned by Glytch3r")
                spawned:setTooltip("SPAWNED by Glytch3r\nThis tooltip is for debug mode only")
                bag:setName('THE CODE 100% WORKS!')
            end
        end     
    end
end ]]
-----------------------            ---------------------------
--uses SurvivalBag.blacklist to check workds if its there 
--add and remove stuff from that list
function SurvivalBag.isBlacklisted(fType)
    if not fType or fType == "" then return false end
    fType = string.lower(tostring(fType))
    for _, ban in ipairs(SurvivalBag.blacklist) do
        if string.find(fType, ban, 1, true) then
            return true
        end
    end
    return false
end

-- this function basically checks the zed if the outfit has the word surviv in it
-- then iot will check if it has a bag 
-- Type = Container,
-- then check if its fulltype is blacklisted 
function SurvivalBag.survivalistDeath(zed)
    if not zed or instanceof(zed, "IsoPlayer") then return end
    local inv = zed:getInventory()
    if not inv then return end
    local fit = zed:getOutfitName() 
    if not fit then return end
    fit = string.lower(tostring(fit))

    local bag = nil
    if string.find(fit, "surviv") ~= nil then
        local bags = inv:getItemsFromCategory("Container")
        for j=1, bags:size() do
            local item = bags:get(j-1)
            local fType = item and item:getFullType()
            if fType and not SurvivalBag.isBlacklisted(fType) then
                bag = item
                break
            end
        end
    end

    if bag then
        SurvivalBag.bookSpawner(bag)
    end
end

Events.OnCharacterDeath.Add(SurvivalBag.survivalistDeath)