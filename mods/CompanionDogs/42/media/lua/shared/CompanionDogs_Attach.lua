-- Registra os locais de attachment da alforje no grupo de attach "Animal" da engine para que os blocos
-- `attachment saddlebags_l/_r` do modelo do cao (scripts/models_dog.txt) resolvam. Espelha o vanilla
-- NPCs/AttachedLocations.lua, que pre-declara apenas head_hat + bowtie (os cosmeticos chapeu / gravata-borboleta da vaca).
pcall(function()
    local group = AttachedLocations.getGroup("Animal")
    group:getOrCreateLocation("saddlebags_l"):setAttachmentName("saddlebags_l")
    group:getOrCreateLocation("saddlebags_r"):setAttachmentName("saddlebags_r")
    group:getOrCreateLocation("saddlebags_c"):setAttachmentName("saddlebags_c")
end)
