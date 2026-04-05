Config = {}

Config.AccessControl = {
    [1] = "Dono", -- ID 1 (Richard/RZSISTEMA) é Dono total
}

Config.Ranks = {
    ["Dono"] = 3,
    ["Admin"] = 2,
    ["Moderador"] = 1,
    ["Player"] = 0
}

Config.OpenKey = 121 -- Tecla INSERT (Comum para menus de administração)

-- Categorias de Veículos para o Spawner
Config.Vehicles = {
    { category = "Esportivos", models = {"adder", "zentorno", "t20", "turismor", "osiris"} },
    { category = "Motos", models = {"sanchez", "akuma", "bati", "double", "gargoyle"} },
    { category = "SUVs/Off-Road", models = {"baller", "dubsta", "monster", "mesa"} },
    { category = "Serviço", models = {"police", "ambulance", "firetruck", "taxi"} }
}

-- Objetos de Sinalização / Obstáculos
Config.Objects = {
    { name = "Cone", model = "prop_roadcone02a" },
    { name = "Barreira Amarela", model = "prop_barrier_work05" },
    { name = "Barreira Concreto", model = "prop_mp_barrier_02b" },
    { name = "Poste Luz", model = "prop_streetlight_01" }
}
