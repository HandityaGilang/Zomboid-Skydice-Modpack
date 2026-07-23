local PSC_Tags = ProjectSummerCar_Tags

function sendInitVehicleEngine(vehicle, forcebest)
-- Calls initVehicleEngine on server.

sendClientCommand(getPlayer(), "ProjectSummerCar", "SpawnEngineParts", { vehicle =
vehicle:getId(), forcebest = forcebest })
--print("Sending command");

end

-- Hook here so that whenever you get into a vehicle it is setup.
function EngineSetupEnterVehicle(character)
	local vehicle = character:getVehicle()
	if not vehicle then return; end
	local engine = vehicle:getPartById("Engine")
	if engine then
		local itemContainer = engine:getItemContainer()
		if itemContainer then
			if not itemContainer:containsTag(PSC_Tags.EnginePartInitMarker) then	
				if instanceof(character, 'IsoPlayer') and character:isLocalPlayer() then
					sendInitVehicleEngine(vehicle, false)
				end
			end
		end
	end
end


-- Hook here so that the vehicle is inited whenever you open the mechanic menu
oldVehicleMechanicsinitParts = ISVehicleMechanics.initParts
function ISVehicleMechanics:initParts()

	if not self.vehicle then return; end
	local engine = self.vehicle:getPartById("Engine")
	if engine then
		local itemContainer = engine:getItemContainer()
		if itemContainer then
			if not itemContainer:containsTag(PSC_Tags.EnginePartInitMarker) then
				sendInitVehicleEngine(self.vehicle, false)
			end
		end
	end
	oldVehicleMechanicsinitParts(self)
end


Events.OnEnterVehicle.Add(EngineSetupEnterVehicle)