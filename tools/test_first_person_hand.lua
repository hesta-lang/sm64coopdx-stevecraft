-- First-person Steve right-arm placement and swing tests.
package.path = "./?.lua;" .. package.path

OBJ_LIST_GENACTOR = 1
OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE = 0x100
E_MODEL_NONE = -1
E_MODEL_ERROR_MODEL = -2
B_BUTTON = 0x2
HOOK_MARIO_UPDATE = "mario_update"
HOOK_ON_LEVEL_INIT = "level_init"
HOOK_ON_OBJECT_UNLOAD = "object_unload"

local events = {}
local behavior = nil
local firstPerson = true
local nextId = 1
local spawnedObject = nil

function hook_event(name, callback) events[name] = callback end
function hook_behavior(_, _, _, init, loop, name)
    behavior = { init = init, loop = loop, name = name }
    return 700
end
function get_first_person_enabled() return firstPerson end
function smlua_model_util_get_id(name)
    assert(name == "steve_hand_geo")
    return 123
end
function spawn_non_sync_object(_, modelId, x, y, z, setup)
    local object = {
        modelId = modelId,
        oPosX = x, oPosY = y, oPosZ = z,
        oTimer = nextId,
        header = { gfx = { shadowInvisible = false } },
    }
    nextId = nextId + 1
    behavior.init(object)
    if setup then setup(object) end
    spawnedObject = object
    return object
end
function obj_mark_for_deletion(object) object.deleted = true end

gLakituState = { curPos = { x = 100, y = 200, z = 300 } }
gFirstPersonCamera = { yaw = 0, pitch = 0 }
gMarioStates = {
    [0] = {
        playerIndex = 0,
        controller = { buttonPressed = 0 },
        motion = { horizontalSpeed = 0, onGround = true, inWater = false },
    },
}
SteveCraft = {
    physics = {
        get_animation_state = function(m) return m.motion end,
    },
}

dofile("first_person_hand.lua")

local pose = SteveCraft.firstPersonHand.compute_viewmodel_pose(
    gLakituState.curPos, 0, 0, 10,
    { horizontalSpeed = 0, onGround = true }, 0
)
assert(type(pose.x) == "number" and type(pose.y) == "number" and type(pose.z) == "number")
assert(pose.yaw ~= 0, "the long arm axis must point toward the screen centre, not along camera depth")
assert(pose.roll > 0, "the wrist should sit above the shoulder in the first-person view")

local rotated = SteveCraft.firstPersonHand.compute_viewmodel_pose(
    gLakituState.curPos, 0x4000, 0, 10,
    { horizontalSpeed = 0, onGround = true }, 0
)
assert(rotated.yaw ~= pose.yaw, "viewmodel axis did not rotate with camera yaw")

local lookingUp = SteveCraft.firstPersonHand.compute_viewmodel_pose(
    gLakituState.curPos, 0, -0x1000, 10,
    { horizontalSpeed = 0, onGround = true }, 0
)
assert(lookingUp.y ~= pose.y or lookingUp.roll ~= pose.roll,
    "viewmodel did not respond to camera pitch")

-- Exercise the real spawn/loop callbacks and verify the detached right arm
-- is positioned from the current camera, not from Mario's shoulder animation.
events[HOOK_MARIO_UPDATE](gMarioStates[0])
local hand = spawnedObject
assert(behavior ~= nil, "first-person behavior was not registered")
assert(hand ~= nil and hand.modelId == 123, "Steve hand was not spawned")
gMarioStates[0].controller.buttonPressed = 0
behavior.loop(hand)
assert(hand.header.gfx.shadowInvisible == true, "viewmodel generated a native shadow")
local firstRoll = hand.oFaceAngleRoll
gMarioStates[0].controller.buttonPressed = B_BUTTON
behavior.loop(hand)
gMarioStates[0].controller.buttonPressed = 0
behavior.loop(hand)
assert(hand.oFaceAngleRoll ~= firstRoll, "attack did not swing the first-person arm")

gFirstPersonCamera.yaw = 0x4000
behavior.loop(hand)
assert(hand.oFaceAngleYaw ~= pose.yaw or hand.oPosX ~= pose.x,
    "runtime viewmodel did not follow camera rotation")

firstPerson = false
behavior.loop(hand)
assert(hand.deleted == true, "viewmodel should be removed when leaving first person")

print("SteveCraft first-person hand geometry tests passed")
