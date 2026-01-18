-- NUI callbacks: Save, load, import and export database operations

RegisterNUICallback('closeSaveLoadDbMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

function PrepareDatabaseForSave()
	local db = json.decode(json.encode(Database))
	local ped = PlayerPedId()

	for entity, props in pairs(db) do
		if props.attachment.to == ped then
			props.attachment.to = -1
		end
	end

	db[tostring(ped)] = nil

	return {
		spawn = db,
		delete = DeletedEntities
	}
end

function SaveDatabase(name)
	UpdateDatabase()
	SaveDatabaseInKvs(name, PrepareDatabaseForSave())
end

function RemoveDeletedEntity(x, y, z, hash)
	local handle = GetClosestObjectOfType(x, y, z, 1.0, hash, false, false, false)

	if handle ~= 0 then
		DeleteEntity(handle)
	end
end

function LoadDatabase(db, relative, replace, isOffsetPlacement, dataType)
	if replace then
		RemoveAllFromDatabase()
	end

	local ax = 0.0
	local ay = 0.0
	local az = 0.0

	local spawns = {}
	local handles = {}
	local moveableEntities = {}

	-- For backwards compatibility with older DB format
	if not (db.spawn and db.delete) then
		db = {spawn = db, delete = {}}
	end

	if StoreDeleted then
		for _, deleted in pairs(db.delete) do
			RemoveDeletedEntity(deleted.x, deleted.y, deleted.z, deleted.model)
			table.insert(DeletedEntities, deleted)
		end
	end

	local spawnData = (dataType == "script" and db.spawn.spawn) or db.spawn

    for entity, props in pairs(spawnData) do
        local entityProps = props.props or props

        if entityProps.x and entityProps.y and entityProps.z then
            if relative then
                ax = ax + entityProps.x
                ay = ay + entityProps.y
                az = az + entityProps.z
            end

            table.insert(spawns, {entity = tonumber(entity), props = entityProps})
        else
            Logger.warning("[Database] Missing prop positions in entity: " .. tostring(entity))
        end
    end

	local dx, dy, dz

	local rot = GetCamRot(Cam, 2)

	if relative then
		ax = ax / #spawns
		ay = ay / #spawns
		az = az / #spawns

		local pos = GetCamCoord(Cam)
		local spawnPos, entity, distance = GetInView(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z)

		dx = spawnPos.x - ax
		dy = spawnPos.y - ay
		dz = spawnPos.z - az
	end

	local r = math.rad(rot.z)
	local cosr = math.cos(r)
	local sinr = math.sin(r)

	for _, spawn in ipairs(spawns) do
		local entity

		local x, y, z, pitch, roll, yaw

		if relative then
			x = (((spawn.props.x - ax) * cosr - (spawn.props.y - ay) * sinr + ax) + dx) * 1.0
			y = (((spawn.props.y - ay) * cosr + (spawn.props.x - ax) * sinr + ay) + dy) * 1.0
			z = (spawn.props.z + dz) * 1.0
			pitch = spawn.props.pitch * 1.0
			roll = spawn.props.roll * 1.0
			yaw = (spawn.props.yaw + rot.z) * 1.0
		else
			x = spawn.props.x * 1.0
			y = spawn.props.y * 1.0
			z = spawn.props.z * 1.0
			pitch = spawn.props.pitch * 1.0
			roll = spawn.props.roll * 1.0
			yaw = spawn.props.yaw * 1.0
		end

		spawn.props.x = x
		spawn.props.y = y
		spawn.props.z = z
		spawn.props.pitch = pitch
		spawn.props.roll = roll
		spawn.props.yaw = yaw

		if spawn.props.type == 1 then
			entity = SpawnPed(spawn.props)
		elseif spawn.props.type == 2 then
			entity = SpawnVehicle(spawn.props.name, spawn.props.model, x, y, z, pitch, roll, yaw, spawn.props.collisionDisabled, spawn.props.isVisible)
		elseif spawn.props.type == 5 then
			entity = SpawnPickup(spawn.props.name, spawn.props.model, x, y, z)
		else
			entity = SpawnObject(spawn.props.name, spawn.props.model, x, y, z, pitch, roll, yaw, spawn.props.collisionDisabled, spawn.props.isVisible, spawn.props.lightsIntensity, spawn.props.lightsColour, spawn.props.lightsType)
		end

		if entity and relative then
			PlaceOnGroundProperly(entity)
		end

		handles[spawn.entity] = entity

		moveableEntities[#moveableEntities+1] = entity
	end

	for _, spawn in ipairs(spawns) do
		if spawn.props.quaternion then
			local x = spawn.props.quaternion.x
			local y = spawn.props.quaternion.y
			local z = spawn.props.quaternion.z
			local w
			if spawn.props.quaternion.w ~= nil then w = spawn.props.quaternion.w  SetEntityQuaternion(handles[spawn.entity], x, y, z, -w) else w = nil end

			
		end

		if spawn.props.attachment and spawn.props.attachment.to ~= 0 then
			local from  = handles[spawn.entity]
			local to    = spawn.props.attachment.to == -1 and PlayerPedId() or handles[spawn.props.attachment.to]
			local bone  = spawn.props.attachment.bone
			local x     = spawn.props.attachment.x + 0.0
			local y     = spawn.props.attachment.y + 0.0
			local z     = spawn.props.attachment.z + 0.0
			local pitch = spawn.props.attachment.pitch + 0.0
			local roll  = spawn.props.attachment.roll + 0.0
			local yaw   = spawn.props.attachment.yaw + 0.0
			local useSoftPinning = spawn.props.attachment.useSoftPinning
			local collision = spawn.props.attachment.collision
			local vertex = spawn.props.attachment.vertex or 0
			local fixedRot = spawn.props.attachment.fixedRot

			if type(bone) == 'number' then
				bone = FindBoneName(to, bone)
			end

			if useSoftPinning == nil then
				useSoftPinning = true
			end

			if collision == nil then
				collision = true
			end

			if fixedRot == nil then
				fixedRot = true
			end

			AttachEntity(from, to, bone, x, y, z, pitch, roll, yaw, useSoftPinning, collision, vertex, fixedRot)

			AddEntityToDatabase(from, nil, {
				to = to,
				bone = bone,
				x = x,
				y = y,
				z = z,
				pitch = pitch,
				roll = roll,
				yaw = yaw,
				useSoftPinning = useSoftPinning,
				collision = collision,
				vertex = vertex,
				fixedRot = fixedRot
			})
		end
	end

	if isOffsetPlacement then
		CreateObjects(moveableEntities,1,100.0)
	end

end

function LoadSavedDatabase(name, relative, replace)
	local db = LoadDatabaseFromKvs(name)

	if db then
		LoadDatabase(db, relative, replace)
	end
end

function GetSavedDatabases()
	local dbs = {}

	local handle = StartFindKvp('DB_')

	while true do
		local kvp = FindKvp(handle)
		if kvp then
			table.insert(dbs, string.sub(kvp, 4))
		else
			break
		end
	end

	EndFindKvp(handle)

	table.sort(dbs)

	return dbs
end

function DeleteDatabase(name)
	DeleteResourceKvp('DB_' .. name)
end

RegisterNUICallback('saveDb', function(data, cb)
	if not data.name or data.name == "" then
		Logger.error('Database name cannot be empty')
		cb({error = "Invalid name"})
		return
	end
	
	local success = pcall(function()
		SaveDatabase(data.name)
	end)
	
	if success then
		Logger.debug("Database '" .. data.name .. "' saved")
		cb(json.encode(GetSavedDatabases()))
	else
		Logger.error('Failed to save database')
		cb({error = "Save failed"})
	end
end)

RegisterNUICallback('loadDb', function(data, cb)
	if not data.name or data.name == "" then
		Logger.error('Database name cannot be empty')
		cb({error = "Invalid name"})
		return
	end
	
	local success = pcall(function()
		LoadSavedDatabase(data.name, data.relative, data.replace)
	end)
	
	if success then
		Logger.debug("Database '" .. data.name .. "' loaded")
		cb({})
	else
		Logger.error('Failed to load database')
		cb({error = "Load failed"})
	end
end)

RegisterNUICallback('deleteDb', function(data, cb)
	if not data.name or data.name == "" then
		Logger.error('Database name cannot be empty')
		cb({error = "Invalid name"})
		return
	end
	
	local success = pcall(function()
		DeleteDatabase(data.name)
	end)
	
	if success then
		Logger.debug("Database '" .. data.name .. "' deleted")
		cb({})
	else
		Logger.error('Failed to delete database')
		cb({error = "Delete failed"})
	end
end)

RegisterNUICallback('importDb', function(data, cb)
	Logger.debug('[Import] Format: ' .. data.format)
	ImportDatabase(data.format, data.content)
	cb({})
end)

RegisterNUICallback('exportDb', function(data, cb)
	cb(ExportDatabase(data.format, data.content))
end)

RegisterNUICallback('closeImportExportDbWindow', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('setStoreDeleted', function(data, cb)
	if StoreDeleted then
		StoreDeleted = false
		DeletedEntities = {}
	else
		StoreDeleted = true
	end

	cb({})
end)
