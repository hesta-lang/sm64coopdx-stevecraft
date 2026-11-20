-- SteveCraft 64 - independent Steve player representation.
-- MarioState remains the engine-facing state and interaction proxy. SteveCraft
-- owns locomotion and Steve is rendered by the separate object in proxy.lua.

SteveCraft = SteveCraft or {}

SteveCraft.character = SteveCraft.character or {
    geoName = "steve_geo",
    registered = false,
    ready = false,
    modelId = E_MODEL_NONE,
}

local character = SteveCraft.character
local missingModelLogged = false
local lookupCooldown = 0
local proxyUnavailableLogged = false

local function resolve_steve_model()
    if lookupCooldown > 0 then
        lookupCooldown = lookupCooldown - 1
        return false
    end
    lookupCooldown = 30

    local modelId = smlua_model_util_get_id(character.geoName)
    if modelId == nil or modelId == E_MODEL_NONE or modelId == E_MODEL_ERROR_MODEL then
        if not missingModelLogged then
            print("[SteveCraft 64] Waiting for DynOS model '" .. character.geoName .. "'.")
            missingModelLogged = true
        end
        return false
    end

    character.modelId = modelId
    character.registered = true
    character.ready = true
    print("[SteveCraft 64] Registered independent Steve render model.")
    return true
end

local function apply_steve_model(m)
    if m == nil then return end

    -- DynOS actor resources may be built during game startup. Retry the lookup
    -- until the GeoLayout is available instead of spawning an invalid model ID.
    if not character.registered and not resolve_steve_model() then
        return
    end

    local proxy = SteveCraft.proxy
    if proxy == nil or type(proxy.update) ~= "function" then
        if not proxyUnavailableLogged then
            print("[SteveCraft 64] Proxy module is not available; retaining native player model.")
            proxyUnavailableLogged = true
        end
        return
    end

    -- Each client creates a local visual for every MarioState it simulates.
    -- The Mario model is hidden only after the detached Steve visual exists.
    proxy.update(m, character.modelId)
end

hook_event(HOOK_MARIO_UPDATE, apply_steve_model)
