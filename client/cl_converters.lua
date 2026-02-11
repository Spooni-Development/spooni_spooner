-- Import/Export: JSON, XML, Ymap, Script, Offset, Backup formats

local function joaat_hash(input)
    local hash = 0
    for i = 1, #input do
        local char = string.byte(input, i)
        hash = (hash + char) & 0xFFFFFFFF
        hash = (hash + (hash << 10)) & 0xFFFFFFFF
        hash = (hash ~ (hash >> 6)) & 0xFFFFFFFF
    end
    hash = (hash + (hash << 3)) & 0xFFFFFFFF
    hash = (hash ~ (hash >> 11)) & 0xFFFFFFFF
    hash = (hash + (hash << 15)) & 0xFFFFFFFF
    return hash & 0xFFFFFFFF
end

local doorCounter = 1

function GenerateDoorhashText(baseText)
    local doorhash_text = baseText .. "-" .. doorCounter
    doorCounter = doorCounter + 1
    return doorhash_text
end

function ConvertDatabaseToDoorhash(database, content)
    local baseText = KeyboardInput("Enter the base name for the doorhashes:", "", 50)

    if not baseText then return content end

    local original_string = content
    local result = original_string:gsub('(<Item type="CEntityDef">.-<archetypeName>(.-)</archetypeName>.-<artificialAmbientOcclusion value="255"/>%s*)',function(item, archetypeName)
		local doorhash_text = GenerateDoorhashText(baseText)
		local doorhash = joaat_hash(doorhash_text)
		local extensions_block = [[
			<extensions>
				<Item type="CExtensionDefDoor">
					<name>]] .. archetypeName .. [[</name>
					<offsetPosition x="0" y="0" z="0" />
					<ELUGHoA_0xDAF8214E value="false" />
					<enableLimitAngle value="true" />
					<EFwMwAA_0x091A42D0 value="false" />
					<startsLocked value="false" />
					<canBreak value="false" />
					<PkpciBA_0xA37CAB71 value="false" />
					<dKbmTLA_0xCFE37BDB value="1.570796" />
					<nuskEbA_0xA0CF3C8D value="1.570796" />
					<RbUnQLA_0x9C555ECF value="0" />
					<OPkNlHA_0xBCA0289E value="0" />
					<doorTargetRatio value="0" />
					<audioHash>ismdclsa_0x725d11b6</audioHash>
					<doorTags>
						<Item />
						<Item />
						<Item />
						<Item />
					</doorTags>
				</Item>
				<Item type="SSxlGTA_0xDB12012B">
					<name>]] .. archetypeName .. [[</name>
					<offsetPosition x="0" y="0" z="0" />
					<Id>]] .. doorhash_text .. [[</Id> <!-- hash = ]] .. doorhash .. [[ -->
				</Item>
			</extensions>
		]]

		local flags = 1572865
		local lodDist = 150
		local childLodDist = 0
		local modified_item = item
			:gsub('<flags value="%d+"/>', '<flags value="' .. flags .. '"/>')
			:gsub('<lodDist value="%d+"/>', '<lodDist value="' .. lodDist .. '"/>')
			:gsub('<childLodDist value="%d+"/>', '<childLodDist value="' .. childLodDist .. '"/>')

		return modified_item .. extensions_block
	end)

    doorCounter = 1
    return result
end

function ConvertDatabaseToMapEditorXml(creator, database)
	local xml = '<?xml version="1.0"?>\n<Map>\n\t<MapMeta Creator="' .. creator .. '"/>\n'

	for _, properties in ipairs(database.delete) do
		xml = xml .. string.format('\t<DeletedObject Hash="%s" Position_x="%s" Position_y="%s" Position_z="%s"/>\n', properties.model, properties.x, properties.y, properties.z)
	end

	for entity, properties in pairs(database.spawn) do
		if properties.type == 1 then
			xml = xml .. string.format('\t<Ped Hash="%s" Position_x="%s" Position_y="%s" Position_z="%s" Rotation_x="%s" Rotation_y="%s" Rotation_z="%s" Preset="%d" Collision="%s" Visible="%s"/>\n', properties.model, properties.x, properties.y, properties.z, properties.pitch, properties.roll, properties.yaw, properties.outfit, properties.collisionDisabled and "false" or "true", properties.isVisible and "true" or "false")
		elseif properties.type == 2 then
			xml = xml .. string.format('\t<Vehicle Hash="%s" Position_x="%s" Position_y="%s" Position_z="%s" Rotation_x="%s" Rotation_y="%s" Rotation_z="%s" Collision="%s" Visible="%s"/>\n', properties.model, properties.x, properties.y, properties.z, properties.pitch, properties.roll, properties.yaw, properties.collisionDisabled and "false" or "true", properties.isVisible and "true" or "false")
		else
			xml = xml .. string.format('\t<Object Hash="%s" Position_x="%s" Position_y="%s" Position_z="%s" Rotation_x="%s" Rotation_y="%s" Rotation_z="%s" Collision="%s" Visible="%s"/>\n', properties.model, properties.x, properties.y, properties.z, properties.pitch, properties.roll, properties.yaw, properties.collisionDisabled and "false" or "true", properties.isVisible and "true" or "false")
		end
	end

	xml = xml .. '</Map>'

	return xml
end

local function toQuaternion(pitch, roll, yaw)
	local rot = -vector3(roll, pitch, yaw)

	local p = math.rad(rot.y)
	local r = math.rad(rot.z)
	local y = math.rad(rot.x)

	local cy = math.cos(y * 0.5)
	local sy = math.sin(y * 0.5)
	local cr = math.cos(r * 0.5)
	local sr = math.sin(r * 0.5)
	local cp = math.cos(p * 0.5)
	local sp = math.sin(p * 0.5)

	local q = {}

	q.x = cy * sp * cr + sy * cp * sr
	q.y = sy * cp * cr - cy * sp * sr
	q.z = cy * cp * sr - sy * sp * cr
	q.w = cy * cp * cr + sy * sp * sr

	return q
end

function ConvertDatabaseToYmap(database)
	local minX, maxX, minY, maxY, minZ, maxZ

	local entitiesXml = '\t<entities>\n'

	for entity, properties in pairs(database.spawn) do
		if properties.type == 3 then
			local q = toQuaternion(properties.pitch, properties.roll, properties.yaw)

			if not minX or properties.x < minX then
				minX = properties.x
			end
			if not maxX or properties.x > maxX then
				maxX = properties.x
			end
			if not minY or properties.y < minY then
				minY = properties.y
			end
			if not maxY or properties.y > maxY then
				maxY = properties.y
			end
			if not minZ or properties.z < minZ then
				minZ = properties.z
			end
			if not maxZ or properties.z > maxZ then
				maxZ = properties.z
			end

			local flags = 1572865

			if properties.isFrozen then
				flags = flags + 32
			end

			entitiesXml = entitiesXml .. '\t\t<Item type="CEntityDef">\n'
			entitiesXml = entitiesXml .. '\t\t\t<archetypeName>' .. properties.name .. '</archetypeName>\n'
			entitiesXml = entitiesXml .. '\t\t\t<flags value="' .. flags .. '"/>\n'
			entitiesXml = entitiesXml .. string.format('\t\t\t<position x="%f" y="%f" z="%f"/>\n', properties.x, properties.y, properties.z)
			entitiesXml = entitiesXml .. string.format('\t\t\t<rotation w="%f" x="%f" y="%f" z="%f"/>\n', q.w, q.x, q.y, q.z)
			entitiesXml = entitiesXml .. '\t\t\t<scaleXY value="1"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<scaleZ value="1"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<parentIndex value="-1"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<lodDist value="150"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<childLodDist value="0"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<lodLevel>LODTYPES_DEPTH_HD</lodLevel>\n'
			entitiesXml = entitiesXml .. '\t\t\t<numChildren value="0"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<ambientOcclusionMultiplier value="255"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<artificialAmbientOcclusion value="255"/>\n'
			entitiesXml = entitiesXml .. '\t\t</Item>\n'
		end
	end

	entitiesXml = entitiesXml .. '\t</entities>\n'

	local xml = '<?xml version="1.0"?>\n<CMapData>\n\t<flags value="2"/>\n\t<contentFlags value="65"/>\n'

	if minX and minY and minZ and maxX and maxY and maxZ then
		xml = xml .. string.format('\t<streamingExtentsMin x="%f" y="%f" z="%f"/>\n', minX - 400, minY - 400, minZ - 400)
		xml = xml .. string.format('\t<streamingExtentsMax x="%f" y="%f" z="%f"/>\n', maxX + 400, maxY + 400, maxZ + 400)
		xml = xml .. string.format('\t<entitiesExtentsMin x="%f" y="%f" z="%f"/>\n', minX - 50, minY - 50, minZ - 50)
		xml = xml .. string.format('\t<entitiesExtentsMax x="%f" y="%f" z="%f"/>\n', maxX + 50, maxY + 50, maxZ + 50)

		xml = xml .. entitiesXml
	end

	xml = xml .. '</CMapData>'

	return xml
end

function ConvertDatabaseToMlo(database)
	local minX, maxX, minY, maxY, minZ, maxZ

	local entitiesXml = '\t<entities>\n'

	for entity, properties in pairs(database.spawn) do
		if properties.type == 3 then
			local q = toQuaternion(properties.pitch, properties.roll, properties.yaw)
			
			properties.z2 = properties.z - (120.0000)

			if not minX or properties.x < minX then
				minX = properties.x
			end
			if not maxX or properties.x > maxX then
				maxX = properties.x
			end
			if not minY or properties.y < minY then
				minY = properties.y
			end
			if not maxY or properties.y > maxY then
				maxY = properties.y
			end
			if not minZ or properties.z2 < minZ then
				minZ = properties.z2
			end
			if not maxZ or properties.z2 > maxZ then
				maxZ = properties.z2
			end

			local flags = 1572865

			if properties.isFrozen then
				flags = flags + 32
			end

			entitiesXml = entitiesXml .. '\t\t<Item type="CEntityDef">\n'
			entitiesXml = entitiesXml .. '\t\t\t<archetypeName>' .. properties.name .. '</archetypeName>\n'
			entitiesXml = entitiesXml .. '\t\t\t<flags value="' .. flags .. '"/>\n'
			entitiesXml = entitiesXml .. string.format('\t\t\t<position x="%f" y="%f" z="%f"/>\n', properties.x, properties.y, properties.z2)
			entitiesXml = entitiesXml .. string.format('\t\t\t<rotation w="%f" x="%f" y="%f" z="%f"/>\n', q.w, q.x, q.y, q.z)
			entitiesXml = entitiesXml .. '\t\t\t<scaleXY value="1"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<scaleZ value="1"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<parentIndex value="-1"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<lodDist value="30"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<childLodDist value="0"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<lodLevel>LODTYPES_DEPTH_HD</lodLevel>\n'
			entitiesXml = entitiesXml .. '\t\t\t<numChildren value="0"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<ambientOcclusionMultiplier value="255"/>\n'
			entitiesXml = entitiesXml .. '\t\t\t<artificialAmbientOcclusion value="255"/>\n'
			entitiesXml = entitiesXml .. '\t\t</Item>\n'
		end
	end

	entitiesXml = entitiesXml .. '\t</entities>\n'

	local xml = '<?xml version="1.0"?>\n<CMapData>\n\t<flags value="2"/>\n\t<contentFlags value="65"/>\n'

	if minX and minY and minZ and maxX and maxY and maxZ then
		xml = xml .. string.format('\t<streamingExtentsMin x="%f" y="%f" z="%f"/>\n', minX - 400, minY - 400, minZ - 400)
		xml = xml .. string.format('\t<streamingExtentsMax x="%f" y="%f" z="%f"/>\n', maxX + 400, maxY + 400, maxZ + 400)
		xml = xml .. string.format('\t<entitiesExtentsMin x="%f" y="%f" z="%f"/>\n', minX - 50, minY - 50, minZ - 50)
		xml = xml .. string.format('\t<entitiesExtentsMax x="%f" y="%f" z="%f"/>\n', maxX + 50, maxY + 50, maxZ + 50)

		xml = xml .. entitiesXml
	end

	xml = xml .. '</CMapData>'

	return xml
end

function ConvertDatabaseToScript(database)
	local entitiesXml = ''

	for entity, properties in pairs(database.spawn) do
		if properties.type == 3 then
			entitiesXml = entitiesXml .. '\t{\n'
			entitiesXml = entitiesXml .. '\t\tmodel = `' .. properties.name .. '`,\n'
			entitiesXml = entitiesXml .. string.format('\t\tcoords = vec3(%f,%f,%f),\n', properties.x, properties.y, properties.z)
			entitiesXml = entitiesXml .. string.format('\t\trotation = vec3(%f,%f,%f),\n', properties.pitch, properties.roll, properties.yaw)
			entitiesXml = entitiesXml .. '\t},\n'
		end
	end

	local xml = 'objects = {\n'
	xml = xml .. entitiesXml
	xml = xml .. '}'

	return xml
end

function ConvertDatabaseToScriptDeleter(database)
    local entitiesXml = ''

    for entity, properties in pairs(database.delete) do
        entitiesXml = entitiesXml .. '\t{\n'
        entitiesXml = entitiesXml .. '\t\tmodel = `' .. properties.name .. '`,\n'
        entitiesXml = entitiesXml .. string.format('\t\tcoords = vec3(%f,%f,%f),\n', properties.x, properties.y, properties.z)
        entitiesXml = entitiesXml .. '\t\tdistance = ' .. properties.distance .. ',\n'
        entitiesXml = entitiesXml .. '\t},\n'
    end

    local xml = 'objects = {\n'
    xml = xml .. entitiesXml
    xml = xml .. '}'

    return xml
end

function ConvertDatabaseToOffset(database)
	local entities = {}
	local count = 0
	local firstEntity = nil
	for entity, properties in pairs(database.spawn) do
		local currentEntity = tonumber(entity)
		if properties.type == 3 and DoesEntityExist(currentEntity) then
			count = count + 1
			if count == 1 then
				firstEntity = currentEntity
			end
			local x, y, z = table.unpack(GetEntityCoords(firstEntity))
			local x1, y1, z1 = table.unpack(GetEntityCoords(currentEntity))
			local coords = vector3(x1 - x, y1 - y, (z1 - z))

			entities[#entities+1] = {
				model = properties.name,
				offset = {x = coords.x, y = coords.y, z = coords.z},
				rotation = { x = properties.pitch, y = properties.roll, z = properties.yaw},
				isFrozen = properties.isFrozen,
			}
		end
	end

	return json.encode(entities)
end

function ConvertDatabaseToPropPlacerJson(database)
	local props = {}

	for entity, properties in pairs(database.spawn) do
		props[properties.yaw .. '-' .. properties.x] = {
			prophash = properties.model,
			x = properties.x,
			y = properties.y,
			z = properties.z,
			heading = properties.yaw
		}
	end

	return json.encode(props)
end

function BackupDbs()
	local dbs = {}

	for _, name in ipairs(GetSavedDatabases()) do
		dbs[name] = LoadDatabaseFromKvs(name)
	end

	return json.encode(dbs)
end

function RestoreDbs(content)
	local dbs = json.decode(content)

	for name, db in pairs(dbs) do
		SaveDatabaseInKvs(name, db)
	end
end

local function loadOffset(file)
	local data = json.decode(file)
	local db = {}
	local coords = GetEntityCoords(PlayerPedId())
	for index, value in ipairs(data) do
		db[#db+1] = {
			name = value.model,
			model = joaat(value.model),
			isFrozen = value.isFrozen,
			x = value.offset.x+coords.x,
			y = value.offset.y+coords.y,
			z = value.offset.z+coords.z,
			pitch = value.rotation.x,
			roll = value.rotation.y,
			yaw = value.rotation.z,
		}
	end

	DisableSpoonerMode()
	LoadDatabase(db, false, false, true)
end

local function loadYmap(xml)
	local curElem, isEntity

	local db = {}
	local i = 0
	local key = "0"

	local parser = SLAXML:parser {
		startElement = function(name, nsURI, nsPrefix)
			curElem = name
		end,
		attribute = function(name, value, nsURI, nsPrefix)
			if name == "type" and value == "CEntityDef" then
				isEntity = true
				db[key] = {
					quaternion = {},
					x = 0.0,
					y = 0.0,
					z = 0.0,
					pitch = 0.0,
					roll = 0.0,
					yaw = 0.0
				}
			elseif curElem == "position" then
				value = (tonumber(value) or 0) + 0.0
				if name == "x" then
					db[key].x = value
				elseif name == "y" then
					db[key].y = value
				elseif name == "z" then
					db[key].z = value
				end
			elseif curElem == "rotation" then
				db[key].quaternion[name] = (tonumber(value) or 0) + 0.0
			elseif isEntity and curElem == "flags" and name == "value" then
				value = tonumber(value) or 0
				db[key].isFrozen = (value & 32) == 32
			end
		end,
		closeElement = function(name, nsURI)
			if isEntity and name == "Item" then
				isEntity = false
				i = i + 1
				key = tostring(i)
			end
			curElem = nil
		end,
		text = function(text, cdata)
			if isEntity then
				if curElem == "archetypeName" then
					db[key].name = text
					db[key].model = joaat(text)
				end
			end
		end
	}

	parser:parse(xml, {stripWhitespace=true})

	LoadDatabase(db, false, false)
end

local function loadXml(xml)
    local curElem, isEntity

    local db = {spawn = {}, delete = {}}
    local i = 0
    local key = "0"

    local parser = SLAXML:parser {
        startElement = function(name, nsURI, nsPrefix)
            curElem = name
        end,
        attribute = function(name, value, nsURI, nsPrefix)
            if curElem == "DeletedObject" then
                if not db.delete[key] then
                    db.delete[key] = {
						quaternion = {},
                        x = 0.0,
                        y = 0.0,
                        z = 0.0,
                        pitch = 0.0,
                        roll = 0.0,
                        yaw = 0.0
                    }
                end
				if name == "Position_x" then
                    db.delete[key].x = tonumber(value) or 0.0
                elseif name == "Position_y" then
                    db.delete[key].y = tonumber(value) or 0.0
                elseif name == "Position_z" then
                    db.delete[key].z = tonumber(value) or 0.0
                elseif name == "Rotation_x" then
                    db.delete[key].pitch = tonumber(value) or 0.0
                elseif name == "Rotation_y" then
                    db.delete[key].roll = tonumber(value) or 0.0
                elseif name == "Rotation_z" then
                    db.delete[key].yaw = tonumber(value) or 0.0
                elseif name == "Rotation_w" then
                    db.delete[key].quaternion.w = tonumber(value) or 0.0
                elseif name == "Rotation_qx" then
                    db.delete[key].quaternion.x = tonumber(value) or 0.0
                elseif name == "Rotation_qy" then
                    db.delete[key].quaternion.y = tonumber(value) or 0.0
                elseif name == "Rotation_qz" then
                    db.delete[key].quaternion.z = tonumber(value) or 0.0
                elseif name == "Hash" then
                    db.delete[key].model = tonumber(value) or joaat(value)
					db.delete[key].name = GetModelName(db.delete[key].model)
					db.delete[key].distance = 1.0
                elseif name == "Collision" then
                    db.delete[key].collisionDisabled = value == "false"
                elseif name == "Visible" then
                    db.delete[key].isVisible = value == "true"
                end
                db.delete[key][name] = tonumber(value) or value
            elseif curElem == "Object" then
                if not db.spawn[key] then
                    db.spawn[key] = {
                        quaternion = {},
                        x = 0.0,
                        y = 0.0,
                        z = 0.0,
                        pitch = 0.0,
                        roll = 0.0,
                        yaw = 0.0
                    }
                end
                if name == "Position_x" then
                    db.spawn[key].x = tonumber(value) or 0.0
                elseif name == "Position_y" then
                    db.spawn[key].y = tonumber(value) or 0.0
                elseif name == "Position_z" then
                    db.spawn[key].z = tonumber(value) or 0.0
                elseif name == "Rotation_x" then
                    db.spawn[key].pitch = tonumber(value) or 0.0
                elseif name == "Rotation_y" then
                    db.spawn[key].roll = tonumber(value) or 0.0
                elseif name == "Rotation_z" then
                    db.spawn[key].yaw = tonumber(value) or 0.0
                elseif name == "Rotation_w" then
                    db.spawn[key].quaternion.w = tonumber(value) or 0.0
                elseif name == "Rotation_qx" then
                    db.spawn[key].quaternion.x = tonumber(value) or 0.0
                elseif name == "Rotation_qy" then
                    db.spawn[key].quaternion.y = tonumber(value) or 0.0
                elseif name == "Rotation_qz" then
                    db.spawn[key].quaternion.z = tonumber(value) or 0.0
                elseif name == "Hash" then
                    db.spawn[key].model = tonumber(value) or joaat(value)
                elseif name == "Collision" then
                    db.spawn[key].collisionDisabled = value == "false"
                elseif name == "Visible" then
                    db.spawn[key].isVisible = value == "true"
                end
            end
        end,
        closeElement = function(name, nsURI)
            if name == "DeletedObject" then
                i = i + 1
                key = tostring(i)
            elseif name == "Object" then
                i = i + 1
                key = tostring(i)
            end
            curElem = nil
        end,
        text = function(text, cdata)
        end
    }

    parser:parse(xml, {stripWhitespace=true})

    for key, props in pairs(db.delete) do
        local x, y, z = props.x, props.y, props.z
        local model = props.model
        local closestObject = GetClosestObjectOfType(x, y, z, 1.0, model, false, false, false)
        if DoesEntityExist(closestObject) then
            DeleteEntity(closestObject)
        end
    end

    LoadDatabase(db, false, false)
end

local function cleanXml(xml)
	xml = xml:gsub("Config%s*=%s*{}", "")
    xml = xml:gsub("}%s*Config%.Objects%d*%s*=%s*{", ",")
    xml = xml:gsub("Config%.Objects%d*%s*=%s*{", "{")
    xml = xml:gsub("^objects%s*=%s*", "")
    xml = xml:gsub(",%s*}", ",}") 
    xml = xml:gsub("^%s*,", "")
    xml = xml:gsub(",%s*$", "")

    return xml
end

local function loadScript(xml)
	xml = cleanXml(xml)
    local func, err = load("Return " .. xml)
    if not func then
        Logger.error("[XML] Error converting to lua table: " .. err)
        return
    end

    local parsedXml = func()
    if not parsedXml then
        Logger.debug("[XML] Failed to load parsed XML data")
        return
    end
    local db = { spawn = {} }
    local i = 0

    for _, object in ipairs(parsedXml) do
        if object.coords and object.coords.x and object.coords.y and object.coords.z and
           object.rotation and object.rotation.x and object.rotation.y and object.rotation.z then
            i = i + 1
            local key = tostring(i)

            db.spawn[key] = {
                quaternion = {},
                props = {
                    x = object.coords.x,
                    y = object.coords.y,
                    z = object.coords.z,
                    pitch = object.rotation.x,
                    roll = object.rotation.y,
                    yaw = object.rotation.z,
                    model = joaat(object.model),
                    collisionDisabled = false,
                    isVisible = true
                }
            }
        else
            Logger.debug("[XML] Skipping object with missing values")
        end
    end
	local dataType = "script"
    LoadDatabase(db, false, false, false, dataType)
end

function ExportDatabase(format, content)
	UpdateDatabase()
	local db = PrepareDatabaseForSave()

	local result
	if format == 'spooner-db-json' then
		result = json.encode(db)
	elseif format == 'map-editor-xml' then
		result = ConvertDatabaseToMapEditorXml(GetPlayerName(), db)
	elseif format == 'ymap' then
		result = ConvertDatabaseToYmap(db)
	elseif format == 'mlo' then
		result = ConvertDatabaseToMlo(db)
	elseif format == 'script' then
		result = ConvertDatabaseToScript(db)
	elseif format == 'script-deleter' then
		result = ConvertDatabaseToScriptDeleter(db)
	elseif format == 'offset' then
		result = ConvertDatabaseToOffset(db)
	elseif format == 'propplacer' then
		result = ConvertDatabaseToPropPlacerJson(db)
	elseif format == 'doorhash' then
		result = ConvertDatabaseToDoorhash(db, content)
	elseif format == 'backup' then
		result = BackupDbs()
	end

	if result then
		local count = 0
		for _ in pairs(Database) do count = count + 1 end
		Logger.success("Database exported: " .. count .. " entities")
		Logger.debug("[Export] Format: " .. format .. ", Entities: " .. count)
	else
		Logger.error('Export failed')
		Logger.error("[Export] Failed, format: " .. format)
	end

	return result
end

function ImportDatabase(format, content)
	if not format or not content then
		Logger.error('Invalid import data')
		return false
	end
	
	local success = pcall(function()
		if format == 'spooner-db-json' then
			local db = json.decode(content)
			if db then
				LoadDatabase(db, false, false)
				local count = 0
				for _ in pairs(Database) do count = count + 1 end
				Logger.success("Database imported: " .. count .. " entities")
				Logger.debug("[Import] Format: JSON, Entities: " .. count)
			else
				Logger.error('Import failed: Invalid JSON')
			end
		elseif format == 'backup' then
			RestoreDbs(content)
			Logger.success('Backup restored')
			Logger.debug("[Import] Format: Backup")
		elseif format == 'ymap' then
			loadYmap(content)
			local count = 0
			for _ in pairs(Database) do count = count + 1 end
			Logger.success("Ymap imported: " .. count .. " entities")
			Logger.debug("[Import] Format: Ymap, Entities: " .. count)
		elseif format == 'map-editor-xml' then
			loadXml(content)
			local count = 0
			for _ in pairs(Database) do count = count + 1 end
			Logger.success("XML imported: " .. count .. " entities")
			Logger.debug("[Import] Format: XML, Entities: " .. count)
		elseif format == 'offset' then
			loadOffset(content)
			local count = 0
			for _ in pairs(Database) do count = count + 1 end
			Logger.success("Offset imported: " .. count .. " entities")
			Logger.debug("[Import] Format: Offset, Entities: " .. count)
		elseif format == 'script' then
			loadScript(content)
			local count = 0
			for _ in pairs(Database) do count = count + 1 end
			Logger.success("Script imported: " .. count .. " entities")
			Logger.debug("[Import] Format: Script, Entities: " .. count)
		else
			Logger.error('Import failed: Unknown format')
			Logger.debug("[Import] Unknown format: " .. tostring(format))
		end
	end)
	
	if not success then
		Logger.error('Import failed')
		Logger.debug("[Import] Exception occurred during import")
		return false
	end
	
	return true
end
