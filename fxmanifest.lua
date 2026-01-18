fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

author 'Spooni'
description 'Reworked Entity spawner for RedM'
version '4'

files {
	'ui/index.html',
	'ui/css/*.css',
	'ui/js/*.js',
	'ui/img/*.svg',
	'ui/fonts/*.ttf',
}

ui_page 'ui/index.html'

server_scripts {
	'server/sv_main.lua',
	'server/sv_version.lua',
}

client_scripts {
	'@uiprompt/uiprompt.lua',
	'client/slaxml.lua',
	'client/cl_permissions.lua', -- Permission structure first
	'client/cl_utils.lua',       -- Utilities and Logger second
	'client/cl_database.lua',    -- Database functions third
	'client/cl_spawning.lua',    -- Spawning functions fourth
	'client/cl_converters.lua',  -- Import/Export converters fifth
	'client/callbacks/cl_callbacks_spawn.lua',
	'client/callbacks/cl_callbacks_database.lua',
	'client/callbacks/cl_callbacks_properties.lua',
	'client/callbacks/cl_callbacks_save_load.lua',
	'client/callbacks/cl_callbacks_utils.lua',
	'client/cl_camera.lua',      -- Camera system
	'client/cl_main.lua',        -- Main client code last
	'data/rdr3/*.lua',
}

shared_scripts {
	'shared/*.lua',
}

dependency 'uiprompt'
