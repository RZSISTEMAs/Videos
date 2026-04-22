local isSeatbeltOn = false
local engineStatus = true
local streetName = ""
local zoneName = ""
local isAssaltoLivre = false

-- Esconder componentes do HUD nativo e o Minimapa
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        -- Esconde vida, armas, dinheiro, minimapa e NOME DO CARRO
        DisplayRadar(false) -- REMOVE O MINIMAPA
        HideHudComponentThisFrame(3) -- SP_CASH
        HideHudComponentThisFrame(4) -- MP_CASH
        HideHudComponentThisFrame(13) -- PL_NAME
        HideHudComponentThisFrame(7) -- AREA_NAME
        HideHudComponentThisFrame(9) -- STREET_NAME
        HideHudComponentThisFrame(6) -- VEHICLE_NAME
        HideHudComponentThisFrame(8) -- VEHICLE_CLASS
        
        -- Bloquear sada se estiver de cinto
        if isSeatbeltOn then
            DisableControlAction(0, 75, true) -- Bloqueia o "F" (Sair do Carro)
        end

        -- Persistncia do Motor Desligado (Impede auto-start pelo 'W')
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if not engineStatus and GetIsVehicleEngineRunning(veh) then
                SetVehicleEngineOn(veh, false, true, true)
            end
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

        Citizen.Wait(waitTime)
    end
end)
