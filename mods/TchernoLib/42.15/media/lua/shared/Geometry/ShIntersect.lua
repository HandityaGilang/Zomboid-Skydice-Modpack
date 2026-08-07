Sh = Sh or {}



function Sh.isPointInQuadrilateral(point, x1, x2, y1, y2)
    local tri1 = {x=x1,y=y1}
    local tri2 = {x=x1,y=y2}
    local tri3 = {x=x2,y=y2}
    local tri4 = {x=x2,y=y1}
    return Sh.isPointInTriangle(point, tri1, tri2, tri3)
        or Sh.isPointInTriangle(point, tri3, tri4, tri1);
end

function Sh.isPointInTriangle(point, tri1, tri2, tri3)
  local var4 = (tri1.x - point.x) * (tri2.y - tri1.y) - (tri2.x - tri1.x) * (tri1.y - point.y);
  local var5 = (tri2.x - point.x) * (tri3.y - tri2.y) - (tri3.x - tri2.x) * (tri2.y - point.y);
  local var6 = (tri3.x - point.x) * (tri1.y - tri3.y) - (tri1.x - tri3.x) * (tri3.y - point.y);
  return var4 >= 0.0F and var5 >= 0.0F and var6 >= 0.0F or var4 <= 0.0F and var5 <= 0.0F and var6 <= 0.0F;
end

--https://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
-- Returns intersection point if the lines intersect, otherwise nil.
function Sh.get_line_intersection(p0, p1, p2, p3)--segments are p0p1 and p2p3
    local s1 = {x=p1.x-p0.x, y=p1.y-p0.y}
    local s2 = {x=p3.x-p2.x, y=p3.y-p2.y}

    local s = (-s1.y * (p0.x - p2.x) + s1.x * (p0.y - p2.y)) / (-s2.x * s1.y + s1.x * s2.y);
    local t = ( s2.x * (p0.y - p2.y) - s2.y * (p0.x - p2.x)) / (-s2.x * s1.y + s1.x * s2.y);

    if s >= 0 and s <= 1 and t >= 0 and t <= 1 then
        local result = {}
        -- Collision detected
            result.x = p0.x + (t * s1.x);
            result.y = p0.y + (t * s1.y);
        return result;
    end

    return nil; -- No collision
end