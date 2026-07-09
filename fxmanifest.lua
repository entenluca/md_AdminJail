fx_version 'cerulean'
game 'gta5'

name 'md_AdminJail'
author 'md'
description 'Modernes AdminJail System mit mehreren Strafenarten, Aufgaben und Discord-Integration'
version '2.0.0'

lua54 'yes'

shared_scripts {
    'config.lua'
}

server_scripts {
    'server/discord.lua',
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
