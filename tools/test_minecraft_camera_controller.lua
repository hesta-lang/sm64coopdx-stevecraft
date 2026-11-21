-- End-to-end tests for the Lua-owned Steve camera.
package.path = "./?.lua;" .. package.path

OBJ_LIST_UNIMPORTANT = 9
OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE = 0x100
E_MODEL_NONE = -1
Y_BUTTON = 0x1
INPUT_Z_DOWN = 0x2
ACT_CROUCHING = 0x3
HOOK_MARIO_UPDATE = "mario_update"
HOOK_ON_LEVEL_INIT = "level_init"
HOOK_ON_WARP = "warp"
HOOK_ON_EXIT = "exit"
HOOK_ON_OBJECT_UNLOAD = "object_unload"

local events = {}
local cameraBehavior = nil
local cameraBehaviorId = 1000
local cameraObject = nil
local frozen = false
local checkingSurfaces = false
local wallThreshold = nil
local wallQueries = 0
local nextObjectId = 1

function print() end
function hook_event(name, callback) events[name] = callback end
function hook_behavior(_, list, _, init, loop, name)
    assert(list == OBJ_LIST_UNIMPORTANT, "camera controller must update after the player list")
    cameraBehavior = { init = init, loop = loop, name = name }
    return cameraBehaviorId
end
function spawn_non_sync_object(behaviorId, model, x, y, z)
    assert(model == E_MODEL_NONE, "camera controller must be renderless")
    assert(behaviorId == cameraBehaviorId, "wrong camera behavior ID")
    local object = { oTimer = 0, id = nextObjectId, x = x, y = y, z = z }
    nextObjectId = nextObjectId + 1
    cameraBehavior.init(object)
    cameraObject = object
    return object
end
function set_first_person_enabled(enabled)
    gFirstPersonCamera.enabled = enabled
end
function get_first_person_enabled()
    return gFirstPersonCamera.enabled
end
function camera_freeze() frozen = true end
function camera_unfreeze() frozen = false end
function camera_is_frozen() return frozen end
function camera_get_checking_surfaces() return checkingSurfaces end
function camera_set_checking_surfaces(value) checkingSurfaces = value end
function collision_get_temp_wall_collision_data()
    return { x = 0, y = 0, z = 0, offsetY = 0, radius = 0, numWalls = 0 }
end
function find_wall_collisions(wcd)
    wallQueries = wallQueries + 1
    if wallThreshold ~= nil and wcd.z > wallThreshold then
        wcd.numWalls = 1
        return 1
    end
    wcd.numWalls = 0
    return 0
end
function find_floor()
    return 0, nil
end
function find_ceil()
    return 11000, nil
end
function obj_mark_for_deletion(object) object.deleted = true end

gFirstPersonCamera = {
    enabled = false, yaw = 0, pitch = 0, offset = { x = 0, y = 0, z = 0 }, fov = 70,
}
gLakituState = {
    pos = { x = 0, y = 0, z = 0 },
    curPos = { x = 0, y = 0, z = 0 },
    goalPos = { x = 0, y = 0, z = 0 },
    focus = { x = 0, y = 0, z = 0 },
    curFocus = { x = 0, y = 0, z = 0 },
    goalFocus = { x = 0, y = 0, z = 0 },
    yaw = 0, nextYaw = 0, oldYaw = 0, oldPitch = 0, oldRoll = 0, roll = 0,
    focusDistance = 0, posHSpeed = 0, posVSpeed = 0, focHSpeed = 0, focVSpeed = 0,
}
local nativeCamera = {
    pos = { x = 0, y = 0, z = 0 },
    focus = { x = 0, y = 0, z = 0 },
    yaw = 0, nextYaw = 0, mode = 0,
}
local mario = {
    playerIndex = 0,
    pos = { x = 10, y = 20, z = 30 },
    vel = { x = 0, y = 0, z = 0 },
    faceAngle = { x = 0, y = 0, z = 0x8000 },
    controller = { buttonPressed = 0 },
    input = 0,
    action = 0,
    area = { camera = nativeCamera },
    motion = { crouching = false },
}
gMarioStates = { [0] = mario }
SteveCraft = {
    character = { ready = true, modelId = 123 },
    proxy = { is_attached = function(index) return index == 0 end },
    physics = {
        get_animation_state = function(m) return m.motion end,
    },
}

dofile("camera.lua")
assert(cameraBehavior ~= nil, "independent camera behavior was not registered")

-- The hook is inside OBJ_LIST_PLAYER. It enables the native touch-look sampler
-- and freezes the native updater; the controller object writes the final pose
-- later in OBJ_LIST_UNIMPORTANT.
events[HOOK_MARIO_UPDATE](mario)
assert(gFirstPersonCamera.enabled == true, "touch-look input provider was not enabled")
assert(frozen == true, "native Mario camera updater was not frozen")
assert(cameraObject ~= nil, "independent camera controller object was not spawned")

cameraBehavior.loop(cameraObject)
local pose = SteveCraft.cameraController.get_last_pose()
assert(pose ~= nil and pose.firstPerson == true)
local eyeHeight = 20 + 1.62 * (160 / 1.8)
assert(math.abs(nativeCamera.pos.y - eyeHeight) < 1e-5,
    "first-person camera is not at Minecraft standing eye height")
assert(math.abs(nativeCamera.pos.x - 10) < 1e-5 and math.abs(nativeCamera.pos.z - 30) < 1e-5,
    "first-person camera origin is not aligned with the player eye")
assert(nativeCamera.focus.z < nativeCamera.pos.z,
    "first-person focus does not follow the camera's forward vector")

-- Crouching changes the camera to Minecraft's 1.27-block eye height.
mario.motion = { crouching = true }
events[HOOK_MARIO_UPDATE](mario)
cameraBehavior.loop(cameraObject)
pose = SteveCraft.cameraController.get_last_pose()
assert(math.abs(pose.position.y - (20 + 1.27 * (160 / 1.8))) < 1e-5,
    "crouching camera eye height is incorrect")

-- Y switches to third-person back. Four blocks is measured from the eye point.
mario.motion = { crouching = false }
mario.controller.buttonPressed = Y_BUTTON
events[HOOK_MARIO_UPDATE](mario)
mario.controller.buttonPressed = 0
cameraBehavior.loop(cameraObject)
pose = SteveCraft.cameraController.get_last_pose()
local wanted = 4 * (160 / 1.8)
assert(pose.mode == SteveCraft.PERSPECTIVE_THIRD_PERSON)
assert(math.abs(pose.distance - wanted) < 1e-5, "third-person distance is not four Minecraft blocks")
assert(pose.position.z > pose.focus.z, "rear camera is not behind the player")
assert(math.abs(nativeCamera.pos.x - gLakituState.pos.x) < 1e-5
    and math.abs(nativeCamera.pos.z - gLakituState.pos.z) < 1e-5,
    "Camera and Lakitu transforms diverged")

-- A host wall hit clips the camera before it enters the wall. The collision
-- query is performed as a camera query and its previous mode is restored.
wallThreshold = 150
local beforeQueries = wallQueries
cameraBehavior.loop(cameraObject)
pose = SteveCraft.cameraController.get_last_pose()
assert(wallQueries > beforeQueries, "third-person camera did not query level walls")
assert(pose.distance < wanted and pose.distance >= 0,
    "third-person camera failed to shorten its distance at a wall")
assert(checkingSurfaces == false, "camera collision mode was not restored")

-- The native touch sampler's yaw/pitch feeds the independent front view too.
wallThreshold = nil
gFirstPersonCamera.yaw = 0
gFirstPersonCamera.pitch = 0
mario.controller.buttonPressed = Y_BUTTON
events[HOOK_MARIO_UPDATE](mario)
mario.controller.buttonPressed = 0
cameraBehavior.loop(cameraObject)
pose = SteveCraft.cameraController.get_last_pose()
assert(pose.front == true, "Y did not select Minecraft front third-person")
assert(pose.position.z < pose.focus.z, "front camera was not placed in front of Steve")

-- Public controls clamp and retain the Minecraft distance setting.
assert(SteveCraft.cameraController.set_distance_blocks(5.5))
assert(SteveCraft.cameraController.get_distance_blocks() == 5.5)
assert(not SteveCraft.cameraController.set_distance_blocks(0))

-- Leaving the mod restores the camera freeze and the user's original
-- first-person enabled state.
events[HOOK_ON_EXIT]()
assert(frozen == false, "native camera freeze was not released on exit")
assert(gFirstPersonCamera.enabled == false, "original native first-person state was not restored")

print("SteveCraft independent camera controller tests passed")
