-- SteveCraft 64 - Steve player model
-- Requires the generated actors/steve DynOS source in this mod folder.

SteveCraft = SteveCraft or {}

SteveCraft.character = SteveCraft.character or {
    geoName = "steve_geo",
    registered = false,
    ready = false,
    modelId = MODEL_NONE,
}

local character = SteveCraft.character
local missingModelLogged = false

local function resolve_steve_model()
    local modelId = smlua_model_util_get_id(character.geoName)
    if modelId == nil or modelId == MODEL_NONE then
        if not missingModelLogged then
            print("[SteveCraft 64] Waiting for DynOS model '" .. character.geoName .. "'.")
            missingModelLogged = true
        end
        return false
    end

    character.modelId = modelId
    character.registered = true
    character.ready = true
    print("[SteveCraft 64] Registered Steve player model.")
    return true
end

local function apply_steve_model(m)
    -- DynOS actor resources may be built during game startup. Retry the lookup
    -- until the GeoLayout is available instead of applying MODEL_NONE.
    if not character.registered and not resolve_steve_model() then
        return
    end

    -- Register the local player's model choice in the sync table. Other
    -- clients with SteveCraft installed can then display the same model.
    if m.playerIndex == 0 then
        if gPlayerSyncTable[0].modelId ~= character.modelId then
            gPlayerSyncTable[0].modelId = character.modelId
        end
    end

    local sync = gPlayerSyncTable[m.playerIndex]
    if sync ~= nil and sync.modelId == character.modelId then
        obj_set_model_extended(m.marioObj, character.modelId)
    end
end

hook_event(HOOK_MARIO_UPDATE, apply_steve_model)
