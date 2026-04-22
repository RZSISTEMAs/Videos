local streetName = ""
local zoneName = ""
local isAssaltoLivre = false

-- Esconder componentes do HUD nativo
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        -- Esconde vida, armas, dinheiro e o minimapa padro se quiser (neste caso, manteremos o radar limpo)
        HideHudComponentThisFrame(3) -- SP_CASH
        HideHudComponentThisFrame(4) -- MP_CASH
        HideHudComponentThisFrame(13) -- PL_NAME
        -- HideHudComponentThisFrame(2) -- WEAPON_ICON (Opcional)
    end
end)

-- Loop de informaes (Localizao, Horrio e Status)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Atualiza a cada 1 segundo para poupar performance

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

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

        -- Enviar para a UI
        SendNUIMessage({
            type = "updateHUD",
            street = streetName,
            zone = zoneName,
            time = timeString,
            assalto = isAssaltoLivre
        })
    end
end)
