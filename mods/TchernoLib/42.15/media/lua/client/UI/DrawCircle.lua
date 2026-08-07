require 'luautils'

function luautils.renderIsoCircle(playerNum, posX, posY, posZ, ray, r, g, b, a)
    local angularStep =  0.1163552834662886D;--todo make this a parameter
    local northing =     1.0471975511965977D

    local mask = luautils.getScreenMask(playerNum)
    
    local nbSteps = 0 
    local nbStepsDisplayed= 0
    for angularIter = 0, 6.283185307179586D, angularStep do--from 0 to 2 PI
        local xStart = posX + ray * Math.cos(-northing + angularIter);
        local yStart = posY + ray * Math.sin(-northing + angularIter);
        local xEnd   = posX + ray * Math.cos(-northing + angularIter + angularStep);
        local yEnd   = posY + ray * Math.sin(-northing + angularIter + angularStep);
        nbSteps = nbSteps + 1
        
        --display only if the line cross the screen
        local xScreen1  = isoToScreenX(playerNum, xStart, yStart, posZ);
        local yScreen1  = isoToScreenY(playerNum, xStart, yStart, posZ);
        local xScreen2  = isoToScreenX(playerNum, xEnd  , yEnd  , posZ);
        local yScreen2  = isoToScreenY(playerNum, xEnd  , yEnd  , posZ);
        
        local hide = false
        if mask then
            hide, xScreen1, yScreen1, xScreen2, yScreen2 = luautils.applyMask(xScreen1, yScreen1, xScreen2, yScreen2, mask)
        end
        
        if not hide then
            nbStepsDisplayed = nbStepsDisplayed + 1
            local angle = angularIter + angularStep / 2.
            luautils.drawLine2(xScreen1, yScreen1, xScreen2, yScreen2, a, r, g, b, angle, 2)
        end
    end
    
    if luautils.Verbose and nbStepsDisplayed > 0 then print("luautils.renderIsoCircle "..nbStepsDisplayed..'/'..nbSteps..' at '..posX..' '..posY..' '..posZ) end
end

function luautils.drawLine2( x, y, x2, y2, a, r, g, b, angle, thick)
    if thick == nil then thick = 2 end
    if thick < 0 then thick = 0 end
    local thickX = thick
    local thickY = thick
    if angle and thick > 0 then
        thickX = thick * Math.cos(angle)
        thickY = thick * Math.sin(angle)
    end
    getRenderer():render(nil, x-thickX, y-thickY, x+thickX, y+thickY, x2+thickX, y2+thickY, x2-thickX, y2-thickY, r, g, b, a, r, g, b, a, r, g, b, a, r, g, b, a, nil);
end

function luautils.applyMask(xScreen1, yScreen1, xScreen2, yScreen2, mask)
    local hide = false
    if mask then
        local point1 = {x=xScreen1,y=yScreen1}
        local point2 = {x=xScreen2,y=yScreen2}
        local p1In = Sh.isPointInQuadrilateral(point1, mask.x1, mask.x2, mask.y1, mask.y2)
        local p2In = Sh.isPointInQuadrilateral(point2, mask.x1, mask.x2, mask.y1, mask.y2)
        if not p1In and not p2In then--look for intersection anyway
            local newPoint2 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y1}, {x=mask.x1,y=mask.y2})
            local newPoint1 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y1}, {x=mask.x2,y=mask.y1})
            if not newPoint2 then
                newPoint2 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y2}, {x=mask.x2,y=mask.y2})
            elseif not newPoint1 then
                newPoint1 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y2}, {x=mask.x2,y=mask.y2})
            end
            if not newPoint2 then
                newPoint2 = Sh.get_line_intersection(point1, point2, {x=mask.x2,y=mask.y1}, {x=mask.x2,y=mask.y2})
            elseif not newPoint1 then
                newPoint1 = Sh.get_line_intersection(point1, point2, {x=mask.x2,y=mask.y1}, {x=mask.x2,y=mask.y2})
            end
            if newPoint2 and newPoint1 then
                xScreen2 = newPoint2.x;
                yScreen2 = newPoint2.y;
                xScreen1 = newPoint1.x;
                yScreen1 = newPoint1.y;
            else
                hide = true
            end
        elseif p1In and not p2In then
            local newPoint2 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y1}, {x=mask.x1,y=mask.y2})
            if not newPoint2 then newPoint2 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y1}, {x=mask.x2,y=mask.y1}) end
            if not newPoint2 then newPoint2 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y2}, {x=mask.x2,y=mask.y2}) end
            if not newPoint2 then newPoint2 = Sh.get_line_intersection(point1, point2, {x=mask.x2,y=mask.y1}, {x=mask.x2,y=mask.y2}) end
            if newPoint2 then
                xScreen2 = newPoint2.x;
                yScreen2 = newPoint2.y;
            else
                hide = true
            end
        elseif not p1In and p2In then
            local newPoint1 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y1}, {x=mask.x1,y=mask.y2})
            if not newPoint1 then newPoint1 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y1}, {x=mask.x2,y=mask.y1}) end
            if not newPoint1 then newPoint1 = Sh.get_line_intersection(point1, point2, {x=mask.x1,y=mask.y2}, {x=mask.x2,y=mask.y2}) end
            if not newPoint1 then newPoint1 = Sh.get_line_intersection(point1, point2, {x=mask.x2,y=mask.y1}, {x=mask.x2,y=mask.y2}) end
            if newPoint1 then
                xScreen1 = newPoint1.x;
                yScreen1 = newPoint1.y;
            else
                hide = true
            end
        end
    end
    
    return hide, xScreen1, yScreen1, xScreen2, yScreen2
end

function luautils.getScreenMask(playerNum)
    return {x1=getPlayerScreenLeft(playerNum), x2=getPlayerScreenLeft(playerNum)+getPlayerScreenWidth(playerNum), y1=getPlayerScreenTop(playerNum), y2=getPlayerScreenTop(playerNum)+getPlayerScreenHeight(playerNum)}
end
