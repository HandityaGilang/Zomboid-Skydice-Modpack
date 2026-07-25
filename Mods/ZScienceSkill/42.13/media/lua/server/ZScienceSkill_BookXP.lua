-- Grant Science XP when reading skill books or science literature
require "ZScienceSkill/Data"

-- MP:
-- ISReadABook:perform()  is called on client ONLY
-- ISReadABook:complete() is called on server ONLY

-- SP: both are called, perform() -> complete()

zdk.hook({
    ISReadABook = {
        complete = function(orig, self)
            local isAlreadyRead = self.isLiteratureRead -- may be set by ISReadABook:perform(), but not in all contexts
            if isAlreadyRead == nil then
                isAlreadyRead = ZScienceSkill.isLiteratureRead(self.character, self.item, self.startPage)
            end

            local result = orig(self) -- saves literature read flags
            local fullType = self.item:getFullType()

            -- Check if this is read-once literature
            if ZScienceSkill.Data.literatureReadOnce[fullType] then
                if ZScienceSkill.setResearched(self.character, fullType) then
                    ZScienceSkill.addXpFromTable(self.character, ZScienceSkill.Data.literatureReadOnce, fullType, self.item)
                end
            elseif isAlreadyRead == false then -- strict comparison, to not grant extra XP when status is unknown
                -- Check if this is science literature
                if ZScienceSkill.Data.literature[fullType] then
                    ZScienceSkill.addXpFromTable(self.character, ZScienceSkill.Data.literature, fullType, self.item)
                -- Check if this was a skill book
                elseif SkillBook and SkillBook[self.item:getSkillTrained()] and self.item:getSkillTrained() ~= "Science" then
                    local lvl = self.item:getLvlSkillTrained() or 1
                    local scienceXP = ZScienceSkill.skillBookXP[lvl] or 2
                    addXp(self.character, Perks.Science, scienceXP) -- not from a table
                end
            end

            -- XXX is it correct?
            if isClient() then
                self.character:transmitModData()
            end

            return result
        end -- complete
    } -- ISReadABook
}) -- zdk.hook
