-- Headless tests: lua5.4 tools/test_bedrock_animations.lua
local registered, applied, hook_callback = {}, {}, nil
ANIM_FLAG_6 = 0x40
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
    [0x81]="steve_bedrock_sleep", [0x85]="steve_bedrock_sleep",
    [0x86]="steve_bedrock_sleep_lying", [0x87]="steve_bedrock_sleep_lying",
    [0x96]="steve_bedrock_stop_crouch", [0x97]="steve_bedrock_start_crouch",
    [0x98]="steve_bedrock_crouch", [0x99]="steve_bedrock_crawl",
    [0x9A]="steve_bedrock_stop_crawl", [0x9B]="steve_bedrock_start_crawl",
    [0xAA]="steve_bedrock_swim", [0xAB]="steve_bedrock_swim",
    [0xAC]="steve_bedrock_swim_legs", [0xAD]="steve_bedrock_swim",
    [0xB2]="steve_bedrock_swim_idle", [0xC5]="steve_bedrock_idle",
}
local count = 0
for id, clip in pairs(expected) do
    count = count + 1
    assert(a.marioAnimationBindings[id] == clip, string.format("bad binding for 0x%X", id))
    local m = {
        playerIndex = 0,
        marioObj = { header = { gfx = { animInfo = { animID = id } } } },
    }
    hook_callback(m)
    assert(m.marioObj.header.gfx.animInfo.curAnimName == clip,
        string.format("failed to apply 0x%X", id))
end
assert(count == 27 and #applied == 27)
for name, clip in pairs(registered) do
    assert(#clip.indices == 126 and clip.frames > 0, name .. " malformed")
end
assert(registered.steve_bedrock_start_crouch.flags & 1 == 1)
assert(registered.steve_bedrock_stop_crawl.flags & 1 == 1)
print("PASS: 19 Bedrock clips; 27 Mario-ID bindings; 63 channels per clip.")
