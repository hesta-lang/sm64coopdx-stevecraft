-- SteveCraft 64 - Minecraft-style perspective controller.
--
-- Lua exposes the native first-person camera and Camera.yaw, while
-- LakituState position/focus remain engine-owned. This uses the native
-- first-person camera + Steve arm viewmodel and NEWCAM for third person.
-- It does not pretend to replace Lakitu's XYZ camera solver.

SteveCraft = SteveCraft or {}
local MinecraftCamera = require("minecraft_26_3_camera")
SteveCraft.cameraMath = MinecraftCamera
SteveCraft.PERSPECTIVE_FIRST_PERSON = 0
SteveCraft.PERSPECTIVE_THIRD_PERSON = 1
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

local function is_local_steve(m)
    local character = SteveCraft.character
    local proxy = SteveCraft.proxy
    return m ~= nil
        and m.playerIndex == 0
        and character ~= nil
        and character.ready
        and character.modelId ~= nil
        and proxy ~= nil
        and type(proxy.is_attached) == "function"
        and proxy.is_attached(0)
end

local function enter_first_person(m)
    restore_camera_settings(m)
    set_first_person_enabled(true)
    if gFirstPersonCamera ~= nil then
        -- Keep native touch/look input authoritative; do not lock angles to Mario.
        gFirstPersonCamera.forceYaw = false
        gFirstPersonCamera.forcePitch = false
    end
end

local function set_minecraft_orbit_yaw(m, front)
    if m == nil or m.area == nil or m.area.camera == nil
        or m.faceAngle == nil then return end
    local camera = m.area.camera
    if camera.yaw == nil then return end

    -- Camera.yaw points from focus toward the camera. Rear view is behind Steve;
    -- front view is on Steve's forward side. NEWCAM then owns live touch orbit.
    local orbit_yaw = ((m.faceAngle.y or 0) + (front and 0 or 0x8000)) % 65536
    camera.yaw = orbit_yaw
    if camera.nextYaw ~= nil then camera.nextYaw = orbit_yaw end
end

local function enter_third_person(m, front)
    if m == nil or m.area == nil or m.area.camera == nil then return false end
    set_first_person_enabled(false)
    configure_touch_free_camera(m)
    set_minecraft_orbit_yaw(m, front)
    return true
end

local function apply_perspective(m)
    if not is_local_steve(m) then return end
    if SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON then
        enter_first_person(m)
        applyPerspectiveWhenReady = false
    else
        local front = SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_THIRD_PERSON_FRONT
        applyPerspectiveWhenReady = not enter_third_person(m, front)
    end
end

function SteveCraft.set_perspective(mode)
    if mode ~= SteveCraft.PERSPECTIVE_FIRST_PERSON
        and mode ~= SteveCraft.PERSPECTIVE_THIRD_PERSON
        and mode ~= SteveCraft.PERSPECTIVE_THIRD_PERSON_FRONT then
        return false
    end
    SteveCraft.perspectiveMode = mode
    applyPerspectiveWhenReady = true
    return true
end

function SteveCraft.cycle_perspective()
    local next_mode = (SteveCraft.perspectiveMode + 1) % 3
    return SteveCraft.set_perspective(next_mode)
end

local function on_mario_update(m)
    if not is_local_steve(m) then return end
    if m.controller ~= nil and Y_BUTTON ~= nil
        and (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        SteveCraft.cycle_perspective()
    end

    -- Recover if another script or a cutscene toggles the camera behind our back.
    local actual_first_person = get_first_person_enabled() == true
    local expected_first_person = SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON
    if actual_first_person ~= expected_first_person then
        applyPerspectiveWhenReady = true
    end
    if applyPerspectiveWhenReady then apply_perspective(m) end
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
