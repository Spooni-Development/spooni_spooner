-- Utility functions: validation, logging, RedM native wrappers

-- Centralized Logging System
Logger = {
    debug = function(msg, data)
        if Config.DevMode then
            print(string.format("[DEBUG] %s", msg))
            if data then 
                print(json.encode(data, {indent=true})) 
            end
        end
    end,
    
    error = function(msg, err)
        print(string.format("^1[ERROR]^7 %s", msg))
        if err then 
            print(debug.traceback()) 
        end
    end,
    
    info = function(msg)
        if Config.DevMode then
            print(string.format("[INFO] %s", msg))
        end
    end,
    
    warning = function(msg)
        if Config.DevMode then
            print(string.format("^3[WARNING]^7 %s", msg))
        end
    end,
    
    success = function(msg)
        if Config.DevMode then
            print(string.format("^2[SUCCESS]^7 %s", msg))
        end
    end
}

function ValidateNumber(value, min, max, default)
    local num = tonumber(value)
    if not num then return default end
    return math.max(min, math.min(max, num))
end

function ValidateEntity(entity)
    if not entity or type(entity) ~= 'number' then
        return false
    end
    return DoesEntityExist(entity)
end

function ValidateRotation(pitch, roll, yaw)
    return {
        pitch = ValidateNumber(pitch, -360, 360, 0),
        roll = ValidateNumber(roll, -360, 360, 0),
        yaw = ValidateNumber(yaw, -360, 360, 0)
    }
end

function ValidateCoords(x, y, z)
    local vx = tonumber(x)
    local vy = tonumber(y)
    local vz = tonumber(z)
    
    if not vx or not vy or not vz then
        return nil
    end
    
    return {x = vx, y = vy, z = vz}
end

-- RedM Native Wrapper

function SetLightsIntensityForEntity(entity, intensity)
    Citizen.InvokeNative(0x07C0F87AAC57F2E4, entity, intensity)
end

function SetLightsColorForEntity(entity, red, green, blue)
    Citizen.InvokeNative(0x6EC2A67962296F49, entity, red, green, blue)
end

function SetLightsTypeForEntity(entity, type)
    Citizen.InvokeNative(0xAB72C67163DC4DB4, entity, type)
end

function CreatePed_2(modelHash, x, y, z, heading, isNetwork, thisScriptCheck, p7, p8)
    return Citizen.InvokeNative(0xD49F9B0955C367DE, modelHash, x, y, z, heading, isNetwork, thisScriptCheck, p7, p8)
end

function SetRandomOutfitVariation(ped, p1)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, p1)
end

function BlipAddForEntity(blipHash, entity)
    return Citizen.InvokeNative(0x23F74C2FDA6E7C61, blipHash, entity)
end

function SetPedOnMount(ped, mount, seatIndex, p3)
    Citizen.InvokeNative(0x028F76B6E78246EB, ped, mount, seatIndex, p3)
end

function IsUsingKeyboard(padIndex)
    return Citizen.InvokeNative(0xA571D46727E2B718, padIndex)
end

function RequestPropset(hash)
    return Citizen.InvokeNative(0xF3DE57A46D5585E9, hash)
end

function ReleasePropset(hash)
    return Citizen.InvokeNative(0xB1964A83B345B4AB, hash)
end

function HasPropsetLoaded(hash)
    return Citizen.InvokeNative(0x48A88FC684C55FDC, hash)
end

function CreatePropset(hash, x, y, z, p4, p5, p6, p7, p8)
    return Citizen.InvokeNative(0xE65C5CBA95F0E510, hash, x, y, z, p4, p5, p6, p7, p8)
end

function DeletePropset(propSet, p1, p2)
    return Citizen.InvokeNative(0x58AC173A55D9D7B4, propSet, p1, p2)
end

function DoesPropsetExist(propSet)
    return Citizen.InvokeNative(0x7DDDCF815E650FF5, propSet)
end

function GetEntitiesFromPropset(propSet, itemSet, p2, p3, p4)
    return Citizen.InvokeNative(0x738271B660FE0695, propSet, itemSet, p2, p3, p4)
end

function IsPickupTypeValid(pickupHash)
    return Citizen.InvokeNative(0x007BD043587F7C82, pickupHash)
end

function IsEntityFrozen(entity)
    return Citizen.InvokeNative(0x083D497D57B7400F, entity)
end

function IsPedUsingScenarioHash(ped, scenarioHash)
    return Citizen.InvokeNative(0x34D6AC1157C8226C, ped, scenarioHash)
end

function IsPropSetFullyLoaded(propSet)
    return Citizen.InvokeNative(0xF42DB680A8B2A4D9, propSet)
end

function PlaceEntityOnGroundProperly(entity, p1)
    return Citizen.InvokeNative(0x9587913B9E772D29, entity, p1)
end


function GetBoneIndex(entity, bone)
    if type(bone) == 'number' then
        return bone
    else
        return GetEntityBoneIndexByName(entity, bone)
    end
end

function FindBoneName(entity, boneIndex)
    for _, boneName in ipairs(Bones) do
        if GetEntityBoneIndexByName(entity, boneName) == boneIndex then
            return boneName
        end
    end
    return boneIndex
end

function GetPedConfigFlags(ped)
    local flags = {}
    for i = 0, 600 do
        flags[i] = GetPedConfigFlag(ped, i)
    end
    return flags
end

function CheckControls(func, pad, controls)
    if type(controls) == 'number' then
        return func(pad, controls)
    end

    for _, control in ipairs(controls) do
        if func(pad, control) then
            return true
        end
    end

    return false
end

function GetPlayerFromPed(ped)
    for _, playerId in ipairs(GetActivePlayers()) do
        if ped == GetPlayerPed(playerId) then
            return playerId
        end
    end
    return nil
end

function GetModelName(model)
    if PedsHashLookup[model] then
        return PedsHashLookup[model]
    end

    if VehiclesHashLookup[model] then
        return VehiclesHashLookup[model]
    end

    if ObjectsHashLookup[model] then
        return ObjectsHashLookup[model]
    end
    
    if SpooniHashLookup[model] then
        return SpooniHashLookup[model]
    end

    if PickupsHashLookup[model] then
        return PickupsHashLookup[model]
    end

    return tostring(model)
end

function LoadModel(model)
    if IsModelInCdimage(model) then
        Logger.debug("[Model] Loading: " .. tostring(model) .. " (hash: " .. GetHashKey(model) .. ")")
        RequestModel(model)

        while not HasModelLoaded(model) do
            Wait(0)
        end

        Logger.debug("[Model] Loaded successfully: " .. tostring(model))
        return true
    else
        Logger.debug("[Model] Not found in CdImage: " .. tostring(model))
        return false
    end
end

function RequestControl(entity)
    local type = GetEntityType(entity)

    if type < 1 or type > 3 then
        return
    end

    if DoesEntityExist(entity) and not NetworkHasControlOfEntity(entity) then
        NetworkRequestControlOfEntity(entity)

        local t = 100

        while not NetworkHasControlOfEntity(entity) and t > 0 do 
            Wait(0)
            t = t - 1
        end
    end
end

function GetTeleportTarget()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local mnt = GetMount(ped)
    return (veh == 0 and (mnt == 0 and ped or mnt) or veh)
end

function TeleportToCoords(x, y, z, h)
    local ent = GetTeleportTarget()
    FreezeEntityPosition(ent, true)
    SetEntityCoords(ent, x, y, z, 0, 0, 0, 0, 0)
    SetEntityHeading(ent, h)
    FreezeEntityPosition(ent, false)
end

function PlaceOnGroundProperly(entity)
    local r1 = GetEntityRotation(entity, 2)
    PlaceEntityOnGroundProperly(entity, false)

    local r2 = GetEntityRotation(entity, 2)
    SetEntityRotation(entity, r2.x, r2.y, r1.z, 2)
end

function PlacePedOnGroundProperly(ped)
    local x, y, z = table.unpack(GetEntityCoords(ped))
    local found, groundz, normal = GetGroundZAndNormalFor_3dCoord(x, y, z)
    if found then
        SetEntityCoordsNoOffset(ped, x, y, groundz + normal.z, true)
    end
end

function GetInView(x1, y1, z1, pitch, roll, yaw)
    local rx = -math.sin(math.rad(yaw)) * math.abs(math.cos(math.rad(pitch)))
    local ry =  math.cos(math.rad(yaw)) * math.abs(math.cos(math.rad(pitch)))
    local rz =  math.sin(math.rad(pitch))

    local x2 = x1 + rx * 10000.0
    local y2 = y1 + ry * 10000.0
    local z2 = z1 + rz * 10000.0

    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(StartShapeTestRay(x1, y1, z1, x2, y2, z2, -1, -1, 1))

    if entityHit <= 0 or GetEntityType(entityHit) == 0 then
        return endCoords, nil, 0
    end

    local entityCoords = GetEntityCoords(entityHit)
    local distance = #(vector3(x1, y1, z1) - entityCoords)

    if distance >= 100.0 then
        return endCoords, nil, distance
    end

    return endCoords, entityHit, distance
end

function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(0, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Citizen.Wait(100)
        return result or false
    else
        Citizen.Wait(100)
        return false
    end
end

function GetIndexedHashList(List)
    local NewList = {}
    for _, v in ipairs(List) do
        NewList[joaat(v)] = v
    end
    return NewList
end


