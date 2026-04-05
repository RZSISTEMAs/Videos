-- Sistema de Permissões Standalone com Persistência em JSON
local admins = {}
local adminsFile = "admins.json"

-- Carregar admins do JSON ao iniciar
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Primeiro carrega do Config (Predefinição)
    for id, rank in pairs(Config.AccessControl) do
        admins[tonumber(id)] = rank
    end
    
    -- Depois carrega do arquivo salvo (Persistência)
    local file = LoadResourceFile(GetCurrentResourceName(), adminsFile)
    if file then
        local savedAdmins = json.decode(file)
        for id, rank in pairs(savedAdmins) do
            admins[tonumber(id)] = rank
        end
    end
end)

-- Salvar admins no JSON
function SaveAdmins()
    SaveResourceFile(GetCurrentResourceName(), adminsFile, json.encode(admins), -1)
end

-- Pega o cargo do jogador (ID do Servidor)
function GetPlayerRank(source)
    return admins[tonumber(source)] or "Player"
end

-- Callback para o cliente saber o cargo e a lista de players + config de spawn
RegisterNetEvent('painel_p:requestData')
AddEventHandler('painel_p:requestData', function()
    local source = source
    local rank = GetPlayerRank(source)
    local players = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        table.insert(players, {
            id = playerId,
            name = GetPlayerName(playerId),
            rank = GetPlayerRank(playerId),
            ping = GetPlayerPing(playerId)
        })
    end
    
    TriggerClientEvent('painel_p:receiveData', source, rank, players, Config.Vehicles, Config.Objects, Config.WeatherTypes)
end)

-- AÇÕES ADMINISTRATIVAS (Mandar executar no Alvo)
RegisterNetEvent('painel_p:adminAction')
AddEventHandler('painel_p:adminAction', function(targetId, action, extra)
    local source = source
    local adminRank = GetPlayerRank(source)
    
    -- Validação de Segurança (Precisa ser Admin ou Moderador pelo menos)
    if adminRank == "Player" then return end
    
    if action == "kick" then
        DropPlayer(targetId, "[PAINEL P] Expulso por: " .. GetPlayerName(source))
    elseif action == "tpto" then
        local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
        TriggerClientEvent('painel_p:teleport', source, targetCoords)
    elseif action == "tphere" then
        local adminCoords = GetEntityCoords(GetPlayerPed(source))
        TriggerClientEvent('painel_p:teleport', targetId, adminCoords)
    elseif action == "kill" then
        TriggerClientEvent('painel_p:kill', targetId)
    elseif action == "setrank" and adminRank == "Dono" then
        admins[tonumber(targetId)] = extra
        SaveAdmins()
        TriggerClientEvent('chat:addMessage', -1, { args = { '^1[SISTEMA]', '^7O jogador ^3' .. GetPlayerName(targetId) .. ' ^7foi promovido a ^2' .. extra } })
        -- Renviar dados para todos
        TriggerEvent('painel_p:requestData')
    elseif action == "weather" then
        -- Define o clima globalmente (Sincronizado se o clima do server estiver ativo)
        ExecuteCommand("weather " .. extra)
    elseif action == "time" then
        -- Define a hora globalmente
        ExecuteCommand("time " .. extra)
    end
    
    -- Log no Console
    print("^1[ADMIN] ^7O " .. adminRank .. " " .. GetPlayerName(source) .. " executou ^3" .. action .. "^7 no ID " .. targetId)
end)
