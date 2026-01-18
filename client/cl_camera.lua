-- Camera system and entity manipulation in Spooner mode

function MainSpoonerUpdates()
	if IsUsingKeyboard(0) and CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.Toggle) then
		TriggerServerEvent('spooner:toggle')
	end

	if Cam then
		DisableAllControlActions(0)
		EnableControlAction(0, `INPUT_FRONTEND_PAUSE_ALTERNATE`, true)
		EnableControlAction(0, `INPUT_MP_TEXT_CHAT_ALL`, true)

		local x1, y1, z1 = table.unpack(GetCamCoord(Cam))
		local pitch1, roll1, yaw1 = table.unpack(GetCamRot(Cam, 2))

		local x2 = x1
		local y2 = y1
		local z2 = z1
		local pitch2 = pitch1
		local roll2 = roll1
		local yaw2 = yaw1

		local spawnPos, entity, distance = GetInView(x2, y2, z2, pitch2, roll2, yaw2)

		if AttachedEntity then
			entity = AttachedEntity
		elseif FocusTarget and not FreeFocus then
			entity = FocusTarget
		end

        if MessageInterval then
            MessageInterval = false
            CreateThread(function()
                Wait(MessageRate)
                MessageInterval = true
            end)
			SendNUIMessage({
				type = 'updateSpoonerHud',
				entity = entity,
				netId = NetworkGetEntityIsNetworked(entity) and ObjToNet(entity),
				entityType = GetSpoonerEntityType(entity),
				modelName = GetModelName(GetSpoonerEntityModel(entity)),
				attachedEntity = AttachedEntity,
				speed = string.format('%.2f', Speed),
				currentSpawn = CurrentSpawn and CurrentSpawn.modelName,
				rotateMode = RotateMode,
				adjustMode = AdjustMode,
				speedMode = SpeedMode,
				placeOnGround = PlaceOnGround,
				adjustSpeed = AdjustSpeed,
				rotateSpeed = RotateSpeed,
				cursorX = string.format('%.2f', spawnPos.x),
				cursorY = string.format('%.2f', spawnPos.y),
				cursorZ = string.format('%.2f', spawnPos.z),
				camX = string.format('%.2f', x2),
				camY = string.format('%.2f', y2),
				camZ = string.format('%.2f', z2),
				camHeading = string.format('%.2f', yaw2),
				focusTarget = FocusTarget,
				freeFocus = FreeFocus
			})
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.Controls.IncreaseSpeed) then
			if SpeedMode == 0 then
			Speed = Speed + Config.Movement.SpeedIncrement
		elseif SpeedMode == 1 then
			AdjustSpeed = AdjustSpeed + Config.Adjustment.SpeedIncrement
		elseif SpeedMode == 2 then
			RotateSpeed = RotateSpeed + Config.Adjustment.RotateSpeedIncrement
			end
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.Controls.DecreaseSpeed) then
			if SpeedMode == 0 then
			Speed = Speed - Config.Movement.SpeedIncrement
		elseif SpeedMode == 1 then
			AdjustSpeed = AdjustSpeed - Config.Adjustment.SpeedIncrement
		elseif SpeedMode == 2 then
			RotateSpeed = RotateSpeed - Config.Adjustment.RotateSpeedIncrement
			end
		end

	if Speed < Config.Movement.MinSpeed then
		Speed = Config.Movement.MinSpeed
	elseif Speed > Config.Movement.MaxSpeed then
		Speed = Config.Movement.MaxSpeed
	end

	if AdjustSpeed < Config.Adjustment.MinSpeed then
		AdjustSpeed = Config.Adjustment.MinSpeed
	elseif AdjustSpeed > Config.Adjustment.MaxSpeed then
		AdjustSpeed = Config.Adjustment.MaxSpeed
	end

	if RotateSpeed < Config.Adjustment.MinRotateSpeed then
		RotateSpeed = Config.Adjustment.MinRotateSpeed
	elseif RotateSpeed > Config.Adjustment.MaxRotateSpeed then
		RotateSpeed = Config.Adjustment.MaxRotateSpeed
	end

		if CheckControls(IsDisabledControlPressed, 0, Config.Controls.Up) then
			z2 = z2 + Speed
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.Controls.Down) then
			z2 = z2 - Speed
		end

		local axisX = GetDisabledControlNormal(0, Config.Controls.LookLr)
		local axisY = GetDisabledControlNormal(0, Config.Controls.LookUd)

		if axisX ~= 0.0 or axisY ~= 0.0 then
			yaw2 = yaw2 + axisX * -1.0 * Config.Camera.SpeedUd
			pitch2 = math.max(math.min(89.9, pitch2 + axisY * -1.0 * Config.Camera.SpeedLr), -89.9)
		end

		local r1 = -yaw2 * math.pi / 180
		local dx1 = Speed * math.sin(r1)
		local dy1 = Speed * math.cos(r1)

		local r2 = math.floor(yaw2 + 90.0) % 360 * -1.0 * math.pi / 180
		local dx2 = Speed * math.sin(r2)
		local dy2 = Speed * math.cos(r2)

		if CheckControls(IsDisabledControlPressed, 0, Config.Controls.Forward) then
			x2 = x2 + dx1
			y2 = y2 + dy1
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.Controls.Backward) then
			x2 = x2 - dx1
			y2 = y2 - dy1
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.Controls.Left) then
			x2 = x2 + dx2
			y2 = y2 + dy2
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.Controls.Right) then
			x2 = x2 - dx2
			y2 = y2 - dy2
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.Spawn) and CurrentSpawn then
			local entity

			if CurrentSpawn.type == 1 then
				entity = SpawnPed{
					name = CurrentSpawn.modelName,
					model = joaat(CurrentSpawn.modelName),
					x = spawnPos.x,
					y = spawnPos.y,
					z = spawnPos.z,
					pitch = 0.0,
					roll = 0.0,
					yaw = yaw2 + 180.0,
					collisionDisabled = false,
					isVisible = true,
					outfit = -1,
					isInGroup = false,
					blockNonTemporaryEvents = false
				}

			elseif CurrentSpawn.type == 2 then
				entity = SpawnVehicle(CurrentSpawn.modelName, joaat(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z, 0.0, 0.0, yaw2, false, true)
			elseif CurrentSpawn.type == 3 then
				entity = SpawnObject(CurrentSpawn.modelName, joaat(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z, 0.0, 0.0, yaw2, false, true, nil, nil, nil)
			elseif CurrentSpawn.type == 4 then
				entity = SpawnPropset(CurrentSpawn.modelName, joaat(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z, yaw2)
			elseif CurrentSpawn.type == 5 then
				entity = SpawnPickup(CurrentSpawn.modelName, joaat(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z)
			elseif CurrentSpawn.type == 3 then
				entity = SpawnSpooni(CurrentSpawn.modelName, joaat(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z, 0.0, 0.0, yaw2, false, true, nil, nil, nil)
			end

			if entity then
				PlaceOnGroundProperly(entity)
			end
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.Select) then
			if AttachedEntity then
				AttachedEntity = nil
			elseif entity and CanModifyEntity(entity) then
				if IsEntityAttached(entity) then
					AttachedEntity = GetEntityAttachedTo(entity)
				else
					AttachedEntity = entity
				end
			end
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.Delete) and entity then
			if AttachedEntity then
				RemoveEntity(AttachedEntity)
				AttachedEntity = nil
			else
				RemoveEntity(entity)
			end
		end

		if CheckControls(IsDisabledControlJustReleased, 0, Config.Controls.SpawnMenu) then
			SendNUIMessage({
				type = 'openSpawnMenu'
			})
			SetNuiFocus(true, true)
		end

		if CheckControls(IsDisabledControlJustReleased, 0, Config.Controls.DbMenu) then
			OpenDatabaseMenu()
		end

		if CheckControls(IsDisabledControlJustReleased, 0, Config.Controls.SaveLoadDbMenu) then
			OpenSaveDbMenu()
		end

		if CheckControls(IsDisabledControlJustReleased, 0, Config.Controls.HelpMenu) then
			SendNUIMessage({
				type = 'openHelpMenu'
			})
			SetNuiFocus(true, true)
		end

		if CheckControls(IsDisabledControlJustReleased, 0, Config.Controls.ToggleControls) then
			ShowControls = not ShowControls
			if ShowControls then
				SendNUIMessage({
					type = 'showControls'
				})
			else
				SendNUIMessage({
					type = 'hideControls'
				})
			end
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.RotateMode) then
			RotateMode = (RotateMode + 1) % 3
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.AdjustMode) then
			if AdjustMode < 4 then
				AdjustMode = (AdjustMode + 1) % 4
			else
				AdjustMode = 0
			end
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.FreeAdjustMode) then
			AdjustMode = 4
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.AdjustOff) then
			AdjustMode = 5
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.SpeedMode) then
			SpeedMode = (SpeedMode + 1) % 3
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.PlaceOnGround) then
			PlaceOnGround = not PlaceOnGround
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.Focus) then
			if not entity or FocusTarget == entity then
				UnfocusEntity()
			else
				TryFocusEntity(entity)
			end
		end

		if FocusTarget and CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.ToggleFocusMode) then
			if FreeFocus then
				PointCamAtEntity(Cam, FocusTarget)
				FreeFocus = false
			else
				StopCamPointing(Cam)
				FreeFocus = true
			end
		end

		if entity and CanModifyEntity(entity) then
			local posChanged = false
			local rotChanged = false

			if CheckControls(IsDisabledControlJustReleased, 0, Config.Controls.PropMenu) then
				OpenPropertiesMenuForEntity(entity)
			end

			if CheckControls(IsDisabledControlJustPressed, 0, Config.Controls.Clone) then
				AttachedEntity = CloneEntity(entity)
			end

			local ex1, ey1, ez1, epitch1, eroll1, eyaw1

		local dbEntry = GetDatabaseEntry(entity)
		if dbEntry and dbEntry.attachment.to > 0 then
			ex1 = dbEntry.attachment.x
			ey1 = dbEntry.attachment.y
			ez1 = dbEntry.attachment.z
			epitch1 = dbEntry.attachment.pitch
			eroll1 = dbEntry.attachment.roll
			eyaw1 = dbEntry.attachment.yaw
			else
				ex1, ey1, ez1 = table.unpack(GetEntityCoords(entity))
				epitch1, eroll1, eyaw1 = table.unpack(GetEntityRotation(entity, 2))
			end

			local ex2 = ex1
			local ey2 = ey1
			local ez2 = ez1
			local epitch2 = epitch1
			local eroll2 = eroll1
			local eyaw2 = eyaw1

			local edx1, edy1, edx2, edy2

		if dbEntry and dbEntry.attachment.to > 0 then
				edx1 = 0
				edy1 = AdjustSpeed
				edx2 = AdjustSpeed
				edy2 = 0
			else
				edx1 = AdjustSpeed * math.sin(r1)
				edy1 = AdjustSpeed * math.cos(r1)
				edx2 = AdjustSpeed * math.sin(r2)
				edy2 = AdjustSpeed * math.cos(r2)
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.Controls.RotateLeft) then
				if RotateMode == 0 then
					epitch2 = epitch2 + RotateSpeed
				elseif RotateMode == 1 then
					eroll2 = eroll2 + RotateSpeed
				else
					eyaw2 = eyaw2 + RotateSpeed
				end

				rotChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.Controls.RotateRight) then
				if RotateMode == 0 then
					epitch2 = epitch2 - RotateSpeed
				elseif RotateMode == 1 then
					eroll2 = eroll2 - RotateSpeed
				else
					eyaw2 = eyaw2 - RotateSpeed
				end

				rotChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.Controls.AdjustUp) then
				ez2 = ez2 + AdjustSpeed
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.Controls.AdjustDown) then
				ez2 = ez2 - AdjustSpeed
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.Controls.AdjustForward) then
				ex2 = ex2 + edx1
				ey2 = ey2 + edy1
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.Controls.AdjustBackward) then
				ex2 = ex2 - edx1
				ey2 = ey2 - edy1
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.Controls.AdjustLeft) then
				ex2 = ex2 + edx2
				ey2 = ey2 + edy2
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.Controls.AdjustRight) then
				ex2 = ex2 - edx2
				ey2 = ey2 - edy2
				posChanged = true
			end

			if AttachedEntity or posChanged or rotChanged then
				RequestControl(entity)

			if dbEntry and dbEntry.attachment.to > 0 then
				AttachEntity(entity,
					dbEntry.attachment.to,
					dbEntry.attachment.bone,
					ex2, ey2, ez2,
					epitch2, eroll2, eyaw2,
					dbEntry.attachment.useSoftPinning,
					dbEntry.attachment.collision,
					dbEntry.attachment.vertex,
					dbEntry.attachment.fixedRot)
				else
					if posChanged then
						SetEntityCoordsNoOffset(entity, ex2, ey2, ez2)
					end

					if rotChanged then
						SetEntityRotation(entity, epitch2, eroll2, eyaw2, 2)
					end
				end

				if AttachedEntity then
					if AdjustMode < 4 then
						x2 = x1
						y2 = y1
						z2 = z1
						pitch2 = pitch1
						yaw2 = yaw1

						if AdjustMode == 0 then
							SetEntityCoordsNoOffset(AttachedEntity, ex2 - axisX, ey2, ez2)
						elseif AdjustMode == 1 then
							SetEntityCoordsNoOffset(AttachedEntity, ex2, ey2 - axisX, ez2)
						elseif AdjustMode == 2 then
							SetEntityCoordsNoOffset(AttachedEntity, ex2, ey2, ez2 - axisY)
						elseif AdjustMode == 3 then
							if RotateMode == 0 then
							SetEntityRotation(AttachedEntity, epitch2 - axisX * Config.Camera.SpeedLr, eroll2, eyaw2, 2)
						elseif RotateMode == 1 then
							SetEntityRotation(AttachedEntity, epitch2, eroll2 - axisX * Config.Camera.SpeedLr, eyaw2, 2)
						else
							SetEntityRotation(AttachedEntity, epitch2, eroll2, eyaw2 - axisX * Config.Camera.SpeedLr, 2)
							end
						end
					elseif AdjustMode == 4 then
						SetEntityCoordsNoOffset(AttachedEntity, spawnPos.x, spawnPos.y, spawnPos.z)
					end

					if PlaceOnGround or AdjustMode == 4 then
						PlaceOnGroundProperly(AttachedEntity)
					end
				end
			end
		end

		if FocusTarget then
			if DoesEntityExist(FocusTarget) then
				local currentPos = GetEntityCoords(FocusTarget)

				SetCamCoord(Cam, vector3(x2, y2, z2) + (currentPos - FocusTargetPos))

				FocusTargetPos = currentPos
			else
				UnfocusEntity()
			end
		else
			SetCamCoord(Cam, x2, y2, z2)
		end

		SetCamRot(Cam, pitch2, 0.0, yaw2)
	end
end

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end
		enum.destructor = nil
		enum.handle = nil
	end
}

local function enumerateEntities(firstFunc, nextFunc, endFunc)
	return coroutine.wrap(function()
		local iter, id = firstFunc()

		if not id or id == 0 then
			endFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = endFunc}
		setmetatable(enum, entityEnumerator)

		local next = true
		repeat
			coroutine.yield(id)
			next, id = nextFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		endFunc(iter)
	end)
end

function EnumeratePeds()
	return enumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
	return enumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

function EnumerateObjects()
	return enumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumerateSpooni()
	return enumerateEntities(FindFirstSpooni, FindNextSpooni, EndFindSpooni)
end

function DrawText3D(x, y, z, text)
	local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(x, y, z)

	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFontForCurrentCommand(1)
		SetTextColor(255, 255, 255, 255)
		SetTextCentre(1)
		DisplayText(CreateVarString(10, "LITERAL_STRING", text), screenX, screenY)
	end
end

function DrawEntityHandle(type, entity, camCoords)
	local coords = GetEntityCoords(entity)

	if #(camCoords - coords) <= Config.Entity.HandleDrawDistance then
		DrawText3D(coords.x, coords.y, coords.z, type .. " " .. tostring(entity))
	end
end

function DrawEntityHandles()
	if Cam then
		if IsDisabledControlJustPressed(0, Config.Controls.EntityHandles) then
			ShowEntityHandles = not ShowEntityHandles
		end

		if ShowEntityHandles then
			local camCoords = GetCamCoord(Cam)

			for ped in EnumeratePeds() do
				DrawEntityHandle("ped", ped, camCoords)
			end

			for vehicle in EnumerateVehicles() do
				DrawEntityHandle("vehicle", vehicle, camCoords)
			end

			for object in EnumerateObjects() do
				DrawEntityHandle("object", object, camCoords)
			end
		end
	end
end
