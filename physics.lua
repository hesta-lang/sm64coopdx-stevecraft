-- SteveCraft 64 - Minecraft Java Edition 26.3 movement port.
-- The source-side equations live in minecraft_26_3_physics.lua.
-- SM64CoopDX still owns actual geometry collision and MarioState integration.

SteveCraft = SteveCraft or {}
SteveCraft.physics = SteveCraft.physics or {}
local physics = SteveCraft.physics
local PI = math.pi
local MinecraftPhysics = require("minecraft_26_3_physics")

physics.enabled = physics.enabled ~= false
physics.reference = "Minecraft Java Edition 26.3 LocalPlayer / LivingEntity / Entity / Camera"
physics.triangleCollisionEnabled = physics.triangleCollisionEnabled ~= false

-- This unit conversion is provisional and must be calibrated in a live level.
local WORLD_UNITS_PER_BLOCK = MinecraftPhysics.WORLD_UNITS_PER_BLOCK
local TICK_TO_FRAME = MinecraftPhysics.TICK_TO_FRAME
local SPRINT_FOV_MULTIPLIER = 1.15
local SPRINT_DOUBLE_TAP_WINDOW = 11 -- seven Minecraft ticks mapped to 30 FPS
local JUMP_VELOCITY = MinecraftPhysics.jump_velocity()
local block_friction_provider = nil
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
    local proxy = SteveCraft.proxy
    return m ~= nil
        and m.playerIndex == 0
        and character ~= nil
        and character.ready
        and character.modelId ~= nil
        and proxy ~= nil
        and type(proxy.owns_mario_state) == "function"
        and proxy.owns_mario_state(m)
end

local function is_ground_action(action)
    return (ACT_IDLE ~= nil and action == ACT_IDLE)
        or (ACT_WALKING ~= nil and action == ACT_WALKING)
        or (ACT_START_CROUCHING ~= nil and action == ACT_START_CROUCHING)
        or (ACT_CROUCHING ~= nil and action == ACT_CROUCHING)
        or (ACT_STOP_CROUCHING ~= nil and action == ACT_STOP_CROUCHING)
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
            pendingStep = nil,
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

local function input_options(m)
    return {
        sneaking = MinecraftPhysics.is_sneaking_action(m.action),
        usingItem = SteveCraft.usingItem == true,
        itemUseSpeed = SteveCraft.itemUseSpeedMultiplier,
        sneakingSpeed = SteveCraft.sneakingSpeed,
    }
end

local function input_direction(m)
    return MinecraftPhysics.input_from_intent(
        m.intendedMag or 0, m.intendedYaw or 0,
        (m.faceAngle and m.faceAngle.y) or 0, input_options(m)
    )
end

local function get_block_friction(m)
    if type(block_friction_provider) == "function" then
        local ok, friction = pcall(block_friction_provider, m)
        if ok and type(friction) == "number" then
            return math.max(0.0, friction)
        end
    end
    -- A normal Minecraft block has 0.6 friction. SM64 surfaces do not expose
    -- Minecraft block-state friction, so mods may inject a provider if known.
    return MinecraftPhysics.DEFAULT_BLOCK_FRICTION
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
    local _, _, forward_impulse = input_direction(m)
    local camera_cutscene = m.area ~= nil and m.area.camera ~= nil
        and m.area.camera.cutscene ~= nil and m.area.camera.cutscene ~= 0
    local can_start = not camera_cutscene
        and not MinecraftPhysics.is_sneaking_action(m.action)
        and SteveCraft.canSprint ~= false
        and SteveCraft.usingItem ~= true
    state = MinecraftPhysics.update_sprint(
        state, forward_impulse, can_start, SPRINT_DOUBLE_TAP_WINDOW
    )
    sprint_states[m.playerIndex or 0] = state
    apply_sprint_fov(m, state.sprinting)
end

local function update_horizontal_velocity(m, step_type, state, sprinting)
    local wish_x, wish_z = input_direction(m)
    local on_ground = step_type == STEP_TYPE_GROUND
    local move_x, move_z, next_x, next_z =
        MinecraftPhysics.horizontal_step(
            state.vx, state.vz, wish_x, wish_z,
            on_ground, get_block_friction(m), sprinting and on_ground
        )

    m.vel.x = move_x
    m.vel.z = move_z
    state.vx = next_x
    state.vz = next_z
    state.active = true

    if m.forwardVel ~= nil then
        m.forwardVel = math.sqrt(state.vx * state.vx + state.vz * state.vz)
    end
end


local triangleCollisionWarned = false

local function apply_triangle_collision(m, step_type, state)
    if not physics.triangleCollisionEnabled then return false end

    local adapter = SteveCraft.sm64Collision
    if adapter == nil or type(adapter.resolve) ~= "function" then
        return false
    end

    local move = {
        x = (m.vel and m.vel.x) or 0.0,
        y = (m.vel and m.vel.y) or 0.0,
        z = (m.vel and m.vel.z) or 0.0,
    }
    local config = {
        unitsPerBlock = WORLD_UNITS_PER_BLOCK,
        wasOnGround = step_type == STEP_TYPE_GROUND,
    }

    local ok, allowed = pcall(adapter.resolve, m, move, config)
    if not ok then
        if not triangleCollisionWarned then
            print("[SteveCraft] Triangle collision query failed; retaining native SM64 movement.")
            triangleCollisionWarned = true
        end
        return false
    end
    if allowed == nil then return false end

    -- Only pre-clip the proposed displacement. The engine still performs
    -- its normal Mario physics step, contacts, floor actions and interactions.
    if allowed.x ~= move.x or allowed.y ~= move.y or allowed.z ~= move.z then
        m.vel.x = allowed.x
        m.vel.y = allowed.y
        m.vel.z = allowed.z

        -- Keep cached momentum consistent with the fraction of the move that
        -- survived pre-clipping, so the next frame does not keep pushing into
        -- a surface that the triangle pass already found.
        if state ~= nil then
            if math.abs(move.x) > 1e-8 then
                state.vx = state.vx * (allowed.x / move.x)
            elseif allowed.x == 0 then
                state.vx = 0
            end
            if math.abs(move.z) > 1e-8 then
                state.vz = state.vz * (allowed.z / move.z)
            elseif allowed.z == 0 then
                state.vz = 0
            end
        end

        if m.forwardVel ~= nil then
            m.forwardVel = math.sqrt(allowed.x * allowed.x + allowed.z * allowed.z)
        end
        return true
    end
    return false
end

function physics.set_triangle_collision_enabled(enabled)
    physics.triangleCollisionEnabled = enabled == true
end

function physics.is_triangle_collision_enabled()
    return physics.triangleCollisionEnabled == true
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
        -- Minecraft keeps horizontal momentum and adds its sprint-jump impulse.
        state.jumpActive = true
        state.vy = JUMP_VELOCITY
        local sprint = sprint_states[m.playerIndex or 0] ~= nil
            and sprint_states[m.playerIndex or 0].sprinting == true
        state.vx, state.vz = MinecraftPhysics.sprint_jump_impulse(
            state.vx, state.vz, (m.faceAngle and m.faceAngle.y) or 0,
            sprint, WORLD_UNITS_PER_BLOCK
        )
        if m.vel ~= nil then
            m.vel.x = state.vx
            m.vel.y = state.vy
            m.vel.z = state.vz
        end
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

local function vector_component(vector, key, fallback_index)
    if vector == nil then return 0 end
    local value = vector[key]
    if value == nil and fallback_index ~= nil then value = vector[fallback_index] end
    return type(value) == "number" and value or 0
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

    if m.vel == nil or m.pos == nil or m.intendedMag == nil or m.intendedYaw == nil
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
    local sprint = sprint_states[index] ~= nil
        and sprint_states[index].sprinting == true

    -- Build the requested Minecraft displacement first. SM64's native
    -- perform_ground_step/perform_air_step still clips it against level walls,
    -- floors and ceilings. Store the pre-step velocity so Mario's own
    -- apply_gravity() result cannot be mistaken for Minecraft's post-step value.
    update_horizontal_velocity(m, step_type, state, sprint)
    if air and state.jumpActive then
        m.vel.y = state.vy or 0.0
    end

    apply_triangle_collision(m, step_type, state)

    state.pendingStep = {
        startX = m.pos.x or 0,
        startY = m.pos.y or 0,
        startZ = m.pos.z or 0,
        requestedX = (m.vel and m.vel.x) or 0,
        requestedY = (m.vel and m.vel.y) or 0,
        requestedZ = (m.vel and m.vel.z) or 0,
        verticalVelocity = state.vy or 0,
        wasGround = ground,
        wasAir = air and state.jumpActive == true,
    }
end

local function after_mario_update(m)
    if m == nil or m.playerIndex ~= 0 then return end
    if not is_local_steve(m) or not physics.enabled then
        states[0] = nil
        sprint_states[0] = nil
        restore_sprint_fov()
        return
    end

    -- HOOK_MARIO_UPDATE is after Mario's action/physics step. This is the
    -- collision feedback phase corresponding to Entity.move() in Minecraft.
    local state = states[0]
    if state ~= nil and state.pendingStep ~= nil then
        local pending = state.pendingStep
        local actualX = (m.pos and m.pos.x or pending.startX) - pending.startX
        local actualY = (m.pos and m.pos.y or pending.startY) - pending.startY
        local actualZ = (m.pos and m.pos.z or pending.startZ) - pending.startZ

        local expectedX, expectedZ = pending.requestedX, pending.requestedZ
        if pending.wasGround and m.floor ~= nil and m.floor.normal ~= nil then
            local normalY = vector_component(m.floor.normal, "y", 2)
            expectedX = expectedX * normalY
            expectedZ = expectedZ * normalY
        end

        local toleranceX = math.max(1.0, math.abs(expectedX) * 0.25)
        local toleranceZ = math.max(1.0, math.abs(expectedZ) * 0.25)
        local blockedX = math.abs(actualX - expectedX) > toleranceX
        local blockedZ = math.abs(actualZ - expectedZ) > toleranceZ

        local hasWall = m.wall ~= nil
        local normalX = vector_component(m.wallNormal, "x", 1)
        local normalZ = vector_component(m.wallNormal, "z", 3)
        if normalX == 0 and normalZ == 0 and hasWall and m.wall.normal ~= nil then
            normalX = vector_component(m.wall.normal, "x", 1)
            normalZ = vector_component(m.wall.normal, "z", 3)
        end

        state.vx, state.vz = MinecraftPhysics.reconcile_horizontal_velocity(
            state.vx, state.vz, hasWall, normalX, normalZ, blockedX, blockedZ
        )

        if pending.wasAir and state.jumpActive and is_air_action(m.action) then
            local vertical, hitCeiling = MinecraftPhysics.reconcile_vertical_velocity(
                pending.verticalVelocity,
                pending.requestedY,
                actualY,
                math.max(1.0, math.abs(pending.requestedY) * 0.08)
            )
            if hitCeiling then
                state.vy = 0
            else
                -- Do not read m.vel.y here: perform_air_step() has already
                -- applied SM64's own gravity before this hook is called.
                state.vy = MinecraftPhysics.apply_vertical_friction(vertical)
            end
        end

        if m.forwardVel ~= nil and (hasWall or blockedX or blockedZ) then
            m.forwardVel = math.sqrt(state.vx * state.vx + state.vz * state.vz)
        end
        state.pendingStep = nil
    end

    -- The resulting sprint state is consumed by the next physics step.
    update_sprint_input(m)

    if state ~= nil then
        if not is_air_action(m.action) then
            state.jumpActive = false
            state.vy = 0.0
        end

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

function physics.set_block_friction_provider(provider)
    if provider ~= nil and type(provider) ~= "function" then
        error("block friction provider must be a function or nil")
    end
    block_friction_provider = provider
end

print("[SteveCraft 64] Minecraft Java 26.3 movement port loaded")
