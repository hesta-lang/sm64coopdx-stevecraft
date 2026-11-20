-- SteveCraft 64 - replacement for Mario's native geometry-input prepass.
--
-- HOOK_MARIO_OVERRIDE_GEOMETRY_INPUTS skips update_mario_geometry_inputs(),
-- including f32_find_wall_collision() and Mario's native position correction.
-- This module supplies only the contact/input data the rest of the host engine
-- needs. Movement and contact resolution are handled by SteveCraft's Lua solver.

local G = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function safe_floor(x, y, z)
    if type(find_floor) ~= "function" then return nil, nil end
    local ok, height, surface = pcall(find_floor, x, y, z)
    if not ok or not finite(height) or surface == nil then return nil, nil end
    return height, surface
end

local function safe_ceil(x, y, z)
    if type(find_ceil) ~= "function" then return nil, nil end
    local ok, height, surface = pcall(find_ceil, x, y, z)
    if not ok or not finite(height) then return nil, nil end
    return height, surface
end

local function safe_level(fn, x, z, fallback)
    if type(fn) ~= "function" then return fallback end
    local ok, level = pcall(fn, x, z)
    if ok and finite(level) then return level end
    return fallback
end

local function set_component(vector, key, value)
    if vector == nil or not finite(value) then return end
    pcall(function() vector[key] = value end)
end

local function set_field(object, key, value)
    if object == nil then return end
    pcall(function() object[key] = value end)
end

local function update_input_flag(m, flag, enabled)
    if type(flag) ~= "number" or flag == 0 then return end
    local input = m.input or 0
    input = input & (~flag)
    if enabled then input = input | flag end
    set_field(m, "input", input)
end

local function floor_angle(surface)
    if surface == nil or surface.normal == nil then return 0 end
    local normal = surface.normal
    local nx, nz = normal.x or 0, normal.z or 0
    if math.abs(nx) + math.abs(nz) < 1e-9 then return 0 end
    return math.floor(math.atan(nz, nx) * (32768 / math.pi))
end

-- Refreshes native MarioState geometry fields without allowing Mario's
-- geometry updater to move the player or resolve wall penetration.
-- Returns a compact contact state used by the Minecraft movement controller.
function G.update(m, state, config)
    if m == nil or m.pos == nil or state == nil then return false end
    config = config or {}

    local x, y, z = m.pos.x, m.pos.y, m.pos.z
    if not finite(x) or not finite(y) or not finite(z) then return false end

    local units = config.unitsPerBlock or 88.8888888889
    local playerHeight = config.height or units * 1.8
    local stepHeight = config.stepHeight or units * 0.6

    -- Query for the closest support surface just above the feet. The query
    -- reads the level's collision data; it does not perform any positional clip.
    local floorHeight, floor = safe_floor(x, y + math.max(2, stepHeight * 0.05), z)
    if floor ~= nil then
        state.lastFloorSurface = floor
        state.lastFloorHeight = floorHeight
    end

    -- Keep a valid host floor pointer while airborne. execute_mario_action()
    -- otherwise exits early when MarioState.floor is NULL before calling Lua's
    -- action hook. SteveCraft independently decides whether the player is grounded.
    local hostFloor = floor or state.lastFloorSurface
    local hostFloorHeight = floorHeight or state.lastFloorHeight
    if hostFloor == nil and type(get_water_surface_pseudo_floor) == "function" then
        local ok, pseudo = pcall(get_water_surface_pseudo_floor)
        if ok then hostFloor = pseudo end
    end
    set_field(m, "floor", hostFloor)
    set_field(m, "floorHeight", finite(hostFloorHeight) and hostFloorHeight or y)

    local ceilingHeight, ceiling = safe_ceil(x, y + playerHeight, z)
    set_field(m, "ceil", ceiling)
    set_field(m, "ceilHeight", finite(ceilingHeight) and ceilingHeight or 11000)

    local waterLevel = safe_level(find_water_level, x, z, -11000)
    local gasLevel = safe_level(find_poison_gas_level, x, z, -11000)
    set_field(m, "waterLevel", waterLevel)

    -- Mario's wall state is not authoritative in the independent controller.
    set_field(m, "wall", nil)
    set_component(m.wallNormal, "x", 0)
    set_component(m.wallNormal, "y", 0)
    set_component(m.wallNormal, "z", 0)

    local grounded = floor ~= nil
        and math.abs(y - floorHeight) <= (config.groundTolerance or 6.0)
    local inWater = y < waterLevel - 10.0
    local inPoisonGas = y < gasLevel - 100.0

    state.floorSurface = floor or state.lastFloorSurface
    state.floorHeight = hostFloorHeight
    state.ceilingSurface = ceiling
    state.ceilingHeight = ceilingHeight
    state.waterLevel = waterLevel
    state.poisonGasLevel = gasLevel
    state.onGround = grounded
    state.inWater = inWater

    set_field(m, "floorAngle", floor_angle(floor))
    set_field(m, "quicksandDepth", 0)

    -- The original geometry updater also set these four flags. Rebuild the
    -- useful environment flags while intentionally omitting Mario's slope-slide
    -- and dynamic-ceiling/squish rules.
    update_input_flag(m, INPUT_OFF_FLOOR, not grounded)
    update_input_flag(m, INPUT_IN_WATER, inWater)
    update_input_flag(m, INPUT_IN_POISON_GAS, inPoisonGas)
    update_input_flag(m, INPUT_ABOVE_SLIDE, false)
    update_input_flag(m, INPUT_SQUISHED, false)

    return true
end

return G
