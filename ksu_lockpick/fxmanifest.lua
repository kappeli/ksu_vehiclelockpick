fx_version 'cerulean'
game 'gta5'
lua54 'yes'

version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/locale.lua',
    'locales/*.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_target',
    't3_lockpick'
}
