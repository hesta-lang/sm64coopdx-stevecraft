-- SteveCraft 64 - Minecraft-style first-person right-arm viewmodel.
-- The arm is a real 4x12x4 DynOS cuboid, placed in camera space rather than
-- reusing Mario's hand/held-object offsets.

SteveCraft = SteveCraft or {}
local HAND_GEO_NAME = "steve_hand_geo"
local handBehavior = nil
local handModelId = nil
local handObject = nil
local missingModelReported = false
local spawnFailureReported = false
local handState = { swingTimer = 0 }

local PI = math.pi
local TAU = PI * 2.0
local ANGLE_TO_RAD = TAU / 65536.0
local RAD_TO_ANGLE = 65536.0 / TAU
local HAND_SWING_FRAMES = 10

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function normalize(x, y, z)
    local length = math.sqrt(x * x + y * y + z * z)
    if length < 1e-8 then return 0, 0, 0 end
    return x / length, y / length, z / length
end

-- Minecraft's first-person right-hand attachment:
-- shoulder starts off the lower-right screen edge; wrist points toward the
-- screen centre and slightly upward. The arm's local +X axis runs shoulder->wrist.
local function compute_viewmodel_pose(camera_position, yaw_units, pitch_units, timer, motion, swing)
    local yaw = (yaw_units or 0) * ANGLE_TO_RAD
    local pitch = (pitch_units or 0) * ANGLE_TO_RAD
    local sy, cy = math.sin(yaw), math.cos(yaw)
    local sp, cp = math.sin(pitch), math.cos(pitch)

    -- Basis from first_person_cam.c: camera looks opposite this vector.
    local forwardX, forwardY, forwardZ = -cp * sy, -sp, -cp * cy
    local rightX, rightY, rightZ = cy, 0, -sy
    local upX, upY, upZ = -sy * sp, cp, -cy * sp

    local speed = motion ~= nil and (motion.horizontalSpeed or 0) or 0
    local moving = clamp(speed / 5.5, 0, 1)
    local sprinting = motion ~= nil and motion.sprinting == true
    local phase = (timer or 0) * (sprinting and 0.20 or 0.14)
    local bob = math.sin(phase) * moving * (sprinting and 3.0 or 1.8)

    local anchorX = camera_position.x + rightX * 42 - upX * 35 + forwardX * 18
    local anchorY = camera_position.y + rightY * 42 - upY * 35 + forwardY * 18 + math.abs(bob)
    local anchorZ = camera_position.z + rightZ * 42 - upZ * 35 + forwardZ * 18

    if motion ~= nil and motion.crouching then
        anchorY = anchorY - 5.0
    end

    -- The cuboid's shoulder-to-wrist axis is angled toward screen centre.
    local dx = -rightX * 0.78 + upX * 0.42 + forwardX * 0.46
    local dy = -rightY * 0.78 + upY * 0.42 + forwardY * 0.46
    local dz = -rightZ * 0.78 + upZ * 0.42 + forwardZ * 0.46
    dx, dy, dz = normalize(dx, dy, dz)

    -- Object yaw rotates its local X axis in the XZ plane; object roll raises
    -- the wrist in the view plane. This avoids the old yaw+90 pose that aimed
    -- the long arm axis into camera depth.
    local horizontal = math.sqrt(dx * dx + dz * dz)
    local objectYaw = math.atan(-dz, dx)
    local objectRoll = math.atan(dy, horizontal)
    if swing ~= nil then objectRoll = objectRoll + swing end

    return {
        x = anchorX, y = anchorY, z = anchorZ,
        yaw = math.floor(objectYaw * RAD_TO_ANGLE + 0.5),
        pitch = 0,
        roll = math.floor(objectRoll * RAD_TO_ANGLE + 0.5),
        bob = bob,
    }
end

SteveCraft.firstPersonHand = SteveCraft.firstPersonHand or {}
SteveCraft.firstPersonHand.compute_viewmodel_pose = compute_viewmodel_pose

local function hand_viewmodel_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oGraphYOffset = 0
    o.oInteractType = 0
    o.oIntangibleTimer = -1
    local gfx = o.header ~= nil and o.header.gfx or nil
    if gfx ~= nil then gfx.shadowInvisible = true end
end

local function hand_viewmodel_loop(o)
    if not get_first_person_enabled() then
        obj_mark_for_deletion(o)
        if handObject == o then handObject = nil end
        return
    end

    local camera = gLakituState
    local fp = gFirstPersonCamera
    if camera == nil or camera.curPos == nil or fp == nil then return end

    local mario = gMarioStates ~= nil and gMarioStates[0] or nil
    if mario == nil then return end

    local motion = nil
    local physics = SteveCraft.physics
    if physics ~= nil and type(physics.get_animation_state) == "function" then
        local ok, value = pcall(physics.get_animation_state, mario)
        if ok then motion = value end
    end

    local buttonPressed = mario.controller ~= nil and mario.controller.buttonPressed or 0
    if B_BUTTON ~= nil and (buttonPressed & B_BUTTON) ~= 0 then
        handState.swingTimer = HAND_SWING_FRAMES
    end

    local swing = 0
    if handState.swingTimer > 0 then
        local progress = 1.0 - handState.swingTimer / HAND_SWING_FRAMES
        swing = math.sin(progress * PI) * 0.42
        handState.swingTimer = handState.swingTimer - 1
    end

    local pose = compute_viewmodel_pose(
        camera.curPos, fp.yaw, fp.pitch, o.oTimer or 0, motion, swing
    )
    o.oPosX, o.oPosY, o.oPosZ = pose.x, pose.y, pose.z
    o.oFaceAnglePitch = pose.pitch
    o.oFaceAngleYaw = pose.yaw
    o.oFaceAngleRoll = pose.roll
    o.oMoveAnglePitch = pose.pitch
    o.oMoveAngleYaw = pose.yaw
    o.oMoveAngleRoll = pose.roll
    o.oGraphYOffset = 0

    local gfx = o.header ~= nil and o.header.gfx or nil
    if gfx ~= nil then gfx.shadowInvisible = true end
end

handBehavior = hook_behavior(
    nil, OBJ_LIST_GENACTOR, true,
    hand_viewmodel_init, hand_viewmodel_loop,
    "bhvSteveCraftFirstPersonHand"
)

local function spawn_steve_hand(m)
    if m.playerIndex ~= 0 or not get_first_person_enabled() or handObject ~= nil then return end

    if handModelId == nil then
        handModelId = smlua_model_util_get_id(HAND_GEO_NAME)
        if handModelId == nil or handModelId == E_MODEL_NONE or handModelId == E_MODEL_ERROR_MODEL then
            if not missingModelReported then
                print("[SteveCraft] ERROR: DynOS model steve_hand_geo was not found.")
                missingModelReported = true
            end
            return
        end
    end

    handObject = spawn_non_sync_object(handBehavior, handModelId, 0, -10000, 0, nil)
    if handObject == nil then
        if not spawnFailureReported then
            print("[SteveCraft] ERROR: spawn_non_sync_object failed for first-person hand.")
            spawnFailureReported = true
        end
        return
    end
    handState.swingTimer = 0
    print("[SteveCraft] Minecraft-style first-person arm viewmodel spawned.")
end

local function on_level_init()
    handObject = nil
    handModelId = nil
    handState.swingTimer = 0
    missingModelReported = false
    spawnFailureReported = false
end

local function on_hand_unloaded(obj)
    if obj == handObject then handObject = nil end
end

hook_event(HOOK_MARIO_UPDATE, spawn_steve_hand)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_OBJECT_UNLOAD, on_hand_unloaded)
