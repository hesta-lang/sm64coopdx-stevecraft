local hooks = {}
local available = false
local setterCalls = 0

E_MODEL_NONE = 0
E_MODEL_ERROR_MODEL = -1
HOOK_MARIO_UPDATE = "mario_update"
HOOK_ON_OBJECT_UNLOAD = "object_unload"
HOOK_ON_LEVEL_INIT = "level_init"

function print() end
function hook_event(name, callback) hooks[name] = callback end

function smlua_model_util_get_id(name)
    assert(name == "cj_geo", "unexpected model lookup name")
    return available and 900 or E_MODEL_NONE
end

function obj_get_model_id_extended(object)
    return object.modelId or 1
end

function obj_set_model_extended(object, modelId)
    setterCalls = setterCalls + 1
    object.modelId = modelId
end

dofile("character.lua")

local CJ = CJMod.character
assert(CJ.modelName == "cj_geo", "CJ GeoLayout name incorrect")
assert(type(hooks[HOOK_MARIO_UPDATE]) == "function", "Mario update hook missing")

-- Missing asset must be safe: keep the native Mario model unchanged.
local marioA = { modelId = 1 }
local playerA = { playerIndex = 0, marioObj = marioA }
assert(CJ.apply_to_player(playerA) == false, "missing actor should not apply")
assert(marioA.modelId == 1, "missing actor changed the native model")
assert(setterCalls == 0, "setter was called without a CJ model")

-- Register actor and replace the model on the same Mario object.
available = true
assert(CJ.try_register(true) == true, "CJ actor did not register")
assert(CJ.modelId == 900 and CJ.ready, "registered model ID is incorrect")
assert(CJ.apply_to_player(playerA) == true, "local player model swap failed")
assert(marioA.modelId == 900, "local player's model was not replaced")
assert(setterCalls == 1, "first player should be updated once")

-- Do not run obj_set_model_extended every frame.
assert(CJ.apply_to_player(playerA) == true, "second update failed")
assert(setterCalls == 1, "redundant setter call was made")

-- Every player uses its own existing marioObj; no second object is spawned.
local marioB = { modelId = 1 }
local playerB = { playerIndex = 1, marioObj = marioB }
assert(CJ.apply_to_player(playerB) == true, "remote player model swap failed")
assert(marioB.modelId == 900, "second player's model was not replaced")
assert(setterCalls == 2, "second player's object was not updated exactly once")

-- A new Mario object reusing an index must also receive CJ.
local respawnedMario = { modelId = 1 }
local respawnedPlayer = { playerIndex = 0, marioObj = respawnedMario }
assert(CJ.apply_to_player(respawnedPlayer) == true, "respawned object swap failed")
assert(respawnedMario.modelId == 900, "respawned object did not receive CJ")
assert(setterCalls == 3, "respawned object update count incorrect")

-- The level hook clears references so new player objects can be updated.
CJ.on_level_init()
assert(next(CJ.applied) == nil, "level init did not clear object references")

print("CJ native model replacement tests passed.")
