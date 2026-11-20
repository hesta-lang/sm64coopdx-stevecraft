-- SteveCraft 64 - Minecraft Java Edition 26.3 movement port.
-- The source-side equations live in minecraft_26_3_physics.lua.
-- SteveCraft owns intercepted movement steps; SM64CoopDX supplies geometry queries and the engine-facing MarioState.

SteveCraft = SteveCraft or {}
SteveCraft.physics = SteveCraft.physics or {}
local physics = SteveCraft.physics
local PI = math.pi
local MinecraftPhysics = require("minecraft_26_3_physics")
require("tri_collider")
require("sm64_collision_adapter")
local IndependentPhysics = require("independent_physics")
local SteveGeometry = require("steve_geometry")

physics.enabled = physics.enabled ~= false
physics.reference = "Minecraft Java Edition 26.3 LocalPlayer / LivingEntity / Entity / Camera"
-- SteveCraft owns the local player movement step whenever its surface adapter is available.
physics.independentMode = physics.independentMode ~= false
physics.nativeGeometryDisabled = physics.nativeGeometryDisabled ~= false
physics.triangleCollisionEnabled = physics.triangleCollisionEnabled == true

-- Free cutscene-group action slot (0x13F) used only to dispatch SteveCraft's
-- custom Lua locomotion. It is not a Mario movement action.
local ACT_STEVECRAFT_CONTROLLED = ACT_GROUP_CUTSCENE
    | 0x3F
    | ACT_FLAG_STATIONARY
    | ACT_FLAG_CUSTOM_ACTION
    | ACT_FLAG_ALLOW_FIRST_PERSON
    | ACT_FLAG_PAUSE_EXIT

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
        or (ACT_BRAKING ~= nil and action == ACT_BRAKING)
        or (ACT_DECELERATING ~= nil and action == ACT_DECELERATING)
        or (ACT_BEGIN_SLIDING ~= nil and action == ACT_BEGIN_SLIDING)
        or (ACT_BUTT_SLIDE ~= nil and action == ACT_BUTT_SLIDE)
        or (ACT_STOMACH_SLIDE ~= nil and action == ACT_STOMACH_SLIDE)
        or (ACT_HOLD_IDLE ~= nil and action == ACT_HOLD_IDLE)
        or (ACT_HOLD_WALKING ~= nil and action == ACT_HOLD_WALKING)
end

local function is_air_action(action)
    if action == nil then return false end
    if ACT_FLAG_AIR ~= nil then return (action & ACT_FLAG_AIR) ~= 0 end
    return (ACT_JUMP ~= nil and action == ACT_JUMP)
        or (ACT_DOUBLE_JUMP ~= nil and action == ACT_DOUBLE_JUMP)
        or (ACT_TRIPLE_JUMP ~= nil and action == ACT_TRIPLE_JUMP)
        or (ACT_FREEFALL ~= nil and action == ACT_FREEFALL)
end

local function is_water_action(action)
    return ACT_FLAG_SWIMMING ~= nil and action ~= nil
        and (action & ACT_FLAG_SWIMMING) ~= 0
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
            onGround = false,
            inWater = false,
            lastFloorSurface = nil,
            lastFloorHeight = nil,
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

local function is_preserved_native_action(action)
    if action == nil then return false end
    -- Keep text/dialog actions available. They do not own player locomotion.
    return ACT_FLAG_WATER_OR_TEXT ~= nil
        and (action & ACT_FLAG_WATER_OR_TEXT) ~= 0
end

local function before_set_mario_action(m, incoming_action, action_arg)
    if not physics.enabled or not physics.independentMode or not is_local_steve(m) then return end
    if incoming_action == ACT_STEVECRAFT_CONTROLLED or incoming_action == ACT_UNINITIALIZED then
        return
    end
    if is_preserved_native_action(incoming_action) then return end

    -- All normal Mario action groups, plus physical cutscene actions, are
    -- redirected into one Steve-owned controller action. Mario's native action
    -- handlers no longer set walking, jump, fall, swim, knockback or slide speed.
    return ACT_STEVECRAFT_CONTROLLED
end

local function on_set_mario_action(m)
    if not physics.enabled or not physics.independentMode or not is_local_steve(m) then return end
    if m.action ~= ACT_STEVECRAFT_CONTROLLED then return end

    local state = get_motion_state(m)
    state.vx, state.vy, state.vz = 0.0, 0.0, 0.0
    state.jumpActive = false
    state.pendingStep = nil
    state.onGround = false
    state.inWater = false
    if m.vel ~= nil then
        m.vel.x, m.vel.y, m.vel.z = 0.0, 0.0, 0.0
    end
    if m.forwardVel ~= nil then m.forwardVel = 0.0 end
end

local function override_mario_geometry_inputs(m)
    if not physics.enabled or not physics.independentMode or not physics.nativeGeometryDisabled
        or not is_local_steve(m) then
        return true
    end

    local state = get_motion_state(m)
    local ok = SteveGeometry.update(m, state, {
        unitsPerBlock = WORLD_UNITS_PER_BLOCK,
        height = WORLD_UNITS_PER_BLOCK * 1.8,
        stepHeight = WORLD_UNITS_PER_BLOCK * 0.6,
        groundTolerance = 6.0,
    })
    if not ok and not warned then
        print("[SteveCraft 64] Lua geometry sampling failed; native geometry remains disabled and movement will hold.")
        warned = true
    end
    -- false cancels update_mario_geometry_inputs(), including its native wall
    -- penetration correction, wall probes and Mario floor/ceiling corrections.
    return false
end

local function before_mario_update(m)
    if not physics.enabled or not physics.independentMode or not is_local_steve(m) then return end
    if m.action == ACT_STEVECRAFT_CONTROLLED or is_preserved_native_action(m.action) then return end
    set_mario_action(m, ACT_STEVECRAFT_CONTROLLED, 0)
end

local function update_steve_animation(m, state)
    if type(set_character_animation) ~= "function" then return end
    local target
    if state.inWater then
        target = CHAR_ANIM_WALKING
    elseif not state.onGround then
        target = (state.vy or 0) > 0 and CHAR_ANIM_SINGLE_JUMP or CHAR_ANIM_GENERAL_FALL
    else
        local speed = math.sqrt((state.vx or 0) ^ 2 + (state.vz or 0) ^ 2)
        if speed < 0.8 then
            target = CHAR_ANIM_IDLE_HEAD_LEFT
        elseif speed < WORLD_UNITS_PER_BLOCK * 0.075 then
            target = CHAR_ANIM_WALKING
        else
            target = CHAR_ANIM_RUNNING
        end
    end
    if target ~= nil then pcall(set_character_animation, m, target) end
end

local function stevecraft_controlled_action(m)
    if m == nil or not is_local_steve(m) then return false end
    if not physics.enabled or not physics.independentMode then
        set_mario_action(m, ACT_IDLE, 0)
        return true
    end

    local state = get_motion_state(m)
    update_sprint_input(m)

    local input = m.input or 0
    local jumpPressed = INPUT_A_PRESSED ~= nil and (input & INPUT_A_PRESSED) ~= 0
    if state.inWater then
        -- Minecraft swimming uses continuous vertical input instead of Mario's
        -- native water-plunge, breaststroke and current routines.
        if type(perform_water_step) == "function" then
            perform_water_step(m)
        end
    else
        if state.onGround and jumpPressed then
            state.jumpActive = true
            state.onGround = false
            state.vy = JUMP_VELOCITY
            local sprint = sprint_states[0] ~= nil and sprint_states[0].sprinting == true
            state.vx, state.vz = MinecraftPhysics.sprint_jump_impulse(
                state.vx, state.vz, (m.faceAngle and m.faceAngle.y) or 0,
                sprint, WORLD_UNITS_PER_BLOCK
            )
        end

        if state.onGround then
            if type(perform_ground_step) == "function" then
                local result = perform_ground_step(m)
                if GROUND_STEP_LEFT_GROUND ~= nil and result == GROUND_STEP_LEFT_GROUND then
                    state.onGround = false
                end
            end
        else
            if type(perform_air_step) == "function" then
                local result = perform_air_step(m, 0)
                if AIR_STEP_LANDED ~= nil and result == AIR_STEP_LANDED then
                    state.onGround = true
                    state.jumpActive = false
                    state.vy = 0.0
                end
            end
        end
    end

    update_steve_animation(m, state)
    return false
end

local function vector_component(vector, key, fallback_index)
    if vector == nil then return 0 end
    local value = vector[key]
    if value == nil and fallback_index ~= nil then value = vector[fallback_index] end
    return type(value) == "number" and value or 0
end

local function independent_collision_config(on_ground)
    return {
        unitsPerBlock = WORLD_UNITS_PER_BLOCK,
        -- Minecraft dimensions: 0.6 blocks wide and 1.8 blocks tall.
        -- The current triangle solver approximates the horizontal footprint radially.
        radius = WORLD_UNITS_PER_BLOCK * 0.3,
        height = WORLD_UNITS_PER_BLOCK * 1.8,
        stepHeight = WORLD_UNITS_PER_BLOCK * 0.6,
        floorRadius = WORLD_UNITS_PER_BLOCK * 0.25,
        wasOnGround = on_ground == true,
    }
end

local function before_physics_step(m, step_type, step_arg)
    if not is_local_steve(m) then
        if m ~= nil then
            states[m.playerIndex or 0] = nil
            sprint_states[m.playerIndex or 0] = nil
        end
        return
    end

    if not physics.enabled or not physics.independentMode then
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

    -- A successful override cancels the native ground/air/water resolver.
    local ground = step_type == STEP_TYPE_GROUND
    local air = step_type == STEP_TYPE_AIR
    local water = step_type == STEP_TYPE_WATER
    if not ground and not air and not water then
        states[m.playerIndex or 0] = nil
        return
    end

    local index = m.playerIndex or 0
    local state = get_motion_state(m)
    local sprint = sprint_states[index] ~= nil
        and sprint_states[index].sprinting == true

    if water then
        local wish_x, wish_z = input_direction(m)
        local on_floor = m.floorHeight ~= nil
            and math.abs((m.pos.y or 0) - m.floorHeight) <= 1.0
        local move_x, move_z, next_x, next_z =
            MinecraftPhysics.water_horizontal_step(
                state.vx, state.vz, wish_x, wish_z,
                MinecraftPhysics.DEFAULT_MOVEMENT_SPEED,
                SteveCraft.waterMovementEfficiency or 0,
                on_floor, sprint
            )
        local input = m.input or 0
        local jump_held = INPUT_A_DOWN ~= nil and (input & INPUT_A_DOWN) ~= 0
        local descend_held = INPUT_Z_DOWN ~= nil and (input & INPUT_Z_DOWN) ~= 0
        local move_y, next_y = MinecraftPhysics.water_vertical_step(
            state.vy, jump_held, descend_held, MinecraftPhysics.DEFAULT_GRAVITY
        )
        m.vel.x, m.vel.y, m.vel.z = move_x, move_y, move_z
        state.vx, state.vy, state.vz = next_x, next_y, next_z

        local result = IndependentPhysics.resolve(
            m, step_type, state,
            { x = move_x, y = move_y, z = move_z },
            independent_collision_config(on_floor)
        )
        if type(result) == "number" then
            state.pendingStep = nil
            state.independentStep = true
            return result
        end

        -- Never fall back to Mario's native water solver in isolation mode.
        state.vx, state.vy, state.vz = 0.0, 0.0, 0.0
        m.vel.x, m.vel.y, m.vel.z = 0.0, 0.0, 0.0
        state.pendingStep = nil
        return WATER_STEP_NONE
    end

    update_horizontal_velocity(m, step_type, state, sprint)
    if air then
        if not state.jumpActive then
            state.vy = (m.vel and m.vel.y) or state.vy or 0.0
        end
        m.vel.y = state.vy or 0.0
    else
        state.vy = 0.0
        m.vel.y = 0.0
    end

    local requested = {
        x = (m.vel and m.vel.x) or 0.0,
        y = (m.vel and m.vel.y) or 0.0,
        z = (m.vel and m.vel.z) or 0.0,
    }
    local result = IndependentPhysics.resolve(
        m, step_type, state, requested, independent_collision_config(ground)
    )
    if type(result) == "number" then
        state.pendingStep = nil
        state.independentStep = true
        return result
    end

    -- Strict isolation: if Lua cannot resolve a step, stop that step in place.
    -- Never allow Mario's native solver or gravity to take over.
    state.vx, state.vy, state.vz = 0.0, 0.0, 0.0
    m.vel.x, m.vel.y, m.vel.z = 0.0, 0.0, 0.0
    state.pendingStep = nil
    if ground then return GROUND_STEP_NONE end
    return AIR_STEP_NONE
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

        local hasWall = m.wall ~= nil
        local normalX = vector_component(m.wallNormal, "x", 1)
        local normalZ = vector_component(m.wallNormal, "z", 3)
        if normalX == 0 and normalZ == 0 and hasWall and m.wall.normal ~= nil then
            normalX = vector_component(m.wall.normal, "x", 1)
            normalZ = vector_component(m.wall.normal, "z", 3)
        end

        if pending.medium == "water" then
            -- Water currents are added by SM64 after this hook, and its water
            -- solver keeps wall results local. Do not mistake current drift for
            -- player velocity or axis clipping. The water surface/floor clamp
            -- is observable in the actual vertical displacement.
            local verticalBlockedUp = pending.requestedY > 0
                and actualY < pending.requestedY - math.max(1.0, math.abs(pending.requestedY) * 0.08)
            local verticalBlockedDown = pending.requestedY < 0
                and actualY > pending.requestedY + math.max(1.0, math.abs(pending.requestedY) * 0.08)
            if verticalBlockedUp or verticalBlockedDown then
                state.vy = 0
            end
        else
            local toleranceX = math.max(1.0, math.abs(expectedX) * 0.25)
            local toleranceZ = math.max(1.0, math.abs(expectedZ) * 0.25)
            local blockedX = math.abs(actualX - expectedX) > toleranceX
            local blockedZ = math.abs(actualZ - expectedZ) > toleranceZ

            state.vx, state.vz = MinecraftPhysics.reconcile_horizontal_velocity(
                state.vx, state.vz, hasWall, normalX, normalZ, blockedX, blockedZ
            )
        end

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
        local swimming = is_water_action(m.action)
        if not is_air_action(m.action) and not swimming then
            state.jumpActive = false
            state.vy = 0.0
        end

        if not is_ground_action(m.action) and not is_air_action(m.action) and not swimming then
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

-- Enabled by default: successful HOOK_BEFORE_PHYS_STEP overrides replace the
-- native local-player movement resolver. Disable only for diagnosis/fallback.
function physics.set_independent_mode(enabled)
    physics.independentMode = enabled == true
    states = {}
    sprint_states = {}
end

function physics.is_independent_mode()
    return physics.independentMode == true
end

function physics.is_independent_collision_available()
    return IndependentPhysics.is_available()
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
