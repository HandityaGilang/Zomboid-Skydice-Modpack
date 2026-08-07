--Ammo Maker by STIMP_TM, based on Project Zomboid ISBuildingObject by ROBERT JOHNSON

ammomaker_ISBirdFeeder = ISBuildingObject:derive("ammomaker_ISBirdFeeder");

function ammomaker_ISBirdFeeder:create(x, y, z, north, sprite)

	local cell = getWorld():getCell();
	self.sq = cell:getGridSquare(x, y, z);
	self.javaObject = IsoThumpable.new(cell, self.sq, sprite, north, self);
	buildUtil.setInfo(self.javaObject, self);
	buildUtil.consumeMaterial(self);
	self.javaObject:setOutlineThickness(1);

	--the wooden wall have 200 base health + 100 per carpentry lvl

	self.javaObject:setMaxHealth(self:getHealth());
	self.javaObject:setHealth(self.javaObject:getMaxHealth());

	--the sound that will be played when the bird feeder will be broken

	self.javaObject:setBreakSound("BreakObject");

	--construct sprite with properties

	local sharedSprite = getSprite(self:getSprite())

	if self.sq and sharedSprite and sharedSprite:getProperties():Is("IsStackable") then

		local props = ISMoveableSpriteProps.new(sharedSprite);
		self.javaObject:setRenderYOffset(props:getTotalTableHeight(self.sq));

	end

	--add the item to the ground

    self.sq:AddSpecialObject(self.javaObject);
	self.javaObject:transmitCompleteItemToServer();

	--update mod data and transmit to server

	local birdFeederSaveID = "birdFeeder";
	local birdFeederTableClient = ModData.getOrCreate(birdFeederSaveID);

	local birdFeederLocationClientNew = x .. "," .. y .. "," .. z;

	local isPartOf = false;

	for _, birdFeederLocationClient in ipairs(birdFeederTableClient) do

		if birdFeederLocationClientNew == birdFeederLocationClient then

			isPartOf = true;

		end

	end

	if isPartOf == false then

		table.insert(birdFeederTableClient, birdFeederLocationClientNew);

	end

	ModData.add(birdFeederSaveID, birdFeederTableClient);
	ModData.transmit(birdFeederSaveID);

end

function ammomaker_ISBirdFeeder:new(sprite, northSprite)

	local o = {};
	setmetatable(o, self);
	self.__index = self;
	o:init();
	o:setSprite(sprite);
	o:setNorthSprite(northSprite);
	o.isContainer = true;
	o.blockAllTheSquare = true;
	o.name = "Bird Feeder";
	o.dismantable = true;
	return o;

end

--return the health of the new container, it's 200 + 100 per carpentry lvl

function ammomaker_ISBirdFeeder:getHealth()

	return 200 + buildUtil.getWoodHealth(self);

end

function ammomaker_ISBirdFeeder:isValid(square)

    if buildUtil.stairIsBlockingPlacement( square, true ) then
		return false;
	end

	if not self:haveMaterial(square) then
		return false;
	end

	local sharedSprite = getSprite(self:getSprite());

	if square and sharedSprite and sharedSprite:getProperties():Is("IsStackable") then
		local props = ISMoveableSpriteProps.new(sharedSprite);
		return props:canPlaceMoveable("bogus", square, nil);
	end

	return ISBuildingObject.isValid(self, square);

end

function ammomaker_ISBirdFeeder:render(x, y, z, square)

	ISBuildingObject.render(self, x, y, z, square);

end
