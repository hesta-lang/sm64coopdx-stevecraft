-- Tests for independent Minecraft humanoid clips on the detached Steve actor.
package.path = "./?.lua;" .. package.path

ANIM_FLAG_6 = 0x40
local registered = {}
local setCalls = {}
function print() end

function smlua_anim_util_register_animation(name, flags, unused1, unused2, unused3, frames, values, indices)
    registered[name] = {
        flags = flags, frames = frames, values = values, indices = indices,
    }
end

function smlua_anim_util_set_animation(object, name)
    setCalls[#setCalls + 1] = { object = object, name = name }
    object.header.gfx.animInfo.curAnim = { name = name }
    object.header.gfx.animInfo.animID = #setCalls
end

SteveCraft = {
    physics = {
        get_animation_state = function(m) return m.motion end,
    },
}

dofile("animations.lua")

local expected = {
    "steve_mc_idle",
    "steve_mc_walk",
    "steve_mc_run",
    "steve_mc_crouch",
    "steve_mc_crouch_walk",
    "steve_mc_swim",
}
for _, name in ipairs(expected) do
    assert(registered[name] ~= nil, "missing registered Steve clip: " .. name)
    assert(registered[name].frames > 1, "animation clip must contain multiple frames: " .. name)
    assert(#registered[name].indices == 126, "unexpected skeleton channel count: " .. name)
end

local mario = {
    playerIndex = 0,
    motion = {
        horizontalSpeed = 0,
        onGround = true,
        inWater = false,
        crouching = false,
        sprinting = false,
    },
    -- Deliberately unrelated to the Steve clip selector: the detached actor
    -- must not inherit Mario's native animation ID or gPlayerSyncTable model ID.
    action = 0x04000440,
}
local visual = {
    header = { gfx = { animInfo = {
        animID = 12345,
        animFrame = 77,
        prevAnimFrame = 76,
        animAccel = 0x10000,
        animFrameAccelAssist = 0,
        animTimer = 10,
    } } },
}

local clips = {
    { name = "steve_mc_idle", motion = { horizontalSpeed = 0, onGround = true } },
    { name = "steve_mc_walk", motion = { horizontalSpeed = 3, onGround = true } },
    { name = "steve_mc_run", motion = { horizontalSpeed = 7, onGround = true, sprinting = true } },
    { name = "steve_mc_crouch", motion = { horizontalSpeed = 0, onGround = true, crouching = true } },
    { name = "steve_mc_crouch_walk", motion = { horizontalSpeed = 1.5, onGround = true, crouching = true } },
    { name = "steve_mc_swim", motion = { horizontalSpeed = 1, onGround = false, inWater = true } },
}
for _, case in ipairs(clips) do
    mario.motion = case.motion
    local before = #setCalls
    assert(SteveCraft.animations.update_visual(mario, visual), "animation update rejected " .. case.name)
    assert(#setCalls == before + 1, "clip transition did not call set_animation for " .. case.name)
    assert(setCalls[#setCalls].object == visual, "clip was applied to native Mario instead of detached Steve")
    assert(setCalls[#setCalls].name == case.name,
        "wrong clip selected: expected " .. case.name .. ", got " .. setCalls[#setCalls].name)
    assert(visual.header.gfx.animInfo.animFrame == -1, "new clip did not reset its frame")
    assert(SteveCraft.animations.get_active_clip(0) == case.name)
end

-- Enter walking once, then repeated frames of the same state must not
-- restart the clip loop.
mario.motion = { horizontalSpeed = 1.0, onGround = true }
assert(SteveCraft.animations.update_visual(mario, visual))
local before = #setCalls
assert(SteveCraft.animations.update_visual(mario, visual))
assert(#setCalls == before, "unchanged movement reset the walk cycle")
assert(visual.header.gfx.animInfo.animAccel > 0)

-- Changing the visual object forces its own animation state initialization.
local second = { header = { gfx = { animInfo = {} } } }
assert(SteveCraft.animations.update_visual(mario, second))
assert(setCalls[#setCalls].object == second, "new remote visual did not receive a clip")

SteveCraft.animations.reset_player(0)
assert(SteveCraft.animations.get_active_clip(0) == nil)

print("SteveCraft independent animation tests passed")
