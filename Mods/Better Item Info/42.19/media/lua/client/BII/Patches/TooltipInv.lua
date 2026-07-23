require "ISUI/ISToolTipInv"

local EuryTooltipController = require("EuryTooltipController")

_G.BII_TooltipInv_Active = true

local providers = {
    Food = require("BII/Providers/Food"),
    Liquid = require("BII/Providers/Liquid"),
    Weapon = require("BII/Providers/Weapon"),
    Seed = require("BII/Providers/Seed"),
    Metal = require("BII/Providers/Metal"),
    Fuel = require("BII/Providers/Fuel"),
    Electronics = require("BII/Providers/Electronics"),
    Book = require("BII/Providers/Book"),
    Remaining = require("BII/Providers/Remaining"),
}

for key, provider in pairs(providers) do
    EuryTooltipController:registerProvider("BetterItemInfo" .. key, provider)
end

EuryTooltipController:install()
