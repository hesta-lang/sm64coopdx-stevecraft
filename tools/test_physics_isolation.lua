-- Integration test for SteveCraft's local Mario-action and geometry isolation.
package.path = "./?.lua;" .. package.path

ACT_GROUP_CUTSCENE = 0x100
ACT_GROUP_MASK = 0x1C0
ACT_GROUP_STATIONARY = 0x000
ACT_GROUP_MOVING = 0x040
ACT_FLAG_STATIONARY = 0x200
ACT_FLAG_INTANGIBLE = 0x1000
ACT_FLAG_INVULNERABLE = 0x20000
ACT_FLAG_ALLOW_FIRST_PERSON = 0x04000000
ACT_FLAG_PAUSE_EXIT = 0x08000000
ACT_FLAG_CUSTOM_ACTION = 0x40000000
ACT_FLAG_CUSTOM_ACTION = 0x40000000
ACT_FLAG_ALLOW_FIRST_PERSON = 0x04000000
ACT_FLAG_PAUSE_EXIT = 0x08000000
ACT_FLAG_WATER_OR_TEXT = 0x20000000
ACT_FLAG_AIR = 0x800
ACT_FLAG_SWIMMING = 0x2000
ACT_UNINITIALIZED = 0
ACT_READING_SIGN = 0x1308
ACT_WAITING_FOR_DIALOG = 0x130A
ACT_UNKNOWN_0002020E = 0x0002020E
ACT_IDLE = 0x0C400201
ACT_WALKING = 0x04000440

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

INPUT_A_PRESSED = 0x1
INPUT_A_DOWN = 0x2
INPUT_Z_DOWN = 0x4
INPUT_OFF_FLOOR = 0x8
INPUT_IN_WATER = 0x10
INPUT_IN_POISON_GAS = 0x20
INPUT_ABOVE_SLIDE = 0x40
INPUT_SQUISHED = 0x80

HAZARD_TYPE_QUICKSAND = 1
HAZARD_TYPE_LAVA_FLOOR = 2
HAZARD_TYPE_LAVA_WALL = 3
HAZARD_TYPE_HORIZONTAL_WIND = 4
HAZARD_TYPE_VERTICAL_WIND = 5

CHAR_ANIM_IDLE_HEAD_CENTER = 197
CHAR_ANIM_WALKING = 72
CHAR_ANIM_RUNNING = 114
CHAR_ANIM_SINGLE_JUMP = 77
CHAR_ANIM_GENERAL_FALL = 86

HOOK_BEFORE_SET_MARIO_ACTION = "before_set_action"
HOOK_ON_SET_MARIO_ACTION = "on_set_action"
HOOK_BEFORE_MARIO_UPDATE = "before_mario_update"
HOOK_MARIO_OVERRIDE_GEOMETRY_INPUTS = "override_geometry"
HOOK_ALLOW_FORCE_WATER_ACTION = "allow_force_water"
HOOK_BEFORE_PHYS_STEP = "before_physics_step"
HOOK_ON_LEVEL_INIT = "level_init"
HOOK_ON_WARP = "warp"
HOOK_ON_EXIT = "exit"

local events = {}
local actionId
local actionHooks
local actionApplied = 0
local nativeGroundSteps = 0
local lastAnimation = nil

function hook_event(name, callback)
    events[name] = callback
end

function hook_mario_action(id, callbacks)
    actionId = id
    actionHooks = callbacks
end

function set_mario_action(m, action, arg)
    local replacement = events[HOOK_BEFORE_SET_MARIO_ACTION](m, action, arg)
    m.action = replacement or action
    m.actionArg = arg or 0
    events[HOOK_ON_SET_MARIO_ACTION](m)
    actionApplied = actionApplied + 1
    return 0
end

function set_character_animation(m, animation)
    lastAnimation = animation
end

local floorSurface = { type = 0, normal = { x = 0, y = 1, z = 0 } }
function find_floor()
    return 0, floorSurface
end
function find_ceil()
    return 11000, nil
end
function find_water_level()
    return -11000
end
function find_poison_gas_level()
    return -11000
end

local gfxPos = { x = 0, y = 0, z = 0 }
local mario = {
    playerIndex = 0,
    action = ACT_WALKING,
    actionArg = 0,
    input = 0,
    intendedMag = 0,
    intendedYaw = 0,
    pos = { x = 0, y = 0, z = 0 },
    vel = { x = 0, y = 0, z = 0 },
    faceAngle = { x = 0, y = 0, z = 0 },
    wallNormal = { x = 0, y = 0, z = 0 },
    marioBodyState = { modelState = 0 },
    marioObj = {
        hitboxRadius = 27,
        hitboxHeight = 160,
        header = { gfx = { pos = gfxPos, angle = { x = 0, y = 0, z = 0 } } },
    },
}

SteveCraft = {
    character = { ready = true, modelId = 123 },
    proxy = { owns_mario_state = function(candidate) return candidate == mario end },
    sm64Collision = {
        is_available = function() return true end,
        resolve = function(_, move)
            return { x = move.x, y = move.y, z = move.z, surfaces = 1 }
        end,
    },
}

-- Load the same modules and hooks used by the Android mod.
dofile("physics.lua")

local controlled = 0x3F | ACT_FLAG_STATIONARY | ACT_FLAG_CUSTOM_ACTION
    | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT
assert(actionId == controlled, "custom Steve stationary action was not registered")
assert((actionId & ACT_GROUP_MASK) == ACT_GROUP_STATIONARY, "Steve action must remain in stationary group")
assert((actionId & (ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE)) == 0,
    "Steve action must remain interactable and speakable")
assert(type(actionHooks.every_frame) == "function", "every-frame custom action callback missing")
assert(events[HOOK_MARIO_OVERRIDE_GEOMETRY_INPUTS] ~= nil, "native geometry override hook not installed")
assert(events[HOOK_ALLOW_HAZARD_SURFACE] ~= nil, "native hazard-surface override not installed")

-- Mirror mario_ready_to_speak(): stationary/moving groups can start NPC
-- dialogs when neither invulnerable nor riding a shell.
local function dialog_ready(action)
    local group = action & ACT_GROUP_MASK
    return (action == ACT_WAITING_FOR_DIALOG or group == ACT_GROUP_STATIONARY
        or group == ACT_GROUP_MOVING)
        and (action & ACT_FLAG_INVULNERABLE) == 0
end
assert(dialog_ready(actionId), "Steve custom action must permit NPC dialogue initiation")

local remapped = events[HOOK_BEFORE_SET_MARIO_ACTION](mario, ACT_WALKING, 0)
assert(remapped == controlled, "native walking action was not redirected")
assert(events[HOOK_BEFORE_SET_MARIO_ACTION](mario, ACT_READING_SIGN, 0) == nil,
    "reading-sign action should remain available")

-- Before the normal update, force the player into the Steve-only action.
events[HOOK_BEFORE_MARIO_UPDATE](mario)
assert(mario.action == controlled, "Mario locomotion action was not replaced")

-- The geometry hook must return false and repopulate contacts without changing
-- the player's position. This is the exact point where Mario's native wall
-- correction and floor/ceiling recalculation would otherwise execute.
local x, y, z = mario.pos.x, mario.pos.y, mario.pos.z
local allowNativeGeometry = events[HOOK_MARIO_OVERRIDE_GEOMETRY_INPUTS](mario)
assert(allowNativeGeometry == false, "native Mario geometry prepass was not cancelled")
assert(events[HOOK_ALLOW_HAZARD_SURFACE](mario, HAZARD_TYPE_QUICKSAND) == false,
    "Mario quicksand physics must be disabled")
assert(events[HOOK_ALLOW_HAZARD_SURFACE](mario, HAZARD_TYPE_LAVA_FLOOR) == false,
    "Mario lava-floor boost must be disabled")
assert(events[HOOK_ALLOW_HAZARD_SURFACE](mario, HAZARD_TYPE_VERTICAL_WIND) == false,
    "Mario vertical-wind handling must be disabled")
assert(mario.floor == floorSurface and mario.floorHeight == 0, "Lua contact refresh failed")
assert(mario.pos.x == x and mario.pos.y == y and mario.pos.z == z,
    "geometry callback moved MarioState directly")

local stepResult = nil
function perform_ground_step(m)
    local result = events[HOOK_BEFORE_PHYS_STEP](m, STEP_TYPE_GROUND, 0)
    if type(result) == "number" then
        stepResult = result
        return result
    end
    nativeGroundSteps = nativeGroundSteps + 1
    return GROUND_STEP_NONE
end

-- The registered Lua action must invoke the intercepted step and the native
-- movement resolver must never be reached.
local cancelled = actionHooks.every_frame(mario)
assert(cancelled == false, "custom action should suppress native action logic without looping")
assert(stepResult == GROUND_STEP_NONE, "Steve movement did not return its own ground step")
assert(nativeGroundSteps == 0, "native Mario ground movement executed")
assert(lastAnimation == CHAR_ANIM_IDLE_HEAD_CENTER, "Steve idle animation was not selected")
assert(gfxPos.x == mario.pos.x and gfxPos.y == mario.pos.y and gfxPos.z == mario.pos.z,
    "Steve/Mario bridge graphics transform was not synchronized")

print("SteveCraft native Mario isolation integration tests passed")
