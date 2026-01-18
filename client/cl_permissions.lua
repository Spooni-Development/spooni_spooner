-- Default permissions (restrictive) - Server provides ACE-based permissions via 'spooner:init' event

Permissions = {}

Permissions.maxEntities = 0

Permissions.spawn = {}
Permissions.spawn.ped = false
Permissions.spawn.vehicle = false
Permissions.spawn.object = false
Permissions.spawn.propset = false
Permissions.spawn.pickup = false
Permissions.spawn.spooni = false
Permissions.spawn.byName = false

Permissions.delete = {}
Permissions.delete.own = {}
Permissions.delete.own.networked = false
Permissions.delete.own.nonNetworked = false
Permissions.delete.other = {}
Permissions.delete.other.networked = false
Permissions.delete.other.nonNetworked = false

Permissions.modify = {}
Permissions.modify.own = {}
Permissions.modify.own.networked = false
Permissions.modify.own.nonNetworked = false
Permissions.modify.other = {}
Permissions.modify.other.networked = false
Permissions.modify.other.nonNetworked = false

Permissions.properties = {}
Permissions.properties.freeze = false
Permissions.properties.position = false
Permissions.properties.goTo = false
Permissions.properties.rotation = false
Permissions.properties.health = false
Permissions.properties.invincible = false
Permissions.properties.visible = false
Permissions.properties.gravity = false
Permissions.properties.collision = false
Permissions.properties.clone = false
Permissions.properties.attachments = false
Permissions.properties.lights = false
Permissions.properties.registerAsNetworked = false
Permissions.properties.focus = false

Permissions.properties.ped = {}
Permissions.properties.ped.changeModel = false
Permissions.properties.ped.outfit = false
Permissions.properties.ped.group = false
Permissions.properties.ped.scenario = false
Permissions.properties.ped.animation = false
Permissions.properties.ped.clearTasks = false
Permissions.properties.ped.weapon = false
Permissions.properties.ped.mount = false
Permissions.properties.ped.enterVehicle = false
Permissions.properties.ped.resurrect = false
Permissions.properties.ped.ai = false
Permissions.properties.ped.knockOffProps = false
Permissions.properties.ped.walkStyle = false

Permissions.properties.vehicle = {}
Permissions.properties.vehicle.changeModel = false
Permissions.properties.vehicle.repair = false
Permissions.properties.vehicle.fix = false
Permissions.properties.vehicle.getin = false
Permissions.properties.vehicle.engine = false
Permissions.properties.vehicle.driver = false
Permissions.properties.vehicle.passengers = false
Permissions.properties.vehicle.doorStatus = false
Permissions.properties.vehicle.paint = false
Permissions.properties.vehicle.livery = false
Permissions.properties.vehicle.tint = false
Permissions.properties.vehicle.extras = false

Permissions.noEntityLimit = false
