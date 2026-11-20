-- SteveCraft: independent Lua port of Minecraft Java 26.3 player movement.
-- Source references are recorded in CAMERA_REFERENCE.md / TRANSPILER.md.
-- The module preserves Minecraft's 20 TPS equations and exposes a 30 FPS
-- conversion for SM64CoopDX. World collision remains an engine adapter boundary.

local P = {}

P.TPS = 20.0
P.FRAME_RATE = 30.0
P.TICK_TO_FRAME = P.TPS / P.FRAME_RATE
P.WORLD_UNITS_PER_BLOCK = 160.0 / 1.8 -- provisional Steve/Mario scale; calibrate in game
P.DEFAULT_MOVEMENT_SPEED = 0.1
P.DEFAULT_BLOCK_FRICTION = 0.6
P.DEFAULT_AIR_FRICTION = 0.91
P.DEFAULT_GRAVITY = 0.08
P.DEFAULT_VERTICAL_DRAG = 0.98
P.DEFAULT_JUMP_STRENGTH = 0.42
P.DEFAULT_SNEAKING_SPEED = 0.3
P.DEFAULT_ITEM_USE_SPEED = 0.2
P.SPRINT_SPEED_MODIFIER = 1.3
P.SPRINT_JUMP_IMPULSE = 0.2
P.GROUND_SPEED_FACTOR = 0.21600002
P.INPUT_SCALE = 0.98

local PI = math.pi

local function clamp(x, lo, hi)
    return math.max(lo, math.min(hi, x))
end

local function finite_or(value, fallback)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    return value
end

function P.wrap_angle(radians)
    local full = 2.0 * PI
    radians = radians % full
    if radians > PI then radians = radians - full end
    return radians
end

-- LocalPlayer.modifyInputSpeedForSquareMovement: preserve direction while
-- mapping input magnitude to the boundary of a unit square, then cap at 1.
function P.modify_square_input(x, z)
    x, z = finite_or(x, 0), finite_or(z, 0)
    local length = math.sqrt(x * x + z * z)
    if length <= 1.0e-12 then return 0, 0 end
    local nx, nz = x / length, z / length
    local max_axis = math.max(math.abs(nx), math.abs(nz))
    if max_axis <= 1.0e-12 then return 0, 0 end
    local distance_to_square = 1.0 / max_axis
    local modified_length = math.min(length * distance_to_square, 1.0)
    return nx * modified_length, nz * modified_length
end

-- Reconstruct the player's local side/forward impulses from the SM64 intent
-- angle, apply LocalPlayer.modifyInput multipliers, then rotate into world axes.
-- Options correspond to source-side conditions that SM64 does not expose.
function P.input_from_intent(intended_magnitude, intended_yaw, body_yaw, options)
    options = options or {}
    intended_magnitude = clamp(finite_or(intended_magnitude, 0) / 32.0, 0.0, 1.0)
    if intended_magnitude <= 1.0e-8 then return 0, 0, 0, 0 end

    local delta = P.wrap_angle(
        (finite_or(intended_yaw, 0) - finite_or(body_yaw, 0)) * (2.0 * PI / 65536.0)
    )
    local side = math.sin(delta) * intended_magnitude * P.INPUT_SCALE
    local forward = math.cos(delta) * intended_magnitude * P.INPUT_SCALE

    if options.usingItem then
        side = side * finite_or(options.itemUseSpeed, P.DEFAULT_ITEM_USE_SPEED)
        forward = forward * finite_or(options.itemUseSpeed, P.DEFAULT_ITEM_USE_SPEED)
    end
    if options.sneaking then
        side = side * finite_or(options.sneakingSpeed, P.DEFAULT_SNEAKING_SPEED)
        forward = forward * finite_or(options.sneakingSpeed, P.DEFAULT_SNEAKING_SPEED)
    end

    side, forward = P.modify_square_input(side, forward)

    local yaw = finite_or(body_yaw, 0) * (2.0 * PI / 65536.0)
    local sin_yaw, cos_yaw = math.sin(yaw), math.cos(yaw)
    local world_x = side * cos_yaw + forward * sin_yaw
    local world_z = forward * cos_yaw - side * sin_yaw
    return world_x, world_z, forward, side
end

-- Convert one Minecraft per-tick affine velocity recurrence into its
-- fractional 30-FPS step. With constant input, 1.5 frame steps compose to the
-- original 20-TPS recurrence; position scale is 20/30 block units per frame.
function P.tick_coefficients(acceleration_per_tick, drag_per_tick, units_per_block)
    local acceleration = finite_or(acceleration_per_tick, 0)
    local drag = clamp(finite_or(drag_per_tick, 1), 0.0, 1.0)
    local units = finite_or(units_per_block, P.WORLD_UNITS_PER_BLOCK)
    if drag >= 1.0 - 1.0e-12 then
        return acceleration * units * P.TICK_TO_FRAME, 1.0
    end
    if drag <= 1.0e-12 then
        return acceleration * units * P.TICK_TO_FRAME, 0.0
    end
    local frame_drag = drag ^ P.TICK_TO_FRAME
    local frame_acceleration = acceleration * units * P.TICK_TO_FRAME
        * (drag / frame_drag)
        * ((1.0 - frame_drag) / (1.0 - drag))
    return frame_acceleration, frame_drag
end

-- LivingEntity.getFrictionInfluencedSpeed + travelInAir friction.
function P.horizontal_parameters(on_ground, block_friction, movement_speed, sprinting)
    block_friction = math.max(0.0, finite_or(block_friction, P.DEFAULT_BLOCK_FRICTION))
    movement_speed = math.max(0.0, finite_or(movement_speed, P.DEFAULT_MOVEMENT_SPEED))
    if on_ground then
        if sprinting then movement_speed = movement_speed * P.SPRINT_SPEED_MODIFIER end
        -- LivingEntity.getFrictionInfluencedSpeed applies this factor for
        -- every block slipperiness (0.6 default => multiplier 1.0).
        movement_speed = movement_speed * P.GROUND_SPEED_FACTOR
            / math.max(1.0e-9, block_friction ^ 3)
        local drag = block_friction * P.DEFAULT_AIR_FRICTION
        local accel_frame, drag_frame = P.tick_coefficients(movement_speed, drag)
        return accel_frame, drag_frame, movement_speed, drag
    end
    local accel_frame, drag_frame = P.tick_coefficients(0.02, P.DEFAULT_AIR_FRICTION)
    return accel_frame, drag_frame, 0.02, P.DEFAULT_AIR_FRICTION
end

-- Applies the Minecraft movement acceleration before move(), returning the
-- displacement velocity in SM64 units/frame and the cached post-friction speed.
function P.horizontal_step(vx, vz, input_x, input_z, on_ground, block_friction, sprinting)
    local acceleration, drag = P.horizontal_parameters(
        on_ground, block_friction, P.DEFAULT_MOVEMENT_SPEED, sprinting
    )
    local next_x = finite_or(vx, 0) + acceleration * finite_or(input_x, 0)
    local next_z = finite_or(vz, 0) + acceleration * finite_or(input_z, 0)
    return next_x, next_z, next_x * drag, next_z * drag, acceleration, drag
end

-- LivingEntity travel: gravity is applied before vertical friction.
function P.apply_vertical_friction(velocity_y, gravity, vertical_drag, units_per_block)
    gravity = finite_or(gravity, P.DEFAULT_GRAVITY)
    vertical_drag = clamp(finite_or(vertical_drag, P.DEFAULT_VERTICAL_DRAG), 0.0, 1.0)
    local gravity_frame, drag_frame = P.tick_coefficients(gravity, vertical_drag, units_per_block)
    return (finite_or(velocity_y, 0) - gravity_frame) * drag_frame, gravity_frame, drag_frame
end

function P.jump_velocity(jump_strength, block_jump_factor, jump_boost, units_per_block)
    jump_strength = finite_or(jump_strength, P.DEFAULT_JUMP_STRENGTH)
    block_jump_factor = finite_or(block_jump_factor, 1.0)
    jump_boost = finite_or(jump_boost, 0.0)
    local tick_velocity = jump_strength * block_jump_factor + jump_boost
    return tick_velocity * finite_or(units_per_block, P.WORLD_UNITS_PER_BLOCK) * P.TICK_TO_FRAME
end

-- Minecraft jumpFromGround keeps existing horizontal velocity. Sprinting adds
-- an impulse in the player's facing direction; no Mario-style jump chain exists.
function P.sprint_jump_impulse(vx, vz, body_yaw, sprinting, units_per_block)
    if not sprinting then return finite_or(vx, 0), finite_or(vz, 0) end
    local yaw = finite_or(body_yaw, 0) * (2.0 * PI / 65536.0)
    local impulse = P.SPRINT_JUMP_IMPULSE
        * finite_or(units_per_block, P.WORLD_UNITS_PER_BLOCK) * P.TICK_TO_FRAME
    return finite_or(vx, 0) + math.sin(yaw) * impulse,
        finite_or(vz, 0) + math.cos(yaw) * impulse
end

-- Source-side sprint trigger: forward impulse rising edge, configurable
-- Minecraft sprint window, and stop while forward is released/blocked.
function P.update_sprint(state, forward_impulse, can_start, sprint_window_frames)
    state = state or {}
    state.forwardWasDown = state.forwardWasDown == true
    state.tapWindow = math.max(0, math.floor(finite_or(state.tapWindow, 0)))
    state.sprinting = state.sprinting == true
    sprint_window_frames = math.max(1, math.floor(finite_or(sprint_window_frames, 11)))
    local forward_down = finite_or(forward_impulse, 0) > 0.0
    if not can_start or not forward_down then
        state.sprinting = false
    elseif forward_down and not state.forwardWasDown then
        if state.tapWindow > 0 then
            state.sprinting = true
        else
            state.tapWindow = sprint_window_frames
        end
    end
    if state.tapWindow > 0 then state.tapWindow = state.tapWindow - 1 end
    state.forwardWasDown = forward_down
    return state
end

function P.is_sneaking_action(action)
    return (ACT_START_CROUCHING ~= nil and action == ACT_START_CROUCHING)
        or (ACT_CROUCHING ~= nil and action == ACT_CROUCHING)
        or (ACT_STOP_CROUCHING ~= nil and action == ACT_STOP_CROUCHING)
end

return P
