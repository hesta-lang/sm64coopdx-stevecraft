-- SteveCraft 64 - independent movement-step resolver.
--
-- HOOK_BEFORE_PHYS_STEP lets Lua replace the native ground/air/water step.
-- This module moves MarioState itself using SteveCraft's velocity and the
-- sampled level triangles. SM64's surface-query API remains the geometry source;
-- the native perform_*_step movement/resolve/gravity path is bypassed on success.

local M = {}
local MinecraftPhysics = require("minecraft_26_3_physics")

local EPSILON = 0.05

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function safe_query(fn, ...)
    if type(fn) ~= "function" then return nil, nil end
    local ok, height, surface = pcall(fn, ...)
    if not ok or not finite(height) or surface == nil then return nil, nil end
    return height, surface
end

local function set_component(vector, key, value)
    if vector == nil or not finite(value) then return false end
    return pcall(function() vector[key] = value end)
end

local function set_field(object, key, value)
    if object == nil then return false end
    return pcall(function() object[key] = value end)
end

local function sync_render_transform(m, x, y, z)
    local object = m.marioObj
    if object == nil then return end

    set_field(object, "oPosX", x)
    set_field(object, "oPosY", y)
    set_field(object, "oPosZ", z)

    local header = object.header
    local gfx = header ~= nil and header.gfx or nil
    if gfx ~= nil and gfx.pos ~= nil then
        set_component(gfx.pos, "x", x)
        set_component(gfx.pos, "y", y)
        set_component(gfx.pos, "z", z)
    end
    if gfx ~= nil and gfx.angle ~= nil and m.faceAngle ~= nil then
        set_component(gfx.angle, "x", 0)
        set_component(gfx.angle, "y", m.faceAngle.y or 0)
        set_component(gfx.angle, "z", 0)
    end
    if m.faceAngle ~= nil then
        set_field(object, "oFaceAngleYaw", m.faceAngle.y or 0)
    end
end

local function set_contact(m, floor, floor_height, ceil, ceil_height)
    if floor ~= nil then
        set_field(m, "floor", floor)
        set_field(m, "floorHeight", floor_height)
    end
    if ceil ~= nil then
        set_field(m, "ceil", ceil)
        set_field(m, "ceilHeight", ceil_height)
    end
end

local function clip_horizontal_momentum(state, requested, allowed)
    local tolerance_x = math.max(0.05, math.abs(requested.x) * 0.02)
    local tolerance_z = math.max(0.05, math.abs(requested.z) * 0.02)
    local blocked_x = math.abs(allowed.x - requested.x) > tolerance_x
    local blocked_z = math.abs(allowed.z - requested.z) > tolerance_z

    state.vx, state.vz = MinecraftPhysics.reconcile_horizontal_velocity(
        state.vx or 0, state.vz or 0,
        false, 0, 0, blocked_x, blocked_z
    )
    return blocked_x or blocked_z
end

local function collision_config(config)
    config = config or {}
    return {
        unitsPerBlock = config.unitsPerBlock or MinecraftPhysics.WORLD_UNITS_PER_BLOCK,
        radius = config.radius or MinecraftPhysics.WORLD_UNITS_PER_BLOCK * 0.3,
        height = config.height or MinecraftPhysics.WORLD_UNITS_PER_BLOCK * 1.8,
        stepHeight = config.stepHeight or MinecraftPhysics.WORLD_UNITS_PER_BLOCK * 0.6,
        floorRadius = config.floorRadius or MinecraftPhysics.WORLD_UNITS_PER_BLOCK * 0.25,
        wasOnGround = config.wasOnGround == true,
        substep = config.substep,
    }
end

-- Returns the numeric step result expected by perform_ground_step,
-- perform_air_step or perform_water_step. nil means the adapter could not
-- safely take ownership, so the caller must let the native step run.
function M.resolve(m, step_type, state, requested, config)
    if m == nil or m.pos == nil or state == nil or requested == nil then return nil end

    local adapter = SteveCraft ~= nil and SteveCraft.sm64Collision or nil
    if adapter == nil or type(adapter.resolve) ~= "function" then return nil end
    if type(find_floor) ~= "function" or type(find_ceil) ~= "function" then return nil end

    local start_x, start_y, start_z = m.pos.x, m.pos.y, m.pos.z
    if not finite(start_x) or not finite(start_y) or not finite(start_z) then return nil end

    local dimensions = collision_config(config)
    local move = {
        x = finite(requested.x) and requested.x or 0,
        y = finite(requested.y) and requested.y or 0,
        z = finite(requested.z) and requested.z or 0,
    }

    local ok, allowed = pcall(adapter.resolve, m, move, dimensions)
    if not ok or type(allowed) ~= "table"
        or not finite(allowed.x) or not finite(allowed.y) or not finite(allowed.z) then
        return nil
    end

    local end_x = start_x + allowed.x
    local end_y = start_y + allowed.y
    local end_z = start_z + allowed.z
    local floor_height, floor = safe_query(
        find_floor, end_x, math.max(start_y, end_y) + dimensions.stepHeight + 1, end_z
    )
    local ceil_height, ceil = safe_query(
        find_ceil, end_x, start_y + dimensions.height - 1, end_z
    )

    local result
    if step_type == STEP_TYPE_GROUND then
        if floor_height ~= nil
            and floor_height <= start_y + dimensions.stepHeight + EPSILON
            and floor_height >= start_y - dimensions.stepHeight - EPSILON then
            end_y = floor_height
            state.vy = 0
            set_contact(m, floor, floor_height, ceil, ceil_height)
            result = GROUND_STEP_NONE
        else
            -- No floor within Minecraft's step-down range: let the action
            -- transition to its airborne state on the next update.
            state.vy = 0
            result = GROUND_STEP_LEFT_GROUND
        end
    elseif step_type == STEP_TYPE_AIR then
        local landed = move.y <= 0 and floor_height ~= nil
            and floor_height <= start_y + EPSILON
            and floor_height >= end_y - EPSILON

        if landed then
            end_y = floor_height
            state.vy = 0
            set_contact(m, floor, floor_height, ceil, ceil_height)
            result = AIR_STEP_LANDED
        else
            local hit_ceiling = move.y > 0 and ceil_height ~= nil
                and ceil_height >= start_y + dimensions.height - EPSILON
                and end_y + dimensions.height > ceil_height
            if hit_ceiling then
                end_y = ceil_height - dimensions.height
                state.vy = 0
                set_contact(m, floor, floor_height, ceil, ceil_height)
            else
                state.vy = MinecraftPhysics.apply_vertical_friction(state.vy or 0)
                set_contact(m, floor, floor_height, ceil, ceil_height)
            end
            result = AIR_STEP_NONE
        end
    elseif step_type == STEP_TYPE_WATER then
        local hit_floor = move.y < 0 and floor_height ~= nil
            and floor_height <= start_y + EPSILON
            and floor_height >= end_y - EPSILON
        local hit_ceiling = move.y > 0 and ceil_height ~= nil
            and end_y + dimensions.height > ceil_height

        if hit_floor then
            end_y = floor_height
            state.vy = 0
            set_contact(m, floor, floor_height, ceil, ceil_height)
            result = WATER_STEP_HIT_FLOOR
        elseif hit_ceiling then
            end_y = ceil_height - dimensions.height
            state.vy = 0
            set_contact(m, floor, floor_height, ceil, ceil_height)
            result = WATER_STEP_HIT_CEILING
        else
            set_contact(m, floor, floor_height, ceil, ceil_height)
            result = WATER_STEP_NONE
        end
    else
        return nil
    end

    clip_horizontal_momentum(state, move, allowed)

    -- MarioState exposes read-only position/velocity properties, but the
    -- contained Vec3f components are writable in the Android Lua bindings.
    local position_ok = set_component(m.pos, "x", end_x)
        and set_component(m.pos, "y", end_y)
        and set_component(m.pos, "z", end_z)
    if not position_ok then return nil end

    set_component(m.vel, "x", state.vx or 0)
    set_component(m.vel, "y", state.vy or 0)
    set_component(m.vel, "z", state.vz or 0)

    if m.forwardVel ~= nil then
        set_field(m, "forwardVel", math.sqrt((state.vx or 0) ^ 2 + (state.vz or 0) ^ 2))
    end

    sync_render_transform(m, end_x, end_y, end_z)
    return result
end

function M.is_available()
    local adapter = SteveCraft ~= nil and SteveCraft.sm64Collision or nil
    return adapter ~= nil and type(adapter.is_available) == "function"
        and adapter.is_available()
        and type(find_floor) == "function"
        and type(find_ceil) == "function"
end

return M
