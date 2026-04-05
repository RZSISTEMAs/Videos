fx_version 'cerulean'
game 'gta5'

author 'RZSISTEMA'
description 'Painel P - Menu Admin Premium Standalone'
version '1.0.0'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/assets/logo.png' -- Caso queira colocar uma logo depois
}

client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'config.lua',
    'server.lua'
}
