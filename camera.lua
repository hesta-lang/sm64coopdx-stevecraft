-- SteveCraft 64 - independent Minecraft-style camera controller.
--
-- The normal SM64 camera updater is frozen. A render-only Lua object in
-- OBJ_LIST_UNIMPORTANT runs after the Mario/player list and after
-- first_person_update(), then writes the final Camera/Lakitu transforms.
--
-- We deliberately keep the engine's first-person input sampler enabled in all
-- perspectives: it converts Android touchscreen mouse deltas into yaw/pitch.
-- Its generated camera position is overwritten later in the same frame by
-- this controller. This preserves the existing Android touch-look input while
-- removing the normal Mario/NEWCAM position and focus logic.

SteveCraft = SteveCraft or {}
local MinecraftCamera = require("minecraft_26_3_camera")
SteveCraft.cameraMath = MinecraftCamera
SteveCraft.PERSPECTIVE_FIRST_PERSON = 0
SteveCraft.PERSPECTIVE_THIRD_PERSON = 1
SteveCraft.PERSPECTIVE_THIRD_PERSON_FRONT = 2
SteveCraft.perspectiveMode = SteveCraft.perspectiveMode or SteveCraft.PERSPECTIVE_FIRST_PERSON

local controller = SteveCraft.cameraController or {}
SteveCraft.cameraController = controller
controller.version = "1.0.0-alpha"
controller.source = "Lua camera pose + SM64CoopDX touch-look input + camera_freeze"
controller.distanceBlocks = controller.distanceBlocks or 4.0
controller.unitsPerBlock = 160.0 / 1.8

local PI = math.pi
local TAU = 2.0 * PI
local ANGLE_TO_RAD = TAU / 65536.0
local CAMERA_RADIUS_BLOCKS = 0.10
local CAMERA_COLLISION_STEPS = 16
local CAMERA_VERTICAL_SAMPLES = { -0.75, 0, 0.75 }

local cameraBehavior = nil
local cameraObject = nil
local cameraActive = false
local cameraInputInitialized = false
local savedFirstPersonEnabled = nil
local savedFirstPersonYaw = nil
local savedFirstPersonPitch = nil
local savedCameraFrozen = nil
local lastCameraPose = nil
local missingCameraApiReported = false

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function wrap_angle(angle)
    return angle % 65536
end

local function safe_component(vector, key, value)
    if vector == nil or type(value) ~= "number" then return false end
    local ok = pcall(function() vector[key] = value end)
    return ok
end

local function set_vector(vector, x, y, z)
    if vector == nil then return false end
    local a = safe_component(vector, "x", x)
    local b = safe_component(vector, "y", y)
    local c = safe_component(vector, "z", z)
    return a and b and c
end

local function copy_vector(vector)
    if vector == nil then return nil end
    local ok, result = pcall(function()
        return { x = vector.x, y = vector.y, z = vector.z }
    end)
    if ok and type(result.x) == "number" and type(result.y) == "number"
        and type(result.z) == "number" then
        return result
    end
    return nil
end

local function camera_forward(yaw_units, pitch_units)
    local yaw = (yaw_units or 0) * ANGLE_TO_RAD
    local pitch = (pitch_units or 0) * ANGLE_TO_RAD
    local cp = math.cos(pitch)
    -- This matches first_person_camera_update() in the Android fork:
    -- yaw=0 looks toward -Z, positive pitch looks down.
    return {
        x = -math.sin(yaw) * cp,
        y = -math.sin(pitch),
        z = -math.cos(yaw) * cp,
    }
end

controller.camera_forward = camera_forward

local function is_local_steve(m)
    local character = SteveCraft.character
    local proxy = SteveCraft.proxy
    return m ~= nil
        and m.playerIndex == 0
        and character ~= nil
        and character.ready
        and character.modelId ~= nil
        and proxy ~= nil
        and type(proxy.is_attached) == "function"
        and proxy.is_attached(0)
end

local function get_motion_state(m)
    local physics = SteveCraft.physics
    if physics ~= nil and type(physics.get_animation_state) == "function" then
        local ok, state = pcall(physics.get_animation_state, m)
        if ok and state ~= nil then return state end
    end
    return nil
end

local function is_crouching(m)
    local state = get_motion_state(m)
    if state ~= nil then return state.crouching == true end
    local input = m ~= nil and m.input or 0
    if INPUT_Z_DOWN ~= nil and (input & INPUT_Z_DOWN) ~= 0 then return true end
    return ACT_CROUCHING ~= nil and m ~= nil and m.action == ACT_CROUCHING
end

local function eye_position(m)
    local units = controller.unitsPerBlock
    local eyeBlocks = is_crouching(m) and 1.27 or 1.62
    return {
        x = m.pos.x,
        y = m.pos.y + eyeBlocks * units,
        z = m.pos.z,
    }
end

local function wall_query_blocked(wcd, x, y, z, radius)
    if wcd == nil or type(find_wall_collisions) ~= "function" then return false end
    local ok, count = pcall(function()
        wcd.x = x
        wcd.y = y
        wcd.z = z
        wcd.offsetY = 0
        wcd.radius = radius
        wcd.numWalls = 0
        return find_wall_collisions(wcd)
    end)
    if not ok then return false end
    return (type(count) == "number" and count > 0)
        or (type(wcd.numWalls) == "number" and wcd.numWalls > 0)
end

local function floor_or_ceiling_blocked(point, radius)
    if type(find_floor) == "function" then
        local ok, height, surface = pcall(find_floor, point.x, point.y + radius, point.z)
        if ok and surface ~= nil and type(height) == "number"
            and height > point.y - radius then
            return true
        end
    end
    if type(find_ceil) == "function" then
        local ok, height, surface = pcall(find_ceil, point.x, point.y - radius, point.z)
        if ok and surface ~= nil and type(height) == "number"
            and height < point.y + radius then
            return true
        end
    end
    return false
end

-- Approximate Minecraft's eight-ray third-person clipping against the host
-- level's wall/floor/ceiling triangles. It is intentionally not described as a
-- Minecraft voxel VISUAL raycast: SM64 exposes triangle wall/floor queries.
local function clip_camera_distance(eye, forward, desiredDistance)
    desiredDistance = math.max(0, desiredDistance or 0)
    if desiredDistance <= 0 then return 0 end

    if type(collision_get_temp_wall_collision_data) ~= "function"
        or type(find_wall_collisions) ~= "function" then
        return desiredDistance
    end

    local ok, wcd = pcall(collision_get_temp_wall_collision_data)
    if not ok or wcd == nil then return desiredDistance end

    local savedChecking = nil
    if type(camera_get_checking_surfaces) == "function" then
        local getOk, value = pcall(camera_get_checking_surfaces)
        if getOk then savedChecking = value end
    end
    if type(camera_set_checking_surfaces) == "function" then
        pcall(camera_set_checking_surfaces, true)
    end

    local units = controller.unitsPerBlock
    local radius = units * CAMERA_RADIUS_BLOCKS
    local clipped = desiredDistance

    for step = 1, CAMERA_COLLISION_STEPS do
        local sampleDistance = desiredDistance * step / CAMERA_COLLISION_STEPS
        local point = {
            x = eye.x - forward.x * sampleDistance,
            y = eye.y - forward.y * sampleDistance,
            z = eye.z - forward.z * sampleDistance,
        }
        local blocked = false

        for _, verticalScale in ipairs(CAMERA_VERTICAL_SAMPLES) do
            local queryY = point.y + radius * verticalScale
            if wall_query_blocked(wcd, point.x, queryY, point.z, radius) then
                blocked = true
                break
            end
        end

        if blocked or floor_or_ceiling_blocked(point, radius) then
            local previousDistance = desiredDistance * (step - 1) / CAMERA_COLLISION_STEPS
            clipped = math.max(0, previousDistance - radius * 0.5)
            break
        end
    end

    if type(camera_set_checking_surfaces) == "function" and savedChecking ~= nil then
        pcall(camera_set_checking_surfaces, savedChecking)
    end
    return clamp(clipped, 0, desiredDistance)
end

controller.clip_camera_distance = clip_camera_distance

local function perspective_pose(m, mode)
    local eye = eye_position(m)
    local fp = gFirstPersonCamera
    local yaw = fp ~= nil and fp.yaw or ((m.faceAngle.y or 0) + 0x8000)
    local pitch = fp ~= nil and fp.pitch or 0

    local firstPerson = mode == SteveCraft.PERSPECTIVE_FIRST_PERSON
    local front = mode == SteveCraft.PERSPECTIVE_THIRD_PERSON_FRONT

    if front then
        yaw = wrap_angle(yaw + 0x8000)
        pitch = -pitch
    end

    local forward = camera_forward(yaw, pitch)
    local cameraPosition
    local focus
    local distance = 0

    if firstPerson then
        cameraPosition = { x = eye.x, y = eye.y, z = eye.z }
        focus = {
            x = eye.x + forward.x * 100,
            y = eye.y + forward.y * 100,
            z = eye.z + forward.z * 100,
        }
    else
        local desiredDistance = controller.distanceBlocks * controller.unitsPerBlock
        distance = clip_camera_distance(eye, forward, desiredDistance)
        cameraPosition = {
            x = eye.x - forward.x * distance,
            y = eye.y - forward.y * distance,
            z = eye.z - forward.z * distance,
        }
        focus = { x = eye.x, y = eye.y, z = eye.z }
    end

    return {
        mode = mode,
        eye = eye,
        position = cameraPosition,
        focus = focus,
        yaw = wrap_angle(yaw),
        pitch = pitch,
        distance = distance,
        desiredDistance = firstPerson and 0 or controller.distanceBlocks * controller.unitsPerBlock,
        forward = forward,
        firstPerson = firstPerson,
        front = front,
    }
end

controller.compute_pose = perspective_pose

local function write_camera_pose(m, pose)
    local lakitu = gLakituState
    local camera = m.area ~= nil and m.area.camera or nil
    if lakitu == nil or camera == nil or camera.pos == nil or camera.focus == nil then
        return false
    end

    local p, f = pose.position, pose.focus
    local ok = true
    ok = set_vector(camera.pos, p.x, p.y, p.z) and ok
    ok = set_vector(camera.focus, f.x, f.y, f.z) and ok

    -- Every exposed Lakitu vector component is writable even though the
    -- parent Vec3f pointer itself is read-only in the Lua binding.
    ok = set_vector(lakitu.pos, p.x, p.y, p.z) and ok
    ok = set_vector(lakitu.curPos, p.x, p.y, p.z) and ok
    ok = set_vector(lakitu.goalPos, p.x, p.y, p.z) and ok
    ok = set_vector(lakitu.focus, f.x, f.y, f.z) and ok
    ok = set_vector(lakitu.curFocus, f.x, f.y, f.z) and ok
    ok = set_vector(lakitu.goalFocus, f.x, f.y, f.z) and ok

    pcall(function()
        camera.yaw = pose.yaw
        camera.nextYaw = pose.yaw
        lakitu.yaw = pose.yaw
        lakitu.nextYaw = pose.yaw
        lakitu.oldYaw = pose.yaw
        lakitu.oldPitch = pose.pitch
        lakitu.oldRoll = 0
        lakitu.roll = 0
        lakitu.focusDistance = pose.distance > 0 and pose.distance or 100
        lakitu.posHSpeed = 0
        lakitu.posVSpeed = 0
        lakitu.focHSpeed = 0
        lakitu.focVSpeed = 0
    end)

    return ok
end

local function save_engine_camera_state()
    if savedFirstPersonEnabled ~= nil then return end
    savedFirstPersonEnabled = gFirstPersonCamera ~= nil
        and gFirstPersonCamera.enabled == true or false
    savedFirstPersonYaw = gFirstPersonCamera ~= nil and gFirstPersonCamera.yaw or 0
    savedFirstPersonPitch = gFirstPersonCamera ~= nil and gFirstPersonCamera.pitch or 0
    savedCameraFrozen = type(camera_is_frozen) == "function"
        and camera_is_frozen() == true or false
end

local function activate_camera_input(m)
    save_engine_camera_state()
    if not cameraInputInitialized and gFirstPersonCamera ~= nil then
        -- SM64 first-person yaw points 180 degrees away from Mario's body yaw.
        -- Seed it once so the first Steve camera frame faces the player's
        -- current direction; subsequent Android touch deltas remain native.
        gFirstPersonCamera.yaw = wrap_angle((m.faceAngle and m.faceAngle.y or 0) + 0x8000)
        gFirstPersonCamera.pitch = 0
        cameraInputInitialized = true
    end
    set_first_person_enabled(true)
    if type(camera_freeze) == "function" then
        camera_freeze()
    end
    cameraActive = true
end

local function restore_engine_camera_state()
    if cameraActive then
        if savedCameraFrozen == false and type(camera_unfreeze) == "function" then
            camera_unfreeze()
        end
        if gFirstPersonCamera ~= nil then
            set_first_person_enabled(savedFirstPersonEnabled == true)
            gFirstPersonCamera.yaw = savedFirstPersonYaw or gFirstPersonCamera.yaw
            gFirstPersonCamera.pitch = savedFirstPersonPitch or gFirstPersonCamera.pitch
        end
    end
    cameraActive = false
    cameraInputInitialized = false
    savedFirstPersonEnabled = nil
    savedFirstPersonYaw = nil
    savedFirstPersonPitch = nil
    savedCameraFrozen = nil
    lastCameraPose = nil
end

local function camera_controller_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE or 0
    o.oInteractType = 0
    o.oIntangibleTimer = -1
    o.oGravity = 0
    o.oVelX, o.oVelY, o.oVelZ = 0, 0, 0
end

local function camera_controller_loop(o)
    if not cameraActive then return end
    local m = gMarioStates ~= nil and gMarioStates[0] or nil
    if not is_local_steve(m) or m.area == nil or m.area.camera == nil then
        restore_engine_camera_state()
        return
    end

    -- This object is in OBJ_LIST_UNIMPORTANT, which SM64CoopDX processes after
    -- OBJ_LIST_PLAYER. Therefore first_person_update() has already consumed
    -- touchscreen deltas, and update_camera() has not yet run this frame.
    if type(camera_freeze) == "function" then camera_freeze() end
    set_first_person_enabled(true)

    local pose = perspective_pose(m, SteveCraft.perspectiveMode)
    if write_camera_pose(m, pose) then
        lastCameraPose = pose
    elseif not missingCameraApiReported then
        print("[SteveCraft Camera] Camera/Lakitu vector bindings unavailable; using the native camera fallback.")
        missingCameraApiReported = true
    end
end

if type(hook_behavior) == "function" and OBJ_LIST_UNIMPORTANT ~= nil then
    cameraBehavior = hook_behavior(
        nil, OBJ_LIST_UNIMPORTANT, true,
        camera_controller_init, camera_controller_loop,
        "bhvSteveCraftIndependentCamera"
    )
end

local function ensure_camera_object()
    if cameraObject ~= nil then return true end
    if cameraBehavior == nil or type(spawn_non_sync_object) ~= "function"
        or E_MODEL_NONE == nil then
        return false
    end
    cameraObject = spawn_non_sync_object(
        cameraBehavior, E_MODEL_NONE, 0, -10000, 0, nil
    )
    return cameraObject ~= nil
end

function controller.set_mode(mode)
    if mode ~= SteveCraft.PERSPECTIVE_FIRST_PERSON
        and mode ~= SteveCraft.PERSPECTIVE_THIRD_PERSON
        and mode ~= SteveCraft.PERSPECTIVE_THIRD_PERSON_FRONT then
        return false
    end
    SteveCraft.perspectiveMode = mode
    return true
end

function controller.get_mode()
    return SteveCraft.perspectiveMode
end

function controller.is_first_person()
    return SteveCraft.perspectiveMode == SteveCraft.PERSPECTIVE_FIRST_PERSON
end

function controller.set_distance_blocks(distance)
    if type(distance) ~= "number" or distance ~= distance then return false end
    controller.distanceBlocks = clamp(distance, 1.0, 8.0)
    return true
end

function controller.get_distance_blocks()
    return controller.distanceBlocks
end

function controller.get_view_origin(m)
    if m == nil or m.pos == nil then return nil end
    return eye_position(m)
end

function controller.get_last_pose()
    local pose = lastCameraPose
    if pose == nil then return nil end
    return {
        mode = pose.mode,
        position = { x = pose.position.x, y = pose.position.y, z = pose.position.z },
        focus = { x = pose.focus.x, y = pose.focus.y, z = pose.focus.z },
        yaw = pose.yaw,
        pitch = pose.pitch,
        distance = pose.distance,
        desiredDistance = pose.desiredDistance,
        firstPerson = pose.firstPerson,
        front = pose.front,
    }
end

local function on_mario_update(m)
    if not is_local_steve(m) then
        if cameraActive then restore_engine_camera_state() end
        return
    end

    if m.controller ~= nil and (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        controller.set_mode((SteveCraft.perspectiveMode + 1) % 3)
    end

    if ensure_camera_object() then
        activate_camera_input(m)
    end
end

local function on_level_init()
    -- Keep the live controller object if the engine carries it across an area
    -- transition; HOOK_ON_OBJECT_UNLOAD clears the reference when it is removed.
    cameraInputInitialized = false
end

local function on_warp()
    cameraInputInitialized = false
end

local function on_exit()
    restore_engine_camera_state()
    cameraObject = nil
end

local function on_camera_object_unload(obj)
    if obj == cameraObject then cameraObject = nil end
end

hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_EXIT, on_exit)
hook_event(HOOK_ON_OBJECT_UNLOAD, on_camera_object_unload)

print("[SteveCraft Camera] Independent Lua camera controller loaded.")
