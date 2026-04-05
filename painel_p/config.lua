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

-- Tecla de abertura (INSERT)
Config.OpenKey = 121

-- CATEGORIAS DE VEÍCULOS (Lista Estendida RZSISTEMA)
Config.Vehicles = {
    { category = "Super", models = {"adder", "zentorno", "t20", "turismor", "osiris", "entityxf", "cheetah", "vacca"} },
    { category = "Esportivos", models = {"9f", "carbonizzare", "coquette", "feltzer", "furoregt", "kuruma", "sultan"} },
    { category = "Motos", models = {"akuma", "bati", "double", "hakuchou", "sanchez", "gargoyle", "faggio"} },
    { category = "Off-Road", models = {"bifta", "blazer", "dubsta3", "monster", "mesa3", "sandking"} },
    { category = "Aeronaves", models = {"buzzard", "besra", "hydra", "luxor", "mammatus", "titan"} },
    { category = "Serviço", models = {"police", "police2", "police3", "pranger", "sheriff", "ambulance", "firetruck"} }
}

-- OBJETOS DE SINALIZAÇÃO / OBSTÁCULOS (RP Completo)
Config.Objects = {
    { name = "Cone Médio", model = "prop_roadcone02a" },
    { name = "Cone Grande", model = "prop_roadcone01a" },
    { name = "Barreira Amarela (Obra)", model = "prop_barrier_work05" },
    { name = "Barreira Concreto", model = "prop_mp_barrier_02b" },
    { name = "Barreira Policial", model = "prop_mp_barrier_02" },
    { name = "Poste de Luz Urbano", model = "prop_streetlight_01" },
    { name = "Rampa de Salto", model = "lts_prop_lts_ramp_01" },
    { name = "Caixa de Metal", model = "prop_box_connat_01a" }
}

-- TIPOS DE CLIMA
Config.WeatherTypes = {
    { label = "Extra Ensolarado", value = "EXTRASUNNY" },
    { label = "Céu Limpo", value = "CLEAR" },
    { label = "Nublado", value = "CLOUDS" },
    { label = "Chuva", value = "RAIN" },
    { label = "Trovoada", value = "THUNDER" },
    { label = "Nevoeiro", value = "SMOG" },
    { label = "Neve (Natal)", value = "XMAS" }
}
