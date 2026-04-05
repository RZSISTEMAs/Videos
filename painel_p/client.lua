local isOpen = false
local playerRank = "Player"
local playerList = {}

-- Abrir/Fechar com a tecla P
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsDisabledControlJustPressed(0, Config.OpenKey) or IsControlJustPressed(0, Config.OpenKey) then
            -- Tenta abrir o menu
            TriggerServerEvent('painel_p:requestData')
        end
    end
end)

-- Receber dados do servidor e abrir NUI
RegisterNetEvent('painel_p:receiveData')
AddEventHandler('painel_p:receiveData', function(rank, players)
    playerRank = rank
    playerList = players
    
    if playerRank ~= "Player" then
        ToggleMenu(not isOpen)
    else
        TriggerEvent('chat:addMessage', { args = { '^1[ACESSO NEGADO]', '^7Apenas administradores podem usar o Painel P.' } })
    end
end)

function ToggleMenu(toggle)
    isOpen = toggle
    SetNuiFocus(toggle, toggle)
    SendNUIMessage({
        type = "show",
        status = toggle,
        rank = playerRank,
        players = playerList
    })
end

-- Callbacks da NUI
RegisterNUICallback('close', function(data, cb)
    ToggleMenu(false)
    cb('ok')
end)

RegisterNUICallback('adminAction', function(data, cb)
    TriggerServerEvent('painel_p:adminAction', data.id, data.action)
    cb('ok')
end)

RegisterNUICallback('selfAction', function(data, cb)
    local ped = PlayerPedId()
    local action = data.action
    
    if action == "god" then
        SetEntityInvincible(ped, true)
        SetPlayerInvincible(PlayerId(), true)
        TriggerEvent('chat:addMessage', { args = { '[SELF]', 'Modo Deus Ativado.' } })
    elseif action == "godoff" then
        SetEntityInvincible(ped, false)
        SetPlayerInvincible(PlayerId(), false)
        TriggerEvent('chat:addMessage', { args = { '[SELF]', 'Modo Deus Desativado.' } })
    elseif action == "heal" then
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        SetPedArmour(ped, 100)
    elseif action == "ghost" then
        SetEntityVisible(ped, not IsEntityVisible(ped), false)
    end
    cb('ok')
end)

-- Eventos de Teleporte e Morte chamados pelo servidor
RegisterNetEvent('painel_p:teleport')
AddEventHandler('painel_p:teleport', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
end)

RegisterNetEvent('painel_p:kill')
AddEventHandler('painel_p:kill', function()
    SetEntityHealth(PlayerPedId(), 0)
end)
