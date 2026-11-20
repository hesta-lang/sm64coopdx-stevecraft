-- Tests for SteveCraft's camera bridge and Minecraft eye-height mapping.
package.path = "./?.lua;" .. package.path

HOOK_MARIO_UPDATE = "mario_update"
HOOK_ON_LEVEL_INIT = "level_init"
HOOK_ON_WARP = "warp"
HOOK_ON_EXIT = "exit"

Y_BUTTON = 0x1
INPUT_Z_DOWN = 0x2
ACT_CROUCHING = 0x3

CAMERA_MODE_NEWCAM = 1
CAMERA_MODE_BEHIND_MARIO = 2

local events = {}
local firstPerson = false
local cameraMode = nil
function hook_event(name, callback) events[name] = callback end
function set_first_person_enabled(value) firstPerson = value end
function get_first_person_enabled() return firstPerson end
function camera_config_is_free_cam_enabled() return false end
function camera_config_is_mouse_look_enabled() return false end
function camera_config_is_collision_enabled() return true end
function camera_config_is_analog_cam_enabled() return true end
function camera_config_is_dpad_enabled() return true end
function camera_config_get_centering() return true end
function camera_config_get_x_sensitivity() return 50 end
function camera_config_get_y_sensitivity() return 50 end
function camera_config_get_pan_level() return 20 end
function camera_config_get_aggression() return 30 end
function camera_config_get_deceleration() return 25 end
function camera_config_enable_mouse_look() end
function camera_config_enable_collisions() end
function camera_config_enable_analog_cam() end
function camera_config_enable_dpad() end
function camera_config_enable_centering() end
function camera_config_set_x_sensitivity() end
function camera_config_set_y_sensitivity() end
function camera_config_set_pan_level() end
function camera_config_set_aggression() end
function camera_config_set_deceleration() end
function camera_config_enable_free_cam() end
function set_camera_mode(camera, mode)
    cameraMode = mode
    camera.mode = mode
end

SteveCraft = {
    character = { ready = true, modelId = 123 },
    proxy = { is_attached = function(index) return index == 0 end },
    physics = {
        get_animation_state = function(m)
            return m.motion
        end,
    },
}
gFirstPersonCamera = { offset = { x = 0, y = 3, z = 0 }, fov = 70 }
local nativeCamera = { yaw = 0, nextYaw = 0 }
local mario = {
    playerIndex = 0,
    input = 0,
    controller = { buttonPressed = 0 },
    faceAngle = { x = 0, y = 0, z = 0 },
    area = { camera = nativeCamera },
    motion = { crouching = false },
}
dofile("camera.lua")

events[HOOK_MARIO_UPDATE](mario)
assert(firstPerson == true, "default Steve perspective should be first-person")
assert(math.abs(gFirstPersonCamera.offset.y - 24) < 1e-5,
    "standing eye must be raised to Minecraft's 1.62-block height")

mario.motion = { crouching = true }
events[HOOK_MARIO_UPDATE](mario)
local crouchOffset = 1.27 * (160 / 1.8) - 120
assert(math.abs(gFirstPersonCamera.offset.y - crouchOffset) < 1e-5,
    "crouch eye height must follow Minecraft's 1.27-block height")

mario.motion = { crouching = false }
mario.controller.buttonPressed = Y_BUTTON
events[HOOK_MARIO_UPDATE](mario)
assert(SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_THIRD_PERSON)
assert(firstPerson == false, "third-person mode must disable the first-person camera")
assert(math.abs(gFirstPersonCamera.offset.y - 3) < 1e-5,
    "the user's original camera offset must be restored on perspective change")
assert(cameraMode == CAMERA_MODE_NEWCAM,
    "third-person mode must retain Android touch-orbit NEWCAM")

events[HOOK_ON_EXIT]()
assert(firstPerson == false)

print("SteveCraft camera bridge tests passed")
