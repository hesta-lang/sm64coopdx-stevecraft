-- End-to-end tests for the Lua-owned Steve camera.
package.path = "./?.lua;" .. package.path

OBJ_LIST_UNIMPORTANT = 9
OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE = 0x100
E_MODEL_NONE = -1
Y_BUTTON = 0x1
INPUT_Z_DOWN = 0x2
ACT_CROUCHING = 0x3
L_JPAD = 0x200
R_JPAD = 0x100
U_JPAD = 0x800
D_JPAD = 0x400
L_CBUTTONS = 0x2
R_CBUTTONS = 0x1
U_CBUTTONS = 0x8
D_CBUTTONS = 0x4
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
    local dx = wcd.x - 10
    local dy = wcd.y - (20 + 1.62 * (160 / 1.8))
    local dz = wcd.z - 30
    local distanceFromEye = math.sqrt(dx * dx + dy * dy + dz * dz)
    if wallThreshold ~= nil and distanceFromEye > wallThreshold then
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
    controller = { buttonPressed = 0, buttonDown = 0 },
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
local focusDx = nativeCamera.focus.x - nativeCamera.pos.x
local focusDy = nativeCamera.focus.y - nativeCamera.pos.y
local focusDz = nativeCamera.focus.z - nativeCamera.pos.z
local focusDistance = math.sqrt(focusDx * focusDx + focusDy * focusDy + focusDz * focusDz)
assert(math.abs(focusDistance - 100) < 1e-5,
    "first-person focus must remain 100 units along the camera direction")
assert(math.abs(nativeCamera.focus.x - pose.focus.x) < 1e-5
    and math.abs(nativeCamera.focus.y - pose.focus.y) < 1e-5
    and math.abs(nativeCamera.focus.z - pose.focus.z) < 1e-5,
    "Camera focus diverged from Steve's computed camera direction")

-- Android touch-screen D-pad is available to Lua through buttonDown. Right
-- rotates yaw; up rotates pitch. Reset after testing so later geometry checks
-- use a predictable forward direction.
local initialYaw = gFirstPersonCamera.yaw
mario.controller.buttonDown = R_JPAD
cameraBehavior.loop(cameraObject)
local yawStep = math.floor(2.0 * 65536 / 360 + 0.5)
assert(gFirstPersonCamera.yaw == (initialYaw + yawStep) % 65536,
    "right D-pad did not rotate the independent camera")
mario.controller.buttonDown = U_JPAD
cameraBehavior.loop(cameraObject)
assert(gFirstPersonCamera.pitch < 0, "up D-pad did not look upward")
mario.controller.buttonDown = 0
gFirstPersonCamera.yaw = 0
gFirstPersonCamera.pitch = 0
assert(SteveCraft.cameraController.set_digital_look_speed(3.0))
assert(SteveCraft.cameraController.get_digital_look_speed() == 3.0)
assert(not SteveCraft.cameraController.set_digital_look_speed("fast"))
assert(SteveCraft.cameraController.set_digital_look_speed(2.0))

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
local rearDx = pose.position.x - pose.focus.x
local rearDy = pose.position.y - pose.focus.y
local rearDz = pose.position.z - pose.focus.z
assert(math.abs(math.sqrt(rearDx * rearDx + rearDy * rearDy + rearDz * rearDz) - wanted) < 1e-5,
    "rear camera is not four blocks from Steve's eye anchor")
assert(math.abs(nativeCamera.pos.x - gLakituState.pos.x) < 1e-5
    and math.abs(nativeCamera.pos.z - gLakituState.pos.z) < 1e-5,
    "Camera and Lakitu transforms diverged")

-- A host wall hit clips the camera before it enters the wall. The collision
-- query is performed as a camera query and its previous mode is restored.
wallThreshold = 150 -- collision plane 150 SM64 units away from the eye, independent of yaw
local beforeQueries = wallQueries
cameraBehavior.loop(cameraObject)
pose = SteveCraft.cameraController.get_last_pose()
assert(wallQueries > beforeQueries, "third-person camera did not query level walls")
assert(pose.distance < wanted and pose.distance >= 0,
    "third-person camera failed to shorten its distance at a wall: got "
        .. tostring(pose.distance) .. ", wanted " .. tostring(wanted)
        .. ", wall queries " .. tostring(wallQueries - beforeQueries)
        .. ", camera Z " .. tostring(pose.position.z) .. ", focus Z " .. tostring(pose.focus.z))
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
assert(math.abs((pose.yaw - 0) % 65536 - 0x8000) < 1e-5
    or math.abs((pose.yaw - 0x8000) % 65536) < 1e-5,
    "front perspective did not reverse the camera yaw")
local frontDx = pose.position.x - pose.focus.x
local frontDy = pose.position.y - pose.focus.y
local frontDz = pose.position.z - pose.focus.z
assert(math.abs(math.sqrt(frontDx * frontDx + frontDy * frontDy + frontDz * frontDz) - wanted) < 1e-5,
    "front camera distance is not four blocks")

-- Public controls clamp and retain the Minecraft distance setting.
assert(SteveCraft.cameraController.set_distance_blocks(5.5))
assert(SteveCraft.cameraController.get_distance_blocks() == 5.5)
assert(SteveCraft.cameraController.set_distance_blocks(0))
assert(SteveCraft.cameraController.get_distance_blocks() == 1,
    "camera distance lower bound must be clamped to one block")

-- Leaving the mod restores the camera freeze and the user's original
-- first-person enabled state.
events[HOOK_ON_EXIT]()
assert(frozen == false, "native camera freeze was not released on exit")
assert(gFirstPersonCamera.enabled == false, "original native first-person state was not restored")

print("SteveCraft independent camera controller tests passed")
