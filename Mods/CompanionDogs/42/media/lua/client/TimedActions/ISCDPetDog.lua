require "TimedActions/ISCDBaseDogAction"

ISCDPetDog = ISCDBaseDogAction:derive("ISCDPetDog")

function ISCDPetDog:isValid()
    return self.animal:isExistInTheWorld()
end

-- O carinho usa a animacao de petting VANILLA (player ajoelha e faz carinho), espelhando o ISPetAnimal: o setup base
-- de alimentar-na-mao toca "AnimalLureLow", cujo anim-event embutido dispara o foley "Lure/Animal" do farming,
-- o som errado e "estranho" pra carinho. Dirigir petanimal/animal/AnimalSizeX/Y em vez disso da a pose de pet real
-- sem o som de lure. Mantemos o tick loop base (force-complete por cdMaxTicks) e o efeito de pet do CD.
function ISCDPetDog:start()
    pcall(function() self.animal:getBehavior():setBlockMovement(true) end)
    if self.animal and self.animal:isExistInTheWorld() then
        self:setOverrideHandModels(nil, nil)
        self.character:setVariable("AnimalSizeX", 0.01)
        pcall(function()
            local data = self.animal:getData()
            local range = data:getMaxSize() - data:getMinSize()
            local current = data:getSize() - data:getMinSize()
            if current <= 0.001 then current = 0.001 end
            if range and range > 0 then self.character:setVariable("AnimalSizeY", current / range) end
        end)
        self.character:setVariable("petanimal", true)
        -- O estado petanimal escolhe a pose do player casando a var "animal" com um pose node; nossos
        -- tipos custom (dog/gs/retriever) nao casam com nenhum, entao cai no defaultpet (Bob_PetBull, um alcance EM PE pra um
        -- animal alto) e o player nao agacha. Forca uma pose de raccoon (Bob_PetPiglet, o agachar-ate-um-pequeno-
        -- animal-de-chao) ja que os caes tem tamanho de raccoon.
        local pose = "raccoonboar"
        pcall(function()
            if self.animal:isBaby() then pose = "raccoonkit"
            elseif self.animal:isFemale() then pose = "raccoonsow" end
        end)
        self.character:setVariable("animal", pose)
        self.character:faceThisObject(self.animal)
        -- A anim nativa de petting nao tem foley, entao da pro cao um resfolego de satisfacao no emitter do cao (posicionado,
        -- cosmetico, owner-local; sem addSound pra nunca atrair zumbis). Toca no start, a cada carinho.
        CompanionDogs.playAnimalSound(self.animal, CompanionDogs.PET_SOUND)
    end
end

local function clearPetAnim(self)
    pcall(function() self.character:setVariable("petanimal", false) end)
end

function ISCDPetDog:stop()
    clearPetAnim(self)
    ISCDBaseDogAction.stop(self)
end

function ISCDPetDog:forceStop()
    clearPetAnim(self)
    ISCDBaseDogAction.forceStop(self)
end

function ISCDPetDog:perform()
    clearPetAnim(self)
    ISCDBaseDogAction.perform(self)
end

function ISCDPetDog:doEffect()
    if self.cdDone then return end
    self.cdDone = true
    clearPetAnim(self)
    pcall(function() self.animal:getBehavior():setBlockMovement(false) end)
    CompanionDogs.request("pet", self.animal)
end

function ISCDPetDog:new(character, animal)
    local o = ISBaseTimedAction.new(self, character)
    o.animal = animal
    o.cdMaxTicks = 150
    o.cdDuration = 300
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
