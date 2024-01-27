fx_version "cerulean"
game 'rdr3'
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

name "spooni_spooner"
author "i3ucky"
description "Reworked Entity spawner for RedM"
repository "https://github.com/i3ucky/spooni_spooner"

files {
	"ui/index.html",
	"ui/*.css",
	"ui/*.js",
	"ui/*.ttf",
}

ui_page "ui/index.html"

server_scripts {
	"server.lua"
}

client_scripts {
	"@uiprompt/uiprompt.lua",
	"slaxml.lua",
	"client.lua",
	"data/rdr3/*.lua",
}

shared_scripts {
	"config.lua"
}

dependency "uiprompt"