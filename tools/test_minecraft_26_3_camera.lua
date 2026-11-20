package.path = "./?.lua;" .. package.path
local C = require("minecraft_26_3_camera")

local entity = {
    oldPosition = { x = 0, y = 0, z = 0 },
    position = { x = 10, y = 4, z = 20 },
    oldEyeHeight = 1.5, eyeHeight = 2.0,
    oldYaw = 350, yaw = 10, oldPitch = 0, pitch = 30,
    scale = 1, cameraDistance = 1,
}
local origin = C.interpolate_entity(entity, 0.5)
assert(math.abs(origin.x - 5) < 1e-6)
assert(math.abs(origin.y - 3.75) < 1e-6)
assert(math.abs(origin.z - 10) < 1e-6)

local yaw, pitch = C.interpolate_rotation(entity, 0.5)
assert(math.abs(yaw - 360) < 1e-6 or math.abs(yaw) < 1e-6)
assert(math.abs(pitch - 15) < 1e-6)

local rear = C.camera_pose(entity, "third_person_back", 1)
assert(math.abs(rear.desiredDistance - 4) < 1e-6)
assert(math.abs(rear.position.z - (20 - 4 * math.cos(10 * math.pi / 180) * math.cos(30 * math.pi / 180))) < 1e-5)

local front = C.camera_pose(entity, "third_person_front", 1)
assert(math.abs(((front.yaw % 360) + 360) % 360 - 190) < 1e-6)
assert(math.abs(front.pitch + 30) < 1e-6)
assert(front.position.z > entity.position.z)

local calls = 0
local clipped = C.clip_third_person_distance(
    { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 1 }, 4,
    function(from, to, options)
        calls = calls + 1
        assert(options.shape == "VISUAL" and options.fluid == "NONE")
        if calls == 1 then return { x = 0, y = 0, z = -2 } end
        return nil
    end
)
assert(calls == 8)
assert(math.abs(clipped - 2) < 1e-6)

local unblocked = C.clip_third_person_distance(
    { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 1 }, 4,
    function() return nil end
)
assert(unblocked == 4)

print("Minecraft 26.3 camera port tests passed")
