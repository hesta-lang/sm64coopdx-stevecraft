-- Unit tests for Minecraft eye-height conversion used by the independent camera.
package.path = "./?.lua;" .. package.path
local CameraMath = require("minecraft_26_3_camera")

local unitsPerBlock = 160.0 / 1.8
assert(math.abs(CameraMath.player_eye_offset(false, unitsPerBlock, 120) - 24) < 1e-6,
    "standing eye height must map Minecraft's 1.62 blocks to the SM64 head baseline")
assert(math.abs(CameraMath.player_eye_offset(true, unitsPerBlock, 120)
    - (1.27 * unitsPerBlock - 120)) < 1e-6,
    "crouching eye height must map Minecraft's 1.27 blocks to the SM64 head baseline")

print("SteveCraft Minecraft eye-height conversion tests passed")
