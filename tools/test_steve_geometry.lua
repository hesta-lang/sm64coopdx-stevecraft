-- Tests for SteveCraft's native-geometry replacement.
package.path = "./?.lua;" .. package.path

INPUT_OFF_FLOOR = 0x0001
INPUT_IN_WATER = 0x0002
INPUT_IN_POISON_GAS = 0x0004
INPUT_ABOVE_SLIDE = 0x0008
INPUT_SQUISHED = 0x0010

local floorSurface = {
    type = 0,
    normal = { x = 0, y = 1, z = 0 },
}
local ceilSurface = { type = 0 }

local floorHeight = 0
local waterLevel = -11000
local gasLevel = -11000

function find_floor(x, y, z)
    return floorHeight, floorSurface
end

function find_ceil(x, y, z)
    return 11000, nil
end

function find_water_level(x, z)
    return waterLevel
end

function find_poison_gas_level(x, z)
    return gasLevel
end

function get_water_surface_pseudo_floor()
    return { type = 0, normal = { x = 0, y = 1, z = 0 } }
end

local Geometry = require("steve_geometry")
local m = {
    pos = { x = 10, y = 0, z = 20 },
    input = INPUT_ABOVE_SLIDE | INPUT_SQUISHED,
    wallNormal = { x = 1, y = 0, z = 0 },
    floor = nil,
    ceil = nil,
    wall = { type = 0 },
}
local state = {}

assert(Geometry.update(m, state, {
    unitsPerBlock = 88.8888888889,
    height = 160,
    stepHeight = 53.3333333333,
    groundTolerance = 6,
}))
assert(state.onGround == true, "surface at the feet should mark Steve grounded")
assert(state.inWater == false, "default water level should mean dry ground")
assert(m.floor == floorSurface and m.floorHeight == 0, "floor reference/height was not refreshed")
assert(m.ceilHeight == 11000, "missing ceiling should use the engine's no-ceiling sentinel")
assert(m.wall == nil, "Mario's native wall state should be cleared")
assert(m.wallNormal.x == 0 and m.wallNormal.y == 0 and m.wallNormal.z == 0)
assert((m.input & INPUT_ABOVE_SLIDE) == 0, "Mario slide flag must be cleared")
assert((m.input & INPUT_SQUISHED) == 0, "Mario squish flag must be cleared")
assert((m.input & INPUT_OFF_FLOOR) == 0, "grounded state must clear OFF_FLOOR")
assert(m.pos.x == 10 and m.pos.y == 0 and m.pos.z == 20, "geometry refresh must never correct player position")

m.pos.y = 12
waterLevel = 20
gasLevel = 150
assert(Geometry.update(m, state, { height = 160, stepHeight = 50, groundTolerance = 6 }))
assert(state.onGround == false and state.inWater == true)
assert((m.input & INPUT_OFF_FLOOR) ~= 0, "airborne state must set OFF_FLOOR")
assert((m.input & INPUT_IN_WATER) ~= 0, "water query must set IN_WATER")
assert((m.input & INPUT_IN_POISON_GAS) ~= 0, "gas query must set IN_POISON_GAS")
assert(m.pos.y == 12, "native geometry replacement must not change y")

-- A missing floor uses a cached surface only to keep the host Mario action
-- dispatcher alive; the controller still receives onGround=false.
local cachedFloor = state.lastFloorSurface
floorHeight = nil
function find_floor()
    return -11000, nil
end
assert(Geometry.update(m, state, { height = 160, stepHeight = 50 }))
assert(state.onGround == false)
assert(m.floor == cachedFloor or m.floor ~= nil, "cached/pseudo floor should keep the host state valid")
assert(m.pos.y == 12, "void sampling must not snap the player's position")

print("SteveCraft geometry replacement tests passed")
