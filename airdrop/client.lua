local dropCoords = nil
local plane = nil
local pilot = nil
local crate = nil
local parachute = nil
local flare = nil
local guards = {}

-- Configurações
local planeModel = `titan`
local crateModel = `prop_box_ammo04a`
local parachuteModel = `p_cargo_chute_s`
local guardModel = `s_m_m_security_01`

-- Comando para iniciar o Airdrop
RegisterCommand('airdrop', function()
    -- Define um local aleatório perto do jogador (ou você pode passar coordenadas)
    local playerPed = PlayerPedId()
    local pPos = GetEntityCoords(playerPed)
    
    -- Gera um local de destino a ~200-400 metros de distância
    local targetX = pPos.x + math.random(-300, 300)
    local targetY = pPos.y + math.random(-300, 300)
    local found, groundZ = GetGroundZFor_3dCoord(targetX, targetY, pPos.z + 50.0, false)
    
    if not found then groundZ = pPos.z end
    
    CreateAirdrop(vector3(targetX, targetY, groundZ))
    TriggerEvent('chat:addMessage', { args = { '^1[AIRDROP]', '^7Um avião de suprimentos está cruzando o céu!' } })
end)

function CreateAirdrop(coords)
    dropCoords = coords
    
    -- Carregar Modelos
    RequestModel(planeModel)
    RequestModel(crateModel)
    RequestModel(parachuteModel)
    RequestModel(guardModel)
    while not HasModelLoaded(planeModel) or not HasModelLoaded(crateModel) or not HasModelLoaded(parachuteModel) or not HasModelLoaded(guardModel) do
        Wait(0)
    end

    -- 1. SPAWN DO AVIÃO
    -- Spawn longe o suficiente para parecer que está vindo de fora
    local spawnPos = coords + vector3(math.random(-1000, 1000), math.random(-1000, 1000), 500.0)
    plane = CreateVehicle(planeModel, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, false)
    SetEntityHeading(plane, GetHeadingFromVector_2d(coords.x - spawnPos.x, coords.y - spawnPos.y))
    
    -- Criar Piloto Invisível
    pilot = CreatePedInsideVehicle(plane, 4, guardModel, -1, true, false)
    SetBlockingOfNonTemporaryEvents(pilot, true)
    
    -- Comandar avião para voar até o ponto
    TaskVehicleDriveToCoord(pilot, plane, coords.x, coords.y, 500.0, 60.0, 0, planeModel, 262144, 1.0, true)
    
    -- Blip do Avião
    local planeBlip = AddBlipForEntity(plane)
    SetBlipSprite(planeBlip, 307)
    SetBlipColour(planeBlip, 1)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Avião de Suprimentos")
    EndTextCommandSetBlipName(planeBlip)

    -- Thread de monitoramento do voo
    CreateThread(function()
        local dropped = false
        while DoesEntityExist(plane) do
            Wait(500)
            local dist = #(GetEntityCoords(plane) - vector3(coords.x, coords.y, 500.0))
            
            -- Quando chegar perto do centro do drop, solta a caixa
            if dist < 50.0 and not dropped then
                dropped = true
                DropCrate(coords)
                
                -- Avião vai embora
                TaskVehicleDriveToCoord(pilot, plane, -5000.0, -5000.0, 800.0, 80.0, 0, planeModel, 262144, 1.0, true)
                Wait(15000)
                DeleteEntity(pilot)
                DeleteEntity(plane)
                break
            end
        end
    end)
end

function DropCrate(coords)
    local planeCoords = GetEntityCoords(plane)
    
    -- Criar a Caixa
    crate = CreateObject(crateModel, planeCoords.x, planeCoords.y, planeCoords.z - 5.0, true, true, true)
    SetEntityLodDist(crate, 1000)
    ActivatePhysics(crate)
    SetDamping(crate, 2, 0.1) -- Queda original
    
    -- Criar Paraquedas
    parachute = CreateObject(parachuteModel, planeCoords.x, planeCoords.y, planeCoords.z - 5.0, true, true, true)
    AttachEntityToEntity(parachute, crate, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    
    -- Blip da Caixa
    local crateBlip = AddBlipForEntity(crate)
    SetBlipSprite(crateBlip, 478)
    SetBlipColour(crateBlip, 5) -- Amarelo
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Airdrop em Queda")
    EndTextCommandSetBlipName(crateBlip)

    -- Monitorar queda
    CreateThread(function()
        while DoesEntityExist(crate) do
            Wait(0)
            local cCoords = GetEntityCoords(crate)
            local distGround = #(cCoords - vector3(cCoords.x, cCoords.y, coords.z))
            
            -- Simular resistência do ar do paraquedas (reduz velocidade de queda)
            ApplyForceToEntity(crate, 3, 0.0, 0.0, 10.5, 0.0, 0.0, 0.0, 0, true, true, true, false, true)

            -- Verificando pouso
            if distGround < 2.0 or HasEntityCollidedWithBound(crate) then
                DetachEntity(parachute, true, true)
                DeleteObject(parachute)
                
                -- Efeito de Sinalizador (Flare)
                local ptfxAsset = "core"
                RequestNamedPtfxAsset(ptfxAsset)
                while not HasNamedPtfxAssetLoaded(ptfxAsset) do
                    Wait(0)
                end
                UseParticleFxAssetNextCall(ptfxAsset)
                flare = StartParticleFxLoopedAtCoord("exp_grd_flare", cCoords.x, cCoords.y, cCoords.z, 0.0, 0.0, 0.0, 2.0, false, false, false, false)
                SetParticleFxLoopedColour(flare, 1.0, 0.0, 0.0, 0) -- Fumaça Vermelha
                
                -- Spawnar Guardas
                SpawnGuards(cCoords)
                
                TriggerEvent('chat:addMessage', { args = { '^1[AIRDROP]', '^7A carga pousou! Cuidado com os mercenários.' } })

                -- Iniciar Lógica de Abertura
                LootCrateLogic()
                break
            end
        end
    end)
end

-- Função auxiliar para Texto 3D (Mais visível que o aviso no canto)
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

function LootCrateLogic()
    CreateThread(function()
        local looting = false
        while DoesEntityExist(crate) do
            Wait(0)
            local pPed = PlayerPedId()
            local pPos = GetEntityCoords(pPed)
            local cPos = GetEntityCoords(crate)
            local dist = #(pPos - cPos)

            if dist < 5.0 and not looting then
                -- Desenhar Texto 3D flutuando sobre a caixa
                DrawText3D(cPos.x, cPos.y, cPos.z + 0.5, "~g~[E]~w~ Abrir Caixa de Suprimentos")

                if IsControlJustPressed(0, 38) then -- Tecla E
                    looting = true
                    
                    -- Animação de agachar/mexer
                    TaskStartScenarioInPlace(pPed, "PROP_HUMAN_BUM_BIN", 0, true)
                    
                    -- Barra de progresso interna (caso não tenha o script progressBars)
                    local timer = 5000
                    while timer > 0 do
                        Wait(0)
                        timer = timer - 10
                        DrawText3D(cPos.x, cPos.y, cPos.z + 0.7, "~y~Abrindo... ~w~" .. math.floor((5000 - timer) / 50) .. "%")
                        if not DoesEntityExist(crate) then break end
                    end
                    
                    ClearPedTasksImmediately(pPed)
                    
                    if DoesEntityExist(crate) then
                        -- 1. RECOMPENSA: ARMA + 50 MUNIÇÃO
                        local weaponHash = `WEAPON_SPECIALCARBINE`
                        GiveWeaponToPed(pPed, weaponHash, 50, false, true)
                        SetPedArmour(pPed, 100)

                        -- 2. RECOMPENSA: MOTO ALEATÓRIA
                        local bikes = {`sanchez`, `faggio`, `pcj`, `akuma`, `bf400`}
                        local randomBike = bikes[math.random(#bikes)]
                        
                        RequestModel(randomBike)
                        while not HasModelLoaded(randomBike) do Wait(0) end
                        
                        local bike = CreateVehicle(randomBike, cPos.x + 2.0, cPos.y + 2.0, cPos.z, GetEntityHeading(pPed), true, false)
                        PlaceObjectOnGroundProperly(bike)
                        SetEntityAsNoLongerNeeded(bike)

                        TriggerEvent('chat:addMessage', { args = { '^1[AIRDROP]', '^2Você encontrou suprimentos e um veículo!' } })
                        
                        -- Limpeza Final
                        if flare then StopParticleFxLooped(flare, 0) end
                        DeleteObject(crate)
                        for _, guard in ipairs(guards) do
                            if DoesEntityExist(guard) then
                                SetEntityAsNoLongerNeeded(guard)
                            end
                        end
                    end
                    break
                end
            end
        end
    end)
end

function SpawnGuards(coords)
    local _, group = AddRelationshipGroup("AIRDROP_GUARDS") -- Em Lua o hash vem no segundo retorno
    
    for i=1, 3 do
        local angle = i * 120
        local x = coords.x + math.cos(math.rad(angle)) * 5.0
        local y = coords.y + math.sin(math.rad(angle)) * 5.0
        
        local guard = CreatePed(4, guardModel, x, y, coords.z, 0.0, true, false)
        SetPedRelationshipGroupHash(guard, group)
        GiveWeaponToPed(guard, `WEAPON_CARBINERIFLE`, 250, false, true)
        SetPedArmour(guard, 100)
        SetPedCombatAttributes(guard, 46, true)
        SetPedCombatAttributes(guard, 5, true) -- Luta agressiva
        SetPedCombatMovement(guard, 2) -- Avança
        
        TaskGuardCurrentPosition(guard, 15.0, 10.0, 1)
        table.insert(guards, guard)
    end
    
    SetRelationshipBetweenGroups(5, group, `PLAYER`)
    SetRelationshipBetweenGroups(5, `PLAYER`, group)
end
