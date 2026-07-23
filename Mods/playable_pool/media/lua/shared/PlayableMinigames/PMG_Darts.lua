require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Random"

PMG_Darts = PMG_Darts or {}

PMG_Darts.START_SCORE = 501
PMG_Darts.THROWS_PER_TURN = 3
PMG_Darts.SEGMENTS = { 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5 }
PMG_Darts.GEOMETRY = {
    boardRadius = 0.94,
    scoringOuterRadius = 0.7708,
    doubleInnerRadius = 0.6768,
    tripleOuterRadius = 0.4418,
    tripleInnerRadius = 0.3572,
    outerBullRadius = 0.1410,
    innerBullRadius = 0.0658,
}

local function atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y / x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi / 2
    elseif x == 0 and y < 0 then
        return -math.pi / 2
    end
    return 0
end

local function segmentIndexForBase(base)
    base = tonumber(base) or 20
    for i = 1, #PMG_Darts.SEGMENTS do
        if PMG_Darts.SEGMENTS[i] == base then
            return i
        end
    end
    return 1
end

local function scoreSegment(x, y)
    local angle = atan2(x, -y)
    if angle < 0 then
        angle = angle + math.pi * 2
    end
    local index = math.floor(((angle + math.pi / 20) % (math.pi * 2)) / (math.pi / 10)) + 1
    return PMG_Darts.SEGMENTS[index] or 20
end

local function ringRadius(ring)
    local g = PMG_Darts.GEOMETRY
    if ring == "inner_bull" then
        return 0
    elseif ring == "outer_bull" then
        return (g.innerBullRadius + g.outerBullRadius) / 2
    elseif ring == "double" then
        return (g.doubleInnerRadius + g.scoringOuterRadius) / 2
    elseif ring == "triple" then
        return (g.tripleInnerRadius + g.tripleOuterRadius) / 2
    elseif ring == "outer_single" then
        return (g.tripleOuterRadius + g.doubleInnerRadius) / 2
    end
    return (g.outerBullRadius + g.tripleInnerRadius) / 2
end

function PMG_Darts.targetPoint(base, ring)
    base = tonumber(base) or 20
    ring = ring or "single"
    if base == 25 and (ring == "inner_bull" or ring == "double") then
        return 0, 0
    elseif base == 25 then
        return ringRadius("outer_bull"), 0
    end
    local index = segmentIndexForBase(base)
    local angle = (index - 1) * (math.pi / 10)
    local radius = ringRadius(ring)
    return math.sin(angle) * radius, -math.cos(angle) * radius
end

function PMG_Darts.checkoutTarget(score, dartsLeft)
    score = math.floor(tonumber(score) or PMG_Darts.START_SCORE)
    dartsLeft = math.max(1, math.floor(tonumber(dartsLeft) or 1))
    if score == 50 then
        return { base = 25, ring = "inner_bull", label = "Bull" }
    end
    if score >= 2 and score <= 40 and score % 2 == 0 then
        return { base = score / 2, ring = "double", label = "D" .. tostring(score / 2) }
    end
    if score <= 1 then
        return { base = 20, ring = "single", label = "20" }
    end
    if score <= 60 then
        local preferredDoubles = { 40, 32, 36, 24, 16, 20, 12, 8, 4, 2 }
        for i = 1, #preferredDoubles do
            local remaining = preferredDoubles[i]
            local setup = score - remaining
            if setup >= 1 and setup <= 20 then
                return { base = setup, ring = "single", label = tostring(setup) }
            end
        end
    end
    if dartsLeft >= 2 and score <= 110 then
        for base = 20, 1, -1 do
            local afterTriple = score - base * 3
            if afterTriple == 50 or (afterTriple >= 2 and afterTriple <= 40 and afterTriple % 2 == 0) then
                return { base = base, ring = "triple", label = "T" .. tostring(base) }
            end
        end
    end
    return { base = 20, ring = "triple", label = "T20" }
end

function PMG_Darts.scorePoint(x, y)
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    local r = math.sqrt(x * x + y * y)
    local g = PMG_Darts.GEOMETRY
    if r > g.scoringOuterRadius then
        return { score = 0, base = 0, multiplier = 0, ring = "miss", label = "Miss" }
    end
    if r <= g.innerBullRadius then
        return { score = 50, base = 25, multiplier = 2, ring = "inner_bull", label = "Bull" }
    end
    if r <= g.outerBullRadius then
        return { score = 25, base = 25, multiplier = 1, ring = "outer_bull", label = "Outer bull" }
    end
    local base = scoreSegment(x, y)
    if r >= g.doubleInnerRadius and r <= g.scoringOuterRadius then
        return { score = base * 2, base = base, multiplier = 2, ring = "double", label = "D" .. tostring(base) }
    end
    if r >= g.tripleInnerRadius and r <= g.tripleOuterRadius then
        return { score = base * 3, base = base, multiplier = 3, ring = "triple", label = "T" .. tostring(base) }
    end
    return { score = base, base = base, multiplier = 1, ring = "single", label = tostring(base) }
end

local function centeredScatter(rng, radius)
    local a = (PMG_Random.next(rng) + PMG_Random.next(rng) + PMG_Random.next(rng)) / 3
    local b = (PMG_Random.next(rng) + PMG_Random.next(rng) + PMG_Random.next(rng)) / 3
    return (a - 0.5) * radius * 2, (b - 0.5) * radius * 2
end

function PMG_Darts.resolveThrow(session, playerName, args, context)
    args = args or {}
    local throwNo = tonumber(session.publicState.throwNo) or 0
    local rng = PMG_Random.new(PMG_Random.hash(tostring(session.seed or session.key) .. ":darts:" .. tostring(playerName) .. ":" .. tostring(throwNo + 1)))
    local releaseOffset = PMG.clamp(tonumber(args.releaseOffset) or 0, -1, 1)
    local releaseQuality = PMG.clamp(tonumber(args.releaseQuality) or (1 - math.abs(releaseOffset)), 0, 1)
    local baseScatter = 0.082
    local effectiveQuality = releaseQuality
    local scatterRadius = 0.010 + baseScatter * (1 - effectiveQuality * 0.72)
    local drift = releaseOffset * 0.052
    local scatterX, scatterY = centeredScatter(rng, scatterRadius)
    local defaultX, defaultY = PMG_Darts.targetPoint(20, "triple")
    local aimX = PMG.clamp(tonumber(args.x) or defaultX, -0.99, 0.99)
    local aimY = PMG.clamp(tonumber(args.y) or defaultY, -0.99, 0.99)
    return {
        aimX = aimX,
        aimY = aimY,
        x = aimX + scatterX,
        y = aimY + drift + scatterY,
        scatterRadius = scatterRadius,
        releaseOffset = releaseOffset,
        releaseQuality = releaseQuality,
        releaseEffectiveQuality = effectiveQuality,
    }
end

function PMG_Darts.createState(session)
    session.phase = PMG.PHASE_PLAYING
    session.publicState.variant = "501"
    session.publicState.scores = {}
    session.publicState.turnThrows = {}
    session.publicState.turnScore = 0
    session.publicState.turnStartScore = PMG_Darts.START_SCORE
    session.publicState.lastThrow = nil
    session.publicState.winner = nil
    for i = 1, #(session.players or {}) do
        session.publicState.scores[session.players[i]] = PMG_Darts.START_SCORE
    end
end

function PMG_Darts.onPlayerJoined(session, name)
    session.publicState.scores = session.publicState.scores or {}
    session.publicState.scores[name] = session.publicState.scores[name] or PMG_Darts.START_SCORE
    if #(session.players or {}) == 1 then
        session.publicState.turnStartScore = session.publicState.scores[name]
    end
end

local function beginTurnIfNeeded(session, playerName)
    session.publicState.scores = session.publicState.scores or {}
    session.publicState.turnThrows = session.publicState.turnThrows or {}
    session.publicState.scores[playerName] = session.publicState.scores[playerName] or PMG_Darts.START_SCORE
    if not session.publicState.turnStartPlayer or session.publicState.turnStartPlayer ~= playerName or #session.publicState.turnThrows == 0 then
        session.publicState.turnStartPlayer = playerName
        session.publicState.turnStartScore = session.publicState.scores[playerName]
    end
end

local function finishTurn(session)
    session.publicState.turnThrows = {}
    session.publicState.turnScore = 0
    local nextPlayer = PMG.advanceTurn(session)
    session.publicState.turnStartPlayer = nextPlayer
    session.publicState.turnStartScore = session.publicState.scores[nextPlayer] or PMG_Darts.START_SCORE
end

function PMG_Darts.applyThrow(session, playerName, args, context)
    if session.phase == PMG.PHASE_GAME_OVER then
        return false, "The darts game is already over."
    end
    if PMG.currentPlayerName(session) ~= playerName then
        return false, "It is not your turn."
    end
    beginTurnIfNeeded(session, playerName)
    local resolved = PMG_Darts.resolveThrow(session, playerName, args, context)
    session.publicState.throwNo = (tonumber(session.publicState.throwNo) or 0) + 1
    local hit = PMG_Darts.scorePoint(resolved.x, resolved.y)
    local current = session.publicState.scores[playerName] or PMG_Darts.START_SCORE
    local nextScore = current - hit.score
    local throw = {
        aimX = resolved.aimX,
        aimY = resolved.aimY,
        x = resolved.x,
        y = resolved.y,
        scatterRadius = resolved.scatterRadius,
        releaseOffset = resolved.releaseOffset,
        releaseQuality = resolved.releaseQuality,
        releaseEffectiveQuality = resolved.releaseEffectiveQuality,
        score = hit.score,
        label = hit.label,
        ring = hit.ring,
        base = hit.base,
        multiplier = hit.multiplier,
    }
    table.insert(session.publicState.turnThrows, throw)
    session.publicState.lastThrow = throw
    session.publicState.turnScore = (tonumber(session.publicState.turnScore) or 0) + hit.score

    local isDoubleFinish = hit.multiplier == 2
    if nextScore < 0 or nextScore == 1 or (nextScore == 0 and not isDoubleFinish) then
        session.publicState.scores[playerName] = session.publicState.turnStartScore or current
        session.publicState.turnScore = 0
        PMG.addEvent(session, playerName .. " busted on " .. tostring(hit.label) .. ".", "bust")
        finishTurn(session)
        return true
    end

    session.publicState.scores[playerName] = nextScore
    if nextScore == 0 then
        session.publicState.winner = playerName
        session.publicState.winReason = playerName .. " finished 501 with " .. tostring(hit.label) .. "."
        PMG.setPhase(session, PMG.PHASE_GAME_OVER)
        PMG.addEvent(session, session.publicState.winReason, "win")
        return true
    end

    if hit.score <= 0 then
        PMG.addEvent(session, playerName .. " missed the board.", "score")
    else
        PMG.addEvent(session, playerName .. " hit " .. tostring(hit.label) .. " for " .. tostring(hit.score) .. ".", "score")
    end
    if #session.publicState.turnThrows >= PMG_Darts.THROWS_PER_TURN then
        finishTurn(session)
    end
    return true
end
