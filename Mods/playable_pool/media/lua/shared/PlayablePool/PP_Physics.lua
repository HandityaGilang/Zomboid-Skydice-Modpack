require "PlayablePool/PP_Core"

PPPhysics = PPPhysics or {}

local EPS = 0.0001
local MAX_SUBSTEPS = 8

local function clamp(value, low, high)
    value = tonumber(value) or low
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

local function speedSquared(ball)
    return (ball.vx or 0) * (ball.vx or 0) + (ball.vy or 0) * (ball.vy or 0)
end

local function ballSpeed(ball)
    return math.sqrt(speedSquared(ball))
end

local function normalize(dx, dy)
    local length = math.sqrt(dx * dx + dy * dy)
    if length <= EPS then
        return 0, 0, 0
    end
    return dx / length, dy / length, length
end

local function ballRadius()
    return PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R
end

local function pocketCenters()
    return PP.getPocketCenters and PP.getPocketCenters() or {}
end

local function snapshotBalls(balls)
    local frame = {}
    for i = 1, #balls do
        local ball = balls[i]
        frame[i] = {
            id = ball.id,
            x = ball.x,
            y = ball.y,
            pocketed = ball.pocketed and true or false,
        }
    end
    return frame
end

local function containsBall(list, id)
    for i = 1, #(list or {}) do
        if list[i] == id then
            return true
        end
    end
    return false
end

local function pocketForBall(pocketed, id)
    for i = 1, #(pocketed or {}) do
        local entry = pocketed[i]
        if entry and entry.id == id then
            return entry.pocketId
        end
    end
    return nil
end

local function countObjectBallRails(railObjectBalls)
    local count = 0
    for _ in pairs(railObjectBalls or {}) do
        count = count + 1
    end
    return count
end

local function ballMovingTowardPocket(ball, pocket)
    if not ball or not pocket then
        return false
    end
    local vx = ball.vx or 0
    local vy = ball.vy or 0
    local speedSq = vx * vx + vy * vy
    if speedSq <= EPS then
        return false
    end
    local dx, dy, dist = normalize(pocket.x - ball.x, pocket.y - ball.y)
    if dist <= EPS then
        return true
    end
    return vx * dx + vy * dy > -math.sqrt(speedSq) * 0.08
end

local function trajectoryWillEnterPocket(ball, hitX, hitY, pocket)
    if not ball or not pocket then
        return false
    end
    local vx = ball.vx or 0
    local vy = ball.vy or 0
    local speedSq = vx * vx + vy * vy
    if speedSq <= EPS then
        return false
    end

    local dx = pocket.x - hitX
    local dy = pocket.y - hitY
    if dx * vx + dy * vy <= 0 then
        return false
    end

    local t = (dx * vx + dy * vy) / speedSq
    if t < 0 or t > 0.70 then
        return false
    end

    local closestX = hitX + vx * t
    local closestY = hitY + vy * t
    local capture = PP.getPocketCaptureRadius and PP.getPocketCaptureRadius(pocket) or PP.POCKET_R
    capture = capture + ballRadius() * 0.85
    local cx = closestX - pocket.x
    local cy = closestY - pocket.y
    return cx * cx + cy * cy <= capture * capture
end

local function pocketMouthAllowsRailSkip(ball, x, y)
    local pockets = pocketCenters()
    for i = 1, #pockets do
        local pocket = pockets[i]
        local mouthR = pocket.mouthRadius or (PP.getPocketMouthRadius and PP.getPocketMouthRadius() or (PP.POCKET_R + ballRadius() * 0.95))
        local dx = x - pocket.x
        local dy = y - pocket.y
        if dx * dx + dy * dy <= mouthR * mouthR then
            return ballMovingTowardPocket(ball, pocket) or trajectoryWillEnterPocket(ball, x, y, pocket)
        end
    end
    return false
end

local function ballCommittedToPocket(ball, pocket)
    if not ball or not pocket then
        return false
    end
    local mouthR = pocket.mouthRadius or (PP.getPocketMouthRadius and PP.getPocketMouthRadius() or (PP.POCKET_R + ballRadius() * 0.95))
    local dx = ball.x - pocket.x
    local dy = ball.y - pocket.y
    if dx * dx + dy * dy > mouthR * mouthR then
        return false
    end
    local captureR = PP.getPocketCaptureRadius and PP.getPocketCaptureRadius(pocket) or PP.POCKET_R
    local commitR = pocket.commitRadius or (captureR + ballRadius() * 0.92)
    if dx * dx + dy * dy > commitR * commitR then
        return false
    end
    return ballMovingTowardPocket(ball, pocket)
end

local function checkPocket(ball)
    local pockets = pocketCenters()
    for i = 1, #pockets do
        local captureR = PP.getPocketCaptureRadius and PP.getPocketCaptureRadius(pockets[i]) or PP.POCKET_R
        local dx = ball.x - pockets[i].x
        local dy = ball.y - pockets[i].y
        if dx * dx + dy * dy <= captureR * captureR or ballCommittedToPocket(ball, pockets[i]) then
            ball.pocketed = true
            ball.vx = 0
            ball.vy = 0
            return true, pockets[i]
        end
    end
    return false, nil
end

local function applyPocketGravity(ball, dt)
    local pockets = pocketCenters()
    local best = nil
    for i = 1, #pockets do
        local captureRadius = PP.getPocketCaptureRadius and PP.getPocketCaptureRadius(pockets[i]) or PP.POCKET_R
        local lipRadius = PP.getPocketGravityRadius and PP.getPocketGravityRadius(pockets[i]) or (captureRadius + ballRadius() * 0.78)
        local lipRadiusSq = lipRadius * lipRadius
        local dx = pockets[i].x - ball.x
        local dy = pockets[i].y - ball.y
        local distSq = dx * dx + dy * dy
        if distSq > captureRadius * captureRadius and distSq <= lipRadiusSq and (not best or distSq < best.distSq) then
            best = { pocket = pockets[i], dx = dx, dy = dy, distSq = distSq, captureRadius = captureRadius, lipRadius = lipRadius }
        end
    end
    if not best then
        return
    end

    local nx, ny, dist = normalize(best.dx, best.dy)
    if dist <= EPS then
        return
    end
    local edgeT = clamp(((best.lipRadius or 0) - dist) / math.max(EPS, (best.lipRadius or 0) - (best.captureRadius or 0)), 0, 1)
    local speed = ballSpeed(ball)
    local pull = (115 + speed * 0.10) * edgeT * edgeT
    ball.vx = (ball.vx or 0) + nx * pull * dt
    ball.vy = (ball.vy or 0) + ny * pull * dt

    local toward = (ball.vx or 0) * nx + (ball.vy or 0) * ny
    local sideX = (ball.vx or 0) - nx * toward
    local sideY = (ball.vy or 0) - ny * toward
    local damp = 1 - 0.055 * edgeT
    ball.vx = nx * toward + sideX * damp
    ball.vy = ny * toward + sideY * damp
end

local function moveBalls(balls, dt)
    if dt <= 0 then
        return
    end
    for i = 1, #balls do
        local ball = balls[i]
        if not ball.pocketed then
            ball.x = ball.x + (ball.vx or 0) * dt
            ball.y = ball.y + (ball.vy or 0) * dt
        end
    end
end

local function findRailEvent(ball, ballIndex, dt)
    if ball.pocketed then
        return nil
    end
    local best = nil
    local vx = ball.vx or 0
    local vy = ball.vy or 0
    if vx * vx + vy * vy <= EPS then
        return nil
    end
    local segments = PP.getCollisionSegments and PP.getCollisionSegments() or {}
    local nextX = ball.x + vx * dt
    local nextY = ball.y + vy * dt
    local interior = PP.getCollisionInteriorBounds and PP.getCollisionInteriorBounds() or nil
    if interior then
        local pad = math.sqrt(vx * vx + vy * vy) * dt + EPS
        if ball.x > interior.left + pad and ball.x < interior.right - pad and ball.y > interior.top + pad and ball.y < interior.bottom - pad and nextX > interior.left and nextX < interior.right and nextY > interior.top and nextY < interior.bottom then
            return nil
        end
    end
    local pathMinX = math.min(ball.x, nextX) - EPS
    local pathMaxX = math.max(ball.x, nextX) + EPS
    local pathMinY = math.min(ball.y, nextY) - EPS
    local pathMaxY = math.max(ball.y, nextY) + EPS
    for i = 1, #segments do
        local seg = segments[i]
        if pathMaxX >= (seg.minX or math.min(seg.ax, seg.bx)) and pathMinX <= (seg.maxX or math.max(seg.ax, seg.bx)) and pathMaxY >= (seg.minY or math.min(seg.ay, seg.by)) and pathMinY <= (seg.maxY or math.max(seg.ay, seg.by)) then
            local sx = seg.bx - seg.ax
            local sy = seg.by - seg.ay
            local det = vx * sy - vy * sx
            if math.abs(det) > EPS then
                local ox = seg.ax - ball.x
                local oy = seg.ay - ball.y
                local t = (ox * sy - oy * sx) / det
                local u = (ox * vy - oy * vx) / det
                if t >= -EPS and t <= dt + EPS and u >= -EPS and u <= 1 + EPS then
                    local hitX = ball.x + vx * t
                    local hitY = ball.y + vy * t
                    if not pocketMouthAllowsRailSkip(ball, hitX, hitY) and (not best or t < best.t) then
                        best = { kind = "rail", t = math.max(0, t), ballIndex = ballIndex, ball = ball, edge = seg.id, x = hitX, y = hitY, nx = seg.nx, ny = seg.ny }
                    end
                end
            end
        end
    end
    return best
end

local function findBallEvent(a, b, ai, bi, dt)
    if a.pocketed or b.pocketed then
        return nil
    end
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dvx = (b.vx or 0) - (a.vx or 0)
    local dvy = (b.vy or 0) - (a.vy or 0)
    local r = ballRadius() * 2
    local c = dx * dx + dy * dy - r * r
    local normalSpeed = dx * dvx + dy * dvy
    if c <= 0 then
        if normalSpeed < -EPS then
            return { kind = "ball", t = 0, a = a, b = b, ai = ai, bi = bi, x = (a.x + b.x) / 2, y = (a.y + b.y) / 2 }
        end
        return nil
    end
    local qa = dvx * dvx + dvy * dvy
    if qa <= EPS or normalSpeed >= 0 then
        return nil
    end
    local qb = 2 * normalSpeed
    local disc = qb * qb - 4 * qa * c
    if disc < 0 then
        return nil
    end
    local t = (-qb - math.sqrt(disc)) / (2 * qa)
    if t < 0 or t > dt then
        return nil
    end
    return { kind = "ball", t = t, a = a, b = b, ai = ai, bi = bi, x = (a.x + (a.vx or 0) * t + b.x + (b.vx or 0) * t) / 2, y = (a.y + (a.vy or 0) * t + b.y + (b.vy or 0) * t) / 2 }
end

local function findNextEvent(balls, dt)
    local best = nil
    for i = 1, #balls do
        local rail = findRailEvent(balls[i], i, dt)
        if rail and (not best or rail.t < best.t) then
            best = rail
        end
    end
    for i = 1, #balls do
        for j = i + 1, #balls do
            local hit = findBallEvent(balls[i], balls[j], i, j, dt)
            if hit and (not best or hit.t < best.t) then
                best = hit
            end
        end
    end
    return best
end

local function addTrace(trace, event)
    if not trace or not event then
        return
    end
    trace.contacts = trace.contacts or {}
    table.insert(trace.contacts, event)
    if not trace.firstContact and (event.kind == "rail" or event.kind == "ball") and event.primary == "cue" then
        trace.firstContact = PP.copyTable(event)
    end
    if not trace.firstBallContact and event.kind == "ball" and event.primary == "cue" then
        trace.firstBallContact = PP.copyTable(event)
    end
    if not trace.firstRailContact and event.kind == "rail" and event.primary == "cue" then
        trace.firstRailContact = PP.copyTable(event)
    end
end

local function resolveRail(event, trace, tick, tickMs)
    local ball = event.ball
    if not ball or ball.pocketed then
        return false
    end
    local preVx = ball.vx or 0
    local preVy = ball.vy or 0
    local restitution = 0.84
    local tangentLoss = 0.965
    local nx = event.nx or 0
    local ny = event.ny or 0
    local nLen = math.sqrt(nx * nx + ny * ny)
    if nLen <= EPS then
        return false
    end
    nx = nx / nLen
    ny = ny / nLen
    local vn = preVx * nx + preVy * ny
    if vn >= 0 then
        nx = -nx
        ny = -ny
        vn = preVx * nx + preVy * ny
    end
    local tangentX = preVx - nx * vn
    local tangentY = preVy - ny * vn
    ball.x = (event.x or ball.x) + nx * 0.04
    ball.y = (event.y or ball.y) + ny * 0.04
    ball.vx = tangentX * tangentLoss - nx * vn * restitution
    ball.vy = tangentY * tangentLoss - ny * vn * restitution
    addTrace(trace, {
        kind = "rail",
        primary = ball.id,
        ballId = ball.id,
        edge = event.edge,
        x = ball.x,
        y = ball.y,
        normalX = nx,
        normalY = ny,
        preVx = preVx,
        preVy = preVy,
        postVx = ball.vx or 0,
        postVy = ball.vy or 0,
        tick = tick,
        ms = tickMs,
    })
    return true
end

local function separateBalls(a, b)
    local r = ballRadius() * 2
    local dx = b.x - a.x
    local dy = b.y - a.y
    local nx, ny, dist = normalize(dx, dy)
    if dist <= EPS then
        nx, ny, dist = 1, 0, 1
    end
    local overlap = r - dist
    if overlap > 0 then
        local correction = overlap * 0.52 + 0.01
        a.x = a.x - nx * correction
        a.y = a.y - ny * correction
        b.x = b.x + nx * correction
        b.y = b.y + ny * correction
    end
end

local function resolveBall(event, trace, tick, tickMs, context)
    local a = event.a
    local b = event.b
    if not a or not b or a.pocketed or b.pocketed then
        return false
    end
    local dx = b.x - a.x
    local dy = b.y - a.y
    local nx, ny = normalize(dx, dy)
    if nx == 0 and ny == 0 then
        nx, ny = 1, 0
    end
    local tx = -ny
    local ty = nx
    local avx, avy = a.vx or 0, a.vy or 0
    local bvx, bvy = b.vx or 0, b.vy or 0
    local dvx = bvx - avx
    local dvy = bvy - avy
    local normalSpeed = dvx * nx + dvy * ny
    separateBalls(a, b)
    if normalSpeed > -0.05 then
        return false
    end

    local restitution = 0.965
    local normalImpulse = -(1 + restitution) * normalSpeed / 2
    local tangentSpeed = dvx * tx + dvy * ty
    local tangentImpulse = clamp(-tangentSpeed / 2, -normalImpulse * 0.055, normalImpulse * 0.055)
    a.vx = avx - normalImpulse * nx - tangentImpulse * tx
    a.vy = avy - normalImpulse * ny - tangentImpulse * ty
    b.vx = bvx + normalImpulse * nx + tangentImpulse * tx
    b.vy = bvy + normalImpulse * ny + tangentImpulse * ty

    if context and not context.spinApplied and (context.spinX ~= 0 or context.spinY ~= 0) and (a.id == "cue" or b.id == "cue") then
        local cueBall = a.id == "cue" and a or b
        local spinPower = math.sqrt(speedSquared(cueBall))
        cueBall.vx = (cueBall.vx or 0) + context.shotDirX * context.spinY * spinPower * 0.18 + (-context.shotDirY) * context.spinX * spinPower * 0.14
        cueBall.vy = (cueBall.vy or 0) + context.shotDirY * context.spinY * spinPower * 0.18 + context.shotDirX * context.spinX * spinPower * 0.14
        context.spinApplied = true
    end

    addTrace(trace, {
        kind = "ball",
        primary = a.id == "cue" and "cue" or b.id == "cue" and "cue" or a.id,
        ballId = a.id == "cue" and b.id or a.id,
        aId = a.id,
        bId = b.id,
        x = (a.x + b.x) / 2,
        y = (a.y + b.y) / 2,
        aX = a.x,
        aY = a.y,
        bX = b.x,
        bY = b.y,
        cueX = a.id == "cue" and a.x or b.id == "cue" and b.x or nil,
        cueY = a.id == "cue" and a.y or b.id == "cue" and b.y or nil,
        targetX = a.id == "cue" and b.x or b.id == "cue" and a.x or nil,
        targetY = a.id == "cue" and b.y or b.id == "cue" and a.y or nil,
        normalX = nx,
        normalY = ny,
        aPreVx = avx,
        aPreVy = avy,
        bPreVx = bvx,
        bPreVy = bvy,
        aPostVx = a.vx or 0,
        aPostVy = a.vy or 0,
        bPostVx = b.vx or 0,
        bPostVy = b.vy or 0,
        cuePostVx = a.id == "cue" and a.vx or b.id == "cue" and b.vx or nil,
        cuePostVy = a.id == "cue" and a.vy or b.id == "cue" and b.vy or nil,
        targetPostVx = a.id == "cue" and b.vx or b.id == "cue" and a.vx or nil,
        targetPostVy = a.id == "cue" and b.vy or b.id == "cue" and a.vy or nil,
        tick = tick,
        ms = tickMs,
    })
    return true
end

local function stopSlowBall(ball)
    if speedSquared(ball) < 3.5 then
        ball.vx = 0
        ball.vy = 0
    end
end

local function applyTableFriction(ball, dt)
    local speed = ballSpeed(ball)
    if speed <= 0 then
        return
    end
    local newSpeed = math.max(0, speed - 32 * dt)
    newSpeed = newSpeed / (1 + 0.13 * dt)
    local scale = newSpeed / speed
    ball.vx = (ball.vx or 0) * scale
    ball.vy = (ball.vy or 0) * scale
end

local function checkPocketsAndStop(state, result, trace, tick, tickMs)
    for i = 1, #state.balls do
        local ball = state.balls[i]
        if not ball.pocketed then
            local pocketed, pocket = checkPocket(ball)
            if pocketed then
                result.pocketCount = result.pocketCount + 1
                if ball.id == "cue" then
                    result.scratch = true
                else
                    table.insert(result.sunk, ball.id)
                    table.insert(result.pocketed, { id = ball.id, pocketId = pocket and pocket.id or nil })
                end
                addTrace(trace, {
                    kind = "pocket",
                    primary = ball.id,
                    ballId = ball.id,
                    pocketId = pocket and pocket.id or nil,
                    x = pocket and pocket.x or ball.x,
                    y = pocket and pocket.y or ball.y,
                    tick = tick,
                    ms = tickMs,
                })
                table.insert(result.soundEvents, { kind = "pocket", ms = tickMs, strength = 0.85 })
            end
        end
    end
end

local function hasMovingBalls(state)
    for i = 1, #state.balls do
        local ball = state.balls[i]
        if not ball.pocketed and speedSquared(ball) > 0.5 then
            return true
        end
    end
    return false
end

local function addSoundEvent(result, kind, tick, frameIntervalTicks, strength)
    result.soundState = result.soundState or { impact = -999, rail = -999, pocket = -999 }
    local gap = kind == "impact" and 8 or kind == "rail" and 12 or 8
    if tick - (result.soundState[kind] or -999) < gap then
        return
    end
    table.insert(result.soundEvents, {
        kind = kind,
        ms = math.floor(tick / frameIntervalTicks * PP.ANIMATION_FRAME_MS),
        strength = strength or 0.85,
    })
    result.soundState[kind] = tick
end

local function containEscapedBalls(state, result, trace, tick, tickMs, frameIntervalTicks)
    local restitution = 0.74
    for i = 1, #(state.balls or {}) do
        local ball = state.balls[i]
        if ball and not ball.pocketed and PP.isInsidePlayableBoundary and not PP.isInsidePlayableBoundary(ball.x or 0, ball.y or 0) and not pocketMouthAllowsRailSkip(ball, ball.x or 0, ball.y or 0) then
            local preVx = ball.vx or 0
            local preVy = ball.vy or 0
            local best = nil
            local segments = PP.getCollisionSegments and PP.getCollisionSegments() or {}
            for s = 1, #segments do
                local seg = segments[s]
                local dx = seg.bx - seg.ax
                local dy = seg.by - seg.ay
                local lenSq = dx * dx + dy * dy
                if lenSq > EPS then
                    local u = clamp(((ball.x or 0) - seg.ax) * dx / lenSq + ((ball.y or 0) - seg.ay) * dy / lenSq, 0, 1)
                    local px = seg.ax + dx * u
                    local py = seg.ay + dy * u
                    local ox = (ball.x or 0) - px
                    local oy = (ball.y or 0) - py
                    local distSq = ox * ox + oy * oy
                    if not best or distSq < best.distSq then
                        best = { segment = seg, x = px, y = py, distSq = distSq }
                    end
                end
            end

            if best and best.segment then
                local nx = best.segment.nx or 0
                local ny = best.segment.ny or 0
                local vn = preVx * nx + preVy * ny
                local tx = preVx - nx * vn
                local ty = preVy - ny * vn
                ball.x = best.x + nx * 0.2
                ball.y = best.y + ny * 0.2
                if vn < 0 then
                    ball.vx = tx - nx * vn * restitution
                    ball.vy = ty - ny * vn * restitution
                else
                    ball.vx = preVx * 0.45
                    ball.vy = preVy * 0.45
                end
            end

            if best and best.segment then
                addTrace(trace, {
                    kind = "rail",
                    primary = ball.id,
                    ballId = ball.id,
                    edge = best.segment.id,
                    x = ball.x,
                    y = ball.y,
                    normalX = best.segment.nx,
                    normalY = best.segment.ny,
                    preVx = preVx,
                    preVy = preVy,
                    postVx = ball.vx or 0,
                    postVy = ball.vy or 0,
                    tick = tick,
                    ms = tickMs,
                })
                result.railCount = (result.railCount or 0) + 1
                addSoundEvent(result, "rail", tick, frameIntervalTicks or 1, math.min(1, ballSpeed(ball) / PP.MAX_POWER))
            end
        end
    end
end

local function lowestSunkGroup(sunk)
    local group = nil
    for i = 1, #(sunk or {}) do
        local nextGroup = PP.ballGroupName(sunk[i])
        if nextGroup then
            if group and group ~= nextGroup then
                return nil
            end
            group = nextGroup
        end
    end
    return group
end

local function assignEightBallGroup(state, shooter, sunk)
    local modeState = state.modeState or PP.initialModeState("eight_ball")
    state.modeState = modeState
    modeState.groups = modeState.groups or {}
    if modeState.groups[shooter] then
        return nil
    end
    local group = lowestSunkGroup(sunk)
    if not group then
        return nil
    end
    modeState.groups[shooter] = group
    local otherGroup = PP.oppositeEightBallGroup(group)
    for i = 1, #(state.players or {}) do
        local name = state.players[i]
        if name ~= shooter and not modeState.groups[name] then
            modeState.groups[name] = otherGroup
        end
    end
    return group
end

local function setWinner(nextState, winner, reason, eventText, eventKind)
    nextState.winner = winner
    nextState.winReason = reason
    nextState.message = reason
    PP.addEvent(nextState, eventText or reason, eventKind or "win")
end

local function sortedSunkBalls(sunk)
    local result = {}
    for i = 1, #(sunk or {}) do
        if type(sunk[i]) == "number" then
            table.insert(result, sunk[i])
        end
    end
    table.sort(result)
    return result
end

local function formatBallList(sunk)
    local balls = sortedSunkBalls(sunk)
    local count = #balls
    if count == 0 then
        return nil
    end
    if count == 1 then
        return "the " .. tostring(balls[1]) .. " ball"
    end
    if count == 2 then
        return "the " .. tostring(balls[1]) .. " and " .. tostring(balls[2]) .. " balls"
    end
    local parts = {}
    for i = 1, count do
        parts[#parts + 1] = tostring(balls[i])
    end
    return "the " .. table.concat(parts, ", ", 1, count - 1) .. ", and " .. tostring(balls[count]) .. " balls"
end

local function sankText(shooter, sunk)
    local balls = formatBallList(sunk)
    if balls then
        return shooter .. " sank " .. balls .. "."
    end
    return shooter .. " sank no balls."
end

local function afterSinkingText(sunk)
    local balls = formatBallList(sunk)
    if balls then
        return " after sinking " .. balls
    end
    return ""
end

local function resolveNineBall(nextState, state, result, shooter)
    local firstHitId = result.firstHit
    local requiredId = result.required
    local sunk = result.sunk or {}
    local scratch = result.scratch
    local legalHit = requiredId == nil or firstHitId == requiredId
    local winBall = PP.findBall(nextState, 9)
    local winSunk = winBall and winBall.pocketed
    local breakShot = PP.isBreakShot(state)
    local illegalBreak = breakShot and #sunk == 0 and countObjectBallRails(result.railObjectBalls) < 4
    local standardFoul = false
    if winSunk and (scratch or not legalHit) then
        PP.respotBall(nextState, 9)
        winSunk = false
        PP.addEvent(nextState, "The 9 ball was spotted after a foul.", "foul")
    end
    if scratch then
        standardFoul = true
        nextState.message = shooter .. " scratched" .. afterSinkingText(sunk) .. ". Ball in hand."
        PP.addEvent(nextState, nextState.message, "foul")
        PP.advanceTurn(nextState)
        PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
    elseif illegalBreak then
        standardFoul = true
        nextState.message = shooter .. " made an illegal break: four object balls did not reach rails. Ball in hand."
        PP.addEvent(nextState, nextState.message, "foul")
        PP.advanceTurn(nextState)
        PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
    elseif not legalHit then
        standardFoul = true
        local firstText = firstHitId and tostring(firstHitId) or "no ball"
        nextState.message = shooter .. " fouled" .. afterSinkingText(sunk) .. ": hit " .. firstText .. " first. Ball " .. tostring(requiredId) .. " was on."
        PP.addEvent(nextState, nextState.message, "foul")
        PP.advanceTurn(nextState)
        PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
    elseif not result.railAfterContact and #sunk == 0 then
        standardFoul = true
        nextState.message = shooter .. " fouled: no ball reached a rail after contact. Ball in hand."
        PP.addEvent(nextState, nextState.message, "foul")
        PP.advanceTurn(nextState)
        PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
    elseif winSunk then
        setWinner(nextState, shooter, shooter .. " sank the 9 ball and won.")
    else
        if #sunk > 0 then
            nextState.message = sankText(shooter, sunk)
            PP.addEvent(nextState, nextState.message .. " Shoot again.", "score")
        else
            nextState.message = shooter .. " missed."
            PP.addEvent(nextState, nextState.message, "miss")
            PP.advanceTurn(nextState)
        end
    end
    return legalHit and not standardFoul
end

local function resolveEightBall(nextState, state, result, shooter)
    local firstHitId = result.firstHit
    local sunk = result.sunk or {}
    local scratch = result.scratch
    local modeState = nextState.modeState or PP.initialModeState("eight_ball")
    nextState.modeState = modeState
    modeState.groups = modeState.groups or {}
    local group = modeState.groups[shooter]
    local firstGroup = PP.ballGroupName(firstHitId)
    local onEight = group and PP.eightBallGroupCleared(state, group)
    local breakShot = PP.isBreakShot(state)
    local legalHit = onEight and firstHitId == 8 or group and firstGroup == group or (not group and firstGroup ~= nil)
    local eightSunk = containsBall(sunk, 8)
    local shotCall = state and state.shotCall or nil
    local playerIndex = PP.findNameIndex(nextState.players or {}, shooter) or 1
    local opponent = nextState.players and nextState.players[playerIndex == 1 and 2 or 1] or nil
    local illegalBreak = breakShot and #sunk == 0 and countObjectBallRails(result.railObjectBalls) < 4
    local standardFoul = false

    if breakShot and eightSunk then
        PP.respotBall(nextState, 8)
        if scratch then
            nextState.message = shooter .. " sank the 8 on a scratch break. The 8 was spotted. Ball in hand."
            PP.addEvent(nextState, nextState.message, "foul")
            PP.advanceTurn(nextState)
            PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
            return false
        end
        if illegalBreak then
            nextState.message = shooter .. " sank the 8 on an illegal break. The 8 was spotted. Ball in hand."
            PP.addEvent(nextState, nextState.message, "foul")
            PP.advanceTurn(nextState)
            PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
            return false
        end
        nextState.message = shooter .. " sank the 8 on the break. The 8 was spotted; table remains open."
        PP.addEvent(nextState, nextState.message .. " Shoot again.", "score")
        return true
    end

    if eightSunk then
        local calledPocket = shotCall and shotCall.pocketId
        local madeCalledEight = shotCall and shotCall.ballId == 8 and pocketForBall(result.pocketed, 8) == calledPocket
        if legalHit and not scratch and onEight and madeCalledEight then
            setWinner(nextState, shooter, shooter .. " sank the 8 and won.")
        else
            local winner = opponent or shooter
            local reason = shooter .. " illegally sank the 8."
            setWinner(nextState, winner, reason, reason .. " " .. tostring(winner) .. " wins.", "foul")
        end
        return legalHit and not scratch
    end
    if scratch then
        standardFoul = true
        nextState.message = shooter .. " scratched" .. afterSinkingText(sunk) .. ". Ball in hand."
        PP.addEvent(nextState, nextState.message, "foul")
        PP.advanceTurn(nextState)
        PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
    elseif illegalBreak then
        standardFoul = true
        nextState.message = shooter .. " made an illegal break: four object balls did not reach rails. Ball in hand."
        PP.addEvent(nextState, nextState.message, "foul")
        PP.advanceTurn(nextState)
        PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
    elseif not legalHit then
        standardFoul = true
        local target = group and (onEight and "the 8" or group) or "solids or stripes"
        local firstText = firstHitId and tostring(firstHitId) or "no ball"
        nextState.message = shooter .. " fouled" .. afterSinkingText(sunk) .. ": hit " .. firstText .. " first. On: " .. target .. "."
        PP.addEvent(nextState, nextState.message, "foul")
        PP.advanceTurn(nextState)
        PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
    elseif not result.railAfterContact and #sunk == 0 then
        standardFoul = true
        nextState.message = shooter .. " fouled: no ball reached a rail after contact. Ball in hand."
        PP.addEvent(nextState, nextState.message, "foul")
        PP.advanceTurn(nextState)
        PP.setBallInHand(nextState, PP.currentPlayerName(nextState))
    else
        local sunkGroup = nil
        if not breakShot and shotCall and not shotCall.safety then
            local calledPocket = pocketForBall(result.pocketed, shotCall.ballId)
            if calledPocket == shotCall.pocketId then
                sunkGroup = assignEightBallGroup(nextState, shooter, { shotCall.ballId })
            end
        end
        local madeOwn = false
        group = modeState.groups[shooter] or group
        if breakShot then
            madeOwn = #sunk > 0
        elseif shotCall and not shotCall.safety then
            local calledPocket = pocketForBall(result.pocketed, shotCall.ballId)
            madeOwn = calledPocket == shotCall.pocketId and (not group or PP.ballGroupName(shotCall.ballId) == group)
        end
        if shotCall and shotCall.safety then
            madeOwn = false
        end
        if #sunk > 0 then
            local callText = ""
            if not breakShot and shotCall and not shotCall.safety and not madeOwn then
                callText = " Called " .. PP.shotCallLabel(shotCall) .. " was not made."
            end
            local groupText = sunkGroup and (" Took " .. sunkGroup .. ".") or ""
            nextState.message = sankText(shooter, sunk) .. groupText .. callText
            PP.addEvent(nextState, nextState.message .. (madeOwn and " Shoot again." or ""), madeOwn and "score" or "miss")
            if not madeOwn then
                PP.advanceTurn(nextState)
            end
        else
            nextState.message = shooter .. " missed."
            PP.addEvent(nextState, nextState.message, "miss")
            PP.advanceTurn(nextState)
        end
    end
    return legalHit and not standardFoul
end

local function resolveRules(nextState, originalState, result)
    local shooter = PP.currentPlayerName(originalState) or "Player"
    PP.clearBallInHand(nextState)
    local legalHit
    if (originalState.modeId or PP.DEFAULT_MODE_ID) == "eight_ball" then
        legalHit = resolveEightBall(nextState, originalState, result, shooter)
    else
        legalHit = resolveNineBall(nextState, originalState, result, shooter)
    end
    nextState.lastShot = {
        shooter = shooter,
        required = result.required,
        firstHit = result.firstHit,
        legal = legalHit and not result.scratch,
        scratch = result.scratch,
        sunk = PP.copyTable(result.sunk),
        shotCall = PP.copyTable(originalState.shotCall),
    }
    PP.clearShotCall(nextState)
    result.legal = legalHit
    if nextState.winner then
        PP.setPhase(nextState, PP.PHASE_GAME_OVER)
    elseif #(nextState.players or {}) >= 2 then
        PP.setPhase(nextState, PP.PHASE_TURN_READY)
    else
        PP.setPhase(nextState, PP.PHASE_WAITING_FOR_PLAYERS)
    end
end

function PPPhysics.simulate(state, shot, options)
    options = options or {}
    shot = shot or {}
    local mode = options.mode or (options.preview and "preview" or "full")
    local nextState = PP.copyTable(state)
    local cue = PP.findBall(nextState, "cue")
    if not cue or cue.pocketed or nextState.winner then
        return { finalState = nextState, trace = {}, result = { ok = false, reason = "The cue ball is not playable." } }
    end
    local power = clamp(shot.power, 0, PP.MAX_POWER)
    local angle = tonumber(shot.angle) or 0
    if power < 30 then
        return { finalState = nextState, trace = {}, result = { ok = false, reason = "Shot power was too low." } }
    end

    local previewLike = mode == "preview" or mode == "ai_probe"
    local simHz = previewLike and 120 or 240
    local dt = 1 / simHz
    local frameIntervalTicks = mode == "ai_probe" and 999999 or previewLike and 12 or PP.ANIMATION_TICKS_PER_FRAME * 2
    local maxTicks = options.maxTicks or (mode == "ai_probe" and 900 or previewLike and 1440 or 5400)
    local trace = { contacts = {}, mode = mode }
    local result = {
        ok = true,
        scratch = false,
        sunk = {},
        pocketed = {},
        frames = mode == "ai_probe" and {} or { snapshotBalls(nextState.balls) },
        firstHit = nil,
        firstHitX = nil,
        firstHitY = nil,
        required = nil,
        legal = nil,
        impactCount = 0,
        railCount = 0,
        railAfterContact = false,
        railObjectBalls = {},
        pocketCount = 0,
        soundEvents = {},
    }

    local requiredBall = PP.onBallForState(state)
    if requiredBall == "open" then
        requiredBall = nil
    end
    result.required = requiredBall and requiredBall.id or nil

    local launchPower = power * (PP.SHOT_POWER_MULTIPLIER or 1)
    cue.vx = math.cos(angle) * launchPower
    cue.vy = math.sin(angle) * launchPower

    local context = {
        shotDirX = math.cos(angle),
        shotDirY = math.sin(angle),
        spinX = tonumber(shot.spinX) or 0,
        spinY = tonumber(shot.spinY) or 0,
        spinApplied = false,
    }

    for tick = 1, maxTicks do
        for i = 1, #nextState.balls do
            local ball = nextState.balls[i]
            if not ball.pocketed then
                applyPocketGravity(ball, dt)
            end
        end

        local remaining = dt
        for _ = 1, MAX_SUBSTEPS do
            if remaining <= EPS then
                break
            end
            local event = findNextEvent(nextState.balls, remaining)
            if not event then
                moveBalls(nextState.balls, remaining)
                remaining = 0
                break
            end
            local eventDt = math.max(0, event.t)
            moveBalls(nextState.balls, eventDt)
            remaining = remaining - eventDt
            local tickMs = math.floor(tick / frameIntervalTicks * PP.ANIMATION_FRAME_MS)
            if event.kind == "rail" then
                if resolveRail(event, trace, tick, tickMs) then
                    result.railCount = result.railCount + 1
                    if type(event.ball and event.ball.id) == "number" then
                        result.railObjectBalls[event.ball.id] = true
                    end
                    if result.firstHit then
                        result.railAfterContact = true
                    end
                    addSoundEvent(result, "rail", tick, frameIntervalTicks, math.min(1, ballSpeed(event.ball) / PP.MAX_POWER))
                end
            elseif event.kind == "ball" then
                if resolveBall(event, trace, tick, tickMs, context) then
                    result.impactCount = result.impactCount + 1
                    if not result.firstHit then
                        if event.a.id == "cue" and type(event.b.id) == "number" then
                            result.firstHit = event.b.id
                        elseif event.b.id == "cue" and type(event.a.id) == "number" then
                            result.firstHit = event.a.id
                        end
                        if result.firstHit then
                            local cueBall = event.a.id == "cue" and event.a or event.b.id == "cue" and event.b or nil
                            result.firstHitX = cueBall and cueBall.x or event.x
                            result.firstHitY = cueBall and cueBall.y or event.y
                        end
                    end
                    addSoundEvent(result, "impact", tick, frameIntervalTicks, math.min(1, (ballSpeed(event.a) + ballSpeed(event.b)) / PP.MAX_POWER))
                end
            end
            moveBalls(nextState.balls, EPS)
            remaining = math.max(0, remaining - EPS)
        end

        local tickMs = math.floor(tick / frameIntervalTicks * PP.ANIMATION_FRAME_MS)
        checkPocketsAndStop(nextState, result, trace, tick, tickMs)
        containEscapedBalls(nextState, result, trace, tick, tickMs, frameIntervalTicks)
        for i = 1, #nextState.balls do
            local ball = nextState.balls[i]
            if not ball.pocketed then
                applyTableFriction(ball, dt)
                stopSlowBall(ball)
            end
        end
        if tick % frameIntervalTicks == 0 and mode ~= "ai_probe" then
            table.insert(result.frames, snapshotBalls(nextState.balls))
        end
        if not hasMovingBalls(nextState) then
            break
        end
    end

    if result.scratch then
        cue = PP.findBall(nextState, "cue")
        if cue then
            cue.pocketed = false
            cue.x = PP.CUE_SPOT_X or (PP.TABLE_W * 0.25)
            cue.y = PP.TABLE_H / 2
            cue.vx = 0
            cue.vy = 0
        end
    end
    if mode ~= "ai_probe" then
        table.insert(result.frames, snapshotBalls(nextState.balls))
    end
    trace.frames = result.frames
    trace.firstContact = trace.firstContact or (trace.contacts and trace.contacts[1])
    result.trace = trace

    if mode == "full" then
        nextState.shotNumber = (nextState.shotNumber or 0) + 1
        resolveRules(nextState, state, result)
    end
    result.soundState = nil
    return { finalState = nextState, frames = result.frames, events = result.soundEvents, trace = trace, result = result }
end

function PP.simulateShot(state, angle, power, shotOptions)
    shotOptions = shotOptions or {}
    local mode = shotOptions.mode or (shotOptions.preview and "preview" or "full")
    local sim = PPPhysics.simulate(state, {
        angle = angle,
        power = power,
        spinX = shotOptions.spinX,
        spinY = shotOptions.spinY,
    }, {
        mode = mode,
        maxTicks = shotOptions.maxTicks,
        traceMode = shotOptions.traceMode,
    })
    return sim.finalState, sim.result
end
