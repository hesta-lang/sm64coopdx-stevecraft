-- SteveCraft 64 - Minecraft-style perspective controller
-- Three views: first person, third-person back, third-person front.
-- Third person uses SM64CoopDX's ROM_HACK camera implementation:
-- orbit, configurable distance/height, and native ray-based wall collision.

SteveCraft = SteveCraft or {}
SteveCraft.PERSPECTIVE_FIRST_PERSON = 0
SteveCraft.PERSPECTIVE_THIRD_PERSON_BACK = 1
SteveCraft.PERSPECTIVE_THIRD_PERSON_FRONT = 2
SteveCraft.perspectiveMode = SteveCraft.perspectiveMode or SteveCraft.PERSPECTIVE_FIRST_PERSON

local applyPerspectiveWhenReady = true
local savedCameraSettings = nil

local THIRD_PERSON_DISTANCE = 400
local THIRD_PERSON_HEIGHT = 160

local function save_camera_settings()
    if savedCameraSettings ~= nil then return end
    savedCameraSettings = {
        override = camera_get_romhack_override(),
        switchable = camera_romhack_get_allow_switchable(),
        dpad = camera_romhack_get_allow_dpad_usage(),
        collisions = camera_romhack_get_collisions(),
        zoomInDist = camera_romhack_get_zoomed_in_dist(),
        zoomOutDist = camera_romhack_get_zoomed_out_dist(),
        zoomInHeight = camera_romhack_get_zoomed_in_height(),
        zoomOutHeight = camera_romhack_get_zoomed_out_height(),
    }
end

local function restore_camera_settings()
    if savedCameraSettings == nil then return end
    camera_romhack_allow_switchable(savedCameraSettings.switchable)
    camera_romhack_allow_dpad_usage(savedCameraSettings.dpad)
    camera_romhack_set_collisions(savedCameraSettings.collisions)
    camera_romhack_set_zoomed_in_dist(savedCameraSettings.zoomInDist)
    camera_romhack_set_zoomed_out_dist(savedCameraSettings.zoomOutDist)
    camera_romhack_set_zoomed_in_height(savedCameraSettings.zoomInHeight)
    camera_romhack_set_zoomed_out_height(savedCameraSettings.zoomOutHeight)
    camera_set_romhack_override(savedCameraSettings.override)
end

local function configure_minecraft_third_person()
    save_camera_settings()

    -- Allow this mod to use the ROM_HACK camera on vanilla courses.
    camera_set_romhack_override(RCO_ALL_INCLUDING_VANILLA)
    camera_romhack_allow_switchable(0)
    camera_romhack_allow_dpad_usage(1)
    camera_romhack_set_collisions(1)

    -- Minecraft's default third-person distance is four blocks.
    -- SM64CoopDX uses a different world scale, so 400 engine units is the
    -- matching initial target distance for Steve's two-block-tall model.
    camera_romhack_set_zoomed_in_dist(THIRD_PERSON_DISTANCE)
    camera_romhack_set_zoomed_out_dist(THIRD_PERSON_DISTANCE)
    camera_romhack_set_zoomed_in_height(THIRD_PERSON_HEIGHT)
    camera_romhack_set_zoomed_out_height(THIRD_PERSON_HEIGHT)
end

local function show_player_model(m)
    if m ~= nil and m.marioBodyState ~= nil then
        -- First-person sets modelState=0x100 to hide the body.
        -- Clear that state as soon as a third-person view is selected.
        m.marioBodyState.modelState = 0
    end
end

local function enter_first_person(m)
    set_first_person_enabled(false)

    if m ~= nil and m.area ~= nil and m.area.camera ~= nil then
        restore_camera_settings()
        set_camera_mode(m.area.camera, CAMERA_MODE_BEHIND_MARIO, 0)
    else
        restore_camera_settings()
    end

    show_player_model(m)
    if m ~= nil and m.faceAngle ~= nil and gFirstPersonCamera ~= nil then
        gFirstPersonCamera.yaw = m.faceAngle.y + 0x8000
        gFirstPersonCamera.pitch = 0
    end
    set_first_person_enabled(true)
end

local function enter_third_person(m, frontView)
    if m == nil or m.area == nil or m.area.camera == nil then
        return false
    end

    set_first_person_enabled(false)
    show_player_model(m)
    configure_minecraft_third_person()

    -- Minecraft third-person back places the camera behind the player.
    -- Front view rotates the view direction by 180 degrees.
    local viewYaw = m.faceAngle.y
    if not frontView then
        viewYaw = viewYaw + 0x8000
    end

    -- ROM_HACK camera initialises its orbit from the current camera position.
    -- Its internal yaw convention swaps X/Z, so seed with (cos(yaw), sin(yaw)).
    local seedX = math.floor(m.pos.x + coss(viewYaw) * THIRD_PERSON_DISTANCE)
    local seedZ = math.floor(m.pos.z + sins(viewYaw) * THIRD_PERSON_DISTANCE)
    local seedY = math.floor(m.pos.y)

    -- The fixed-mode setter skips the previous camera interpolation. Switching
    -- to ROM_HACK with zero transition frames makes the perspective change immediate.
    set_camera_mode_fixed(m.area.camera, seedX, seedY, seedZ)
    set_camera_mode(m.area.camera, CAMERA_MODE_ROM_HACK, 0)
    return true
end

local function apply_perspective(m)
    if m == nil or m.playerIndex ~= 0 then return end

    if SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON then
        enter_first_person(m)
        applyPerspectiveWhenReady = false
        return
    end

    if SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_THIRD_PERSON_FRONT then
        applyPerspectiveWhenReady = not enter_third_person(m, true)
    else
        applyPerspectiveWhenReady = not enter_third_person(m, false)
    end
end

local function cycle_perspective()
    SteveCraft.perspectiveMode =
        (SteveCraft.perspectiveMode + 1) % 3
    applyPerspectiveWhenReady = true
end

local function on_mario_update(m)
    if m == nil or m.playerIndex ~= 0 then return end

    -- Y cycles FIRST PERSON -> THIRD PERSON BACK -> THIRD PERSON FRONT.
    -- D-pad is deliberately left free for the ROM_HACK camera orbit:
    -- Up recentres behind Steve, Left/Right orbit, Down snaps to 45 degrees.
    if m.controller ~= nil and (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        cycle_perspective()
    end

    if applyPerspectiveWhenReady then
        apply_perspective(m)
    elseif SteveCraft.perspectiveMode ~= SteveCraft.PERSPECTIVE_FIRST_PERSON then
        show_player_model(m)
    end
end

local function on_level_init()
    applyPerspectiveWhenReady = true
end

local function on_warp()
    applyPerspectiveWhenReady = true
end

-- Preserve first-person as the default mode used by 0.5.x.
set_first_person_enabled(
    SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON
)

hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
