-- SteveCraft compatibility helpers for Java code translated to Lua.
-- This is deliberately a small API bridge, not a Minecraft runtime.
-- Functions below are ported against the Minecraft Java 26.3 Mth API.
local MC = {}
MC.Mth = {}

-- Mirrors Math.min(Math.max(value, min), max), including min > max.
function MC.Mth.clamp(value, low, high)
    return math.min(math.max(value, low), high)
end

function MC.Mth.lerp(delta, start_value, end_value)
    return start_value + delta * (end_value - start_value)
end

function MC.Mth.sign(value)
    if value == 0 then return 0 end
    if value > 0 then return 1 end
    return -1
end

function MC.Mth.wrapDegrees(value)
    value = value % 360
    if value >= 180 then value = value - 360 end
    if value < -180 then value = value + 360 end
    return value
end

function MC.Mth.fastFloor(value)
    return math.floor(value)
end

function MC.Mth.absMax(x, y)
    return math.max(math.abs(x), math.abs(y))
end

function MC.Mth.degreesDifference(from_angle, to_angle)
    return MC.Mth.wrapDegrees(to_angle - from_angle)
end

function MC.Mth.degreesDifferenceAbs(angle_a, angle_b)
    return math.abs(MC.Mth.degreesDifference(angle_a, angle_b))
end

function MC.Mth.rotateIfNecessary(base_angle, target_angle, max_angle_diff)
    local delta = MC.Mth.degreesDifference(base_angle, target_angle)
    local clamped = MC.Mth.clamp(delta, -max_angle_diff, max_angle_diff)
    return target_angle - clamped
end

function MC.Mth.approach(current, target, increment)
    increment = math.abs(increment)
    if current < target then
        return MC.Mth.clamp(current + increment, current, target)
    end
    return MC.Mth.clamp(current - increment, target, current)
end

function MC.Mth.approachDegrees(current, target, increment)
    local difference = MC.Mth.degreesDifference(current, target)
    return MC.Mth.approach(current, current + difference, increment)
end

function MC.Mth.positiveModulo(input, mod)
    return (input % mod + mod) % mod
end

function MC.Mth.frac(value)
    return value - math.floor(value)
end

function MC.Mth.square(value)
    return value * value
end

function MC.Mth.cube(value)
    return value * value * value
end

function MC.Mth.equal(a, b)
    return math.abs(b - a) < 1.0E-5
end

function MC.Mth.clampedLerp(factor, minimum, maximum)
    if factor < 0 then return minimum end
    if factor > 1 then return maximum end
    return MC.Mth.lerp(factor, minimum, maximum)
end

return MC
