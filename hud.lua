-- SteveCraft 64: responsive Minecraft-style HUD using native DJUI primitives.
-- The engine's Android A/B/X/Y/L/R touch controls are separate and remain visible.

SteveCraft = SteveCraft or {}
SteveCraft.hud = SteveCraft.hud or {enabled=true,inventoryOpen=false}
local hud=SteveCraft.hud
local HEARTS={"01100110","11111111","11111111","11111111","01111110","00111100","00011000"}

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function rect(x,y,w,h,r,g,b,a)
    if w<=0 or h<=0 then return end
    djui_hud_set_color(r,g,b,a); djui_hud_render_rect(x,y,w,h)
end
local function label(s,x,y,scale,r,g,b,a)
    djui_hud_set_color(r,g,b,a); djui_hud_print_text(tostring(s),x,y,scale)
end

local function draw_slot(x,y,size,selected)
    rect(x-2,y-2,size+4,size+4,5,5,5,255)
    rect(x-1,y-1,size+2,size+2,112,112,112,255)
    rect(x,y,size,size,45,45,45,255)
    rect(x+3,y+3,size-6,size-6,30,30,30,255)
    if selected then
        rect(x-4,y-4,size+8,2,250,250,250,255)
        rect(x-4,y+size+2,size+8,2,250,250,250,255)
        rect(x-4,y-2,2,size+4,250,250,250,255)
        rect(x+size+2,y-2,2,size+4,250,250,250,255)
    end
end

local function draw_stone(x,y,size)
    local u=math.max(2,math.floor(size/12))
    local l,t=x+u*2,y+u*2
    local w,h=size-u*4,size-u*4
    rect(l,t,w,h,145,145,145,255)
    rect(l,t,w,u,192,192,192,255)
    rect(l,t,u,h,168,168,168,255)
    rect(l+w-u,t,u,h,79,79,79,255)
    rect(l,t+h-u,w,u,72,72,72,255)
    rect(l+u*2,t+u*2,u*2,u,105,105,105,255)
    rect(l+u*6,t+u*3,u*2,u*2,117,117,117,255)
    rect(l+u*3,t+u*6,u*3,u,94,94,94,255)
end

local function draw_count(n,x,y,s)
    if n==nil or n<=1 then return end
    label(n,x+1,y+1,s,0,0,0,255); label(n,x,y,s,255,255,255,255)
end

local function draw_hearts(width,y,scale)
    local pixel=math.max(2,math.floor(2*scale))
    local hw=8*pixel
    local gap=math.max(3,math.floor(4*scale))
    local total=10*hw+9*gap
    local x0=math.floor((width-total)/2)
    local m=gMarioStates and gMarioStates[0]
    local health=m and m.health or 0x880
    local half=math.floor(clamp((health-0xFF)/(0x880-0xFF),0,1)*20+0.5)
    for heart=0,9 do
        local fill=clamp(half-heart*2,0,2)
        local x=x0+heart*(hw+gap)
        for row=1,#HEARTS do
            for col=1,8 do
                if HEARTS[row]:sub(col,col)=="1" then
                    local full=fill==2 or (fill==1 and col<=4)
                    rect(x+(col-1)*pixel,y+(row-1)*pixel,pixel,pixel,
                        full and 220 or 70,full and 35 or 70,full and 45 or 70,255)
                end
            end
        end
    end
end

local function draw_hotbar(width,height,scale,slotSize,gap)
    local pad=math.max(4,math.floor(6*scale))
    local content=9*slotSize+8*gap
    local bw,bh=content+pad*2,slotSize+pad*2
    local margin=math.max(74,math.floor(height*0.12))
    local x,y=math.floor((width-bw)/2),height-bh-margin
    rect(x-3,y-3,bw+6,bh+6,0,0,0,225)
    rect(x-1,y-1,bw+2,bh+2,132,132,132,255)
    rect(x,y,bw,bh,27,27,27,255)
    local b=SteveCraft.blocks
    for i=1,9 do
        local sx=x+pad+(i-1)*(slotSize+gap)
        local sy=y+pad
        draw_slot(sx,sy,slotSize,b and i==b.selectedSlot)
        local slot=b and b.get_slot and b.get_slot(i)
        if slot and slot.count>0 then
            draw_stone(sx,sy,slotSize)
            draw_count(slot.count,sx+slotSize-math.floor(13*scale),
                sy+slotSize-math.floor(14*scale),0.7*scale)
        end
    end
    return y
end

local function draw_crosshair(width,height,scale)
    local cx,cy=math.floor(width/2),math.floor(height/2)
    local arm=math.max(5,math.floor(7*scale))
    local thick=math.max(2,math.floor(2*scale))
    rect(cx-thick,cy-arm-1,thick*2,arm*2+2,0,0,0,230)
    rect(cx-arm-1,cy-thick,arm*2+2,thick*2,0,0,0,230)
    rect(cx-1,cy-arm,2,arm*2,245,245,245,255)
    rect(cx-arm,cy-1,arm*2,2,245,245,245,255)
end

local function draw_inventory(width,height,scale,slotSize,gap)
    if not hud.inventoryOpen then return end
    local pad=math.floor(14*scale)
    local title=math.floor(32*scale)
    local gw=9*slotSize+8*gap
    local gh=4*slotSize+3*gap
    local pw,ph=gw+pad*2,gh+pad*2+title
    local x,y=math.floor((width-pw)/2),math.floor((height-ph)/2)
    rect(0,0,width,height,0,0,0,145)
    rect(x,y,pw,ph,8,8,8,255)
    rect(x+2,y+2,pw-4,ph-4,118,118,118,255)
    rect(x+5,y+5,pw-10,ph-10,32,32,32,255)
    label("Inventory",x+pad,y+math.floor(7*scale),0.9*scale,245,245,245,255)
    local b=SteveCraft.blocks
    for row=1,4 do
        for col=1,9 do
            local i=(row-1)*9+col
            local sx=x+pad+(col-1)*(slotSize+gap)
            local sy=y+pad+title+(row-1)*(slotSize+gap)
            local slot=(row==4 and b and b.get_slot) and b.get_slot(col) or nil
            draw_slot(sx,sy,slotSize,row==4 and b and col==b.selectedSlot)
            if slot and slot.count>0 then
                draw_stone(sx,sy,slotSize)
                draw_count(slot.count,sx+slotSize-math.floor(13*scale),
                    sy+slotSize-math.floor(14*scale),0.7*scale)
            end
        end
    end
end

local function on_mario_update(m)
    if not hud.enabled or m==nil or m.playerIndex~=0 or m.controller==nil then return end
    local pressed=m.controller.buttonPressed or 0
    if L_TRIG~=nil and (pressed & L_TRIG)~=0 then
        if SteveCraft.blocks and SteveCraft.blocks.select_next_slot then
            SteveCraft.blocks.select_next_slot()
        end
    end
end

local function on_hud_render()
    if not hud.enabled then return end
    djui_hud_set_resolution(RESOLUTION_DJUI)
    djui_hud_set_font(FONT_HUD or FONT_MENU)
    djui_hud_set_filter(FILTER_NEAREST)
    local w,h=djui_hud_get_screen_width(),djui_hud_get_screen_height()
    local scale=clamp(math.min(w/800,h/480),0.5,1.15)
    local slotSize=math.max(24,math.floor(48*scale))
    local gap=math.max(2,math.floor(4*scale))
    local barY=draw_hotbar(w,h,scale,slotSize,gap)
    draw_hearts(w,barY-math.max(23,math.floor(29*scale)),scale)
    draw_crosshair(w,h,scale)
    draw_inventory(w,h,scale,slotSize,gap)
    djui_hud_reset_color()
end

local function toggle_inventory(message)
    if message=="open" then hud.inventoryOpen=true
    elseif message=="close" then hud.inventoryOpen=false
    else hud.inventoryOpen=not hud.inventoryOpen end
    return true
end

local function toggle_hud(message)
    if message=="on" then hud.enabled=true
    elseif message=="off" then hud.enabled=false
    else hud.enabled=not hud.enabled end
    if hud.enabled then hud_hide() else hud_show() end
    return true
end

hud_hide()
hook_event(HOOK_MARIO_UPDATE,on_mario_update)
hook_event(HOOK_ON_HUD_RENDER,on_hud_render)
hook_chat_command("steveinv","[open|close] toggle Minecraft-style inventory",toggle_inventory)
hook_chat_command("stevehud","[on|off] toggle the SteveCraft HUD",toggle_hud)
print("[SteveCraft] Responsive DJUI HUD loaded.")
