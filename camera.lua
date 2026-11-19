-- SteveCraft 64 - Native Minecraft-style camera
-- Requires the matching sm64coopdx-craft SteveCraft native-camera branch.
--
-- Y cycles through Minecraft's three camera types:
--   0 = first person
--   1 = third person, rear
--   2 = third person, front
--
-- The actual camera transform, collision rays, and Android touch deltas are
-- handled by the native engine. Lua only selects the perspective and settings.

SteveCraft = SteveCraft or {}
SteveCraft.PERSPECTIVE_FIRST_PERSON = 0
SteveCraft.PERSPECTIVE_THIRD_PERSON_BACK = 1
SteveCraft.PERSPECTIVE_THIRD_PERSON_FRONT = 2
SteveCraft.perspectiveMode = SteveCraft.perspectiveMode or SteveCraft.PERSPECTIVE_FIRST_PERSON

local applyPerspectiveWhenReady = true
local savedCameraSettings = nil

local function save_camera_settings()
    if savedCameraSettings ~= nil then return end
    savedCameraSettings = {
        mouseLook = camera_config_is_mouse_look_enabled(),
        xSensitivity = camera_config_get_x_sensitivity(),
        ySensitivity = camera_config_get_y_sensitivity(),
    }
end

local function configure_native_camera()
    save_camera_settings()

    -- Android touch gestures are fed to the native camera runtime while it is
    -- active. The engine handles wall clipping and camera geometry itself.
    camera_config_enable_mouse_look(true)
    camera_config_set_x_sensitivity(65)
    camera_config_set_y_sensitivity(45)
end

local function restore_camera_settings()
    if savedCameraSettings == nil then return end
    camera_config_enable_mouse_look(savedCameraSettings.mouseLook)
    camera_config_set_x_sensitivity(savedCameraSettings.xSensitivity)
    camera_config_set_y_sensitivity(savedCameraSettings.ySensitivity)
    savedCameraSettings = nil
end

local function apply_perspective(m)
    if m == nil or m.playerIndex ~= 0 or m.area == nil or m.area.camera == nil then
        return false
    end

    configure_native_camera()
    set_first_person_enabled(false)
    stevecraft_camera_set_perspective(SteveCraft.perspectiveMode)
    stevecraft_camera_enable(true)
    applyPerspectiveWhenReady = false
    return true
end

local function on_mario_update(m)
    if m == nil or m.playerIndex ~= 0 then return end

    if m.controller ~= nil and (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        SteveCraft.perspectiveMode = (SteveCraft.perspectiveMode + 1) % 3
        applyPerspectiveWhenReady = true
    end

    if applyPerspectiveWhenReady then
        apply_perspective(m)
    end
end

local function on_level_init()
    applyPerspectiveWhenReady = true
end

local function on_warp()
    applyPerspectiveWhenReady = true
end

local function on_exit()
    stevecraft_camera_enable(false)
    set_first_person_enabled(false)
    restore_camera_settings()
end

-- Do not let the legacy first-person camera fight the native Minecraft camera.
set_first_person_enabled(false)

hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_EXIT, on_exit)
