-- Tests for the SkyCraft-derived triangle collision solver.
local Tri = dofile("tri_collider.lua")

local function triangle(a, b, c, walkable)
    return assert(Tri.make_triangle(a, b, c, { walkable = walkable }))
end

local floor = {
    triangle({ x=-10, y=0, z=-10 }, { x=10, y=0, z=-10 }, { x=10, y=0, z=10 }, true),
    triangle({ x=-10, y=0, z=-10 }, { x=10, y=0, z=10 }, { x=-10, y=0, z=10 }, true),
}

local x, y, z = Tri.resolve(floor, 0, 1, 0, 0.5, 1.8, 0.6, false, 0, -2, 0)
assert(math.abs(x) < 1e-8 and math.abs(y + 1) < 1e-6 and math.abs(z) < 1e-8,
    "falling onto a flat floor should stop at floor height")

local walkX, walkY, walkZ = Tri.resolve(floor, 0, 0, 0, 0.5, 1.8, 0.6, true, 0.25, 0, 0)
assert(math.abs(walkX - 0.25) < 1e-8 and math.abs(walkY) < 1e-8 and math.abs(walkZ) < 1e-8,
    "flat floor should not change a clear horizontal move")

local step = {
    triangle({ x=-10, y=0, z=-10 }, { x=0, y=0, z=-10 }, { x=0, y=0, z=10 }, true),
    triangle({ x=0, y=0.4, z=-10 }, { x=10, y=0.4, z=-10 }, { x=10, y=0.4, z=10 }, true),
    triangle({ x=0, y=0.4, z=-10 }, { x=10, y=0.4, z=10 }, { x=0, y=0.4, z=10 }, true),
}
local stepX, stepY, stepZ = Tri.resolve(step, -0.2, 0, 0, 0.1, 1.8, 0.6, true, 0.4, 0, 0)
assert(stepY > 0.35 and stepY < 0.45, "walkable 0.4-unit step should be climbed")
assert(stepX > 0.35 and math.abs(stepZ) < 1e-6, "step should preserve horizontal progress")

local wall = {
    triangle({ x=1, y=0, z=-5 }, { x=1, y=3, z=-5 }, { x=1, y=3, z=5 }, false),
    triangle({ x=1, y=0, z=-5 }, { x=1, y=3, z=5 }, { x=1, y=0, z=5 }, false),
}
local wallX, wallY, wallZ = Tri.resolve(wall, 0.4, 0, 0, 0.5, 1.8, 0.6, false, 0.4, 0, 0)
assert(wallX < 0.11 and wallX > 0.09, "vertical wall should push the capsule back to its radius")
assert(math.abs(wallZ) < 1e-8 and math.abs(wallY) < 1e-8, "wall should not create vertical or lateral movement")

local ceiling = {
    triangle({ x=-5, y=2, z=-5 }, { x=5, y=2, z=-5 }, { x=5, y=2, z=5 }, false),
    triangle({ x=-5, y=2, z=-5 }, { x=5, y=2, z=5 }, { x=-5, y=2, z=5 }, false),
}
local ceilX, ceilY, ceilZ = Tri.resolve(ceiling, 0, 0, 0, 0.5, 1.8, 0.6, false, 0, 0.5, 0)
assert(ceilY > 0.19 and ceilY < 0.21, "ceiling should shorten the upward movement")
assert(math.abs(ceilX) < 1e-8 and math.abs(ceilZ) < 1e-8, "ceiling should not affect horizontal movement")

local longX = Tri.resolve(wall, 0.4, 0, 0, 0.5, 1.8, 0.6, false, 3.0, 0, 0)
assert(longX < 0.11, "long movement must not tunnel through a wall")

local sloped = triangle(
    { x=-5, y=0, z=-5 },
    { x=5, y=1, z=-5 },
    { x=5, y=1, z=5 },
    true
)
local atSlope = Tri.height_at(sloped, 4, 0)
assert(atSlope ~= nil and atSlope > 0.7 and atSlope < 0.9, "plane height should be computed inside a triangle")
assert(Tri.height_at(sloped, -4, 4) == nil, "points outside a triangle must be rejected")

print("SkyCraft-derived triangle collision tests passed.")
