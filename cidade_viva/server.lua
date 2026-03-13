local destroyedObjects = {}
local jsonFile = "destroyed_objects.json"

-- Carregar dados ao iniciar
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    local file = LoadResourceFile(GetCurrentResourceName(), jsonFile)
    if file then
        destroyedObjects = json.decode(file)
        print("^2[Cidade Viva] ^7" .. #destroyedObjects .. " objetos destruídos carregados.")
    end
end)

-- Salvar dados
function SaveData()
    SaveResourceFile(GetCurrentResourceName(), jsonFile, json.encode(destroyedObjects), -1)
end

-- Registrar objeto destruído
RegisterNetEvent('cidade_viva:registerDestroyed')
AddEventHandler('cidade_viva:registerDestroyed', function(model, coords)
    local found = false
    for _, obj in ipairs(destroyedObjects) do
        if #(vector3(obj.coords.x, obj.coords.y, obj.coords.z) - coords) < 1.0 then
            found = true
            break
        end
    end
    
    if not found then
        table.insert(destroyedObjects, {model = model, coords = {x = coords.x, y = coords.y, z = coords.z}})
        SaveData()
        TriggerClientEvent('cidade_viva:syncObjects', -1, destroyedObjects)
    end
end)

-- Pedir sincronização (quando o player entra)
RegisterNetEvent('cidade_viva:requestSync')
AddEventHandler('cidade_viva:requestSync', function()
    TriggerClientEvent('cidade_viva:syncObjects', source, destroyedObjects)
end)

-- Comando Consertar
RegisterCommand('consertar', function(source, args)
    TriggerClientEvent('cidade_viva:checkRepair', source)
end)

-- Finalizar conserto
RegisterNetEvent('cidade_viva:finishRepair')
AddEventHandler('cidade_viva:finishRepair', function(index)
    local playerName = GetPlayerName(source)
    if destroyedObjects[index] then
        table.remove(destroyedObjects, index)
        SaveData()
        TriggerClientEvent('cidade_viva:syncObjects', -1, destroyedObjects)
        
        -- Notificação lateral
        TriggerClientEvent('chat:addMessage', -1, {
            args = { "^2[ZELADORIA]", "^7O cidadão ^3" .. playerName .. " ^7consertou um item da prefeitura!" }
        })
    end
end)
