local isCreatorOpen = false
local cam = nil
local currentGender = "male"

-- Coordenadas de Spawn Disponveis
local spawnPoints = {
    ['aeroporto'] = vector4(-1037.15, -2737.56, 20.17, 330.0),
    ['hospital'] = vector4(298.63, -584.58, 43.26, 70.0),
    ['praca'] = vector4(180.3, -923.3, 30.7, 160.0)
}

-- Coordenada do "Estdio de Criao" (Lugar limpo e iluminado)
local creatorCoords = vector3(402.9, -996.7, -99.0)

-- Abrir o Criador (Comando de Teste)
RegisterCommand('gg', function()
    openCreator()
end)

-- Gatilho aps a Loadscreen
AddEventHandler('onClientResourceStart', function (resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(5000) -- Espera o carregamento total
    TriggerServerEvent('rz_creator:loadCharacter')
end)

function openCreator()
    if isCreatorOpen then return end
    isCreatorOpen = true
    
    local ped = PlayerPedId()
    
    -- Teleportar para o estdio e congelar
    SetEntityCoords(ped, creatorCoords.x, creatorCoords.y, creatorCoords.z)
    SetEntityHeading(ped, 180.0)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    
    -- Webcam Cinema
    createCamera()
    
    -- Mostrar NUI
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "openCreator" })
end

function createCamera()
    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", 402.9, -998.0, -98.3, 0.0, 0.0, 0.0, 50.0, false, 0)
    PointCamAtCoord(cam, 402.9, -996.7, -98.3)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 2000, true, true)
end

function updateCamera(part)
    if not cam then return end
    if part == "face" then
        SetCamParams(cam, 402.9, -997.5, -98.3, 0.0, 0.0, 0.0, 30.0, 1000, 0, 0, 2)
    else
        SetCamParams(cam, 402.9, -998.5, -98.3, 0.0, 0.0, 0.0, 50.0, 1000, 0, 0, 2)
    end
end

-- Callbacks da NUI
RegisterNUICallback('changeGender', function(data)
    local model = data.gender == "male" and `mp_m_freemode_01` or `mp_f_freemode_01`
    currentGender = data.gender
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    
    SetPlayerModel(PlayerId(), model)
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    
    -- Reposicionar no estdio (SetPlayerModel reseta coords)
    SetEntityCoords(ped, creatorCoords.x, creatorCoords.y, creatorCoords.z)
    SetEntityHeading(ped, 180.0)
    FreezeEntityPosition(ped, true)
end)

RegisterNUICallback('updateCharacter', function(data)
    local ped = PlayerPedId()
    
    -- DNA / Face
    SetPedHeadBlendData(ped, data.father, data.mother, 0, data.father, data.mother, 0, data.shapeMix, data.skinMix, 0, false)
    
    -- Cabelo e Olhos
    SetPedComponentVariation(ped, 2, data.hair, 0, 0)
    SetPedHairColor(ped, data.hairColor, 0)
    SetPedEyeColor(ped, data.eyes)
    
    -- Roupas
    SetPedComponentVariation(ped, 11, data.tops, 0, 0)
    SetPedComponentVariation(ped, 4, data.legs, 0, 0)
    SetPedComponentVariation(ped, 6, data.shoes, 0, 0)
end)

RegisterNUICallback('finalize', function(data)
    -- Envia para a prxima tela (Spawn)
    SendNUIMessage({ type = "openSpawnPicker" })
end)

RegisterNUICallback('selectSpawn', function(data)
    local loc = spawnPoints[data.location]
    if loc then
        DoScreenFadeOut(1000)
        Wait(1000)
        
        isCreatorOpen = false
        SetNuiFocus(false, false)
        
        -- Cleanup Camera
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(cam, true)
        
        -- Teleport Final
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, false)
        SetEntityCoords(ped, loc.x, loc.y, loc.z)
        SetEntityHeading(ped, loc.w)
        
        -- Salvar no servidor
        TriggerServerEvent('rz_creator:saveCharacter', data.charData)
        
        Wait(1000)
        DoScreenFadeIn(1000)
    end
end)

-- Evento para aplicar o personagem salvo
RegisterNetEvent('rz_creator:applyCharacter')
AddEventHandler('rz_creator:applyCharacter', function(data)
    local model = data.gender == "male" and `mp_m_freemode_01` or `mp_f_freemode_01`
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    
    SetPlayerModel(PlayerId(), model)
    local ped = PlayerPedId()
    
    -- Aplicar todas as caractersticas (DNA, Cabelo, Roupas)
    SetPedHeadBlendData(ped, data.father, data.mother, 0, data.father, data.mother, 0, data.shapeMix, data.skinMix, 0, false)
    SetPedComponentVariation(ped, 2, data.hair, 0, 0)
    SetPedHairColor(ped, data.hairColor, 0)
    SetPedEyeColor(ped, data.eyes)
    SetPedComponentVariation(ped, 11, data.tops, 0, 0)
    SetPedComponentVariation(ped, 4, data.legs, 0, 0)
    SetPedComponentVariation(ped, 6, data.shoes, 0, 0)
end)

RegisterNetEvent('rz_creator:openCreator')
AddEventHandler('rz_creator:openCreator', function()
    openCreator()
end)
