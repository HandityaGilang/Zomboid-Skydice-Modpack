NMZombieVisualTargetLedger = NMZombieVisualTargetLedger or {}
require "zombies/NMZombieAudioVisualSupport"
require "zombies/NMZombieDeviceVariantCatalog"
require "zombies/NMZombieSandboxRarity"
NMZombieVisualTargetLedger._recordsByZombieId = NMZombieVisualTargetLedger._recordsByZombieId or {}
NMZombieVisualTargetLedger._selectionEpoch = NMZombieVisualTargetLedger._selectionEpoch or 0
NMZombieVisualTargetLedger._diag = NMZombieVisualTargetLedger._diag or {
    assigned = 0,
    reusedMemory = 0,
    reusedStamp = 0,
    zombieStamped = 0,
    corpseStamped = 0
}

local function shouldLog()
    return NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("zombieDiagnostics") == true
end

local function logSummary(tag, detail)
    if not shouldLog() then
        return
    end
    print("[NewMusic] [ZombieProof] " .. tostring(tag or "") .. " " .. tostring(detail or ""))
end

local function getProofModData(holder)
    return NMZombieAudioVisualSupport and NMZombieAudioVisualSupport.getProofModData and NMZombieAudioVisualSupport.getProofModData(holder) or nil
end

local function copyRecord(record)
    if type(record) ~= "table" then
        return nil
    end
    local variantId = tostring(record.variantId or (((record.musicSelected == true or record.selected == true) and "walkman") or "none"))
    local musicSelected = record.musicSelected == true or variantId ~= "none"
    return {
        zombieId = tostring(record.zombieId or ""),
        musicSelected = musicSelected,
        selected = record.selected == true or musicSelected,
        variantId = variantId,
        strategy = tostring(record.strategy or ""),
        selectionEpoch = tonumber(record.selectionEpoch) or 0,
        selectionSource = tostring(record.selectionSource or "server_ledger")
    }
end

local function readStampedRecord(holder, fallbackZombieId)
    local md = getProofModData(holder)
    if type(md) ~= "table" then
        return nil
    end
    if md.selectionSource ~= "server_ledger" then
        return nil
    end
    local zombieId = tostring(md.selectionZombieId or fallbackZombieId or "")
    if zombieId == "" then
        return nil
    end
    local variantId = tostring(md.variantId or (((md.musicSelected == true or md.selected == true) and "walkman") or "none"))
    local musicSelected = md.musicSelected == true or variantId ~= "none"
    return {
        zombieId = zombieId,
        musicSelected = musicSelected,
        selected = md.selected == true or musicSelected,
        variantId = variantId,
        strategy = tostring(md.strategy or md.liveVisualStrategy or ""),
        selectionEpoch = tonumber(md.selectionEpoch) or 0,
        selectionSource = tostring(md.selectionSource or "server_ledger")
    }
end

local function writeStamp(holder, record, extraFields)
    local md = getProofModData(holder)
    if type(md) ~= "table" then
        return false
    end
    local variantId = tostring(record and record.variantId or (((record and (record.musicSelected == true or record.selected == true)) and "walkman") or "none"))
    md.musicSelected = record and (record.musicSelected == true or variantId ~= "none") or false
    md.selected = record and (record.selected == true or md.musicSelected == true) or false
    md.variantId = variantId
    md.selectionSource = tostring(record and record.selectionSource or "server_ledger")
    md.selectionEpoch = tonumber(record and record.selectionEpoch) or 0
    md.selectionZombieId = tostring(record and record.zombieId or "")
    if tostring(record and record.strategy or "") ~= "" then
        md.strategy = tostring(record.strategy)
    end
    if type(extraFields) == "table" then
        for key, value in pairs(extraFields) do
            md[key] = value
        end
    end
    if holder and holder.transmitModData then
        pcall(holder.transmitModData, holder)
    end
    return true
end

function NMZombieVisualTargetLedger.getZombieSelectionById(zombieId)
    local key = tostring(zombieId or "")
    if key == "" then
        return nil
    end
    return copyRecord(NMZombieVisualTargetLedger._recordsByZombieId[key])
end

function NMZombieVisualTargetLedger.stampZombieSelection(zombie, record)
    if not (zombie and record) then
        return false
    end
    local stamped = writeStamp(zombie, record)
    if stamped then
        NMZombieVisualTargetLedger._diag.zombieStamped = (NMZombieVisualTargetLedger._diag.zombieStamped or 0) + 1
    end
    return stamped
end

function NMZombieVisualTargetLedger.applySelectionToModData(modData, record, strategyName)
    if NMZombieAudioVisualSupport and NMZombieAudioVisualSupport.applySelectionFields then
        NMZombieAudioVisualSupport.applySelectionFields(modData, record, strategyName)
        return
    end
    if type(modData) ~= "table" or type(record) ~= "table" then
        return
    end
    modData.musicSelected = record.musicSelected == true
    modData.selected = record.selected == true
    modData.variantId = tostring(record.variantId or "none")
    modData.selectionSource = tostring(record.selectionSource or "server_ledger")
    modData.selectionEpoch = tonumber(record.selectionEpoch) or 0
    modData.selectionZombieId = tostring(record.zombieId or "")
    if tostring(strategyName or record.strategy or "") ~= "" then
        modData.strategy = tostring(strategyName or record.strategy)
    end
end

function NMZombieVisualTargetLedger.stampCorpseSelection(body, record, corpseHadProof)
    if not (body and record) then
        return false
    end
    local stamped = writeStamp(body, record, {
        corpseHadProof = corpseHadProof == true,
        corpseSettled = true
    })
    if stamped then
        NMZombieVisualTargetLedger._diag.corpseStamped = (NMZombieVisualTargetLedger._diag.corpseStamped or 0) + 1
    end
    return stamped
end

function NMZombieVisualTargetLedger.getOrAssignZombieSelection(zombie, strategy)
    local zombieId = NMZombieVisualTargetContract and NMZombieVisualTargetContract.getZombieId and NMZombieVisualTargetContract.getZombieId(zombie) or tostring(zombie or "")
    if zombieId == "" then
        return nil
    end
    local existing = NMZombieVisualTargetLedger._recordsByZombieId[zombieId]
    if existing then
        NMZombieVisualTargetLedger._diag.reusedMemory = (NMZombieVisualTargetLedger._diag.reusedMemory or 0) + 1
        NMZombieVisualTargetLedger.stampZombieSelection(zombie, existing)
        return copyRecord(existing)
    end
    local stamped = readStampedRecord(zombie, zombieId)
    if stamped then
        if stamped.strategy == "" then
            stamped.strategy = tostring(strategy or "")
        end
        if stamped.selectionEpoch <= 0 then
            NMZombieVisualTargetLedger._selectionEpoch = (tonumber(NMZombieVisualTargetLedger._selectionEpoch) or 0) + 1
            stamped.selectionEpoch = NMZombieVisualTargetLedger._selectionEpoch
        end
        NMZombieVisualTargetLedger._recordsByZombieId[zombieId] = copyRecord(stamped)
        NMZombieVisualTargetLedger._diag.reusedStamp = (NMZombieVisualTargetLedger._diag.reusedStamp or 0) + 1
        NMZombieVisualTargetLedger.stampZombieSelection(zombie, stamped)
        return copyRecord(stamped)
    end
    NMZombieVisualTargetLedger._selectionEpoch = (tonumber(NMZombieVisualTargetLedger._selectionEpoch) or 0) + 1
    local musicalRate = NMRuntimeConfig and NMRuntimeConfig.getMusicalZombiesSpawnRate and NMRuntimeConfig.getMusicalZombiesSpawnRate() or 0.6
    local outcome = NMZombieSandboxRarity and NMZombieSandboxRarity.resolveMusicZombieOutcome and NMZombieSandboxRarity.resolveMusicZombieOutcome(zombieId, musicalRate) or nil
    local record = {
        zombieId = zombieId,
        musicSelected = outcome and outcome.musicSelected == true or false,
        selected = outcome and outcome.selected == true or false,
        variantId = tostring(outcome and outcome.variantId or "none"),
        strategy = tostring(strategy or ""),
        selectionEpoch = NMZombieVisualTargetLedger._selectionEpoch,
        selectionSource = "server_ledger"
    }
    NMZombieVisualTargetLedger._recordsByZombieId[zombieId] = copyRecord(record)
    NMZombieVisualTargetLedger._diag.assigned = (NMZombieVisualTargetLedger._diag.assigned or 0) + 1
    NMZombieVisualTargetLedger.stampZombieSelection(zombie, record)
    return copyRecord(record)
end

function NMZombieVisualTargetLedger.getStampedSelection(holder, fallbackZombieId)
    return copyRecord(readStampedRecord(holder, fallbackZombieId))
end

function NMZombieVisualTargetLedger.logDiag(tag)
    logSummary(
        tag or "target_ledger",
        string.format(
            "assigned=%s reusedMemory=%s reusedStamp=%s zombieStamped=%s corpseStamped=%s",
            tostring(NMZombieVisualTargetLedger._diag.assigned or 0),
            tostring(NMZombieVisualTargetLedger._diag.reusedMemory or 0),
            tostring(NMZombieVisualTargetLedger._diag.reusedStamp or 0),
            tostring(NMZombieVisualTargetLedger._diag.zombieStamped or 0),
            tostring(NMZombieVisualTargetLedger._diag.corpseStamped or 0)
        )
    )
end

return NMZombieVisualTargetLedger
