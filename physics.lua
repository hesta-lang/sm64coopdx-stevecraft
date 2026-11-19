-- SteveCraft 64 - Lua-only Minecraft Java 1.21.11 movement adaptation.
-- Reference: LocalPlayer.aiStep, LivingEntity.jumpFromGround/travelInAir,
-- AbstractClientPlayer.getFieldOfViewModifier.
-- SM64CoopDX remains responsible for surface and wall collision resolution.

SteveCraft = SteveCraft or {}
SteveCraft.physics = SteveCraft.physics or {}
local physics = SteveCraft.physics
local PI = math.pi

physics.enabled = physics.enabled ~= false
physics.reference = "Minecraft Java 1.21.11 LocalPlayer / LivingEntity / AbstractClientPlayer"

-- Provisional model-scale conversion. Calibrate in a real level before treating
-- these SM64 units as an exact Minecraft block equivalent.
local WORLD_UNITS_PER_BLOCK = 160.0 / 1.8
local MINECRAFT_TPS = 20.0
local SM64_FPS = 30.0
local TICK_TO_FRAME = MINECRAFT_TPS / SM64_FPS
local FRAMES_PER_TICK = SM64_FPS / MINECRAFT_TPS
local DEFAULT_FRICTION = 0.6
local PLAYER_MOVEMENT_SPEED = 0.1
local SPRINT_SPEED_MULTIPLIER = 1.3
local SPRINT_FOV_MULTIPLIER = 1.15
local SPRINT_DOUBLE_TAP_WINDOW = 11 -- about seven Minecraft ticks at 30 FPS
local JUMP_POWER_BLOCKS_PER_TICK = 0.42
local GRAVITY_BLOCKS_PER_TICK2 = 0.08
local VERTICAL_DRAG_PER_TICK = 0.98
-- Horizontal sprint-jump knock-on is intentionally disabled: jumps are vertical-only.

local JUMP_VELOCITY = JUMP_POWER_BLOCKS_PER_TICK
    * WORLD_UNITS_PER_BLOCK * TICK_TO_FRAME
local VERTICAL_GRAVITY, VERTICAL_DRAG = 0, 1
local states = {}
local sprint_states = {}
local warned = false
local first_person_fov_base = nil
local applied_fov_mode = nil

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
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

local function get_motion_state(m)
    local index = m.playerIndex or 0
    local state = states[index]
    if state == nil then
        state = {
            vx = (m.vel and m.vel.x) or 0.0,
            vz = (m.vel and m.vel.z) or 0.0,
            vy = (m.vel and m.vel.y) or 0.0,
            jumpActive = false,
        }
        states[index] = state
    end
    return state
end

local function get_sprint_state(m)
    local index = m.playerIndex or 0
    local state = sprint_states[index]
    if state == nil then
        state = {
            forwardWasDown = false,
            tapWindow = 0,
            sprinting = false,
        }
        sprint_states[index] = state
    end
    return state
end

local function convert_coefficients(acceleration_tick, drag_tick)
    -- Convert a 20 Hz discrete recurrence to 30 Hz while preserving its
    -- terminal velocity in the provisional SM64-units-per-block scale.
    local drag_frame = drag_tick ^ (1.0 / FRAMES_PER_TICK)
    local acceleration_frame = acceleration_tick
        * WORLD_UNITS_PER_BLOCK
        * TICK_TO_FRAME
        * (drag_tick / drag_frame)
        * ((1.0 - drag_frame) / math.max(0.000001, 1.0 - drag_tick))
    return acceleration_frame, drag_frame
end

VERTICAL_GRAVITY, VERTICAL_DRAG = convert_coefficients(
    GRAVITY_BLOCKS_PER_TICK2, VERTICAL_DRAG_PER_TICK
)

local function input_direction(m)
    -- LocalPlayer.modifyInput() applies 0.98 to non-zero movement input.
    -- Item-use and sneak multipliers are not part of this movement pass.
    local magnitude = clamp((m.intendedMag or 0.0) / 32.0, 0.0, 1.0) * 0.98
    if magnitude < 0.0001 then return 0.0, 0.0, 0.0 end
    local yaw = (m.intendedYaw or 0) * (2.0 * PI / 65536.0)
    return math.sin(yaw) * magnitude, math.cos(yaw) * magnitude, magnitude
end

local function is_forward_input(m)
    if m.intendedMag == nil or m.intendedYaw == nil or m.faceAngle == nil then
        return false
    end
    if m.intendedMag < 14.0 then
        return false
    end

    -- Treat the forward cone (including diagonal-forward input) as W input.
    local difference = ((m.intendedYaw - m.faceAngle.y + 32768) % 65536) - 32768
    local radians = difference * (2.0 * PI / 65536.0)
    return math.cos(radians) >= 0.5
end

local function restore_sprint_fov()
    if applied_fov_mode == nil then return end

    if first_person_fov_base ~= nil
        and gFirstPersonCamera ~= nil
        and gFirstPersonCamera.fov ~= nil then
        gFirstPersonCamera.fov = first_person_fov_base
    end

    if type(set_fov_function) == "function" and CAM_FOV_DEFAULT ~= nil then
        set_fov_function(CAM_FOV_DEFAULT)
    end

    applied_fov_mode = nil
end

local function apply_sprint_fov(m, sprinting)
    -- The first-person camera exposes its FOV directly to Lua, so its target
    -- follows Minecraft's (1.3 + 1) / 2 = 1.15 speed-based modifier.
    local first_person = type(get_first_person_enabled) == "function"
        and get_first_person_enabled() == true
    local can_change_first_person = gFirstPersonCamera ~= nil
        and gFirstPersonCamera.fov ~= nil

    if first_person and can_change_first_person then
        if first_person_fov_base == nil then
            first_person_fov_base = gFirstPersonCamera.fov
        end
        if applied_fov_mode ~= "first-person" then
            if type(set_fov_function) == "function" and CAM_FOV_DEFAULT ~= nil then
                set_fov_function(CAM_FOV_DEFAULT)
            end
            applied_fov_mode = "first-person"
        end

        local target = first_person_fov_base
            * (sprinting and SPRINT_FOV_MULTIPLIER or 1.0)
        local current = gFirstPersonCamera.fov
        -- GameRenderer interpolates the modifier by 0.5 each 20 Hz tick.
        local alpha = 1.0 - (0.5 ^ TICK_TO_FRAME)
        gFirstPersonCamera.fov = current + (target - current) * alpha
        return
    end

    -- Third-person LakituState has no writable FOV field in the Lua bindings.
    -- Use the engine's existing 60-degree approach preset while sprinting.
    if first_person_fov_base ~= nil and can_change_first_person then
        gFirstPersonCamera.fov = first_person_fov_base
    end

    local target_mode = sprinting and "third-person-sprint" or "third-person-normal"
    if applied_fov_mode ~= target_mode then
        if type(set_fov_function) == "function" then
            if sprinting and CAM_FOV_APP_60 ~= nil then
                set_fov_function(CAM_FOV_APP_60)
            elseif CAM_FOV_DEFAULT ~= nil then
                set_fov_function(CAM_FOV_DEFAULT)
            end
        end
        applied_fov_mode = target_mode
    end
end

local function update_sprint_input(m)
    local state = get_sprint_state(m)
    local forward_down = is_forward_input(m)

    -- Minecraft Java LocalPlayer supports double-tap forward sprinting.
    if forward_down and not state.forwardWasDown then
        if state.tapWindow > 0 then
            state.sprinting = true
        end
        state.tapWindow = SPRINT_DOUBLE_TAP_WINDOW
    elseif not forward_down then
        -- Minecraft stops ground sprinting when forward input is released.
        state.sprinting = false
    end

    if state.tapWindow > 0 then
        state.tapWindow = state.tapWindow - 1
    end
    state.forwardWasDown = forward_down

    local camera_cutscene = m.area ~= nil and m.area.camera ~= nil
        and m.area.camera.cutscene ~= nil and m.area.camera.cutscene ~= 0
    apply_sprint_fov(m, state.sprinting and not camera_cutscene)
end

local function update_horizontal_velocity(m, step_type, state, sprinting)
    local wish_x, wish_z = input_direction(m)
    local acceleration, drag

    if step_type == STEP_TYPE_GROUND then
        -- LivingEntity.getFrictionInfluencedSpeed(), plus its +30% sprint
        -- movement-speed attribute modifier.
        local friction = DEFAULT_FRICTION
        local movement_speed = PLAYER_MOVEMENT_SPEED
            * (sprinting and SPRINT_SPEED_MULTIPLIER or 1.0)
        local ground_accel = movement_speed * 0.21600002
            / (friction * friction * friction)
        acceleration, drag = convert_coefficients(
            ground_accel, friction * 0.91
        )
    else
        -- LivingEntity.travelInAir(): normal air input and horizontal drag.
        acceleration, drag = convert_coefficients(0.02, 0.91)
    end

    local move_x = state.vx + acceleration * wish_x
    local move_z = state.vz + acceleration * wish_z
    m.vel.x = move_x
    m.vel.z = move_z

    -- Save the post-drag velocity for the next 30 Hz frame.
    state.vx = move_x * drag
    state.vz = move_z * drag
    state.active = true

    if m.forwardVel ~= nil then
        m.forwardVel = math.sqrt(state.vx * state.vx + state.vz * state.vz)
    end
end

local function before_set_mario_action(m, incoming_action, action_arg)
    if not physics.enabled or not is_local_steve(m) then return end

    -- Minecraft has no SM64-style double/triple jump chain. Convert those
    -- landing transitions into the same ordinary ground jump.
    if incoming_action == ACT_DOUBLE_JUMP or incoming_action == ACT_TRIPLE_JUMP then
        return ACT_JUMP
    end
end

local function on_set_mario_action(m)
    if not physics.enabled or not is_local_steve(m) then return end
    local state = get_motion_state(m)

    if m.action == ACT_JUMP then
        -- SteveCraft's requested jump mode is strictly vertical. Do not carry
        -- Mario's forward momentum or Minecraft's sprint-jump horizontal
        -- knock-on into the jump; both produced visible sideways drift.
        state.jumpActive = true
        state.vy = JUMP_VELOCITY
        state.vx = 0.0
        state.vz = 0.0
        if m.vel ~= nil then
            m.vel.x = 0.0
            m.vel.y = state.vy
            m.vel.z = 0.0
        end
        if m.slideVelX ~= nil then m.slideVelX = 0.0 end
        if m.slideVelZ ~= nil then m.slideVelZ = 0.0 end
        if m.forwardVel ~= nil then m.forwardVel = 0.0 end
    elseif m.action == ACT_FREEFALL then
        if not state.jumpActive then
            state.vy = (m.vel and m.vel.y) or 0.0
        end
        state.jumpActive = true
    elseif not is_air_action(m.action) then
        state.jumpActive = false
        state.vy = 0.0
    end
end

local function before_physics_step(m, step_type, step_arg)
    if not is_local_steve(m) then
        if m ~= nil then
            states[m.playerIndex or 0] = nil
            sprint_states[m.playerIndex or 0] = nil
        end
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
    local state = get_motion_state(m)

    -- Reseed horizontal momentum after a wall collision. Vertical movement
    -- still uses the original SM64 surface solver.
    if m.wall ~= nil then
        state.vx = m.vel.x or 0.0
        state.vz = m.vel.z or 0.0
    end

    if air and state.jumpActive then
        -- Apply vertical movement only. Clear all horizontal channels after
        -- Mario's native airborne controller has processed the stick input.
        -- The original SM64 air-step collision solver still handles landings
        -- and ceilings, but no horizontal velocity is fed into the step.
        m.vel.x = 0.0
        m.vel.y = state.vy or 0.0
        m.vel.z = 0.0
        if m.forwardVel ~= nil then m.forwardVel = 0.0 end
        if m.slideVelX ~= nil then m.slideVelX = 0.0 end
        if m.slideVelZ ~= nil then m.slideVelZ = 0.0 end
        state.vx = 0.0
        state.vz = 0.0
        return
    end

    local sprint = step_type == STEP_TYPE_GROUND
        and sprint_states[index] ~= nil
        and sprint_states[index].sprinting == true
    update_horizontal_velocity(m, step_type, state, sprint)
end

local function after_mario_update(m)
    if m == nil or m.playerIndex ~= 0 then return end
    if not is_local_steve(m) or not physics.enabled then
        states[0] = nil
        sprint_states[0] = nil
        restore_sprint_fov()
        return
    end

    -- HOOK_MARIO_UPDATE runs after controller intent has been calculated.
    -- The resulting sprint state is consumed by the next physics step.
    update_sprint_input(m)

    local state = states[0]
    if state ~= nil then
        if state.jumpActive and is_air_action(m.action) then
            -- Minecraft applies vertical drag and gravity after movement.
            -- Reading m.vel.y here also respects the solver's ceiling response.
            local actual_vertical = (m.vel and m.vel.y) or state.vy or 0.0
            state.vy = actual_vertical * VERTICAL_DRAG - VERTICAL_GRAVITY
        elseif not is_air_action(m.action) then
            state.jumpActive = false
            state.vy = 0.0
        end

        -- Idle, crouch, cutscenes, water and other unsupported actions must not
        -- inherit the cached Minecraft ground/air momentum.
        if not is_ground_action(m.action) and not is_air_action(m.action) then
            states[0] = nil
        end
    end
end

function physics.set_enabled(enabled)
    physics.enabled = enabled == true
    states = {}
    sprint_states = {}
    restore_sprint_fov()
end

function physics.is_enabled()
    return physics.enabled
end

function physics.is_sprinting()
    local state = sprint_states[0]
    return physics.enabled and state ~= nil and state.sprinting == true
end

function physics.reset()
    states = {}
    sprint_states = {}
    restore_sprint_fov()
end

hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)
hook_event(HOOK_BEFORE_PHYS_STEP, before_physics_step)
hook_event(HOOK_MARIO_UPDATE, after_mario_update)
hook_event(HOOK_ON_LEVEL_INIT, physics.reset)
hook_event(HOOK_ON_WARP, physics.reset)
hook_event(HOOK_ON_EXIT, physics.reset)

print("[SteveCraft 64] Lua Minecraft sprint/jump movement layer loaded")
