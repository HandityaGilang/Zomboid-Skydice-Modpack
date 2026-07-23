local env = _G.NMWalkmanWindowEnv
setfenv(1, env)

function normalizeWalkmanVariantToken(rawToken)
    local text = tostring(rawToken or "")
    local token = text:match("Walkman([A-Za-z]+)$")
        or text:match("NM_Walkman([A-Za-z]+)$")
        or text:match("World_NM_Walkman([A-Za-z]+)$")
        or text:match("^([A-Za-z]+)$")
    token = tostring(token or "")
    if token == "" then
        return nil
    end
    return token
end

function resolveWalkmanVariantFromItem(item)
    if not item then
        return WALKMAN_UI_VARIANT_FALLBACK
    end

    if item.getScriptItem then
        local okScript, scriptItem = pcall(item.getScriptItem, item)
        if okScript and scriptItem then
            if scriptItem.getWorldStaticModel then
                local okWorld, token = pcall(scriptItem.getWorldStaticModel, scriptItem)
                local variant = okWorld and normalizeWalkmanVariantToken(token) or nil
                if variant then
                    return variant
                end
            end
            if scriptItem.getStaticModel then
                local okStatic, token = pcall(scriptItem.getStaticModel, scriptItem)
                local variant = okStatic and normalizeWalkmanVariantToken(token) or nil
                if variant then
                    return variant
                end
            end
        end
    end

    if item.getWorldStaticModel then
        local okWorld, token = pcall(item.getWorldStaticModel, item)
        local variant = okWorld and normalizeWalkmanVariantToken(token) or nil
        if variant then
            return variant
        end
    end

    if item.getStaticModel then
        local okStatic, token = pcall(item.getStaticModel, item)
        local variant = okStatic and normalizeWalkmanVariantToken(token) or nil
        if variant then
            return variant
        end
    end

    if item.getFullType then
        local variant = normalizeWalkmanVariantToken(item:getFullType())
        if variant then
            return variant
        end
    end

    if item.getType then
        local variant = normalizeWalkmanVariantToken(item:getType())
        if variant then
            return variant
        end
    end

    return WALKMAN_UI_VARIANT_FALLBACK
end

function getWalkmanUITexturesForVariant(variant)
    local token = normalizeWalkmanVariantToken(variant) or WALKMAN_UI_VARIANT_FALLBACK
    local cached = WALKMAN_UI_TEXTURES_BY_VARIANT[token]
    if cached then
        return cached
    end

    local basePath = BACKPLATE_BASE_TEXTURE_PATH
    if token == "White" then
        basePath = BACKPLATE_BASE_DARK_TEXTURE_PATH
    end

    local textures = {
        variant = token,
        base = getTexture and getTexture(basePath) or nil,
        side = getTexture and getTexture("media/textures/UI/Walkman/NM_UI_Walkman_Side_" .. token .. ".png") or nil,
        lid = getTexture and getTexture("media/textures/UI/Walkman/NM_UI_Walkman_Lid_" .. token .. ".png") or nil,
        play = nil,
        prev = nil,
        next = nil,
    }
    if token == "White" then
        textures.play = getTexture and getTexture(PLAY_BUTTON_DARK_TEXTURE_PATH) or nil
        textures.prev = getTexture and getTexture(PREV_BUTTON_DARK_TEXTURE_PATH) or nil
        textures.next = getTexture and getTexture(NEXT_BUTTON_DARK_TEXTURE_PATH) or nil
    else
        textures.play = getTexture and getTexture(PLAY_BUTTON_TEXTURE_PATH) or nil
        textures.prev = getTexture and getTexture(PREV_BUTTON_TEXTURE_PATH) or nil
        textures.next = getTexture and getTexture(NEXT_BUTTON_TEXTURE_PATH) or nil
    end
    WALKMAN_UI_TEXTURES_BY_VARIANT[token] = textures
    return textures
end
function WalkmanWindow:resolveWalkmanUIVariant()
    local resolved = self:resolveContextCached()
    local item = resolved and resolved.item or nil
    return resolveWalkmanVariantFromItem(item)
end

function WalkmanWindow:resolveWalkmanUITextures()
    return getWalkmanUITexturesForVariant(self:resolveWalkmanUIVariant())
end

