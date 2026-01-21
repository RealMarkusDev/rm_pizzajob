fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Real Markus Dev'
description 'RM Pizza Job - Advanced Delivery System'
version '1.0.0'

-- UI Definition
ui_page 'web/index.html'

files {
    'web/index.html',
    'web/css/*.css',
    'web/js/*.js',
    'web/assets/*.png' -- Ensure images are here
}

-- Shared Scripts & Libraries
shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

-- Server Scripts
server_scripts {
    'server/main.lua'
}

-- Client Scripts
client_scripts {
    'client/main.lua'
}

-- Dependencies
dependencies {
    'ox_lib',
    'ox_target'
}