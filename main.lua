-- SteveCraft 64 - First Person Camera
-- Version: 0.1.0-alpha
-- Target: sm64coopdx (ManIsCat2 Android fork)

local function keep_first_person_enabled()
    -- "enabled" reports whether first-person mode is configured as enabled.
    -- get_first_person_enabled() can be false during engine-controlled camera
    -- cancellations, so it is intentionally not used here.
    if not gFirstPersonCamera.enabled then
        set_first_person_enabled(true)
    end
end

-- Enable immediately when the mod loads.
set_first_person_enabled(true)

-- Re-enable the setting if another menu or camera option turns it off.
hook_event(HOOK_UPDATE, keep_first_person_enabled)

-- Reassert the setting after loading or warping into a level.
hook_event(HOOK_ON_LEVEL_INIT, keep_first_person_enabled)
hook_event(HOOK_ON_WARP, keep_first_person_enabled)
