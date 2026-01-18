-- Spawn functions: creates peds, vehicles, objects, pickups and propsets

function SpawnObject(name, model, x, y, z, pitch, roll, yaw, collisionDisabled, isVisible, lightsIntensity, lightsColour, lightsType)
    if not Permissions.spawn.object then
        Logger.error('No permission to spawn objects')
        return nil
    end

    if IsDatabaseFull() then
        Logger.error('Database is full')
        return nil
    end
    
    if IsEntityTypeLimitReached(3) then
        Logger.error('Object limit reached')
        return nil
    end

    if not LoadModel(model) then
        Logger.error("Failed to load model: " .. tostring(name))
        return nil
    end

    local object = CreateObjectNoOffset(model, x, y, z, true, false, true)

    SetModelAsNoLongerNeeded(model)

    if not object or object < 1 then
        Logger.error('Failed to spawn object')
        return nil
    end

    SetEntityRotation(object, pitch, roll, yaw, 2)
    FreezeEntityPosition(object, true)

    if collisionDisabled then
        SetEntityCollision(object, false, false)
    end

    if isVisible == false then
        SetEntityVisible(object, false)
    end

    if lightsIntensity then
        SetLightsIntensityForEntity(object, lightsIntensity)
    end

    if lightsColour then
        SetLightsColorForEntity(object, lightsColour.red, lightsColour.green, lightsColour.blue)
    end

    if lightsType then
        SetLightsTypeForEntity(object, lightsType)
    end

    AddEntityToDatabase(object, name)

    return object
end

function SpawnSpooni(name, model, x, y, z, pitch, roll, yaw, collisionDisabled, isVisible, lightsIntensity, lightsColour, lightsType)
    if not Permissions.spawn.spooni then
        Logger.error('No permission to spawn spooni objects')
        return nil
    end

    if IsDatabaseFull() then
        Logger.error('Database is full')
        return nil
    end

    if not LoadModel(model) then
        Logger.error("Failed to load model: " .. tostring(name))
        return nil
    end

    local spooni = CreateObjectNoOffset(model, x, y, z, true, false, true)

    SetModelAsNoLongerNeeded(model)

    if not spooni or spooni < 1 then
        Logger.error('Failed to spawn spooni object')
        return nil
    end

    SetEntityRotation(spooni, pitch, roll, yaw, 2)
    FreezeEntityPosition(spooni, true)

    if collisionDisabled then
        SetEntityCollision(spooni, false, false)
    end

    if isVisible == false then
        SetEntityVisible(spooni, false)
    end

    if lightsIntensity then
        SetLightsIntensityForEntity(spooni, lightsIntensity)
    end

    if lightsColour then
        SetLightsColorForEntity(spooni, lightsColour.red, lightsColour.green, lightsColour.blue)
    end

    if lightsType then
        SetLightsTypeForEntity(spooni, lightsType)
    end

    AddEntityToDatabase(spooni, name)

    return spooni
end

function SpawnVehicle(name, model, x, y, z, pitch, roll, yaw, collisionDisabled, isVisible)
    if not Permissions.spawn.vehicle then
        Logger.error('No permission to spawn vehicles')
        return nil
    end

    if IsDatabaseFull() then
        Logger.error('Database is full')
        return nil
    end
    
    if IsEntityTypeLimitReached(2) then
        Logger.error('Vehicle limit reached')
        return nil
    end

    if not LoadModel(model) then
        Logger.error("Failed to load model: " .. tostring(name))
        return nil
    end

    local veh = CreateVehicle(model, x, y, z, 0.0, true, false)

    SetModelAsNoLongerNeeded(model)

    if not veh or veh < 1 then
        Logger.error('Failed to spawn vehicle')
        return nil
    end

    SetEntityRotation(veh, pitch, roll, yaw, 2)

    if collisionDisabled then
        FreezeEntityPosition(veh, true)
        SetEntityCollision(veh, false, false)
    end

    if isVisible == false then
        SetEntityVisible(veh, false)
    end

    -- Hotairballoon fix: needs AsNoLongerNeeded to move with wind
    if model == joaat('hotairballoon01') then
        SetVehicleAsNoLongerNeeded(veh)
    end

    AddEntityToDatabase(veh, name)


    return veh
end

function StartScenario(ped, scenario)
    TaskStartScenarioInPlace(ped, joaat(scenario), -1)
end

function PlayAnimation(ped, anim)
    if not DoesAnimDictExist(anim.dict) then
        return false
    end

    RequestAnimDict(anim.dict)

    while not HasAnimDictLoaded(anim.dict) do
        Wait(0)
    end

    TaskPlayAnim(ped, anim.dict, anim.name, anim.blendInSpeed, anim.blendOutSpeed, anim.duration, anim.flag, anim.playbackRate, false, false, false, '', false)

    RemoveAnimDict(anim.dict)

    return true
end

function SetWalkStyle(ped, base, style)
    Citizen.InvokeNative(0x923583741DC87BCE, ped, base)
    Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, style)

    if Database[ped] then
        Database[ped].walkStyle = {
            base = base,
            style = style
        }
    end
end

function SpawnPed(props)
    if not Permissions.spawn.ped then
        Logger.error('No permission to spawn peds')
        return nil
    end

    if IsDatabaseFull() then
        Logger.error('Database is full')
        return nil
    end
    
    if IsEntityTypeLimitReached(1) then
        Logger.error('Ped limit reached')
        return nil
    end
    
    if not LoadModel(props.model) then
        Logger.error("Failed to load model: " .. tostring(props.name))
        return nil
    end

    local ped = CreatePed_2(props.model, props.x, props.y, props.z, 0.0, true, false)

    SetModelAsNoLongerNeeded(props.model)

    if not ped or ped < 1 then
        Logger.error('Failed to spawn ped')
        return nil
    end

    SetEntityRotation(ped, props.pitch, props.roll, props.yaw, 2)

    if props.collisionDisabled then
        FreezeEntityPosition(ped, true)
        SetEntityCollision(ped, false, false)
    end

    if props.isVisible == false then
        SetEntityVisible(ped, false)
    end

    if props.outfit == -1 then
        SetRandomOutfitVariation(ped, true)
    else
        SetPedOutfitPreset(ped, props.outfit)
    end

    if props.isInGroup then
        AddToGroup(ped)
    end

    if props.animation then
        PlayAnimation(ped, props.animation)
    end

    if props.scenario then
        Wait(500)
        StartScenario(ped, props.scenario)
    end

    if props.blockNonTemporaryEvents then
        SetBlockingOfNonTemporaryEvents(ped, true)
    end

    if props.weapons then
        for _, weapon in ipairs(props.weapons) do
            GiveWeaponToPed_2(ped, joaat(weapon), 500, true, false, 0, false, 0.5, 1.0, 0, false, 0.0, false)
        end
    end

    if props.walkStyle then
        SetWalkStyle(ped, props.walkStyle.base, props.walkStyle.style)
    end

    if props.scale then
        SetPedScale(ped, props.scale)
    end

    if props.pedConfigFlags then
        for flag, value in pairs(props.pedConfigFlags) do
            SetPedConfigFlag(ped, tonumber(flag), value)
        end
    end

    AddEntityToDatabase(ped, props.name)
    Database[ped].outfit = props.outfit
    Database[ped].animation = props.animation
    Database[ped].scenario = props.scenario
    Database[ped].blockNonTemporaryEvents = props.blockNonTemporaryEvents
    Database[ped].weapons = props.weapons
    Database[ped].walkStyle = props.walkStyle
    Database[ped].scale = props.scale

    return ped
end

function WaitForPropSetToLoad(propSet)
    local timeWaited = 0

    while not IsPropSetFullyLoaded(propSet) and timeWaited <= 500 do
        Wait(100)
        timeWaited = timeWaited + 100
    end

    return true
end

function SpawnPropset(name, model, x, y, z, heading)
    if not Permissions.spawn.propset then
        Logger.error('No permission to spawn propsets')
        return nil
    end

    if IsDatabaseFull() then
        Logger.error('Database is full')
        return nil
    end

    RequestPropset(model)

    while not HasPropsetLoaded(model) do
        Wait(0)
    end

    local propset = CreatePropset(model, x, y, z, 0, heading, 0.0, false, false)

    ReleasePropset(hash)

    if not propset or propset < 1 then
        Logger.error('Failed to spawn propset')
        return nil
    end

    -- Load and wait for propset
    WaitForPropSetToLoad(propset)

    -- Clone propset objects into DB (created as new networked entities)
    local itemset = CreateItemset(true)
    local size = GetEntitiesFromPropset(propset, itemset, 0, false, false)

    if size > 0 then
        for i = 0, size - 1 do
            CloneEntity(GetIndexedItemInItemset(i, itemset))
        end
    end

    if IsItemsetValid(itemset) then
        DestroyItemset(itemset)
    end

    DeletePropset(propset, false, false)

    return nil
end

function SpawnPickup(name, model, x, y, z)
    if not Permissions.spawn.pickup then
        Logger.error('No permission to spawn pickups')
        return nil
    end

    if IsDatabaseFull() then
        Logger.error('Database is full')
        return nil
    end

    if not IsPickupTypeValid(model) then
        Logger.error('Invalid pickup type')
        return nil
    end

    local pickup = CreatePickup(model, x, y, z, 0, 0, false, 0, 0, 0.0, 0)

    if not pickup or pickup < 1 then
        Logger.error('Failed to spawn pickup')
        return nil
    end

    AddEntityToDatabase(pickup, name)
    Database[pickup].model = model
    Database[pickup].type = 5

    return pickup
end

function AddToGroup(ped)
    local group = GetPlayerGroup(PlayerId())
    SetPedAsGroupMember(ped, group)
    SetGroupSeparationRange(group, -1)
    SetPedCanTeleportToGroupLeader(ped, group, true)
    BlipAddForEntity(Config.Entity.GroupMemberBlipSprite, ped)
end
