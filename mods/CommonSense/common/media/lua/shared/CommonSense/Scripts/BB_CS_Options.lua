-- ************************************************************************
-- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- ************************************************************************
-- ** All rights reserved. This content is protected by © Copyright law. **
-- ************************************************************************

CommonSense = {}
CommonSense.PryingTools = { "Base.Crowbar", "Base.CrowbarForged" }

--- Add an item (Equipable ONLY) to the list of items that can be used to pry stuff open.
---@param toolID string
---@return boolean successful
function CommonSense.AddPryingTool(toolID)
	local item = ScriptManager.instance:getItem(toolID)
	if not item then return false end
	table.insert(CommonSense.PryingTools, toolID)
	return true
end

--- Remove an item from the list of items that can be used to pry stuff open.
---@param toolID string
---@return boolean successful
function CommonSense.RemovePryingTool(toolID)

	for k, v in pairs(CommonSense.PryingTools) do
		if v == toolID then
			table.remove(CommonSense.PryingTools, k)
			return true
		end
  	end
	return false
end