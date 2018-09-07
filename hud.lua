local lg = love.graphics
local hud_notif = ""
local hud_notif_fade_out = true
local hud_notif_alpha = 2

function set_notif(str)
    if str == nil then error("Notification can't be nil") end
    hud_notif = str
    hud_notif_alpha = 2

    return true
end

function update_hud(dt)
    if hud_notif_fade_out then
        hud_notif_alpha = math.max(hud_notif_alpha - dt, 0)
    end
end

function draw_hud()
    lg.setFont(hudFont)
    preventAttack = false

    for index, item in pairs(entities.entities[playerUUID].inventory) do
        if item ~= nil then
            local x = (index - ((#ply.inventory + 1) / 2)) * 64 + window_width / 2
            if entities.entities[playerUUID].selectedSlot == index then
                lg.setColor(0, 1, 0, .5)
            else
                lg.setColor(1, 1, 1, .5)
            end
            local startx, starty = x - 24, window_height - 64

            lg.rectangle("fill", startx, starty, 48, 48, 5)
            lg.setColor(0, 0, 0)
            lg.setLineWidth(3)
            lg.rectangle("line", startx, starty, 48, 48, 5)
            lg.setColor(1, 1, 1)
            lg.print(lang.print(item), startx, starty + 48)

            if images.weapons.side[item] then lg.draw(images.weapons.side[item], startx + 8, starty + 8) end

            if inSquare(mx, my, startx, starty, 48, 48) then
                dotCursor = true
                if love.mouse.isDown(1) then
                    ply:setSlot(index)
                end
                preventAttack = true
            end
        end
    end

    for index, skill in pairs(ply.boostedSkills) do
        local x = window_width - index * 64
        lg.setColor(1, 1, 1, .5)
        lg.rectangle("fill", x, 16, 48, 48, 5)
        lg.setColor(0, 0, 0)
        lg.setLineWidth(3)
        lg.rectangle("line", x, 16, 48, 48, 5)

        lg.print(lang.print(skill.name), x, 16)
        lg.print("+" .. skill.amount, x, 32)
    end

    if config.debug then lg.print("Framerate: " .. love.timer.getFPS(), 5, 59) end

    -- cooldown bar
    lg.setLineWidth(1)
    lg.setColor(1, 1, 1)
    local wep = ply:getWeapon()
    if wep then maxCooldown = (ply.enable_burst and wep.cooldown * 1.5) or wep.cooldown
    else maxCooldown = 1 end
    local percentage = math.min(ply.cooldown.attack / maxCooldown * 100, 100)

    lg.line(mx - 20, my + 24, (mx - 20) + percentage / 100 * 40, my + 24)

    -- health bar
    lg.setLineWidth(3) -- make a bigger line for stats bars

    local health, maxHealth = ply:getHealth()
    local percentage = health / maxHealth * 200
    lg.setColor(1, 0, 0)
    sharpRectangle("fill", 4, 4, percentage, 24, 200)

    -- draw border
    lg.setColor(0, 0, 0)
    lg.rectangle("line", 5, 5, 200, 24, 5)

    -- draw percentage text
    lg.setColor(1, 1, 1)
    local text = lang.print("hp", {math.max(round(health, 1), 0)})
    lg.print(text, (4 + 200 - hudFont:getWidth(text)) / 2, 24 - hudFont:getHeight(text))

    -- stamina bar
    lg.setColor(0, 0, 1)
    local percentage = (ply.skills.stamina - ply.cooldown.sprint) / ply.skills.stamina * 200
    sharpRectangle("fill", 4, 36, percentage, 24, 200)

    -- draw border
    lg.setColor(0, 0, 0)
    lg.rectangle("line", 5, 36, 200, 24, 5)

    -- draw percentage text
    lg.setColor(1, 1, 1)
    local percentage = round(percentage / 2, 0) .. "%"
    lg.print(percentage, (4 + 200 - hudFont:getWidth(percentage)) / 2, 34 + round((24 - hudFont:getHeight(percentage) / 1.5) / 2, 0))

    -- score bar
    local percentage = math.min(ply.score / ply.highScore * 300, 300)
    local x = window_width / 2 - 300 / 2
    lg.setColor(0.3, 0.4, 0.45)
    sharpRectangle("fill", x, 4, percentage, 24, 300)

    -- draw border
    lg.setColor(0, 0, 0)
    lg.rectangle("line", x, 4, 300, 24, 5)

    -- draw percentage text
    lg.setColor(1, 1, 1)
    if percentage < 300 then
        percentage = lang.print("score", {round(ply.score, 0)})
    else
        percentage = lang.print("new score", {round(ply.score, 0)})
    end
    lg.print(percentage, window_width / 2 - hudFont:getWidth(percentage) / 2, 2 + round((24 - hudFont:getHeight(percentage) / 1.5) / 2, 0))

    lg.setLineWidth(0) -- reset line size

    -- kills and level
    lg.setColor(1, 1, 1)
    lg.draw(images.skull, 5, 64)
    lg.print(ply.kills, 32, 68)
    lg.draw(images.level, 64, 64)
    lg.print(round(ply:getLevel(), 1), 96, 68)

    console.draw()
end

function notif_hud()
    -- notification message
    if hud_notif ~= "" then
        text = lang.print(unpack(hud_notif))

        lg.setFont(menuFont)
        lg.setColor(1, 1, 1, hud_notif_alpha)
        lg.print(text, window_width / 2 - round(menuFont:getWidth(text) / 2, 0), window_height / 2 + window_height / 4, 0)
    end
end