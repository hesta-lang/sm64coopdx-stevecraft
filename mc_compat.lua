-- SteveCraft compatibility helpers for Java code translated to Lua.
-- This is deliberately a small API bridge, not a Minecraft runtime.
local MC = {}
MC.Mth = {}

function MC.Mth.clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function MC.Mth.lerp(delta, start_value, end_value)
    return start_value + delta * (end_value - start_value)
end

function MC.Mth.sign(value)
    if value < 0 then return -1 end
    if value > 0 then return 1 end
    return 0
end

function MC.Mth.wrapDegrees(value)
    value = value % 360
    if value >= 180 then value = value - 360 end
    if value < -180 then value = value + 360 end
    return value
end

function MC.Mth.fastFloor(value)
    local integer = math.floor(value)
    return integer
end

function MC.Mth.absMax(x, y)
    return math.max(math.abs(x), math.abs(y))
end

return MC
