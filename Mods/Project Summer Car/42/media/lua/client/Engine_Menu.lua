require "ISUI/playerdata/ISPlayerData"
require "ISTransferFluid"


-- Declared here so other mods can add their own transmission tables. 
-- Note, ratios less then 1 increase a vehicles top speed. 
	TransmissionTable = {
		{name="Base.Transmission1",ratios={2.6,2.6,1.6,1.0}},		
		{name="Base.Transmission2",ratios={3.0,3.0,1.8,1.3,1.0}},
		{name="Base.Transmission3",ratios={3.4,3.4,2.3,1.7,1.0}},
		{name="Base.Transmission4",ratios={3.4,3.4,2.1,1.60,1.20,0.9}},
		{name="Base.Transmission5",ratios={4.0,4.0,2.5,1.9,1.5,1.3,1.1,0.9,0.8}},
		}
		
	-- Add another torque converter or two?
	-- First converter was 1800 but that causes creep forward for people who haven't updated realistic physics. 
	TorqueConverterTable = {
		{name="Base.TorqueConverter1",lockupRPM = 2200, lockupRange = 800},
		{name="Base.TorqueConverter2",lockupRPM = 3000, lockupRange = 800},
		{name="Base.TorqueConverter3",lockupRPM = 4000, lockupRange = 800},
		}		


function getPlayerEngineUI(id)
    local data = getPlayerData(id)
    return data and data.engineUI
end




local oldCreateInventoryInterface = ISPlayerDataObject.createInventoryInterface

function ISPlayerDataObject:createInventoryInterface()
	local playerObj = getSpecificPlayer(self.id);
    self.engineUI = ISEngineMechanics:new(0,0,playerObj,nil);
    self.engineUI:initialise();
--    self.engineUI:addToUIManager();
    self.engineUI:setVisible(false);
    self.engineUI:setEnabled(false);
	
	local infoPanel = ISRichTextPanel:new(220, 60, 270, 90);
    infoPanel:initialise();
    infoPanel.text = "";
    infoPanel:paginate();
	infoPanel:setMargins(0,0,0,0);
	infoPanel.backgroundColor.a = 0;
	
	self.engineUI.infoPanel = infoPanel
    self.engineUI:addChild(infoPanel);
	
	oldCreateInventoryInterface(self)
end


function ISVehicleMechanics.onOpenEngine(playerObj, part, vehicle)
	
	--local ui = getPlayerMechanicsUI(self.character:getPlayerNum());
	getPlayerMechanicsUI(playerObj:getPlayerNum()).usedHood = nil; -- Disable closing hood on switching to engine menu
	getPlayerMechanicsUI(playerObj:getPlayerNum()):close();
	local ui = getPlayerEngineUI(playerObj:getPlayerNum())
	
	ui.vehicle = vehicle; 
	ui.usedHood = nil; --self.usedHood -- Disable it for now BM
	ui:initParts();
	ui:setVisible(true, JoypadState.players[playerObj:getPlayerNum()+1])
	ui:addToUIManager()
end



function FixingManager.getFixes(item)
--[[
	-- Bugged Java code:
        ArrayList arrayList0 = new ArrayList();
        ArrayList arrayList1 = ScriptManager.instance.getAllFixing(new ArrayList<>());

        for (int int0 = 0; int0 < arrayList1.size(); int0++) {
            Fixing fixing = (Fixing)arrayList1.get(int0);
            if (fixing.getRequiredItem().contains(item.getType())) {
                arrayList0.add(fixing);
            }
        }
        return arrayList0;
--]]
	local arrayList0 = ArrayList.new()
	local arrayList1 = ScriptManager.instance:getAllFixing(ArrayList.new())
	for x = 0, arrayList1:size()-1 do
		local curItem = arrayList1:get(x):getRequiredItem();
		if curItem then
			local contains = false;
			for y = 0, curItem:size()-1 do
				if string.match(curItem:get(y),item:getType()) then
					contains = true;
				end
			end
			if contains == true then
				arrayList0:add(arrayList1:get(x));
			end
		end
	end
	return arrayList0;
end

oldDoPartContextMenu = ISVehicleMechanics.doPartContextMenu
function ISVehicleMechanics:doPartContextMenu(part, x,y)
	if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return; end
	local playerObj = getSpecificPlayer(self.playerNum);
	self.context = ISContextMenu.get(self.playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())
	
	if part:getId() == "Engine" then
		local option = self.context:addOption(getText("IGUI_EnginePanel_InspectEngine"), playerObj, ISVehicleMechanics.onOpenEngine, part, self.vehicle); 
		self:doMenuTooltipEngine(part, option, "inspectengine");
		-- Replace doMenuTooltip for this. 
		
		-- Readd Get key cheat. 
		if self.vehicle:getPartById("Engine") then
			if getDebug() and (ISVehicleMechanics.cheat or (isClient() and isAdmin())) then
				option = self.context:addOption("CHEAT: Get Key", playerObj, ISVehicleMechanics.onCheatGetKey, self.vehicle)
			end
		end
		
		-- Do end part of ISVehicleMechanics:doPartContextMenu for passing joystick focus.
		if JoypadState.players[self.playerNum+1] and self.context:getIsVisible() then
			self.context.mouseOver = 1
			self.context.origin = self
			JoypadState.players[self.playerNum+1].focus = self.context
			updateJoypadFocus(JoypadState.players[self.playerNum+1])
		end
		return -- Return early. 
	end		
	
	local arrayList1 = ScriptManager.instance:getAllFixing(ArrayList.new())
	local oldModDetected = false;
	for x = 0, arrayList1:size()-1 do
		if arrayList1:get(x):getRequiredItem() == nil then
			oldModDetected = true;
		end
	end
	oldDoPartContextMenu(self,part,x,y)
	if oldModDetected == true then
		local option = self.context:addOption("An out of date (<B42.12) mod detected.", nil, nil); 
		local tooltip = ISToolTip:new();
		tooltip:initialise();
		tooltip:setVisible(false);
		tooltip.description = "An out of date car or weapon mod has been detected and Project summer car has prevented this and other context menus from crashing. <LINE><GHC>You are welcome";
		option.toolTip = tooltip;
	end
end


function ISVehicleMechanics:doMenuTooltipEngine(part, option, lua, name)
	local vehicle = part:getVehicle();
	local tooltip = ISToolTip:new();
	tooltip:initialise();
	tooltip:setVisible(false);
	tooltip.description = ""--getText("Tooltip_craft_Needs") .. " : <LINE>";
	option.toolTip = tooltip;

	-- repair engines tooltip
	if lua == "inspectengine" then
		tooltip.description = tooltip.description .. " " .. ISVehicleMechanics.ghs .. " " .. getText("IGUI_EnginePanel_InspectEngineParts") .. " <LINE>";
	end

end


ISEngineMechanics = ISCollapsableWindow:derive("ISEngineMechanics");
ISEngineMechanics.alphaOverlay = 1;
ISEngineMechanics.alphaOverlayInc = true;
ISEngineMechanics.tooltip = nil;
-- disable mechanics cheat for non-debug
ISEngineMechanics.cheat = getDebug();
ISEngineMechanics.ghs = "<GHC>"
ISEngineMechanics.bhs = "<BHC>"

local function predicateNotBroken(item)
	return not item:isBroken()
end

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function ISEngineMechanics:initialise()
	ISCollapsableWindow.initialise(self);
end

function ISEngineMechanics:update()
	if self.vehicle and self.chr:DistTo(self.vehicle:getX(), self.vehicle:getY()) > 6 then
		self:close()
	elseif not self.vehicle or not self.vehicle:getSquare() or self.vehicle:getSquare():getMovingObjects():indexOf(self.vehicle) < 0 then
		self:close() -- handle vehicle being removed by admin/cheat command
	else
		self:recalculEngineCondition();
	end
end

function ISEngineMechanics:updateLayout()
	self.listbox:setWidth(self.listWidth)
	self.bodyworklist:setWidth(self.listWidth)
	self.bodyworklist:setX(self.listbox:getRight() + 20)
	self.listbox.vscroll:setX(self.listbox:getWidth() - 16)
	self.bodyworklist.vscroll:setX(self.bodyworklist:getWidth() - 16)
	self.bodyworklist:setX(self.listbox:getRight() + 20)
	self:setWidth(math.max(500, self.xCarTexOffset + self.listWidth + 20 + self.listWidth + 10))
	self.collapseButton:setX(self:getWidth() - 3 - self.collapseButton:getWidth())
	self.pinButton:setX(self:getWidth() - 3 - self.pinButton:getWidth())
end

function ISEngineMechanics:updateParts()

	local engine = self.vehicle:getPartById("Engine")
	local engineParts = engine:getItemContainer()
	
	for a,b in pairs(self.vehiclePart) do
		for i,v in pairs(b.parts) do
			v.part = engineParts:getFirstTag(v.tag)	
		end
	end
end

function ISEngineMechanics:initParts()
	if not self.vehicle then return; end
	self.listbox:clear();
	self.bodyworklist:clear();
	self.vehiclePart = {};
	local currentCat = {};
	for i=1,self.vehicle:getPartCount() do
		local part = self.vehicle:getPartByIndex(i-1)
		local category = part:getCategory() or "Other";
			if part:getId() == "Engine" then
				--print("Found Engine")
				if part:getItemContainer() == nil then
					print("Found no item container in engine")
				end
				--print("Found Engine item container ", part:getItemContainer())
				
				local engineParts = part:getItemContainer()

				local category = getText("IGUI_EnginePanel_Category_EngineParts");
				local currentCat = {};
				currentCat.parts = {};
				currentCat.name = category
				currentCat.cat = category;
				self.vehiclePart[category] = currentCat;
				
				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_SparkPlugs");
				newPart.tag = "EngineSparkplug"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 2
				table.insert(currentCat.parts, newPart);

				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_CylinderHead");
				newPart.tag = "EngineCylinderHead"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 7
				table.insert(currentCat.parts, newPart);

				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_HeadGasket");
				newPart.tag = "EngineHeadGasket"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 7
				table.insert(currentCat.parts, newPart);

				newPart = {}; -- Hide pistons till cylinder head is removed? Replace with 'remove cylinder head' tip?
				newPart.name = getText("IGUI_EnginePanel_PartType_Pistons");
				newPart.tag = "EnginePistons"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 7
				table.insert(currentCat.parts, newPart);

				newPart = {}; -- Hide till oil pan removed?
				newPart.name = getText("IGUI_EnginePanel_PartType_Crankshaft");
				newPart.tag = "EngineCrankshaft"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 7
				table.insert(currentCat.parts, newPart);

				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_Flywheel");
				newPart.tag = "EngineFlywheel"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 5
				table.insert(currentCat.parts, newPart);

				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_Starter");
				newPart.tag = "EngineStarter";
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 4
				table.insert(currentCat.parts, newPart);

				category = getText("IGUI_EnginePanel_Category_DriveTrain");
				currentCat = {};
				currentCat.parts = {};
				currentCat.name = category
				currentCat.cat = category;
				self.vehiclePart[category] = currentCat;
				
				newPart = {}; 
				newPart.name = getText("IGUI_EnginePanel_PartType_Transmission");
				newPart.tag = "EngineTransmission"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 5
				table.insert(currentCat.parts, newPart);

				newPart = {}; 
				newPart.name = getText("IGUI_EnginePanel_PartType_TorqueConverter");
				newPart.tag = "EngineTorqueConverter"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 5
				table.insert(currentCat.parts, newPart);


				category = getText("IGUI_EnginePanel_Category_Fluids");
				currentCat = {};
				currentCat.parts = {};
				currentCat.name = category
				currentCat.cat = category;
				self.vehiclePart[category] = currentCat;
				
				
				local newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_TransmissionFluid");
				newPart.tag = "EngineTransmission"
				newPart.isFluid = true;
				newPart.info = getText("Tooltip_Engine_TransmissionFluid");
				--
				newPart.skill = 0
				table.insert(currentCat.parts, newPart);				

				local newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_PowerSteeringFluid");
				newPart.tag = "EnginePowerSteeringPump"
				newPart.info = getText("Tooltip_Engine_PowerSteeringFluid");
				newPart.isFluid = true;
				newPart.skill = 0
				table.insert(currentCat.parts, newPart);				
				
				
				local newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_Oil");
				newPart.tag = "EngineOilPan"
				newPart.info = getText("Tooltip_Engine_Oil");
				newPart.isFluid = true;
				newPart.skill = 0
				table.insert(currentCat.parts, newPart);				

				-- Stores, oil, damage results in oil loss. 
				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_OilPan");
				newPart.tag = "EngineOilPan"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 3
				table.insert(currentCat.parts, newPart);

				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_OilFilter");
				newPart.tag = "EngineOilFilter"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 1
				table.insert(currentCat.parts, newPart);
	

				-- Could be a mix of water/antifreeze (And maybe alcohol? or other fluids?)
				-- Sets freezing point, engine block destroyed if goes below. 
				-- Also block gets damaged if quantity goes too low. 
				
				-- Stored in radiator?
				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_Coolant");
				newPart.tag = "EngineRadiator"
				newPart.info = getText("Tooltip_Engine_Coolant");
				newPart.isFluid = true;
				newPart.skill = 0
				table.insert(currentCat.parts, newPart);
				

				-- Stores coolant, damage results in coolant loss. 
				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_Radiator");
				newPart.tag = "EngineRadiator"
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 2
				table.insert(currentCat.parts, newPart);

				category = getText("IGUI_EnginePanel_Category_Accessories");
				currentCat = {};
				currentCat.parts = {};
				currentCat.name = category
				currentCat.cat = category;
				self.vehiclePart[category] = currentCat;
				
				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_FanBelt");
				newPart.tag = "EngineFanBelt";
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 2
				table.insert(currentCat.parts, newPart);

				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_Alternator");
				newPart.tag = "EngineAlternator";
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 4
				table.insert(currentCat.parts, newPart);

				newPart = {};
				newPart.name = getText("IGUI_EnginePanel_PartType_WaterPump");
				newPart.tag = "EngineWaterPump";
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 4
				table.insert(currentCat.parts, newPart);
				
				newPart = {}; -- Add PS fluid? (Transmission fluid for all 3?)
				newPart.name = getText("IGUI_EnginePanel_PartType_PowerSteeringPump");
				newPart.tag = "EnginePowerSteeringPump";
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 4
				table.insert(currentCat.parts, newPart);


				newPart = {}; -- Add brake fluid?
				newPart.name = getText("IGUI_EnginePanel_PartType_BrakeBooster");
				newPart.tag = "EngineBrakeBooster";
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 3
				table.insert(currentCat.parts, newPart);

				newPart = {}; 
				newPart.name = getText("IGUI_EnginePanel_PartType_AirConditioner");
				newPart.tag = "EngineAirConditioner";
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 4
				table.insert(currentCat.parts, newPart);

				newPart = {}; 
				newPart.name = getText("IGUI_EnginePanel_PartType_HeaterCore");
				newPart.tag = "EngineHeaterCore";
				newPart.info = getText("Tooltip_"..newPart.tag) 
				newPart.skill = 4
				table.insert(currentCat.parts, newPart);
				
				self:updateParts();
			end
		
	end
	
	local scrollbarWidth = self.listbox.vscroll:getWidth()
	local maxWidth = (500 - self.xCarTexOffset - 10 - 20) / 2
	
	for i,v in pairs(self.vehiclePart) do
		local cat = {};
		cat.name = v.name;
		cat.cat = true;
		local list = self.listbox;
		if v.name == getText("IGUI_EnginePanel_Category_Fluids") or v.name == getText("IGUI_EnginePanel_Category_Accessories") then list = self.bodyworklist;  end
		list:addItem(cat.name, cat);
		for j,k in ipairs(v.parts) do
			list:addItem(k.name, k);
			local width = 20 + getTextManager():MeasureStringX(UIFont.Small, k.name)
			width = width + 2 + getTextManager():MeasureStringX(UIFont.Small, "(100%)")
			maxWidth = math.max(maxWidth, width + scrollbarWidth + 2)
		end
	end
	
	self.listWidth = maxWidth
	self:updateLayout()
	
	self.engineCondition = 0;
	self.engineCondRGB = self:getConditionRGB(self.engineCondition);
	
	self.leftListHasFocus = true
	self.leftListSelection = 1
	self.rightListSelection = 1
	if self.listbox:size() > 1 then self.listbox.selected = 2 end
	if self.bodyworklist:size() > 1 then self.rightListSelection = 2 end
end

function ISEngineMechanics:recalculEngineCondition()
	if not self.vehicle then return; end
	local generalCondition = -100; -- Start at -100 because there is one 'marker' part that is always at 100% condition. 
	local totalPart = 19; -- Fixed cause its easier. 
	local engine = self.vehicle:getPartById("Engine");
	local engineItems = engine:getItemContainer():getItems();
	for i=0,engineItems:size()-1 do
		local part = engineItems:get(i)
		local cond = part:getCondition();
		generalCondition = generalCondition + cond;
		--totalPart = totalPart + 1;
	end
	self.engineCondition = round(generalCondition / totalPart, 2);
	self.engineCondRGB = self:getConditionRGB(self.engineCondition);
end



function ISEngineMechanics:createChildren()
	ISCollapsableWindow.createChildren(self);
	if self.resizeWidget then self.resizeWidget.yonly = true end
	--self:setInfo(getText("IGUI_InfoPanel_Mechanics"))	;
	self:setInfo("Engine Mechanics");

	local rh = self.resizable and self:resizeWidgetHeight() or 0
	local y = self:titleBarHeight() + 10 + 5 + FONT_HGT_MEDIUM + FONT_HGT_SMALL * (5 + 1) + 10
	
	self.listbox = ISScrollingListBox:new(self.xCarTexOffset, y, 220, self.height - rh - 10 - y);
	self.listbox:initialise();
	self.listbox:instantiate();
	self.listbox:setAnchorLeft(true);
	self.listbox:setAnchorRight(false);
	self.listbox:setAnchorTop(true);
	self.listbox:setAnchorBottom(true);
	self.listbox.itemheight = FONT_HGT_SMALL;
	self.listbox.drawBorder = false
	self.listbox.backgroundColor.a = 0
	self.listbox.doDrawItem = ISEngineMechanics.doDrawItem;
	self.listbox.onRightMouseUp = ISEngineMechanics.onListRightMouseUp;
	self.listbox.onMouseDown = ISEngineMechanics.onListMouseDown;
	self.listbox.parent = self;
	self:addChild(self.listbox);
	
	self.bodyworklist = ISScrollingListBox:new(self.xCarTexOffset + self.listbox.width + 20, y, 220, self.height - rh - 10 - y);
	self.bodyworklist:initialise();
	self.bodyworklist:instantiate();
	self.bodyworklist:setAnchorLeft(true);
	self.bodyworklist:setAnchorRight(false);
	self.bodyworklist:setAnchorTop(true);
	self.bodyworklist:setAnchorBottom(true);
	self.bodyworklist.itemheight = FONT_HGT_SMALL;
	self.bodyworklist.drawBorder = false
	self.bodyworklist.backgroundColor.a = 0
	self.bodyworklist.doDrawItem = ISEngineMechanics.doDrawItem;
	self.bodyworklist.onRightMouseUp = ISEngineMechanics.onListRightMouseUp;
	self.bodyworklist.onMouseDown = ISEngineMechanics.onListMouseDown;
	self.bodyworklist.parent = self;
	self:addChild(self.bodyworklist);
	
	self:initParts();
end

function ISEngineMechanics:onListMouseDown(x, y)
	if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 and not getDebug() then return; end
	
	self.parent.listbox.selected = 0;
	self.parent.bodyworklist.selected = 0;
	
	local row = self:rowAt(x, y)
	if row < 1 or row > #self.items then return end
	if not self.items[row].item.cat then
		self.selected = row;
	end
end

function ISEngineMechanics:onListRightMouseUp(x, y)
	self:onMouseDown(x, y);
	if self.items[self.selected] and not self.items[self.selected].item.cat then
		self.parent:doPartContextMenu(self.items[self.selected].item, self:getX() + x, self:getY() + self:getYScroll() + y)
	else
		self.parent:onRightMouseUp(self:getX() + x, self:getY() + self:getYScroll() + y)
	end
end

function ISEngineMechanics:doPartContextMenu(item, x,y)
	-- Changed item.part variable for item
	-- Needs to be rewriten for inventoryitems instead of vehicleparts. 

	if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return; end
	local playerObj = getSpecificPlayer(self.playerNum);
	
	if playerObj:getVehicle() ~= nil and not (isDebugEnabled() or (isClient() and (isAdmin() or getAccessLevel() == "moderator"))) then return end
	self.context = ISContextMenu.get(self.playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())


	local option;
	--local wrench = ISEngineMechanics:getWrench(self.chr)
	--local screwdriver = ISEngineMechanics:getScrewdriver(self.chr)
	--local tirePump = ISEngineMechanics:getTirePump(self.chr)
	local playerInv = playerObj:getInventory();
	
	if item.isFluid then
		-- Check fluid amount, remove/notAvailable if full/empty/lacking fluid to add/lacking container to remove?
		
		-- TODO: Fluid option should be different when part not available
		
		option = self.context:addOption(getText("IGUI_EnginePanel_Action_AddFluid"), playerObj, nil);
		--self:doMenuTooltip(item, option, "addfluid");
		option.notAvailable = item.part and item.part:getFluidContainer():getFreeCapacity() < 0.01
		local subMenu = ISContextMenu:getNew(self.context);
		self.context:addSubMenu(option, subMenu);			
		
		local invList = playerInv:getItems()
		if invList:size() and item.part then
			for i=0, invList:size() - 1 do
				local part = invList:get(i)
				-- Find all fluid containers, add as options if they have fluid.
				if part:getFluidContainer() then
					if part:getFluidContainer():getAmount() > 0 then
						local itemOpt = subMenu:addOption(part:getName(), playerObj, ISEngineMechanics.onAddFluid, item, part, self);
						self:doMenuTooltip(item, itemOpt, "addfluid", part);
					end
				end
			end
		end
		
		
		
		option = self.context:addOption(getText("IGUI_EnginePanel_Action_RemoveFluid"), playerObj, nil);
		--self:doMenuTooltip(item, option, "removefluid");
		option.notAvailable = item.part and item.part:getFluidContainer():getAmount() == 0
		
		subMenu = ISContextMenu:getNew(self.context);
		self.context:addSubMenu(option, subMenu);			
				
		if invList:size() and item.part then
			for i=0, invList:size() - 1 do
				local part = invList:get(i)
				-- Find all fluid containers, add as options if they have space for fluid.
				if part:getFluidContainer() then
					if part:getFluidContainer():getFreeCapacity() > 0.01 then
						local itemOpt = subMenu:addOption(part:getName(), playerObj, ISEngineMechanics.onRemoveFluid, item, part, self);
						self:doMenuTooltip(item, itemOpt, "removefluid", part);
					end
				end
			end
		end		
	else
		
		if item.part == nil then
			option = self.context:addOption(getText("IGUI_EnginePanel_Action_InstallPart"), playerObj, nil);
			--self:doMenuTooltip(item, option, "addpart");
			
			--option = self.context:addOption(getText("IGUI_Install"), playerObj, nil)
			local subMenu = ISContextMenu:getNew(self.context);
			self.context:addSubMenu(option, subMenu);
			
			-- So the way the vanilla game works, is it first displays all possible things that could be installed
			-- then lets you pick from those in a sub menu. 
			-- But I think we can get away with just doing it simpler.
			local partList = playerInv:getAllTag(item.tag, ArrayList.new())
			if partList:size() ~= 0 then
				for i=0, partList:size() - 1 do
					local curPart = partList:get(i)
					local name = curPart:getScriptItem():getDisplayName()
					local itemOpt = subMenu:addOption(name .. " (" .. curPart:getCondition() .. "%)", playerObj, ISEngineMechanics.onAddPart, item, curPart, self);
					
					itemOpt.notAvailable = (ISEngineMechanics.getWrench(playerObj) == nil) and not ISEngineMechanics.cheat or (curPart:getMechanicType() ~= self.vehicle:getScript():getMechanicType())
					-- Todo: add icon from scriptItem.
					--itemOpt.iconTexture = scriptItem and scriptItem:getNormalTexture()
					self:doMenuTooltip(item, itemOpt, "addpart", curPart);
				end
			else
				-- No parts in player inventory, just display name redded out instead.
				local itemOpt = subMenu:addOption(getText("IGUI_EnginePanel_Misc_NoParts"), playerObj, nil);
				itemOpt.notAvailable = true;
				self:doMenuTooltip(item, itemOpt, "addpart", nil);
			end
			
		else
			if getDebug() and (ISEngineMechanics.cheat or (isClient() and isAdmin())) then
			option = self.context:addOption("CHEAT: Repair Part", playerObj, ISEngineMechanics.onCheatRepairPart, item.part)
			--option = self.context:addOption("CHEAT: Repair All Parts", playerObj, ISEngineMechanics.onCheatRepair, self.vehicle)
			option = self.context:addOption("CHEAT: Set Part Condition", playerObj, ISEngineMechanics.onCheatSetCondition, item.part)
			--if part:isContainer() and part:getContainerContentType() then
			--	option = self.context:addOption("CHEAT: Set Content Amount", playerObj, ISEngineMechanics.onCheatSetContentAmount, part)
			--end
			end		
		
			option = self.context:addOption(getText("IGUI_EnginePanel_Action_RemovePart"), playerObj, ISEngineMechanics.onRemovePart, item, self);
			
			option.notAvailable = (ISEngineMechanics.getWrench(playerObj) == nil) and not ISEngineMechanics.cheat
			self:doMenuTooltip(item, option, "removepart");
		end
	end	
	
	-- Todo: fill out information about each part. 
	-- Todo: Change getID to something that works for our parts.
	--[[
	local condInfo = getTextOrNull("IGUI_Vehicle_CondInfo" .. part:getId());
	if condInfo then
		option = self.context:addOption(getText("ContextMenu_PartInfo"), playerObj, nil)
		local tooltip = ISToolTip:new();
		tooltip:initialise();
		tooltip:setVisible(false);
		tooltip.description = condInfo;
		option.toolTip = tooltip;
	end--]]

	-- disable mechanics cheat for non-debug
	if getDebug() and (ISEngineMechanics.cheat or (isClient() and isAdmin())) then
		--option = self.context:addOption("CHEAT: Repair Part", playerObj, ISEngineMechanics.onCheatRepairPart, part)
		option = self.context:addOption("CHEAT: Repair All Parts", playerObj, ISEngineMechanics.onCheatRepair, self)
		--option = self.context:addOption("CHEAT: Set Part Condition", playerObj, ISEngineMechanics.onCheatSetCondition, item.part)
		--if part:isContainer() and part:getContainerContentType() then
		--	option = self.context:addOption("CHEAT: Set Content Amount", playerObj, ISEngineMechanics.onCheatSetContentAmount, part)
		--end
	end
	if getDebug() then
		if ISEngineMechanics.cheat then
			self.context:addOption("DBG: ISEngineMechanics.cheat=false", playerObj, ISEngineMechanics.onCheatToggle)
		else
			self.context:addOption("DBG: ISEngineMechanics.cheat=true", playerObj, ISEngineMechanics.onCheatToggle)
		end
	end
	
	if self.context.numOptions == 1 then self.context:setVisible(false) end
	if JoypadState.players[self.playerNum+1] and self.context:getIsVisible() then
		self.context.mouseOver = 1
		self.context.origin = self
		JoypadState.players[self.playerNum+1].focus = self.context
		updateJoypadFocus(JoypadState.players[self.playerNum+1])
	end
end

function ISEngineMechanics.onAddFluid(playerObj, item, newPart, engineMechanics)
	
	local engine = engineMechanics.vehicle:getPartById("Engine")
	if not ISVehicleMechanics.cheat then
		if playerObj:getVehicle() then
			ISVehicleMenu.onExit(playerObj)
		end
		
		ISVehiclePartMenu.toPlayerInventory(playerObj, newPart)
		local area = engine:getArea()
		ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, engineMechanics.vehicle, area))
		
		-- Should equip container here?
		--ISVehiclePartMenu.equipRequiredItems(playerObj, part, tbl)
	end
	
	-- Open the engine cover if needed
	local engineCover = nil;
	local doorPart = engineMechanics.vehicle:getPartById("EngineDoor")
	if doorPart and doorPart:getDoor() and doorPart:getInventoryItem() and not doorPart:getDoor():isOpen() then
		engineCover = doorPart
	end
	
	
	
	if engineCover and not ISVehicleMechanics.cheat then
		ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, engineMechanics.vehicle, engineCover))
		ISTimedActionQueue.add(ISTransferFluid:new(playerObj, newPart, item.part, false));
		--ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, part:getVehicle(), engineCover))
	else
		ISTimedActionQueue.add(ISTransferFluid:new(playerObj, newPart, item.part, false));
	end	
	
	-- Transfer fluid from newPart to item.Part
	-- newPart:getFluidContainer():transferTo(item.part:getFluidContainer())
end

function ISEngineMechanics.onRemoveFluid(playerObj, item, newPart, engineMechanics)
	local engine = engineMechanics.vehicle:getPartById("Engine")
	if not ISVehicleMechanics.cheat then
		if playerObj:getVehicle() then
			ISVehicleMenu.onExit(playerObj)
		end
		
		ISVehiclePartMenu.toPlayerInventory(playerObj, newPart)

		local area = engine:getArea()
		ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, engineMechanics.vehicle, area))

		-- Should equip container here?
		--ISVehiclePartMenu.equipRequiredItems(playerObj, part, tbl)
	end
	
	-- Open the engine cover if needed
	local engineCover = nil;
	local doorPart = engineMechanics.vehicle:getPartById("EngineDoor")
	if doorPart and doorPart:getDoor() and doorPart:getInventoryItem() and not doorPart:getDoor():isOpen() then
		engineCover = doorPart
	end
	
	
	
	if engineCover and not ISVehicleMechanics.cheat then
		ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, engineMechanics.vehicle, engineCover))
		ISTimedActionQueue.add(ISTransferFluid:new(playerObj, item.part, newPart, true));
		--ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, part:getVehicle(), engineCover))
	else
		ISTimedActionQueue.add(ISTransferFluid:new(playerObj, item.part, newPart, true));
	end	

	-- Transfer fluid from item.Part to newPart
	--item.part:getFluidContainer():transferTo(newPart:getFluidContainer())
	

end


function ISEngineMechanics.onAddPart(playerObj, item, newPart, engineMechanics)

	--print("Onadd part ", playerobj, " ",item, " ", newPart, " ", engineMechanics.vehicle)
	local engine = engineMechanics.vehicle:getPartById("Engine")
	if not ISVehicleMechanics.cheat then
		if playerObj:getVehicle() then
			ISVehicleMenu.onExit(playerObj)
		end
		
		ISVehiclePartMenu.toPlayerInventory(playerObj, newPart)
		
		--local tbl = part:getTable("install")
		--ISVehiclePartMenu.transferRequiredItems(playerObj, part, tbl)

		local area = engine:getArea()
		ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, engineMechanics.vehicle, area))
		
		--ISVehiclePartMenu.equipRequiredItems(playerObj, part, tbl)
	end
	
	-- Open the engine cover if needed
	local engineCover = nil;
	local doorPart = engineMechanics.vehicle:getPartById("EngineDoor")
	if doorPart and doorPart:getDoor() and doorPart:getInventoryItem() and not doorPart:getDoor():isOpen() then
		engineCover = doorPart
	end
	
	
	
	if engineCover and not ISVehicleMechanics.cheat then
		ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, engineMechanics.vehicle, engineCover))
		ISTimedActionQueue.add(ISInstallEnginePart:new(playerObj, engineMechanics, engineMechanics.vehicle, item, newPart))
		--ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, part:getVehicle(), engineCover))
	else
		ISTimedActionQueue.add(ISInstallEnginePart:new(playerObj, engineMechanics, engineMechanics.vehicle, item, newPart))
	end

--[[
	local wrench = ISEngineMechanics.getWrench(playerObj)
	if (wrench == nil and not ISEngineMechanics.cheat) then return end

	if playerObj:getVehicle() then
		ISVehicleMenu.onExit(playerObj)
	end
	
	--print("Part Power: ", newPart:getScriptItem():getMaxItemSize());
	
	playerObj:removeFromHands(newPart)
	playerObj:getInventory():DoRemoveItem(newPart)
	sendRemoveItemFromContainer(playerObj:getInventory(),newPart)
	--item.part = newPart; 
	
	local engine = engineMechanics.vehicle:getPartById("Engine")
	engine:getItemContainer():AddItem(newPart)
	--engine:getModData().EngineDamageSensorDisable = 2
	
	engineMechanics:updateParts();
	-- Make sure to add all instances of this part, due to fluid containers you get multiple!
	--]]
end

function ISEngineMechanics.onRemovePart(playerObj, item, engineMechanics)

	local engine = engineMechanics.vehicle:getPartById("Engine")
	if not ISVehicleMechanics.cheat then
		if playerObj:getVehicle() then
			ISVehicleMenu.onExit(playerObj)
		end
		
		--local tbl = part:getTable("uninstall")
		--ISVehiclePartMenu.transferRequiredItems(playerObj, part, tbl)
		local area = engine:getArea()
		ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, engineMechanics.vehicle, area))
		--ISVehiclePartMenu.equipRequiredItems(playerObj, part, tbl)
	end
	
	
	-- Open the engine cover if needed
	local engineCover = nil;
	local doorPart = engineMechanics.vehicle:getPartById("EngineDoor")
	if doorPart and doorPart:getDoor() and doorPart:getInventoryItem() and not doorPart:getDoor():isOpen() then
		engineCover = doorPart
	end

	if engineCover and not ISVehicleMechanics.cheat then
		ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, engineMechanics.vehicle, engineCover))
		ISTimedActionQueue.add(ISUninstallEnginePart:new(playerObj, engineMechanics, engineMechanics.vehicle, item))
		--ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, engineMechanics.vehicle, engineCover))
	else
		ISTimedActionQueue.add(ISUninstallEnginePart:new(playerObj, engineMechanics, engineMechanics.vehicle, item))
	end
end

function ISEngineMechanics.onCheatRepair(playerObj, engineMechanics)
	-- Clear all parts and respawn with forced quality
	local engine = engineMechanics.vehicle:getPartById("Engine")
	engine:getItemContainer():clear()
	initVehicleEngine(engineMechanics.vehicle,true)
	engineMechanics:initParts();
end

function ISEngineMechanics.onCheatRepairPart(playerObj, part)
	part:setCondition(100)	
end

function ISEngineMechanics.onCheatSetConditionAux(target, button, playerObj, part)
	if button.internal ~= "OK" then return end
	local text = button.parent.entry:getText()
	local condition = tonumber(text)
	if not condition then return end
	condition = math.max(condition, 0)
	condition = math.min(condition, 100)
	--local vehicle = part:getVehicle()
	part:setCondition(condition)
	--sendClientCommand(playerObj, "vehicle", "setPartCondition", { vehicle = vehicle:getId(), part = part:getId(), condition = condition })
end

function ISEngineMechanics.onCheatSetCondition(playerObj, part)
	local modal = ISTextBox:new(0, 0, 280, 180, "Condition (0-100):", tostring(part:getCondition()),
		nil, ISEngineMechanics.onCheatSetConditionAux, playerObj:getPlayerNum(), playerObj, part)
	modal:initialise()
	modal:addToUIManager()
end

function ISEngineMechanics.onCheatSetContentAmountAux(target, button, playerObj, part)
	if button.internal ~= "OK" then return end
	local text = button.parent.entry:getText()
	local amount = tonumber(text)
	if not amount then return end
	local vehicle = part:getVehicle()
	if isClient() then
		sendClientCommand(playerObj, "vehicle", "setContainerContentAmount", { vehicle = vehicle:getId(), part = part:getId(), amount = amount })
	else
		part:setContainerContentAmount(amount)
	end
end

function ISEngineMechanics.onCheatSetContentAmount(playerObj, part)
	local modal = ISTextBox:new(0, 0, 280, 180, "Content Amount:", tostring(part:getContainerContentAmount()),
		nil, ISEngineMechanics.onCheatSetContentAmountAux, playerObj:getPlayerNum(), playerObj, part)
	modal:initialise()
	modal:addToUIManager()
end

function ISEngineMechanics.onCheatToggle(playerObj)
	ISEngineMechanics.cheat = not ISEngineMechanics.cheat
	playerObj:setMechanicsCheat(ISEngineMechanics.cheat)
	if isClient() then
	    sendPlayerExtraInfo(playerObj)
	end
end

function ISEngineMechanics:doMenuTooltip(item, option, lua, part)

	local tooltip = ISToolTip:new();
	tooltip:initialise();
	tooltip:setVisible(false);
	--tooltip.description = getText("Tooltip_craft_Needs") .. " : <LINE>";
	tooltip.description = ""
	option.toolTip = tooltip;
	local playerObj = getSpecificPlayer(self.playerNum);

	local wrench = ISEngineMechanics.getWrench(playerObj)
	--local screwdriver = ISEngineMechanics.getScrewdriver(self.chr)

	if lua == "addfluid" then
		tooltip.description = tooltip.description .. getText("IGUI_EnginePanel_Action_AddFluid_tooltip") .. " <LINE>"
	elseif lua == "removefluid" then
		tooltip.description = tooltip.description .. getText("IGUI_EnginePanel_Action_RemoveFluid_tooltip") .. " <LINE>"
	end

	if (lua == "addfluid") or (lua == "removefluid") then
		tooltip.description = tooltip.description .. getText("IGUI_EnginePanel_AmountCapacity") .. string.format("%.2f/%.2fL <LINE>",part:getFluidContainer():getAmount(), part:getFluidContainer():getCapacity())
		
		tooltip.description = tooltip.description ..  getText("IGUI_EnginePanel_MainFluid") .. (part:getFluidContainer():getPrimaryFluid() and part:getFluidContainer():getPrimaryFluid():getTranslatedName() or getText("IGUI_None")) .. " <LINE>"
		tooltip.description = tooltip.description ..  getText("IGUI_EnginePanel_MixedFluid") .. (part:getFluidContainer():isMixture() and getText("IGUI_Yes") or getText("IGUI_No")) .. " <LINE>"
	end
	
	if lua == "addpart" then
		if part then -- valid part
		
			if part:getMechanicType() ~= self.vehicle:getScript():getMechanicType() then
				tooltip.description = tooltip.description .. getText("IGUI_EnginePanel_Misc_IncorrectVehicleType")
				return;
			else

				tooltip.description = tooltip.description .. getText("IGUI_EnginePanel_Action_InstallPart_tooltip")
				if not wrench then
					tooltip.description = tooltip.description .. " " .. ISEngineMechanics.bhs .. getItemDisplayName("Base.Wrench") .. " 0/1 <LINE>";
				else
					tooltip.description = tooltip.description .. " " .. ISEngineMechanics.ghs .. getItemDisplayName("Base.Wrench") .. " 1/1 <LINE>";
				end
			end
		else
			tooltip.description = tooltip.description .. ISEngineMechanics.bhs .. getText("IGUI_EnginePanel_Misc_NoValidParts")
		end
	end

	if lua == "removepart" then
	tooltip.description = tooltip.description .. getText("IGUI_EnginePanel_Action_RemovePart_tooltip")
		if not wrench then
			tooltip.description = tooltip.description .. " " .. ISEngineMechanics.bhs .. getItemDisplayName("Base.Wrench") .. " 0/1 <LINE>";
		else
			tooltip.description = tooltip.description .. " " .. ISEngineMechanics.ghs .. getItemDisplayName("Base.Wrench") .. " 1/1 <LINE>";
		end
	end
	
	-- now required skill
	
	if lua == "removepart" or lua == "addpart" then
			
		tooltip.description = tooltip.description .. " " .. ISEngineMechanics.ghs .. " " .. getText("Tooltip_vehicle_recommendedSkill", getText("IGUI_perks_Mechanics"), playerObj:getPerkLevel(Perks.Mechanics) .. "/" .. item.skill) .. " <LINE>";
		local failure = ISInstallEnginePart.calculateInstallationChance(playerObj,item.skill);
		--if success < 100 or failure > 0 then
		local successCol = ColorInfo.new(1, 1, 1, 0)
		local failCol = ColorInfo.new(1, 1, 1, 0)
		--getCore():getBadHighlitedColor():interp(getCore():getGoodHighlitedColor(), success/100, successCol);
		getCore():getGoodHighlitedColor():interp(getCore():getBadHighlitedColor(), failure/100, failCol);
		local colorFailure = "<RGB:".. failCol:getR() ..",".. failCol:getG() ..",".. failCol:getB() ..">";
		tooltip.description = tooltip.description .. colorFailure .. getText("IGUI_EnginePanel_Misc_ChanceOfDamage") .. " " .. math.floor(failure) .. "%";
		--end
		
	end
end



function ISEngineMechanics:doDrawItem(y, item, alt)
	if not item.item.cat then
		if item.itemindex == self.selected then
			self:drawRect(0, y, self:getWidth(), item.height, 0.1, 1.0, 1.0, 1.0);
		elseif item.itemindex == self.mouseoverselected and ((self.parent.context and not self.parent.context:isVisible()) or not self.parent.context) then
			self:drawRect(0, y, self:getWidth(), item.height, 0.05, 1.0, 1.0, 1.0);
		end
	end
	
	if item.item.cat then
		self:drawText(item.item.name, 0, y, self.parent.partCatRGB.r, self.parent.partCatRGB.g, self.parent.partCatRGB.b, self.parent.partCatRGB.a, UIFont.Medium);
		y = y + 5;
	else
		local rgb = self.parent.partRGB;
		local badRGB = getCore():getBadHighlitedColor();
		
		--self:drawText("HELLO EVERYBODY IM DOCTOR NICK.. IN YOUR ENGINE", 20, y, getCore():getBadHighlitedColor():getR(), getCore():getBadHighlitedColor():getG(), getCore():getBadHighlitedColor():getB(), 1, UIFont.Small);
		
		if item.item.part then
			
		
		
			if item.item.isFluid then
				if item.item.part:getFluidContainer() then
					self:drawText(item.item.name, 20, y, rgb.r, rgb.g, rgb.b, rgb.a, UIFont.Small);
					
					-- Todo: round number off. 
					local amount = (item.item.part:getFluidContainer():getAmount() * 100.0f) / item.item.part:getFluidContainer():getCapacity()
					local condRGB = self.parent:getConditionRGB(amount);
					self:drawText(" (" .. math.floor(amount) .. "%)", getTextManager():MeasureStringX(UIFont.Small, item.item.name) + 22, y, condRGB.r, condRGB.g, condRGB.b, self.parent.partRGB.a, UIFont.Small)
				end
			else
				local condition = item.item.part:getCondition()
				local condRGB = self.parent:getConditionRGB(condition);
				local itemName = item.item.part:getDisplayName()
				self:drawText(itemName, 20, y, rgb.r, rgb.g, rgb.b, rgb.a, UIFont.Small);
				self:drawText(" (" .. condition .. "%)", getTextManager():MeasureStringX(UIFont.Small, itemName) + 22, y, condRGB.r, condRGB.g, condRGB.b, self.parent.partRGB.a, UIFont.Small)
			end
		else
			self:drawText(item.item.name .. " ".. getText("IGUI_EnginePanel_Misc_Missing"), 20, y, badRGB:getR(), badRGB:getG(), badRGB:getB(), 1, UIFont.Small);
		end
	end
	
	return y + self.itemheight;
end

-- render the car overlay on the left based on ISCarMechanicsOverlay
function ISEngineMechanics:renderCarOverlay()
	-- Replace with some cool engine overlay thing, someday. 
	-- Display some cool engine picture instead?
end

function ISEngineMechanics:selectPart(part)
	--[[if not part then return end
	for i=1,self.listbox:size() do
		local item = self.listbox.items[i]
		if item.item.part == part then
			if self.joyfocus then self:onJoypadDirLeft() end
			self.bodyworklist.selected = -1
			self.listbox.selected = i
			self.listbox:ensureVisible(i)
			return
		end
	end
	for i=1,self.bodyworklist:size() do
		local item = self.bodyworklist.items[i]
		if item.item.part == part then
			if self.joyfocus then self:onJoypadDirRight() end
			self.listbox.selected = -1
			self.bodyworklist.selected = i
			self.bodyworklist:ensureVisible(i)
			return
		end
	end--]]
end

function ISEngineMechanics:isMouseOverPart(x, y, part)
	return false -- murdered because it relates to old icon stuff
end

function ISEngineMechanics:getMouseOverPart(x, y)
	return nil -- murdered because it relates to old icon stuff
end

function ISEngineMechanics:onMouseDown(x, y)
	ISCollapsableWindow.onMouseDown(self, x, y)
	local part = self:getMouseOverPart(self:getMouseX(), self:getMouseY())
	self:selectPart(part)
end

function ISEngineMechanics:onRightMouseUp(x, y)
	local playerObj = getSpecificPlayer(self.playerNum)
	local part = self:getMouseOverPart(x, y)
	--print("Mouseup over part ", part);
	self.context = nil
	if part then
		self:selectPart(part)
		self:doPartContextMenu(part, x, y)
	-- disable mechanics cheat for non-debug
	elseif getDebug() and (ISEngineMechanics.cheat or (isClient() and isAdmin())) then
		if UIManager.getSpeedControls():getCurrentGameSpeed() == 0 then return; end
		self.context = ISContextMenu.get(self.playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY())
		if self.vehicle:getScript() and self.vehicle:getScript():getWheelCount() > 0 then
			if self.vehicle:getPartById("Engine") then
				self.context:addOption("CHEAT: Get Key", playerObj, ISEngineMechanics.onCheatGetKey, self.vehicle)
			end
			self.context:addOption("CHEAT: Repair All Parts", playerObj, ISEngineMechanics.onCheatRepair, self)
			--self.context:addOption("CHEAT: Repair Vehicle", playerObj, ISEngineMechanics.onCheatRepair, self.vehicle)
		end
	end
	if not part and getDebug() then
		if not self.context then self.context = ISContextMenu.get(self.playerNum, x + self:getAbsoluteX(), y + self:getAbsoluteY()) end
		if ISEngineMechanics.cheat then
			self.context:addOption("DBG: ISEngineMechanics.cheat=false", playerObj, ISEngineMechanics.onCheatToggle)
		else
			self.context:addOption("DBG: ISEngineMechanics.cheat=true", playerObj, ISEngineMechanics.onCheatToggle)
		end
	end
end

function ISEngineMechanics:startFlashRed()
	self.flashFailure = true
	self.flashTimer = 250;
	self.flashTimerAlpha = 1;
	self.flashTimerAlphaInc = false;
end

function ISEngineMechanics:startFlashGreen()
	self.flashFailure = false
	self.flashTimer = 250;
	self.flashTimerAlpha = 1;
	self.flashTimerAlphaInc = false;
end

local ROUND_CONTENT_AMOUNT = {
	Air = 1,
	Gasoline = 3,
}

function ISEngineMechanics:roundContainerContentAmount(part)
	local amount = part:getContainerContentAmount()
	return round(amount, ROUND_CONTENT_AMOUNT[part:getContainerContentType()] or 3)
end

function ISEngineMechanics:prerender()
	ISCollapsableWindow.prerender(self)
	self:updateLayout()
end

function ISEngineMechanics:render()
	ISCollapsableWindow.render(self)
	if self.isCollapsed then return end
	
	
	local fgBar = {r=getCore():getGoodHighlitedColor():getR(), g=getCore():getGoodHighlitedColor():getG(), b=getCore():getGoodHighlitedColor():getB(), a=1}
	--	self:drawTexture(self.texVehicle, 20, 50, 1);
	self:renderCarOverlay();
	
	-- car info rect
	local x = self.xCarTexOffset;
	local y = self:titleBarHeight() + 10;
	local lineHgt = FONT_HGT_SMALL;
	local rectWidth = self:getWidth() - self.xCarTexOffset - 10;
	local rectHgt = 5 + FONT_HGT_MEDIUM + FONT_HGT_SMALL * (5 + 1) -- +1 for the progressbar
	self:drawRectBorder(x, y, rectWidth, rectHgt, 1, self.borderColor.r, self.borderColor.g, self.borderColor.b);
	x = x + 5;
	y = y + 5;
	local debugLine = "";
    local carName = self.vehicle:getScript():getCarModelName() or self.vehicle:getScript():getName()
	local name = getText("IGUI_VehicleName" .. carName);
	if string.match(self.vehicle:getScript():getName(), "Burnt") then
		local unburnt = string.gsub(self.vehicle:getScript():getName(), "Burnt", "")
		if getTextOrNull("IGUI_VehicleName" .. unburnt) then
			name = getText("IGUI_VehicleName" .. unburnt)
		end
		name = getText("IGUI_VehicleNameBurntCar", name);
	end
	self:drawTextCentre(getText("IGUI_EnginePanel_Misc_Engine") .. name .. debugLine, x + (rectWidth / 2), y, self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Medium);
	--self:drawTextCentre("Engine" .. debugLine, x + (rectWidth / 2), y, self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Medium);
	y = y + FONT_HGT_MEDIUM;
	self:drawText(getText("Tooltip_item_Mechanic") .. ": " .. getText("IGUI_VehicleType_" .. self.vehicle:getScript():getMechanicType()), x, y, self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Small);
	y = y + lineHgt;
	
	-- Change this to show overall engine condition instead?
	self:drawText(getText("IGUI_OverallCondition") .. ": ", x, y, self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Small);
	self:drawText(self.engineCondition .. "%", x + getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_OverallCondition") .. ": ") + 2, y, self.engineCondRGB.r, self.engineCondRGB.g, self.engineCondRGB.b, self.partCatRGB.a, UIFont.Small);
	y = y + lineHgt;
	self:drawText(getText("IGUI_char_Weight") .. ": " .. self.vehicle:getMass(), x, y, self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Small);
	y = y + lineHgt;
	if self.vehicle:getPartById("Engine") then
		self:drawText(getText("IGUI_EnginePower") .. ": " .. (self.vehicle:getEnginePower()/10) .. " hp", x, y, self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Small);
	end
	--	y = y + lineHgt;
	--	self:drawText("Ignition :", x, y, self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Small);
	--	if self.checkEngine then
	--		self:drawText("Ok", x + getTextManager():MeasureStringX(UIFont.Small, "Engine :") + 2, y, 0.1, 0.9, 0.1, self.partCatRGB.a, UIFont.Small);
	--	else
	--		self:drawText("Failure", x + getTextManager():MeasureStringX(UIFont.Small, "Engine :") + 2, y, 1, 0, 0, self.partCatRGB.a, UIFont.Small);
	--	end
	y = y + lineHgt + 4;
	local actionQueue = ISTimedActionQueue.getTimedActionQueue(self.chr);
	local progress = false;
	if actionQueue and actionQueue.queue and actionQueue.queue[1] and actionQueue.queue[1].jobType and actionQueue.queue[1].jobType ~= "" then
		local progressY = 30 + rectHgt - lineHgt - 4
		self:drawProgressBar(x, progressY, rectWidth - 10, lineHgt - 2, actionQueue.queue[1]:getJobDelta(), fgBar);
		self:drawTextCentre(actionQueue.queue[1].jobType, (self.width - 12 + x) / 2, progressY - 2, 0.8, 0.8, 0.8, 1, UIFont.Small);
		y = y + lineHgt;
		progress = true;
	end
	
	if not progress and self.flashTimer > 0 then
		local progressY = 30 + rectHgt - lineHgt - 4
		self.flashTimer = self.flashTimer - 1
		if self.flashFailure then
			self:drawProgressBar(x, progressY, rectWidth - 10, lineHgt - 2, 100, {r=0.5, g=0.1, b=0.1, a=self.flashTimerAlpha});
			self:drawTextCentre(getText("IGUI_Failure"), (self.width - 12 + x) / 2, progressY- 2, 0.8, 0.8, 0.8, 1, UIFont.Small);
		else
			self:drawProgressBar(x, progressY, rectWidth - 10, lineHgt - 2, 100, {r=0.1, g=0.6, b=0.1, a=self.flashTimerAlpha});
			self:drawTextCentre(getText("IGUI_Success"), (self.width - 12 + x) / 2, progressY- 2, 0.8, 0.8, 0.8, 1, UIFont.Small);
		end
		if self.flashTimerAlphaInc then
			self.flashTimerAlpha = self.flashTimerAlpha + 0.06;
			if self.flashTimerAlpha >= 1 then self.flashTimerAlpha = 1; self.flashTimerAlphaInc = false; end
		else
			self.flashTimerAlpha = self.flashTimerAlpha - 0.06;
			if self.flashTimerAlpha <= 0 then self.flashTimerAlpha = 0; self.flashTimerAlphaInc = true; end
		end
		y = y + lineHgt;
	end
	
	-- list of parts
	x = self.xCarTexOffset;
	y = 140;
	--	self:drawText("Parts:", x, y, self.partCatRGB.r, self.partCatRGB.g, self.partCatRGB.b, self.partCatRGB.a, UIFont.Medium);
	
	local selectedPart;
	if self.listbox.items[self.listbox.selected] then
		selectedPart = self.listbox.items[self.listbox.selected].item;
	elseif self.bodyworklist.items[self.bodyworklist.selected] then
		selectedPart = self.bodyworklist.items[self.bodyworklist.selected].item;
	end
	if selectedPart then self:renderPartDetail(selectedPart); end
	
	if self.drawJoypadFocus and self.leftListHasFocus then
		local ui = self.listbox
		self:drawRectBorder(ui:getX(), ui:getY(), ui:getWidth(), ui:getHeight(), 0.4, 0.2, 1.0, 1.0);
		self:drawRectBorder(ui:getX()+1, ui:getY()+1, ui:getWidth()-2, ui:getHeight()-2, 0.4, 0.2, 1.0, 1.0);
	elseif self.drawJoypadFocus then
		local ui = self.bodyworklist
		self:drawRectBorder(ui:getX(), ui:getY(), ui:getWidth(), ui:getHeight(), 0.4, 0.2, 1.0, 1.0);
		self:drawRectBorder(ui:getX()+1, ui:getY()+1, ui:getWidth()-2, ui:getHeight()-2, 0.4, 0.2, 1.0, 1.0);
	end
end

function ISEngineMechanics:renderPartDetail(part)
	
	self.infoPanel.text = part.info or "";
	self.infoPanel:paginate();

end

function ISEngineMechanics:getConditionRGB(condition)
	local colorB = Color.new(getCore():getBadHighlitedColor():getR(), getCore():getBadHighlitedColor():getG(), getCore():getBadHighlitedColor():getB())
	local colorG = Color.new(getCore():getGoodHighlitedColor():getR(), getCore():getGoodHighlitedColor():getG(), getCore():getGoodHighlitedColor():getB())
	local colorA = Color.new(getCore():getBadHighlitedColor():getR(), getCore():getBadHighlitedColor():getG(), getCore():getBadHighlitedColor():getB())
	colorB:interp(colorG, condition/100, colorA);
	return {r=colorA:getR(), g=colorA:getG(), b=colorA:getB()};
end

function ISEngineMechanics:setVisible(bVisible, joypadData)
	if self.javaObject == nil then
		self:instantiate();
	end
	
	self:setEnabled(bVisible);
	
	self.javaObject:setVisible(bVisible);
	if self.visibleTarget and self.visibleFunction then
		self.visibleFunction(self.visibleTarget, self);
	end
	
	if self.vehicle then
		self.vehicle:setActiveInBullet(bVisible);
		self.vehicle:setMechanicUIOpen(bVisible);
	end
	
	if self.tooltip then
		self.tooltip:setVisible(false);
	end
	
	if bVisible and joypadData then
		joypadData.focus = self
		updateJoypadFocus(joypadData)
	end
	
	if self.usedHood then
		if not bVisible then
			if self.chr and self.vehicle and self.vehicle:isInArea(self.usedHood:getArea(), self.chr) then
				ISTimedActionQueue.add(ISCloseVehicleDoor:new(self.chr, self.vehicle, self.usedHood))
			end
			self.usedHood = nil
		else
			if self.chr and self.vehicle then
				ISTimedActionQueue.add(ISOpenVehicleDoor:new(self.chr, self.vehicle, self.usedHood))
			end
		end
	end
end

function ISEngineMechanics:close()
	self:setVisible(false)
	self:setEnabled(false);
	
	self:removeFromUIManager()
	if JoypadState.players[self.playerNum+1] then
		setJoypadFocus(self.playerNum, nil)
	end
	
end

function ISEngineMechanics:onListboxJoypadDirUp(listbox)
	listbox:onJoypadDirUp()
	if listbox.items[listbox.selected].item.cat then
		listbox:onJoypadDirUp()
	end
	if listbox.selected == 2 then
		listbox:ensureVisible(1)
	end
end

function ISEngineMechanics:onListboxJoypadDirDown(listbox)
	listbox:onJoypadDirDown()
	if listbox.items[listbox.selected].item.cat then
		listbox:onJoypadDirDown()
	end
	if listbox.selected == 2 then
		listbox:ensureVisible(1)
	end
end

function ISEngineMechanics:onGainJoypadFocus(joypadData)
	ISPanel.onGainJoypadFocus(self, joypadData)
	self.drawJoypadFocus = true
end

function ISEngineMechanics:onJoypadDown(button)
	if button == Joypad.AButton then
		local listbox = self.leftListHasFocus and self.listbox or self.bodyworklist
		local item = listbox.items[listbox.selected]
		if item and not item.item.cat then
			local menuX = listbox:getX() + 20
			local menuY = listbox:getY() + listbox:topOfItem(listbox.selected) + item.height + listbox:getYScroll()
			self:doPartContextMenu(item.item, menuX, menuY)
		end
	end
	if button == Joypad.BButton then
		self:close()
	end
end

function ISEngineMechanics:onJoypadDirUp()
	if self.leftListHasFocus then
		self:onListboxJoypadDirUp(self.listbox)
	else
		self:onListboxJoypadDirUp(self.bodyworklist)
	end
end

function ISEngineMechanics:onJoypadDirDown()
	if self.leftListHasFocus then
		self:onListboxJoypadDirDown(self.listbox)
	else
		self:onListboxJoypadDirDown(self.bodyworklist)
	end
end

function ISEngineMechanics:onJoypadDirLeft()
	if self.leftListHasFocus then return end
	self.leftListHasFocus = true
	self.rightListSelection = self.bodyworklist.selected
	self.bodyworklist.selected = -1
	self.listbox.selected = self.leftListSelection or -1
end

function ISEngineMechanics:onJoypadDirRight()
	if not self.leftListHasFocus then return end
	self.leftListHasFocus = false
	self.leftListSelection = self.listbox.selected
	self.listbox.selected = -1
	self.bodyworklist.selected = self.rightListSelection or 1
end

function ISEngineMechanics:new(x, y, character, vehicle)
	local width = 500;
	local height = 450;
	if x == 0 and y == 0 then
		x = (getCore():getScreenWidth() / 2) - (width / 2);
		y = (getCore():getScreenHeight() / 2) - (height / 2);
	end
	local o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;
	o.minimumHeight = height
	o.chr = character;
	o.playerNum = character:getPlayerNum();
	o.vehicle = vehicle;
	o:setResizable(true);
	o.partCatRGB = {r=1;g=1;b=1;a=1};
	o.partRGB = {r=0.8;g=0.8;b=0.8;a=1};
	o.title = getText("IGUI_EnginePanel_Misc_Title");
	o.clearStentil = false;
	--	o.borderColor = {r=1;g=1;b=1;a=1};
	--o.xCarTexOffset = 300;
	o.xCarTexOffset = 10; -- Just set to 0 till we do something with this... 
	--	o.texVehicle = getTexture("media/ui/vehicle/vehicle.png")
	o.leftListHasFocus = true
	o.flashFailure = false;
	o.flashTimer = 0;
	o.flashTimerAlpha = 1;
	o.flashTimerAlphaInc = false;
	o:setWantKeyEvents(true)
	return o
end

function ISEngineMechanics:isKeyConsumed(key)
	return key == Keyboard.KEY_ESCAPE or
			getCore():isKey("VehicleMechanics", key)
end

function ISEngineMechanics:onKeyRelease(key)
	if key == Keyboard.KEY_ESCAPE then
		if isPlayerDoingActionThatCanBeCancelled(self.chr) then
			stopDoingActionThatCanBeCancelled(self.chr)
		else
			self:close()
		end
	end
	if getCore():isKey("VehicleMechanics", key) then
		self:close();
	end
end

ISEngineMechanics.OnMechanicActionDone = function(chr, success)
	local ui = getPlayerMechanicsUI(chr:getPlayerNum());
	if ui and ui:isReallyVisible() then
		if success then ui:startFlashGreen()
		else ui:startFlashRed() end
	end
end

function ISEngineMechanics.getWrench(player)
	return player:getInventory():getFirstTypeEvalRecurse("Wrench", predicateNotBroken)
end

function ISEngineMechanics.getScrewdriver(player)
	return player:getInventory():getFirstTagEvalRecurse("Screwdriver", predicateNotBroken)
end

Events.OnMechanicActionDone.Add(ISEngineMechanics.OnMechanicActionDone);
