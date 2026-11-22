-- SteveCraft 64 - Minecraft-inspired HUD
--
-- Uses the supported DJUI HUD drawing API. The native Mario HUD is hidden
-- while this mod HUD is enabled. The hotbar is visual-only for now: it will
-- be connected to blocks.lua when block/item storage is implemented.

SteveCraft = SteveCraft or {}

SteveCraft.hud = SteveCraft.hud or {
    enabled = true,
    inventoryOpen = false,
    selectedSlot = 1,
}

local hud = SteveCraft.hud
local SLOT_COUNT = 9
local INVENTORY_ROWS = 4
local INVENTORY_COLUMNS = 9

local function draw_rect(x, y, width, height, r, g, b, a)
    djui_hud_set_color(r, g, b, a)
    djui_hud_render_rect(x, y, width, height)
end

local function draw_text(text, x, y, scale, r, g, b, a)
    djui_hud_set_color(r, g, b, a)
    djui_hud_print_text(text, x, y, scale)
end

local function draw_slot(x, y, width, height, selected)
    if selected then
        draw_rect(x - 2, y - 2, width + 4, height + 4, 245, 245, 245, 255)
        draw_rect(x - 1, y - 1, width + 2, height + 2, 35, 35, 35, 255)
    else
        draw_rect(x - 1, y - 1, width + 2, height + 2, 18, 18, 18, 230)
    end

    draw_rect(x, y, width, height, 94, 94, 94, 225)
    draw_rect(x + 1, y + 1, width - 2, height - 2, 48, 48, 48, 235)
end

local function health_to_half_hearts(health)
    if health == nil then return 20 end

    -- SM64CoopDX uses 0x880 as full health and 0xFF as its lowest living
    -- health value. Convert that range into 20 Minecraft half-heart units.
    local normalized = (health - 0xFF) / (0x880 - 0xFF)
    normalized = math.max(0, math.min(1, normalized))
    return math.floor(normalized * 20 + 0.5)
end

local HEART_ROWS = {
    { 0, 1, 0, 0, 1, 0, 0 },
    { 1, 1, 1, 0, 1, 1, 1 },
    { 1, 1, 1, 1, 1, 1, 1 },
    { 0, 1, 1, 1, 1, 1, 0 },
    { 0, 0, 1, 1, 1, 0, 0 },
    { 0, 0, 0, 1, 0, 0, 0 },
}

local function draw_hearts(m, screenWidth, screenHeight)
    local halfHearts = health_to_half_hearts(m and m.health)
    local pixel = 1
    local heartWidth = 7
    local heartGap = 2
    local totalWidth = 10 * heartWidth + 9 * heartGap
    local startX = math.floor((screenWidth - totalWidth) / 2)
    local y = screenHeight - 43

    for heart = 0, 9 do
        local remaining = halfHearts - heart * 2
        local fill = math.max(0, math.min(2, remaining))
        local x = startX + heart * (heartWidth + heartGap)

        for row = 1, #HEART_ROWS do
            for col = 1, #HEART_ROWS[row] do
                if HEART_ROWS[row][col] == 1 then
                    local colorR, colorG, colorB = 72, 72, 72

                    if fill == 2 then
                        colorR, colorG, colorB = 220, 35, 45
                    elseif fill == 1 and col <= 4 then
                        colorR, colorG, colorB = 220, 35, 45
                    end

                    draw_rect(
                        x + (col - 1) * pixel,
                        y + (row - 1) * pixel,
                        pixel,
                        pixel,
                        colorR,
                        colorG,
                        colorB,
                        255
                    )
                end
            end
        end
    end
end

local function draw_hotbar(screenWidth, screenHeight)
    local slotWidth = 18
    local slotHeight = 18
    local gap = 2
    local totalWidth = SLOT_COUNT * slotWidth + (SLOT_COUNT - 1) * gap
    local startX = math.floor((screenWidth - totalWidth) / 2)
    local y = screenHeight - 25

    draw_rect(startX - 5, y - 5, totalWidth + 10, slotHeight + 10, 0, 0, 0, 155)
    draw_rect(startX - 4, y - 4, totalWidth + 8, slotHeight + 8, 92, 92, 92, 230)

    for slot = 1, SLOT_COUNT do
        local x = startX + (slot - 1) * (slotWidth + gap)
        draw_slot(x, y, slotWidth, slotHeight, slot == hud.selectedSlot)
        draw_text(tostring(slot), x + 2, y + 1, 0.35, 220, 220, 220, 255)
    end
end

local function draw_crosshair(screenWidth, screenHeight)
    if not get_first_person_enabled() then return end

    local centerX = math.floor(screenWidth / 2)
    local centerY = math.floor(screenHeight / 2)

    -- Black outline keeps the crosshair readable against bright and dark areas.
    draw_rect(centerX - 1, centerY - 5, 3, 11, 0, 0, 0, 220)
    draw_rect(centerX - 5, centerY - 1, 11, 3, 0, 0, 0, 220)

    draw_rect(centerX, centerY - 4, 1, 9, 245, 245, 245, 255)
    draw_rect(centerX - 4, centerY, 9, 1, 245, 245, 245, 255)
end

local function draw_inventory(screenWidth, screenHeight)
    if not hud.inventoryOpen then return end

    local panelWidth = 174
    local panelHeight = 94
    local panelX = math.floor((screenWidth - panelWidth) / 2)
    local panelY = math.floor((screenHeight - panelHeight) / 2)

    draw_rect(0, 0, screenWidth, screenHeight, 0, 0, 0, 145)
    draw_rect(panelX, panelY, panelWidth, panelHeight, 15, 15, 15, 245)
    draw_rect(panelX + 1, panelY + 1, panelWidth - 2, panelHeight - 2, 72, 72, 72, 255)
    draw_rect(panelX + 3, panelY + 3, panelWidth - 6, panelHeight - 6, 28, 28, 28, 255)

    draw_text("INVENTORY", panelX + 8, panelY + 5, 0.65, 235, 235, 235, 255)

    local slotWidth = 14
    local slotHeight = 14
    local gap = 3
    local gridX = panelX + 10
    local gridY = panelY + 22

    for row = 1, INVENTORY_ROWS do
        for column = 1, INVENTORY_COLUMNS do
            local slot = (row - 1) * INVENTORY_COLUMNS + column
            local x = gridX + (column - 1) * (slotWidth + gap)
            local y = gridY + (row - 1) * (slotHeight + gap)
            local selected = row == INVENTORY_ROWS and column == hud.selectedSlot

            draw_slot(x, y, slotWidth, slotHeight, selected)
        end
    end
end

local function on_mario_update(m)
    if m == nil or m.playerIndex ~= 0 or not hud.enabled then return end
    if m.controller == nil then return end

    local pressed = m.controller.buttonPressed or 0

    if (pressed & L_TRIG) ~= 0 then
        hud.selectedSlot = hud.selectedSlot - 1
        if hud.selectedSlot < 1 then hud.selectedSlot = SLOT_COUNT end
    elseif (pressed & R_TRIG) ~= 0 then
        hud.selectedSlot = hud.selectedSlot + 1
        if hud.selectedSlot > SLOT_COUNT then hud.selectedSlot = 1 end
    end
end

local function on_hud_render()
    if not hud.enabled then return end

    local m = gMarioStates[0]
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_MENU)
    djui_hud_set_filter(FILTER_NEAREST)

    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()

    draw_hearts(m, screenWidth, screenHeight)
    draw_hotbar(screenWidth, screenHeight)

    if hud.inventoryOpen then
        draw_inventory(screenWidth, screenHeight)
    else
        draw_crosshair(screenWidth, screenHeight)
    end

    djui_hud_reset_color()
end

local function toggle_inventory(message)
    if message == "open" then
        hud.inventoryOpen = true
    elseif message == "close" then
        hud.inventoryOpen = false
    else
        hud.inventoryOpen = not hud.inventoryOpen
    end

    djui_chat_message_create(hud.inventoryOpen and "SteveCraft: inventory open" or "SteveCraft: inventory closed")
    return true
end

local function toggle_hud(message)
    if message == "on" then
        hud.enabled = true
    elseif message == "off" then
        hud.enabled = false
    else
        hud.enabled = not hud.enabled
    end

    if hud.enabled then
        hud_hide()
    else
        hud_show()
    end

    djui_chat_message_create(hud.enabled and "SteveCraft HUD enabled" or "SteveCraft HUD disabled")
    return true
end

hud_hide()
hook_event(HOOK_MARIO_UPDATE, on_mario_update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_chat_command("steveinv", "[open|close] toggle the SteveCraft inventory panel", toggle_inventory)
hook_chat_command("stevehud", "[on|off] toggle the SteveCraft HUD", toggle_hud)

print("[SteveCraft 64] Minecraft-inspired HUD loaded.")
