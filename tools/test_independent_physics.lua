package.path = "./?.lua;" .. package.path

STEP_TYPE_GROUND = 1
STEP_TYPE_AIR = 2
STEP_TYPE_WATER = 3
GROUND_STEP_NONE = 0
GROUND_STEP_LEFT_GROUND = 1
AIR_STEP_NONE = 0
AIR_STEP_LANDED = 1
WATER_STEP_NONE = 0
WATER_STEP_HIT_FLOOR = 1
WATER_STEP_HIT_CEILING = 2

local floorSurface = { type = 0 }
local ceilingSurface = { type = 0 }
local floorHeight = 0
local ceilingHeight = 100
local clipX = nil

function find_floor()
    if floorHeight == nil then return -11000, nil end
    return floorHeight, floorSurface
end

function find_ceil()
    if ceilingHeight == nil then return 11000, nil end
    return ceilingHeight, ceilingSurface
end

SteveCraft = {
    sm64Collision = {
        is_available = function() return true end,
        resolve = function(_, move)
            return {
                x = clipX ~= nil and math.min(move.x, clipX) or move.x,
                y = move.y,
                z = move.z,
                surfaces = 1,
            }
        end,
    },
}

local Independent = require("independent_physics")
assert(Independent.is_available(), "independent controller must detect the mocked collision API")

local function make_mario(x, y, z)
    return {
        pos = { x = x, y = y, z = z },
        vel = { x = 0, y = 0, z = 0 },
        faceAngle = { x = 0, y = 0, z = 0 },
        marioObj = {
            oPosX = x, oPosY = y, oPosZ = z,
            header = { gfx = { pos = { x = x, y = y, z = z }, angle = { x = 0, y = 0, z = 0 } } },
        },
    }
end

-- Ground: custom movement is committed directly to MarioState and the
-- function returns a native-compatible result to cancel perform_ground_step.
local mario = make_mario(0, 0, 0)
local state = { vx = 3, vy = 0, vz = 0 }
local result = Independent.resolve(
    mario, STEP_TYPE_GROUND, state,
    { x = 4, y = 0, z = 0 },
    { unitsPerBlock = 1, radius = 0.3, height = 1.8, stepHeight = 0.6, floorRadius = 0.25, wasOnGround = true }
)
assert(result == GROUND_STEP_NONE)
assert(math.abs(mario.pos.x - 4) < 1e-9 and mario.pos.y == 0)
assert(mario.marioObj.oPosX == 4 and mario.marioObj.header.gfx.pos.x == 4)
assert(mario.vel.x == 3, "post-friction Steve velocity must remain in MarioState")

-- Wall clipping feeds the accepted displacement back into Steve's cached speed.
clipX = 0.5
mario = make_mario(0, 0, 0)
state = { vx = 2, vy = 0, vz = 0 }
result = Independent.resolve(
    mario, STEP_TYPE_GROUND, state,
    { x = 1, y = 0, z = 0 },
    { unitsPerBlock = 1, radius = 0.3, height = 1.8, stepHeight = 0.6, floorRadius = 0.25, wasOnGround = true }
)
assert(result == GROUND_STEP_NONE and math.abs(mario.pos.x - 0.5) < 1e-9)
assert(state.vx == 0 and mario.vel.x == 0)
clipX = nil

-- A falling player is clamped to the queried floor and reports a landing.
floorHeight = 0
mario = make_mario(0, 2, 0)
state = { vx = 0, vy = -3, vz = 0 }
result = Independent.resolve(
    mario, STEP_TYPE_AIR, state,
    { x = 0, y = -3, z = 0 },
    { unitsPerBlock = 1, radius = 0.3, height = 1.8, stepHeight = 0.6, floorRadius = 0.25 }
)
assert(result == AIR_STEP_LANDED and mario.pos.y == 0 and state.vy == 0)

-- Rising into a ceiling clips the body at ceilingHeight - playerHeight.
floorHeight = nil
ceilingHeight = 1.5
mario = make_mario(0, 0, 0)
state = { vx = 0, vy = 1, vz = 0 }
result = Independent.resolve(
    mario, STEP_TYPE_AIR, state,
    { x = 0, y = 1, z = 0 },
    { unitsPerBlock = 1, radius = 0.3, height = 1, stepHeight = 0.6, floorRadius = 0.25 }
)
assert(result == AIR_STEP_NONE and math.abs(mario.pos.y - 0.5) < 1e-9)
assert(state.vy == 0)

-- Water steps use the independent resolver and return water-specific contacts.
floorHeight = 0
ceilingHeight = 100
mario = make_mario(0, 1, 0)
state = { vx = 0, vy = -1, vz = 0 }
result = Independent.resolve(
    mario, STEP_TYPE_WATER, state,
    { x = 0, y = -2, z = 0 },
    { unitsPerBlock = 1, radius = 0.3, height = 1, stepHeight = 0.6, floorRadius = 0.25 }
)
assert(result == WATER_STEP_HIT_FLOOR and mario.pos.y == 0 and state.vy == 0)

print("Independent Steve movement resolver tests passed")
