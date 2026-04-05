-- Sistema de Permissões Standalone
local admins = {}

-- Carrega admins do config inicial
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for id, rank in pairs(Config.AccessControl) do
        admins[tonumber(id)] = rank
    end
end)

-- Pega o cargo do jogador (ID do Servidor)
function GetPlayerRank(source)
    local id = tonumber(source)
    return admins[id] or "Player"
end

-- Callback para o cliente saber o cargo e a lista de players
RegisterNetEvent('painel_p:requestData')
AddEventHandler('painel_p:requestData', function()
    local source = source
    local rank = GetPlayerRank(source)
    local players = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        table.insert(players, {
            id = playerId,
            name = GetPlayerName(playerId),
            ping = GetPlayerPing(playerId)
        })
    end
    
    TriggerClientEvent('painel_p:receiveData', source, rank, players)
end)

-- AÇÕES ADMINISTRATIVAS (Mandar executar no Alvo)
RegisterNetEvent('painel_p:adminAction')
AddEventHandler('painel_p:adminAction', function(targetId, action)
    local source = source
    local adminRank = GetPlayerRank(source)
    
    -- Validação de Segurança
    if adminRank == "Player" then return end
    
    if action == "kick" then
        DropPlayer(targetId, "[PAINEL P] Você foi expulso do servidor por um administrador.")
    elseif action == "ban" then
        -- Simulação de Ban (Standalone precisa de arquivo JSON ou SQL)
        DropPlayer(targetId, "[PAINEL P] Você foi banido permanentemente.")
    elseif action == "tpto" then
        local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
        TriggerClientEvent('painel_p:teleport', source, targetCoords)
    elseif action == "tphere" then
        local adminCoords = GetEntityCoords(GetPlayerPed(source))
        TriggerClientEvent('painel_p:teleport', targetId, adminCoords)
    elseif action == "kill" then
        TriggerClientEvent('painel_p:kill', targetId)
    end
    
    -- Log no Console
    print("^1[ADMIN] ^7O " .. adminRank .. " " .. GetPlayerName(source) .. " executou ^3" .. action .. "^7 no ID " .. targetId)
end)

-- Alterar Clima/Tempo (Global)
RegisterNetEvent('painel_p:setWeather')
AddEventHandler('painel_p:setWeather', function(weather)
    if GetPlayerRank(source) ~= "Player" then
        ExecuteCommand("weather " .. weather)
    end
end)
