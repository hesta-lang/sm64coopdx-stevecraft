package.path = "./?.lua;" .. package.path
local P = require("minecraft_26_3_physics")

local x, z = P.modify_square_input(0.98, 0.98)
assert(math.abs(x - math.sqrt(0.5)) < 1e-6)
assert(math.abs(z - math.sqrt(0.5)) < 1e-6)
x, z = P.modify_square_input(0.5, 0)
assert(math.abs(x - 0.5) < 1e-6 and z == 0)

local wx, wz, forward = P.input_from_intent(32, 0, 0)
assert(math.abs(wx) < 1e-6 and math.abs(wz - 0.98) < 1e-6)
assert(math.abs(forward - 0.98) < 1e-6)

local sx, sz = P.input_from_intent(32, 8192, 0)
assert(math.abs(sx - math.sqrt(0.5)) < 1e-5)
assert(math.abs(sz - math.sqrt(0.5)) < 1e-5)

local sneak_x, sneak_z = P.input_from_intent(32, 0, 0, { sneaking = true })
assert(math.abs(sneak_z - 0.294) < 1e-6)
local item_x, item_z = P.input_from_intent(32, 0, 0, { usingItem = true })
assert(math.abs(item_z - 0.196) < 1e-6)

local a, d, raw, drag = P.horizontal_parameters(true, 0.6, 0.1, false)
assert(math.abs(raw - 0.1) < 1e-9)
assert(math.abs(drag - 0.546) < 1e-9)
assert(a > 0 and d > 0 and d < 1)

local ice_a, ice_d, ice_raw = P.horizontal_parameters(true, 0.98, 0.1, false)
assert(math.abs(ice_raw - (0.1 * 0.21600002 / (0.98 ^ 3))) < 1e-9)
assert(ice_raw < 0.1)
assert(ice_d > d)

local soul_a, soul_d, soul_raw = P.horizontal_parameters(true, 0.4, 0.1, false)
assert(math.abs(soul_raw - (0.1 * 0.21600002 / (0.4 ^ 3))) < 1e-9)
assert(soul_raw > 0.1 and soul_d < d)
local air_a, air_d, air_raw = P.horizontal_parameters(false, 0.6, 0.1, false)
assert(math.abs(air_raw - 0.02) < 1e-9)
assert(math.abs(air_d - (0.91 ^ (2 / 3))) < 1e-9)
assert(air_a > 0)

local post = P.apply_vertical_friction(10, 0.08, 0.98)
local gravity_frame, vertical_drag = P.tick_coefficients(0.08, 0.98)
assert(math.abs(post - ((10 - gravity_frame) * vertical_drag)) < 1e-9)

local jump = P.jump_velocity(0.42, 1.0, 0.0)
assert(math.abs(jump - (0.42 * P.WORLD_UNITS_PER_BLOCK * 2 / 3)) < 1e-9)
local jx, jz = P.sprint_jump_impulse(2, 3, 0, true)
assert(jx == 2 and jz > 3)
jx, jz = P.sprint_jump_impulse(2, 3, 0, false)
assert(jx == 2 and jz == 3)

local sprint = P.update_sprint({}, 1, true, 11)
assert(not sprint.sprinting and sprint.tapWindow > 0)
sprint.forwardWasDown = false
sprint = P.update_sprint(sprint, 1, true, 11)
assert(sprint.sprinting)
sprint = P.update_sprint(sprint, 0, true, 11)
assert(not sprint.sprinting)

print("Minecraft 26.3 physics port tests passed")
