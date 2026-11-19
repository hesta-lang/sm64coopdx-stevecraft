-- SteveCraft 64 - Minecraft-like free touch camera
-- The third-person camera is SM64CoopDX NEWCAM (Puppycam).
-- In TOUCH_CONTROLS builds it consumes touch_x/touch_y from the native
-- TOUCH_MOUSE region, so the player can orbit by dragging on the right side
-- of the phone screen instead of holding C-buttons or the D-pad.

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
        freeCam = camera_config_is_free_cam_enabled(),
        mouseLook = camera_config_is_mouse_look_enabled(),
        collisions = camera_config_is_collision_enabled(),
        analog = camera_config_is_analog_cam_enabled(),
        dpad = camera_config_is_dpad_enabled(),
        center = camera_config_get_centering(),
        xSensitivity = camera_config_get_x_sensitivity(),
        ySensitivity = camera_config_get_y_sensitivity(),
        pan = camera_config_get_pan_level(),
        aggression = camera_config_get_aggression(),
        deceleration = camera_config_get_deceleration(),
    }
end

local function restore_camera_settings(m)
    if savedCameraSettings == nil then return end
    local settings = savedCameraSettings

    -- Restore options first. Free-camera enable is last because its setter
    -- calls newcam_init_settings() and restores the mode state.
    camera_config_enable_mouse_look(settings.mouseLook)
    camera_config_enable_collisions(settings.collisions)
    camera_config_enable_analog_cam(settings.analog)
    camera_config_enable_dpad(settings.dpad)
    camera_config_enable_centering(settings.center)
    camera_config_set_x_sensitivity(settings.xSensitivity)
    camera_config_set_y_sensitivity(settings.ySensitivity)
    camera_config_set_pan_level(settings.pan)
    camera_config_set_aggression(settings.aggression)
    camera_config_set_deceleration(settings.deceleration)
    camera_config_enable_free_cam(settings.freeCam)

    if m ~= nil and m.area ~= nil and m.area.camera ~= nil then
        if settings.freeCam then
            set_camera_mode(m.area.camera, CAMERA_MODE_NEWCAM, 0)
        else
            set_camera_mode(m.area.camera, CAMERA_MODE_BEHIND_MARIO, 0)
        end
    end
    savedCameraSettings = nil
end

local function configure_touch_free_camera(m)
    save_camera_settings()

    -- NEWCAM is the camera system used by the fork's touchscreen mouse-look.
    -- TOUCH_MOUSE supplies movement deltas through touch_x/touch_y when the
    -- user drags in the configured right-hand camera region.
    camera_config_enable_mouse_look(true)
    camera_config_enable_collisions(true)
    camera_config_enable_analog_cam(false)
    camera_config_enable_dpad(false)
    camera_config_enable_centering(false)
    camera_config_set_x_sensitivity(65)
    camera_config_set_y_sensitivity(45)
    camera_config_set_pan_level(0)
    camera_config_set_aggression(0)
    camera_config_set_deceleration(75)
    camera_config_enable_free_cam(true)

    if m ~= nil and m.area ~= nil and m.area.camera ~= nil then
        set_camera_mode(m.area.camera, CAMERA_MODE_NEWCAM, 0)
    end
end

local function show_player_model(m)
    if m ~= nil and m.marioBodyState ~= nil then
        m.marioBodyState.modelState = 0
    end
end

local function enter_first_person(m)
    set_first_person_enabled(false)
    restore_camera_settings(m)
    show_player_model(m)
    set_first_person_enabled(true)
end

local function enter_third_person(m)
    if m == nil or m.area == nil or m.area.camera == nil then
        return false
    end

    set_first_person_enabled(false)
    show_player_model(m)
    configure_touch_free_camera(m)
    return true
end

local function apply_perspective(m)
    if m == nil or m.playerIndex ~= 0 then return end

    -- The Android fork implements the actual Minecraft Camera runtime in C++.
    -- Do not route this mode through NEWCAM: that would be SM64's camera, not
    -- the reverse-ported Minecraft camera.
    if stevecraft_camera_enable ~= nil and stevecraft_camera_set_perspective ~= nil then
        stevecraft_camera_enable(true)
        stevecraft_camera_set_perspective(SteveCraft.perspectiveMode)
        set_first_person_enabled(false)
        applyPerspectiveWhenReady = false
        show_player_model(m)
        return
    end

    -- Compatibility fallback for older builds without the native runtime.
    if SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON then
        enter_first_person(m)
        applyPerspectiveWhenReady = false
    else
        applyPerspectiveWhenReady = not enter_third_person(m)
    end
end

local function on_mario_update(m)
    if m == nil or m.playerIndex ~= 0 then return end

    -- Y toggles first/third person. In third person, use touch-drag to orbit
    -- freely through the rear and front views rather than a button preset.
    if m.controller ~= nil and (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        SteveCraft.perspectiveMode = (SteveCraft.perspectiveMode + 1) % 3
        applyPerspectiveWhenReady = true
    end

    if applyPerspectiveWhenReady then
        apply_perspective(m)
    elseif SteveCraft.perspectiveMode ~= SteveCraft.PERSPECTIVE_FIRST_PERSON then
        show_player_model(m)
    end
end

local function on_level_init()
    savedCameraSettings = nil
    applyPerspectiveWhenReady = true
end

local function on_warp()
    applyPerspectiveWhenReady = true
end

set_first_person_enabled(
    SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON
)

hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
