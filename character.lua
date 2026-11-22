-- CJ for SM64CoopDX - native player model replacement.
--
-- This is Option 1: keep the engine-owned MarioState and marioObj. Replace
-- only the model on that object. No second body, movement solver, collision
-- body, or custom camera is created.
--
-- Required DynOS actor name: cj_geo
-- Required actor folder: actors/cj/

CJMod = CJMod or {}
CJMod.character = CJMod.character or {
    modelName = "cj_geo",
    modelId = nil,
    ready = false,
    lookupInterval = 60,
    lookupCooldown = 0,
    applied = {},
    missingModelLogged = false,
    missingApiLogged = false,
}

local character = CJMod.character

local function is_valid_model_id(modelId)
    if type(modelId) ~= "number" then return false end
    if E_MODEL_NONE ~= nil and modelId == E_MODEL_NONE then return false end
    if E_MODEL_ERROR_MODEL ~= nil and modelId == E_MODEL_ERROR_MODEL then return false end
    return true
end

function character.try_register(force)
    if character.ready and is_valid_model_id(character.modelId) then
        return true
    end

    if character.lookupCooldown > 0 and not force then
        character.lookupCooldown = character.lookupCooldown - 1
        return false
    end

    character.lookupCooldown = character.lookupInterval

    if type(smlua_model_util_get_id) ~= "function" then
        if not character.missingApiLogged then
            print("[CJ Mod] ERROR: smlua_model_util_get_id is unavailable.")
            character.missingApiLogged = true
        end
        return false
    end

    local ok, modelId = pcall(smlua_model_util_get_id, character.modelName)
    if not ok or not is_valid_model_id(modelId) then
        if not character.missingModelLogged then
            print("[CJ Mod] Waiting for DynOS actor '" .. character.modelName .. "'.")
            character.missingModelLogged = true
        end
        return false
    end

    character.modelId = modelId
    character.ready = true
    character.missingModelLogged = false
    print("[CJ Mod] Registered CJ model: " .. character.modelName
        .. " (ID " .. tostring(modelId) .. ").")
    return true
end

function character.apply_to_player(m)
    if m == nil or m.playerIndex == nil or m.marioObj == nil then
        return false
    end

    if not character.ready and not character.try_register(false) then
        return false
    end

    if type(obj_set_model_extended) ~= "function" then
        if not character.missingApiLogged then
            print("[CJ Mod] ERROR: obj_set_model_extended is unavailable.")
            character.missingApiLogged = true
        end
        return false
    end

    local playerIndex = m.playerIndex
    local marioObject = m.marioObj
    local record = character.applied[playerIndex]
    local shouldApply = record == nil
        or record.object ~= marioObject
        or record.modelId ~= character.modelId

    -- Avoid calling the setter every frame when the model is already correct.
    -- If the getter is not available, the per-player record is the fallback.
    if type(obj_get_model_id_extended) == "function" then
        local ok, currentModelId = pcall(obj_get_model_id_extended, marioObject)
        if ok and type(currentModelId) == "number" then
            shouldApply = currentModelId ~= character.modelId
        end
    end

    if shouldApply then
        local ok, err = pcall(
            obj_set_model_extended,
            marioObject,
            character.modelId
        )
        if not ok then
            print("[CJ Mod] ERROR: failed to set CJ model: " .. tostring(err))
            return false
        end

        character.applied[playerIndex] = {
            object = marioObject,
            modelId = character.modelId,
        }
    end

    return true
end

function character.on_object_unload(obj)
    if obj == nil then return end
    for playerIndex, record in pairs(character.applied) do
        if record.object == obj then
            character.applied[playerIndex] = nil
        end
    end
end

function character.on_level_init()
    -- Keep the resolved model ID; DynOS resources remain loaded between areas.
    -- Clear object references so the next MarioState instance is updated.
    character.applied = {}
    character.lookupCooldown = 0
end

hook_event(HOOK_MARIO_UPDATE, character.apply_to_player)
if HOOK_ON_OBJECT_UNLOAD ~= nil then
    hook_event(HOOK_ON_OBJECT_UNLOAD, character.on_object_unload)
end
if HOOK_ON_LEVEL_INIT ~= nil then
    hook_event(HOOK_ON_LEVEL_INIT, character.on_level_init)
end

-- Try once during load, then retry automatically while the actor is absent.
character.try_register(true)

print("[CJ Mod] Model replacement initialized. MarioState remains native.");
