-- SteveCraft 64 - first-person arm viewmodel
-- Positioning and lifecycle adapted from Gun Mod's c-viewmodel.lua.
-- Uses SteveCraft's own DynOS arm actor (steve_hand_geo).

SteveCraft = SteveCraft or {}

local HAND_GEO_NAME = "steve_hand_geo"
local handBehavior = nil
local handModelId = nil
local handObject = nil
local missingModelReported = false
local spawnFailureReported = false

local function hand_viewmodel_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oGraphYOffset = 0
    o.oInteractType = 0
    o.oIntangibleTimer = -1
end

local function hand_viewmodel_loop(o)
    if not get_first_person_enabled() then
        obj_mark_for_deletion(o)
        if handObject == o then handObject = nil end
        return
    end

    local camera = gLakituState
    local fp = gFirstPersonCamera
    if camera == nil or camera.pos == nil or fp == nil then return end

    local yaw = fp.yaw
    local pitch = fp.pitch

    -- Gun Mod camera-relative transform, with a lower Minecraft-style arm position.
    o.oPosX = camera.pos.x - 35 * coss(pitch) * sins(yaw)
    o.oPosY = camera.pos.y - 35 * sins(pitch) - 20
    o.oPosZ = camera.pos.z - 35 * coss(pitch) * coss(yaw)

    o.oPosX = o.oPosX + sins(yaw + 0x4000) * 30
    o.oPosZ = o.oPosZ + coss(yaw + 0x4000) * 30

    o.oFaceAnglePitch = 0
    o.oFaceAngleYaw = yaw + 0x4000
    o.oFaceAngleRoll = -pitch

    local mario = gMarioStates[0]
    if mario ~= nil then
        local speed = math.min(math.abs(mario.forwardVel) / 30, 1)
        local sway = sins(o.oTimer * 0x0888) * speed
        o.oPosY = o.oPosY + math.abs(sway) * 2
        o.oFaceAngleRoll = o.oFaceAngleRoll + sway * 0x300
    end
end

-- Register during mod loading, never inside a runtime callback.
handBehavior = hook_behavior(
    nil,
    OBJ_LIST_GENACTOR,
    true,
    hand_viewmodel_init,
    hand_viewmodel_loop,
    "bhvSteveCraftFirstPersonHand"
)

local function spawn_steve_hand(m)
    if m.playerIndex ~= 0 or not get_first_person_enabled() or handObject ~= nil then
        return
    end

    if handModelId == nil then
        handModelId = smlua_model_util_get_id(HAND_GEO_NAME)
        if handModelId == nil or handModelId == E_MODEL_NONE or handModelId == E_MODEL_ERROR_MODEL then
            if not missingModelReported then
                print("[SteveCraft] ERROR: DynOS model steve_hand_geo was not found.")
                missingModelReported = true
            end
            return
        end
        print("[SteveCraft] Found steve_hand_geo model ID: " .. tostring(handModelId))
    end

    handObject = spawn_non_sync_object(handBehavior, handModelId, 0, -10000, 0, nil)
    if handObject == nil then
        if not spawnFailureReported then
            print("[SteveCraft] ERROR: spawn_non_sync_object failed for first-person hand.")
            spawnFailureReported = true
        end
        return
    end
    print("[SteveCraft] First-person hand viewmodel spawned.")
end

local function on_level_init()
    handObject = nil
    handModelId = nil
    missingModelReported = false
    spawnFailureReported = false
end

local function on_hand_unloaded(obj)
    if obj == handObject then handObject = nil end
end

hook_event(HOOK_MARIO_UPDATE, spawn_steve_hand)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_OBJECT_UNLOAD, on_hand_unloaded)
