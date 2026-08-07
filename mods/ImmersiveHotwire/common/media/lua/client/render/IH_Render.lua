local RenderConfig = require "render/IH_RenderConfig"
local Utils = require "util/IH_Utils"
local WireModel = require "gameplay/IH_WireModel"

local WIRES = RenderConfig.WIRES
local WIRE_TINTS = RenderConfig.WIRE_TINTS

local M = {}

function M.getTint(color)
    local tint = color and WIRE_TINTS[color] or nil
    if tint then
        return tint[1] or 1, tint[2] or 1, tint[3] or 1
    end
    return 1, 1, 1
end

local function pushLayer(layers, tex, r, g, b, alpha)
    layers[#layers + 1] = {
        tex = tex,
        r = r or 1,
        g = g or 1,
        b = b or 1,
        alpha = alpha or 1.0,
    }
end

function M.buildWireLayers(textures, wire)
    local layers = {}
    local mergedCount = WireModel.countRoles(wire)
    local tex = textures.wires and textures.wires[wire.texId or 1] or nil
    local isCut = wire.cut == true
    local cutBase = isCut and textures.wireCutBase and textures.wireCutBase[wire.texId or 1] or nil
    local cutTint = isCut and textures.wireCutTint and textures.wireCutTint[wire.texId or 1] or nil

    if mergedCount >= 3 and textures.wireMerged3Base then
        local colors = wire.mergedColors or {
            wire.mergedLeftColor or wire.color,
            wire.mergedCenterColor or wire.color,
            wire.mergedRightColor or wire.color,
        }
        pushLayer(layers, textures.wireMerged3Base, 1, 1, 1, 1.0)
        if textures.wireMerged3TintLeft then
            local lr, lg, lb = M.getTint(colors[1])
            pushLayer(layers, textures.wireMerged3TintLeft, lr, lg, lb, 1.0)
        end
        if textures.wireMerged3TintCenter then
            local cr, cg, cb = M.getTint(colors[2])
            pushLayer(layers, textures.wireMerged3TintCenter, cr, cg, cb, 1.0)
        end
        if textures.wireMerged3TintRight then
            local rr, rg, rb = M.getTint(colors[3])
            pushLayer(layers, textures.wireMerged3TintRight, rr, rg, rb, 1.0)
        end
        return layers
    end

    if mergedCount == 2 and textures.wireMerged2Base then
        local leftColor = wire.mergedLeftColor or wire.color
        local rightColor = wire.mergedRightColor or wire.color
        pushLayer(layers, textures.wireMerged2Base, 1, 1, 1, 1.0)
        if textures.wireMerged2TintLeft then
            local lr, lg, lb = M.getTint(leftColor)
            pushLayer(layers, textures.wireMerged2TintLeft, lr, lg, lb, 1.0)
        end
        if textures.wireMerged2TintRight then
            local rr, rg, rb = M.getTint(rightColor)
            pushLayer(layers, textures.wireMerged2TintRight, rr, rg, rb, 1.0)
        end
        return layers
    end

    if wire.taped and tex then
        local r, g, b = M.getTint(wire.color)
        pushLayer(layers, tex, r, g, b, 1.0)
        local tapedTex = textures.wireTaped and textures.wireTaped[wire.texId or 1] or nil
        if tapedTex then
            pushLayer(layers, tapedTex, 1, 1, 1, 1.0)
        end
        return layers
    end

    if cutBase or cutTint then
        local baseTex = cutBase or tex
        pushLayer(layers, baseTex, 1, 1, 1, 1.0)
        if cutTint then
            local r, g, b = M.getTint(wire.color)
            pushLayer(layers, cutTint, r, g, b, 1.0)
        end
        return layers
    end

    if tex then
        local r, g, b = M.getTint(wire.color)
        pushLayer(layers, tex, r, g, b, 1.0)
    end

    return layers
end

local function drawRotatedWire(self, tex, x, y, w, h, angleDeg, alpha, r, g, b, wireScale)
    local pivotX, pivotY = Utils.getWirePivot(x, y, h, wireScale, WIRES.PIVOT_X, WIRES.PIVOT_Y)
    local angle = math.rad(angleDeg or 0)
    local cosT = math.cos(angle)
    local sinT = math.sin(angle)
    local function rotate(lx, ly)
        local ox = lx - pivotX
        local oy = ly - pivotY
        return (ox * cosT) - (oy * sinT) + pivotX, (ox * sinT) + (oy * cosT) + pivotY
    end
    local tlx, tly = rotate(x, y)
    local trx, try = rotate(x + w, y)
    local brx, bry = rotate(x + w, y + h)
    local blx, bly = rotate(x, y + h)
    local absX = self:getAbsoluteX()
    local absY = self:getAbsoluteY()
    self:drawTextureAllPoint(
        tex,
        tlx + absX, tly + absY,
        trx + absX, try + absY,
        brx + absX, bry + absY,
        blx + absX, bly + absY,
        r or 1, g or 1, b or 1, alpha or 1.0
    )
end

function M.drawWire(self, slot, layers, opts)
    local angleDeg = opts.angle
    local alpha = opts.alpha or 1.0
    local scale = slot.scale or 1
    for _, layer in ipairs(layers) do
        local layerAlpha = alpha * (layer.alpha or 1.0)
        if angleDeg then
            drawRotatedWire(self, layer.tex, slot.x, slot.y, slot.w, slot.h, angleDeg, layerAlpha, layer.r, layer.g, layer.b, scale)
        else
            self:drawTextureScaled(layer.tex, slot.x, slot.y, slot.w, slot.h, layerAlpha, layer.r, layer.g, layer.b)
        end
    end
end

function M.drawWireTails(self, hoverIndex, hoverAlpha)
    for slotIdx, slot in ipairs(self.wireSlots) do
        local wireIndex = slot.internal or slotIdx
        local wire = self.wires[wireIndex]

        if wire.cut and not wire.tailHidden then
            local tailTex = self:getWireTailTexture(wire)
            if tailTex then
                local x = slot.x
                local y = slot.y
                if self.dragging and self.dragging.index == wireIndex then
                    x = self.dragging.homeX
                    y = self.dragging.homeY
                end

                local alpha = 1
                if hoverIndex == wireIndex then
                    alpha = hoverAlpha or 1
                end

                local tailBase, tailTint = self:getWireTailLayers(wire)
                if tailBase or tailTint then
                    local baseTex = tailBase or tailTex
                    self:drawTextureScaled(baseTex, x, y, slot.w, slot.h, alpha, 1, 1, 1)
                    if tailTint then
                        local r, g, b = M.getTint(wire.color)
                        self:drawTextureScaled(tailTint, x, y, slot.w, slot.h, alpha, r, g, b)
                    end
                else
                    local r, g, b = M.getTint(wire.color)
                    self:drawTextureScaled(tailTex, x, y, slot.w, slot.h, alpha, r, g, b)
                end
            end
        end
    end
end

function M.drawTooltip(self, mx, my, text)
    if not text then return end
    if mx < 0 or my < 0 or mx > self.width or my > self.height then return end
    local font = UIFont.Small
    local pad = 4
    local textW = 0
    local lineCount = 0
    for line in string.gmatch(text, "([^\n]+)") do
        lineCount = lineCount + 1
        local w = getTextManager():MeasureStringX(font, line)
        if w > textW then
            textW = w
        end
    end
    if lineCount == 0 then
        lineCount = 1
        textW = getTextManager():MeasureStringX(font, text)
    end
    local lineH = getTextManager():getFontHeight(font)
    local textH = lineH * lineCount
    local x = mx + 12
    local y = my + 18
    local w = textW + (pad * 2)
    local h = textH + (pad * 2)
    local edgePad = 2
    if x + w > self.width - edgePad then x = self.width - w - edgePad end
    if y + h > self.height - edgePad then y = self.height - h - edgePad end
    if x < edgePad then x = edgePad end
    if y < edgePad then y = edgePad end
    self:drawRect(x, y, w, h, 0.85, 0, 0, 0)
    self:drawRectBorder(x, y, w, h, 0.9, 1, 1, 1)
    self:drawText(text, x + pad, y + pad, 1, 1, 1, 1, font)
end

return M



