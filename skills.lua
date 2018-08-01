local T = {}

local skills_buttons = {}

local centerX, centerY = window_width / 2, window_height / 2

local skills = {
    "speed",
    "stamina",
    "strength",
    "accuracy",
    "recoil"
}

function T.init()
    print("Skill tree: " .. #skills .. " skills loaded")

    for index, name in pairs(skills) do
        skills_buttons[index] = NewButton(
            "button", centerX - centerX / 2 + 8, (index - ((#skills + 1) / 2)) * 48 + centerY - 16, 128, 32,
            function() ply:increaseSkill(name) end,
            {name, rf(0, 1, 2), rf(0, 1, 2), rf(0, 1, 2), hudFont}, name )
        print("Added button for " .. name)
    end
end

function T.draw()
    love.graphics.setLineWidth(8)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", centerX - centerX / 2, centerY - centerY / 2, centerX, centerY)
    love.graphics.setColor(0.25, 0.25, 0.25, 0.75)
    love.graphics.rectangle("fill", centerX - centerX / 2, centerY - centerY / 2, centerX, centerY)

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
    for index, name in pairs(skills) do
        skills_buttons[index]:draw()

        local x, y = skills_buttons[index]:getPos()
        local cost = math.max(ply.skills[name] * 5, 2.5)
        love.graphics.print("Current level: " .. ply.skills[name] .. "\nCost for next level: " .. cost, x + 128 + 16, y)
    end
end

function T.mouse()
    for index, name in pairs(skills) do
        skills_buttons[index]:mouse()
    end
end

return T