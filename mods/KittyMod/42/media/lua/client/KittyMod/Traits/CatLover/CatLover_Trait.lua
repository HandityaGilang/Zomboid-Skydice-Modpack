--[[
local function initCatLoverTrait()
  TraitFactory.addTrait(
    "CatLover_Trait",
    "Cat Lover",
    2,
    "You're a cat person through and through! Start with a Cat Toy that can summon a wild cat to befriend. Keep some food handy to tame your new feline companion! (NOTE: Use the Cat Toy from your inventory to summon a cat. Feed them to earn their trust!)",
    false,
    false
  )
end

Events.OnGameBoot.Add(initCatLoverTrait)
--]]