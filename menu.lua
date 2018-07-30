local M = {}

M.main = {}
M.settings = {}
M.pause = {}
M.connecting = {}

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
