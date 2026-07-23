Project_Dashboard = {}
Project_Dashboard.Dashes = {}

function Project_Dashboard.addDash(dash)
	table.insert(Project_Dashboard.Dashes,dash); 
end

function setupSwitches(x, y, spacing)

	local switches = { -- Can add new switches here if you want, will call its onClick member. Can override existing switches like that too. 
		radio = 	 {x = x+0*spacing, y = y, icon = "media/textures/dashboard/dash_radio.png"},
		heater = 	 {x = x+1*spacing, y = y, icon = "media/textures/dashboard/heatericon.png"}, -- Heater was taken. 
		locks = 	 {x = x+2*spacing, y = y, icon = "media/textures/dashboard/door_lock.png"},
		trunk = 	 {x = x+3*spacing, y = y, icon = "media/textures/dashboard/trunk_lock.png"},
		headlights = {x = x+4*spacing, y = y, icon = "media/textures/dashboard/headlight.png"},
	}

	local buttonTextureNames = {"media/textures/dashboard/switch_off.png","media/textures/dashboard/switch_on.png"}
	for key,switch in pairs(switches) do -- Init common stuff. Its stored per-switch to allow later variation between dashes. 
		switch.buttonTextureNames = buttonTextureNames
		switch.iconOffset = {x = 0, y = -30}
		switch.ledBG = "media/textures/dashboard/switch_indicator.png"
		switch.ledBGOffset = {x = 0, y = -10}
		switch.led = "media/textures/dashboard/switch_indicator_light.png"
		switch.ledOffset = {x = 0, y = -8}
	end 
	return switches
end


function setupIgnition(x, y)
	local ignition = {
		x = x, y = y, filename = "media/textures/dashboard/ignitionkeyhole.png",
		emptyIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/ignitionkeyempty.png"},
		keyOffIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/ignitionkeyoff.png"},
		keyRunIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/ignitionkeyon.png"},
		keyStartIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/ignitionkeystart.png"},
		hotwireOffIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/hotwire_off.png"},
		hotwireOnIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/hotwire_on.png"},
	}
	return ignition;
end

local dashboard = {
	name = "Main Dash",
	background = "media/textures/dashboard/dashboardbackground.png",
	
	rpmGauge = {x = 193, y = 18, needleLength = 37, needleX = 121/2, needleY = 121/2, needleStart = 267, needleEnd = 29, filename = "media/textures/dashboard/tachometer.png", 
				redline4500 = "media/textures/dashboard/tachometer4500.png", redline6000 = "media/textures/dashboard/tachometer6000.png"},
				
	speedGauge = {x = 393, y = 18, needleLength = 37, needleX = 121/2, needleY = 121/2, needleStart = 267, needleEnd = 29, filename = "media/textures/dashboard/speedometer.png"},
	
	tempGauge = {x = 94, y = 89, needleLength = 25, needleX = 67/2, needleY = 29, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/tempgauge.png",
		icon = {offsetX = -26, offsetY = 10,filename = "media/textures/dashboard/tempgaugeicon.png"},},
		
	fuelGauge = {x = 94, y = 44, needleLength = 25, needleX = 67/2, needleY = 29, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/fuelgauge.png",
		icon = {offsetX = -30, offsetY = 10,filename = "media/textures/dashboard/fuelcenter.png"}, 
		iconLeft = {offsetX = -30, offsetY = 10,filename = "media/textures/dashboard/fuelleft.png"},
		iconRight = {offsetX = -30, offsetY = 10,filename = "media/textures/dashboard/fuelright.png"},},

	batteryGauge = {x = 553, y = 39, needleLength = 25, needleX = 67/2, needleY = 29, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/battgauge.png",
		icon = {offsetX = 73, offsetY = 10,filename = "media/textures/dashboard/batticon.png"},},
	
	engineIcon = {x = 344, y = 45, filename = "media/textures/dashboard/checkenginelight.png"},
	oilIcon = {x = 344, y = 78, filename = "media/textures/dashboard/oil_light.png"},

	gearIndicator = {x = 350, y = 99, font = UIFont.Medium},
	
	cruiseControlIndicator = {x = 450, y = 108, font = UIFont.Medium,
		icon = {offsetX = -18, offsetY = 7, filename = "media/textures/dashboard/minidash/speedregulator_small.png"},},
}

dashboard.switches = setupSwitches(700, 100, 35); -- X, Y, Spacing
dashboard.ignition = setupIgnition(617, 92) -- X, Y

Project_Dashboard.addDash(dashboard);




function setupSwitches2(x, y, spacing)

	local switches = { -- Can add new switches here if you want, will call its onClick member. Can override existing switches like that too. 
		radio = 	 {x = x+0*spacing, y = y, icon = "media/textures/dashboard/minidash/speaker_icon.png"},
		heater = 	 {x = x+1*spacing, y = y, icon = "media/textures/dashboard/minidash/heater_icon.png"}, -- Heater was taken. 
		locks = 	 {x = x+2*spacing, y = y, icon = "media/textures/dashboard/minidash/doorlock_icon.png"},
		trunk = 	 {x = x+3*spacing, y = y, icon = "media/textures/dashboard/minidash/trunklock_icon.png"},
		headlights = {x = x+4*spacing, y = y, icon = "media/textures/dashboard/minidash/lights_icon.png"},
	}

	local buttonTextureNames = {"media/textures/dashboard/minidash/button.png","media/textures/dashboard/minidash/button_on.png"}
	for key,switch in pairs(switches) do -- Init common stuff. Its stored per-switch to allow later variation between dashes. 
		switch.buttonTextureNames = buttonTextureNames
		switch.iconOffset = {x = 0, y = 16}
		switch.ledBG = "media/textures/dashboard/null.png"
		switch.ledBGOffset = {x = 0, y = -10}
		switch.led = "media/textures/dashboard/minidash/button_on_light.png"
		switch.ledOffset = {x = 0, y = 12}
	end 
	return switches
end


function setupIgnition2 (x, y)
	local ignition = {
		x = x, y = y, filename = "media/textures/dashboard/minidash/ignitionkeyhole.png",
		emptyIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/minidash/keyhole_empty.png"},
		keyOffIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/minidash/ignition_off.png"},
		keyRunIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/minidash/ignition_on.png"},
		keyStartIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/minidash/ignition_START.png"},
		hotwireOffIcon = {offsetX = 6, offsetY = 7, filename = "media/textures/dashboard/minidash/hotwire_off.png"},
		hotwireOnIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/minidash/hotwire_on.png"},
	}
	return ignition;
end


dashboard = {
	name = "Mini Dash",
	background = "media/textures/dashboard/minidash/compactdashbackground.png",
	
	rpmGauge = {x = 95-20-5, y = 23, needleLength = 37, needleX = 108/2, needleY = 110/2, needleStart = 267, needleEnd = 29, filename = "media/textures/dashboard/minidash/tachometer.png"},
	speedGauge = {x = 205, y = 23, needleLength = 37, needleX = 120/2, needleY = 116/2, needleStart = 267, needleEnd = 29, filename = "media/textures/dashboard/minidash/speedometer.png"},
	
	tempGauge = {x = 347+130, y = 35, needleLength = 18, needleX = 47/2, needleY = 23, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/minidash/temp_gauge.png",
		icon = {offsetX = 8, offsetY = 27,filename = "media/textures/dashboard/minidash/temp_icon.png"},},
		
	fuelGauge = {x = 347+65, y = 35, needleLength = 18, needleX = 47/2, needleY = 23, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/minidash/fuel_gauge.png",
		icon = {offsetX = 6, offsetY = 27,filename = "media/textures/dashboard/minidash/fuel.png"}, 
		iconLeft = {offsetX = 6, offsetY = 27,filename = "media/textures/dashboard/minidash/fuel_left.png"},
		iconRight = {offsetX = 3, offsetY = 27,filename = "media/textures/dashboard/minidash/fuel_right.png"},},

	batteryGauge = {x = 347, y = 35, needleLength = 18, needleX = 47/2, needleY = 23, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/minidash/battery_gauge.png",
		icon = {offsetX = 7, offsetY = 27,filename = "media/textures/dashboard/minidash/battery_icon.png"},},
	
	engineIcon = {x = 205, y = 78+43, filename = "media/textures/dashboard/minidash/check_light.png"},
	oilIcon = {x = 175, y = 78+44, filename = "media/textures/dashboard/minidash/oil_light.png"},

	gearIndicator = {x = 165-3, y = 78+37, font = UIFont.Medium},
	
	cruiseControlIndicator = {x = 250, y = 78+36, font = UIFont.Medium,
		icon = {offsetX = -20, offsetY = 8, filename = "media/textures/dashboard/minidash/speedregulator_small.png"},},
}

dashboard.switches = setupSwitches2(700-270-28-28, 96, 40 ); -- X, Y, Spacing
dashboard.ignition = setupIgnition2(700-120+1, 95+5 ) -- X, Y

Project_Dashboard.addDash(dashboard);




function setupSwitches3(x, y, spacing)

    local switches = { -- Can add new switches here if you want, will call its onClick member. Can override existing switches like that too. 
        radio =      {x = x+0*spacing, y = y, icon = "media/textures/dashboard/megadash/Speaker_icon.png"},
        heater =     {x = x+0*spacing, y = y, icon = "media/textures/dashboard/megadash/Heater_icon.png"}, -- Heater was taken. 
        locks =      {x = x+1*spacing, y = y, icon = "media/textures/dashboard/megadash/Doorlock_icon.png"},
        trunk =      {x = x+2*spacing, y = y, icon = "media/textures/dashboard/megadash/Trunklock_icon.png"},
        headlights = {x = x+3*spacing, y = y, icon = "media/textures/dashboard/megadash/Lights_icon.png"},
    }

    local buttonTextureNames = {"media/textures/dashboard/megadash/SWITCH2off.png","media/textures/dashboard/megadash/SWITCH2on.png"}
    for key,switch in pairs(switches) do -- Init common stuff. Its stored per-switch to allow later variation between dashes. 
        switch.buttonTextureNames = buttonTextureNames
        switch.iconOffset = {x = 0, y = -18}
        switch.ledBG = "media/textures/dashboard/null.png"
        switch.ledBGOffset = {x = 0, y = -10}
        switch.led = "media/textures/dashboard/null.png"
        switch.ledOffset = {x = 0, y = 12}
    end 
    return switches
end

function setupIgnition3 (x, y)
	local ignition = {
		x = x, y = y, filename = "media/textures/dashboard/megadash/Keyhole_empty.png",
		emptyIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/megadash/Keyhole_normal.png"},
		keyOffIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/megadash/Ignition_key_off.png"},
		keyRunIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/megadash/Ignition_key_on.png"},
		keyStartIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/megadash/Ignition_key_START.png"},
		hotwireOffIcon = {offsetX = 6, offsetY = 6, filename = "media/textures/dashboard/megadash/Hotwire_off.png"},
		hotwireOnIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/megadash/Hotwire_on.png"},
	}
	return ignition;
end

dashboard = {
	name = "Mega Dash",
	background = "media/textures/dashboard/megadash/megadashbackground.png",
	
	rpmGauge = {x = 150, y = 17, needleLength = 37, needleX = 120/2, needleY = 116/2, needleStart = 267, needleEnd = 29, filename = "media/textures/dashboard/megadash/tachometer2.png"},
	speedGauge = {x = 313, y = 17, needleLength = 37, needleX = 120/2, needleY = 116/2, needleStart = 267, needleEnd = 29, filename = "media/textures/dashboard/megadash/speedometer2.png"},
	
	tempGauge = {x = 68, y = 77, needleLength = 18, needleX = 60/2, needleY = 30, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/megadash/watergauge2.png",
		icon = {offsetX = 25, offsetY = 33,filename = "media/textures/dashboard/megadash/temp_icon.png"},},
		
	fuelGauge = {x = 68, y = 15, needleLength = 18, needleX = 60/2, needleY = 30, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/megadash/fuelgauge2.png",
		icon = {offsetX = 24, offsetY = 33,filename = "media/textures/dashboard/megadash/fuel.png"}, 
		iconLeft = {offsetX = 24, offsetY = 33,filename = "media/textures/dashboard/megadash/fuel_left.png"},
		iconRight = {offsetX = 24, offsetY = 33,filename = "media/textures/dashboard/megadash/fuel_right.png"},},

	batteryGauge = {x = 453, y = 15, needleLength = 18, needleX = 60/2, needleY = 30, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/megadash/voltmeter2.png",
		icon = {offsetX = 25, offsetY = 33,filename = "media/textures/dashboard/megadash/battery_icon.png"},},
	
	engineIcon = {x = 282, y = 38, filename = "media/textures/dashboard/megadash/check_light2.png"},
	oilIcon = {x = 282, y = 60, filename = "media/textures/dashboard/megadash/oil_light2.png"},

	gearIndicator = {x = 284, y = 71, font = UIFont.Medium},
	
	cruiseControlIndicator = {x = 283, y = 98, font = UIFont.Small,
		icon = {offsetX = 4, offsetY = -1, filename = "media/textures/dashboard/null.png"},},
}


dashboard.switches = setupSwitches3(500+60,103, 50 ); -- X, Y, Spacing
dashboard.switches.heater.x = 50-32.5;
dashboard.switches.heater.y = 33;
dashboard.switches.heater.buttonTextureNames = {"media/textures/dashboard/megadash/switch1off.png","media/textures/dashboard/megadash/switch1on.png"}

dashboard.switches.headlights.x = 50-32.5;
dashboard.switches.headlights.y = 95+5;
dashboard.switches.headlights.buttonTextureNames = {"media/textures/dashboard/megadash/switch1off.png","media/textures/dashboard/megadash/switch1on.png"}

dashboard.ignition = setupIgnition3 (500-30, 98 ) -- X, Y

Project_Dashboard.addDash(dashboard);


function setupSwitches4(x, y, spacing)

	local switches = { -- Can add new switches here if you want, will call its onClick member. Can override existing switches like that too. 
		radio = 	 {x = x+0*spacing, y = y, icon = "media/textures/dashboard/olddash/Speaker_Icon.png"},
		heater = 	 {x = x+1*spacing, y = y, icon = "media/textures/dashboard/olddash/heater_icon.png"}, -- Heater was taken. 
		locks = 	 {x = x+2*spacing, y = y, icon = "media/textures/dashboard/olddash/doorlock_icon.png"},
		trunk = 	 {x = x+3*spacing, y = y, icon = "media/textures/dashboard/olddash/trunklock_icon.png"},
		headlights = {x = x+4*spacing, y = y, icon = "media/textures/dashboard/olddash/lights_icon.png"},
	}

	local buttonTextureNames = {"media/textures/dashboard/olddash/button1off.png","media/textures/dashboard/olddash/button1on.png"}
	for key,switch in pairs(switches) do -- Init common stuff. Its stored per-switch to allow later variation between dashes. 
		switch.buttonTextureNames = buttonTextureNames
		switch.iconOffset = {x = 0, y = -21}
		switch.ledBG = "media/textures/dashboard/null.png"
		switch.ledBGOffset = {x = 0, y = -10}
		switch.led = "media/textures/dashboard/olddash/button1_indicator.png"
		switch.ledOffset = {x = 0, y = 2}
	end 
	return switches
end


function setupIgnition4(x, y)
	local ignition = {
		x = x, y = y, filename = "media/textures/dashboard/olddash/keyhole.png",
		emptyIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/olddash/keyhole_ok.png"},
		keyOffIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/olddash/ignition_key_off.png"},
		keyRunIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/olddash/ignition_key_on.png"},
		keyStartIcon = {offsetX = 3, offsetY = 3, filename = "media/textures/dashboard/olddash/ignition_key_START.png"},
		hotwireOffIcon = {offsetX = 6, offsetY = 8, filename = "media/textures/dashboard/olddash/hotwire_off.png"},
		hotwireOnIcon = {offsetX = 6, offsetY = 6, filename = "media/textures/dashboard/olddash/hotwire_on.png"},
	}
	return ignition;
end

dashboard = {
	name = "olddash",
	background = "media/textures/dashboard/olddash/olddashbackground1.png",
	
	rpmGauge = {x = 390, y = 28, needleLength = 37, needleX = 120/2, needleY = 125/2, needleStart = 267, needleEnd = 29, filename = "media/textures/dashboard/olddash/tachoSQUARE.png"},
	speedGauge = {x = 237.5, y = 28, needleLength = 37, needleX = 126/2, needleY = 125/2, needleStart = 267, needleEnd = 29, filename = "media/textures/dashboard/olddash/spedometerSQUARE.png"},
	
	tempGauge = {x = 127, y = 35, needleLength = 22, needleX = 64/2, needleY = 26, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/olddash/temp_gauge.png",
		icon = {offsetX = -22, offsetY = 10,filename = "media/textures/dashboard/olddash/temp_icon.png"},},
		
	fuelGauge = {x = 127, y = 75, needleLength = 22, needleX = 64/2, needleY = 26, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/olddash/fuel_gauge.png",
		icon = {offsetX = -22, offsetY = 10,filename = "media/textures/dashboard/olddash/fuel_icon.png"}, 
		iconLeft = {offsetX = -25, offsetY = 10,filename = "media/textures/dashboard/olddash/FUELArrowLeft.png"},
		iconRight = {offsetX = -22, offsetY = 10,filename = "media/textures/dashboard/olddash/FUELArrowRight.png"},},

	batteryGauge = {x = 127, y = 110, needleLength = 22, needleX = 64/2, needleY = 26, needleStart = 180, needleEnd = 0, filename = "media/textures/dashboard/olddash/batt_gauge.png",
		icon = {offsetX = -22, offsetY = 10,filename = "media/textures/dashboard/olddash/batt_icon.png"},},
	
	engineIcon = {x = 330, y = 121+6, filename = "media/textures/dashboard/olddash/check_light.png"},
	oilIcon = {x = 250, y = 122+6, filename = "media/textures/dashboard/olddash/oil_light.png"},

	gearIndicator = {x = 445, y = 118, font = UIFont.Medium},
	
	cruiseControlIndicator = {x = 304, y = 118, font = UIFont.Medium,
		icon = {offsetX = -17, offsetY = 7, filename = "media/textures/dashboard/minidash/speedregulator_small.png"},},
}

dashboard.switches = setupSwitches4(580, 105, 35); -- X, Y, Spacing
dashboard.ignition = setupIgnition4(768, 103) -- X, Y

Project_Dashboard.addDash(dashboard);

