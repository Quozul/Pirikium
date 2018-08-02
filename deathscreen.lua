deathscreen = {}

local alpha = 0
local duration = 5

function deathscreen.update(dt)
    alpha = alpha + dt / duration
end

function deathscreen.draw()
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, window_width, window_height)
    love.graphics.setFont(menuFont)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(lang.print("death"), (window_width - menuFont:getWidth(lang.print("death"))) / 2, (window_height - menuFont:getHeight(lang.print("death"))) / 2)
end