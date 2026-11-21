-- Runtime-independent tests for SteveCraft's single-object model adapter.
local hooks = {}
local model_set_calls = 0

E_MODEL_NONE = -1
E_MODEL_ERROR_MODEL = -2
ACT_FLAG_AIR = 0x200
HOOK_ON_LEVEL_INIT = "level_init"
HOOK_ON_WARP = "warp"
HOOK_ON_EXIT = "exit"

function print() end
function hook_event(name, callback)
    hooks[name] = callback
end
function obj_get_model_id_extended(object)
    return object.modelId
end
function obj_set_model_extended(object, model_id)
    model_set_calls = model_set_calls + 1
    object.modelId = model_id
end

local function make_mario(index)
    local mario_object = {
        modelId = 5,
        oPosX = 10 + index, oPosY = 20, oPosZ = 30,
        header = { gfx = { animInfo = { animID = 12, animFrame = 8 } } },
    }
    return {
        playerIndex = index,
        pos = { x = 10 + index, y = 20, z = 30 },
        vel = { x = 1, y = 2, z = 3 },
        faceAngle = { x = 1, y = 0x4000, z = 2 },
        action = 0x200,
        actionArg = 4,
        forwardVel = 5,
        floorHeight = 19,
        health = 0x880,
        marioBodyState = { modelState = 7, headPos = { x = 11, y = 45, z = 31 } },
        marioObj = mario_object,
    }
end

dofile("proxy.lua")
assert(SteveCraft.proxy ~= nil, "proxy module was not created")
local proxy = SteveCraft.proxy

local local_mario = make_mario(0)
assert(proxy.update(local_mario, 123) == true, "native model replacement failed")
assert(local_mario.marioObj.modelId == 123, "Steve model was not set on marioObj")
assert(proxy.is_attached(0), "native model adapter did not attach")
assert(proxy.owns_mario_state(local_mario), "MarioState authority was not registered")
assert(proxy.get_visual_object(0) == local_mario.marioObj, "visual object must be the native marioObj")
assert(proxy.get_physical_object(0) == local_mario.marioObj, "physical object must be the native marioObj")
assert(local_mario.marioBodyState.modelState == 7, "native body alpha must not be overwritten")

local state = proxy.get_state(0)
assert(state ~= nil and state.position.x == 10, "physics snapshot missing")
assert(state.velocity.y == 2 and state.isAirborne == true, "velocity/action snapshot incorrect")
assert(state.headPosition.y == 45, "head position was not captured")

local calls_after_first_set = model_set_calls
assert(proxy.update(local_mario, 123) == true, "second update failed")
assert(model_set_calls == calls_after_first_set, "model was redundantly replaced")
assert(proxy.get_state(0).position.x == 10, "state snapshot did not refresh")

local_mario.pos.x = 88
local_mario.vel.y = 9
assert(proxy.update(local_mario, 123) == true, "proxy refresh failed")
assert(proxy.get_state(0).position.x == 88, "state snapshot did not refresh after movement")

-- If another system changes the model, SteveCraft must restore Steve.
obj_set_model_extended(local_mario.marioObj, 5)
assert(proxy.update(local_mario, 123) == true, "model reapplication failed")
assert(local_mario.marioObj.modelId == 123, "Steve model was not re-applied")

local remote_mario = make_mario(1)
assert(proxy.update(remote_mario, 123) == true, "remote player model replacement failed")
assert(remote_mario.marioObj.modelId == 123, "remote Steve model was not set")
assert(proxy.get_visual_object(1) == remote_mario.marioObj, "remote player created a detached object")

proxy.destroy(1)
assert(remote_mario.marioObj.modelId == 5, "destroy did not restore remote native model")
assert(not proxy.is_attached(1), "destroy left remote player attached")

proxy.reset()
assert(local_mario.marioObj.modelId == 5, "reset did not restore local native model")
assert(not proxy.is_attached(0), "reset left local player attached")

print("SteveCraft single-object model adapter tests passed.")
