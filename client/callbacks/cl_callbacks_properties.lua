-- NUI callbacks: Entity properties (position, rotation, physics, attachments, ped/vehicle specific)

RegisterNUICallback('closePropertiesMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

function OpenPropertiesMenuForEntity(entity)
	if not CanModifyEntity(entity) then
		SetNuiFocus(false, false)
		return
	end

	SendNUIMessage({
		type = 'openPropertiesMenu',
		entity = entity
	})
	SetNuiFocus(true, true)
end

RegisterNUICallback('openPropertiesMenuForEntity', function(data, cb)
	OpenPropertiesMenuForEntity(data.entity)
	cb({})
end)

RegisterNUICallback('updatePropertiesMenu', function(data, cb)
	cb({
		entity = data.handle,
		properties = json.encode(GetEntityProperties(data.handle)),
		inDb = EntityIsInDatabase(data.handle),
		hasNetworkControl = NetworkHasControlOfEntity(data.handle)
	})
end)

RegisterNUICallback('requestControl', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if CanModifyEntity(data.handle) then
		RequestControl(data.handle)
	else
		Logger.error('No permission to control entity')
	end
	cb({})
end)

RegisterNUICallback('selectEntity', function(data, cb)
	if CanModifyEntity(data.handle) then
		if AttachedEntity == data.handle then
			AttachedEntity = nil
		else
			if not Cam then
				EnableSpoonerMode()
			end

			AttachedEntity = data.handle
		end
	end
	cb({})
end)

-- Freeze/Unfreeze
RegisterNUICallback('freezeEntity', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.freeze and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		FreezeEntityPosition(data.handle, true)
	else
		Logger.error('No permission to freeze entity')
	end
	cb({})
end)

RegisterNUICallback('unfreezeEntity', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.freeze and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		FreezeEntityPosition(data.handle, false)
	else
		Logger.error('No permission to unfreeze entity')
	end
	cb({})
end)

-- Position and Rotation
RegisterNUICallback('setEntityRotation', function(data, cb)
	if not ValidateEntity(data.handle) then
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.rotation and CanModifyEntity(data.handle) then
		-- local pitch = ValidateNumber(data.pitch, -360, 360, 0)
		-- local roll = ValidateNumber(data.roll, -360, 360, 0)
		-- local yaw = ValidateNumber(data.yaw, -360, 360, 0)

		RequestControl(data.handle)
		-- SetEntityRotation(data.handle, pitch, roll, yaw, 2, true)
		SetEntityRotation(data.handle, data.pitch * 1.0, data.roll * 1.0, data.yaw * 1.0, 2, true)
	end

	cb({})
end)

RegisterNUICallback('setEntityCoords', function(data, cb)
	if not ValidateEntity(data.handle) then
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.position and CanModifyEntity(data.handle) then
		local x = ValidateNumber(data.x, -10000, 10000, 0)
		local y = ValidateNumber(data.y, -10000, 10000, 0)
		local z = ValidateNumber(data.z, -1000, 10000, 0)

		RequestControl(data.handle)
		SetEntityCoordsNoOffset(data.handle, x, y, z)
	end

	cb({})
end)

RegisterNUICallback('resetRotation', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.rotation and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityRotation(data.handle, 0.0, 0.0, 0.0, 2)
	else
		Logger.error('No permission to reset rotation')
	end
	cb({})
end)

function PlacePedOnGroundProperly(ped)
	local x, y, z = table.unpack(GetEntityCoords(ped))
	local found, groundz, normal = GetGroundZAndNormalFor_3dCoord(x, y, z)
	if found then
		SetEntityCoordsNoOffset(ped, x, y, groundz + normal.z, true)
	end
end

RegisterNUICallback('placeEntityHere', function(data, cb)
	if Permissions.properties.position and CanModifyEntity(data.handle) then
		local x, y, z = table.unpack(GetCamCoord(Cam))
		local pitch, roll, yaw = table.unpack(GetCamRot(Cam, 2))

		local spawnPos, entity, distance = GetInView(x, y, z, pitch, roll, yaw)

		RequestControl(data.handle)
		SetEntityCoordsNoOffset(data.handle, spawnPos.x, spawnPos.y, spawnPos.z)
		PlaceOnGroundProperly(data.handle)

		x, y, z = table.unpack(GetEntityCoords(data.handle))
		pitch, roll, yaw = table.unpack(GetEntityRotation(data.handle, 2))

		cb({
			x = x,
			y = y,
			z = z,
			pitch = pitch,
			roll = roll,
			yaw = yaw
		})
	else
		cb({})
	end
end)

RegisterNUICallback('goToEntity', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.goTo then
		DisableSpoonerMode()
		local x, y, z = table.unpack(GetEntityCoords(data.handle))
		TeleportToCoords(x, y, z, 0.0)
	else
		Logger.error('No permission to teleport')
	end
	cb({})
end)

-- Invincibility
RegisterNUICallback('invincibleOn', function(data, cb)
	if Permissions.properties.invincible and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityInvincible(data.handle, true)
	end
	cb({})
end)

RegisterNUICallback('invincibleOff', function(data, cb)
	if Permissions.properties.invincible and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityInvincible(data.handle, false)
	end
	cb({})
end)

-- Visibility
RegisterNUICallback('setEntityVisible', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.visible and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityVisible(data.handle, true)
	else
		Logger.error('No permission to change visibility')
	end
	cb({})
end)

RegisterNUICallback('setEntityInvisible', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.visible and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityVisible(data.handle, false)
	else
		Logger.error('No permission to change visibility')
	end
	cb({})
end)

-- Gravity
RegisterNUICallback('gravityOn', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.gravity and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityHasGravity(data.handle, true)
	else
		Logger.error('No permission to change gravity')
	end
	cb({})
end)

RegisterNUICallback('gravityOff', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.gravity and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityHasGravity(data.handle, false)
	else
		Logger.error('No permission to change gravity')
	end
	cb({})
end)

-- Collision
RegisterNUICallback('collisionOn', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.collision and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityCollision(data.handle, true, true)
	else
		Logger.error('No permission to change collision')
	end
	cb({})
end)

RegisterNUICallback('collisionOff', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.collision and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityCollision(data.handle, false, false)
	else
		Logger.error('No permission to change collision')
	end
	cb({})
end)

-- Health
RegisterNUICallback('setEntityHealth', function(data, cb)
	if not ValidateEntity(data.handle) then
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.health and CanModifyEntity(data.handle) then
		local health = ValidateNumber(data.health, 0, 10000, 100)
		RequestControl(data.handle)
		SetEntityHealth(data.handle, health, 0)
	end
	cb({})
end)

-- Clone
RegisterNUICallback('cloneEntity', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.clone and CanModifyEntity(data.handle) then
		local clone = CloneEntity(data.handle)

		if clone then
			Logger.success('Entity cloned')
			Logger.debug("[Clone] Original: " .. data.handle .. ", Clone: " .. clone)
			OpenPropertiesMenuForEntity(clone)
		else
			Logger.error('Failed to clone entity')
		end
	else
		Logger.error('No permission to clone entity')
	end

	cb({})
end)

-- Attachments
RegisterNUICallback('attachTo', function(data, cb)
	if not ValidateEntity(data.from) then
		Logger.error('Invalid entity to attach')
		cb({error = "Invalid entity"})
		return
	end
	
	if not Permissions.properties.attachments then
		Logger.error('No permission to attach entities')
		cb({error = "No permission"})
		return
	end
	
	if not CanModifyEntity(data.from) then
		Logger.error('Cannot modify this entity')
		cb({error = "Cannot modify"})
		return
	end
	
	local from = data.from
	local to = data.to
	local bone = data.bone
	local useSoftPinning = data.useSoftPinning
	local collision = data.collision
	local vertex = data.vertex
	local fixedRot = data.fixedRot

	if not to then
		local props = GetEntityProperties(from)

		if props.attachment.to ~= 0 then
			to = props.attachment.to
		else
			Logger.error('No attachment target')
			cb({error = "No target"})
			return
		end
	end
	
	if not ValidateEntity(to) then
		Logger.error('Invalid attachment target')
		cb({error = "Invalid target"})
		return
	end

	local x, y, z, pitch, roll, yaw

	if data.keepPos then
		local x1, y1, z1 = table.unpack(GetEntityCoords(from))
		x, y, z = table.unpack(GetOffsetFromEntityGivenWorldCoords(to, x1, y1, z1))
		pitch, roll, yaw = table.unpack(GetEntityRotation(from, 2) - GetEntityRotation(to, 2))
	else
		-- x = ValidateNumber(data.x, -1000, 1000, 0.0)
		-- y = ValidateNumber(data.y, -1000, 1000, 0.0)
		-- z = ValidateNumber(data.z, -1000, 1000, 0.0)
		-- pitch = ValidateNumber(data.pitch, -360, 360, 0.0)
		-- roll = ValidateNumber(data.roll, -360, 360, 0.0)
		-- yaw = ValidateNumber(data.yaw, -360, 360, 0.0)
		x = data.x * 1.0
		y = data.y * 1.0
		z = data.z * 1.0
		pitch = data.pitch * 1.0
		roll = data.roll * 1.0
		yaw = data.yaw * 1.0
	end

	if type(bone) == 'number' then
		bone = FindBoneName(to, bone)
	end

	RequestControl(from)
	AttachEntity(from, to, bone, x, y, z, pitch, roll, yaw, useSoftPinning, collision, vertex, fixedRot)
	Logger.success('Entity attached')

	cb({})
end)

function TryDetach(handle)
	if Permissions.properties.attachments and CanModifyEntity(handle) then
		RequestControl(handle)
		DetachEntity(handle, false, true)

		if EntityIsInDatabase(handle) then
			AddEntityToDatabase(handle, nil, {
				to = 0,
				x = 0.0,
				y = 0.0,
				z = 0.0,
				pitch = 0.0,
				roll = 0.0,
				yaw = 0.0
			})
		end
	end
end

RegisterNUICallback('detach', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid entity')
		cb({error = "Invalid entity"})
		return
	end
	
	TryDetach(data.handle)
	cb({})
end)

-- Lights
RegisterNUICallback('setLightsIntensity', function(data, cb)
	if Permissions.properties.lights and CanModifyEntity(data.handle) then
		local intensity = data.intensity and data.intensity * 1.0 or 0.0

		RequestControl(data.handle)
		SetLightsIntensityForEntity(data.handle, intensity)

		if EntityIsInDatabase(data.handle) then
			Database[data.handle].lightsIntensity = intensity
		end
	end

	cb({})
end)

RegisterNUICallback('setLightsColour', function(data, cb)
	if Permissions.properties.lights and CanModifyEntity(data.handle) then
		local red = data.red and data.red or 0
		local green = data.green and data.green or 0
		local blue = data.blue and data.blue or 0

		RequestControl(data.handle)
		SetLightsColorForEntity(data.handle, red, green, blue)

		if EntityIsInDatabase(data.handle) then
			Database[data.handle].lightsColour = {
				red = red,
				green = green,
				blue = blue
			}
		end
	end

	cb({})
end)

RegisterNUICallback('setLightsType', function(data, cb)
	if Permissions.properties.lights and CanModifyEntity(data.handle) then
		local type = data.type and data.type or 0

		RequestControl(data.handle)
		SetLightsTypeForEntity(data.handle, type)

		if EntityIsInDatabase(data.handle) then
			Database[data.handle].lightsType = type
		end
	end

	cb({})
end)

-- Focus
function FocusEntity(entity)
	FocusTarget = entity
	FocusTargetPos = GetEntityCoords(entity)

	if not FreeFocus then
		StopCamPointing(Cam)
		PointCamAtEntity(Cam, entity)
	end
end

function UnfocusEntity()
	FocusTarget = nil
	StopCamPointing(Cam)
end

function TryFocusEntity(handle)
	if Permissions.properties.focus then
		if not Cam then
			EnableSpoonerMode()
		end

		FocusEntity(handle)
	end
end

RegisterNUICallback('focusEntity', function(data, cb)
	if FocusTarget == data.handle then
		UnfocusEntity()
	else
		TryFocusEntity(data.handle)
	end

	cb({})
end)

-- Network
RegisterNUICallback('registerAsNetworked', function(data, cb)
	if Permissions.properties.registerAsNetworked and CanModifyEntity(data.handle) then
		Logger.debug("[Network] Manual registration for entity " .. data.handle)
		NetworkRegisterEntityAsNetworked(data.handle)
		if NetworkGetEntityIsNetworked(data.handle) then
			Logger.success('Entity registered as networked')
			Logger.debug("[Network] Entity " .. data.handle .. " registered successfully")
		else
			Logger.error('Network registration failed')
			Logger.debug("[Network] Entity " .. data.handle .. " registration failed")
		end
	end

	cb({})
end)

-- ==================== PED SPECIFIC ====================

RegisterNUICallback('performScenario', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid ped')
		cb({error = "Invalid entity"})
		return
	end
	
	if not data.scenario or type(data.scenario) ~= 'string' then
		Logger.error('Invalid scenario')
		cb({error = "Invalid scenario"})
		return
	end
	
	if Permissions.properties.ped.scenario and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		StartScenario(data.handle, data.scenario)

		local entry = GetDatabaseEntry(data.handle)
		if entry then
			Database[data.handle].animation = nil
			Database[data.handle].scenario = data.scenario
			MarkEntityAsActive(data.handle, 'scenario')
			UnmarkEntityAsActive(data.handle, 'animation')
		end
	else
		Logger.error('No permission to perform scenarios')
	end

	cb({})
end)

function TryClearTasks(handle)
	if Permissions.properties.ped.clearTasks and CanModifyEntity(handle) then
		RequestControl(handle)
		ClearPedTasks(handle)

		local entry = GetDatabaseEntry(handle)
		if entry then
			Database[handle].scenario = nil
			Database[handle].animation = nil
			UnmarkEntityAsActive(handle, 'scenario')
			UnmarkEntityAsActive(handle, 'animation')
		end
	end
end

RegisterNUICallback('clearPedTasks', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid ped')
		cb({error = "Invalid entity"})
		return
	end
	
	TryClearTasks(data.handle)
	cb({})
end)

RegisterNUICallback('clearPedTasksImmediately', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid ped')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.ped.clearTasks and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		ClearPedTasksImmediately(data.handle)

		local entry = GetDatabaseEntry(data.handle)
		if entry then
			Database[data.handle].scenario = nil
			Database[data.handle].animation = nil
			UnmarkEntityAsActive(data.handle, 'scenario')
			UnmarkEntityAsActive(data.handle, 'animation')
		end
	else
		Logger.error('No permission to clear ped tasks')
	end

	cb({})
end)

RegisterNUICallback('setOutfit', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid ped')
		cb({error = "Invalid entity"})
		return
	end
	
	local outfit = ValidateNumber(data.outfit, 0, 100, 0)
	
	if Permissions.properties.ped.outfit and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetPedOutfitPreset(data.handle, outfit)

		if EntityIsInDatabase(data.handle) then
			Database[data.handle].outfit = outfit
		end
	else
		Logger.error('No permission to change outfits')
	end

	cb({})
end)

function AddToGroup(ped)
	local group = GetPlayerGroup(PlayerId())
	SetPedAsGroupMember(ped, group)
	SetGroupSeparationRange(group, -1)
	SetPedCanTeleportToGroupLeader(ped, group, true)
	BlipAddForEntity(Config.Entity.GroupMemberBlipSprite, ped)
end

RegisterNUICallback('addToGroup', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid ped')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.ped.group and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		AddToGroup(data.handle)
	else
		Logger.error('No permission to modify groups')
	end
	cb({})
end)

RegisterNUICallback('removeFromGroup', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid ped')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.ped.group and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		RemovePedFromGroup(data.handle)
		RemoveBlip(GetBlipFromEntity(data.handle))
	else
		Logger.error('No permission to modify groups')
	end
	cb({})
end)

RegisterNUICallback('giveWeapon', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid ped')
		cb({error = "Invalid entity"})
		return
	end
	
	if not data.weapon or type(data.weapon) ~= 'string' then
		Logger.error('Invalid weapon')
		cb({error = "Invalid weapon"})
		return
	end
	
	if Permissions.properties.ped.weapon and CanModifyEntity(data.handle) then
		RequestControl(data.handle)

		GiveWeaponToPed_2(data.handle, joaat(data.weapon), 500, true, false, 0, false, 0.5, 1.0, 0, false, 0.0, false)

		local entry = GetDatabaseEntry(data.handle)
		if entry then
			table.insert(Database[data.handle].weapons, data.weapon)
		end
		Logger.success('Weapon given')
	else
		Logger.error('No permission to give weapons')
	end
	cb({})
end)

RegisterNUICallback('removeAllWeapons', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid ped')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.ped.weapon and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		RemoveAllPedWeapons(data.handle, true, true)

		local entry = GetDatabaseEntry(data.handle)
		if entry then
			Database[data.handle].weapons = {}
		end
		Logger.success('Weapons removed')
	else
		Logger.error('No permission to remove weapons')
	end
	cb({})
end)

RegisterNUICallback('resurrectPed', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid ped')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.ped.resurrect and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		ResurrectPed(data.handle)
		Logger.success('Ped resurrected')
	else
		Logger.error('No permission to resurrect peds')
	end
	cb({})
end)

RegisterNUICallback('setOnMount', function(data, cb)
	if not ValidateEntity(data.handle) or not ValidateEntity(data.entity) then
		Logger.error('Invalid ped or mount')
		cb({error = "Invalid entity"})
		return
	end
	
	if Permissions.properties.ped.mount and CanModifyEntity(data.handle) then
		SetPedOnMount(data.handle, data.entity, -1, false)
		Logger.success('Ped mounted')
	else
		Logger.error('No permission to mount peds')
	end
	cb({})
end)

RegisterNUICallback('attackPed', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid attacker ped')
		cb({error = "Invalid entity"})
		return
	end
	
	if not ValidateEntity(data.ped) then
		Logger.error('Invalid target ped')
		cb({error = "Invalid target"})
		return
	end
	
	if Permissions.properties.ped.attack and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		TaskCombatPed(data.handle, data.ped)
	else
		Logger.error('No permission to command ped attacks')
	end
	cb {}
end)

RegisterNUICallback('aiOn', function(data, cb)
	if Permissions.properties.ped.ai and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetBlockingOfNonTemporaryEvents(data.handle, false)

		local entry = GetDatabaseEntry(data.handle)
		if entry then
			Database[data.handle].blockNonTemporaryEvents = false
		end
	end

	cb({})
end)

RegisterNUICallback('aiOff', function(data, cb)
	if Permissions.properties.ped.ai and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetBlockingOfNonTemporaryEvents(data.handle, true)

		local entry = GetDatabaseEntry(data.handle)
		if entry then
			Database[data.handle].blockNonTemporaryEvents = true
		end
	end

	cb({})
end)

RegisterNUICallback('setPlayerModel', function(data, cb)
	if Permissions.properties.ped.changeModel and data.modelName then
		local model = joaat(data.modelName)

		if LoadModel(model) then
			SetPlayerModel(PlayerId(), model, true)
		end
	end
	cb({
		handle = PlayerPedId()
	})
end)

RegisterNUICallback('playAnimation', function(data, cb)
	if Permissions.properties.ped.animation and CanModifyEntity(data.handle) then
		local blendInSpeed = data.blendInSpeed and data.blendInSpeed * 1.0 or 1.0
		local blendOutSpeed = data.blendOutSpeed and data.blendOutSpeed * 1.0 or 1.0
		local duration = data.duration and data.duraction or -1
		local flag = data.flag and data.flag or 1
		local playbackRate = data.playbackRate and data.playbackRate * 1.0 or 0.0

		RequestControl(data.handle)

		local animation = {
			dict = data.dict,
			name = data.name,
			blendInSpeed = blendInSpeed,
			blendOutSpeed = blendOutSpeed,
			duration = duration,
			flag = flag,
			playbackRate = playbackRate
		}

		if PlayAnimation(data.handle, animation) then
			local entry = GetDatabaseEntry(data.handle)
			if entry then
				Database[data.handle].animation = animation
				Database[data.handle].scenario = nil
				MarkEntityAsActive(data.handle, 'animation')
				UnmarkEntityAsActive(data.handle, 'scenario')
			end
		end
	end

	cb({})
end)

RegisterNUICallback('knockOffProps', function(data, cb)
	if Permissions.properties.ped.knockOffProps and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		KnockOffPedProp(data.handle, true, true, true, true)
	end

	cb({})
end)

RegisterNUICallback('setWalkStyle', function(data, cb)
	if Permissions.properties.ped.walkStyle and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetWalkStyle(data.handle, data.base, data.style)
	end

	cb({})
end)

RegisterNUICallback('clonePedToTarget', function(data, cb)
	if Permissions.properties.ped.cloneToTarget and CanModifyEntity(data.target) then
		RequestControl(data.target)
		ClonePedToTarget(data.handle, data.target)
	end

	cb({})
end)

function TryClonePed(handle)
	if Permissions.properties.ped.clone and CanModifyEntity(handle) then
		RequestControl(handle)
		local clone = CloneEntity(handle)
		Wait(500)
		ClonePedToTarget(handle, clone)
	end
end

RegisterNUICallback('clonePed', function(data, cb)
	TryClonePed(data.handle)
	cb({})
end)

RegisterNUICallback('lookAtEntity', function(data, cb)
	if Permissions.properties.ped.lookAtEntity and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		TaskLookAtEntity(data.handle, data.target, -1)
	end

	cb({})
end)

RegisterNUICallback('clearLookAt', function(data, cb)
	if Permissions.properties.ped.lookAtEntity and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		TaskClearLookAt(data.handle)
	end

	cb({})
end)

function GetPedConfigFlagsWithDescr(ped)
	local flags = GetPedConfigFlags(ped)

	local flagsWithDescr = {}

	for flag, value in pairs(flags) do
		local descr = PedConfigFlags[flag]

		if descr then
			flagsWithDescr[tostring(flag)] = {descr = descr, value = value}
		elseif value then
			flagsWithDescr[tostring(flag)] = {descr = "", value = true}
		end
	end

	return flagsWithDescr
end

RegisterNUICallback('getPedConfigFlags', function(data, cb)
	cb(GetPedConfigFlagsWithDescr(data.handle))
end)

function TrySetPedConfigFlag(handle, flag, value)
	if Permissions.properties.ped.configFlags and CanModifyEntity(handle) then
		RequestControl(handle)
		SetPedConfigFlag(handle, flag, value)
	end
end

RegisterNUICallback('setPedConfigFlag', function(data, cb)
	TrySetPedConfigFlag(data.handle, data.flag, data.value)
	cb(GetPedConfigFlagsWithDescr(data.handle))
end)

function TryGoToWaypoint(handle)
	if Permissions.properties.ped.goToWaypoint and CanModifyEntity(handle) then
		RequestControl(handle)

		local coords = GetWaypointCoords()
		local groundZ = GetHeightmapBottomZForPosition(coords.x, coords.y)

		local vehicle = GetVehiclePedIsIn(handle, false)

		if vehicle == 0 then
			TaskGoToCoordAnyMeans(handle, coords.x, coords.y, groundZ, 1.0, 0, 0, 0, 0.5)
		else
			TaskVehicleDriveToCoord(handle, vehicle, coords.x, coords.y, groundZ, 2.0, 0, GetEntityModel(vehicle), 67108864, 0.5, 0.0)
		end
	end
end

RegisterNUICallback('goToWaypoint', function(data, cb)
	TryGoToWaypoint(data.handle)
	cb({})
end)

function TryPedGoToEntity(handle, entity)
	if Permissions.properties.ped.goToEntity and CanModifyEntity(handle) then
		RequestControl(handle)

		local vehicle = GetVehiclePedIsIn(handle, false)

		if vehicle == 0 then
			TaskGoToEntity(handle, entity, -1, 1.0, 1.0, 0.0, 0)
		else
			TaskVehicleDriveToCoord(handle, vehicle, GetEntityCoords(entity), 2.0, 0, GetEntityModel(vehicle), 67108864, 0.5, 0.0)
		end
	end
end

RegisterNUICallback('pedGoToEntity', function(data, cb)
	TryPedGoToEntity(data.handle, data.entity)
	cb({})
end)

RegisterNUICallback('cleanPed', function(data, cb)
	if Permissions.properties.ped.clean and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		ClearPedEnvDirt(data.handle)
		ClearPedDamageDecalByZone(data.handle, 10, "ALL")
		ClearPedBloodDamage(data.handle)
	end
	cb({})
end)

RegisterNUICallback('setScale', function(data, cb)
	if Permissions.properties.ped.scale and CanModifyEntity(data.handle) then
		local scale = data.scale or 1.0

		if scale < 0.1 then
			scale = 0.1
		elseif scale > 10.0 then
			scale = 10.0
		end

		RequestControl(data.handle)
		SetPedScale(data.handle, scale + 0.0)

		local entry = GetDatabaseEntry(data.handle)
		if entry then
			Database[data.handle].scale = scale
		end
	end

	cb({})
end)

-- ==================== VEHICLE SPECIFIC ====================

RegisterNUICallback('getIntoVehicle', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid vehicle')
		cb({error = "Invalid entity"})
		return
	end
	
	if not IsEntityAVehicle(data.handle) then
		Logger.error('Entity is not a vehicle')
		cb({error = "Not a vehicle"})
		return
	end
	
	if Permissions.properties.vehicle.getin then
		DisableSpoonerMode()
		RequestControl(data.handle)
		TaskWarpPedIntoVehicle(PlayerPedId(), data.handle, -1)
	else
		Logger.error('No permission to enter vehicles')
	end
	cb({})
end)

RegisterNUICallback('repairVehicle', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid vehicle')
		cb({error = "Invalid entity"})
		return
	end
	
	if not IsEntityAVehicle(data.handle) then
		Logger.error('Entity is not a vehicle')
		cb({error = "Not a vehicle"})
		return
	end
	
	if Permissions.properties.vehicle.repair and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleFixed(data.handle)
		Logger.success('Vehicle repaired')
	else
		Logger.error('No permission to repair vehicles')
	end
	cb({})
end)

RegisterNUICallback('engineOn', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid vehicle')
		cb({error = "Invalid entity"})
		return
	end
	
	if not IsEntityAVehicle(data.handle) then
		Logger.error('Entity is not a vehicle')
		cb({error = "Not a vehicle"})
		return
	end
	
	if Permissions.properties.vehicle.engine and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleEngineOn(data.handle, true, true)
	else
		Logger.error('No permission to control engine')
	end
	cb({})
end)

RegisterNUICallback('engineOff', function(data, cb)
	if not ValidateEntity(data.handle) then
		Logger.error('Invalid vehicle')
		cb({error = "Invalid entity"})
		return
	end
	
	if not IsEntityAVehicle(data.handle) then
		Logger.error('Entity is not a vehicle')
		cb({error = "Not a vehicle"})
		return
	end
	
	if Permissions.properties.vehicle.engine and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleEngineOn(data.handle, false, true)
	else
		Logger.error('No permission to control engine')
	end
	cb({})
end)

RegisterNUICallback('setVehicleLightsOn', function(data, cb)
	if Permissions.properties.vehicle.lights and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleLights(data.handle, false)
	end
	cb({})
end)

RegisterNUICallback('setVehicleLightsOff', function(data, cb)
	if Permissions.properties.vehicle.lights and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleLights(data.handle, true)
	end
	cb({})
end)

function TryEnterVehicle(handle, entity)
	if Permissions.properties.ped.enterVehicle and CanModifyEntity(handle) then
		if IsVehicleSeatFree(entity, -1) then
			TaskWarpPedIntoVehicle(handle, entity, -1)
		else
			TaskWarpPedIntoVehicle(handle, entity, -2)
		end
	end
end

RegisterNUICallback('enterVehicle', function(data, cb)
	TryEnterVehicle(data.handle, data.entity)
	cb({})
end)
