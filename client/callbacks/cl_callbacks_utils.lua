-- NUI callbacks: UI initialization, settings and general utilities

RegisterNUICallback('init', function(data, cb)
	local bones = Bones

	local SpooniList = {}

    for k, v in pairs(Spooni) do
        if IsModelValid(v) then
            table.insert(SpooniList, v)
        end
    end

	cb({
		peds = json.encode(Peds),
		vehicles = json.encode(Vehicles),
		objects = json.encode(Objects),
		spooni = json.encode(SpooniList),
		scenarios = json.encode(Scenarios),
		weapons = json.encode(Weapons),
		animations = json.encode(Animations),
		propsets = json.encode(Propsets),
		pickups = json.encode(Pickups),
		bones = json.encode(bones),
		walkStyleBases = json.encode(WalkStyleBases),
		walkStyles = json.encode(WalkStyles),
		adjustSpeed = AdjustSpeed,
		rotateSpeed = RotateSpeed,
		favourites = GetFavourites()
	})
end)

RegisterNUICallback('closeMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closeHelpMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('setAdjustSpeed', function(data, cb)
	local speed = ValidateNumber(data.speed, 0.01, 100.0, 1.0)
	AdjustSpeed = speed
	cb({})
end)

RegisterNUICallback('setRotateSpeed', function(data, cb)
	local speed = ValidateNumber(data.speed, 0.01, 100.0, 1.0)
	RotateSpeed = speed
	cb({})
end)

RegisterNUICallback('loadPermissions', function(data, cb)
	cb(json.encode(Permissions))
end)
