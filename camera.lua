-- SteveCraft 64 - First-person camera
-- This is the proven camera implementation from 0.1.0-alpha.

local function keep_first_person_enabled()
    -- Use the configured flag, not get_first_person_enabled().
    -- The getter may be false during engine-controlled camera cancellations.
    if not gFirstPersonCamera.enabled then
        set_first_person_enabled(true)
    end
end

-- Enable immediately when this script loads.
set_first_person_enabled(true)

-- Re-enable the setting if another menu or camera option turns it off.
hook_event(HOOK_UPDATE, keep_first_person_enabled)

-- Reassert the setting after loading or warping into a level.
hook_event(HOOK_ON_LEVEL_INIT, keep_first_person_enabled)
hook_event(HOOK_ON_WARP, keep_first_person_enabled)
