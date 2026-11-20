-- SteveCraft: independent Lua port of Minecraft Java 26.3 camera math.
-- Geometry queries are injected by the host. The module does not pretend that
-- SM64 triangle collision data is Minecraft's voxel VISUAL block ray tracer.

local C = {}
local PI = math.pi
local RAD = PI / 180.0
local DEG = 180.0 / PI

local function clamp(x, lo, hi)
    return math.max(lo, math.min(hi, x))
end

local function finite(x, fallback)
    if type(x) ~= "number" or x ~= x or x == math.huge or x == -math.huge then
        return fallback
    end
    return x
end

local function vec(x, y, z)
    return { x = finite(x, 0), y = finite(y, 0), z = finite(z, 0) }
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function angle_lerp_degrees(a, b, t)
    local delta = (b - a) % 360.0
    if delta >= 180.0 then delta = delta - 360.0 end
    return a + delta * t
end

function C.interpolate_entity(entity, partial_tick)
    partial_tick = clamp(finite(partial_tick, 1), 0, 1)
    local old = entity.oldPosition or entity.oldPos or entity.position
    local now = entity.position or entity.pos
    if type(old) ~= "table" or type(now) ~= "table" then
        error("Camera entity needs oldPosition and position vectors")
    end
    local x = lerp(finite(old.x, 0), finite(now.x, 0), partial_tick)
    local y = lerp(finite(old.y, 0), finite(now.y, 0), partial_tick)
    local z = lerp(finite(old.z, 0), finite(now.z, 0), partial_tick)
    local old_eye = finite(entity.oldEyeHeight, finite(entity.eyeHeight, 0))
    local eye = finite(entity.eyeHeight, old_eye)
    return vec(x, y + lerp(old_eye, eye, partial_tick), z)
end

function C.interpolate_rotation(entity, partial_tick)
    partial_tick = clamp(finite(partial_tick, 1), 0, 1)
    local yaw = angle_lerp_degrees(
        finite(entity.oldYaw, finite(entity.yaw, 0)),
        finite(entity.yaw, 0), partial_tick
    )
    local pitch = lerp(
        finite(entity.oldPitch, finite(entity.pitch, 0)),
        finite(entity.pitch, 0), partial_tick
    )
    return yaw, pitch
end

function C.perspective_rotation(yaw_degrees, pitch_degrees, front)
    local yaw = finite(yaw_degrees, 0)
    local pitch = finite(pitch_degrees, 0)
    if front then return yaw + 180.0, -pitch end
    return yaw, pitch
end

function C.direction(yaw_degrees, pitch_degrees)
    local yaw, pitch = finite(yaw_degrees, 0) * RAD, finite(pitch_degrees, 0) * RAD
    local cp = math.cos(pitch)
    return vec(-math.sin(yaw) * cp, -math.sin(pitch), math.cos(yaw) * cp)
end

function C.camera_pose(entity, perspective, partial_tick, camera_distance)
    perspective = perspective or "first_person"
    local origin = C.interpolate_entity(entity, partial_tick)
    local yaw, pitch = C.interpolate_rotation(entity, partial_tick)
    local detached = perspective ~= "first_person"
    local front = perspective == "third_person_front"

    if front then
        yaw = yaw + 180.0
        pitch = -pitch
    end

    local desired = 0.0
    if detached then
        local scale = math.max(0.0, finite(entity.scale, 1.0))
        local attribute = math.max(0.0, finite(entity.cameraDistance, 1.0))
        desired = math.max(0.0, finite(camera_distance, 4.0)) * scale * attribute
    end
    local dir = C.direction(yaw, pitch)
    local position = vec(
        origin.x - dir.x * desired,
        origin.y - dir.y * desired,
        origin.z - dir.z * desired
    )
    return {
        origin = origin, position = position, yaw = yaw, pitch = pitch,
        desiredDistance = desired, detached = detached, front = front,
    }
end

local function distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Camera.getMaxZoom: cast eight short-offset rays, reducing the maximum
-- third-person distance to the nearest obstructing hit. raycast(from,to,opts)
-- must return a hit point vector or nil. Coordinates are supplied by caller.
function C.clip_third_person_distance(origin, direction, distance_blocks, raycast, options)
    local desired = math.max(0.0, finite(distance_blocks, 4.0))
    if type(raycast) ~= "function" or desired <= 0 then return desired end
    options = options or {}
    local offset = finite(options.ray_offset, 0.1)
    local minimum = desired
    local signs = { -1, 1 }

    for ix = 1, 2 do
        for iy = 1, 2 do
            for iz = 1, 2 do
                local from = vec(
                    origin.x + signs[ix] * offset,
                    origin.y + signs[iy] * offset,
                    origin.z + signs[iz] * offset
                )
                local to = vec(
                    from.x - direction.x * desired,
                    from.y - direction.y * desired,
                    from.z - direction.z * desired
                )
                local ok, hit = pcall(raycast, from, to, {
                    shape = "VISUAL", fluid = "NONE", source = "minecraft_camera"
                })
                if ok and type(hit) == "table"
                    and type(hit.x) == "number" and type(hit.y) == "number"
                    and type(hit.z) == "number" then
                    minimum = math.min(minimum, distance(origin, hit))
                end
            end
        end
    end
    return clamp(minimum, 0.0, desired)
end

function C.pose_with_collision(entity, perspective, partial_tick, raycast, options)
    options = options or {}
    local pose = C.camera_pose(entity, perspective, partial_tick, options.distance or 4.0)
    if not pose.detached then return pose end
    local direction = C.direction(pose.yaw, pose.pitch)
    local distance = C.clip_third_person_distance(
        pose.origin, direction, pose.desiredDistance, raycast, options
    )
    pose.clippedDistance = distance
    pose.position = vec(
        pose.origin.x - direction.x * distance,
        pose.origin.y - direction.y * distance,
        pose.origin.z - direction.z * distance
    )
    return pose
end

return C
