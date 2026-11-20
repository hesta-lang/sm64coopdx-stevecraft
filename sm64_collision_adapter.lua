-- SteveCraft 64 - SM64CoopDX surface sampler for the triangle solver.
--
-- The sampler uses documented Lua collision functions from SM64CoopDX:
-- find_floor, find_ceil, collision_get_temp_wall_collision_data,
-- find_wall_collisions, and get_surface_from_wcd_index.
--
-- It does not enumerate or modify the engine's surface pools. It asks the engine
-- for the nearby surfaces around the proposed movement and converts those
-- surfaces into the SkyCraft/MarioCraft triangle format.

SteveCraft = SteveCraft or {}
SteveCraft.sm64Collision = SteveCraft.sm64Collision or {}
local adapter = SteveCraft.sm64Collision

adapter.version = "1.0.0-alpha"
adapter.source = "SM64CoopDX Lua collision API + SkyCraft TriCollider adapter"

local function available()
    return type(find_floor) == "function"
        and type(find_ceil) == "function"
        and type(collision_get_temp_wall_collision_data) == "function"
        and type(find_wall_collisions) == "function"
        and type(get_surface_from_wcd_index) == "function"
        and SteveCraft.triCollision ~= nil
end

local function point_key(surface)
    local a, b, c = surface.vertex1, surface.vertex2, surface.vertex3
    if a == nil or b == nil or c == nil then return nil end
    return table.concat({
        tostring(a.x), tostring(a.y), tostring(a.z),
        tostring(b.x), tostring(b.y), tostring(b.z),
        tostring(c.x), tostring(c.y), tostring(c.z),
        tostring(surface.type),
    }, ":")
end

local function is_ignored_surface(surface)
    local surfaceType = surface.type
    if SURFACE_DEATH_PLANE ~= nil and surfaceType == SURFACE_DEATH_PLANE then return true end
    if SURFACE_CAMERA_BOUNDARY ~= nil and surfaceType == SURFACE_CAMERA_BOUNDARY then return true end
    if SURFACE_VANISH_CAP_WALLS ~= nil and surfaceType == SURFACE_VANISH_CAP_WALLS then return true end
    if SURFACE_FLAG_INTANGIBLE ~= nil and surface.flags ~= nil
        and (surface.flags & SURFACE_FLAG_INTANGIBLE) ~= 0 then
        return true
    end
    return false
end

local function is_walkable(surface, normalY)
    local ny = math.abs(normalY or 0)
    if ny >= 0.7 then return true end

    local surfaceType = surface.type
    local explicitlyWalkable =
        (SURFACE_NOT_SLIPPERY ~= nil and surfaceType == SURFACE_NOT_SLIPPERY)
        or (SURFACE_HARD_NOT_SLIPPERY ~= nil and surfaceType == SURFACE_HARD_NOT_SLIPPERY)

    -- MarioCraft's extension uses a walkable flag for explicitly walkable SM64
    -- ramps down to |normal.y| >= 0.4. The Lua API does not expose its exported
    -- TRI_WALKABLE flag, so only the two explicit non-slippery surface types
    -- receive this lower threshold in SteveCraft.
    return explicitlyWalkable and ny >= 0.4
end

local function add_surface(surface, triangles, seen)
    if surface == nil or is_ignored_surface(surface) then return end
    local key = point_key(surface)
    if key == nil or seen[key] then return end

    local normal = surface.normal
    if normal == nil then return end
    local walkable = is_walkable(surface, normal.y)

    local triangle = SteveCraft.triCollision.make_triangle(
        surface.vertex1,
        surface.vertex2,
        surface.vertex3,
        {
            walkable = walkable,
            stairHelper = false,
            source = surface.socId,
            surfaceType = surface.type,
        }
    )
    if triangle ~= nil then
        seen[key] = true
        triangles[#triangles + 1] = triangle
    end
end

local FLOOR_SAMPLES = {
    { 0, 0 },
    { 1, 0 }, { 0.70710678, 0.70710678 },
    { 0, 1 }, { -0.70710678, 0.70710678 },
    { -1, 0 }, { -0.70710678, -0.70710678 },
    { 0, -1 }, { 0.70710678, -0.70710678 },
    { 0.35355339, 0.35355339 }, { -0.35355339, 0.35355339 },
    { -0.35355339, -0.35355339 }, { 0.35355339, -0.35355339 },
}

local CEILING_SAMPLES = {
    { 0, 0 }, { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 },
}

local function safe_find_floor(x, y, z, triangles, seen)
    local ok, floorHeight, surface = pcall(find_floor, x, y, z)
    if ok and surface ~= nil then
        add_surface(surface, triangles, seen)
    end
    return ok and floorHeight or nil
end

local function safe_find_ceil(x, y, z, triangles, seen)
    local ok, ceilingHeight, surface = pcall(find_ceil, x, y, z)
    if ok and surface ~= nil then
        add_surface(surface, triangles, seen)
    end
    return ok and ceilingHeight or nil
end

local function safe_find_walls(x, y, z, offsetY, radius, triangles, seen)
    local ok, wcd = pcall(collision_get_temp_wall_collision_data)
    if not ok or wcd == nil then return end

    local success = pcall(function()
        wcd.x = x
        wcd.y = y
        wcd.z = z
        wcd.offsetY = offsetY
        wcd.radius = radius
        wcd.numWalls = 0
        find_wall_collisions(wcd)

        local count = math.min(4, wcd.numWalls or 0)
        for i = 0, count - 1 do
            local surface = get_surface_from_wcd_index(wcd, i)
            add_surface(surface, triangles, seen)
        end
    end)
    return success
end

function adapter.is_available()
    return available()
end

function adapter.collect(m, move, config)
    if not available() or m == nil or m.pos == nil or move == nil then return nil end
    config = config or {}

    local units = config.unitsPerBlock or 88.8888888889
    local startX, startY, startZ = m.pos.x, m.pos.y, m.pos.z
    if type(startX) ~= "number" or type(startY) ~= "number" or type(startZ) ~= "number" then
        return nil
    end

    local marioObject = m.marioObj
    local radius = config.radius
        or (marioObject ~= nil and marioObject.hitboxRadius)
        or 37
    local height = config.height
        or (marioObject ~= nil and marioObject.hitboxHeight)
        or 160
    local stepHeight = config.stepHeight or units * 0.6
    local floorRadius = config.floorRadius or units * 0.15

    local endX, endY, endZ = startX + move.x, startY + move.y, startZ + move.z
    local triangles, seen = {}, {}

    -- Collect floor planes at the destination footprint. Multiple small
    -- samples avoid losing triangles that only cover part of the player's feet.
    for _, sample in ipairs(FLOOR_SAMPLES) do
        local x = endX + sample[1] * floorRadius
        local z = endZ + sample[2] * floorRadius
        safe_find_floor(x, endY + stepHeight + 1, z, triangles, seen)
    end

    -- Ceiling queries are sampled around the head, not just at the centre.
    local headRadius = radius * 0.8
    for _, sample in ipairs(CEILING_SAMPLES) do
        local x = endX + sample[1] * headRadius
        local z = endZ + sample[2] * headRadius
        safe_find_ceil(x, endY + height - 1, z, triangles, seen)
    end

    -- Wall queries run along the proposed path and at three heights through
    -- the player's body. This approximates the cylinder/slab collection used
    -- by SkyCraft while leaving SM64's own solver as the final authority.
    local horizontal = math.sqrt(move.x * move.x + move.z * move.z)
    local pathSegments = math.max(1, math.min(4, math.ceil(horizontal / (units * 0.3))))
    local wallFrom = config.wasOnGround and stepHeight or units * 0.02
    local wallOffsets = {
        wallFrom,
        (wallFrom + math.max(wallFrom, height - 2)) * 0.5,
        math.max(wallFrom, height - 2),
    }

    for segment = 0, pathSegments do
        local fraction = segment / pathSegments
        local x = startX + move.x * fraction
        local y = startY + move.y * fraction
        local z = startZ + move.z * fraction
        for _, offset in ipairs(wallOffsets) do
            safe_find_walls(x, y, z, offset, radius, triangles, seen)
        end
    end

    return triangles, {
        radius = radius,
        height = height,
        stepHeight = stepHeight,
        floorRadius = floorRadius,
    }
end

function adapter.resolve(m, move, config)
    local triangles, dimensions = adapter.collect(m, move, config)
    if triangles == nil then return nil end

    local options = {
        floorRadius = dimensions.floorRadius,
        substep = (config and config.substep) or ((config and config.unitsPerBlock) or 88.8888888889) * 0.1,
        airStep = ((config and config.unitsPerBlock) or 88.8888888889) * 0.3,
        maxPiece = ((config and config.unitsPerBlock) or 88.8888888889) * 0.45,
        epsilon = 0.01,
    }

    local allowedX, allowedY, allowedZ = SteveCraft.triCollision.resolve(
        triangles,
        m.pos.x, m.pos.y, m.pos.z,
        dimensions.radius, dimensions.height, dimensions.stepHeight,
        config ~= nil and config.wasOnGround == true,
        move.x, move.y, move.z,
        options
    )

    return {
        x = allowedX,
        y = allowedY,
        z = allowedZ,
        surfaces = #triangles,
    }
end

print("[SteveCraft] SM64CoopDX surface adapter loaded.")
