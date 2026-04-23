fx_version 'cerulean'
game 'gta5'

author 'RZSISTEMA'
description 'Sistema de Criação de Personagem Premium'
version '1.1.0'

ui_page 'ui/index.html'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/assets/*' -- Reservado para imagens se houver
}
