require "LifestyleSystems/LSK_SystemDefinitions"
require "LifestyleCore/LSK_ActionAuthority"

LifestyleSecure = LifestyleSecure or {}
local Art = {}
local Defs = LifestyleSecure.SystemDefinitions
local Limits = Defs.Art

Art.allowedSprites = {}

function Art.registerSprite(spriteName)
    spriteName = Defs.identifier(spriteName)
    if not spriteName then
        return false
    end
    for i = 1, #Limits.spritePrefixes do
        if string.sub(spriteName, 1, string.len(Limits.spritePrefixes[i])) == Limits.spritePrefixes[i] then
            Art.allowedSprites[spriteName] = true
            return true
        end
    end
    return false
end

function Art.sanitizeArtwork(data)
    if type(data) ~= "table" then
        return nil, "invalid_artwork"
    end
    local sprite = Defs.identifier(data.sprite)
    local style = Defs.identifier(data.style)
    local size = Defs.identifier(data.size)
    local beauty = Defs.clamp(data.beauty, Limits.beautyMin, Limits.beautyMax)
    if not sprite or Art.allowedSprites[sprite] ~= true
        or not style or not Limits.styles[style]
        or not size or not Limits.sizes[size]
        or beauty == nil then
        return nil, "invalid_artwork_schema"
    end
    return {
        sprite = sprite,
        style = style,
        size = size,
        beauty = beauty,
        authorKey = tostring(data.authorKey or ""),
    }
end

function Art.beginCreation(player, artwork, durationMs)
    local clean, err = Art.sanitizeArtwork(artwork)
    if not clean then
        return nil, err
    end
    clean.authorKey = Defs.playerKey(player)
    durationMs = math.floor(Defs.clamp(durationMs, 5000, 3600000) or 5000)
    local nonce = LSK_ActionAuthority.begin(player, "LSCanvasCreate", durationMs + 30000, clean)
    return nonce, clean
end

function Art.completeCreation(player, nonce, transaction)
    -- World and inventory operations stay injectable until command handlers are migrated.
    if type(transaction) ~= "table" or type(transaction.validateResources) ~= "function"
        or type(transaction.consumeResources) ~= "function"
        or type(transaction.createArtwork) ~= "function" then
        return false, "invalid_transaction_contract"
    end
    return LSK_ActionAuthority.complete(player, "LSCanvasCreate", nonce, function(actor, context)
        local artwork, err = Art.sanitizeArtwork(context)
        if not artwork or artwork.authorKey ~= Defs.playerKey(actor) then
            error(err or "author_mismatch")
        end
        local valid, prepared = transaction.validateResources(actor, artwork)
        if valid ~= true then
            error("resources_unavailable")
        end
        local consumed = transaction.consumeResources(actor, prepared)
        if consumed ~= true then
            error("resource_commit_failed")
        end
        local created = transaction.createArtwork(actor, artwork, prepared)
        if not created then
            if type(transaction.rollback) == "function" then
                transaction.rollback(actor, prepared)
            end
            error("artwork_create_failed")
        end
        local state = Defs.systemState(actor, "Art")
        state.known = Defs.boundedIdList(state.known or {}, nil, Limits.maxKnownArtworks)
        return created
    end)
end

function Art.setBeauty(actor, object, value)
    if not Defs.isAdmin(actor) then
        return false, "admin_only"
    end
    value = Defs.clamp(value, Limits.beautyMin, Limits.beautyMax)
    local data = object and object.getModData and object:getModData() or nil
    if value == nil or not data then
        return false, "invalid_object"
    end
    data.LSKBeauty = value
    if object.transmitModData then
        object:transmitModData()
    end
    return true, value
end

return Art
