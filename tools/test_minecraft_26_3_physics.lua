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
assert(math.abs(raw - (0.1 * 0.21600002 / (0.6 ^ 3))) < 1e-9)
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

-- Regression: horizontal_step must use the effective speed returned by
-- horizontal_parameters, not an undefined global movement_speed.
local ground_move_x, ground_move_z, ground_next_x, ground_next_z,
    ground_accel, ground_drag =
    P.horizontal_step(0, 0, 1, 0.5, true, 0.6, false)
local ground_speed = 0.1 * 0.21600002 / (0.6 ^ 3)
local expected_ground_displacement = ground_speed * P.WORLD_UNITS_PER_BLOCK * P.TICK_TO_FRAME
assert(math.abs(ground_move_x - expected_ground_displacement) < 1e-8)
assert(math.abs(ground_move_z - expected_ground_displacement * 0.5) < 1e-8)
assert(ground_next_x > 0 and ground_next_z > 0)
assert(ground_next_x < ground_move_x and ground_next_z < ground_move_z)
assert(ground_accel > 0 and ground_drag > 0 and ground_drag < 1)

local air_move_x, air_move_z, air_next_x, air_next_z, air_step_accel, air_step_drag =
    P.horizontal_step(0, 0, 1, 0, false, 0.6, false)
local expected_air_displacement = 0.02 * P.WORLD_UNITS_PER_BLOCK * P.TICK_TO_FRAME
assert(math.abs(air_move_x - expected_air_displacement) < 1e-8)
assert(air_move_z == 0 and air_next_x > 0 and air_next_z == 0)
assert(air_step_accel > 0 and air_step_drag > 0 and air_step_drag < 1)

local sprint_move_x = P.horizontal_step(0, 0, 1, 0, true, 0.6, true)
assert(sprint_move_x > ground_move_x)

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

-- Water path: low efficiency starts at vanilla base speed, efficiency
-- approaches land speed, and the travel drag is applied after displacement.
local water_req_x, water_req_z, water_next_x, water_next_z, water_speed, water_slowdown =
    P.water_horizontal_step(0, 0, 0, 0.98, 0.1, 0, false, false)
assert(math.abs(water_speed - 0.02) < 1e-9)
assert(math.abs(water_slowdown - 0.8) < 1e-9)
assert(water_req_z > 0 and water_next_z > 0 and water_next_z < water_req_z)
local efficient_req_x, efficient_req_z, _, _, efficient_speed, efficient_slowdown =
    P.water_horizontal_step(0, 0, 0, 0.98, 0.1, 1, true, false)
assert(math.abs(efficient_speed - 0.1) < 1e-9)
assert(math.abs(efficient_slowdown - 0.54600006) < 1e-8)
assert(efficient_req_z > water_req_z)

local requested_water_y, post_water_y = P.water_vertical_step(0, true, false, 0.08)
assert(requested_water_y > 0 and post_water_y > 0)
local requested_sink_y, post_sink_y = P.water_vertical_step(0, false, false, 0.08)
assert(requested_sink_y == 0 and post_sink_y < 0)

-- Collision reconciliation mirrors Minecraft Entity.move() feedback.
local slide_x, slide_z = P.reconcile_horizontal_velocity(1.0, 0.4, true, 1.0, 0.0, false, false)
assert(math.abs(slide_x) < 1e-9 and math.abs(slide_z - 0.4) < 1e-9)
local clipped_x, clipped_z = P.reconcile_horizontal_velocity(1.0, 0.4, false, 0, 0, true, false)
assert(clipped_x == 0 and clipped_z == 0.4)
local ceiling_vy, hit_ceiling = P.reconcile_vertical_velocity(6.0, 4.0, 1.0, 0.5)
assert(ceiling_vy == 0 and hit_ceiling)
local clear_vy, clear_ceiling = P.reconcile_vertical_velocity(6.0, 4.0, 4.0, 0.5)
assert(clear_vy == 6 and not clear_ceiling)

-- Water efficiency blends toward land movement, and water/lava have
-- their own source drag/gravity sequences.
assert(math.abs(P.water_movement_speed(0.1, 1.0, true) - 0.1) < 1e-9)
assert(math.abs(P.water_movement_speed(0.1, 1.0, false) - 0.06) < 1e-9)
local water_x, water_y, water_z, water_drag =
    P.apply_water_drag(1, 1, 1, { efficiency = 0, onGround = true, gravity = 0.08 })
assert(math.abs(water_x - 0.8) < 1e-9 and math.abs(water_z - 0.8) < 1e-9)
assert(math.abs(water_y - 0.795) < 1e-9 and math.abs(water_drag - 0.8) < 1e-9)
local lava_x, lava_y, lava_z = P.apply_lava_drag(1, 1, 1, { deep = true, gravity = 0.08 })
assert(math.abs(lava_x - 0.5) < 1e-9 and math.abs(lava_z - 0.5) < 1e-9)
assert(math.abs(lava_y - 0.48) < 1e-9)

print("PASS: horizontal_step ground/air/sprint displacement regression")
print("Minecraft 26.3 physics port tests passed")
