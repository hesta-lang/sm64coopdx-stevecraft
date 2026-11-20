-- SteveCraft 64 - triangle collision solver.
-- Adapted from SkyCraft's TriCollider.java (MIT, chasmlol, 2026).
-- MarioCraft uses the same solver to clip Minecraft movement against SM64 triangles.
--
-- This module only limits a proposed displacement. SM64CoopDX remains responsible
-- for the actual MarioState step, object interactions and final contact resolution.

SteveCraft = SteveCraft or {}
SteveCraft.triCollision = SteveCraft.triCollision or {}
local M = SteveCraft.triCollision

M.source = "SkyCraft TriCollider.java, adapted for SM64CoopDX Lua"
M.version = "1.0.0-alpha"

local DEFAULTS = {
    floorRadius = 0.15,
    substep = 0.1,
    airStep = 0.3,
    epsilon = 1e-4,
    maxPiece = 0.45,
    wallEpsilon = 0.02,
    walkableNormalY = 0.7,
    wallIterations = 4,
    maxSubsteps = 64,
}

local function xyz(v)
    if v == nil then return nil end
    local x, y, z = v.x or v[1], v.y or v[2], v.z or v[3]
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
        return nil
    end
    return x, y, z
end

local function edge(px, pz, x0, z0, x1, z1)
    return (x1 - x0) * (pz - z0) - (z1 - z0) * (px - x0)
end

function M.make_triangle(v1, v2, v3, options)
    options = options or {}
    local ax, ay, az = xyz(v1)
    local bx, by, bz = xyz(v2)
    local cx, cy, cz = xyz(v3)
    if ax == nil or bx == nil or cx == nil then return nil end

    local ux, uy, uz = bx - ax, by - ay, bz - az
    local wx, wy, wz = cx - ax, cy - ay, cz - az
    local nx = uy * wz - uz * wy
    local ny = uz * wx - ux * wz
    local nz = ux * wy - uy * wx
    local length = math.sqrt(nx * nx + ny * ny + nz * nz)
    if length < 1e-9 then return nil end

    nx, ny, nz = nx / length, ny / length, nz / length
    local threshold = options.walkableNormalY or DEFAULTS.walkableNormalY
    local walkable = options.walkable
    if walkable == nil then
        walkable = math.abs(ny) >= threshold
    end

    return {
        ax = ax, ay = ay, az = az,
        bx = bx, by = by, bz = bz,
        cx = cx, cy = cy, cz = cz,
        nx = nx, ny = ny, nz = nz,
        minX = math.min(ax, bx, cx),
        minY = math.min(ay, by, cy),
        minZ = math.min(az, bz, cz),
        maxX = math.max(ax, bx, cx),
        maxY = math.max(ay, by, cy),
        maxZ = math.max(az, bz, cz),
        walkable = walkable == true,
        stairHelper = options.stairHelper == true,
        source = options.source,
        surfaceType = options.surfaceType,
    }
end

function M.height_at(triangle, x, z)
    if triangle == nil or math.abs(triangle.ny) < 0.05 then return nil end
    if x < triangle.minX - 1e-8 or x > triangle.maxX + 1e-8
        or z < triangle.minZ - 1e-8 or z > triangle.maxZ + 1e-8 then
        return nil
    end

    local d1 = edge(x, z, triangle.ax, triangle.az, triangle.bx, triangle.bz)
    local d2 = edge(x, z, triangle.bx, triangle.bz, triangle.cx, triangle.cz)
    local d3 = edge(x, z, triangle.cx, triangle.cz, triangle.ax, triangle.az)
    local hasNegative = d1 < -1e-10 or d2 < -1e-10 or d3 < -1e-10
    local hasPositive = d1 > 1e-10 or d2 > 1e-10 or d3 > 1e-10
    if hasNegative and hasPositive then return nil end

    return triangle.ay
        - (triangle.nx * (x - triangle.ax) + triangle.nz * (z - triangle.az)) / triangle.ny
end

local function build_samples(radius)
    local samples = { { 0, 0 } }
    for i = 0, 7 do
        local angle = i * math.pi / 4
        samples[#samples + 1] = {
            math.cos(angle) * radius,
            math.sin(angle) * radius,
        }
    end
    for i = 0, 3 do
        local angle = math.pi / 4 + i * math.pi / 2
        samples[#samples + 1] = {
            math.cos(angle) * radius * 0.5,
            math.sin(angle) * radius * 0.5,
        }
    end
    return samples
end

local function floor_height(triangles, x, y, z, walkableOnly, maxAbove, samples)
    local best = -math.huge
    local limit = y + maxAbove

    for _, triangle in ipairs(triangles) do
        if (not walkableOnly or triangle.walkable) and triangle.minY <= limit then
            for _, sample in ipairs(samples) do
                local height = M.height_at(triangle, x + sample[1], z + sample[2])
                if height ~= nil and height <= limit and height > best then
                    best = height
                end
            end
        end
    end
    return best
end

local function ceiling_height(triangles, x, head, z, radius, samples, floorRadius)
    local best = nil
    for _, triangle in ipairs(triangles) do
        if not triangle.stairHelper and triangle.maxY >= head - 0.05 then
            for _, sample in ipairs(samples) do
                local ratio = radius / math.max(1e-9, floorRadius)
                local height = M.height_at(
                    triangle,
                    x + sample[1] * ratio,
                    z + sample[2] * ratio
                )
                if height ~= nil and height >= head - 0.05 and (best == nil or height < best) then
                    best = height
                end
            end
        end
    end
    return best
end

local function clip_plane(input, level, keepAbove)
    local output = {}
    local count = #input
    for i = 1, count do
        local j = (i % count) + 1
        local a, b = input[i], input[j]
        local aInside = keepAbove and a.y >= level or (not keepAbove and a.y <= level)
        local bInside = keepAbove and b.y >= level or (not keepAbove and b.y <= level)

        if aInside then
            output[#output + 1] = { x = a.x, y = a.y, z = a.z }
        end
        if aInside ~= bInside then
            local denominator = b.y - a.y
            if math.abs(denominator) > 1e-12 then
                local fraction = (level - a.y) / denominator
                output[#output + 1] = {
                    x = a.x + (b.x - a.x) * fraction,
                    y = level,
                    z = a.z + (b.z - a.z) * fraction,
                }
            end
        end
    end
    return output
end

local function clip_triangle_to_slab(triangle, lower, upper)
    local polygon = {
        { x = triangle.ax, y = triangle.ay, z = triangle.az },
        { x = triangle.bx, y = triangle.by, z = triangle.bz },
        { x = triangle.cx, y = triangle.cy, z = triangle.cz },
    }
    polygon = clip_plane(polygon, lower, true)
    if #polygon == 0 then return polygon end
    return clip_plane(polygon, upper, false)
end

local function closest_xz(polygon, x, z)
    local count = #polygon
    if count == 0 then return x, z end
    local area = 0
    for i = 1, count do
        local j = (i % count) + 1
        local a, b = polygon[i], polygon[j]
        area = area + a.x * b.z - b.x * a.z
    end

    if math.abs(area) > 1e-9 then
        local inside = true
        for i = 1, count do
            local j = (i % count) + 1
            local a, b = polygon[i], polygon[j]
            local cross = (b.x - a.x) * (z - a.z) - (b.z - a.z) * (x - a.x)
            if (area > 0 and cross < -1e-10) or (area < 0 and cross > 1e-10) then
                inside = false
                break
            end
        end
        if inside then return x, z end
    end

    local bestDistance = math.huge
    local bestX, bestZ = polygon[1].x, polygon[1].z
    for i = 1, count do
        local j = (i % count) + 1
        local a, b = polygon[i], polygon[j]
        local ex, ez = b.x - a.x, b.z - a.z
        local lengthSquared = ex * ex + ez * ez
        local fraction = 0
        if lengthSquared > 1e-12 then
            fraction = math.max(0, math.min(1,
                ((x - a.x) * ex + (z - a.z) * ez) / lengthSquared))
        end
        local px, pz = a.x + ex * fraction, a.z + ez * fraction
        local dx, dz = px - x, pz - z
        local distance = dx * dx + dz * dz
        if distance < bestDistance then
            bestDistance, bestX, bestZ = distance, px, pz
        end
    end
    return bestX, bestZ
end

local function push_out_of_walls(triangles, x, y, z, radius, height,
    wallFrom, stepHeight, previousX, previousZ, epsilon, iterations)

    for _ = 1, iterations do
        local bestPenetration = 0
        local bestDirectionX, bestDirectionZ = 0, 0

        for _, triangle in ipairs(triangles) do
            if not triangle.stairHelper then
                local lower = y + (triangle.walkable and stepHeight or wallFrom)
                local upper = y + height - 0.02

                if triangle.maxY >= lower and triangle.minY <= upper
                    and triangle.maxX >= x - radius and triangle.minX <= x + radius
                    and triangle.maxZ >= z - radius and triangle.minZ <= z + radius then

                    local polygon = clip_triangle_to_slab(triangle, lower, upper)
                    if #polygon > 0 then
                        local closestX, closestZ = closest_xz(polygon, x, z)
                        local dx, dz = x - closestX, z - closestZ
                        local distance = math.sqrt(dx * dx + dz * dz)
                        local penetration, directionX, directionZ

                        if distance > 1e-6 then
                            penetration = radius - distance
                            directionX, directionZ = dx / distance, dz / distance
                        else
                            local horizontalNormal = math.sqrt(
                                triangle.nx * triangle.nx + triangle.nz * triangle.nz
                            )
                            if horizontalNormal > 1e-6 then
                                directionX = triangle.nx / horizontalNormal
                                directionZ = triangle.nz / horizontalNormal
                                if (previousX - triangle.ax) * directionX
                                    + (previousZ - triangle.az) * directionZ < 0 then
                                    directionX, directionZ = -directionX, -directionZ
                                end
                                penetration = radius
                            end
                        end

                        if penetration ~= nil and penetration > bestPenetration then
                            bestPenetration = penetration
                            bestDirectionX, bestDirectionZ = directionX, directionZ
                        end
                    end
                end
            end
        end

        if bestPenetration <= epsilon then break end
        x = x + bestDirectionX * (bestPenetration + epsilon)
        z = z + bestDirectionZ * (bestPenetration + epsilon)
    end
    return x, z
end

local function resolve_once(triangles, x0, y0, z0, radius, height, stepHeight,
    wasOnGround, mx, my, mz, config)

    if #triangles == 0 then return mx, my, mz end

    local x, y, z = x0, y0, z0
    local horizontal = math.sqrt(mx * mx + mz * mz)
    local steps = math.max(1, math.ceil(horizontal / config.substep))
    steps = math.min(steps, config.maxSubsteps)
    local wallFrom = wasOnGround and stepHeight or config.wallEpsilon
    local hitWall = false

    for i = 1, steps do
        local previousX, previousZ = x, z
        x = x + mx / steps
        z = z + mz / steps
        local fixedX, fixedZ = push_out_of_walls(
            triangles, x, y, z, radius, height, wallFrom, stepHeight,
            previousX, previousZ, config.epsilon, config.wallIterations
        )
        if fixedX ~= x or fixedZ ~= z then hitWall = true end
        x, z = fixedX, fixedZ
    end

    local dy = my
    if dy > 0 then
        local ceiling = ceiling_height(
            triangles, x, y + height, z, radius * 0.8, config.floorSamples, config.floorRadius
        )
        if ceiling ~= nil then
            dy = math.max(0, math.min(dy, ceiling - (y + height)))
        end
    end

    local walkUp = wasOnGround and stepHeight or config.airStep
    local walkFloor = floor_height(triangles, x, y, z, true, walkUp, config.floorSamples)
    local anyFloor = floor_height(triangles, x, y, z, false, config.epsilon, config.floorSamples)
    local floor = math.max(walkFloor, anyFloor)
    local targetY = y + dy
    local outY

    if targetY <= floor then
        outY = floor - y0
    elseif wasOnGround and dy <= 0 and walkFloor > -math.huge
        and y - walkFloor <= math.max(stepHeight, horizontal * 1.5) then
        outY = walkFloor - y0
    else
        outY = dy
    end

    return hitWall and (x - x0) or mx, outY, hitWall and (z - z0) or mz
end

local function merge_config(options)
    local config = {}
    for key, value in pairs(DEFAULTS) do config[key] = value end
    for key, value in pairs(options or {}) do
        if value ~= nil then config[key] = value end
    end
    if config.floorSamples == nil then
        config.floorSamples = build_samples(config.floorRadius)
    end
    return config
end

function M.resolve(triangles, x, y, z, radius, height, stepHeight,
    wasOnGround, mx, my, mz, options)

    local config = merge_config(options)
    if type(triangles) ~= "table" or #triangles == 0 then
        return mx, my, mz
    end
    if radius <= 0 or height <= 0 or stepHeight < 0 then
        return mx, my, mz
    end

    local length = math.sqrt(mx * mx + my * my + mz * mz)
    if length <= config.maxPiece then
        return resolve_once(triangles, x, y, z, radius, height, stepHeight,
            wasOnGround == true, mx, my, mz, config)
    end

    local pieces = math.ceil(length / config.maxPiece)
    local px, py, pz = mx / pieces, my / pieces, mz / pieces
    local currentX, currentY, currentZ = x, y, z
    local onGround = wasOnGround == true
    local changed, stoppedY = false, false

    for _ = 1, pieces do
        local wantedY = stoppedY and 0 or py
        local allowedX, allowedY, allowedZ = resolve_once(
            triangles, currentX, currentY, currentZ, radius, height, stepHeight,
            onGround, px, wantedY, pz, config
        )
        if allowedX ~= px or allowedY ~= wantedY or allowedZ ~= pz then
            changed = true
        end
        if allowedY ~= wantedY then
            stoppedY = true
            onGround = wantedY <= 0
        end
        currentX = currentX + allowedX
        currentY = currentY + allowedY
        currentZ = currentZ + allowedZ
    end

    if not changed and not stoppedY then return mx, my, mz end
    return currentX - x, currentY - y, currentZ - z
end

print("[SteveCraft] SkyCraft-compatible triangle collision solver loaded.")
