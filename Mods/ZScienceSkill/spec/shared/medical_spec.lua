local player   = get_player()
local bodyPart = player:getBodyDamage():getBodyPart(BodyPartType.Hand_L)

describe(ISApplyBandage, function()
    local bandage = create_item("Base.Bandage")

    it("has shorter duration with higher Science skill", function()
        player:setPerkLevelDebug(Perks.Science, 10)
        local dur10 = described_class:new(player, player, bandage, bodyPart, true):getDuration()
        player:setPerkLevelDebug(Perks.Science, 5)
        local dur05 = described_class:new(player, player, bandage, bodyPart, true):getDuration()
        player:setPerkLevelDebug(Perks.Science, 0)
        local dur00 = described_class:new(player, player, bandage, bodyPart, true):getDuration()

        assert(dur10 < dur05)
        assert(dur05 < dur00)
    end)

    pending("has longer bandage life with higher Science skill")
end)

describe(ISDisinfect, function()
    local alcohol = create_item("Base.AlcoholWipes")

    it("has shorter duration with higher Science skill", function()
        player:setPerkLevelDebug(Perks.Science, 10)
        local dur10 = described_class:new(player, player, alcohol, bodyPart):getDuration()
        player:setPerkLevelDebug(Perks.Science, 5)
        local dur05 = described_class:new(player, player, alcohol, bodyPart):getDuration()
        player:setPerkLevelDebug(Perks.Science, 0)
        local dur00 = described_class:new(player, player, alcohol, bodyPart):getDuration()

        assert(dur10 < dur05)
        assert(dur05 < dur00)
    end)
end)

describe(ISSplint, function()
    local splint = create_item("Base.Splint")

    it("has shorter duration with higher Science skill", function()
        player:setPerkLevelDebug(Perks.Science, 10)
        local dur10 = described_class:new(player, player, splint, bodyPart, true):getDuration()
        player:setPerkLevelDebug(Perks.Science, 5)
        local dur05 = described_class:new(player, player, splint, bodyPart, true):getDuration()
        player:setPerkLevelDebug(Perks.Science, 0)
        local dur00 = described_class:new(player, player, splint, bodyPart, true):getDuration()

        assert(dur10 < dur05)
        assert(dur05 < dur00)
    end)
end)

return ZBSpec.runAsync()
