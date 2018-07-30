local M = {}

M.main = {}
M.settings = {}
M.pause = {}
M.character = {}

local buttons = {}

function M.main:init()
    buttons.play = NewButton("button", 10, 10, 200, 100, function() gamestate.switch(game) end , {"Play", 0, 255, 0, menuFont})
    buttons.settings = NewButton("button", 10, 120, 200, 100, function() gamestate.switch(M.settings) end , {"Settings", 0, 0, 255, menuFont})
end

function M.main:enter()
    love.mouse.setVisible(true)
    love.graphics.setBackgroundColor(0, 0, 0)
end

function M.main:draw()
    buttons.play:draw()
    buttons.settings:draw()
end

function M.main:mousepressed(x, y, button, isTouch)
    buttons.play:mouse()
    buttons.settings:mouse()
end

function M.character:init()
    -- slider = newSlider(x, y, length, value, min, max, setter, style)
    strength = newSlider(100, 100, 100, 0.1, 0, 1)
    speed = newSlider(100, 120, 100, 0.1, 0, 1)
    accuracy = newSlider(100, 140, 100, 0.1, 0, 1)
end

function M.character:update(dt)
    love.graphics.setColor(1, 1, 1)
    strength:update()
    speed:update()
    accuracy:update()
end

function M.character:draw()
    strength:draw()
    speed:draw()
    accuracy:draw()
end

function M.settings:init()
    buttons.back = NewButton("button", 10, 10, 64, 32, function() gamestate.switch(M.main) end , {"Back", 55, 255, 55, menuFont})
    buttons.shader = NewButton("checkbox", 100, 100, 10, 10, function() config.shader = not config.shader end , {"Toggle shader", nil, nil, nil, hudFont}, config.shader)
end

function M.settings:draw()
    buttons.back:draw()
    buttons.shader:draw()
end

function M.settings:mousepressed(x, y, button, isTouch)
    buttons.back:mouse()
    buttons.shader:mouse()
end

return M
