fx_version 'cerulean'
game 'gta5'

author 'Haxwel'
description 'Security cameras by Haxwel'
version '1.0.0'

lua54 'yes'

client_scripts {
    'client.lua',
    'cameras.lua',
    'zones.lua'
}

dependencies {
    'es_extended'
}

shared_scripts {
    '@es_extended/imports.lua'
}
