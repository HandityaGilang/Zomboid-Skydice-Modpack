local TABAS_ISPlace3DItemCursor = {}

local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")

function TABAS_ISPlace3DItemCursor.apply()
    if TABAS_ISPlace3DItemCursor._applied then return end
    TABAS_ISPlace3DItemCursor._applied = true

    if not ISPlace3DItemCursor or ISPlace3DItemCursor.tabas_BathWrapped then
        return
    end

    ISPlace3DItemCursor.tabas_BathWrapped = true

    local old_isValid = ISPlace3DItemCursor.isValid
    function ISPlace3DItemCursor:isValid(square)
        if not square or not self.chr then
            return old_isValid and old_isValid(self, square) or false
        end

        if not self.previousSq then
            self.previousSq = square
        end
        if self.previousSq ~= square then
            self.previousSq = square
            self.surfaceSelected = 1
        end

        local isBathing = TABAS_BathingUtils.isTakingBath(self.chr)

        if (not isBathing)
        and self.chr:getCharacterActions():isEmpty()
        and not self.chr:isSittingOnFurniture() then
            self.chr:faceLocation(square:getX(), square:getY())
        end

        if not luautils.walkAdjTest(self.chr, square) then
            return false
        end

        local totalWeight = 0
        if self.placeAll then
            for _,item in ipairs(self.items) do
                totalWeight = totalWeight + item:getUnequippedWeight()
            end
        else
            local item = self.items[1]
            totalWeight = totalWeight + item:getUnequippedWeight()
        end

        if square:getTotalWeightOfItemsOnFloor() + totalWeight >= 50 then
            return false
        end
        if not square:isCouldSee(self.chr:getPlayerNum()) then
            return false
        end
        if square:isWallTo(self.chr:getCurrentSquare()) or square:isWindowTo(self.chr:getCurrentSquare()) then
            return false
        end

        local surface = self:getSurface(square)
        if (surface == 0) and (square:isSolid() or square:isSolidTrans() or not square:TreatAsSolidFloor()) then
            return false
        end
        return true
    end

    local old_render = ISPlace3DItemCursor.render
    function ISPlace3DItemCursor:render(x, y, z, square)
        if not square or not self:isValid(square) then
            self:getFloorCursorSprite():RenderGhostTileColor(x, y, z, 1.0, 0.0, 0.0, 0.2)

            if self.chr and not TABAS_BathingUtils.isTakingBath(self.chr) then
                self.chr:setIgnoreMovement(false)
            end
            return
        end

        self:getFloorCursorSprite():RenderGhostTileColor(x, y, z, 1.0, 1.0, 1.0, 0.2)
    end

    local old_deactivate = ISPlace3DItemCursor.deactivate
    function ISPlace3DItemCursor:deactivate()
        if self.chr and not TABAS_BathingUtils.isTakingBath(self.chr) then
            self.chr:setIgnoreMovement(false)
        end

        if old_deactivate then
            return old_deactivate(self)
        end
        return ISBuildingObject.deactivate(self)
    end
end

return TABAS_ISPlace3DItemCursor
