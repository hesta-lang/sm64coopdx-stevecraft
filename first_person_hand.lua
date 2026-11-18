-- SteveCraft 64 - Minecraft-style first-person arm
-- A separate DynOS actor is positioned in the camera's view space.
-- This is a camera-attached 3D object, not a 2D HUD image.

SteveCraft = SteveCraft or {}

local HAND_GEO_NAME = "steve_hand_geo"
local HAND_BEHAVIOR = nil
local handModelId = nil
local handObject = nil
local shouldSpawnHand = true
local modelRetry = 0

local function first_person_hand_init(o)
    o.oFlags = o.oFlags | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = 0
    o.oIntangibleTimer = -1
    o.oGravity = 0
end

-- Behavior registration must happen while the Lua mod is loading.
-- hook_behavior() is not permitted from HOOK_UPDATE or other runtime callbacks.
HAND_BEHAVIOR = hook_behavior(
    nil,
    OBJ_LIST_DEFAULT,
    true,
    first_person_hand_init,
    first_person_hand_loop,
    "bhvSteveFirstPersonHand"
)

local function first_person_hand_loop(o)
    if not get_first_person_enabled() then
        o.oPosY = -10000
        return
    end

    local mario = gMarioStates[0]
    local camera = gLakituState
    local fp = gFirstPersonCamera
    if mario == nil or camera == nil or camera.curPos == nil or fp == nil then
        return
    end

    local yaw = fp.yaw
    local pitch = fp.pitch
    local sy = sins(yaw)
    local cy = coss(yaw)
    local sp = sins(pitch)
    local cp = coss(pitch)

    -- Camera basis from the same yaw/pitch equations as first_person_cam.c.
    local fx = -cp * sy
    local fy = -sp
    local fz = -cp * cy
    local rx = cy
    local rz = -sy
    local ux = sp * sy
    local uy = cp
    local uz = -sp * cy

    local speed = math.min(math.abs(mario.forwardVel) / 30, 1)
    local walkPhase = sins(o.oTimer * 0x0888)
    local walkSway = walkPhase * speed
    local bob = math.abs(walkPhase) * 3 * speed
    local punching = (mario.action == ACT_PUNCHING or mario.action == ACT_MOVE_PUNCHING)
    local punch = punching and 1 or 0

    local forwardOffset = 82 + punch * 18 + walkSway * 2
    local rightOffset = 14 + walkSway * 2
    local downOffset = 38 + bob - punch * 8

    local cx = camera.curPos.x
    local cyPos = camera.curPos.y
    local cz = camera.curPos.z
    o.oPosX = cx + fx * forwardOffset + rx * rightOffset - ux * downOffset
    o.oPosY = cyPos + fy * forwardOffset - uy * downOffset
    o.oPosZ = cz + fz * forwardOffset + rz * rightOffset - uz * downOffset

    o.oFaceAngleYaw = yaw
    o.oFaceAnglePitch = -pitch
    o.oFaceAngleRoll = -0x1000 + walkSway * 0x500 + punch * 0x1800
end

local function first_person_hand_unloaded(obj)
    if obj == handObject then
        handObject = nil
    end
end

local function ensure_first_person_hand()
    if not shouldSpawnHand or handObject ~= nil or not get_first_person_enabled() then
        return
    end

    local mario = gMarioStates[0]
    if mario == nil or mario.marioObj == nil then
        return
    end

    if handModelId == nil then
        if modelRetry > 0 then
            modelRetry = modelRetry - 1
            return
        end
        modelRetry = 30
        local modelId = smlua_model_util_get_id(HAND_GEO_NAME)
        if modelId == nil or modelId == E_MODEL_NONE or modelId == E_MODEL_ERROR_MODEL then
            return
        end
        handModelId = modelId
    end

    handObject = spawn_non_sync_object(HAND_BEHAVIOR, handModelId, 0, 0, 0, nil)
end

local function on_level_init()
    shouldSpawnHand = true
    modelRetry = 0
end

hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_OBJECT_UNLOAD, first_person_hand_unloaded)
hook_event(HOOK_UPDATE, ensure_first_person_hand)
