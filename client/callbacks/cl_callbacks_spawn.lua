-- NUI callbacks: Spawn menus (peds, vehicles, objects, propsets, pickups) and favourites

RegisterNUICallback('closeSpawnMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closePedMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or PedsHashLookup[joaat(data.modelName)]) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 1
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closeVehicleMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or VehiclesHashLookup[joaat(data.modelName)]) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 2
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closeObjectMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or ObjectsHashLookup[joaat(data.modelName)]) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 3
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closeSpooniMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or SpooniHashLookup[joaat(data.modelName)]) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 3
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closePropsetMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or PropsetsHashLookup[joaat(data.modelName)]) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 4
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closePickupMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or PickupsHashLookup[joaat(data.modelName)]) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 5
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

function GetFavourites()
	local content = GetResourceKvpString('favourites')

	if content then
		return json.decode(content)
	end
end

RegisterNUICallback('saveFavourites', function(data, cb)
	SetResourceKvp('favourites', json.encode(data.favourites))
	cb({})
end)
