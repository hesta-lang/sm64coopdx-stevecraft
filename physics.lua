-- SteveCraft 64 - first-pass Minecraft-style movement tuning
--
-- Keep SM64CoopDX responsible for the actual ground/air/water collision
-- steps. This module only places conservative horizontal speed limits before
-- the engine performs each physics step; it does not teleport Mario or replace
-- the collision solver.
--
-- Jump impulse, gravity, slopes, swimming and special actions remain native
-- until they can be calibrated in-game without breaking level mechanics.

SteveCraft = SteveCraft or {}

SteveCraft.physics = SteveCraft.physics or {
    enabled = true,
    groundSpeedLimit = 28.0,
    airSpeedLimit = 32.0,
    usingNativeCollision = true,
}

local physics = SteveCraft.physics

local function clamp_forward_speed(m, limit)
    local speed = m.forwardVel
    if speed == nil then return end

    if speed > limit then
        m.forwardVel = limit
    elseif speed < -limit then
        m.forwardVel = -limit
    end
end

local function before_physics_step(m, stepType)
    if not physics.enabled or m == nil or m.playerIndex ~= 0 then
        return
    end

    if m.action == nil or m.forwardVel == nil then
        return
    end

    -- Do not interfere with scripted movement when the player is not giving
    -- directional input (cannons, knockback, cutscenes, moving platforms, etc.).
    if m.intendedMag == nil or m.intendedMag <= 0.5 then
        return
    end

    local isMoving = (m.action & ACT_FLAG_MOVING) ~= 0
    if not isMoving then return end

    if stepType == STEP_TYPE_GROUND then
        -- Keep the normal engine's acceleration and friction; only limit the
        -- maximum horizontal speed during regular ground movement.
        if (m.action & ACT_FLAG_AIR) == 0 then
            clamp_forward_speed(m, physics.groundSpeedLimit)
        end
    elseif stepType == STEP_TYPE_AIR then
        -- Preserve the engine's jump arc and air-step collision response.
        -- This only prevents excessive horizontal carry while steering.
        if (m.action & ACT_FLAG_AIR) ~= 0 then
            clamp_forward_speed(m, physics.airSpeedLimit)
        end
    end
end

hook_event(HOOK_BEFORE_PHYS_STEP, before_physics_step)

print("[SteveCraft 64] Movement tuning enabled (native collision retained).")
