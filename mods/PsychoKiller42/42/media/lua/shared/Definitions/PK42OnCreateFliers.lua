PsychoKillerFliers = PsychoKillerFliers or {}

PsychoKillerFliers.OnCreateDiaryPage = function(item)
    if not item then return end

    local fullType = item:getFullType()              -- PK42.PsychoFlierPage1
    local page = string.match(fullType, "%.(.+)$")   -- PsychoFlierPage1
    if not page then return end

    -- PrintMedia exclusivo (igual ao Flier Nolan)
    item:getModData().printMedia = {
        id    = page,
        title = "Print_Media_" .. page .. "_title",
        info  = "Print_Media_" .. page .. "_info",
        text  = "Print_Text_"  .. page .. "_info",
    }
end