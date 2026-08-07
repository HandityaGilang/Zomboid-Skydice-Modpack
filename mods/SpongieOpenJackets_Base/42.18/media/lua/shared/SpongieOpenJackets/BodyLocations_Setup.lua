
local function init()

    require("NPCs/BodyLocations")

    local BodyLocations_Helper = require("SpongieOpenJackets/BodyLocations_Helper")

    local jacketIndex = BodyLocations_Helper.group:indexOf(ItemBodyLocation.JACKET)

    local bodylocations = {
        [SpnOpenCloth.ItemBodyLocation.JACKET_OPEN] = {
            index = jacketIndex,
            exclusive = {
                ItemBodyLocation.JACKET,
                SpnOpenCloth.ItemBodyLocation.JACKET_ROLL,
                SpnOpenCloth.ItemBodyLocation.JACKET_OPENROLL,
                ItemBodyLocation.FULL_SUIT_HEAD,
                ItemBodyLocation.FULL_SUIT,
                ItemBodyLocation.FULL_TOP,
                ItemBodyLocation.BATH_ROBE,
                ItemBodyLocation.FULL_ROBE,
                ItemBodyLocation.JACKET_DOWN,
                ItemBodyLocation.JACKET_HAT,
                ItemBodyLocation.JACKET_BULKY,
                ItemBodyLocation.JACKET_HAT_BULKY,
                ItemBodyLocation.JACKET_SUIT,
                ItemBodyLocation.SPORT_SHOULDERPAD,
                ItemBodyLocation.TORSO_EXTRA,
            },
            hidden = {
                ItemBodyLocation.LEFT_WRIST,
                ItemBodyLocation.RIGHT_WRIST,
                ItemBodyLocation.FANNY_PACK_FRONT,
                ItemBodyLocation.FANNY_PACK_BACK,
                ItemBodyLocation.SHOULDER_HOLSTER,
            },
            altModel = {
                ItemBodyLocation.FORE_ARM_LEFT,
                ItemBodyLocation.FORE_ARM_RIGHT,
                ItemBodyLocation.SHOULDERPAD_RIGHT,
                ItemBodyLocation.SHOULDERPAD_LEFT,
                ItemBodyLocation.ELBOW_LEFT,
                ItemBodyLocation.ELBOW_RIGHT,
                ItemBodyLocation.CUIRASS,
                ItemBodyLocation.WEBBING,
            },
        },
        [SpnOpenCloth.ItemBodyLocation.JACKET_ROLL] = {
            index = jacketIndex,
            exclusive = {
                ItemBodyLocation.JACKET,
                SpnOpenCloth.ItemBodyLocation.JACKET_OPEN,
                SpnOpenCloth.ItemBodyLocation.JACKET_OPENROLL,
                ItemBodyLocation.FULL_SUIT_HEAD,
                ItemBodyLocation.FULL_SUIT,
                ItemBodyLocation.FULL_TOP,
                ItemBodyLocation.BATH_ROBE,
                ItemBodyLocation.FULL_ROBE,
                ItemBodyLocation.JACKET_DOWN,
                ItemBodyLocation.JACKET_HAT,
                ItemBodyLocation.JACKET_BULKY,
                ItemBodyLocation.JACKET_HAT_BULKY,
                ItemBodyLocation.JACKET_SUIT,
                ItemBodyLocation.SPORT_SHOULDERPAD,
                ItemBodyLocation.TORSO_EXTRA,
            },
            hidden = {
                ItemBodyLocation.FANNY_PACK_FRONT,
                ItemBodyLocation.FANNY_PACK_BACK,
                ItemBodyLocation.SHOULDER_HOLSTER,
            },
            altModel = {
                ItemBodyLocation.SHOULDERPAD_RIGHT,
                ItemBodyLocation.SHOULDERPAD_LEFT,
                ItemBodyLocation.ELBOW_LEFT,
                ItemBodyLocation.ELBOW_RIGHT,
                ItemBodyLocation.CUIRASS,
                ItemBodyLocation.WEBBING,
            },
        },
        [SpnOpenCloth.ItemBodyLocation.JACKET_OPENROLL] = {
            index = jacketIndex,
            exclusive = {
                ItemBodyLocation.JACKET,
                SpnOpenCloth.ItemBodyLocation.JACKET_OPEN,
                SpnOpenCloth.ItemBodyLocation.JACKET_ROLL,
                ItemBodyLocation.FULL_SUIT_HEAD,
                ItemBodyLocation.FULL_SUIT,
                ItemBodyLocation.FULL_TOP,
                ItemBodyLocation.BATH_ROBE,
                ItemBodyLocation.FULL_ROBE,
                ItemBodyLocation.JACKET_DOWN,
                ItemBodyLocation.JACKET_HAT,
                ItemBodyLocation.JACKET_BULKY,
                ItemBodyLocation.JACKET_HAT_BULKY,
                ItemBodyLocation.JACKET_SUIT,
                ItemBodyLocation.SPORT_SHOULDERPAD,
                ItemBodyLocation.TORSO_EXTRA,
            },
            hidden = {
                ItemBodyLocation.FANNY_PACK_BACK,
                ItemBodyLocation.SHOULDER_HOLSTER,
            },
            altModel = {
                ItemBodyLocation.SHOULDERPAD_RIGHT,
                ItemBodyLocation.SHOULDERPAD_LEFT,
                ItemBodyLocation.ELBOW_LEFT,
                ItemBodyLocation.ELBOW_RIGHT,
                ItemBodyLocation.CUIRASS,
                ItemBodyLocation.WEBBING,
            },
        },
    }


    for name, data in pairs(bodylocations) do
        BodyLocations_Helper:AddLocation(name, data.index)
    end
    for name, data in pairs(bodylocations) do
        BodyLocations_Helper:SetExclusive(name, data.exclusive)
        BodyLocations_Helper:SetHidden(name, data.hidden)
        BodyLocations_Helper:SetAltModel(name, data.altModel)
    end

end

init()
init = nil