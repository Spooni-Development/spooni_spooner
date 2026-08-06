-- =============================================================================
-- 3D-Gizmo (Port von gs_gizmo: https://github.com/GlitchOo/gs_gizmo) —
-- komplett in spooni_spooner, keine dusk_utils-Abhängigkeit.
-- NUI: ui/gizmo/* (Original-Vite-Dateinamen, NIE umbenennen!), eingebettet in
-- ui/index.html (#root, Sichtbarkeit toggelt script.js über die SetupGizmo-Message).
--
-- WICHTIG — Prompt/Control-Muster vom laufenden Original (Referenz-Scripte/gs_gizmo):
--  * KEIN DisableAllControlActions! Nur INPUT_ATTACK wird disabled, sonst sind
--    Prompts UND Tasten tot (Prompt-System braucht aktive Controls).
--  * Tasten über das Prompt-System: PromptSetControlAction(rohe Key-Hashes) +
--    PromptHasStandardModeCompleted. Prompts pro Session registriert + gelöscht.
--
-- KAMERA = ORBIT (Dusk-Wunsch): fest aufs Objekt fokussiert, die MAUS steuert nur
-- das Gizmo (kein Maus-Look). Mit den TASTEN kreist man um das Objekt:
--   A/D  = links/rechts herum (Azimut)
--   E/Q  = hoch/runter herum (Elevation)
--   W/S  = näher/weiter (Zoom)
-- So bleibt die Maus immer frei fürs Gizmo und die Blickrichtung wackelt nie.
-- =============================================================================

local GizmoKeys = {
	Q      = 0x06052D11,
	E      = 0xD51B784F,
	R      = 0xE30CD707,
	G      = 0x760A9C6F,
	L      = 0x80F28E95,
	ENTER  = 0xC7B5340A,
	W_S    = 0xAEB4B1DE, -- Achsen-Kombi vor/zurück (Zoom)
	A_D    = 0xF1111E4A, -- Achsen-Kombi links/rechts (Orbit)
	ATTACK = 0x07CE1E61, -- INPUT_ATTACK (linke Maustaste)
}

local ORBIT_SPEED   = 0.02  -- rad/Frame für Azimut & Elevation
local ZOOM_SPEED    = 0.20  -- m/Frame für rein/raus
local MIN_RADIUS    = 1.5
local MAX_RADIUS    = 100.0
local MAX_ELEVATION = math.rad(85.0) -- nicht über den Pol (Gimbal vermeiden)

local gizmoActive = false
local gizmoPromise = nil
local gizmoMode = 'translate'
local gizmoTarget = nil
local GizmoCam = nil

-- Orbit-Zustand relativ zum Objekt
local gizmoAzimuth = 0.0
local gizmoElevation = 0.0
local gizmoRadius = 5.0

--- Prompt im 'click'-Modus registrieren (Muster aus gs_gizmo UIPrompts.lua)
local function RegisterGizmoPrompt(group, text, keyHash)
	local prompt = PromptRegisterBegin()

	PromptSetControlAction(prompt, keyHash)
	PromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', text))
	PromptSetEnabled(prompt, true)
	PromptSetVisible(prompt, true)
	PromptSetStandardMode(prompt, 1)
	PromptSetGroup(prompt, group, 0)
	PromptSetUrgentPulsingEnabled(prompt, false)
	PromptRegisterEnd(prompt)

	return prompt
end

--- Normal-Wert eines Controls bzw. einer Control-Differenz (Achsen-Kombi)
local function GetSmartControlNormal(control)
	if type(control) == 'table' then
		return GetDisabledControlNormal(0, control[1]) - GetDisabledControlNormal(0, control[2])
	end

	return GetDisabledControlNormal(0, control)
end

--- Kamera aus dem Orbit-Zustand (Azimut/Elevation/Radius) um den Anker setzen und
--- den Blick fest aufs Objekt richten — deterministisch, kein PointCamAtEntity.
local function ApplyOrbitCam(anchor)
	if not GizmoCam or not DoesEntityExist(anchor) then return end

	local aPos = GetEntityCoords(anchor)
	local flat = gizmoRadius * math.cos(gizmoElevation)

	local cx = aPos.x + flat * math.sin(gizmoAzimuth)
	local cy = aPos.y + flat * math.cos(gizmoAzimuth)
	local cz = aPos.z + gizmoRadius * math.sin(gizmoElevation)

	SetCamCoord(GizmoCam, cx, cy, cz)

	local dx = aPos.x - cx
	local dy = aPos.y - cy
	local dz = aPos.z - cz
	local flatD = math.sqrt(dx * dx + dy * dy)

	SetCamRot(GizmoCam, math.deg(math.atan(dz, flatD)), 0.0, GetHeadingFromVector_2d(dx, dy), 2)
end

--- Orbit-Steuerung: Tasten ändern Azimut/Elevation/Radius (Maus bleibt fürs Gizmo frei)
local function GizmoOrbitControl()
	local orbitLR = GetSmartControlNormal(GizmoKeys.A_D)                -- A/D um das Objekt
	local zoom    = GetSmartControlNormal(GizmoKeys.W_S)                -- W/S näher/weiter
	local orbitUD = GetSmartControlNormal({ GizmoKeys.E, GizmoKeys.Q }) -- E hoch / Q runter

	if orbitLR ~= 0.0 then
		gizmoAzimuth = gizmoAzimuth + orbitLR * ORBIT_SPEED
	end

	if orbitUD ~= 0.0 then
		gizmoElevation = gizmoElevation + orbitUD * ORBIT_SPEED

		if gizmoElevation < -MAX_ELEVATION then gizmoElevation = -MAX_ELEVATION end
		if gizmoElevation > MAX_ELEVATION then gizmoElevation = MAX_ELEVATION end
	end

	if zoom ~= 0.0 then
		gizmoRadius = gizmoRadius - zoom * ZOOM_SPEED -- W (positiv) = näher

		if gizmoRadius < MIN_RADIUS then gizmoRadius = MIN_RADIUS end
		if gizmoRadius > MAX_RADIUS then gizmoRadius = MAX_RADIUS end
	end
end

--- Orbit-Zustand aus der aktuellen Kamera-zu-Objekt-Lage initialisieren, damit der
--- Einstieg nahtlos ist. Bei weit entferntem Anker (DB-Move) auf einen nahen Radius clampen.
local function SetupGizmoCam(anchor, radius)
	local aPos = GetEntityCoords(anchor)
	local camPos = GetFinalRenderedCamCoord()
	local delta = camPos - aPos
	local dist = #(delta)

	local maxStart = math.max(12.0, (radius or 0.0) + 6.0)
	gizmoRadius = math.min(math.max(dist, 2.5), maxStart)

	if dist > 0.01 then
		gizmoAzimuth = math.atan(delta.x, delta.y)
		local flat = math.sqrt(delta.x * delta.x + delta.y * delta.y)
		gizmoElevation = math.atan(delta.z, flat)
	else
		gizmoAzimuth = 0.0
		gizmoElevation = math.rad(20.0)
	end

	if gizmoElevation < -MAX_ELEVATION then gizmoElevation = -MAX_ELEVATION end
	if gizmoElevation > MAX_ELEVATION then gizmoElevation = MAX_ELEVATION end

	GizmoCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
	SetCamFov(GizmoCam, GetGameplayCamFov())
	ApplyOrbitCam(anchor)

	RenderScriptCams(true, true, 500, true, true)
end

--- Controls/HUD während der Session (Muster aus gs_gizmo DisableControlsAndUI).
--- Bewusst NUR INPUT_ATTACK — DisableAllControlActions killt Prompts und Tasten.
local function DisableGizmoControlsAndUI()
	DisableControlAction(0, GizmoKeys.ATTACK, true)
	HideHudAndRadarThisFrame()
	DisablePlayerFiring(PlayerId(), true)
end

local function StopGizmoSession()
	gizmoActive = false
	gizmoTarget = nil

	local ped = PlayerPedId()

	SetNuiFocus(false, false)
	-- KeepInput unbedingt zurücksetzen: bleibt es an, gehen Maus-Inputs künftig
	-- durchs Spooner-Menü ans Spiel durch → Freecam dreht sich beim Klicken im UI
	SetNuiFocusKeepInput(false)

	ClearPedTasks(ped)
	FreezeEntityPosition(ped, false)
	SetEntityInvincible(ped, false)

	if GizmoCam then
		RenderScriptCams(false, true, 500, true, true)
		SetCamActive(GizmoCam, false)
		DestroyCam(GizmoCam, true)
		GizmoCam = nil
	end

	-- fehlender handle versteckt Gizmo und Canvas (#root) im NUI
	SendNUIMessage({
		action = 'SetupGizmo',
		data = {}
	})
end

--- Blockierende Gizmo-Session für ein Entity.
--- @param anchor number Entity-Handle
--- @param radius number|nil Ausdehnung der Gruppe um den Anker (für den Start-Radius)
--- @return table|string|nil {entity, position, rotation} bei Fertig, 'stop' bei Abbruch
function SpoonerToggleGizmo(anchor, radius)
	if not anchor or not DoesEntityExist(anchor) then return nil end

	if gizmoActive then
		-- laufende Session sauber als Abbruch beenden, sonst hängt deren Await ewig
		if gizmoPromise then
			gizmoPromise:resolve('stop')
		end

		StopGizmoSession()
		Wait(50)
	end

	gizmoTarget = anchor
	gizmoMode = 'translate'
	gizmoActive = true

	local ped = PlayerPedId()

	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)

	-- Ped ruhigstellen (Muster aus vorp_character/clothingstore — dort laufen
	-- Prompts nachweislich weiter): Freeze stoppt nur die Bewegung, TaskStandStill
	-- unterbindet Lauf-Anims und Drehung
	FreezeEntityPosition(ped, true)
	SetEntityInvincible(ped, true)
	TaskStandStill(ped, -1)

	SetupGizmoCam(anchor, radius or 0.0)

	SendNUIMessage({
		action = 'SetupGizmo',
		data = {
			handle = anchor,
			position = GetEntityCoords(anchor),
			rotation = GetEntityRotation(anchor),
			gizmoMode = gizmoMode
		}
	})

	gizmoPromise = promise.new()

	-- Orbit-Kamera-Loop
	CreateThread(function()
		while gizmoActive do
			Wait(0)
			DisableGizmoControlsAndUI()

			if GizmoCam and gizmoTarget then
				-- Nicht während des Widget-Drags (LMB) — sonst wandert der Raycast
				-- unterm Cursor weg. Sonst: Tasten-Orbit anwenden und aufs (evtl.
				-- verschobene) Objekt zentriert bleiben.
				if GetDisabledControlNormal(0, GizmoKeys.ATTACK) == 0 then
					GizmoOrbitControl()
					ApplyOrbitCam(gizmoTarget)
				end
			end
		end
	end)

	-- NUI-Kamera-Sync (three.js braucht die Kamera-Pose fürs Widget-Alignment)
	CreateThread(function()
		local lastCamPos, lastCamRot

		while gizmoActive do
			Wait(0)

			if GetDisabledControlNormal(0, GizmoKeys.ATTACK) == 0 then
				local camPos = GetFinalRenderedCamCoord()
				local camRot = GetFinalRenderedCamRot(0)

				if camPos ~= lastCamPos or camRot ~= lastCamRot then
					lastCamPos = camPos
					lastCamRot = camRot

					SendNUIMessage({
						action = 'SetCameraPosition',
						data = {
							position = camPos,
							rotation = camRot
						}
					})
				end
			end
		end
	end)

	-- Prompt-Loop: Prompts pro Session registrieren, Gruppe jeden Frame zeigen,
	-- Tasten über PromptHasStandardModeCompleted lesen (NICHT IsControlJustPressed)
	CreateThread(function()
		local group = GetRandomIntInRange(0, 0xffffff)

		local ModePrompt   = RegisterGizmoPrompt(group, 'Rotate', GizmoKeys.R)
		local GroundPrompt = RegisterGizmoPrompt(group, 'Snap to Ground', GizmoKeys.G)
		local DonePrompt   = RegisterGizmoPrompt(group, 'Done', GizmoKeys.ENTER)
		local CancelPrompt = RegisterGizmoPrompt(group, 'Cancel', GizmoKeys.L)
		local OrbitPrompt  = RegisterGizmoPrompt(group, 'Orbit L/R', GizmoKeys.A_D)
		local ZoomPrompt   = RegisterGizmoPrompt(group, 'Zoom', GizmoKeys.W_S)
		local UpPrompt     = RegisterGizmoPrompt(group, 'Up', GizmoKeys.E)
		local DownPrompt   = RegisterGizmoPrompt(group, 'Down', GizmoKeys.Q)

		while gizmoActive do
			Wait(5)

			PromptSetActiveGroupThisFrame(group, CreateVarString(10, 'LITERAL_STRING', 'Gizmo'), 1, 0, 0, 0)

			if PromptHasStandardModeCompleted(ModePrompt) then
				gizmoMode = (gizmoMode == 'translate') and 'rotate' or 'translate'

				SendNUIMessage({
					action = 'SetGizmoMode',
					data = gizmoMode
				})

				PromptSetText(ModePrompt, CreateVarString(10, 'LITERAL_STRING',
					gizmoMode == 'translate' and 'Rotate' or 'Translate'))
			end

			if PromptHasStandardModeCompleted(GroundPrompt) and gizmoTarget then
				PlaceObjectOnGroundProperly(gizmoTarget)

				SendNUIMessage({
					action = 'SetupGizmo',
					data = {
						handle = gizmoTarget,
						position = GetEntityCoords(gizmoTarget),
						rotation = GetEntityRotation(gizmoTarget),
						gizmoMode = gizmoMode
					}
				})
			end

			if PromptHasStandardModeCompleted(DonePrompt) and gizmoTarget then
				gizmoPromise:resolve({
					entity = gizmoTarget,
					position = GetEntityCoords(gizmoTarget),
					rotation = GetEntityRotation(gizmoTarget)
				})

				StopGizmoSession()
			elseif PromptHasStandardModeCompleted(CancelPrompt) then
				gizmoPromise:resolve('stop')
				StopGizmoSession()
			end
		end

		PromptDelete(ModePrompt)
		PromptDelete(GroundPrompt)
		PromptDelete(DonePrompt)
		PromptDelete(CancelPrompt)
		PromptDelete(OrbitPrompt)
		PromptDelete(ZoomPrompt)
		PromptDelete(UpPrompt)
		PromptDelete(DownPrompt)
	end)

	return Citizen.Await(gizmoPromise)
end

-- NUI → Lua: Gizmo hat das Objekt bewegt
RegisterNUICallback('UpdateEntity', function(data, cb)
	-- DoesEntityExist-Guard: despawnt das Entity während eines Moves, wäre der
	-- Transform-Write auf den stalen Handle ein Use-after-free im Renderer
	if gizmoActive and gizmoTarget and data.handle == gizmoTarget and DoesEntityExist(gizmoTarget) then
		SetEntityCoords(gizmoTarget, data.position.x, data.position.y, data.position.z)
		SetEntityRotation(gizmoTarget, data.rotation.x, data.rotation.y, data.rotation.z)
	end

	-- Das gs_gizmo-Bundle erwartet { status = 'ok' } — bei allem anderen springt es
	-- in seinen Revert-Pfad und liest position/rotation aus der Antwort
	cb({ status = 'ok' })
end)

AddEventHandler('onResourceStop', function(res)
	if res == GetCurrentResourceName() and gizmoActive then
		if gizmoPromise then
			gizmoPromise:resolve('stop')
		end

		StopGizmoSession()
	end
end)
