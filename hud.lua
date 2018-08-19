function hud()
    love.graphics.setFont(hudFont)
    for index, item in pairs(entities.entities[playerUUID].inventory) do
        if item ~= nil then
            local x = (index - ((#ply.inventory + 1) / 2)) * 64 + window_width / 2
            if entities.entities[playerUUID].selectedSlot == index then
                love.graphics.setColor(0, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
            local startx, starty = x - 24, window_height - 64

            love.graphics.draw(images.slot, startx, starty)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(lang.print(item), startx, starty + 48)

            if images.weapons.side[item] then love.graphics.draw(images.weapons.side[item], startx + 8, starty + 8) end

            if inSquare(mx, my, startx, starty, 48, 48) then
                dotCursor = true
                attackIsDown = true
                if love.mouse.isDown(1) then
                    ply:setSlot(index)
                end
            end
        end
    end

    for index, skill in pairs(ply.boostedSkills) do
        local x = window_width - index * 64
        love.graphics.draw(images.slot, x, 16)

        love.graphics.print(lang.print(skill.name), x, 16)
        love.graphics.print("+" .. skill.amount, x, 32)
    end

    if config.debug then love.graphics.print("Framerate: " .. love.timer.getFPS(), 5, 59) end

    if ply:getWeapon() then maxCooldown = ply:getWeapon().cooldown
    else maxCooldown = 1 end
    local percentage = math.min(ply.cooldown.attack / maxCooldown * 100, 100)

    love.graphics.line(mx - 20, my + 24, (mx - 20) + percentage / 100 * 40, my + 24)

    -- health bar
    love.graphics.setLineWidth(3) -- make a bigger line for stats bars

    local health, maxHealth = ply:getHealth()
    local percentage = health / maxHealth * 200
    love.graphics.setColor(1, 0, 0)
    sharpRectangle("fill", 4, 4, percentage, 24, 200)

    -- draw border
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", 5, 5, 200, 24, 5)

    -- draw percentage text
    love.graphics.setColor(1, 1, 1)
    local text = lang.print("hp", {math.max(round(health, 1), 0)})
    love.graphics.print(text, (4 + 200 - hudFont:getWidth(text)) / 2, 24 - hudFont:getHeight(text))

    -- stamina bar
    love.graphics.setColor(0, 0, 1)
    local percentage = (ply.skills.stamina - ply.cooldown.sprint) / ply.skills.stamina * 200
    sharpRectangle("fill", 4, 36, percentage, 24, 200)

    -- draw border
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", 5, 36, 200, 24, 5)

    -- draw percentage text
    love.graphics.setColor(1, 1, 1)
    local percentage = round(percentage / 2, 0) .. "%"
    love.graphics.print(percentage, (4 + 200 - hudFont:getWidth(percentage)) / 2, 34 + round((24 - hudFont:getHeight(percentage) / 1.5) / 2, 0))

    -- score bar
    local percentage = ply.score / ply.highScore * 300
    local x = window_width / 2 - 300 / 2
    love.graphics.setColor(0.3, 0.4, 0.45)
    sharpRectangle("fill", x, 4, percentage, 24, 300)

    -- draw border
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", x, 4, 300, 24, 5)

    -- draw percentage text
    love.graphics.setColor(1, 1, 1)
    if percentage < 100 then
        percentage = lang.print("score", {round(ply.score, 0)})
    else
        percentage = lang.print("new score", {round(ply.score, 0)})
    end
    love.graphics.print(percentage, window_width / 2 - hudFont:getWidth(percentage) / 2, 2 + round((24 - hudFont:getHeight(percentage) / 1.5) / 2, 0))

    love.graphics.setLineWidth(0) -- reset line size

    -- kills and level
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(images.skull, 5, 64)
    love.graphics.print(ply.kills, 32, 68)
    love.graphics.draw(images.level, 64, 64)
    love.graphics.print(round(ply:getLevel(), 1), 96, 68)

    -- skill tree (if opened)
    if skillTreeIsOpen then
        tree.draw()
        love.graphics.setLineWidth(1)
    end

    -- warmup message
    if warmup ~= 0 then
        text = lang.print( "warmup", {
            string.format("%.1f", tostring(round(warmup, 1)))
        })

        love.graphics.setFont(menuFont)
        love.graphics.setColor(1, 1, 1, warmup / 5)
        love.graphics.print(text, window_width / 2 - round(menuFont:getWidth(text) / 2, 0), window_height / 2 + window_height / 4, 0)
    end
end