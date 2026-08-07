local M = {}

local function loadSeries(prefix, count)
    local textures = {}
    for i = 1, count do
        textures[i] = getTexture(prefix .. i .. ".png")
    end
    return textures
end

function M.getWireTexture(self, wire)
    if not self.textures then
        return nil
    end

    local id = wire.texId or 1

    local bank = self.textures.wires
    return bank and bank[id] or nil
end

function M.getWireTailTexture(self, wire)
    if not self.textures then
        return nil
    end
    local id = wire.texId or 1
    local base = self.textures.wireTailBase and self.textures.wireTailBase[id] or nil
    if base then
        return base
    end
    local tint = self.textures.wireTailTint and self.textures.wireTailTint[id] or nil
    return tint
end

function M.getMerged2Layers(self)
    if not self.textures then
        return nil
    end
    local base = self.textures.wireMerged2Base or nil
    local tintLeft = self.textures.wireMerged2TintLeft or nil
    local tintRight = self.textures.wireMerged2TintRight or nil
    if base or tintLeft or tintRight then
        return base, tintLeft, tintRight
    end
    return nil
end

function M.getMerged3Layers(self)
    if not self.textures then
        return nil
    end
    local base = self.textures.wireMerged3Base or nil
    local tintLeft = self.textures.wireMerged3TintLeft or nil
    local tintCenter = self.textures.wireMerged3TintCenter or nil
    local tintRight = self.textures.wireMerged3TintRight or nil
    if base or tintLeft or tintCenter or tintRight then
        return base, tintLeft, tintCenter, tintRight
    end
    return nil
end

function M.getWireCutLayers(self, wire)
    if not wire.cut or not self.textures then
        return nil
    end
    local id = wire.texId or 1
    local base = self.textures.wireCutBase and self.textures.wireCutBase[id] or nil
    local tint = self.textures.wireCutTint and self.textures.wireCutTint[id] or nil
    if base or tint then
        return base, tint
    end
    return nil
end

function M.getWireTailLayers(self, wire)
    if not self.textures then
        return nil
    end
    local id = wire.texId or 1
    local base = self.textures.wireTailBase and self.textures.wireTailBase[id] or nil
    local tint = self.textures.wireTailTint and self.textures.wireTailTint[id] or nil
    if base or tint then
        return base, tint
    end
    return nil
end

function M.loadTextures(self)
    if self.textures then
        return
    end

    local wires = {}

    local baseWires = loadSeries("media/textures/wire_", 4)
    local wireCutBase = loadSeries("media/textures/wire_cut_base_", 4)
    local wireCutTint = loadSeries("media/textures/wire_cut_tint_", 4)
    local wireTailBase = loadSeries("media/textures/wire_tail_base_", 4)
    local wireTailTint = loadSeries("media/textures/wire_tail_tint_", 4)
    local wireTaped = loadSeries("media/textures/wire_taped_", 4)
    local wireMerged2Base = getTexture("media/textures/wire_merged_base_1.png")
    local wireMerged2TintLeft = getTexture("media/textures/wire_merged_tint_left_1.png")
    local wireMerged2TintRight = getTexture("media/textures/wire_merged_tint_right_1.png")
    local wireMerged3Base = getTexture("media/textures/wire_merged_3_base_1.png")
    local wireMerged3TintLeft = getTexture("media/textures/wire_merged_3_tint_left_1.png")
    local wireMerged3TintCenter = getTexture("media/textures/wire_merged_3_tint_center_1.png")
    local wireMerged3TintRight = getTexture("media/textures/wire_merged_3_tint_right_1.png")

    for i = 1, 4 do
        wires[i] = baseWires[i]
    end

    self.textures = {
        background = getTexture("media/textures/background.png"),
        panel = getTexture("media/textures/panel.png"),
        panelOpen = getTexture("media/textures/panel_open.png"),
        screw = getTexture("media/textures/screw.png"),
        line = getTexture("media/ui/white.png"),
        wires = wires,
        wireCutBase = wireCutBase,
        wireCutTint = wireCutTint,
        wireTailBase = wireTailBase,
        wireTailTint = wireTailTint,
        wireTaped = wireTaped,
        wireMerged2Base = wireMerged2Base,
        wireMerged2TintLeft = wireMerged2TintLeft,
        wireMerged2TintRight = wireMerged2TintRight,
        wireMerged3Base = wireMerged3Base,
        wireMerged3TintLeft = wireMerged3TintLeft,
        wireMerged3TintCenter = wireMerged3TintCenter,
        wireMerged3TintRight = wireMerged3TintRight,
    }
end

return M


