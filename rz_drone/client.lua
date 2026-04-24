local isDroneActive = false
local droneModel = `prop_nano_drone_01`
local droneEntity = nil
local droneCam = nil
local droneSpeed = 0.5
local droneRotateSpeed = 2.0

-- Comando para iniciar o drone
RegisterCommand('drone', function()
    if not isDroneActive then
        startDrone()
    else
        stopDrone()
    end
end)

function startDrone()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Carregar Modelo
    RequestModel(droneModel)
    while not HasModelLoaded(droneModel) do Wait(0) end
    
    -- Spawn do Drone
    droneEntity = CreateObject(droneModel, coords.x, coords.y, coords.z + 1.5, true, true, true)
    SetEntityAsMissionEntity(droneEntity, true, true)
    SetEntityInvincible(droneEntity, true)
    SetEntityCollision(droneEntity, false, false) -- Otimizao para no bater em si mesmo
    
    -- Animao do Jogador
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_MOBILE", 0, true)
    
    -- Configurao da Cmera
    droneCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    AttachCamToEntity(droneCam, droneEntity, 0.0, 0.0, 0.0, true)
    SetCamActive(droneCam, true)
    RenderScriptCams(true, true, 1000, true, true)
    
    isDroneActive = true
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "showHUD", status = true })

    -- Loop de Voo
    Citizen.CreateThread(function()
        while isDroneActive do
            Citizen.Wait(0)
            local dCoords = GetEntityCoords(droneEntity)
            local dRot = GetEntityRotation(droneEntity, 2)
            local forward, right, up, pos = GetEntityMatrix(droneEntity)

            -- CONTROLES TÉCNICOS
            
            -- Subir e Descer (Q / E)
            if IsControlPressed(0, 44) then -- Q
                SetEntityCoords(droneEntity, dCoords.x, dCoords.y, dCoords.z + 0.1 * droneSpeed)
            elseif IsControlPressed(0, 38) then -- E
                SetEntityCoords(droneEntity, dCoords.x, dCoords.y, dCoords.z - 0.1 * droneSpeed)
            end

            -- Frente e Trs (W / S)
            if IsControlPressed(0, 32) then -- W
                local newPos = dCoords + forward * droneSpeed
                SetEntityCoords(droneEntity, newPos.x, newPos.y, newPos.z)
            elseif IsControlPressed(0, 33) then -- S
                local newPos = dCoords - forward * droneSpeed
                SetEntityCoords(droneEntity, newPos.x, newPos.y, newPos.z)
            end

            -- Lados (A / D)
            if IsControlPressed(0, 34) then -- A
                local newPos = dCoords - right * droneSpeed
                SetEntityCoords(droneEntity, newPos.x, newPos.y, newPos.z)
            elseif IsControlPressed(0, 35) then -- D
                local newPos = dCoords + right * droneSpeed
                SetEntityCoords(droneEntity, newPos.x, newPos.y, newPos.z)
            end

            -- Rotação (Mouse / Setas)
            local mouseX = GetControlNormal(0, 1) * -droneRotateSpeed
            local mouseY = GetControlNormal(0, 2) * -droneRotateSpeed
            
            SetEntityRotation(droneEntity, dRot.x + mouseY, 0.0, dRot.z + mouseX, 2)

            -- Sair (F)
            if IsControlJustPressed(0, 75) then
                stopDrone()
            end
        end
    end)
end

function stopDrone()
    isDroneActive = false
    local ped = PlayerPedId()
    
    ClearPedTasksImmediately(ped)
    RenderScriptCams(false, true, 1000, true, true)
    DestroyCam(droneCam, true)
    DeleteObject(droneEntity)
    
    SendNUIMessage({ type = "showHUD", status = false })
end
