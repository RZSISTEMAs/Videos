local isSeatbeltOn = false
local engineStatus = true
local streetName = ""
local zoneName = ""
local isAssaltoLivre = false

-- Esconder componentes do HUD nativo e o Minimapa (Sempre OFF a pedido do usurio)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)

        DisplayRadar(false) -- MAPA SEMPRE DESATIVADO

        -- Esconde componentes nativos de forma agressiva (Nome do carro, Classe, etc)
        HideHudComponentThisFrame(6)  -- VEHICLE_NAME
        HideHudComponentThisFrame(7)  -- AREA_NAME
        HideHudComponentThisFrame(8)  -- VEHICLE_CLASS
        HideHudComponentThisFrame(9)  -- STREET_NAME
        HideHudComponentThisFrame(3)  -- CASH
        HideHudComponentThisFrame(4)  -- CASH
        HideHudComponentThisFrame(13) -- PLAYER_NAME
        HideHudComponentThisFrame(2)  -- WEAPON_ICON

        -- Bloquear sada se estiver de cinto
        if isSeatbeltOn then
            DisableControlAction(0, 75, true) 
        end

        -- Persistncia do Motor Desligado (Sem travar rodas)
        if inVehicle then
            local veh = GetVehiclePedIsIn(ped, false)
            if not engineStatus then
                SetVehicleEngineOn(veh, false, true, true)
                -- Em vez de Undriveable, desativamos apenas a acelerao/r
                DisableControlAction(2, 71, true) -- W
                DisableControlAction(2, 72, true) -- S
            end
        else
            engineStatus = true
        end
    end
end)

-- Comandos de Tecla (Motor e Cinto)
 Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local class = GetVehicleClass(veh)

            -- Tecla Z (Motor) - ID 20
            if IsControlJustPressed(0, 20) then
                engineStatus = not engineStatus
                SetVehicleEngineOn(veh, engineStatus, false, true)
                local msg = engineStatus and "Motor Ligado" or "Motor Desligado"
                SendNUIMessage({ type = "notify", message = msg })
            end

            -- Tecla G (Cinto) - ID 47 (Ignorar motos classe 8)
            if IsControlJustPressed(0, 47) and class ~= 8 then
                isSeatbeltOn = not isSeatbeltOn
                local msg = isSeatbeltOn and "Cinto Colocado" or "Cinto Retirado"
                SendNUIMessage({ type = "notify", message = msg })
                SendNUIMessage({ type = "updateSeatbelt", status = isSeatbeltOn })
            end
        else
            -- Resetar cinto ao sair do carro
            if isSeatbeltOn then
                isSeatbeltOn = false
                SendNUIMessage({ type = "updateSeatbelt", status = false })
            end
        end
    end
end)

-- Loop de informaes (Localizao, Horrio e Status)
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inVehicle = IsPedInAnyVehicle(ped, false)
        local waitTime = inVehicle and 100 or 1000 -- Mais rpido se estiver correndo no carro

        -- 1. Localizao
        local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        streetName = GetStreetNameFromHashKey(streetHash)
        
        local zone = GetNameOfZone(coords.x, coords.y, coords.z)
        zoneName = GetLabelText(zone)

        -- 2. Horrio
        local hours = GetClockHours()
        local minutes = GetClockMinutes()
        local timeString = string.format("%02d:%02d", hours, minutes)

        -- 3. Lgica Assalto Livre (00h at as 06h)
        if hours >= 0 and hours < 6 then
            isAssaltoLivre = true
        else
            isAssaltoLivre = false
        end

        -- 4. Status e Velocidade
        local speed = 0
        if inVehicle then
            local veh = GetVehiclePedIsIn(ped, false)
            speed = math.ceil(GetEntitySpeed(veh) * 3.6) -- KM/H
        end

        local health = GetEntityHealth(ped) - 100
        if health < 0 then health = 0 end
        local armor = GetPedArmour(ped)

        -- Enviar para a UI
        SendNUIMessage({
            type = "updateHUD",
            street = streetName,
            zone = zoneName,
            time = timeString,
            assalto = isAssaltoLivre,
            speed = speed,
            inVehicle = inVehicle,
            health = health,
            armor = armor
        })

        Citizen.Wait(0)
    end
end)

-- Listas de Modelos de Elite e Polcia
local supercars = { "adder", "zentorno", "t20", "osiris", "vacca", "turismor", "tempesta", "italigtb", "nero", "nero2", "prototipo", "visione", "cyclone", "tezeract" }
local policeModels = { "police", "police2", "police3", "police4", "policeb", "fbi", "fbi2" }
local processedVehicles = {}

-- 1. Controle de Procurado e Densidade Base
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local player = PlayerId()

        -- Remover Nvel de Procurado
        if GetPlayerWantedLevel(player) ~= 0 then
            ClearPlayerWantedLevel(player)
            SetMaxWantedLevel(0)
        end

        -- Densidade Geral (Reduzida para dar espao aos Supercarros e Polcia)
        SetVehicleDensityMultiplierThisFrame(0.5)
        SetPedDensityMultiplierThisFrame(0.5)
        SetRandomVehicleDensityMultiplierThisFrame(0.5)
        
        -- Garantir que a polcia possa spawnar nativamente tambm
        SetCreateRandomCops(true)
        SetCreateRandomCopsOnScenarios(true)
        SetCreateRandomCopsNotOnScenarios(true)
        SetDispatchCopsForPlayer(player, false)
    end
end)

-- 2. Substituio de Trfego (Comuns -> Supercarros)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local vehicles = GetGamePool('CVehicle')

        for _, veh in ipairs(vehicles) do
            if DoesEntityExist(veh) and not processedVehicles[veh] then
                local class = GetVehicleClass(veh)
                
                -- Se for um carro comum (não emergência, não supercarro prévio)
                if class ~= 18 and class ~= 19 and class ~= 15 and not IsPedAPlayer(GetPedInVehicleSeat(veh, -1)) then
                    local randomSuper = supercars[math.random(#supercars)]
                    local hash = GetHashKey(randomSuper)

                    if #(coords - GetEntityCoords(veh)) > 40.0 and #(coords - GetEntityCoords(veh)) < 150.0 then
                        RequestModel(hash)
                        while not HasModelLoaded(hash) do Wait(0) end

                        local pos = GetEntityCoords(veh)
                        local heading = GetEntityHeading(veh)
                        local newVeh = CreateVehicle(hash, pos.x, pos.y, pos.z, heading, true, false)
                        
                        local driver = GetPedInVehicleSeat(veh, -1)
                        if DoesEntityExist(driver) then
                            SetPedIntoVehicle(driver, newVeh, -1)
                            TaskVehicleDriveWander(driver, newVeh, 20.0, 786603)
                        end

                        DeleteVehicle(veh)
                        processedVehicles[newVeh] = true
                    end
                end
                processedVehicles[veh] = true
            end
        end
    end
end)

-- 3. Gerador de Patrulhas Intensas (Garantir 3 viaturas próximas)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local vehicles = GetGamePool('CVehicle')
        local policeCount = 0

        for _, veh in ipairs(vehicles) do
            local model = GetEntityModel(veh)
            for _, pModel in ipairs(policeModels) do
                if model == GetHashKey(pModel) then
                    policeCount = policeCount + 1
                    break
                end
            end
        end

        if policeCount < 3 then
            local randomPolice = policeModels[math.random(#policeModels)]
            local hash = GetHashKey(randomPolice)
            
            RequestModel(hash)
            while not HasModelLoaded(hash) do Wait(0) end

            local retval, spawnPos, spawnHeading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-150, 150), coords.y + math.random(-150, 150), coords.z, 1, 3, 0)
            
            if retval then
                local pVeh = CreateVehicle(hash, spawnPos.x, spawnPos.y, spawnPos.z, spawnHeading, true, false)
                local pPed = CreatePedInsideVehicle(pVeh, 4, GetHashKey("s_m_y_cop_01"), -1, true, false)
                
                SetVehicleOnGroundProperly(pVeh)
                TaskVehicleDriveWander(pPed, pVeh, 15.0, 786603) -- Patrulha
                SetEntityAsMissionEntity(pVeh, true, true)
            end
        end
    end
end)
    end
end)
