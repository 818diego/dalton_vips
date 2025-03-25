fx_version 'cerulean'
game 'gta5'

author 'Dalton Life'
description 'Vip System'
version '0.1'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'config/**.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/**.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**.lua'
}

files {
    'locales/*.json'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
