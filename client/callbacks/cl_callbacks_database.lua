-- NUI callbacks: Entity database operations (add, remove, update)

RegisterNUICallback('closeDatabase', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('deleteEntity', function(data, cb)
	if not ValidateEntity(data.handle) then
		cb({error = "Invalid entity", database = json.encode(Database)})
		return
	end
	
	RemoveEntity(data.handle)
	cb({
		database = json.encode(Database)
	})
end)

RegisterNUICallback('removeAllFromDatabase', function(data, cb)
	RemoveAllFromDatabase();
	cb({})
end)

RegisterNUICallback('addEntityToDatabase', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	AddEntityToDatabase(data.handle)

	if not KeepSelfInDb and data.handle == PlayerPedId() then
		KeepSelfInDb = true
	end

	cb({})
end)

RegisterNUICallback('addCustomEntityToDatabase', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity", database = json.encode(Database)})
		return
	end
	
	if not Permissions.maxEntities and Permissions.modify.other then
		AddEntityToDatabase(data.handle)

		if not KeepSelfInDb and data.handle == PlayerPedId() then
			KeepSelfInDb = true
		end
	end

	cb{database = json.encode(Database)}
end)

RegisterNUICallback('removeEntityFromDatabase', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if not Permissions.maxEntities and Permissions.modify.other then
		RemoveEntityFromDatabase(data.handle)

		if KeepSelfInDb and data.handle == PlayerPedId() then
			KeepSelfInDb = false
		end
	end
	cb({})
end)

RegisterNUICallback('getDatabase', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	UpdateDatabase()
	cb({
		properties = json.encode(GetEntityProperties(data.handle)),
		database = json.encode(Database)
	})
end)

function UpdateDatabase()
	local entities = {}
	local propsets = {}
	local pickups = {}

	for entity, properties in pairs(Database) do
		if properties.type == 4 then
			table.insert(propsets, entity)
		elseif properties.type == 5 then
			table.insert(pickups, entity)
		else
			table.insert(entities, entity)
		end
	end

	for _, entity in ipairs(entities) do
		if DoesEntityExist(entity) then
			AddEntityToDatabase(entity)
		elseif Database[entity].isSelf then
			RemoveEntityFromDatabase(entity)
		else
			Database[entity].exists = false
		end
	end

	for _, propset in ipairs(propsets) do
		if DoesPropsetExist(propset) then
			AddEntityToDatabase(propset)
		else
			Database[propset].exists = false
		end
	end

	for _, pickup in ipairs(pickups) do
		if DoesPickupExist(pickup) then
			AddEntityToDatabase(pickup)
		else
			Database[pickup].exists = false
		end
	end
end

function CanModifyEntity(entity)
	if EntityIsInDatabase(entity) then
		if NetworkGetEntityIsNetworked(entity) then
			return Permissions.modify.own.networked
		else
			return Permissions.modify.own.nonNetworked
		end
	else
		if NetworkGetEntityIsNetworked(entity) then
			return Permissions.modify.other.networked
		else
			return Permissions.modify.other.nonNetworked
		end
	end
end
