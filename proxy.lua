-- SteveCraft 64 - independent Steve render / Mario physical proxy.
--
-- MarioState and its marioObj remain the ONLY physics and collision authority.
-- Each client creates one local, non-colliding Steve render object per player.
-- That object follows the matching MarioState and mirrors Mario's animation
-- descriptor. No second controller, gravity solver, or collision body is made.

SteveCraft = SteveCraft or {}
SteveCraft.proxy = SteveCraft.proxy or {}
local proxy = SteveCraft.proxy

proxy.version = "1.0.0-alpha"
proxy.reference = "SM64CoopDX MarioState + detached Steve render object"

local records = {}
local behaviorId = nil
local warnedBehavior = false
local warnedSpawn = false

local NATIVE_BODY_HIDDEN_ALPHA = 0x100

local ANIMATION_FIELDS = {
    "curAnim",
    "prevAnimPtr",
    "animID",
    "prevAnimID",
    "animFrame",
    "prevAnimFrame",
    "animFrameAccelAssist",
    "animAccel",
    "animTimer",
    "animYTrans",
}

local function copy_vec3(value)
    if value == nil then return nil end
    if value.x == nil or value.y == nil or value.z == nil then return nil end
    return { x = value.x, y = value.y, z = value.z }
end

local function capture_state(m)
    local state = {
        playerIndex = m.playerIndex,
        position = copy_vec3(m.pos),
        velocity = copy_vec3(m.vel),
        rotation = copy_vec3(m.faceAngle),
        action = m.action,
        actionArg = m.actionArg,
        forwardVelocity = m.forwardVel,
        floorHeight = m.floorHeight,
        health = m.health,
    }

    if m.action ~= nil and ACT_FLAG_AIR ~= nil then
        state.isAirborne = (m.action & ACT_FLAG_AIR) ~= 0
    end

    if m.marioBodyState ~= nil then
        state.headPosition = copy_vec3(m.marioBodyState.headPos)
    end

    return state
end

local function copy_animation_state(sourceObject, visualObject)
    if sourceObject == nil or visualObject == nil then return end

    -- Steve's generated GeoLayout deliberately uses the same 21-part
    -- animated hierarchy as the SM64CoopDX player model.
    local sourceHeader = sourceObject.header
    local targetHeader = visualObject.header
    if sourceHeader == nil or targetHeader == nil
        or sourceHeader.gfx == nil or targetHeader.gfx == nil then
        return
    end

    local sourceInfo = sourceHeader.gfx.animInfo
    local targetInfo = targetHeader.gfx.animInfo
    if sourceInfo == nil or targetInfo == nil then return end

    for _, field in ipairs(ANIMATION_FIELDS) do
        local value = sourceInfo[field]
        if value ~= nil then
            targetInfo[field] = value
        end
    end

    if sourceObject.oAnimations ~= nil then
        visualObject.oAnimations = sourceObject.oAnimations
    end
    if sourceObject.oAnimState ~= nil then
        visualObject.oAnimState = sourceObject.oAnimState
    end


end

local function set_visual_transform(m, visualObject)
    local sourceObject = m.marioObj
    if sourceObject ~= nil then
        visualObject.oPosX = sourceObject.oPosX
        visualObject.oPosY = sourceObject.oPosY
        visualObject.oPosZ = sourceObject.oPosZ
        visualObject.oFaceAnglePitch = sourceObject.oFaceAnglePitch
        visualObject.oFaceAngleYaw = sourceObject.oFaceAngleYaw
        visualObject.oFaceAngleRoll = sourceObject.oFaceAngleRoll
        visualObject.oMoveAnglePitch = sourceObject.oMoveAnglePitch
        visualObject.oMoveAngleYaw = sourceObject.oMoveAngleYaw
        visualObject.oMoveAngleRoll = sourceObject.oMoveAngleRoll
        copy_animation_state(sourceObject, visualObject)
    else
        local position = m.pos
        local rotation = m.faceAngle
        if position ~= nil then
            visualObject.oPosX = position.x
            visualObject.oPosY = position.y
            visualObject.oPosZ = position.z
        end
        if rotation ~= nil then
            visualObject.oFaceAnglePitch = rotation.x
            visualObject.oFaceAngleYaw = rotation.y
            visualObject.oFaceAngleRoll = rotation.z
            visualObject.oMoveAngleYaw = rotation.y
        end
    end

    local networkPlayer = gNetworkPlayers ~= nil
        and gNetworkPlayers[m.playerIndex] or nil
    if networkPlayer ~= nil and networkPlayer.globalIndex ~= nil then
        -- Steve's GeoLayout calls geo_mario_head_rotation and
        -- geo_mario_tilt_torso. These resolve the correct body-state slot
        -- through the object's globalPlayerIndex.
        visualObject.globalPlayerIndex = networkPlayer.globalIndex
    end
end

local function hide_native_body(m, record)
    if m == nil or m.marioBodyState == nil then return end

    local current = m.marioBodyState.modelState or 0
    if record.lastHiddenModelState == nil or current ~= record.lastHiddenModelState then
        record.originalModelState = current
    end

    -- SM64CoopDX's first-person camera uses 0x100 with alpha byte 0.
    -- Preserve other flags such as metal/vanish state while hiding the native body.
    local hidden = (current & ~0x1FF) | NATIVE_BODY_HIDDEN_ALPHA
    m.marioBodyState.modelState = hidden
    record.lastHiddenModelState = hidden
end

local function restore_native_body(record)
    if record == nil or record.marioState == nil
        or record.marioState.marioBodyState == nil
        or record.originalModelState == nil then
        return
    end

    local bodyState = record.marioState.marioBodyState
    if bodyState.modelState == record.lastHiddenModelState then
        bodyState.modelState = record.originalModelState
    end
end

local function visual_init(o)
    o.oFlags = (o.oFlags or 0) | OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = 0
    o.oIntangibleTimer = -1
    o.oWallHitboxRadius = 0
    o.oGravity = 0
    o.oOpacity = 255
    o.oGraphYOffset = 0
end

local function visual_loop(o)
    local playerIndex = (o.oBehParams or 0) & 0xFF
    local record = records[playerIndex]
    if record == nil or record.visual ~= o then
        obj_mark_for_deletion(o)
        return
    end

    local m = gMarioStates ~= nil and gMarioStates[playerIndex] or nil
    if m == nil or m.marioObj == nil then
        obj_mark_for_deletion(o)
        record.visual = nil
        return
    end

    record.marioState = m
    record.marioObject = m.marioObj
    record.state = capture_state(m)
    set_visual_transform(m, o)

    -- First person uses Steve's separate hand viewmodel. The full body stays
    -- available in third person and for remote players.
    if playerIndex == 0
        and type(get_first_person_enabled) == "function"
        and get_first_person_enabled() then
        cur_obj_hide()
    else
        cur_obj_unhide()
    end

    -- Only hide the native Mario body once its Steve visual exists.
    hide_native_body(m, record)
end

if type(hook_behavior) == "function"
    and OBJ_LIST_GENACTOR ~= nil
    and OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE ~= nil then
    behaviorId = hook_behavior(
        nil,
        OBJ_LIST_GENACTOR,
        true,
        visual_init,
        visual_loop,
        "bhvSteveCraftProxyVisual"
    )
end

local function ensure_visual(m, modelId, record)
    local index = m.playerIndex
    local current = record.visual

    if current ~= nil and record.modelId ~= modelId then
        if type(obj_mark_for_deletion) == "function" then
            obj_mark_for_deletion(current)
        end
        record.visual = nil
        current = nil
    end

    if current ~= nil then return current end

    if behaviorId == nil or type(spawn_non_sync_object) ~= "function" then
        if not warnedBehavior then
            print("[SteveCraft] Proxy visual unavailable: behavior/object API missing.")
            warnedBehavior = true
        end
        return nil
    end

    local position = m.marioObj ~= nil and m.marioObj or m
    local x = position.oPosX or (position.pos and position.pos.x) or 0
    local y = position.oPosY or (position.pos and position.pos.y) or 0
    local z = position.oPosZ or (position.pos and position.pos.z) or 0

    local networkPlayer = gNetworkPlayers ~= nil and gNetworkPlayers[index] or nil
    local globalIndex = networkPlayer ~= nil and networkPlayer.globalIndex or nil

    local visual = spawn_non_sync_object(
        behaviorId,
        modelId,
        x,
        y,
        z,
        function(o)
            o.oBehParams = index
            if globalIndex ~= nil then
                o.globalPlayerIndex = globalIndex
            end
        end
    )

    if visual == nil then
        if not warnedSpawn then
            print("[SteveCraft] Proxy visual spawn failed; native player model was left enabled.")
            warnedSpawn = true
        end
        return nil
    end

    record.visual = visual
    record.modelId = modelId
    set_visual_transform(m, visual)
    return visual
end

function proxy.update(m, modelId)
    if m == nil or m.playerIndex == nil or modelId == nil
        or modelId == E_MODEL_NONE or modelId == E_MODEL_ERROR_MODEL then
        return false
    end

    local index = m.playerIndex
    local record = records[index]
    if record == nil then
        record = {}
        records[index] = record
    end

    record.marioState = m
    record.marioObject = m.marioObj
    record.state = capture_state(m)

    local visual = ensure_visual(m, modelId, record)
    if visual == nil then return false end

    set_visual_transform(m, visual)
    hide_native_body(m, record)

    return true
end

function proxy.owns_mario_state(m)
    if m == nil or m.playerIndex == nil then return false end
    local record = records[m.playerIndex]
    return record ~= nil and record.visual ~= nil and record.marioState == m
end

function proxy.is_attached(playerIndex)
    local record = records[playerIndex or 0]
    return record ~= nil and record.visual ~= nil
end

function proxy.get_state(playerIndex)
    local record = records[playerIndex or 0]
    if record == nil or record.state == nil then return nil end

    local source = record.state
    return {
        playerIndex = source.playerIndex,
        position = copy_vec3(source.position),
        velocity = copy_vec3(source.velocity),
        rotation = copy_vec3(source.rotation),
        action = source.action,
        actionArg = source.actionArg,
        forwardVelocity = source.forwardVelocity,
        floorHeight = source.floorHeight,
        health = source.health,
        isAirborne = source.isAirborne,
        headPosition = copy_vec3(source.headPosition),
    }
end

function proxy.get_camera_anchor(playerIndex)
    local state = proxy.get_state(playerIndex or 0)
    if state == nil then return nil end
    return {
        position = state.position,
        headPosition = state.headPosition,
        yaw = state.rotation ~= nil and state.rotation.y or nil,
    }
end

function proxy.get_physical_object(playerIndex)
    local record = records[playerIndex or 0]
    return record ~= nil and record.marioObject or nil
end

function proxy.get_visual_object(playerIndex)
    local record = records[playerIndex or 0]
    return record ~= nil and record.visual or nil
end

function proxy.destroy(playerIndex)
    local record = records[playerIndex]
    if record == nil then return end

    restore_native_body(record)
    if record.visual ~= nil and type(obj_mark_for_deletion) == "function" then
        obj_mark_for_deletion(record.visual)
    end
    records[playerIndex] = nil
end

function proxy.reset()
    for index in pairs(records) do
        proxy.destroy(index)
    end
    records = {}
end

local function on_object_unload(o)
    for index, record in pairs(records) do
        if record.visual == o then
            record.visual = nil
            record.modelId = nil
            break
        end
    end
end

if type(hook_event) == "function" then
    if HOOK_ON_OBJECT_UNLOAD ~= nil then
        hook_event(HOOK_ON_OBJECT_UNLOAD, on_object_unload)
    end
    if HOOK_ON_LEVEL_INIT ~= nil then
        hook_event(HOOK_ON_LEVEL_INIT, proxy.reset)
    end
    if HOOK_ON_WARP ~= nil then
        hook_event(HOOK_ON_WARP, proxy.reset)
    end
    if HOOK_ON_EXIT ~= nil then
        hook_event(HOOK_ON_EXIT, proxy.reset)
    end
end

print("[SteveCraft] Independent Steve visual proxy initialized; Mario remains the physics authority.")
