local hooks,spawned,surfaces={},{},{}
local nextHit,behavior=nil,nil
OBJ_LIST_GENACTOR=1
OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE=0x100
E_MODEL_TTC_PUSH_BLOCK=243
SURFACE_DEFAULT=0
R_TRIG=0x20
L_TRIG=0x40
HOOK_MARIO_UPDATE="mario"
HOOK_ON_OBJECT_UNLOAD="unload"
HOOK_ON_LEVEL_INIT="level"
gLakituState={curPos={x=0,y=100,z=0},curFocus={x=0,y=100,z=-100}}
gMarioStates={[0]={playerIndex=0,controller={buttonPressed=0}}}
function print() end
function hook_event(n,f) hooks[n]=f end
function hook_chat_command() end
function djui_chat_message_create() end
function hook_behavior(_,_,_,init,loop,name) behavior={init=init,loop=loop,name=name}; return 700 end
function obj_scale_xyz(o,x,y,z) o.testScale={x=x,y=y,z=z} end
function spawn_sync_object(id,model,x,y,z,setup)
 local o={behaviorId=id,modelId=model,oPosX=x,oPosY=y,oPosZ=z,oAction=0,oFlags=0}
 behavior.init(o); setup(o); spawned[#spawned+1]=o; return o
end
function collision_find_surface_on_ray() return nextHit end
function smlua_collision_add_surface(dynamic,kind,a,b,c)
 local s={dynamic=dynamic,type=kind,vertex1=a,vertex2=b,vertex3=c,normal={x=0,y=1,z=0}}
 surfaces[#surfaces+1]=s; return s
end
function smlua_collision_delete_surface(s) s.deleted=true end
dofile("blocks.lua")
assert(SteveCraft.blocks.enabled and behavior,"block module did not initialize")
assert(SteveCraft.blocks.get_count(1)==64,"initial stack is not 64")
nextHit={hitPos={x=90,y=0,z=0},surface={normal={x=0,y=1,z=0}}}
assert(SteveCraft.blocks.place_from_camera(gMarioStates[0]),"first placement failed")
behavior.loop(spawned[1])
local function active_surfaces()
 local n=0; for _,s in ipairs(surfaces) do if not s.deleted then n=n+1 end end; return n
end
assert(active_surfaces()==12,"isolated block should have 12 triangles")
local top=surfaces[1]
nextHit={hitPos={x=90,y=45,z=0},surface=top}
assert(SteveCraft.blocks.place_from_camera(gMarioStates[0]),"stack placement failed")
behavior.loop(spawned[2])
assert(active_surfaces()==20,"stacked blocks should omit their shared internal face")
assert(SteveCraft.blocks.get_count(1)==62,"two placements must consume two blocks")
local count=#spawned
gMarioStates[0].controller.buttonPressed=R_TRIG
hooks[HOOK_MARIO_UPDATE](gMarioStates[0])
assert(#spawned==count+1,"R trigger did not request placement")
print("SteveCraft block placement tests passed.")
