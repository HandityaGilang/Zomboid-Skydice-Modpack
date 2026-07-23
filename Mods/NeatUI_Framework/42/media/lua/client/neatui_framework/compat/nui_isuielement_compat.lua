require "ISUI/ISUIElement"

-- Compatibility helpers for vanilla ISUIElement API drift across Build 42 versions.
-- Build 42.19 renamed the old getCentreX/getCentreY helpers and added several
-- American-spelling center helpers. Define only missing functions so vanilla
-- behavior remains untouched when the game already provides them.

if ISUIElement then
    if not ISUIElement.getCentreX then
        function ISUIElement:getCentreX()
            -- Preserve pre-42.19 semantics: local center inside the element.
            return self:getWidth() / 2.0
        end
    end

    if not ISUIElement.getCentreY then
        function ISUIElement:getCentreY()
            -- Preserve pre-42.19 semantics: local center inside the element.
            return self:getHeight() / 2.0
        end
    end

    if not ISUIElement.getSelfCenterX then
        function ISUIElement:getSelfCenterX()
            -- Match the Build 42.19 helper name when running on older builds.
            return self:getWidth() / 2.0
        end
    end

    if not ISUIElement.getSelfCenterY then
        function ISUIElement:getSelfCenterY()
            -- Y counterpart for local-center calculations on all supported builds.
            return self:getHeight() / 2.0
        end
    end

    if not ISUIElement.getCenterX then
        function ISUIElement:getCenterX()
            -- Match Build 42.19 semantics: center in the parent's coordinate space.
            return self:getX() + self:getWidth() / 2.0
        end
    end

    if not ISUIElement.getCenterY then
        function ISUIElement:getCenterY()
            -- Match Build 42.19 semantics: center in the parent's coordinate space.
            return self:getY() + self:getHeight() / 2.0
        end
    end

    if not ISUIElement.getAbsoluteCenterX then
        function ISUIElement:getAbsoluteCenterX()
            -- Match Build 42.19 semantics: center in screen/absolute coordinates.
            return self:getAbsoluteX() + self:getWidth() / 2.0
        end
    end

    if not ISUIElement.getAbsoluteCenterY then
        function ISUIElement:getAbsoluteCenterY()
            -- Match Build 42.19 semantics: center in screen/absolute coordinates.
            return self:getAbsoluteY() + self:getHeight() / 2.0
        end
    end

    if not ISUIElement.setCenterX then
        function ISUIElement:setCenterX(x)
            -- Position the element so its center X matches the provided coordinate.
            self:setX(x - self:getWidth() / 2.0)
        end
    end

    if not ISUIElement.setCenterY then
        function ISUIElement:setCenterY(y)
            -- Position the element so its center Y matches the provided coordinate.
            self:setY(y - self:getHeight() / 2.0)
        end
    end
end
