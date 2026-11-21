-- SteveCraft 64 - Minecraft Bedrock humanoid animation port.
--
-- Source: Mojang/bedrock-samples v1.26.60.5 (player.animation.json,
-- humanoid.animation.json and player.entity.json). Curves are sampled into
-- SM64CoopDX named animations so they also work on SteveCraft's detached
-- visual proxy. proxy.lua copies the current Mario animation descriptor to
-- the visual object; the collision/physics proxy is not replaced.
--
-- The actor rig has 20 animated nodes and 63 XYZ channels. Root translation
-- stays zero so Steve remains aligned with MarioState's collision body.
-- Bedrock XYZ rotations are converted to the SM64 player model basis.

SteveCraft = SteveCraft or {}
SteveCraft.animations = SteveCraft.animations or {}

local animations = SteveCraft.animations
local PI = math.pi
local ROTATION_ONLY = ANIM_FLAG_6 or 0x40
local NO_LOOP = 1
local REGISTER = smlua_anim_util_register_animation
local SET_ANIMATION = smlua_anim_util_set_animation

animations.source = "Mojang bedrock-samples v1.26.60.5"
animations.skeleton = "SM64CoopDX player rig: 20 animated nodes / 63 XYZ channels"
animations.customClipsReady = false
animations.registeredClips = {}
animations.marioAnimationBindings = {}
animations.mappedMarioAnimationIds = {
    0x47, 0x48, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6D,
    0x72, 0x81, 0x85, 0x86, 0x87, 0x96, 0x97, 0x98, 0x99,
    0x9A, 0x9B, 0xAA, 0xAB, 0xAC, 0xAD, 0xB2, 0xBA, 0xC5,
}

local PARTS = {
    "butt", "torso", "head",
    "upperLeft", "leftArm", "leftForearm", "leftHand",
    "upperRight", "rightArm", "rightForearm", "rightHand",
    "lowerLeft", "leftThigh", "leftLeg", "leftFoot",
    "lowerRight", "rightThigh", "rightLeg", "rightFoot",
}

local function rad(d) return (d or 0.0) * PI / 180.0 end
local function sin_deg(d) return math.sin(rad(d)) end
local function cos_deg(d) return math.cos(rad(d)) end
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function part() return { xRot = 0.0, yRot = 0.0, zRot = 0.0 } end
local function pose()
    local p = { root = part() }
    for _, name in ipairs(PARTS) do p[name] = part() end
    return p
end
local function set(p, name, x, y, z)
    p[name].xRot, p[name].yRot, p[name].zRot = rad(x), rad(y), rad(z)
end

local function append_constant(values, indices, angle)
    indices[#indices + 1] = 1
    indices[#indices + 1] = #values
    values[#values + 1] = math.floor((angle or 0) * 32768 / PI + 0.5) % 65536
end

local function append_channel(values, indices, poses, part_name, axis)
    local samples, first, varying = {}, 0, false
    for frame = 1, #poses do
        local p = poses[frame][part_name]
        local value = 0
        if p then
            if axis == 0 then value = -(p.yRot or 0)
            elseif axis == 1 then value = p.xRot or 0
            else value = p.zRot or 0 end
        end
        samples[frame] = value
        if frame == 1 then first = value
        elseif math.abs(value - first) > 0.000001 then varying = true end
    end
    if not varying then append_constant(values, indices, first); return end
    indices[#indices + 1] = #samples
    indices[#indices + 1] = #values
    for _, value in ipairs(samples) do
        values[#values + 1] = math.floor(value * 32768 / PI + 0.5) % 65536
    end
end

local function register_clip(name, frames, looped, make_pose)
    local poses = {}
    for f = 0, frames - 1 do poses[#poses + 1] = make_pose(f) end
    local values, indices = {}, {}
    for _ = 1, 3 do append_constant(values, indices, 0) end
    for axis = 0, 2 do append_channel(values, indices, poses, "root", axis) end
    for _, name_part in ipairs(PARTS) do
        for axis = 0, 2 do append_channel(values, indices, poses, name_part, axis) end
    end
    if #indices ~= 126 then
        error("[SteveCraft] " .. name .. " has " .. tostring(#indices) .. " indices; expected 126")
    end
    local flags = ROTATION_ONLY
    if not looped then flags = flags | NO_LOOP end
    REGISTER(name, flags, 0, 0, 0, frames, values, indices)
    animations.registeredClips[name] = {
        frames = frames, channels = #indices / 2, values = #values, looped = looped
    }
end

local function idle(frame)
    local p = pose()
    local life_time = frame / 30
    local bob = cos_deg(life_time * 103.2 * 180 / PI) * 2.865 + 2.865
    set(p, "upperLeft", 0, 0, -bob)
    set(p, "upperRight", 0, 0, bob)
    return p
end

local function gait(frame, cycle, amplitude)
    local p = pose()
    -- Bedrock's tcos0 depends on modified_distance_moved and modified_move_speed.
    -- This baked SM64 clip uses one normalized fixed-phase sample instead.
    local tcos0 = cos_deg(frame * 360 / cycle) * 57.3
    set(p, "upperLeft", tcos0 * amplitude, 0, 0)
    set(p, "upperRight", -tcos0 * amplitude, 0, 0)
    set(p, "leftThigh", -1.4 * tcos0 * amplitude, -0.1, -0.1)
    set(p, "rightThigh", 1.4 * tcos0 * amplitude, 0.1, 0.1)
    return p
end

local function crouch()
    local p = pose()
    set(p, "root", 28, 0, 0)
    set(p, "upperLeft", -5.7, 0, 0)
    set(p, "upperRight", -5.7, 0, 0)
    set(p, "leftThigh", -28, -0.1, -0.1)
    set(p, "rightThigh", -28, 0.1, 0.1)
    return p
end

local function transition(target, reverse)
    return function(frame)
        local p, goal = pose(), target(0)
        local amount = clamp(frame / 9, 0, 1)
        if reverse then amount = 1 - amount end
        local names = { "root" }
        for _, name in ipairs(PARTS) do names[#names + 1] = name end
        for _, name in ipairs(names) do
            for _, axis in ipairs({ "xRot", "yRot", "zRot" }) do
                p[name][axis] = goal[name][axis] * amount
            end
        end
        return p
    end
end

local swim_left = {
    { 0.0, { 0, 180, 180 } }, { 0.7, { 0, 180, 287.2 } },
    { 1.1, { 90, 180, 180 } }, { 1.3, { 0, 180, 180 } },
}
local swim_right = {
    { 0.0, { 0, 180, -180 } }, { 0.7, { 0, 180, -287.2 } },
    { 1.1, { 90, 180, -180 } }, { 1.3, { 0, 180, -180 } },
}
local function keyframe(t, keys)
    if t <= keys[1][1] then return keys[1][2] end
    if t >= keys[#keys][1] then return keys[#keys][2] end
    for i = 1, #keys - 1 do
        local a, b = keys[i], keys[i + 1]
        if t >= a[1] and t <= b[1] then
            local u = (t - a[1]) / (b[1] - a[1])
            return {
                a[2][1] + (b[2][1] - a[2][1]) * u,
                a[2][2] + (b[2][2] - a[2][2]) * u,
                a[2][3] + (b[2][3] - a[2][3]) * u,
            }
        end
    end
    return keys[#keys][2]
end

local function swim(frame, mode)
    local p, t = pose(), frame / 30
    if mode ~= "legs" and mode ~= "idle" then
        local l, r = keyframe(t, swim_left), keyframe(t, swim_right)
        set(p, "upperLeft", l[1], l[2], l[3])
        set(p, "upperRight", r[1], r[2], r[3])
    end
    if mode ~= "idle" then
        local phase = t * 390
        set(p, "leftThigh", cos_deg(phase + 180) * 17.2, -0.1, -0.1)
        set(p, "rightThigh", cos_deg(phase) * 17.2, 0.1, 0.1)
    end
    set(p, "root", 90, 0, 0)
    return p
end

local function crawl(frame)
    local p, t = pose(), frame / 30
    local l, r = keyframe(t, swim_left), keyframe(t, swim_right)
    set(p, "upperLeft", l[1], l[2], l[3])
    set(p, "upperRight", r[1], r[2], r[3])
    -- Bedrock crawl leg phase is movement-distance-driven; this is a sample.
    local phase = frame * 18
    set(p, "leftThigh", cos_deg(phase + 180) * 17.2, -0.1, -0.1)
    set(p, "rightThigh", cos_deg(phase) * 17.2, 0.1, 0.1)
    set(p, "root", 90, 0, 0)
    return p
end

local function attack(frame, left_attack)
    local p, t = pose(), frame / 20
    local swing = sin_deg((1 - (1 - t) ^ 4) * 180)
    local arm_curve = swing * 1.2 + sin_deg(t * 180)
    -- player.entity.json evaluates this body-yaw expression with JS radians.
    local body_yaw = math.sin(360 * math.sqrt(t)) * 5
    local lp, rp = -arm_curve * 10, -arm_curve * 30
    local arm_yaw = math.abs(swing) > 1e-8 and (-90 * swing + 30) or 0
    if left_attack then
        lp, rp = rp, lp
        set(p, "upperLeft", lp, arm_yaw, 0)
        set(p, "upperRight", rp, 0, 0)
    else
        set(p, "upperLeft", lp, 0, 0)
        set(p, "upperRight", rp, arm_yaw, 0)
    end
    set(p, "torso", 0, body_yaw, 0)
    return p
end

local function riding()
    local p = pose()
    set(p, "upperLeft", -36, 0, 0)
    set(p, "upperRight", -36, 0, 0)
    set(p, "leftThigh", -81, -18, 0)
    set(p, "rightThigh", -81, 18, 0)
    return p
end

local function sleeping()
    local p = pose()
    set(p, "root", -90, 270, 0)
    set(p, "head", 30, 0, 0)
    return p
end

if type(REGISTER) ~= "function" or type(SET_ANIMATION) ~= "function" then
    error("[SteveCraft] SM64CoopDX custom animation API is unavailable.")
end

if not animations.customClipsRegistered then
    local clips = {
        steve_bedrock_idle = { 105, true, idle },
        steve_bedrock_walk = { 32, true, function(f) return gait(f, 32, 1) end },
        steve_bedrock_run = { 24, true, function(f) return gait(f, 24, 1) end },
        steve_bedrock_crouch = { 30, true, crouch },
        steve_bedrock_start_crouch = { 10, false, transition(crouch, false) },
        steve_bedrock_stop_crouch = { 10, false, transition(crouch, true) },
        steve_bedrock_crawl = { 39, true, crawl },
        steve_bedrock_start_crawl = { 10, false, transition(crawl, false) },
        steve_bedrock_stop_crawl = { 10, false, transition(crawl, true) },
        steve_bedrock_swim = { 39, true, function(f) return swim(f, "full") end },
        steve_bedrock_swim_legs = { 39, true, function(f) return swim(f, "legs") end },
        steve_bedrock_swim_idle = { 39, true, function(f) return swim(f, "idle") end },
        steve_bedrock_ride = { 30, true, riding },
        steve_bedrock_attack = { 21, false, function(f) return attack(f, false) end },
        steve_bedrock_attack_left = { 21, false, function(f) return attack(f, true) end },
        steve_bedrock_attack_fast = { 21, false, function(f) return attack(f, false) end },
        steve_bedrock_attack_fast_left = { 21, false, function(f) return attack(f, true) end },
        steve_bedrock_sleep = { 30, true, sleeping },
        steve_bedrock_sleep_lying = { 30, true, sleeping },
    }
    for name, d in pairs(clips) do register_clip(name, d[1], d[2], d[3]) end
    animations.customClipsRegistered = true
    animations.customClipsReady = true
    animations.clipCount = 19
end

local by_mario_id = {}
local function bind(name, ...)
    for i = 1, select("#", ...) do
        local id = select(i, ...)
        by_mario_id[id] = name
        animations.marioAnimationBindings[id] = name
    end
end

bind("steve_bedrock_ride", 0x47, 0x6D)
bind("steve_bedrock_walk", 0x48, 0xBA)
bind("steve_bedrock_attack", 0x65, 0x66, 0x67)
bind("steve_bedrock_attack_left", 0x68)
bind("steve_bedrock_attack_fast", 0x69)
bind("steve_bedrock_attack_fast_left", 0x6A)
bind("steve_bedrock_run", 0x72)
bind("steve_bedrock_sleep", 0x81, 0x85)
bind("steve_bedrock_sleep_lying", 0x86, 0x87)
bind("steve_bedrock_stop_crouch", 0x96)
bind("steve_bedrock_start_crouch", 0x97)
bind("steve_bedrock_crouch", 0x98)
bind("steve_bedrock_crawl", 0x99)
bind("steve_bedrock_stop_crawl", 0x9A)
bind("steve_bedrock_start_crawl", 0x9B)
bind("steve_bedrock_swim", 0xAA, 0xAB, 0xAD)
bind("steve_bedrock_swim_legs", 0xAC)
bind("steve_bedrock_swim_idle", 0xB2)
bind("steve_bedrock_idle", 0xC5)

animations.mappedAnimationCount = 27
animations.rootPoseGuards = { swimming = true, crawling = true, sleeping = true }
local active_clip_by_player, previous_base_by_player = {}, {}

local function is_steve_player(m)
    local character = SteveCraft.character
    if character == nil or not character.ready or character.modelId == nil then return false end
    -- Steve's proxy is local to every MarioState; no network modelId flag is needed.
    return m ~= nil and m.playerIndex ~= nil and m.marioObj ~= nil
end

local function apply_bedrock_animation(m)
    if m == nil or m.marioObj == nil or not is_steve_player(m) then return end
    local player_index = m.playerIndex or 0
    local info = m.marioObj.header.gfx.animInfo
    if info == nil then return end
    local base_id = info.animID
    local clip = by_mario_id[base_id]

    -- Root-rotating Bedrock poses must only run in their real player state.
    -- SM64's water actions expose both flags; flying sets only the first.
    -- Crawl/sleep are opt-in states because SM64 has no matching native
    -- Minecraft crawl/sleep controller.
    if clip ~= nil then
        local is_water_action = false
        if type(m.action) == "number"
            and ACT_FLAG_SWIMMING_OR_FLYING ~= nil
            and ACT_FLAG_WATER_OR_TEXT ~= nil then
            is_water_action =
                (m.action & ACT_FLAG_SWIMMING_OR_FLYING) ~= 0
                and (m.action & ACT_FLAG_WATER_OR_TEXT) ~= 0
        end
        if clip:find("swim", 1, true) and not is_water_action then
            clip = nil
        elseif clip:find("crawl", 1, true) and SteveCraft.crawling ~= true then
            clip = nil
        elseif clip:find("sleep", 1, true) and SteveCraft.sleeping ~= true then
            clip = nil
        end
    end

    if clip == nil then
        active_clip_by_player[player_index] = nil
        previous_base_by_player[player_index] = base_id
        return
    end
    if active_clip_by_player[player_index] ~= clip
        or previous_base_by_player[player_index] ~= base_id then
        SET_ANIMATION(m.marioObj, clip)
        if type(print) == "function" then
            print(string.format("[SteveCraft] Player %d animation 0x%02X -> %s",
                player_index, base_id, clip))
        end
        info.animFrame = -1
        info.prevAnimFrame = -1
        info.animFrameAccelAssist = -0x10000
        info.animAccel = 0x10000
        active_clip_by_player[player_index] = clip
    end
    info.animAccel = 0x10000
    previous_base_by_player[player_index] = base_id
end

hook_event(HOOK_MARIO_UPDATE, apply_bedrock_animation)
print("[SteveCraft] Registered 19 sampled Bedrock animation clips for the detached Steve model.")
