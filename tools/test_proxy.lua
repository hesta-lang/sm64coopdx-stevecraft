-- Runtime-independent tests for SteveCraft's proxy adapter.
local hooks = {}
local activeObject = nil
local nextObjectId = 1
local behavior = nil
local firstPerson = false

OBJ_LIST_GENACTOR = 1
OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE = 0x100
E_MODEL_NONE = -1
E_MODEL_ERROR_MODEL = -2
ACT_FLAG_AIR = 0x200
HOOK_ON_OBJECT_UNLOAD = "object_unload"
HOOK_ON_LEVEL_INIT = "level_init"
HOOK_ON_WARP = "warp"
HOOK_ON_EXIT = "exit"

function print() end
function hook_event(name, callback)
    hooks[name] = callback
end
function hook_behavior(_, _, _, init, loop, name)
    behavior = { init = init, loop = loop, name = name }
    return 700
end
function spawn_non_sync_object(_, modelId, x, y, z, setup)
    local object = {
        modelId = modelId,
        oPosX = x, oPosY = y, oPosZ = z,
        oFlags = 0, oBehParams = 0,
        oFaceAnglePitch = 0, oFaceAngleYaw = 0, oFaceAngleRoll = 0,
        oMoveAnglePitch = 0, oMoveAngleYaw = 0, oMoveAngleRoll = 0,
        header = {
            gfx = {
                animInfo = {
                    curAnim = nil, prevAnimPtr = nil,
                    animID = 0, prevAnimID = 0,
                    animFrame = 0, prevAnimFrame = 0,
                    animFrameAccelAssist = 0, animAccel = 0,
                    animTimer = 0, animYTrans = 0,
                },
                scale = { x = 1, y = 1, z = 1 },
                shadowInvisible = false,
            },
        },
    }
    behavior.init(object)
    setup(object)
    object.id = nextObjectId
    nextObjectId = nextObjectId + 1
    return object
end
function obj_mark_for_deletion(object)
    object.deleted = true
end
function cur_obj_hide()
    if activeObject then activeObject.hidden = true end
end
function cur_obj_unhide()
    if activeObject then activeObject.hidden = false end
end
function get_first_person_enabled()
    return firstPerson
end

local function make_mario(index, globalIndex)
    local anim = {
        curAnim = { name = "run" },
        prevAnimPtr = { name = "walk" },
        animID = 12, prevAnimID = 11,
        animFrame = 8, prevAnimFrame = 7,
        animFrameAccelAssist = 2, animAccel = 0x10000,
        animTimer = 5, animYTrans = 3,
    }
    local marioObject = {
        oPosX = 10 + index, oPosY = 20, oPosZ = 30,
        oFaceAnglePitch = 1, oFaceAngleYaw = 0x4000, oFaceAngleRoll = 2,
        oMoveAnglePitch = 0, oMoveAngleYaw = 0x4000, oMoveAngleRoll = 0,
        oAnimations = { name = "mario-player-animations" },
        oAnimState = 3,
        header = { gfx = { animInfo = anim, scale = { x = 1.1, y = 1.2, z = 1.3 }, shadowInvisible = false } },
    }
    return {
        playerIndex = index,
        pos = { x = 10 + index, y = 20, z = 30 },
        vel = { x = 1, y = 2, z = 3 },
        faceAngle = { x = 1, y = 0x4000, z = 2 },
        action = 0x200,
        actionArg = 4,
        forwardVel = 5,
        floorHeight = 19,
        health = 0x880,
        marioBodyState = { modelState = 7, headPos = { x = 11, y = 45, z = 31 } },
        marioObj = marioObject,
    }
end

gMarioStates = {}
gNetworkPlayers = {
    [0] = { globalIndex = 0 },
    [1] = { globalIndex = 2 },
}
dofile("proxy.lua")

assert(SteveCraft.proxy ~= nil, "proxy module was not created")
local proxy = SteveCraft.proxy
local localMario = make_mario(0, 0)
gMarioStates[0] = localMario

assert(proxy.update(localMario, 123) == true, "local proxy failed to attach")
assert(proxy.is_attached(0), "local visual object is missing")
assert(proxy.owns_mario_state(localMario), "MarioState is not registered as authority")
assert(localMario.marioBodyState.modelState == 0x100, "native Mario body was not hidden with zero alpha")

local visual = proxy.get_visual_object(0)
assert(visual ~= nil, "Steve render object was not created")
assert(visual.globalPlayerIndex == 0, "local global player index was not copied")
assert(visual.oInteractType == 0, "visual object has interactions enabled")
assert(visual.oIntangibleTimer == -1, "visual object is not intangible")
assert(visual.oPosX == 10 and visual.oPosY == 20 and visual.oPosZ == 30, "initial transform mismatch")
assert(localMario.marioObj.header.gfx.shadowInvisible == true, "native Mario shadow was not hidden")
assert(visual.header.gfx.shadowInvisible == true, "detached Steve shadow was not hidden")
assert(visual.header.gfx.animInfo.animID == 12, "animation ID was not copied")
assert(visual.header.gfx.animInfo.animFrame == 8, "animation frame was not copied")
assert(visual.oAnimations == localMario.marioObj.oAnimations, "animation table was not copied")

local state = proxy.get_state(0)
assert(state ~= nil and state.position.x == 10, "physics snapshot missing")
assert(state.velocity.y == 2 and state.isAirborne == true, "velocity/action snapshot incorrect")
assert(state.headPosition.y == 45, "head position was not captured")

localMario.pos.x = 88
localMario.vel.y = 9
-- The old Mario object may still have a previous-frame transform. Steve must
-- use MarioState's independent controller position, not this stale object value.
localMario.marioObj.oPosX = 99
localMario.marioObj.header.gfx.animInfo.animFrame = 9
assert(proxy.update(localMario, 123) == true, "proxy update failed")
assert(proxy.get_visual_object(0) == visual, "proxy recreated the visual unnecessarily")
assert(visual.oPosX == 88, "visual did not follow MarioState's independent position")
assert(localMario.marioObj.header.gfx.shadowInvisible == true, "native Mario shadow reappeared")
assert(visual.header.gfx.shadowInvisible == true, "detached Steve shadow reappeared")
assert(visual.header.gfx.animInfo.animFrame == 9, "animation frame did not track Mario")
assert(proxy.get_state(0).position.x == 88, "physics snapshot did not refresh")

firstPerson = true
activeObject = visual
behavior.loop(visual)
assert(visual.hidden == true, "local Steve body should hide in first person")
firstPerson = false
behavior.loop(visual)
assert(visual.hidden == false, "local Steve body should show in third person")

local remoteMario = make_mario(1, 2)
gMarioStates[1] = remoteMario
assert(proxy.update(remoteMario, 123) == true, "remote proxy failed to attach")
local remoteVisual = proxy.get_visual_object(1)
assert(remoteVisual ~= nil, "remote Steve object was not created")
assert(remoteVisual.globalPlayerIndex == 2, "remote global player index was not copied")
assert(remoteMario.marioBodyState.modelState == 0x100, "remote native Mario body was not hidden")

proxy.destroy(1)
assert(remoteVisual.deleted == true, "destroy did not delete remote visual")
assert(not proxy.is_attached(1), "destroy left the remote proxy attached")
assert(remoteMario.marioBodyState.modelState == 7, "destroy did not restore native body state")
assert(remoteMario.marioObj.header.gfx.shadowInvisible == false, "destroy did not restore native shadow visibility")

proxy.reset()
assert(visual.deleted == true, "reset did not delete local visual")
assert(not proxy.is_attached(0), "reset left local proxy attached")
assert(localMario.marioBodyState.modelState == 7, "reset did not restore native body state")
assert(localMario.marioObj.header.gfx.shadowInvisible == false, "reset did not restore native shadow visibility")

print("SteveCraft proxy tests passed.")
