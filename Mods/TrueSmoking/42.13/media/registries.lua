TrueSmoking = TrueSmoking or {}
TrueSmoking.registries = TrueSmoking.registries or {}

TrueSmoking.registries.mask =
ItemBodyLocation.register('TrueSmoking:Mask_Smoke')

TrueSmoking.registries.tag =
ItemTag.register('TrueSmoking:CantSmoke')

-- local group = BodyLocations.getGroup('Human')
-- local bodyLocation = BodyLocation.new(group, TrueSmoking.registries.mask)
-- group:getAllLocations():add(bodyLocation)