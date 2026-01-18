-- Main: Core Spooner functionality - state management, events, threads

Database = {}

Cam = nil
Speed = Config.Movement.Speed
AdjustSpeed = Config.Adjustment.Speed
RotateSpeed = Config.Adjustment.RotateSpeed
AttachedEntity = nil
RotateMode = 2
AdjustMode = 4
SpeedMode = 0
PlaceOnGround = false
CurrentSpawn = nil
ShowControls = true
KeepSelfInDb = true
FocusTarget = nil
FocusTargetPos = nil
FreeFocus = false
MessageRate = 70
MessageInterval = true
ShowEntityHandles = false

local SpoonerPrompts, ClearTasksPrompt, DetachPrompt
local PlacementPrompts, RotateLeftPrompt, RotateRightPrompt, UpPrompt, DownPrompt, LeftPrompt, RightPrompt, PlacePrompt, CancelPrompt

SpoonerPrompts = UipromptGroup:new("Spooner", false)

ClearTasksPrompt = Uiprompt:new(`INPUT_INTERACT_NEG`, "Clear Tasks", SpoonerPrompts)
ClearTasksPrompt:setHoldMode(true)
ClearTasksPrompt:setOnHoldModeJustCompleted(function()
    TryClearTasks(PlayerPedId())
end)

DetachPrompt = Uiprompt:new(`INPUT_INTERACT_LEAD_ANIMAL`, "Detach", SpoonerPrompts)
DetachPrompt:setHoldMode(true)
DetachPrompt:setOnHoldModeJustCompleted(function()
    TryDetach(PlayerPedId())
end)

PlacementPrompts = UipromptGroup:new("Spooner Placement", false)

RotateLeftPrompt = Uiprompt:new(`INPUT_SELECT_NEXT_WEAPON`, "Rotate -", PlacementPrompts)
RotateRightPrompt = Uiprompt:new(`INPUT_SELECT_PREV_WEAPON`, "Rotate +", PlacementPrompts)
UpPrompt = Uiprompt:new(`INPUT_FRONTEND_UP`, "Up", PlacementPrompts)
DownPrompt = Uiprompt:new(`INPUT_FRONTEND_DOWN`, "Down", PlacementPrompts)
LeftPrompt = Uiprompt:new(`INPUT_FRONTEND_LEFT`, "Left", PlacementPrompts)
RightPrompt = Uiprompt:new(`INPUT_FRONTEND_RIGHT`, "Right", PlacementPrompts)

PlacePrompt = Uiprompt:new(`INPUT_FRONTEND_ACCEPT`, "Place", PlacementPrompts)
PlacePrompt:setHoldMode(true)

CancelPrompt = Uiprompt:new(`INPUT_FRONTEND_CANCEL`, "Cancel", PlacementPrompts)
CancelPrompt:setHoldMode(true)

StoreDeleted = false
DeletedEntities = {}

local loopFast = 2

-- Track entities with active scenarios/animations for performance optimization
local activeScenarioEntities = {}
local activeAnimationEntities = {}

-- Server provides permissions via 'spooner:init' event
local lastAutoSave = GetGameTimer()
local autoSaveEnabled = Config.Database.AutoSaveInterval > 0

RegisterNetEvent('spooner:init')
RegisterNetEvent('spooner:toggle')
RegisterNetEvent('spooner:openDatabaseMenu')
RegisterNetEvent('spooner:openSaveDbMenu')
RegisterNetEvent('spooner:refreshPermissions')

function EnableSpoonerMode()
	local x, y, z = table.unpack(GetGameplayCamCoord())
	local pitch, roll, yaw = table.unpack(GetGameplayCamRot(2))
	local fov = GetGameplayCamFov()
	Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
	SetCamCoord(Cam, x, y, z)
	SetCamRot(Cam, pitch, roll, yaw, 2)
	SetCamFov(Cam, fov)
	RenderScriptCams(true, true, 500, true, true)

	if FocusTarget then
		FocusEntity(FocusTarget)
	end

	SendNUIMessage({
		type = 'showSpoonerHud'
	})
end

function DisableSpoonerMode()
	if Cam then
		RenderScriptCams(false, true, 500, true, true)
		SetCamActive(Cam, false)
		DetachCam(Cam)
		DestroyCam(Cam, true)
		Cam = nil
	end

	AttachedEntity = nil

	SendNUIMessage({
		type = 'hideSpoonerHud'
	})

	SetNuiFocus(false, false)
end

function ToggleSpoonerMode()
	if Cam then
		DisableSpoonerMode()
	else
		EnableSpoonerMode()
	end
end


function OpenDatabaseMenu()
	UpdateDatabase()
	SendNUIMessage({
		type = 'openDatabase',
		database = json.encode(Database)
	})
	SetNuiFocus(true, true)
end

function OpenSaveDbMenu()
	SendNUIMessage({
		type = 'openSaveLoadDbMenu',
		databaseNames = json.encode(GetSavedDatabases())
	})
	SetNuiFocus(true, true)
end

RegisterCommand('spooner', function(source, args, raw)
	TriggerServerEvent('spooner:toggle')
end, false)

RegisterCommand('spooner_db', function(source, args, raw)
	TriggerServerEvent('spooner:openDatabaseMenu')
end, false)

RegisterCommand('spooner_savedb', function(source, args, raw)
	TriggerServerEvent('spooner:openSaveDbMenu')
end, false)

AddEventHandler('spooner:toggle', ToggleSpoonerMode)
AddEventHandler('spooner:openDatabaseMenu', OpenDatabaseMenu)
AddEventHandler('spooner:openSaveDbMenu', OpenSaveDbMenu)

AddEventHandler('spooner:init', function(permissions)
	Permissions = permissions

	SendNUIMessage({
		type = 'updatePermissions',
		permissions = json.encode(permissions)
	})
end)

AddEventHandler('spooner:refreshPermissions', function()
	TriggerServerEvent('spooner:init')
end)

function GetPedConfigFlags(ped)
	local flags = {}

	for i = 0, 600 do
		flags[i] = GetPedConfigFlag(ped, i)
	end

	return flags
end

-- Cleanup tracking
local activeThreads = {}
local isResourceStopping = false

function RegisterThread(thread)
	table.insert(activeThreads, thread)
end

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
		isResourceStopping = true
		
		DisableSpoonerMode()
		
		if SpoonerPrompts then
			SpoonerPrompts:setActive(false)
		end
		if PlacementPrompts then
			PlacementPrompts:setActive(false)
		end
		
		if Config.Entity.CleanUpOnStop then
			RemoveAllFromDatabase()
		end
		
		if activeScenarioEntities then
			for entity in pairs(activeScenarioEntities) do
				if DoesEntityExist(entity) then
					ClearPedTasks(entity)
				end
			end
		end
		
		if activeAnimationEntities then
			for entity in pairs(activeAnimationEntities) do
				if DoesEntityExist(entity) then
					ClearPedTasks(entity)
				end
			end
		end
		
		FocusTarget = nil
		FocusTargetPos = nil
		
		SetNuiFocus(false, false)
		
		Logger.debug('[Cleanup] Resource stopped and cleaned up')
	end
end)

-- Migrate old KVS keys to new format with DB_ prefix
function MigrateOldSavedDbs()
	local handle = StartFindKvp("")

	while true do
		local kvp = FindKvp(handle)

		if kvp then
			if kvp ~= 'favourites' and string.sub(kvp, 1, 3) ~= 'DB_' and not GetResourceKvpString('DB_' .. kvp) then
				SetResourceKvp('DB_' .. kvp, GetResourceKvpString(kvp))
				Logger.info('[Database] Migrated old DB: ' .. kvp)
				DeleteResourceKvp(kvp)
			end
		else
			break
		end
	end

	EndFindKvp(handle)
end

RegisterCommand('spooner_migrate_old_dbs', function(source, args, raw)
	MigrateOldSavedDbs()
end, false)

-- Main thread: handles spooner mode toggle, updates and UI prompts
CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/spooner', 'Toggle spooner mode', {})

	TriggerServerEvent('spooner:init')

	while true do
		if Cam then
			MainSpoonerUpdates()
			DrawEntityHandles()
			Wait(0)
		else
			if IsUsingKeyboard(0) and CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.Toggle) then
				TriggerServerEvent('spooner:toggle')
			end
			Wait(1)
		end

		SpoonerPrompts:handleEvents()
	end
end)

function MarkEntityAsActive(entity, type)
	if type == 'scenario' then
		activeScenarioEntities[entity] = true
	elseif type == 'animation' then
		activeAnimationEntities[entity] = true
	end
end

function UnmarkEntityAsActive(entity, type)
	if type == 'scenario' then
		activeScenarioEntities[entity] = nil
	elseif type == 'animation' then
		activeAnimationEntities[entity] = nil
	end
end

function UpdateDbEntities()
	local playerPed = PlayerPedId()

	if KeepSelfInDb and not EntityIsInDatabase(playerPed) then
		AddEntityToDatabase(playerPed)
	end

	local enableSpoonerPrompts = false

	-- Check active entities only (optimized for performance)
	for entity in pairs(activeScenarioEntities) do
		if not DoesEntityExist(entity) then
			activeScenarioEntities[entity] = nil
		else
			local properties = GetDatabaseEntry(entity)
			if properties and properties.scenario then
				local hash = joaat(properties.scenario)
				if not IsPedUsingScenarioHash(entity, hash) then
					StartScenario(entity, properties.scenario)
				end
			end
		end
	end

	for entity in pairs(activeAnimationEntities) do
		if not DoesEntityExist(entity) then
			activeAnimationEntities[entity] = nil
		else
			local properties = GetDatabaseEntry(entity)
			if properties and properties.animation then
				if not IsEntityPlayingAnim(entity, properties.animation.dict, properties.animation.name, properties.animation.flag) then
					PlayAnimation(entity, properties.animation)
				end
			end
		end
	end

	-- Register networked entities, remove deleted from DB
	local deletedCount = 0
	for entity, properties in pairs(Database) do
		if not DoesEntityExist(entity) then
			Database[entity] = nil
			activeScenarioEntities[entity] = nil
			activeAnimationEntities[entity] = nil
			deletedCount = deletedCount + 1
		else
			if not NetworkGetEntityIsNetworked(entity) then
				Logger.debug("[Network] Entity " .. entity .. " not networked, registering...")
				NetworkRegisterEntityAsNetworked(entity)
				if NetworkGetEntityIsNetworked(entity) then
					Logger.success("[Network] Entity " .. entity .. " registered successfully")
				else
					Logger.error("[Network] Entity " .. entity .. " registration failed")
				end
			end
		end
	end

	local playerProps = GetDatabaseEntry(playerPed)
	if playerProps then
		if playerProps.scenario or playerProps.animation then
			if Permissions.properties.ped.clearTasks then
				if not ClearTasksPrompt:isEnabled() then
					ClearTasksPrompt:setEnabledAndVisible(true)
				end
				enableSpoonerPrompts = true
			end
		else
			if ClearTasksPrompt:isEnabled() then
				ClearTasksPrompt:setEnabledAndVisible(false)
			end
		end

		if playerProps.attachment.bone then
			if Permissions.properties.attachments then
				if not DetachPrompt:isEnabled() then
					DetachPrompt:setEnabledAndVisible(true)
				end
				enableSpoonerPrompts = true
			end
		else
			if DetachPrompt:isEnabled() then
				DetachPrompt:setEnabledAndVisible(false)
			end
		end
		
		if enableSpoonerPrompts then
			if not SpoonerPrompts:isActive() then
				SpoonerPrompts:setActive(true)
			end
		else
			if SpoonerPrompts:isActive() then
				SpoonerPrompts:setActive(false)
			end
		end
	end
end

-- Background thread: updates database entities and handles auto-save
CreateThread(function()
	while true do
		Wait(1000)
		UpdateDbEntities()
		
		-- Auto-save database at configured interval when in Spooner mode
		if autoSaveEnabled and Cam then
			local currentTime = GetGameTimer()
			local autoSaveIntervalMs = Config.Database.AutoSaveInterval * 60 * 1000
			
				if currentTime - lastAutoSave >= autoSaveIntervalMs then
				lastAutoSave = currentTime
				
				if Config.Database.KeepBackup then
					local backupName = "_autosave_backup"
					SaveDatabase(backupName)
				end
				
				SaveDatabase("_autosave")
				
				if Config.UI.DevMode then
					Logger.info('Database auto-saved')
				end
			end
		end
	end
end)

-- Raytrace from screen to world coordinates
function ScreenToWorld(distance, flags, toIgnore)
	local camRot = GetGameplayCamRot(0)
	local camPos = GetGameplayCamCoord(0)
	local cursor = vector2(0.5,0.5)
	local cam3DPos, forwardDir = ScreenRelToWorld(camPos, camRot, cursor)
	cam3DPos = cam3DPos + forwardDir * 0.5
	local direction = camPos + forwardDir * distance
	local rayHandle = StartShapeTestRay(cam3DPos, direction, flags, toIgnore, 0)
	local a, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
	if entityHit >= 1 then
		entityType = GetEntityType(entityHit)
	end
	return hit, endCoords, surfaceNormal, entityHit, entityType, direction
end

-- Screen coordinates to world coordinates relative to camera
function ScreenRelToWorld(camPos, camRot, cursor)
	local camForward = RotationToDirection(camRot)
	local rotUp = vector3(camRot.x + 1.0, camRot.y, camRot.z)
	local rotDown = vector3(camRot.x - 1.0, camRot.y, camRot.z)
	local rotLeft = vector3(camRot.x, camRot.y, camRot.z - 1.0)
	local rotRight = vector3(camRot.x, camRot.y, camRot.z + 1.0)
	local camRight = RotationToDirection(rotRight) - RotationToDirection(rotLeft)
	local camUp = RotationToDirection(rotUp) - RotationToDirection(rotDown)
	local rollRad = -(camRot.y * math.pi / 180.0)
	local camRightRoll = camRight * math.cos(rollRad) - camUp * math.sin(rollRad)
	local camUpRoll = camRight * math.sin(rollRad) + camUp * math.cos(rollRad)
	local point3DZero = camPos + camForward * 1.0
	local point3D = point3DZero + camRightRoll + camUpRoll
	local point2D = World3DToScreen2D(point3D)
	local point2DZero = World3DToScreen2D(point3DZero)
	local scaleX = (cursor.x - point2DZero.x) / (point2D.x - point2DZero.x)
	local scaleY = (cursor.y - point2DZero.y) / (point2D.y - point2DZero.y)
	local point3Dret = point3DZero + camRightRoll * scaleX + camUpRoll * scaleY
	local forwardDir = camForward + camRightRoll * scaleX + camUpRoll * scaleY
	return point3Dret, forwardDir
end

function RotationToDirection(rotation)
	local x = rotation.x * math.pi / 180.0
	local z = rotation.z * math.pi / 180.0
	local num = math.abs(math.cos(x))
	return vector3((-math.sin(z) * num), (math.cos(z) * num), math.sin(x))
end

function World3DToScreen2D(pos)
	local _, sX, sY = GetScreenCoordFromWorldCoord(pos.x, pos.y, pos.z)
	return vector2(sX, sY)
end

-- Object placement with rotation and offset adjustment
function CreateObjects(data, flag, distance)
	  local zValue = 0.0
	  local yValue = 0.0
	  local Origin = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.0, 1.0)
	  local entities = {}
	  for index, value in ipairs(data) do
		  entities[#entities+1] = value
		  SetEntityCompletelyDisableCollision(value, false, false)
		  SetEntityAlpha(value,200)
	  end
	  ObjectHeading = 0
	  ObjectOrigin = Origin
  
	  local callback = promise.new()
	  local previousCoord = Origin
	  
	  PlacementPrompts:setActive(true)

	  CreateThread(function()
		  while true do
			  Wait(loopFast)
  
			  PlacementPrompts:setActiveThisFrame()
  
			  local hit,targetCoord = ScreenToWorld(distance, flag, PlayerPedId())
  
			  if hit and #(targetCoord - GetEntityCoords(PlayerPedId())) <= distance and #(previousCoord - targetCoord) > 0.025 then
				  targetCoord = vector3(targetCoord.x,targetCoord.y+yValue,targetCoord.z+zValue)
				  previousCoord = targetCoord
				  ObjectOrigin = ObjectMove(entities,ObjectOrigin,targetCoord)
			  end
  
			  if RotateLeftPrompt:isControlPressed(0) then
				  local NewAngle = (ObjectHeading - 1 + 360)%360
				  ObjectRotate(entities,ObjectHeading,ObjectOrigin,NewAngle)
			  end
  
			  if RotateRightPrompt:isControlPressed(0) then
				  local NewAngle = (ObjectHeading + 1)%360
				  ObjectRotate(entities,ObjectHeading,ObjectOrigin,NewAngle)
			  end
			  
			  if UpPrompt:isControlPressed(0) then
				  zValue = zValue + 0.005
			  end
			  
			  if DownPrompt:isControlPressed(0) then
				  zValue = zValue - 0.005
			  end
  
			  if LeftPrompt:isControlPressed(0) then
				  yValue = yValue + 0.005
			  end
  
			  if RightPrompt:isControlPressed(0) then
				  yValue = yValue - 0.005
			  end
  
			  if PlacePrompt:hasHoldModeJustCompleted() then
				  PlacementPrompts:setActive(false)
				  callback:resolve({
					  coords = ObjectOrigin,
					  heading = ObjectHeading
				  })
				  for index, value in ipairs(entities) do
					  SetEntityCompletelyDisableCollision(value, true, true)
					  SetEntityAlpha(value,255)
				  end
				  break
			  end
  
			  if CancelPrompt:hasHoldModeJustCompleted() then
				  PlacementPrompts:setActive(false)
				  callback:resolve(nil)
				  for index, value in ipairs(entities) do
					  RemoveEntity(value)
				  end
				  break
			  end
		  end
	  end)
	  return Citizen.Await(callback)
end

ObjectRotate = function(entities,heading,origin,angle)
    local rotation, coords
    local diffAngle = heading - angle
    if diffAngle < 0 then
      diffAngle = diffAngle + 360
    end
	for index, value in ipairs(entities) do
		rotation = GetEntityRotation(value,2)
		coords = GetEntityCoords(value)
		newCoord = RotateObject(coords.xy,origin.xy, math.rad(diffAngle))
		SetEntityCoords(value, newCoord.x, newCoord.y, coords.z)
		SetEntityRotation(value, rotation.x, rotation.y, rotation.z + diffAngle,2,false)
	end
	heading = angle
end

ObjectMove = function(entities,Origin,NewCoords)
    local offset = vector3(0,0,0)
	for index, value in ipairs(entities) do
		offset = GetEntityCoords(value) - Origin
		SetEntityCoords(value, NewCoords.x + offset.x, NewCoords.y + offset.y, NewCoords.z + offset.z)
	end
    return NewCoords
end

function RotateObject(_coord,_center,_angle)
    return vector2(
      (_coord.x - _center.x) * math.cos(_angle) - (_coord.y - _center.y) * math.sin(_angle) + _center.x,
      (_coord.x - _center.x) * math.sin(_angle) + (_coord.y - _center.y) * math.cos(_angle) + _center.y
    )
end

