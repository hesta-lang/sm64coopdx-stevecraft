-- SteveCraft 64: placeable, synchronized stone blocks.
-- No block-breaking or level/environment destruction is implemented here.

SteveCraft = SteveCraft or {}
SteveCraft.blocks = SteveCraft.blocks or {}
local blocks = SteveCraft.blocks

blocks.enabled = true
blocks.blockSize = 90.0
blocks.reach = 450.0
blocks.selectedSlot = blocks.selectedSlot or 1
blocks.slots = blocks.slots or {}

local SIZE, HALF, VISUAL_SCALE = blocks.blockSize, blocks.blockSize * 0.5, 0.90
local MODEL = E_MODEL_TTC_PUSH_BLOCK or E_MODEL_METAL_BOX or E_MODEL_BREAKABLE_BOX
local SURFACE = SURFACE_DEFAULT or 0
local behaviorId
local blocksByKey, blockByObject, surfaceOwner = {}, {}, {}
local warned = false

for i = 1, 9 do
    if blocks.slots[i] == nil then
        blocks.slots[i] = { id = "stone", name = "Stone", count = 64 }
    end
end

local faces = {
    { dx=0, dy=1, dz=0, verts=function(x0,y0,z0,x1,y1,z1)
        return {{x0,y1,z0},{x0,y1,z1},{x1,y1,z1},{x1,y1,z0}} end },
    { dx=0, dy=-1, dz=0, verts=function(x0,y0,z0,x1,y1,z1)
        return {{x0,y0,z1},{x0,y0,z0},{x1,y0,z0},{x1,y0,z1}} end },
    { dx=0, dy=0, dz=1, verts=function(x0,y0,z0,x1,y1,z1)
        return {{x0,y0,z1},{x1,y0,z1},{x1,y1,z1},{x0,y1,z1}} end },
    { dx=0, dy=0, dz=-1, verts=function(x0,y0,z0,x1,y1,z1)
        return {{x1,y0,z0},{x0,y0,z0},{x0,y1,z0},{x1,y1,z0}} end },
    { dx=1, dy=0, dz=0, verts=function(x0,y0,z0,x1,y1,z1)
        return {{x1,y0,z1},{x1,y0,z0},{x1,y1,z0},{x1,y1,z1}} end },
    { dx=-1, dy=0, dz=0, verts=function(x0,y0,z0,x1,y1,z1)
        return {{x0,y0,z0},{x0,y0,z1},{x0,y1,z1},{x0,y1,z0}} end }
}

local function q(n) return math.floor(n * 100 + 0.5) / 100 end
local function key(x,y,z) return string.format("%.2f|%.2f|%.2f", q(x),q(y),q(z)) end
local function chat(s)
    if type(djui_chat_message_create) == "function" then
        djui_chat_message_create("[SteveCraft] " .. s)
    end
end

function blocks.get_slot(i)
    return blocks.slots[i or blocks.selectedSlot]
end
function blocks.get_count(i)
    local s = blocks.get_slot(i)
    return s and s.count or 0
end
function blocks.select_next_slot()
    blocks.selectedSlot = (blocks.selectedSlot % 9) + 1
    return blocks.selectedSlot
end

local function vec3s(x,y,z)
    local function cv(v)
        local n = math.floor(v + 0.5)
        if n < -32768 or n > 32767 then return nil end
        return n
    end
    local a,b,c = cv(x),cv(y),cv(z)
    if a == nil or b == nil or c == nil then return nil end
    return {x=a,y=b,z=c}
end

local function clear_surfaces(block)
    for _,s in ipairs(block.surfaces or {}) do
        surfaceOwner[s] = nil
        if type(smlua_collision_delete_surface) == "function" then
            pcall(smlua_collision_delete_surface, s)
        end
    end
    block.surfaces = {}
end

local function add_triangle(block,a,b,c)
    local va,vb,vc = vec3s(a[1],a[2],a[3]),vec3s(b[1],b[2],b[3]),vec3s(c[1],c[2],c[3])
    if va == nil or vb == nil or vc == nil then return end
    local ok,s = pcall(smlua_collision_add_surface,false,SURFACE,va,vb,vc)
    if ok and s ~= nil then
        block.surfaces[#block.surfaces+1] = s
        surfaceOwner[s] = block
    end
end

local function has_block(x,y,z)
    return blocksByKey[key(x,y,z)] ~= nil
end

local function rebuild(block)
    clear_surfaces(block)
    local c = block.center
    local x0,y0,z0 = c.x-HALF,c.y-HALF,c.z-HALF
    local x1,y1,z1 = c.x+HALF,c.y+HALF,c.z+HALF

    for _,f in ipairs(faces) do
        if not has_block(c.x+f.dx*SIZE,c.y+f.dy*SIZE,c.z+f.dz*SIZE) then
            local v = f.verts(x0,y0,z0,x1,y1,z1)
            add_triangle(block,v[1],v[2],v[3])
            add_triangle(block,v[1],v[3],v[4])
        end
    end
end

local function rebuild_neighbours(block)
    for _,f in ipairs(faces) do
        local n = blocksByKey[key(
            block.center.x+f.dx*SIZE,
            block.center.y+f.dy*SIZE,
            block.center.z+f.dz*SIZE
        )]
        if n ~= nil then rebuild(n) end
    end
end

local function register_block(o)
    local c = {x=q(o.oPosX or 0),y=q(o.oPosY or 0),z=q(o.oPosZ or 0)}
    local k = key(c.x,c.y,c.z)
    if blocksByKey[k] ~= nil then return blocksByKey[k] end
    local b = {object=o,key=k,center=c,surfaces={}}
    blocksByKey[k],blockByObject[o] = b,b
    rebuild(b)
    rebuild_neighbours(b)
    return b
end

local function unregister_block(o)
    local b = blockByObject[o]
    if b == nil then return end
    blocksByKey[b.key] = nil
    clear_surfaces(b)
    blockByObject[o] = nil
    rebuild_neighbours(b)
end

local function reset_collision()
    for _,b in pairs(blocksByKey) do clear_surfaces(b) end
    blocksByKey,blockByObject,surfaceOwner = {},{},{}
end

local function block_init(o)
    o.oFlags = (o.oFlags or 0) | (OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE or 0)
    o.oInteractType = 0
    o.oIntangibleTimer = -1
    o.oGravity = 0
    o.oWallHitboxRadius = 0
    o.oOpacity = 255
    o.oDrawingDistance = 5000
    o.oAction = 0
    obj_scale_xyz(o,VISUAL_SCALE,VISUAL_SCALE,VISUAL_SCALE)
end

local function block_loop(o)
    if o == nil or o.oAction ~= 0 then return end
    register_block(o)
    o.oAction = 1
end

if type(hook_behavior) == "function" and OBJ_LIST_GENACTOR ~= nil
    and type(obj_scale_xyz) == "function"
    and type(smlua_collision_add_surface) == "function" then
    behaviorId = hook_behavior(nil,OBJ_LIST_GENACTOR,true,block_init,block_loop,
        "bhvSteveCraftPlacedBlock")
end

local function camera_ray(m)
    local c = gLakituState
    if c and c.curPos and c.curFocus then
        local p,f = c.curPos,c.curFocus
        local dx,dy,dz = f.x-p.x,f.y-p.y,f.z-p.z
        local len = math.sqrt(dx*dx+dy*dy+dz*dz)
        if len > 0.001 then
            return p,{x=dx/len*blocks.reach,y=dy/len*blocks.reach,z=dz/len*blocks.reach}
        end
    end
    local fp = gFirstPersonCamera
    local head = m and m.marioBodyState and m.marioBodyState.headPos
    if fp and head then
        local yaw,pitch = (fp.yaw or 0)*math.pi/32768,(fp.pitch or 0)*math.pi/32768
        local cp = math.cos(pitch)
        return head,{
            x=-math.sin(yaw)*cp*blocks.reach,
            y=math.sin(pitch)*blocks.reach,
            z=-math.cos(yaw)*cp*blocks.reach
        }
    end
    return nil,nil
end

local function get_axis_normal(surface)
    local n = surface and surface.normal
    if n == nil then return nil,nil end
    local ax,ay,az = math.abs(n.x or 0),math.abs(n.y or 0),math.abs(n.z or 0)
    if math.max(ax,ay,az) < 0.1 then return nil,nil end
    if ax >= ay and ax >= az then return {x=n.x>=0 and 1 or -1,y=0,z=0},1 end
    if ay >= ax and ay >= az then return {x=0,y=n.y>=0 and 1 or -1,z=0},2 end
    return {x=0,y=0,z=n.z>=0 and 1 or -1},3
end

local function nearest_step(v) return math.floor(v/SIZE+0.5)*SIZE end

local function get_target_center(hit,normal,axis)
    local source = surfaceOwner[hit.surface]
    if source == nil then
        return {
            x=q(hit.hitPos.x+normal.x*HALF),
            y=q(hit.hitPos.y+normal.y*HALF),
            z=q(hit.hitPos.z+normal.z*HALF)
        }
    end

    local c = {x=source.center.x,y=source.center.y,z=source.center.z}
    if axis ~= 1 then c.x = c.x+nearest_step(hit.hitPos.x-source.center.x) end
    if axis ~= 2 then c.y = c.y+nearest_step(hit.hitPos.y-source.center.y) end
    if axis ~= 3 then c.z = c.z+nearest_step(hit.hitPos.z-source.center.z) end
    c.x,c.y,c.z = q(c.x+normal.x*SIZE),q(c.y+normal.y*SIZE),q(c.z+normal.z*SIZE)
    return c
end

function blocks.place_from_camera(m)
    local slot = blocks.get_slot()
    if slot == nil or slot.count <= 0 then chat("No quedan bloques."); return false end
    if behaviorId == nil or type(spawn_sync_object) ~= "function"
        or type(collision_find_surface_on_ray) ~= "function"
        or type(smlua_collision_add_surface) ~= "function"
        or type(smlua_collision_delete_surface) ~= "function" then
        if not warned then chat("La API de colision/raycast no esta disponible."); warned=true end
        return false
    end

    local origin,direction = camera_ray(m)
    if origin == nil or direction == nil then chat("No se pudo leer la camara."); return false end
    local ok,hit = pcall(collision_find_surface_on_ray,
        origin.x,origin.y,origin.z,direction.x,direction.y,direction.z,2.0)
    if not ok or hit == nil or hit.surface == nil or hit.hitPos == nil then
        chat("No hay una superficie al alcance."); return false
    end

    local normal,axis = get_axis_normal(hit.surface)
    if normal == nil then chat("No se pudo determinar la cara del bloque."); return false end
    local center = get_target_center(hit,normal,axis)
    if blocksByKey[key(center.x,center.y,center.z)] ~= nil then
        chat("Ese espacio ya esta ocupado."); return false
    end
    if MODEL == nil then chat("No hay un modelo de bloque disponible."); return false end

    local object = spawn_sync_object(behaviorId,MODEL,center.x,center.y,center.z,function(o)
        o.oPosX,o.oPosY,o.oPosZ = center.x,center.y,center.z
        o.oFaceAnglePitch,o.oFaceAngleYaw,o.oFaceAngleRoll = 0,0,0
        o.oAction = 0
    end)
    if object == nil then chat("No se pudo crear el bloque."); return false end

    slot.count = slot.count-1
    chat("Piedra colocada: "..tostring(slot.count).." restantes en este espacio.")
    return true
end

local function on_mario_update(m)
    if m == nil or m.playerIndex ~= 0 or m.controller == nil then return end
    local pressed = m.controller.buttonPressed or 0
    if R_TRIG ~= nil and (pressed & R_TRIG) ~= 0 then blocks.place_from_camera(m) end
end

if type(hook_event) == "function" then
    if HOOK_MARIO_UPDATE ~= nil then hook_event(HOOK_MARIO_UPDATE,on_mario_update) end
    if HOOK_ON_OBJECT_UNLOAD ~= nil then hook_event(HOOK_ON_OBJECT_UNLOAD,unregister_block) end
    if HOOK_ON_LEVEL_INIT ~= nil then hook_event(HOOK_ON_LEVEL_INIT,reset_collision) end
end

if type(hook_chat_command) == "function" then
    hook_chat_command("steveplace","Place a stone block at the crosshair (R trigger also places).",
        function() blocks.place_from_camera(gMarioStates and gMarioStates[0] or nil); return true end)
end

function blocks.get_block_count()
    local n=0
    for i=1,9 do n=n+(blocks.slots[i] and blocks.slots[i].count or 0) end
    return n
end

print("[SteveCraft] Synchronized block placement and persistent collision enabled.")
