-- SteveCraft 64 - Minecraft Java 1.21.11 humanoid animation port
--
-- The animation curves are adapted from the decompiled Java source:
-- HumanoidModel.setupAnim() and AnimationUtils.bobModelPart().
-- Runtime clips are baked into SM64CoopDX's native Animation format.
--
-- SM64's compatible player actor has 20 animated GeoLayout nodes. The first
-- three animation channels are the engine's root-translation slots; they are
-- kept at zero and skipped with ANIM_FLAG_6. The remaining 60 channels are
-- XYZ rotations for the 20 nodes in the exact SM64 player order.
--
-- Minecraft model axes differ from the actor's local axes:
-- MC xRot (limb pitch) -> SM64 local Y rotation;
-- MC yRot (yaw)        -> SM64 local X rotation;
-- MC zRot (roll)       -> SM64 local Z rotation.

SteveCraft = SteveCraft or {}
SteveCraft.animations = SteveCraft.animations or {}

local animations = SteveCraft.animations
local PI = math.pi
local TAU = PI * 2.0
local ROTATION_ONLY = ANIM_FLAG_6 or 0x40
local REGISTER = smlua_anim_util_register_animation
local SET_ANIMATION = smlua_anim_util_set_animation

animations.source = "Minecraft Java 1.21.11 HumanoidModel.setupAnim + AnimationUtils.bobModelPart"
animations.skeleton = "SM64CoopDX 20 animated nodes / 63 channels"
animations.customClipsReady = false
animations.formulasReady = true
animations.registeredClips = {}

local PARTS = {
    "butt",
    "torso",
    "head",
    "upperLeft",
    "leftArm",
    "leftForearm",
    "leftHand",
    "upperRight",
    "rightArm",
    "rightForearm",
    "rightHand",
    "lowerLeft",
    "leftThigh",
    "leftLeg",
    "leftFoot",
    "lowerRight",
    "rightThigh",
    "rightLeg",
    "rightFoot",
}

local function new_part()
    return { xRot = 0.0, yRot = 0.0, zRot = 0.0 }
end

local function new_pose()
    local pose = {}
    for _, name in ipairs(PARTS) do
        pose[name] = new_part()
    end
    return pose
end

local function safe_speed(value)
    if value == nil or value < 0.0001 then
        return 1.0
    end
    return value
end

local function to_u16_angle(radians)
    local value = math.floor((radians or 0.0) * 32768.0 / PI + 0.5)
    return value % 65536
end

function animations.radians_to_sm64_angle(radians)
    return to_u16_angle(radians)
end

-- Exact HumanoidModel walk equations. The generated gameplay clips use a
-- fixed 0.60 walk amount and 1.00 run amount because SM64 exposes Mario's
-- animation ID, not Minecraft's walkAnimationSpeed / walkAnimationPos pair.
function animations.minecraft_walk_pose(walk_position, walk_speed, speed_value)
    local speed = math.max(0.0, math.min(walk_speed or 0.0, 1.0))
    local divisor = safe_speed(speed_value or 1.0)
    local phase = (walk_position or 0.0) * 0.6662
    local arm_amplitude = 2.0 * speed * 0.5 / divisor
    local leg_amplitude = 1.4 * speed / divisor
    return {
        rightArmPitch = math.cos(phase + PI) * arm_amplitude,
        leftArmPitch = math.cos(phase) * arm_amplitude,
        rightLegPitch = math.cos(phase) * leg_amplitude,
        leftLegPitch = math.cos(phase + PI) * leg_amplitude,
        rightLegYaw = 0.005,
        leftLegYaw = -0.005,
        rightLegRoll = 0.005,
        leftLegRoll = -0.005,
    }
end

-- Exact crouch rotations from HumanoidModel.setupAnim(). Minecraft also moves
-- the head, torso, arms and legs by small local offsets; those translations
-- are intentionally not baked because this SM64 actor's local unit/axis
-- conversion has not yet been verified in-game.
function animations.minecraft_crouch_pose()
    return {
        bodyPitch = 0.5,
        rightArmPitchOffset = 0.4,
        leftArmPitchOffset = 0.4,
        legOffsetZ = 4.0,
        headOffsetY = 4.2,
        bodyOffsetY = 3.2,
        armOffsetY = 3.2,
    }
end

local function apply_arm_bob(pose, age_in_ticks)
    -- AnimationUtils.bobModelPart(modelPart, ageInTicks, scale)
    local pitch = math.sin(age_in_ticks * 0.067) * 0.05
    local roll = math.cos(age_in_ticks * 0.09) * 0.05 + 0.05
    pose.rightArm.xRot = pose.rightArm.xRot + pitch
    pose.rightArm.zRot = pose.rightArm.zRot + roll
    pose.leftArm.xRot = pose.leftArm.xRot - pitch
    pose.leftArm.zRot = pose.leftArm.zRot - roll
end

local function make_idle_pose(frame)
    local pose = new_pose()
    local age_in_ticks = frame * (2.0 / 3.0) -- 30 Hz SM64 -> 20 Hz Minecraft
    apply_arm_bob(pose, age_in_ticks)
    pose.rightLeg.yRot = 0.005
    pose.leftLeg.yRot = -0.005
    pose.rightLeg.zRot = 0.005
    pose.leftLeg.zRot = -0.005
    return pose
end

local function make_walk_pose(frame, speed, cycle_frames, crouched)
    local pose = new_pose()
    local phase = TAU * (frame % cycle_frames) / cycle_frames
    local animation_position = phase / 0.6662
    local values = animations.minecraft_walk_pose(animation_position, speed, 1.0)

    pose.rightArm.xRot = values.rightArmPitch
    pose.leftArm.xRot = values.leftArmPitch
    pose.rightLeg.xRot = values.rightLegPitch
    pose.leftLeg.xRot = values.leftLegPitch
    pose.rightLeg.yRot = values.rightLegYaw
    pose.leftLeg.yRot = values.leftLegYaw
    pose.rightLeg.zRot = values.rightLegRoll
    pose.leftLeg.zRot = values.leftLegRoll

    if crouched then
        pose.torso.xRot = 0.5
        pose.rightArm.xRot = pose.rightArm.xRot + 0.4
        pose.leftArm.xRot = pose.leftArm.xRot + 0.4
    end
    return pose
end

local function make_crouch_pose(frame)
    local pose = new_pose()
    pose.torso.xRot = 0.5
    pose.rightArm.xRot = 0.4
    pose.leftArm.xRot = 0.4
    apply_arm_bob(pose, frame * (2.0 / 3.0))
    pose.rightLeg.yRot = 0.005
    pose.leftLeg.yRot = -0.005
    pose.rightLeg.zRot = 0.005
    pose.leftLeg.zRot = -0.005
    return pose
end

local function quadratic_arm_update(x)
    -- Exact HumanoidModel.quadraticArmUpdate(float x) from 1.21.11.
    return -65.0 * x + x * x
end

local function make_swim_pose(frame)
    local pose = new_pose()
    local animation_position = frame * (2.0 / 3.0)
    local swim_position = animation_position % 26.0
    local left_x, right_x = 0.0, 0.0
    local left_y, right_y = PI, PI
    local left_z, right_z

    if swim_position < 14.0 then
        local ratio = quadratic_arm_update(swim_position) / quadratic_arm_update(14.0)
        left_z = PI + 1.8707964 * ratio
        right_z = PI - 1.8707964 * ratio
    elseif swim_position < 22.0 then
        local t = (swim_position - 14.0) / 8.0
        left_x = (PI / 2.0) * t
        right_x = (PI / 2.0) * t
        left_z = 5.012389 - 1.8707964 * t
        right_z = 1.2707963 + 1.8707964 * t
    else
        local t = (swim_position - 22.0) / 4.0
        left_x = (PI / 2.0) - (PI / 2.0) * t
        right_x = (PI / 2.0) - (PI / 2.0) * t
        left_z, right_z = PI, PI
    end

    pose.head.xRot = -PI / 4.0
    pose.leftArm.xRot = left_x
    pose.rightArm.xRot = right_x
    pose.leftArm.yRot = left_y
    pose.rightArm.yRot = right_y
    pose.leftArm.zRot = left_z
    pose.rightArm.zRot = right_z

    pose.leftLeg.xRot = 0.3 * math.cos(animation_position * 0.33333334 + PI)
    pose.rightLeg.xRot = 0.3 * math.cos(animation_position * 0.33333334)
    return pose
end

local function append_constant(values, indices, sample)
    indices[#indices + 1] = 1
    indices[#indices + 1] = #values
    values[#values + 1] = to_u16_angle(sample)
end

local function append_channel(values, indices, poses, part_name, engine_axis)
    local samples = {}
    local first = 0.0
    local varying = false

    for frame = 1, #poses do
        local part = poses[frame][part_name]
        local value = 0.0
        if part ~= nil then
            if engine_axis == 0 then
                value = part.yRot or 0.0 -- MC yaw -> actor local X
            elseif engine_axis == 1 then
                value = part.xRot or 0.0 -- MC pitch -> actor local Y
            else
                value = part.zRot or 0.0 -- MC roll -> actor local Z
            end
        end
        samples[frame] = value
        if frame == 1 then
            first = value
        elseif math.abs(value - first) > 0.000001 then
            varying = true
        end
    end

    if not varying then
        append_constant(values, indices, first)
        return
    end

    indices[#indices + 1] = #samples
    indices[#indices + 1] = #values
    for frame = 1, #samples do
        values[#values + 1] = to_u16_angle(samples[frame])
    end
end

local function register_clip(name, frame_count, pose_function)
    local poses = {}
    for frame = 0, frame_count - 1 do
        poses[#poses + 1] = pose_function(frame)
    end

    local values, indices = {}, {}

    -- ANIM_FLAG_6 tells the renderer to skip the three root-translation
    -- channels. Keep those slots present because they are part of the format.
    append_constant(values, indices, 0.0)
    append_constant(values, indices, 0.0)
    append_constant(values, indices, 0.0)

    -- Root rotation is neutral; the head's look direction is still supplied
    -- by SM64CoopDX's existing geo_mario_head_rotation callback.
    append_constant(values, indices, 0.0)
    append_constant(values, indices, 0.0)
    append_constant(values, indices, 0.0)

    for _, part_name in ipairs(PARTS) do
        for engine_axis = 0, 2 do
            append_channel(values, indices, poses, part_name, engine_axis)
        end
    end

    if #indices ~= 126 then
        error("[SteveCraft 64] Invalid animation channel count for " .. name ..
            ": expected 126 index values, got " .. #indices)
    end

    REGISTER(name, ROTATION_ONLY, 0, 0, 0, frame_count, values, indices)
    animations.registeredClips[name] = {
        frames = frame_count,
        channels = #indices / 2,
        values = #values,
    }
end

if type(REGISTER) ~= "function" or type(SET_ANIMATION) ~= "function" then
    error("[SteveCraft 64] SM64CoopDX custom animation API is unavailable.")
end

if not animations.customClipsRegistered then
    -- Fourteen-second idle/crouch cycles keep the two tiny Minecraft arm-bob
    -- curves close to their source phase when the native clip loops.
    register_clip("steve_mc_idle", 420, make_idle_pose)
    register_clip("steve_mc_walk", 24, function(frame)
        return make_walk_pose(frame, 0.60, 24, false)
    end)
    register_clip("steve_mc_run", 14, function(frame)
        return make_walk_pose(frame, 1.00, 14, false)
    end)
    register_clip("steve_mc_crouch", 420, make_crouch_pose)
    register_clip("steve_mc_crouch_walk", 24, function(frame)
        return make_walk_pose(frame, 0.60, 24, true)
    end)
    register_clip("steve_mc_swim", 39, make_swim_pose)
    animations.customClipsRegistered = true
    animations.customClipsReady = true
end

local clip_by_mario_animation = {}

local function bind_clip(clip_name, ...)
    for index = 1, select("#", ...) do
        local animation_id = select(index, ...)
        if type(animation_id) == "number" then
            clip_by_mario_animation[animation_id] = clip_name
        end
    end
end

-- Minecraft has one HumanoidModel walk equation; the run clip simply uses a
-- higher walkAnimationSpeed. Normal jumps and falls do not have a separate
-- vanilla humanoid limb cycle, so they use Minecraft's neutral arm-bob pose.
bind_clip("steve_mc_idle",
    MARIO_ANIM_IDLE_HEAD_LEFT,
    MARIO_ANIM_IDLE_HEAD_RIGHT,
    MARIO_ANIM_IDLE_HEAD_CENTER,
    MARIO_ANIM_SINGLE_JUMP,
    MARIO_ANIM_DOUBLE_JUMP_RISE,
    MARIO_ANIM_DOUBLE_JUMP_FALL,
    MARIO_ANIM_GENERAL_FALL,
    MARIO_ANIM_LAND_FROM_SINGLE_JUMP,
    MARIO_ANIM_LAND_FROM_DOUBLE_JUMP,
    MARIO_ANIM_GENERAL_LAND,
    MARIO_ANIM_TRIPLE_JUMP,
    MARIO_ANIM_TRIPLE_JUMP_FLY)

bind_clip("steve_mc_walk", MARIO_ANIM_WALKING)
bind_clip("steve_mc_run", MARIO_ANIM_RUNNING, MARIO_ANIM_RUNNING_UNUSED)
bind_clip("steve_mc_crouch", MARIO_ANIM_CROUCHING)
bind_clip("steve_mc_crouch_walk", MARIO_ANIM_CRAWLING)
bind_clip("steve_mc_swim",
    MARIO_ANIM_SWIM_PART1,
    MARIO_ANIM_SWIM_PART2,
    MARIO_ANIM_FLUTTERKICK,
    MARIO_ANIM_WATER_ACTION_END,
    MARIO_ANIM_WATER_IDLE,
    MARIO_ANIM_DIVE)

local active_clip_by_player = {}
local previous_base_animation_by_player = {}

local function is_steve_player(m)
    local character = SteveCraft.character
    if character == nil or not character.ready or character.modelId == nil then
        return false
    end
    if gPlayerSyncTable == nil or m.playerIndex == nil then
        return false
    end
    local sync = gPlayerSyncTable[m.playerIndex]
    return sync ~= nil and sync.modelId == character.modelId
end

local function apply_minecraft_animation(m)
    if m == nil or m.marioObj == nil or not is_steve_player(m) then
        return
    end

    local player_index = m.playerIndex or 0
    local info = m.marioObj.header.gfx.animInfo
    if info == nil then
        return
    end

    local base_animation_id = info.animID
    local clip_name = clip_by_mario_animation[base_animation_id]

    if clip_name == nil then
        active_clip_by_player[player_index] = nil
        previous_base_animation_by_player[player_index] = base_animation_id
        return
    end

    -- Re-apply only when the game changes its native animation state. This
    -- avoids resetting the custom cycle to frame zero on every Mario update.
    if active_clip_by_player[player_index] ~= clip_name
        or previous_base_animation_by_player[player_index] ~= base_animation_id then
        SET_ANIMATION(m.marioObj, clip_name)
        active_clip_by_player[player_index] = clip_name
    end

    info.animAccel = 0x10000
    previous_base_animation_by_player[player_index] = base_animation_id
end

hook_event(HOOK_MARIO_UPDATE, apply_minecraft_animation)
