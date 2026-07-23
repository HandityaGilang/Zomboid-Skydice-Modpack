require 'NPCs/ZombiesZoneDefinition'

local mult = 1
if SandboxVars and SandboxVars.CamisetaChilena and SandboxVars.CamisetaChilena.ZombieOutfitMultiplier then
    mult = SandboxVars.CamisetaChilena.ZombieOutfitMultiplier
end

FS_ZombiesZoneDefinition = ZombiesZoneDefinition or {};

table.insert(ZombiesZoneDefinition.Default, {name = "LaRoja", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Duki_Trap_Outfit", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Service_Staff", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Male_WWE_Fan", chance = 3.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Male_Kpop_Idol", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "GakuranUniform", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "SchoolBoyGreen_Full", chance = 3.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "SchoolBoy_Japan", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "BobMarley", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "CyberpunkRunner", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Frozono_Outfit", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "FireForceCombatOutfit", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "DBZ_Fan", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Fan_Random", chance = 5.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "PotterWinter", chance = 2.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Gamer_Streamer", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Invincible_Suit", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Shinra_FireForce", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Anime_SchoolGirl", chance = 3.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Bikini_Summer", chance = 3.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "LaRoja_Female", chance = 2.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "FireForceMaki", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "TamakiKotatsu", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "FireForce_Mixed", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "31Min", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "MomoTwice", chance = 2.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "GengarGastly", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "WWE_Fan", chance = 3.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "AdventureTime", chance = 2.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Kpop_Idol", chance = 3.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "ZombieBait", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "AkatsukiGirl", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "KillBill", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "ReiMiyamotoOutfit", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "SaekoBusujimaOutfit", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "SayaTakagiOutfit", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "HimikoBtooomOutfit", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "MomoAyaseOutfit", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "ViperOutfit", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "MissIncredible", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "HarleyFan", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "SquidGameGuard", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "SquidGamePlayer", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "CasaDePapel", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Shaco_Jester", chance = 1.2 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "SquidGameGuard_Female", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "SquidGamePlayer_Female", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "CasaDePapel_Female", chance = 1.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Shaco_Jester_Female", chance = 1.2 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "GrizzboltPal", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "DerpyBusiness", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "GengarSuitOutfit_Female", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Female_Duki_Trap_Outfit", chance = 2.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "GrizzboltPal_Female", chance = 0.2 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "DerpyBusiness_Female", chance = 0.2 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "MarshmelloDJ", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "GengarSuitOutfit", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "AtomEveOutfit", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "VendettaFan", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "VendettaFan_Female", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "HisokaOutfit", chance = 0.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "ColoColoFan", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "PotterWinter_Female", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Female_BobMarley", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Service_Staff_Female", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "HisokaOutfitFemale", chance = 1.0 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "Netflix_SchoolGirl", chance = 3.5 * mult});
table.insert(ZombiesZoneDefinition.Default, {name = "FanGirl_Random", chance = 5.0 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "GakuranUniform", chance = 4.5 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "SchoolBoyGreen_Full", chance = 4.5 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "SchoolBoy_Japan", chance = 4.5 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "ReiMiyamotoOutfit", chance = 4.5 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "SaekoBusujimaOutfit", chance = 4.5 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "SayaTakagiOutfit", chance = 2.5 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "HimikoBtooomOutfit", chance = 2.5 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "MomoAyaseOutfit", chance = 2.5 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "Anime_SchoolGirl", chance = 4.5 * mult});
table.insert(ZombiesZoneDefinition.School, {name = "Netflix_SchoolGirl", chance = 5.5 * mult});

-- OTRAS ZONAS (Beach, Bar, Rich)
table.insert(ZombiesZoneDefinition.Beach, {name = "Bikini_Summer", chance = 5.0 * mult});
table.insert(ZombiesZoneDefinition.Beach, {name = "AdventureTime", chance = 2.5 * mult});
table.insert(ZombiesZoneDefinition.Beach, {name = "31Min", chance = 2.0 * mult});
table.insert(ZombiesZoneDefinition.Beach, {name = "ZombieBait", chance = 1.5 * mult});

table.insert(ZombiesZoneDefinition.Bar, {name = "KillBill", chance = 3.2 * mult});
table.insert(ZombiesZoneDefinition.Bar, {name = "WWE_Fan", chance = 1.5 * mult});

table.insert(ZombiesZoneDefinition.Rich, {name = "Kpop_Idol", chance = 5 * mult});
table.insert(ZombiesZoneDefinition.Rich, {name = "SayaTakagiOutfit", chance = 5 * mult});
table.insert(ZombiesZoneDefinition.Rich, {name = "SquidGameGuard", chance = 5 * mult});

print("[CamisetaChilena] Outfits inyectados completamente");