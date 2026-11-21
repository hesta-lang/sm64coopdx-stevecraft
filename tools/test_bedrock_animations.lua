-- Headless tests: lua5.4 tools/test_bedrock_animations.lua
local registered, applied, hook_callback = {}, {}, nil
ANIM_FLAG_6 = 0x40
ACT_FLAG_SWIMMING_OR_FLYING = 1 << 28
ACT_FLAG_WATER_OR_TEXT = 1 << 29
HOOK_MARIO_UPDATE = "HOOK_MARIO_UPDATE_TEST"

smlua_anim_util_register_animation = function(name, flags, y_divisor, start_frame,
        loop_start, loop_end, values, indices)
    assert(type(name) == "string" and name ~= "")
    assert(type(flags) == "number")
    assert(type(values) == "table" and #values > 0)
    assert(type(indices) == "table" and #indices == 126, name .. " must have 63 channels")
    assert(loop_end > 0)
    assert(registered[name] == nil, "duplicate clip " .. name)
    for i = 1, #indices, 2 do
        local count, offset = indices[i], indices[i + 1]
        assert(type(count) == "number" and count >= 1)
        assert(type(offset) == "number" and offset >= 0)
        assert(offset + count <= #values, name .. " index points outside the value array")
    end
    for _, angle in ipairs(values) do
        assert(type(angle) == "number" and angle >= 0 and angle <= 65535)
    end
    registered[name] = { flags = flags, frames = loop_end, indices = indices }
end

smlua_anim_util_set_animation = function(obj, name)
    local info = obj.header.gfx.animInfo
    info.curAnimName = name
    applied[#applied + 1] = name
end

hook_event = function(event, callback)
    assert(event == HOOK_MARIO_UPDATE)
    hook_callback = callback
end

SteveCraft = { character = { ready = true, modelId = 123 } }
dofile(arg[1] or "animations.lua")

local a = assert(SteveCraft.animations)
assert(hook_callback ~= nil)
assert(a.customClipsReady == true)
assert(a.clipCount == 19)
assert(a.mappedAnimationCount == 27)
assert(#a.mappedMarioAnimationIds == 27)

local expected = {
    [0x47]="steve_bedrock_ride", [0x6D]="steve_bedrock_ride",
    [0x48]="steve_bedrock_walk", [0xBA]="steve_bedrock_walk",
    [0x65]="steve_bedrock_attack", [0x66]="steve_bedrock_attack", [0x67]="steve_bedrock_attack",
    [0x68]="steve_bedrock_attack_left", [0x69]="steve_bedrock_attack_fast",
    [0x6A]="steve_bedrock_attack_fast_left", [0x72]="steve_bedrock_run",
    [0x96]="steve_bedrock_stop_crouch", [0x97]="steve_bedrock_start_crouch",
    [0x98]="steve_bedrock_crouch", [0xC5]="steve_bedrock_idle",
}
local count = 0
for id, clip in pairs(expected) do
    count = count + 1
    assert(a.marioAnimationBindings[id] == clip, string.format("bad binding for 0x%X", id))
    local m = {
        playerIndex = 0,
        action = 0,
        marioObj = { header = { gfx = { animInfo = { animID = id } } } },
    }
    hook_callback(m)
    assert(m.marioObj.header.gfx.animInfo.curAnimName == clip,
        string.format("failed to apply 0x%X", id))
end

local function test_gated(id, action, sleeping, crawling, expected_clip)
    SteveCraft.sleeping = sleeping
    SteveCraft.crawling = crawling
    local m = {
        playerIndex = 0,
        action = action,
        marioObj = { header = { gfx = { animInfo = { animID = id } } } },
    }
    hook_callback(m)
    assert(m.marioObj.header.gfx.animInfo.curAnimName == expected_clip,
        string.format("unexpected clip for 0x%X: got %s expected %s",
            id, tostring(m.marioObj.header.gfx.animInfo.curAnimName), tostring(expected_clip)))
end

-- False swim IDs and flight-only actions must not rotate the body on dry land.
test_gated(0xAA, 0, false, false, nil)
test_gated(0xAA, ACT_FLAG_SWIMMING_OR_FLYING, false, false, nil)
-- A real SM64 water action enables the Bedrock swimming root pose.
test_gated(0xAA, ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_WATER_OR_TEXT,
    false, false, "steve_bedrock_swim")
-- Crawl and sleep require explicit SteveCraft state activation.
test_gated(0x99, 0, false, false, nil)
test_gated(0x99, 0, false, true, "steve_bedrock_crawl")
test_gated(0x87, 0, false, false, nil)
test_gated(0x87, 0, true, false, "steve_bedrock_sleep_lying")

assert(count == 15, "expected 15 always-safe animation bindings")
assert(#applied == 18, "expected 15 normal clips and 3 explicitly enabled root poses")
for name, clip in pairs(registered) do
    assert(#clip.indices == 126 and clip.frames > 0, name .. " malformed")
end
assert(registered.steve_bedrock_start_crouch.flags & 1 == 1)
assert(registered.steve_bedrock_stop_crawl.flags & 1 == 1)
print("PASS: unsafe root poses are gated by water/crawl/sleep states")
print("PASS: 19 Bedrock clips; 27 Mario-ID bindings; 63 channels per clip.")
