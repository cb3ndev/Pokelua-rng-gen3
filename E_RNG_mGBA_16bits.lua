--SCRIPT LUA para revisar avances de RNG y numero de frames
--Normalmente el juego avanza el rng al mismo ritmo que los frames (60 fps en emulador o 59.7275 en GBA)
--pero algunos eventos hacen que avance algunos rngs más, el script mapea esos avances
--Además mapea los inputs y permite introducir inputs automaticos en frames especificos
--*****Nota****: Los avances NO FUNCIONARAN en un juego nuevo (aparecerá -1), 
--pues como el juego si genera una semilla diferente de 0 la primera ves que se juega, el script no
--lo detecta bien, el script esta hecho para partidas cargadas pues el seed de Esmeralda siempre se resetea a 0

-- Dirección del seed: descomentar la que corresponda
--local rng_addr = 0x03005AE0 -- Seed address para Esmeralda JPN/JAP
local rng_addr = 0x03005D80 -- Seed address para Esmeralda ESP/USA

local LCRNG_MULT = 0x41C64E6D --valores para el algoritmo RNG (LCG)
local LCRNG_ADD  = 0x6073
local SEED_INICIAL = 0x00000000 -- Seed inicial típico en Esmeralda (seed=0)
--Si el juego es Rubi Zafiro, la semilla cuando estos tienen la batería agotada es siempre:
--local SEED_INICIAL = 0x5A0

-- Variables internas
local prev_rng, prev_frame, avance_global, last_printed_frame

-- ## INICIO DE LA SECCIÓN DE INPUTS ##
--Solo usar si se quiere introducir inputs automáticos, por defecto esta vacía
--ejemplo:
--local inputs_a_presionar = {
--    [250] = "A",
--    [724] = "Left",
--}
-- Variables para presionar botones en ciertos frames.
-- La estructura es: [frame] = "BOTON" o [frame] = {"BOTON1", "BOTON2"}
-- Puedes usar "A", "B", "Start", "Select", "Up", "Down", "Left", "Right", "L", "R"
local inputs_a_presionar = {
}

-- Mapa de nombres de botones a constantes del emulador
local key_map = {
    ["A"] = C.GBA_KEY.A,
    ["B"] = C.GBA_KEY.B,
    ["Select"] = C.GBA_KEY.SELECT,
    ["Start"] = C.GBA_KEY.START,
    ["Right"] = C.GBA_KEY.RIGHT,
    ["Left"] = C.GBA_KEY.LEFT,
    ["Up"] = C.GBA_KEY.UP,
    ["Down"] = C.GBA_KEY.DOWN,
    ["R"] = C.GBA_KEY.R,
    ["L"] = C.GBA_KEY.L,
}

-- Almacena los botones que el script presionó en el frame anterior para liberarlos
local keys_pressed_by_script = {}


-- ## FIN DE LA SECCIÓN DE INPUTS ##

function reset_vars()
    prev_rng = nil
    prev_frame = nil
    avance_global = nil
    last_printed_frame = nil
    keys_pressed_by_script = {} -- Limpiar también al resetear
end

function count_rng_advances(old, new)
    local count = 0
    local temp = old
    if old == new then return 0 end
    while count < 20 do
        temp = (temp * LCRNG_MULT + LCRNG_ADD) % 0x100000000
        count = count + 1
        if temp == new then
            return count
        end
    end
    return -1
end

function calcular_avance_real(seed_inicial, rng_actual)
    local avance = 0
    local temp = seed_inicial
    if seed_inicial == rng_actual then return 0 end
    while avance < 100000 do
        temp = (temp * LCRNG_MULT + LCRNG_ADD) % 0x100000000
        avance = avance + 1
        if temp == rng_actual then
            return avance
        end
    end
    return -1
end

function get_nth_rng(old, n)
    local temp = old
    for i = 1, n do
        temp = (temp * LCRNG_MULT + LCRNG_ADD) % 0x100000000
    end
    return temp
end

function pad(s, n)
    s = tostring(s)
    return s .. string.rep(" ", math.max(0, n - #s))
end

function get_input_string()
    local btns = {
        {"A",      C.GBA_KEY.A},
        {"B",      C.GBA_KEY.B},
        {"Select", C.GBA_KEY.SELECT},
        {"Start",  C.GBA_KEY.START},
        {"Right",  C.GBA_KEY.RIGHT},
        {"Left",   C.GBA_KEY.LEFT},
        {"Up",     C.GBA_KEY.UP},
        {"Down",   C.GBA_KEY.DOWN},
        {"R",      C.GBA_KEY.R},
        {"L",      C.GBA_KEY.L},
    }
    local pressed = {}
    for _,btn in ipairs(btns) do
        if emu:getKey(btn[2]) == 1 then
            table.insert(pressed, btn[1])
        end
    end
    if #pressed == 0 then
        return "-"
    else
        return table.concat(pressed, "+")
    end
end

-- ========= CAMBIO: helper para mostrar los 16 bits superiores en decimal =========
local function upper16_dec(n)
    return math.floor(n / 0x10000)
end
-- ================================================================================

function on_frame()
    local curr_rng = emu:read32(rng_addr)
    local curr_frame = emu:currentFrame()
    local input = get_input_string()
    local avance_actual = calcular_avance_real(SEED_INICIAL, curr_rng)

    -- ## INICIO DE LA LÓGICA DE INPUT AUTOMÁTICO ##

    -- 1. Liberar los botones que el script presionó en el frame anterior
    if #keys_pressed_by_script > 0 then
        for _, key_constant in ipairs(keys_pressed_by_script) do
            emu:clearKey(key_constant)
        end
        keys_pressed_by_script = {} -- Limpiar la tabla
    end

    -- 2. Presionar los botones correspondientes al frame actual
    local buttons_to_press = inputs_a_presionar[curr_frame]
    if buttons_to_press then
        -- Asegurarse de que sea una tabla para poder iterar siempre
        if type(buttons_to_press) == "string" then
            buttons_to_press = {buttons_to_press}
        end

        for _, button_name in ipairs(buttons_to_press) do
            local key_constant = key_map[button_name]
            if key_constant then
                emu:addKey(key_constant)
                table.insert(keys_pressed_by_script, key_constant) -- Recordar liberarlo
            end
        end
    end

    -- ## FIN DE LA LÓGICA DE INPUT AUTOMÁTICO ##

    if prev_rng and (last_printed_frame ~= curr_frame) then
        local advances = count_rng_advances(prev_rng, curr_rng)
        if advances == 1 then
            print(string.format(
                "[RNG  NORMAL  ] Frame: %s | Avance: %s | RNG: %d | Input: %s",
                pad(curr_frame, 6), pad(avance_actual, 6), upper16_dec(curr_rng), input
            ))
        elseif advances > 1 then
            for i = 1, advances do
                local rng_val = get_nth_rng(prev_rng, i)
                print(string.format(
                    "[RNG MULTIPLE] Frame: %s | Avance: %s | RNG: %d | (Avance #%d/%d) | Input: %s",
                    pad(curr_frame, 6), pad(calcular_avance_real(SEED_INICIAL, rng_val), 6),
                    upper16_dec(rng_val), i, advances, input
                ))
            end
        elseif advances == 0 then
            -- No imprimir nada si el RNG no cambió
        else
            print(string.format(
                "[RNG ANÓMALO ] Frame: %s | Avance: %s | RNG: %d -> %d | Avances: ?? | Input: %s",
                pad(curr_frame, 6), pad(avance_actual, 6),
                upper16_dec(prev_rng), upper16_dec(curr_rng), input
            ))
        end
        last_printed_frame = curr_frame
    end

    prev_rng = curr_rng
    prev_frame = curr_frame
end

-- Reinicia variables al cargar el script
reset_vars()

-- Añade el callback de frame y reset
callbacks:add("frame", on_frame)
callbacks:add("reset", reset_vars)
callbacks:add("loadstate", reset_vars)
