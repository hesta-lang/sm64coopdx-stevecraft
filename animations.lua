-- SteveCraft 64 - Minecraft HumanoidModel animation reference
--
-- The formulas below reimplement the classic HumanoidModel walk/crouch pose
-- math from Minecraft Java 1.21.11 in Lua-friendly radians.
-- The current runtime skeleton remains SM64CoopDX's 21-part Mario-compatible
-- rig; custom keyframe clips are still a separate conversion step.

SteveCraft = SteveCraft or {}
SteveCraft.animations = SteveCraft.animations or {}

local animations = SteveCraft.animations
animations.source = "Reimplemented Minecraft Java 1.21.11 HumanoidModel.setupAnim formulas"
animations.skeleton = "SM64CoopDX player armature (compatible bone order)"
animations.customClipsReady = false
animations.formulasReady = true

local PI = math.pi
local function safe_speed(value)
    if value == nil or value < 0.0001 then return 1 end
    return value
end

-- walkPosition and walkSpeed correspond to Minecraft's limbSwing and
-- limbSwingAmount. Angles are radians, before conversion to SM64 s16 angles.
function animations.minecraft_walk_pose(walkPosition, walkSpeed, speedValue)
    speedValue = safe_speed(speedValue or 1)
    walkSpeed = math.max(0, math.min(walkSpeed or 0, 1))
    local phase = (walkPosition or 0) * 0.6662
    local armAmplitude = 2.0 * walkSpeed * 0.5 / speedValue
    local legAmplitude = 1.4 * walkSpeed / speedValue
    return {
        rightArmPitch = math.cos(phase + PI) * armAmplitude,
        leftArmPitch = math.cos(phase) * armAmplitude,
        rightLegPitch = math.cos(phase) * legAmplitude,
        leftLegPitch = math.cos(phase + PI) * legAmplitude,
        rightArmRoll = 0,
        leftArmRoll = 0,
        rightLegRoll = 0,
        leftLegRoll = 0,
    }
end

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

function animations.radians_to_sm64_angle(radians)
    return math.floor((radians or 0) * 32768 / PI)
end

-- These pose functions document and validate the Minecraft motion curves.
-- They are not yet applied directly to Mario's read-only Lua bone rotation
-- fields. The next export step must bake them to SM64 Animation values/indexes
-- matching the 21-part player skeleton before enabling custom runtime clips.
