local isSeatbeltOn = false
local engineStatus = true
local streetName = ""
local zoneName = ""
local isAssaltoLivre = false

-- Esconder componentes do HUD nativo e o Minimapa
Citizen.CreateThread(function()
    -- Configurao do Minimapa Moderno (Quadrado)
    SetMinimapClipType(1) 
    
    -- Loop para esconder o HUD nativo e configurar o radar
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)

        -- Mostrar/Esconder Radar condicionalmente
        if inVehicle then
            DisplayRadar(true)
            SetRadarAlpha(180) -- Transparncia do GPS (Waze style)
            
            -- Esconder barras de Vida/Colete do mapa nativo (Scaleform)
            local minimap = RequestScaleformMovie("minimap")
            if HasScaleformMovieLoaded(minimap) then
                BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
                ScaleformMovieMethodAddParamInt(3) -- Esconde ambos
                EndScaleformMovieMethod()
            end
        else
            DisplayRadar(false)
            isSeatbeltOn = false -- Reset se sair do carro
        end
        
        -- Esconde componentes nativos (Nome do carro, Classe, Rua, etc)
        HideHudComponentThisFrame(6) -- VEHICLE_NAME
        HideHudComponentThisFrame(8) -- VEHICLE_CLASS
        HideHudComponentThisFrame(7) -- AREA_NAME
        HideHudComponentThisFrame(9) -- STREET_NAME
        HideHudComponentThisFrame(3) -- CASH
        HideHudComponentThisFrame(4) -- CASH
        HideHudComponentThisFrame(2) -- WEAPON
        
        -- Bloquear sada se estiver de cinto
        if isSeatbeltOn then
            DisableControlAction(0, 75, true) 
        end

        -- Persistncia do Motor Desligado (TOTAL)
        if inVehicle then
            local veh = GetVehiclePedIsIn(ped, false)
            if not engineStatus then
                SetVehicleEngineOn(veh, false, true, true)
                SetVehicleUndriveable(veh, true) -- Trava o carro totalmente
                DisableControlAction(2, 71, true) 
                DisableControlAction(2, 72, true) 
            else
                SetVehicleUndriveable(veh, false)
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

        Citizen.Wait(waitTime)
    end
end)
