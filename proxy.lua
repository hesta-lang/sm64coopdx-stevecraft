-- SteveCraft 64 - native MarioState / Steve model adapter.
--
-- Keep exactly one player object. MarioState and marioObj remain the engine's
-- only movement, collision, interaction and camera authority; this module
-- changes the model on that same object instead of spawning a second Steve.

SteveCraft = SteveCraft or {}
SteveCraft.proxy = SteveCraft.proxy or {}
local proxy = SteveCraft.proxy

proxy.version = "2.0.0-alpha"
proxy.reference = "SM64CoopDX MarioState + obj_set_model_extended"

local records = {}
local warnedModelApi = false
local warnedModelSet = false

local function copy_vec3(value)
    if value == nil or type(value.x) ~= "number"
        or type(value.y) ~= "number" or type(value.z) ~= "number" then
        return nil
    end
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

local function read_model_id(object)
    if type(obj_get_model_id_extended) ~= "function" then return nil end
    local ok, model_id = pcall(obj_get_model_id_extended, object)
    if ok and type(model_id) == "number" then return model_id end
    return nil
end

local function set_native_steve_model(m, model_id, record)
    local object = m ~= nil and m.marioObj or nil
    if object == nil then return false end

    if type(obj_set_model_extended) ~= "function" then
        if not warnedModelApi then
            print("[SteveCraft] ERROR: obj_set_model_extended is unavailable; cannot replace the native player model.")
            warnedModelApi = true
        end
        return false
    end

    local current_model = read_model_id(object)
    local object_changed = record.modelObject ~= object

    if object_changed then
        record.originalModelId = current_model
        record.modelObject = object
        record.modelId = nil
    end

    -- Prefer the engine's actual model ID to detect changes by other mods.
    -- If the getter is unavailable, only write on object/model transitions.
    local needs_update
    if current_model ~= nil then
        needs_update = current_model ~= model_id
    else
        needs_update = record.modelId ~= model_id or object_changed
    end

    if needs_update then
        local ok, err = pcall(obj_set_model_extended, object, model_id)
        if not ok then
            if not warnedModelSet then
                print("[SteveCraft] ERROR: could not set Steve on the native player object: " .. tostring(err))
                warnedModelSet = true
            end
            return false
        end
    end

    record.modelObject = object
    record.modelId = model_id
    return true
end

function proxy.update(m, model_id)
    if m == nil or m.playerIndex == nil or m.marioObj == nil
        or type(model_id) ~= "number"
        or model_id == E_MODEL_NONE or model_id == E_MODEL_ERROR_MODEL then
        return false
    end

    local index = m.playerIndex
    local record = records[index]
    if record == nil then
        record = {}
        records[index] = record
    end

    if not set_native_steve_model(m, model_id, record) then
        return false
    end

    record.marioState = m
    record.marioObject = m.marioObj
    record.state = capture_state(m)
    return true
end

function proxy.owns_mario_state(m)
    if m == nil or m.playerIndex == nil then return false end
    local record = records[m.playerIndex]
    return record ~= nil and record.marioState == m
        and record.marioObject ~= nil and record.marioObject == m.marioObj
end

function proxy.is_attached(player_index)
    local record = records[player_index or 0]
    return record ~= nil and record.marioState ~= nil
        and record.marioObject ~= nil
        and record.marioState.marioObj == record.marioObject
end

function proxy.get_state(player_index)
    local record = records[player_index or 0]
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

function proxy.get_camera_anchor(player_index)
    local state = proxy.get_state(player_index or 0)
    if state == nil then return nil end
    return {
        position = state.position,
        headPosition = state.headPosition,
        yaw = state.rotation ~= nil and state.rotation.y or nil,
    }
end

-- The visual and physical objects are now deliberately the same marioObj.
function proxy.get_physical_object(player_index)
    local record = records[player_index or 0]
    return record ~= nil and record.marioObject or nil
end

function proxy.get_visual_object(player_index)
    local record = records[player_index or 0]
    return record ~= nil and record.marioObject or nil
end

function proxy.destroy(player_index)
    local record = records[player_index]
    if record == nil then return end

    local object = record.marioObject
    local original_model = record.originalModelId
    if object ~= nil and original_model ~= nil
        and type(obj_set_model_extended) == "function" then
        local current_model = read_model_id(object)
        if current_model == nil or current_model == record.modelId then
            pcall(obj_set_model_extended, object, original_model)
        end
    end
    records[player_index] = nil
end

function proxy.reset()
    local indices = {}
    for index in pairs(records) do indices[#indices + 1] = index end
    for _, index in ipairs(indices) do
        proxy.destroy(index)
    end
end

if type(hook_event) == "function" then
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

print("[SteveCraft] Single-object player model adapter initialized; no detached body is spawned.")
