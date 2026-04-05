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
AddEventHandler('painel_p:receiveData', function(rank, players, vehicles, objects, weather)
    playerRank = rank
    playerList = players
    
    if playerRank ~= "Player" then
        isOpen = not isOpen
        SetNuiFocus(isOpen, isOpen)
        SendNUIMessage({
            type = "show",
            status = isOpen,
            rank = playerRank,
            players = playerList,
            vehicles = vehicles,
            objects = objects,
            weather = weather
        })
    else
        TriggerEvent('chat:addMessage', { args = { '^1[ACESSO NEGADO]', '^7Apenas administradores podem usar o Painel P.' } })
    end
end)

-- Spawn de Veículos
RegisterNUICallback('spawnVehicle', function(data, cb)
    local model = data.model
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    TaskWarpPedIntoVehicle(ped, veh, -1)
    cb('ok')
end)

-- Spawn de Objetos (MELHORADO)
RegisterNUICallback('spawnObject', function(data, cb)
    local model = data.model
    local ped = PlayerPedId()
    -- Spawn 2 metros à frente do jogador
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.5, 0.0)
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    
    local obj = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true) -- Congela para evitar bugs de física
    cb('ok')
end)

-- Callbacks da NUI
RegisterNUICallback('close', function(data, cb)
    isOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('adminAction', function(data, cb)
    TriggerServerEvent('painel_p:adminAction', data.id, data.action, data.extra)
    cb('ok')
end)

RegisterNUICallback('selfAction', function(data, cb)
    local ped = PlayerPedId()
    local action = data.action
    
    if action == "god" then
        SetEntityInvincible(ped, true)
    elseif action == "godoff" then
        SetEntityInvincible(ped, false)
    elseif action == "heal" then
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        SetPedArmour(ped, 100)
    elseif action == "dv" then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then veh = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 71) end
        if (veh ~= 0) then 
            SetEntityAsMissionEntity(veh, true, true)
            DeleteVehicle(veh) 
        end
    elseif action == "fix" then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then SetVehicleFixed(veh) SetVehicleDirtLevel(veh, 0.0) end
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
