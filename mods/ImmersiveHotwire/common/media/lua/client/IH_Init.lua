local ToolsSync = require "net/IH_ToolsSync"
local StartIntercept = require "net/IH_StartIntercept"
local Actions = require "gameplay/IH_Actions"

ToolsSync.init()
StartIntercept.init()

Events.OnCreatePlayer.Add(function(playerNum, player)
    Actions.IH_UnderDash_Clear(player)
end)
