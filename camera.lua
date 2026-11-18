-- SteveCraft 64 - perspective controller
-- First-person remains the default. D-pad Up cycles between first and
-- native third-person free-roam view. The camera engine handles orbit,
-- smoothing and wall avoidance while first-person is disabled.

SteveCraft = SteveCraft or {}
SteveCraft.PERSPECTIVE_FIRST_PERSON = 0
SteveCraft.PERSPECTIVE_THIRD_PERSON = 1
SteveCraft.perspectiveMode = SteveCraft.perspectiveMode or SteveCraft.PERSPECTIVE_FIRST_PERSON

local applyPerspectiveWhenReady = true

local function apply_perspective(m)
    if m == nil or m.playerIndex ~= 0 then
        return
    end

    if SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON then
        set_first_person_enabled(true)
        applyPerspectiveWhenReady = false
        return
    end

    -- Let SM64CoopDX's native Lakitu camera take over. FREE_ROAM uses the
    -- standard third-person follow camera, accepts camera orbit input and
    -- runs the engine's built-in geometry/wall collision handling.
    set_first_person_enabled(false)

    if m.area ~= nil and m.area.camera ~= nil then
        set_camera_mode(m.area.camera, CAMERA_MODE_FREE_ROAM, 18)
        applyPerspectiveWhenReady = false
    end
end

local function on_mario_update(m)
    if m == nil or m.playerIndex ~= 0 then
        return
    end

    -- Minecraft-style perspective cycling, using an Android-accessible
    -- controller button rather than forcing first person every frame.
    if (m.controller.buttonPressed & U_JPAD) ~= 0 then
        if SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON then
            SteveCraft.perspectiveMode = SteveCraft.PERSPECTIVE_THIRD_PERSON
        else
            SteveCraft.perspectiveMode = SteveCraft.PERSPECTIVE_FIRST_PERSON
        end
        applyPerspectiveWhenReady = true
    end

    if applyPerspectiveWhenReady then
        apply_perspective(m)
    end
end

local function on_level_init()
    -- Reapply the selected view after the new area has created its camera.
    applyPerspectiveWhenReady = true
end

local function on_warp()
    applyPerspectiveWhenReady = true
end

-- Keep first person as the initial/default mode, preserving the camera
-- that was already working in SteveCraft 0.5.x.
set_first_person_enabled(
    SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON
)

hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
