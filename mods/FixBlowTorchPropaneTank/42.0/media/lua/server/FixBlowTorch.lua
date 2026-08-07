local function FixBlowTorch()
	local item = ScriptManager.instance:getItem("Base.BlowTorch")
	if item:getUseDelta() > 0.01 then
		item:DoParam("UseDelta = 0.01")
	end
end

Events.OnInitGlobalModData.Add(FixBlowTorch)