local isSeatbeltOn = false
local engineStatus = true
local streetName = ""
local zoneName = ""
local isAssaltoLivre = false
local playerInVehicle = false
local currentVehicle = 0

-- 1. Thread de Estado (Otimizao: roda a cada 500ms)
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        playerInVehicle = IsPedInAnyVehicle(ped, false)
        if playerInVehicle then
            currentVehicle = GetVehiclePedIsIn(ped, false)
        else
            currentVehicle = 0
            engineStatus = true -- Reseta motor ao sair
            if isSeatbeltOn then
                isSeatbeltOn = false
                SendNUIMessage({ type = "updateSeatbelt", status = false })
            end
        end
        Citizen.Wait(500)
    end
end)

-- 2. Loop de HUD e Controle Essencial (Wait 0 - apenas o necessrio)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        DisplayRadar(false) -- Mapa OFF sempre

        -- Ocultao de componentes nativos
        HideHudComponentThisFrame(6)
        HideHudComponentThisFrame(7)
        HideHudComponentThisFrame(8)
        HideHudComponentThisFrame(9)
        HideHudComponentThisFrame(3)
        HideHudComponentThisFrame(4)
        HideHudComponentThisFrame(13)
        HideHudComponentThisFrame(2)

        if playerInVehicle then
            -- Cinto (Bloqueio de sada)
            if isSeatbeltOn then
                DisableControlAction(0, 75, true)
            end

            -- Motor Desligado (Impede acelerao sem forar nativas de motor no loop 0)
            if not engineStatus then
                DisableControlAction(2, 71, true)
                DisableControlAction(2, 72, true)
            end
        end
    end
end)

-- 3. Teclas e Ao (Wait 0 - entrada de comando)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if playerInVehicle and currentVehicle ~= 0 then
            -- Tecla Z (Motor)
            if IsControlJustPressed(0, 20) then
                engineStatus = not engineStatus
                SetVehicleEngineOn(currentVehicle, engineStatus, false, true)
                local msg = engineStatus and "Motor Ligado" or "Motor Desligado"
                SendNUIMessage({ type = "notify", message = msg })
            end

            -- Tecla G (Cinto) - Ignorar motos classe 8
            if IsControlJustPressed(0, 47) and GetVehicleClass(currentVehicle) ~= 8 then
                isSeatbeltOn = not isSeatbeltOn
                local msg = isSeatbeltOn and "Cinto Colocado" or "Cinto Retirado"
                SendNUIMessage({ type = "notify", message = msg })
                SendNUIMessage({ type = "updateSeatbelt", status = isSeatbeltOn })
            end
        end
    end
end)

-- 4. Loop de UI e Informaes (Otimizado por Importncia)
Citizen.CreateThread(function()
    local lastLocUpdate = 0
    while true do
        local ped = PlayerPedId()
        local waitTime = playerInVehicle and 150 or 1000
        local now = GetGameTimer()

        -- Atualizar Localizao apenas a cada 2 segundos
        if now - lastLocUpdate > 2000 then
            local coords = GetEntityCoords(ped)
            local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            streetName = GetStreetNameFromHashKey(streetHash)
            zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
            
            local hours = GetClockHours()
            isAssaltoLivre = (hours >= 0 and hours < 6)
            lastLocUpdate = now
        end

        local speed = 0
        if playerInVehicle and currentVehicle ~= 0 then
            speed = math.ceil(GetEntitySpeed(currentVehicle) * 3.6)
            -- Forar motor OFF se estiver desativado (apenas aqui para evitar chamar todo frame no loop 0)
            if not engineStatus and GetIsVehicleEngineRunning(currentVehicle) then
                SetVehicleEngineOn(currentVehicle, false, true, true)
            end
        end

        local health = math.max(0, GetEntityHealth(ped) - 100)
        local armor = GetPedArmour(ped)

        SendNUIMessage({
            type = "updateHUD",
            street = streetName,
            zone = zoneName,
            time = string.format("%02d:%02d", GetClockHours(), GetClockMinutes()),
            assalto = isAssaltoLivre,
            speed = speed,
            inVehicle = playerInVehicle,
            health = health,
            armor = armor
        })

        Citizen.Wait(waitTime)
    end
end)

