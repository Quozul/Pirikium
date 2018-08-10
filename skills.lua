local T = {}

local skills_buttons = {}

local centerX, centerY = window_width / 2, window_height / 2

function T.init()
    print("Skill tree: " .. #skills.list .. " skills loaded")

    local collumn = 0

    for index, name in pairs(skills.list) do
        local row = index
        if index >= 8 then
            collumn = 0.75
            row = index - 7
        end

        local x = centerX / 4 + 8 + centerX * collumn
        local y = (row - ((#skills + 1) / 2)) * 48 + centerY / 4

        -- NewButton(type, x, y, w, h, click, text, color, style, value)
        --skills_buttons[index] = NewButton(
        --    "button", x, y, 128, 32,
        --    function() ply:increaseSkill(name) end,
        --    {lang.print(name), rf(0, 1, 2), rf(0, 1, 2), rf(0, 1, 2), hudFont}, name )
        skills_buttons[index] = NewButton(
            "button", x, y, 128, 32, function() ply:increaseSkill(name) end,
            lang.print(name), {math.random(55, 255), math.random(55, 255), math.random(55, 255)},
            {shape = "sharp", easing = "inOut"}
        )
        print("Added button for " .. name)
    end
end

function T.draw()
    love.graphics.setLineWidth(8)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", centerX / 4, centerY / 4, centerX * 1.5, centerY * 1.5)
    love.graphics.setColor(0.25, 0.25, 0.25, 0.75)
    love.graphics.rectangle("fill", centerX / 4, centerY / 4, centerX * 1.5, centerY * 1.5)
    
    love.graphics.setColor(1, 1, 1)
    --love.graphics.print(lang.print("exp", {round(ply.exp, 1)}), centerX / 4 + 4, centerY / 4 + 4)
    love.graphics.draw(images.exp, centerX / 4 + 4, centerY / 4 + 4)
    love.graphics.print(round(ply.exp, 1), centerX / 4 + 4 + 32, centerY / 4 + 8)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
    for index, name in pairs(skills.list) do
        skills_buttons[index]:draw()

        local x, y = skills_buttons[index]:getPos()
        local cost = round(math.max(ply.skills[name] * skills.skills[name].mult, skills.skills[name].mult), 2)
        local text = lang.print("skill level", {ply.skills[name]}) .. "\n" .. lang.print("skill cost", {cost})

        love.graphics.print(text, x + 128 + 16, y)
    end
end

function T.update(dt)
    for index, but in pairs(skills.list) do
        skills_buttons[index]:update(dt)
    end
end

function T.mousepressed(x, y, button)
    for index, but in pairs(skills.list) do
        skills_buttons[index]:mousepressed(x, y, button)
    end
end

function T.mousereleased(x, y, button)
    for index, but in pairs(skills.list) do
        skills_buttons[index]:mousereleased(x, y, button)
    end
end

return T