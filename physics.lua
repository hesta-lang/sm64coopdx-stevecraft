-- SteveCraft 64 - Lua-only Minecraft movement adaptation.
-- Reverse-ported from Minecraft Java 1.21.11 Entity/LivingEntity travel.
-- Uses HOOK_BEFORE_PHYS_STEP to change velocity, then leaves collision to SM64.

SteveCraft = SteveCraft or {}
SteveCraft.physics = SteveCraft.physics or {}
local physics = SteveCraft.physics
local PI = math.pi

physics.enabled = physics.enabled ~= false
physics.reference = "Minecraft Java 1.21.11 Entity.moveRelative / LivingEntity.travel"

-- Provisional model-scale conversion from the previous Steve model pipeline.
-- Calibrate against in-game distances before claiming exact world equivalence.
local WORLD_UNITS_PER_BLOCK = 160.0 / 1.8
local MINECRAFT_TPS = 20.0
local SM64_FPS = 30.0
local FRAMES_PER_TICK = SM64_FPS / MINECRAFT_TPS
local DEFAULT_FRICTION = 0.6
local PLAYER_MOVEMENT_SPEED = 0.1

local states = {}
local warned = false

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function is_local_steve(m)
    local character = SteveCraft.character
    return m ~= nil
        and m.playerIndex == 0
        and character ~= nil
        and character.ready
        and character.modelId ~= nil
        and gPlayerSyncTable ~= nil
        and gPlayerSyncTable[0] ~= nil
        and gPlayerSyncTable[0].modelId == character.modelId
end

local function is_ground_action(action)
    return ACT_WALKING ~= nil and action == ACT_WALKING
end

local function is_air_action(action)
    return (ACT_JUMP ~= nil and action == ACT_JUMP)
        or (ACT_DOUBLE_JUMP ~= nil and action == ACT_DOUBLE_JUMP)
        or (ACT_TRIPLE_JUMP ~= nil and action == ACT_TRIPLE_JUMP)
        or (ACT_FREEFALL ~= nil and action == ACT_FREEFALL)
end

local function input_direction(m)
    local magnitude = clamp((m.intendedMag or 0.0) / 32.0, 0.0, 1.0)
    if magnitude < 0.0001 then return 0.0, 0.0 end
    local yaw = (m.intendedYaw or 0) * (2.0 * PI / 65536.0)
    return math.sin(yaw) * magnitude, math.cos(yaw) * magnitude
end

local function convert_coefficients(acceleration_tick, drag_tick)
    -- Convert the 20 Hz discrete recurrence to 30 Hz while preserving its
    -- terminal velocity. SM64 units/frame and Minecraft blocks/tick differ.
    local drag_frame = drag_tick ^ (1.0 / FRAMES_PER_TICK)
    local acceleration_frame = acceleration_tick
        * WORLD_UNITS_PER_BLOCK
        * (MINECRAFT_TPS / SM64_FPS)
        * ((1.0 - drag_frame) / math.max(0.000001, 1.0 - drag_tick))
    return acceleration_frame, drag_frame
end

local function update_horizontal_velocity(m, step_type, state)
    local wish_x, wish_z = input_direction(m)
    local acceleration, drag

    if step_type == STEP_TYPE_GROUND then
        -- Minecraft ground input: movementSpeed * 0.21600002 / friction^3.
        local friction = DEFAULT_FRICTION
        local ground_accel = PLAYER_MOVEMENT_SPEED * 0.21600002
            / (friction * friction * friction)
        acceleration, drag = convert_coefficients(
            ground_accel, friction * 0.91
        )
    else
        -- Minecraft ordinary air travel: 0.02 input acceleration, 0.91 drag.
        acceleration, drag = convert_coefficients(0.02, 0.91)
    end

    -- The collision solver consumes the pre-drag velocity for this frame.
    local move_x = state.vx + acceleration * wish_x
    local move_z = state.vz + acceleration * wish_z
    m.vel.x = move_x
    m.vel.z = move_z

    -- Retain the post-drag velocity for the next 30 Hz frame.
    state.vx = move_x * drag
    state.vz = move_z * drag
    state.active = true

    if m.forwardVel ~= nil then
        m.forwardVel = math.sqrt(state.vx * state.vx + state.vz * state.vz)
    end
end

function physics.set_enabled(enabled)
    physics.enabled = enabled == true
    states = {}
end

function physics.is_enabled()
    return physics.enabled
end

function physics.reset()
    states = {}
end

local function before_physics_step(m, step_type, step_arg)
    if not is_local_steve(m) then
        if m ~= nil then states[m.playerIndex or 0] = nil end
        return
    end

    if not physics.enabled then
        states[m.playerIndex or 0] = nil
        return
    end

    if m.vel == nil or m.intendedMag == nil or m.intendedYaw == nil
        or STEP_TYPE_GROUND == nil or STEP_TYPE_AIR == nil then
        if not warned then
            print("[SteveCraft 64] Physics API fields unavailable; keeping SM64 movement.")
            warned = true
        end
        return
    end

    local ground = step_type == STEP_TYPE_GROUND and is_ground_action(m.action)
    local air = step_type == STEP_TYPE_AIR and is_air_action(m.action)
    if not ground and not air then
        states[m.playerIndex or 0] = nil
        return
    end

    local index = m.playerIndex or 0
    local state = states[index]
    if state == nil then
        state = { vx = m.vel.x or 0.0, vz = m.vel.z or 0.0 }
        states[index] = state
    end

    -- Re-seed the cache when the SM64 solver has registered a wall contact.
    if m.wall ~= nil then
        state.vx = m.vel.x or 0.0
        state.vz = m.vel.z or 0.0
    end

    update_horizontal_velocity(m, step_type, state)
end

local function after_mario_update(m)
    if m == nil or m.playerIndex ~= 0 then return end
    if not is_local_steve(m) then
        states[0] = nil
        return
    end
    -- Stationary Mario actions do not call perform_ground_step(), so clear
    -- cached momentum here rather than carrying it into the next walk.
    if not is_ground_action(m.action) and not is_air_action(m.action) then
        states[0] = nil
    end
end

hook_event(HOOK_BEFORE_PHYS_STEP, before_physics_step)
hook_event(HOOK_MARIO_UPDATE, after_mario_update)
hook_event(HOOK_ON_LEVEL_INIT, physics.reset)
hook_event(HOOK_ON_WARP, physics.reset)

print("[SteveCraft 64] Lua Minecraft movement layer loaded")
