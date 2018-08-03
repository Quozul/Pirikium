deathscreen = {}

local alpha = 0
local duration = 5

function deathscreen.init()
    alpha = 0
end

function deathscreen.update(dt)
    alpha = math.min(alpha + dt / duration, 1)

    if alpha == 1 and love.mouse.isDown(1) then gamestate.switch(menu) end
end

function deathscreen.draw()
    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.rectangle("fill", 0, 0, window_width, window_height)

    love.graphics.setFont(menuFont)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(lang.print("death"), (window_width - menuFont:getWidth(lang.print("death"))) / 2, (window_height - menuFont:getHeight(lang.print("death"))) / 2)

    if not ply.highScore or ply.score > ply.highScore then -- new record
        text = lang.print("new score", {ply.score})
    else
        text = lang.print("score", {ply.score}) .. "\n" .. lang.print("best score", {ply.highScore})
    end
    local x, y = (window_width - hudFont:getWidth(text)) / 2, window_height / 2 + hudFont:getHeight(text) * 2

    love.graphics.setFont(hudFont)
    love.graphics.print(text, x, y)

end