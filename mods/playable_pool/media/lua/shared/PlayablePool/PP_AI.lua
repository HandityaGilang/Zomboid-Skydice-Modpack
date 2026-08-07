require "PlayablePool/PP_Core"
require "PlayablePool/PP_Physics"

PP_AI = PP_AI or {}

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

local function random01()
    if ZombRand then
        return ZombRand(10000) / 9999
    end
    return math.random()
end

local function randomBetween(low, high)
    return low + (high - low) * random01()
end

local function nowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    return math.floor(os.clock() * 1000)
end

local function normalizeAngleDelta(angle)
    while angle > math.pi do
        angle = angle - math.pi * 2
    end
    while angle < -math.pi do
        angle = angle + math.pi * 2
    end
    return angle
end

local function lerpAngle(fromAngle, toAngle, t)
    return fromAngle + normalizeAngleDelta(toAngle - fromAngle) * t
end

local function normalizeVector(x, y)
    local len = math.sqrt(x * x + y * y)
    if len <= 0 then
        return 0, 0, 0
    end
    return x / len, y / len, len
end

local function tablePockets()
    return PP.getPocketCenters and PP.getPocketCenters() or {
        { x = 0, y = 0 },
        { x = PP.TABLE_W / 2, y = 0 },
        { x = PP.TABLE_W, y = 0 },
        { x = 0, y = PP.TABLE_H },
        { x = PP.TABLE_W / 2, y = PP.TABLE_H },
        { x = PP.TABLE_W, y = PP.TABLE_H },
    }
end

local function pointSegmentDistanceSq(px, py, ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    local lenSq = dx * dx + dy * dy
    if lenSq <= 0 then
        local ex = px - ax
        local ey = py - ay
        return ex * ex + ey * ey
    end
    local t = clamp(((px - ax) * dx + (py - ay) * dy) / lenSq, 0, 1)
    local cx = ax + dx * t
    local cy = ay + dy * t
    local ex = px - cx
    local ey = py - cy
    return ex * ex + ey * ey
end

local function segmentClear(state, ax, ay, bx, by, ignoreA, ignoreB, clearance)
    local balls = state and state.balls or {}
    clearance = clearance or ((PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R) * 2.05)
    local clearanceSq = clearance * clearance
    for i = 1, #balls do
        local ball = balls[i]
        if ball and not ball.pocketed and ball.id ~= ignoreA and ball.id ~= ignoreB then
            if pointSegmentDistanceSq(ball.x, ball.y, ax, ay, bx, by) < clearanceSq then
                return false
            end
        end
    end
    return true
end

local function legalTargetBalls(state, playerName)
    local targets = {}
    for i = 1, #(state.balls or {}) do
        local ball = state.balls[i]
        if ball and type(ball.id) == "number" and not ball.pocketed and PP.isLegalFirstHit(state, ball.id, playerName) then
            targets[#targets + 1] = ball
        end
    end
    table.sort(targets, function(a, b)
        return (a.id or 99) < (b.id or 99)
    end)
    return targets
end

local function insidePlayableTable(x, y)
    if PP.isInsidePlayableBoundary then
        return PP.isInsidePlayableBoundary(x, y)
    end
    local r = PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R
    local rails = PP.getRailBounds and PP.getRailBounds() or { left = r, top = r, right = PP.TABLE_W - r, bottom = PP.TABLE_H - r }
    return x >= rails.left and x <= rails.right and y >= rails.top and y <= rails.bottom
end

local function pocketRiskScore(x, y)
    local pockets = tablePockets()
    local best = nil
    for i = 1, #pockets do
        local dx = x - pockets[i].x
        local dy = y - pockets[i].y
        local distSq = dx * dx + dy * dy
        if not best or distSq < best then
            best = distSq
        end
    end
    local r = PP.getPocketCaptureRadius and PP.getPocketCaptureRadius() or PP.POCKET_R or 32
    if not best then
        return 0
    end
    local dist = math.sqrt(best)
    if dist < r * 1.7 then
        return -260
    end
    if dist < r * 2.8 then
        return -110
    end
    return math.min(90, dist * 0.08)
end

local function opponentName(state, playerName)
    for i = 1, #(state.players or {}) do
        if state.players[i] ~= playerName then
            return state.players[i]
        end
    end
    return nil
end

local function remainingGoodBalls(state, playerName)
    local count = 0
    for i = 1, #(state.balls or {}) do
        local ball = state.balls[i]
        if ball and type(ball.id) == "number" and not ball.pocketed and PP.isLegalFirstHit(state, ball.id, playerName) then
            count = count + 1
        end
    end
    return count
end

local function isSunkGoodForPlayer(state, playerName, ballId)
    if not ballId or type(ballId) ~= "number" then
        return false
    end
    if (state.modeId or PP.DEFAULT_MODE_ID) == "nine_ball" then
        return true
    end
    local group = PP.playerEightBallGroup(state, playerName)
    if not group then
        return PP.isSolidBall(ballId) or PP.isStripeBall(ballId)
    end
    if ballId == 8 then
        return PP.eightBallGroupCleared(state, group)
    end
    return PP.ballGroupName(ballId) == group
end

local function addCandidate(candidates, angle, power, kind, targetId, scoreHint, meta)
    if not angle or not power then
        return
    end
    candidates[#candidates + 1] = {
        angle = angle,
        power = clamp(power, 45, PP.MAX_POWER),
        kind = kind or "probe",
        targetId = targetId,
        scoreHint = scoreHint or 0,
        meta = meta,
    }
end

local function addCandidateFamily(candidates, baseAngle, basePower, kind, targetId, scoreHint, difficulty, meta)
    local id = difficulty and difficulty.id or "medium"
    local angleOffsets = id == "easy" and { 0 } or id == "medium" and { 0, -0.026, 0.026 } or { 0, -0.038, 0.038, -0.018, 0.018 }
    local powerMultipliers = id == "easy" and { 1.0 } or id == "medium" and { 0.90, 1.0, 1.10 } or { 0.82, 0.94, 1.0, 1.08, 1.18 }
    for i = 1, #angleOffsets do
        for p = 1, #powerMultipliers do
            local hintPenalty = math.abs(angleOffsets[i]) * 260 + math.abs(1 - powerMultipliers[p]) * 100
            addCandidate(candidates, baseAngle + angleOffsets[i], basePower * powerMultipliers[p], kind, targetId, (scoreHint or 0) - hintPenalty, meta)
        end
    end
end

local function addPocketCandidates(state, playerName, difficulty, candidates, cue, target, pockets, r)
    for p = 1, #pockets do
        local pocket = pockets[p]
        local pocketDirX, pocketDirY, pocketDist = normalizeVector(pocket.x - target.x, pocket.y - target.y)
        if pocketDist > r * 3 then
            local ghostX = target.x - pocketDirX * r * 2
            local ghostY = target.y - pocketDirY * r * 2
            if insidePlayableTable(ghostX, ghostY) then
                local aimDirX, aimDirY, cueDist = normalizeVector(ghostX - cue.x, ghostY - cue.y)
                if cueDist > r * 2 then
                    local alignment = aimDirX * pocketDirX + aimDirY * pocketDirY
                    local cueClear = segmentClear(state, cue.x, cue.y, ghostX, ghostY, "cue", target.id, r * 2.12)
                    local pocketClear = segmentClear(state, target.x, target.y, pocket.x, pocket.y, "cue", target.id, r * 2.04)
                    local clearBonus = (cueClear and 210 or -90) + (pocketClear and 230 or -130)
                    local angleCutPenalty = math.max(0, 0.55 - alignment) * 300
                    local hint = 420 + alignment * 320 + clearBonus - cueDist * 0.20 - pocketDist * 0.17 - angleCutPenalty
                    if alignment > -0.20 or difficulty.id == "hard" then
                        local power = 230 + cueDist * 0.47 + pocketDist * 0.23
                        addCandidateFamily(candidates, PP.atan2(aimDirY, aimDirX), power, "pocket", target.id, hint, difficulty, {
                            pocketId = pocket.id,
                            cueDist = cueDist,
                            pocketDist = pocketDist,
                            alignment = alignment,
                        })
                    end
                end
            end
        end
    end
end

local function addDirectCandidates(state, difficulty, candidates, cue, target, r)
    local dirX, dirY, dist = normalizeVector(target.x - cue.x, target.y - cue.y)
    if dist <= r * 2 then
        return
    end
    local clear = segmentClear(state, cue.x, cue.y, target.x, target.y, "cue", target.id, r * 2.08)
    local clearBonus = clear and 180 or -160
    local baseHint = clearBonus - dist * 0.25 - (target.id or 0) * 3
    addCandidateFamily(candidates, PP.atan2(dirY, dirX), 260 + dist * 0.42, "direct", target.id, baseHint + 80, difficulty, { dist = dist })
    addCandidateFamily(candidates, PP.atan2(dirY, dirX), 125 + dist * 0.24, "safety", target.id, baseHint + 20, difficulty, { dist = dist })
end

local function addBankCandidates(difficulty, candidates, cue, target)
    if not difficulty or difficulty.id ~= "hard" then
        return
    end
    local mirrorPoints = {
        { x = -target.x, y = target.y },
        { x = PP.TABLE_W * 2 - target.x, y = target.y },
        { x = target.x, y = -target.y },
        { x = target.x, y = PP.TABLE_H * 2 - target.y },
    }
    for i = 1, #mirrorPoints do
        local mx = mirrorPoints[i].x
        local my = mirrorPoints[i].y
        local _, _, dist = normalizeVector(mx - cue.x, my - cue.y)
        addCandidateFamily(candidates, PP.atan2(my - cue.y, mx - cue.x), 360 + dist * 0.18, "bank", target.id, 10, difficulty, { bank = i })
    end
end

local function findBreakTarget(state)
    local best = nil
    for i = 1, #(state and state.balls or {}) do
        local ball = state.balls[i]
        if ball and type(ball.id) == "number" and not ball.pocketed and (not best or ball.x < best.x) then
            best = ball
        end
    end
    return best
end

local function isOpeningBreak(state)
    if not state or (state.shotNumber or 0) ~= 0 or state.ballInHand or state.winner then
        return false
    end
    local rack = PP.getRackLayout and PP.getRackLayout(state.modeId) or {}
    local expected = #rack
    if expected <= 0 then
        expected = (state.modeId == "nine_ball") and 9 or 15
    end
    local count = 0
    for i = 1, #(state.balls or {}) do
        local ball = state.balls[i]
        if ball and type(ball.id) == "number" then
            if ball.pocketed then
                return false
            end
            if ((ball.vx or 0) * (ball.vx or 0) + (ball.vy or 0) * (ball.vy or 0)) > 0.5 then
                return false
            end
            count = count + 1
        end
    end
    return count == expected and findBreakTarget(state) ~= nil
end

local function addOpeningBreakCandidates(state, difficulty, candidates, cue, r)
    local target = findBreakTarget(state)
    if not target then
        return
    end
    local id = difficulty and difficulty.id or "medium"
    local offsets = id == "easy" and { 0, -r * 0.45, r * 0.45 } or id == "medium" and { 0, -r * 0.72, r * 0.72, -r * 1.15, r * 1.15 } or { 0, -r * 0.55, r * 0.55, -r * 0.95, r * 0.95, -r * 1.35, r * 1.35 }
    local powers = id == "easy" and { 610, 675 } or id == "medium" and { 690, 745, 800 } or { 735, 790, 835, PP.MAX_POWER }
    for i = 1, #offsets do
        local aimY = target.y + offsets[i]
        local dirX, dirY, dist = normalizeVector(target.x - cue.x, aimY - cue.y)
        if dist > r * 2 and segmentClear(state, cue.x, cue.y, target.x, aimY, "cue", target.id, r * 2.10) then
            for p = 1, #powers do
                local centerPenalty = math.abs(offsets[i]) * 0.16 + math.abs(powers[p] - (id == "hard" and 805 or 735)) * 0.10
                addCandidate(candidates, PP.atan2(dirY, dirX), powers[p], "opening_break", target.id, 760 - centerPenalty + randomBetween(-18, 18), {
                    openingBreak = true,
                    offsetY = offsets[i],
                    cueDist = dist,
                })
            end
        end
    end
end

local function buildCandidates(state, playerName, difficulty)
    local cue = PP.findBall(state, "cue")
    if not cue or cue.pocketed then
        return {}
    end
    local candidates = {}
    local r = PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R
    if isOpeningBreak(state) then
        addOpeningBreakCandidates(state, difficulty, candidates, cue, r)
    end
    if #candidates > 0 then
        table.sort(candidates, function(a, b)
            return (a.scoreHint or 0) > (b.scoreHint or 0)
        end)
        return candidates
    end

    local targets = legalTargetBalls(state, playerName)
    local pockets = tablePockets()
    local maxTargets = difficulty.id == "easy" and math.min(4, #targets) or difficulty.id == "medium" and math.min(8, #targets) or #targets

    for i = 1, maxTargets do
        local target = targets[i]
        addDirectCandidates(state, difficulty, candidates, cue, target, r)
        addPocketCandidates(state, playerName, difficulty, candidates, cue, target, pockets, r)
        addBankCandidates(difficulty, candidates, cue, target)
    end

    if #candidates == 0 then
        addCandidate(candidates, randomBetween(-math.pi, math.pi), 260, "fallback", nil, -300)
    end
    table.sort(candidates, function(a, b)
        return (a.scoreHint or 0) > (b.scoreHint or 0)
    end)
    return candidates
end

local function candidateProbeTicks(difficulty)
    if difficulty.id == "easy" then
        return 680
    end
    if difficulty.id == "medium" then
        return 940
    end
    return 1240
end

local function probeLimitForDifficulty(difficulty)
    if difficulty.id == "easy" then
        return 18
    end
    if difficulty.id == "medium" then
        return 72
    end
    return 180
end

local function probeBatchForDifficulty(difficulty)
    if difficulty.id == "hard" then
        return 5
    end
    if difficulty.id == "medium" then
        return 3
    end
    return 1
end

local function refineLimitForDifficulty(difficulty)
    if difficulty.id == "easy" then
        return 0
    end
    if difficulty.id == "medium" then
        return 18
    end
    return 48
end

local function cueLeaveScore(finalState, playerName, result, madeGood)
    if not finalState then
        return 0
    end
    local cue = PP.findBall(finalState, "cue")
    if not cue or cue.pocketed then
        return -400
    end
    local score = pocketRiskScore(cue.x, cue.y)
    local nextPlayer = PP.currentPlayerName(finalState)
    if nextPlayer and nextPlayer ~= playerName and not madeGood then
        local targets = legalTargetBalls(finalState, nextPlayer)
        local bestDist = nil
        for i = 1, #targets do
            local dx = targets[i].x - cue.x
            local dy = targets[i].y - cue.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if not bestDist or dist < bestDist then
                bestDist = dist
            end
        end
        if bestDist then
            score = score + math.min(180, bestDist * 0.32)
        end
    elseif madeGood then
        local remaining = remainingGoodBalls(finalState, playerName)
        score = score - math.min(120, remaining * 8)
    end
    if result and result.railCount and result.railCount >= 3 and not madeGood then
        score = score + 45
    end
    return score
end

local function scoreEightBallProbe(state, finalState, playerName, result, candidate)
    local score = 0
    local group = PP.playerEightBallGroup(state, playerName)
    local onEight = group and PP.eightBallGroupCleared(state, group)
    local opponent = opponentName(state, playerName)
    local eightSunk = false
    local madeGood = false
    local madeBad = false

    for i = 1, #(result.sunk or {}) do
        local ballId = result.sunk[i]
        if ballId == 8 then
            eightSunk = true
        elseif isSunkGoodForPlayer(state, playerName, ballId) then
            madeGood = true
            score = score + (group and 760 or 640)
        elseif PP.isSolidBall(ballId) or PP.isStripeBall(ballId) then
            madeBad = true
            score = score - 560
        end
    end

    if eightSunk then
        if onEight and not result.scratch and result.firstHit == 8 then
            score = score + 4200
            madeGood = true
        else
            score = score - 5200
            if opponent then
                score = score - 400
            end
        end
    end

    if not group and madeGood and not madeBad then
        score = score + 180
    end
    if candidate.kind == "safety" and not madeGood then
        score = score + 210
    end
    return score, madeGood
end

local function scoreNineBallProbe(state, playerName, result, candidate)
    local score = 0
    local madeGood = false
    local required = result.required
    for i = 1, #(result.sunk or {}) do
        local ballId = result.sunk[i]
        if ballId == 9 then
            if required == nil or result.firstHit == required then
                score = score + 3600
                madeGood = true
            else
                score = score - 1400
            end
        elseif type(ballId) == "number" then
            score = score + 620
            madeGood = true
        end
    end
    if required and result.firstHit == required then
        score = score + 180
    end
    if candidate.kind == "safety" and not madeGood then
        score = score + 170
    end
    return score, madeGood
end

local function openingBreakProbeTicks(difficulty)
    if difficulty.id == "easy" then
        return 1300
    end
    if difficulty.id == "medium" then
        return 1650
    end
    return 2050
end

local function scoreOpeningBreakProbe(state, finalState, playerName, result, candidate)
    local score = candidate.scoreHint or 0
    local legalHit = result.firstHit and PP.isLegalFirstHit(state, result.firstHit, playerName)
    if legalHit then
        score = score + 720
    elseif result.firstHit then
        score = score - 1200
    else
        score = score - 1600
    end
    if result.scratch then
        score = score - 2400
    end
    score = score + math.min(760, (result.impactCount or 0) * 64)
    score = score + math.min(360, (result.railCount or 0) * 36)
    score = score + math.min(220, #(result.sunk or {}) * 85)

    local rackX = PP.RACK_SPOT_X or (PP.TABLE_W * 0.67)
    local rackY = PP.TABLE_H / 2
    local spread = 0
    local advanced = 0
    local r = PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R
    for i = 1, #(finalState and finalState.balls or {}) do
        local ball = finalState.balls[i]
        if ball and type(ball.id) == "number" and not ball.pocketed then
            local dx = ball.x - rackX
            local dy = ball.y - rackY
            spread = spread + math.min(42, math.sqrt(dx * dx + dy * dy) * 0.10)
            if ball.x < rackX - r * 2.5 then
                advanced = advanced + 1
            end
        end
    end
    score = score + math.min(620, spread)
    score = score + math.min(220, advanced * 34)
    return score, legalHit and not result.scratch
end

local function scoreProbe(state, playerName, candidate, difficulty)
    if not PPPhysics or not PPPhysics.simulate then
        return candidate.scoreHint or 0, nil
    end
    local sim = PPPhysics.simulate(state, {
        angle = candidate.angle,
        power = candidate.power,
        spinX = 0,
        spinY = 0,
    }, {
        mode = "ai_probe",
        maxTicks = candidate.meta and candidate.meta.openingBreak and openingBreakProbeTicks(difficulty) or candidateProbeTicks(difficulty),
    })
    local result = sim and sim.result or nil
    if not result or not result.ok then
        return -99999, result
    end

    if candidate.meta and candidate.meta.openingBreak then
        return scoreOpeningBreakProbe(state, sim.finalState, playerName, result, candidate), result
    end

    local score = candidate.scoreHint or 0
    local legalHit = result.firstHit and PP.isLegalFirstHit(state, result.firstHit, playerName)
    if legalHit then
        score = score + 520
    elseif result.firstHit then
        score = score - 1200
    else
        score = score - 900
    end
    if result.scratch then
        score = score - 1800
    end

    local modeId = state.modeId or PP.DEFAULT_MODE_ID
    local madeScore, madeGood
    if modeId == "eight_ball" then
        madeScore, madeGood = scoreEightBallProbe(state, sim.finalState, playerName, result, candidate)
    else
        madeScore, madeGood = scoreNineBallProbe(state, playerName, result, candidate)
    end
    score = score + madeScore

    if result.impactCount and result.impactCount > 0 then
        score = score + math.min(140, result.impactCount * 10)
    end
    if result.railCount and candidate.kind == "bank" then
        score = score + math.min(170, result.railCount * 22)
    elseif result.railCount and candidate.kind == "safety" then
        score = score + math.min(110, result.railCount * 16)
    end
    score = score + cueLeaveScore(sim.finalState, playerName, result, madeGood)
    score = score + randomBetween(-(difficulty.planNoise or 0) * 140, (difficulty.planNoise or 0) * 140)
    return score, result
end

local function addRefinementCandidates(plan, candidate, difficulty)
    if not plan or not candidate then
        return
    end
    local refinements = {}
    local angleSteps = difficulty.id == "hard" and { -0.018, -0.010, 0.010, 0.018, -0.005, 0.005 } or { -0.018, 0.018, -0.009, 0.009 }
    local powerSteps = difficulty.id == "hard" and { 0.88, 0.95, 1.04, 1.12 } or { 0.92, 1.08 }
    for i = 1, #angleSteps do
        addCandidate(refinements, candidate.angle + angleSteps[i], candidate.power, "refine_" .. tostring(candidate.kind), candidate.targetId, (candidate.scoreHint or 0) - 10, candidate.meta)
    end
    for i = 1, #powerSteps do
        addCandidate(refinements, candidate.angle, candidate.power * powerSteps[i], "refine_" .. tostring(candidate.kind), candidate.targetId, (candidate.scoreHint or 0) - 12, candidate.meta)
    end
    for a = 1, math.min(#angleSteps, difficulty.id == "hard" and 4 or 2) do
        for p = 1, #powerSteps do
            addCandidate(refinements, candidate.angle + angleSteps[a], candidate.power * powerSteps[p], "refine_" .. tostring(candidate.kind), candidate.targetId, (candidate.scoreHint or 0) - 24, candidate.meta)
        end
    end
    plan.refinementCandidates = plan.refinementCandidates or {}
    for i = 1, #refinements do
        plan.refinementCandidates[#plan.refinementCandidates + 1] = refinements[i]
    end
end

function PP_AI.applyPlanTiming(plan, difficulty, now)
    if not plan then
        return nil
    end
    now = now or nowMs()
    local aimError = difficulty.aimError or 0
    local powerError = difficulty.powerError or 0
    plan.finalAngle = plan.angle + randomBetween(-aimError, aimError)
    plan.finalPower = clamp(plan.power * (1 + randomBetween(-powerError, powerError)), 45, PP.MAX_POWER)
    plan.startAngle = plan.finalAngle + randomBetween(-aimError * 4.5, aimError * 4.5)
    plan.startPower = clamp(plan.finalPower * (1 + randomBetween(-powerError * 2.0, powerError * 2.0)), 45, PP.MAX_POWER)
    plan.step = 0
    plan.steps = math.max(1, difficulty.aimSteps or 4)
    plan.nextAimAt = now + (difficulty.thinkingMs or 900)
    plan.shootAt = plan.nextAimAt + plan.steps * (difficulty.aimStepMs or 320) + (difficulty.shootDelayMs or 500)
    plan.difficulty = difficulty.id
    return plan
end

local function adoptCandidate(plan, candidate, score, result, difficulty)
    if not plan or not candidate then
        return
    end
    plan.angle = candidate.angle
    plan.power = candidate.power
    plan.kind = candidate.kind
    plan.targetId = candidate.targetId
    plan.scoreHint = candidate.scoreHint
    plan.score = score
    plan.probe = result

    local aimError = difficulty.aimError or 0
    local powerError = difficulty.powerError or 0
    plan.finalAngle = plan.angle + randomBetween(-aimError, aimError)
    plan.finalPower = clamp(plan.power * (1 + randomBetween(-powerError, powerError)), 45, PP.MAX_POWER)
end

local function roughPlanFromCandidates(candidates)
    if candidates and candidates[1] then
        return PP.copyTable(candidates[1])
    end
    return { angle = randomBetween(-math.pi, math.pi), power = 260, kind = "fallback", scoreHint = -400 }
end

function PP_AI.createShotPlanner(state, playerName, difficulty, now)
    difficulty = difficulty or PP.getAIDifficulty("medium")
    local candidates = buildCandidates(state, playerName, difficulty)
    local plan = PP_AI.applyPlanTiming(roughPlanFromCandidates(candidates), difficulty, now)
    plan.candidates = candidates
    plan.probeIndex = 1
    plan.probeLimit = math.min(#candidates, probeLimitForDifficulty(difficulty))
    plan.probeBatch = probeBatchForDifficulty(difficulty)
    plan.bestProbeCandidate = nil
    plan.bestProbeScore = nil
    plan.bestProbeResult = nil
    plan.refinementLimit = refineLimitForDifficulty(difficulty)
    plan.refinementIndex = 1
    plan.planningStage = "broad"
    plan.planningDone = plan.probeLimit <= 0
    plan.planningDeadlineAt = math.max(plan.nextAimAt or nowMs(), (plan.shootAt or nowMs()) - math.max(260, difficulty.shootDelayMs or 500))
    return plan
end

function PP_AI.advanceShotPlanner(state, playerName, difficulty, plan, now, budgetMs)
    if not plan or plan.planningDone then
        return
    end
    difficulty = difficulty or PP.getAIDifficulty("medium")
    now = now or nowMs()
    budgetMs = budgetMs or 8
    local startMs = nowMs()
    local batch = math.max(1, plan.probeBatch or 1)

    while batch > 0 and nowMs() - startMs < budgetMs do
        local candidates = plan.planningStage == "refine" and (plan.refinementCandidates or {}) or (plan.candidates or {})
        local indexKey = plan.planningStage == "refine" and "refinementIndex" or "probeIndex"
        local limit = plan.planningStage == "refine" and math.min(#candidates, plan.refinementLimit or 0) or math.min(#candidates, plan.probeLimit or 0)
        if (plan[indexKey] or 1) > limit then
            if plan.planningStage == "broad" and plan.bestProbeCandidate and (plan.refinementLimit or 0) > 0 then
                addRefinementCandidates(plan, plan.bestProbeCandidate, difficulty)
                plan.planningStage = "refine"
                plan.refinementIndex = 1
            else
                break
            end
        else
            local candidate = candidates[plan[indexKey]]
            local score, result = scoreProbe(state, playerName, candidate, difficulty)
            if not plan.bestProbeCandidate or score > (plan.bestProbeScore or -99999) then
                plan.bestProbeCandidate = PP.copyTable(candidate)
                plan.bestProbeScore = score
                plan.bestProbeResult = result
                if plan.planningStage == "broad" and (plan.refinementLimit or 0) > 0 then
                    addRefinementCandidates(plan, candidate, difficulty)
                end
            end
            plan[indexKey] = (plan[indexKey] or 1) + 1
            batch = batch - 1
        end
    end

    local broadDone = (plan.probeIndex or 1) > (plan.probeLimit or 0)
    local refineDone = (plan.refinementIndex or 1) > math.min(#(plan.refinementCandidates or {}), plan.refinementLimit or 0)
    if (broadDone and (plan.refinementLimit or 0) <= 0) or (broadDone and refineDone) or now >= (plan.planningDeadlineAt or 0) then
        if plan.bestProbeCandidate then
            adoptCandidate(plan, plan.bestProbeCandidate, plan.bestProbeScore, plan.bestProbeResult, difficulty)
            if plan.step >= plan.steps then
                plan.step = math.max(0, plan.steps - 1)
                plan.nextAimAt = now
            end
        end
        plan.candidates = nil
        plan.refinementCandidates = nil
        plan.bestProbeCandidate = nil
        plan.bestProbeResult = nil
        plan.planningDone = true
    end
end

function PP_AI.chooseCuePlacement(state, playerName, difficulty)
    difficulty = difficulty or PP.getAIDifficulty("medium")
    local targets = legalTargetBalls(state, playerName)
    local r = PP.ballPhysicsRadius and PP.ballPhysicsRadius() or PP.BALL_R
    local rails = PP.getRailBounds and PP.getRailBounds() or { left = r, top = r, right = PP.TABLE_W - r, bottom = PP.TABLE_H - r }
    local best = nil

    for x = rails.left + 24, rails.right - 24, difficulty.id == "hard" and 36 or 54 do
        for y = rails.top + 24, rails.bottom - 24, difficulty.id == "hard" and 34 or 44 do
            local clear = PP.isCuePlacementClear(state, x, y)
            if clear then
                local score = randomBetween(-16, 16) + pocketRiskScore(x, y)
                for i = 1, #targets do
                    local target = targets[i]
                    local dx = target.x - x
                    local dy = target.y - y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    local lineClear = segmentClear(state, x, y, target.x, target.y, "cue", target.id, r * 2.08)
                    local ideal = difficulty.id == "easy" and 260 or 320
                    local targetScore = (lineClear and 210 or -90) - math.abs(dist - ideal) * 0.30 - (target.id or 0) * 2
                    if targetScore > score then
                        score = targetScore + pocketRiskScore(x, y)
                    end
                end
                if #targets == 0 then
                    score = score - math.abs(x - PP.CUE_SPOT_X) * 0.2 - math.abs(y - PP.TABLE_H / 2) * 0.4
                end
                if not best or score > best.score then
                    best = { x = x, y = y, score = score }
                end
            end
        end
    end
    return best or { x = PP.CUE_SPOT_X, y = PP.TABLE_H / 2, score = -999 }
end

function PP_AI.nextAim(plan, difficulty, now)
    if not plan or now < (plan.nextAimAt or 0) or plan.step >= plan.steps then
        return nil
    end
    plan.step = plan.step + 1
    local t = clamp(plan.step / plan.steps, 0, 1)
    local settle = 1 - t
    local angle = lerpAngle(plan.startAngle, plan.finalAngle, t)
    local power = plan.startPower + (plan.finalPower - plan.startPower) * t
    angle = angle + randomBetween(-(difficulty.aimError or 0), difficulty.aimError or 0) * settle * 0.45
    power = power * (1 + randomBetween(-(difficulty.powerError or 0), difficulty.powerError or 0) * settle * 0.40)
    plan.nextAimAt = now + (difficulty.aimStepMs or 320)
    return angle, power
end
