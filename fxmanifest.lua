fx_version 'adamant'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

author 'Spooni'
description 'Reworked Entity spawner for RedM'
version '4'

files {
	'ui/index.html',
	'ui/*.css',
	'ui/*.js',
	'ui/img/*.svg',
	'ui/fonts/*.ttf',
}

ui_page 'ui/index.html'

server_scripts {
	'server/*.lua',
}

client_scripts {
	'@uiprompt/uiprompt.lua',
	'client/slaxml.lua',
	'client/client.lua',
	'data/rdr3/*.lua',
}

shared_scripts {
	'shared/*.lua',
}

dependency 'uiprompt'
