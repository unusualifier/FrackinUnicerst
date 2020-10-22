require '/scripts/fupower.lua'
require '/scripts/util.lua'

function init()
	power.init()
	power.setPower(0)
	power.setMaxEnergy(config.getParameter('isn_batteryCapacity'))
	if config.getParameter('isnStoredPower') then
		power.setStoredEnergy(config.getParameter('isnStoredPower'))
		object.setConfigParameter('isnStoredPower', nil)
	end
end

function update(dt)
	object.setConfigParameter('description', isn_makeBatteryDescription())
	power.update(dt)
	power.setPower(power.getStoredEnergy())
	animator.setAnimationState("meter", power.getStoredEnergy() == 0 and 'd' or tostring(math.floor(math.min(power.getStoredEnergy() / power.getMaxEnergy(),1.0) * 10),10))
end

function die()
	if power.getStoredEnergy() > 0 then
		local charge = power.getStoredEnergy() / power.getMaxEnergy() * 100
		local iConf = root.itemConfig(object.name())
		local newObject = { isnStoredPower = power.getStoredEnergy() }

		if iConf and iConf.config then
			-- set the border colour according to the charge level (red → yellow → green)
			if iConf.config.inventoryIcon then
				local colour

				if charge <	25 then colour = 'FF0000'
				elseif charge <	50 then colour = 'FF8000'
				elseif charge <	75 then colour = 'FFFF00'
				elseif charge < 100 then colour = '80FF00'
				else colour = '00FF00'
				end
				newObject.inventoryIcon = iConf.config.inventoryIcon .. '?border=1;' .. colour .. '?fade=' .. colour .. 'FF;0.1'
			end
			newObject.description = isn_makeBatteryDescription(iConf.config.description or '', charge)
		end

		world.spawnItem(object.name(), entity.position(), 1, newObject)
	else
		world.spawnItem(object.name(), entity.position())
	end
end

function isn_makeBatteryDescription(desc, charge)
	if desc == nil then
		desc = root.itemConfig(object.name())
		desc = desc and desc.config and desc.config.description or ''
	end
	charge = charge or power.getStoredEnergy() / power.getMaxEnergy() * 100

	-- bat flattery
	if charge == 0 then return desc end

	-- round down to multiple of 0.5 (special case if < 0.5)
	if charge < 0.5 then
		charge = '< 0.5'
	else
		charge = math.floor (charge * 2) / 2
	end

	-- append charge state to default description; ensure that it's on a line of its own
	local str=string.split(desc,"^truncate;")
	if str[1] then str=str[1] else str="" end
	str = str .. (desc ~= '' and "\n" or '') .. "Power Stored: ^yellow;"..util.round(power.getStoredEnergy(),1).."^reset;/^green;"..util.round(power.getMaxEnergy(),1).."^reset;J (^yellow;" .. charge .. '^reset;%)'
	return str
end

function string.split(str, pat)
	 local t = {}	-- NOTE: use {n = 0} in Lua-5.0
	 local fpat = "(.-)" .. pat
	 local last_end = 1
	 local s, e, cap = str:find(fpat, 1)
	 while s do
		if s ~= 1 or cap ~= "" then
			 table.insert(t, cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	 end
	 if last_end <= #str then
			cap = str:sub(last_end)
			table.insert(t, cap)
	 end
	 return t
end

function isPower()
	return "battery"
end
function power.onNodeConnectionChange(arg)
	return arg
end
function power.getEnergy(id)
	return storage.energy or 0
end
function power.getMaxEnergy()
	return storage.maxenergy
end
function power.getStorageLeft()
	return (storage.maxenergy or 0) - (storage.storedenergy or 0) - (storage.energy or 0)
end
function power.getStoredEnergy()
	return (storage.storedenergy or 0) + (storage.energy or 0)
end