require "ZScienceSkill/Data"

ZScienceSkill.Data.add({ specimens = {
    ["MyPhoto.BodakCamera"]                      = { Science = 10, Electricity =  5 },
    ["MyPhoto.BodakCameraNoRoll"]                = { Science = 10, Electricity =  5, key = "MyPhoto.BodakCamera" },
    ["MyPhoto.BodakCameraUsed"]                  = { Science = 10, Electricity =  5, key = "MyPhoto.BodakCamera" },

    ["MyPhoto.EmptyPhotoFilm"]                   = { Science = 10 },
    ["MyPhoto.FilmRoll"]                         = { Science = 10 },
    ["MyPhoto.PhotoFilm"]                        = { Science = 10 },
    ["MyPhoto.PhotoFilmUsed"]                    = { Science = 10 },

    ["MyPhoto.DeveloperFluid"]                   = { Science = 20, AppliedChemistry = 20 },
    ["MyPhoto.FixerFluid"]                       = { Science = 20, AppliedChemistry = 20 },

    ["MyPhoto.DevelopingTank"]                   = { Science = 15 },
    ["MyPhoto.Waterbath"]                        = { Science = 15 },
    ["MyPhoto.WaterbathEmpty"]                   = { Science = 15, key = "MyPhoto.Waterbath" },

    ["MyPhoto.PolaroidInstantCameraNoPolaroids"] = { Science = 10, Electricity =  5 },
    ["MyPhoto.PolaroidInstantCamera"]            = { Science = 10, Electricity =  5 },
    ["MyPhoto.PolaroidFrameSet"]                 = { Science = 10, Electricity =  5 },
    ["MyPhoto.Polaroid"]                         = { Science = 10, Electricity =  5 },
    ["MyPhoto.ProcessingPolaroid"]               = { Science = 10, Electricity =  5 },

    ["MyPhoto.KonanBubbleJetPrinter"]            = { Science = 20, Electricity = 20 },
}})
