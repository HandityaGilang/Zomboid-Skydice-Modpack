describe("IGUI_HerbalistUnlocked", function()
    it("is defined", function()
        assert(getText(subject))
        assert(getText(subject) ~= subject)
    end)
end)

return ZBSpec.runAsync()
