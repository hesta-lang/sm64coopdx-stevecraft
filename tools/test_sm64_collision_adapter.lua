-- Tests for the SM64CoopDX surface-query adapter.
dofile("tri_collider.lua")

SURFACE_DEATH_PLANE = 100
SURFACE_CAMERA_BOUNDARY = 101
SURFACE_VANISH_CAP_WALLS = 102
SURFACE_NOT_SLIPPERY = 10
SURFACE_HARD_NOT_SLIPPERY = 11

local floorSurface = {
    type = 0, flags = 0, socId = 1,
    vertex1 = { x = -10, y = 0, z = -10 },
    vertex2 = { x = 10, y = 0, z = -10 },
    vertex3 = { x = 10, y = 0, z = 10 },
    normal = { x = 0, y = 1, z = 0 },
}

local wallA = {
    type = 0, flags = 0, socId = 2,
    vertex1 = { x = 0.8, y = 0, z = -5 },
    vertex2 = { x = 0.8, y = 3, z = -5 },
    vertex3 = { x = 0.8, y = 3, z = 5 },
    normal = { x = 1, y = 0, z = 0 },
}
local wallB = {
    type = 0, flags = 0, socId = 3,
    vertex1 = { x = 0.8, y = 0, z = -5 },
    vertex2 = { x = 0.8, y = 3, z = 5 },
    vertex3 = { x = 0.8, y = 0, z = 5 },
    normal = { x = 1, y = 0, z = 0 },
}

function find_floor(x, y, z)
    return 0, floorSurface
end

function find_ceil(x, y, z)
    return 1000, nil
end

function collision_get_temp_wall_collision_data()
    return {
        walls = {},
        numWalls = 0,
        x = 0, y = 0, z = 0,
        offsetY = 0, radius = 0,
    }
end

function find_wall_collisions(wcd)
    if wcd.x + wcd.radius >= 0.8 and wcd.x - wcd.radius <= 0.8
        and wcd.y + wcd.offsetY <= 3 and wcd.y + wcd.offsetY >= 0 then
        wcd.walls = { wallA, wallB }
        wcd.numWalls = 2
    else
        wcd.walls = {}
        wcd.numWalls = 0
    end
    return wcd.numWalls
end

function get_surface_from_wcd_index(wcd, index)
    return wcd.walls[index + 1]
end

dofile("sm64_collision_adapter.lua")

local adapter = SteveCraft.sm64Collision
assert(adapter ~= nil and adapter.is_available(), "SM64 surface adapter should detect the mocked API")

local mario = {
    pos = { x = 0, y = 0, z = 0 },
    marioObj = { hitboxRadius = 0.5, hitboxHeight = 1.8 },
}
local clearMove = { x = 0.1, y = 0, z = 0 }
local clearResult = adapter.resolve(mario, clearMove, {
    unitsPerBlock = 1,
    wasOnGround = true,
})
assert(clearResult ~= nil, "adapter should return a resolved displacement")
assert(clearResult.surfaces >= 1, "adapter should collect the floor triangle")
assert(math.abs(clearResult.x - clearMove.x) < 1e-8, "clear movement should be preserved")

local wallMove = { x = 1, y = 0, z = 0 }
local wallResult = adapter.resolve(mario, wallMove, {
    unitsPerBlock = 1,
    wasOnGround = true,
})
assert(wallResult ~= nil and wallResult.surfaces >= 2, "adapter should collect wall triangles")
assert(wallResult.x < 0.4, "adapter should clip movement into the sampled wall")

print("SM64CoopDX collision adapter tests passed.")
