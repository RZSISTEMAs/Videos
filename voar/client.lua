local isFlying = false
local speed = 1.0
local grabbedEntity = nil

RegisterCommand('voar', function()
    isFlying = not isFlying
    local ped = PlayerPedId()

    if isFlying then
        SetEntityInvincible(ped, true)
        SetEntityCollision(ped, false, false)
        SetEntityAlpha(ped, 200, false) -- Efeito visual de que está "flutuando"
        TriggerEvent('chat:addMessage', { args = { '^5[VOAR]', '^7Você começou a voar! Use ^3W/S^7 para mover, ^3Shift^7 para acelerar, e ^1Q^7 para parar.' } })
    else
        StopFlying(ped)
    end
end, false)

function StopFlying(ped)
    isFlying = false
    SetEntityInvincible(ped, false)
    SetEntityCollision(ped, true, true)
    ResetEntityAlpha(ped)

    -- Solta a pessoa se estiver agarrando
    if grabbedEntity ~= nil then
        DetachEntity(grabbedEntity, true, true)
        SetEntityAsNoLongerNeeded(grabbedEntity) -- Permite que o jogo delete o NPC de novo se ele ficar longe
        grabbedEntity = nil
    end

    TriggerEvent('chat:addMessage', { args = { '^5[VOAR]', '^7Você parou de voar e ficou neste local.' } })
end

-- Pega o PED (jogador ou NPC) mais próximo da sua localização
function GetClosestPed(coords)
    local peds = GetGamePool('CPed')
    local closestPed = nil
    local closestDist = 5.0 -- 5 metros no máximo para agarrar
    local playerPed = PlayerPedId()
    
    for i=1, #peds do
        local ped = peds[i]
        if ped ~= playerPed then
            local dist = #(coords - GetEntityCoords(ped))
            if dist < closestDist then
                closestPed = ped
                closestDist = dist
            end
        end
    end
    return closestPed
end

-- Função para desenhar os comandos na tela enquanto voa
function DrawInstructions()
    -- Fundo preto transparente (Box)
    -- Argumentos: X (centro), Y (centro), Largura, Altura, R, G, B, Alpha
    DrawRect(0.09, 0.415, 0.16, 0.20, 0, 0, 0, 160)

    -- Texto das instruções
    SetTextFont(4)
    SetTextScale(0.40, 0.40)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    
    local text = "~b~MODO VOO ATIVO~n~~w~[W/S] Mover~n~[SHIFT] Voar Rapido"
    if grabbedEntity == nil then
        text = text .. "~n~[E] Agarrar Pessoa"
    else
        text = text .. "~n~[E] Soltar Pessoa"
    end
    text = text .. "~n~[Q] Parar~n~~n~~y~RZSISTEMA"

    -- Usamos AddTextEntry pois a função normal corta textos maiores que 99 caracteres!
    AddTextEntry("HUD_VOAR_TXT", text)
    SetTextEntry("HUD_VOAR_TXT")
    DrawText(0.015, 0.32) -- Exibe em cima da caixa
end

-- Função para calcular a direção XYZ baseada para onde a câmera aponta
function GetCamDirection()
    local rot = GetGameplayCamRot(2)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return -math.sin(z) * num, math.cos(z) * num, math.sin(x)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if isFlying then
            DrawInstructions() -- Exibe o menu na tela todo frame de jogo

            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped, false))
            local dx, dy, dz = GetCamDirection()
            
            local currentSpeed = speed
            
            -- Acelerar com a tecla Shift Esq (Control 21)
            if IsControlPressed(0, 21) then
                currentSpeed = speed * 4.0 -- Voa bem mais rápido
            end

            -- Zera a velocidade padrão do jogo para não cair
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)

            -- Move pra frente (W - Control 32)
            if IsControlPressed(0, 32) then
                x = x + currentSpeed * dx
                y = y + currentSpeed * dy
                z = z + currentSpeed * dz
            end

            -- Move pra trás (S - Control 33)
            if IsControlPressed(0, 33) then
                x = x - currentSpeed * dx
                y = y - currentSpeed * dy
                z = z - currentSpeed * dz
            end

            -- Atualiza a posição constantemente de forma "teleportada" (NoClip)
            SetEntityCoordsNoOffset(ped, x, y, z, true, true, true)
            
            -- Faz o personagem virar para onde a câmera está olhando
            SetEntityHeading(ped, GetGameplayCamRot(2).z)

            -- Lógica para Agarrar / Soltar Pessoas com a tecla E (Control 38)
            if IsControlJustPressed(0, 38) then
                if grabbedEntity == nil then
                    -- Tenta pegar alguém perto
                    local target = GetClosestPed(vector3(x, y, z))
                    if target ~= nil then
                        grabbedEntity = target

                        -- Solicita controle da entidade pela rede (Importante para o servidor não bugar e sumir)
                        NetworkRequestControlOfEntity(grabbedEntity)
                        -- Diz ao GTA V que esse ped é importante e NÃO pode sumir (não despawnar)
                        SetEntityAsMissionEntity(grabbedEntity, true, true)

                        -- Anexa a pessoa a nós (Fica flutuando junto)
                        AttachEntityToEntity(grabbedEntity, ped, 0, 0.0, 1.5, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        TriggerEvent('chat:addMessage', { args = { '^5[VOAR]', '^2Você agarrou alguém!' } })
                    else
                        TriggerEvent('chat:addMessage', { args = { '^5[VOAR]', '^1Ninguém por perto para agarrar.' } })
                    end
                else
                    -- Solta quem estiver agarrado
                    DetachEntity(grabbedEntity, true, true)
                    -- Libera a pessoa de volta pro motor normal do GTA
                    SetEntityAsNoLongerNeeded(grabbedEntity)
                    grabbedEntity = nil
                    TriggerEvent('chat:addMessage', { args = { '^5[VOAR]', '^3Você soltou a pessoa.' } })
                end
            end

            -- Parar de voar com a tecla Q (Control 44) no lugar que ficou
            if IsControlJustPressed(0, 44) then
                StopFlying(ped)
            end
        else
            -- Se não estiver voando, espera um pouco para poupar processamento
            Citizen.Wait(500)
        end
    end
end)

-- Comando extra super rápido para te ajudar com coordenadas!
RegisterCommand('coord', function()
    local ped = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(ped))
    local heading = GetEntityHeading(ped)

    -- Formata bonitinho pra você copiar do seu chat apertando T
    local positionStr = string.format("vector3(%.1f, %.1f, %.1f) | Ângulo: %.1f", x, y, z, heading)
    
    TriggerEvent('chat:addMessage', { args = { '^3[COORD]', '^7Sua Posição atual é: ^2' .. positionStr } })
end)
