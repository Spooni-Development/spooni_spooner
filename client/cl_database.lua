-- Entity database: stores spawned entities and their properties

function GetDatabaseEntry(entity)
    if not entity or entity == 0 then
        return nil
    end
    
    if not DoesEntityExist(entity) then
        Database[entity] = nil
        return nil
    end
    
    local entry = Database[entity]
    if entry and GetEntityType(entity) == entry.type then
        return entry
    end
    
    Database[entity] = nil
    return nil
end

function GetLiveEntityProperties(entity)
    local model = GetEntityModel(entity)
    local x, y, z = table.unpack(GetEntityCoords(entity))
    local pitch, roll, yaw = table.unpack(GetEntityRotation(entity, 2))
    local isPlayer = IsPedAPlayer(entity)
    local player = isPlayer and GetPlayerFromPed(entity)
    local type = GetEntityType(entity)

    return {
        name = GetModelName(model),
        type = type,
        model = model,
        x = x,
        y = y,
        z = z,
        pitch = pitch,
        roll = roll,
        yaw = yaw,
        health = GetEntityHealth(entity),
        outfit = -1,
        isInGroup = IsPedGroupMember(entity, GetPlayerGroup(PlayerId())),
        collisionDisabled = GetEntityCollisionDisabled(entity),
        blockNonTemporaryEvents = false,
        isSelf = entity == PlayerPedId(),
        playerName = player and GetPlayerName(player),
        weapons = {},
        isFrozen = IsEntityFrozen(entity),
        isVisible = IsEntityVisible(entity),
        pedConfigFlags = type == 1 and GetPedConfigFlags(entity) or nil,
        attachment = {
            to = GetEntityAttachedTo(entity),
            x = 0.0,
            y = 0.0,
            z = 0.0,
            pitch = 0.0,
            roll = 0.0,
            yaw = 0.0
        },
        netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity),
        exists = true
    }
end

function AddEntityToDatabase(entity, name, attachment)
    if not entity then
        return nil
    end

    if not name and Database[entity] then
        name = Database[entity].name
    end

    local model = Database[entity] and Database[entity].model
    local type = Database[entity] and Database[entity].type

    local outfit = Database[entity] and Database[entity].outfit or -1

    local attachBone, attachX, attachY, attachZ, attachPitch, attachRoll, attachYaw, attachSoftPinning, attachCollision, attachVertex, attachFixedRot

    local lightsIntensity = Database[entity] and Database[entity].lightsIntensity or nil
    local lightsColour = Database[entity] and Database[entity].lightsColour or nil
    local lightsType = Database[entity] and Database[entity].lightsType or nil

    local animation = Database[entity] and Database[entity].animation
    local scenario = Database[entity] and Database[entity].scenario

    local blockNonTemporaryEvents = Database[entity] and Database[entity].blockNonTemporaryEvents or false

    local weapons = Database[entity] and Database[entity].weapons or {}

    local walkStyle = Database[entity] and Database[entity].walkStyle

    local scale = Database[entity] and Database[entity].scale

    if attachment then
        attachBone        = attachment.bone
        attachX           = attachment.x
        attachY           = attachment.y
        attachZ           = attachment.z
        attachPitch       = attachment.pitch
        attachRoll        = attachment.roll
        attachYaw         = attachment.yaw
        attachSoftPinning = attachment.useSoftPinning
        attachCollision   = attachment.collision
        attachVertex      = attachment.vertex
        attachFixedRot    = attachment.fixedRot
    else
        attachBone        = (Database[entity] and Database[entity].attachment.bone)
        attachX           = (Database[entity] and Database[entity].attachment.x              or 0.0)
        attachY           = (Database[entity] and Database[entity].attachment.y              or 0.0)
        attachZ           = (Database[entity] and Database[entity].attachment.z              or 0.0)
        attachPitch       = (Database[entity] and Database[entity].attachment.pitch          or 0.0)
        attachRoll        = (Database[entity] and Database[entity].attachment.roll           or 0.0)
        attachYaw         = (Database[entity] and Database[entity].attachment.yaw            or 0.0)
        attachSoftPinning = (Database[entity] and Database[entity].attachment.useSoftPinning or false)
        attachCollision   = (Database[entity] and Database[entity].attachment.collision      or true)
        attachVertex      = (Database[entity] and Database[entity].attachment.vertex         or 0)
        attachFixedRot    = (Database[entity] and Database[entity].attachment.fixedRot       or true)
    end

    local isFrozen = Database[entity] and Database[entity].isFrozen

    Database[entity] = GetLiveEntityProperties(entity)

    if name then
        Database[entity].name = name
    end

    if model then
        Database[entity].model = model
    end

    if type then
        Database[entity].type = type
    end

    Database[entity].outfit = outfit

    Database[entity].attachment.bone = attachBone
    Database[entity].attachment.x = attachX
    Database[entity].attachment.y = attachY
    Database[entity].attachment.z = attachZ
    Database[entity].attachment.pitch = attachPitch
    Database[entity].attachment.roll = attachRoll
    Database[entity].attachment.yaw = attachYaw
    Database[entity].attachment.useSoftPinning = attachSoftPinning
    Database[entity].attachment.collision = attachCollision
    Database[entity].attachment.vertex = attachVertex
    Database[entity].attachment.fixedRot = attachFixedRot

    Database[entity].lightsIntensity = lightsIntensity
    Database[entity].lightsColour = lightsColour
    Database[entity].lightsType = lightsType

    Database[entity].animation = animation
    Database[entity].scenario = scenario

    Database[entity].blockNonTemporaryEvents = blockNonTemporaryEvents

    Database[entity].weapons = weapons

    Database[entity].walkStyle = walkStyle

    Database[entity].scale = scale
    
    -- Mark entity for active tracking (scenarios/animations)
    if scenario then
        MarkEntityAsActive(entity, 'scenario')
    end
    if animation then
        MarkEntityAsActive(entity, 'animation')
    end

    return Database[entity]
end

function RemoveEntityFromDatabase(entity)
    UnmarkEntityAsActive(entity, 'scenario')
    UnmarkEntityAsActive(entity, 'animation')
    Database[entity] = nil
end

function GetEntityPropertiesFromDatabase(entity)
    return AddEntityToDatabase(entity)
end

function EntityIsInDatabase(entity)
    return Database[entity] ~= nil
end

function GetEntityProperties(entity)
    if EntityIsInDatabase(entity) then
        return GetEntityPropertiesFromDatabase(entity)
    else
        return GetLiveEntityProperties(entity)
    end
end

function GetDatabaseSize()
    local n = 0
    for entity, props in pairs(Database) do
        n = n + 1
    end
    return n
end

function IsDatabaseFull()
    if not Permissions.maxEntities then
        return false
    end
    
    return GetDatabaseSize() >= Permissions.maxEntities
end

function IsEntityTypeLimitReached(entityType)
    if Permissions.noEntityLimit then
        return false
    end
    
    return false
end

function GetSpoonerEntityType(entity)
    local entry = GetDatabaseEntry(entity)
    return entry and entry.type or GetEntityType(entity)
end

function GetSpoonerEntityModel(entity)
    local entry = GetDatabaseEntry(entity)
    return entry and entry.model or GetEntityModel(entity)
end

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
        else
            local entry = GetDatabaseEntry(entity)
            if entry and entry.isSelf then
                RemoveEntityFromDatabase(entity)
            elseif entry then
                Database[entity].exists = false
            end
        end
    end

    for _, propset in ipairs(propsets) do
        if DoesPropsetExist(propset) then
            AddEntityToDatabase(propset)
        else
            local entry = GetDatabaseEntry(propset)
            if entry then
                Database[propset].exists = false
            end
        end
    end

    for _, pickup in ipairs(pickups) do
        if DoesPickupExist(pickup) then
            AddEntityToDatabase(pickup)
        else
            local entry = GetDatabaseEntry(pickup)
            if entry then
                Database[pickup].exists = false
            end
        end
    end
end

function CanDeleteEntity(entity)
    if EntityIsInDatabase(entity) then
        if NetworkGetEntityIsNetworked(entity) then
            return Permissions.delete.own.networked
        else
            return Permissions.delete.own.nonNetworked
        end
    else
        if NetworkGetEntityIsNetworked(entity) then
            return Permissions.delete.other.networked
        else
            return Permissions.delete.other.nonNetworked
        end
    end
end

function StoreDeletedEntity(entity)
    local props = GetLiveEntityProperties(entity)

    table.insert(DeletedEntities, {
        x = props.x,
        y = props.y,
        z = props.z,
        model = props.model,
        name = props.name,
        distance = 0.1
    })
end

function RemoveEntity(entity)
    if not CanDeleteEntity(entity) then
        Logger.error('No permission to delete this entity')
        return
    end

    if IsPedAPlayer(entity) then
        Logger.error('Cannot delete player ped')
        return
    end

    local entityType = GetSpoonerEntityType(entity)

    if entityType == 4 then
        DeletePropset(entity)
    elseif entityType == 5 then
        RemovePickup(entity)
    else
        if StoreDeleted and not EntityIsInDatabase(entity) then
            StoreDeletedEntity(entity)
        end

        RequestControl(entity)
        SetEntityAsMissionEntity(entity, true, true)
        DeleteEntity(entity)
    end

    RemoveEntityFromDatabase(entity)
end

function RemoveAllFromDatabase()
    local entities = {}
    for handle, info in pairs(Database) do
        table.insert(entities, handle)
    end
    
    local count = #entities
    for _, handle in ipairs(entities) do
        RemoveEntity(handle)
    end
    
    Logger.info("Database cleared: " .. count .. " entities")
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

function CloneEntity(entity)
    local props = GetEntityProperties(entity)
    local clone

    if props.type == 1 then
        clone = SpawnPed(props)
    elseif props.type == 2 then
        clone = SpawnVehicle(props.name, props.model, props.x, props.y, props.z, props.pitch, props.roll, props.yaw, props.collisionDisabled, props.isVisible)
    elseif props.type == 3 then
        clone = SpawnObject(props.name, props.model, props.x, props.y, props.z, props.pitch, props.roll, props.yaw, props.collisionDisabled, props.isVisible, props.lightsIntensity, props.lightsColour, props.lightsType)
    elseif props.type == 4 then
        clone = SpawnSpooni(props.name, props.model, props.x, props.y, props.z, props.pitch, props.roll, props.yaw, props.collisionDisabled, props.isVisible, props.lightsIntensity, props.lightsColour, props.lightsType)
    elseif props.type == 5 then
        clone = SpawnPickup(props.name, props.model, props.x, props.y, props.z)
    else
        return nil
    end

    if clone and props.attachment and props.attachment.to ~= 0 then
        AttachEntity(clone, props.attachment.to, props.attachment.bone, props.attachment.x, props.attachment.y, props.attachment.z, props.attachment.pitch, props.attachment.roll, props.attachment.yaw, props.attachment.useSoftPinning, props.attachment.collision, props.attachment.vertex, props.attachment.fixedRot)
    end

    return clone
end

function AttachEntity(from, to, bone, x, y, z, pitch, roll, yaw, useSoftPinning, collision, vertex, fixedRot)
    if not bone then
        bone = 0
    end

    local boneIndex = GetBoneIndex(to, bone)

    AttachEntityToEntity(from, to, boneIndex, x, y, z, pitch, roll, yaw, false, useSoftPinning, collision, false, vertex, fixedRot, false, false)

    if EntityIsInDatabase(from) then
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

-- KVS functions (Key-Value Storage)

function SaveDatabaseInKvs(name, db)
    SetResourceKvp('DB_' .. name, json.encode(db))
end

function LoadDatabaseFromKvs(name)
    return json.decode(GetResourceKvpString('DB_' .. name))
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
    Logger.success("Database saved: " .. name)
end
