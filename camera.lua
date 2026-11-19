-- SteveCraft 64 - Lua-only first/third-person camera.
-- NEWCAM supplies Android touch orbit and SM64 surface collision. The Lua
-- API does not expose writable Lakitu position/focus, so camera placement
-- remains delegated to the engine rather than imitated incompletely.

SteveCraft = SteveCraft or {}
SteveCraft.PERSPECTIVE_FIRST_PERSON = 0
SteveCraft.PERSPECTIVE_THIRD_PERSON = 1
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

local function is_local_steve(m)
    local character = SteveCraft.character
    return m ~= nil
        and m.playerIndex == 0
        and character ~= nil
        and character.ready
        and character.modelId ~= nil
        and gPlayerSyncTable ~= nil
        and gPlayerSyncTable[0] ~= nil
        and gPlayerSyncTable[0].modelId == character.modelId
end

local function enter_first_person(m)
    set_first_person_enabled(false)
    restore_camera_settings(m)
    show_player_model(m)
    set_first_person_enabled(true)
end

local function enter_third_person(m)
    if m == nil or m.area == nil or m.area.camera == nil then return false end
    set_first_person_enabled(false)
    show_player_model(m)
    configure_touch_free_camera(m)
    return true
end

local function apply_perspective(m)
    if not is_local_steve(m) then return end
    if SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON then
        enter_first_person(m)
        applyPerspectiveWhenReady = false
    else
        applyPerspectiveWhenReady = not enter_third_person(m)
    end
end

local function on_mario_update(m)
    if not is_local_steve(m) then return end
    if m.controller ~= nil and (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        SteveCraft.perspectiveMode = 1 - SteveCraft.perspectiveMode
        applyPerspectiveWhenReady = true
    end
    if applyPerspectiveWhenReady then
        apply_perspective(m)
    elseif SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_THIRD_PERSON then
        show_player_model(m)
    end
end

local function on_level_init()
    restore_camera_settings(nil)
    applyPerspectiveWhenReady = true
end

local function on_warp()
    applyPerspectiveWhenReady = true
end

local function on_exit()
    restore_camera_settings(nil)
    set_first_person_enabled(false)
    applyPerspectiveWhenReady = true
end

set_first_person_enabled(
    SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON
)

hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_EXIT, on_exit)
