-- Sistema de Salvamento RZ_Creator
local playersData = {}

-- Salvar dados do personagem (Usando KVP para persistncia sem DB)
RegisterNetEvent('rz_creator:saveCharacter')
AddEventHandler('rz_creator:saveCharacter', function(charData)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0) -- Steam ou License

    if identifier then
        SetResourceKvpString('rzChar_' .. identifier, json.encode(charData))
        print('^2[RZ_CREATOR] Dados salvos para: ' .. identifier .. '^7')
    end
end)

-- Carregar dados do personagem
RegisterNetEvent('rz_creator:loadCharacter')
AddEventHandler('rz_creator:loadCharacter', function()
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)

    if identifier then
        local data = GetResourceKvpString('rzChar_' .. identifier)
        if data then
            TriggerClientEvent('rz_creator:applyCharacter', src, json.decode(data))
        else
            -- Se no tem dados, abre o criador (Primeiro Acesso)
            TriggerClientEvent('rz_creator:openCreator', src)
        end
    end
end)
