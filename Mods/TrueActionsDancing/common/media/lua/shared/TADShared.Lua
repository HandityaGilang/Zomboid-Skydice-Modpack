
TAD = TAD or {}

TAD.inhibitedBrokenAnimations = {
}

TAD.OrdinaryDanceBook = {
}

TAD.DifficultDanceBook = {
}

TAD.DifficultDanceBookMap = {
}

local emotesInit = false
local function compareEmoteTranslationStr(a,b)
    local textA = getText('IGUI_Emote_'..a)
    local textB = getText('IGUI_Emote_'..b)
    return textA < textB
end

function TAD.initTAD()--call onLoad to avoid emote stutter ?
    if not emotesInit then
        --inhibition
        local inhibMap = {}
        for nbInhib=1, #TAD.inhibitedBrokenAnimations do
            local key2Inhibit = TAD.inhibitedBrokenAnimations[nbInhib]
            inhibMap[key2Inhibit] = key2Inhibit
        end
    
    
    
        local sm = getScriptManager()
        local ordinaryDanceMagList = sm:getItemsTag(TAD.TAG_DanceMag)
        for iterItem=0, ordinaryDanceMagList:size()-1 do
            local item = ordinaryDanceMagList:get(iterItem)
            local name = item and item:getName()
            local danceKey = name and string.split(name,'_Mag')[1]
            if danceKey and not inhibMap[danceKey] then
                TAD.OrdinaryDanceBook[#TAD.OrdinaryDanceBook+1]=danceKey
            end
        end
        table.sort(TAD.OrdinaryDanceBook, compareEmoteTranslationStr)
        
        local difficultDanceCardList = sm:getItemsTag(TAD.TAG_DanceCard)
        for iterItem=0, difficultDanceCardList:size()-1 do
            local item = difficultDanceCardList:get(iterItem)
            local fullType = item and item:getFullName()
            local name = item and item:getName()
            local danceKey = name and string.split(name,'_card')[1]
            if danceKey and not inhibMap[danceKey] then
                TAD.DifficultDanceBookMap[fullType]=danceKey
                TAD.DifficultDanceBook[#TAD.DifficultDanceBook+1]=fullType
            end
        end
        table.sort(TAD.DifficultDanceBook, compareEmoteTranslationStr)
        
        emotesInit = true
    end
end