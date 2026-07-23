require "LifestyleSystems/LSK_SystemDefinitions"
require "LifestyleCore/LSK_ActionAuthority"

LifestyleSecure = LifestyleSecure or {}
local Invention = {}
local Defs = LifestyleSecure.SystemDefinitions
local Limits = Defs.Invention

Invention.sessions = {}

function Invention.isKnown(inventionId)
    return Defs.identifier(inventionId) ~= nil and Limits.ids[inventionId] == true
end

function Invention.sanitizeItems(items, maximum)
    if type(items) ~= "table" or #items > maximum then
        return nil, "item_limit"
    end
    local clean = {}
    for i = 1, #items do
        local entry = items[i]
        local itemType = type(entry) == "table" and Defs.identifier(entry.type) or nil
        local quantity = type(entry) == "table"
            and Defs.clamp(entry.quantity, 1, Limits.maxQuantity) or nil
        if not itemType or not quantity then
            return nil, "invalid_item"
        end
        clean[#clean + 1] = { type = itemType, quantity = math.floor(quantity) }
    end
    return clean
end

function Invention.beginSession(player, mode, inventionId, durationMs, contract)
    if (mode ~= "Research" and mode ~= "Production") or not Invention.isKnown(inventionId) then
        return nil, "invalid_session"
    end
    contract = type(contract) == "table" and contract or {}
    local ingredients, ingredientError = Invention.sanitizeItems(
        contract.ingredients or {},
        Limits.maxIngredients
    )
    local outputs, outputError = Invention.sanitizeItems(contract.outputs or {}, Limits.maxOutputs)
    if not ingredients or not outputs then
        return nil, ingredientError or outputError
    end
    local key = Defs.playerKey(player)
    if not key or Invention.sessions[key] then
        return nil, "action_busy"
    end
    durationMs = math.floor(Defs.clamp(durationMs, 5000, 3600000) or 5000)
    local actionName = "LSIW" .. mode
    local context = {
        inventionId = inventionId,
        mode = mode,
        ingredients = ingredients,
        outputs = outputs,
        upgradeId = Defs.identifier(contract.upgradeId),
        upgradeLevel = Defs.clamp(contract.upgradeLevel, 0, Limits.maxUpgradeLevel),
    }
    local nonce = LSK_ActionAuthority.begin(player, actionName, durationMs + 30000, context)
    if not nonce then
        return nil, "session_rejected"
    end
    Invention.sessions[key] = {
        nonce = nonce,
        actionName = actionName,
        expiresAt = Defs.now() + durationMs + 30000,
    }
    return nonce, context
end

function Invention.completeSession(player, nonce, transaction)
    local key = Defs.playerKey(player)
    local session = key and Invention.sessions[key] or nil
    if not session or session.nonce ~= nonce then
        return false, "invalid_session"
    end
    Invention.sessions[key] = nil
    -- The adapter owns validation/order; integration supplies concrete inventory mutations.
    if type(transaction) ~= "table" or type(transaction.hasIngredients) ~= "function"
        or type(transaction.consumeIngredients) ~= "function"
        or type(transaction.createOutputs) ~= "function" then
        return false, "invalid_transaction_contract"
    end
    return LSK_ActionAuthority.complete(player, session.actionName, nonce, function(actor, context)
        if not Invention.isKnown(context.inventionId) then
            error("unknown_invention")
        end
        local available, prepared = transaction.hasIngredients(actor, context.ingredients, context)
        if available ~= true then
            error("ingredients_unavailable")
        end
        if transaction.consumeIngredients(actor, context.ingredients, prepared) ~= true then
            error("ingredient_commit_failed")
        end
        local outputs = transaction.createOutputs(actor, context.outputs, context, prepared)
        if outputs == false or outputs == nil then
            if type(transaction.rollback) == "function" then
                transaction.rollback(actor, context.ingredients, prepared)
            end
            error("output_commit_failed")
        end
        if context.mode == "Research" then
            Invention.markResearched(actor, context.inventionId)
            if context.upgradeId and context.upgradeLevel then
                Invention.setUpgradeLevel(
                    actor,
                    context.inventionId,
                    context.upgradeId,
                    context.upgradeLevel
                )
            end
        end
        return outputs
    end)
end

function Invention.markResearched(player, inventionId)
    if not Invention.isKnown(inventionId) then
        return false
    end
    local state = Defs.systemState(player, "Invention")
    state.researched = type(state.researched) == "table" and state.researched or {}
    state.researched[inventionId] = true
    return true
end

function Invention.setUpgradeLevel(player, inventionId, upgradeId, level)
    if not Invention.isKnown(inventionId) or not Defs.identifier(upgradeId) then
        return false, "invalid_upgrade"
    end
    level = Defs.clamp(level, 0, Limits.maxUpgradeLevel)
    if level == nil or level ~= math.floor(level) then
        return false, "invalid_level"
    end
    local state = Defs.systemState(player, "Invention")
    state.upgrades = type(state.upgrades) == "table" and state.upgrades or {}
    state.upgrades[inventionId] = type(state.upgrades[inventionId]) == "table"
        and state.upgrades[inventionId] or {}
    local current = tonumber(state.upgrades[inventionId][upgradeId]) or 0
    if level < current then
        return false, "upgrade_regression"
    end
    state.upgrades[inventionId][upgradeId] = level
    return true, level
end

function Invention.cleanupPlayer(player)
    local key = Defs.playerKey(player)
    if key then
        Invention.sessions[key] = nil
    end
end

return Invention
