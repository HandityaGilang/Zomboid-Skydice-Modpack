-- From "Snowman" mod -- Author = carlesturo

Melt_Snowman = Melt_Snowman or {}
Melt_Snowman.snowmen = Melt_Snowman.snowmen or {}

local meltMap = {
    ["snowman_01_0"] = "snowman_01_4",
    ["snowman_01_1"] = "snowman_01_5",
    ["snowman_01_2"] = "snowman_01_6",
    ["snowman_01_3"] = "snowman_01_7",

    ["snowman_01_4"] = true,
    ["snowman_01_5"] = true,
    ["snowman_01_6"] = true,
    ["snowman_01_7"] = true
}

function Melt_Snowman.getSnowStage()
    local cm = getClimateManager()
    if not cm then return "none" end

    local snowStrength = cm:getSnowStrength()
    local frac = snowStrength > 7.5 and 1.0 or snowStrength / 7.5

    if frac <= 0.0 then
        return "none"
    elseif frac > 0.2 then
        return "snow"
    else
        return "melt"
    end
end

function Melt_Snowman.registerSnowman(obj)
    if not obj or not obj:getSprite() then return end
    local spriteName = obj:getSprite():getName()
    if not meltMap[spriteName] then return end

    Melt_Snowman.snowmen[obj] = true
end

Events.OnObjectAdded.Add(function(obj)
    Melt_Snowman.registerSnowman(obj)
end)

Events.EveryHours.Add(function()
    local stage = Melt_Snowman.getSnowStage()
    for obj in pairs(Melt_Snowman.snowmen) do
        if not obj or obj:isDestroyed() then
			Melt_Snowman.snowmen[obj] = nil
        else
            local square = obj:getSquare()
            if stage == "none" and SandboxVars and SandboxVars.Snowman and SandboxVars.Snowman.Melt then
                local container = obj:getContainer()
                if container then
                    local items = container:getItems()
                    for i = items:size()-1, 0, -1 do
                        local item = items:get(i)
                        if item then
                            square:AddWorldInventoryItem(item, 0.0, 0.0, 0.0)
                        end
                    end
                end
                square:transmitRemoveItemFromSquare(obj)
				Melt_Snowman.snowmen[obj] = nil

				for i=0, getNumActivePlayers()-1 do
					local player = getSpecificPlayer(i)
					if player and getPlayerInventory and getPlayerLoot then
						local invPage = getPlayerInventory(player:getPlayerNum())
						local lootPage = getPlayerLoot(player:getPlayerNum())
						if invPage then invPage:refreshBackpacks() end
						if lootPage then lootPage:refreshBackpacks() end
					end
				end
            -- elseif stage == "melt" then
            end
            -- stage == "snow"
        end
    end
end)

function Melt_Snowman.RemoveSnowman(square)
    if not square then return end

    local objects = square:getObjects()
    if not objects then return end

    local stage = Melt_Snowman.getSnowStage()

    for i=0, objects:size()-1 do
        local obj = objects:get(i)
        if obj and obj:getSprite() then
            local spriteName = obj:getSprite():getName()
			if spriteName and meltMap[spriteName] then
				Melt_Snowman.registerSnowman(obj)

				if stage == "none" and SandboxVars and SandboxVars.Snowman and SandboxVars.Snowman.Melt then
					local container = obj:getContainer()
					if container then
						local items = container:getItems()
						for j = items:size()-1, 0, -1 do
							local item = items:get(j)
							if item then
								square:AddWorldInventoryItem(item, 0.0, 0.0, 0.0)
							end
						end
					end
					square:transmitRemoveItemFromSquare(obj)
					Melt_Snowman.snowmen[obj] = nil
				end
			end
        end
    end
end
Events.LoadGridsquare.Add(Melt_Snowman.RemoveSnowman)