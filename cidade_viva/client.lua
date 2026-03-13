local destroyedObjects = {}
local isRepairing = false
local recentlyFixed = {} -- Trava para não re-detectar o mesmo item logo após o conserto

-- Sincronizar objetos com o servidor
RegisterNetEvent('cidade_viva:syncObjects')
AddEventHandler('cidade_viva:syncObjects', function(data)
    destroyedObjects = data
end)

-- Pedir sincronização inicial
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('cidade_viva:requestSync')
end)

-- Loop principal: Detecção e Manutenção Visual
CreateThread(function()
    while true do
        local sleep = 1000
        local pPed = PlayerPedId()
        local pPos = GetEntityCoords(pPed)

        -- 1. DETECÇÃO DE NOVOS OBJETOS QUEBRADOS
        -- Só detecta objetos num raio curto
        local handle, object = FindFirstObject()
        local success
        repeat
            local oPos = GetEntityCoords(object)
            local dist = #(pPos - oPos)

            if dist < 50.0 then
                -- Se o objeto é do mapa e está quebrado/caído
                if GetEntityHealth(object) < 100 or not IsEntityUpright(object, 85.0) then
                    -- Evita registrar objetos de scripts ou carros
                    if GetEntityType(object) == 3 and not IsEntityAPed(object) and not IsEntityAVehicle(object) then
                        local oPos = GetEntityCoords(object)
                        local model = GetEntityModel(object)
                        
                        -- FILTRO: Só envia se não for um objeto que já conhecemos ou que acabamos de consertar
                        local alreadyRegistered = false
                        
                        -- Checa se está na lista de destruídos
                        for _, recorded in ipairs(destroyedObjects) do
                            if #(vector3(recorded.coords.x, recorded.coords.y, recorded.coords.z) - oPos) < 3.0 then
                                alreadyRegistered = true
                                break
                            end
                        end

                        -- Checa se foi consertado recentemente (trava de re-detecção)
                        if not alreadyRegistered then
                            for _, fixedPos in ipairs(recentlyFixed) do
                                if #(fixedPos - oPos) < 3.0 then
                                    alreadyRegistered = true
                                    break
                                end
                            end
                        end

                        if not alreadyRegistered and model ~= 0 then
                             TriggerServerEvent('cidade_viva:registerDestroyed', model, oPos)
                        end
                    end
                end
            end
            success, object = FindNextObject(handle)
        until not success
        EndFindObject(handle)

        -- 2. MANUTENÇÃO VISUAL (Forçar objetos salvos a ficarem destruídos)
        for _, obj in ipairs(destroyedObjects) do
            local dist = #(pPos - vector3(obj.coords.x, obj.coords.y, obj.coords.z))
            if dist < 100.0 then
                sleep = 0
                -- Localiza o objeto original no mapa
                local mapObj = GetClosestObjectOfType(obj.coords.x, obj.coords.y, obj.coords.z, 2.0, obj.model, false, false, false)
                if DoesEntityExist(mapObj) then
                    -- Garante que ele continue quebrado ou invisível (dependendo do tipo)
                    SetEntityHealth(mapObj, 0)
                    -- Se o objeto não cair sozinho, podemos deletar o original e spawnar um prop no chão
                    -- Mas por enquanto, forçamos a saúde a 0 para NPCs e players verem quebrado.
                end
                
                -- Desenhar marcador 3D se estiver muito perto (Dica de reparo)
                if dist < 3.0 and not isRepairing then
                    DrawText3D(obj.coords.x, obj.coords.y, obj.coords.z + 1.0, "~w~Objeto ~r~Danificado~w~\nUse ~y~/consertar")
                end
            end
        end

        Wait(sleep)
    end
end)

-- Evento para restaurar o objeto visualmente para todos
RegisterNetEvent('cidade_viva:objectFixed')
AddEventHandler('cidade_viva:objectFixed', function(coords, model)
    local vCoords = vector3(coords.x, coords.y, coords.z)
    
    -- Adiciona à lista de ignorados temporariamente
    table.insert(recentlyFixed, vCoords)
    SetTimeout(10000, function() -- Remove da trava após 10 segundos
        for i, pos in ipairs(recentlyFixed) do
            if pos == vCoords then
                table.remove(recentlyFixed, i)
                break
            end
        end
    end)

    -- Tenta "levantar" o objeto original
    local mapObj = GetClosestObjectOfType(vCoords.x, vCoords.y, vCoords.z, 5.0, model, false, false, false)
    if DoesEntityExist(mapObj) then
        SetEntityCoords(mapObj, vCoords.x, vCoords.y, vCoords.z)
        SetEntityRotation(mapObj, 0.0, 0.0, 0.0, 2, true)
        SetEntityHealth(mapObj, 1000)
        FreezeEntityPosition(mapObj, true) -- Congela para não cair de novo
        Wait(500)
        FreezeEntityPosition(mapObj, false)
    end
end)

-- Lógica de Reparo
RegisterNetEvent('cidade_viva:checkRepair')
AddEventHandler('cidade_viva:checkRepair', function()
    local pPed = PlayerPedId()
    local pPos = GetEntityCoords(pPed)
    local foundIndex = nil

    for i, obj in ipairs(destroyedObjects) do
        local dist = #(pPos - vector3(obj.coords.x, obj.coords.y, obj.coords.z))
        if dist < 3.0 then
            foundIndex = i
            break
        end
    end

    if foundIndex and not isRepairing then
        isRepairing = true
        TaskStartScenarioInPlace(pPed, "WORLD_HUMAN_WELDING", 0, true)
        
        -- Progresso
        local timer = 7000 -- 7 segundos de reparo
        CreateThread(function()
            while timer > 0 do
                Wait(0)
                timer = timer - 10
                local obj = destroyedObjects[foundIndex]
                if obj then
                    DrawText3D(obj.coords.x, obj.coords.y, obj.coords.z + 1.2, "~y~CONSERTANDO... ~w~" .. math.floor((7000 - timer) / 70) .. "%")
                end
            end
            
            ClearPedTasks(pPed)
            isRepairing = false
            TriggerServerEvent('cidade_viva:finishRepair', foundIndex)
        end)
    else
        TriggerEvent('chat:addMessage', { args = { "^1[ERRO]", "^7Não há nada para consertar por perto." } })
    end
end)

-- Função auxiliar para Texto 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end
end
