multiplayer_game = {}

function multiplayer_game:enter()
    set_notif({"The multiplayer mode is not available at the moment..."})
    back = NewButton(
        "button", 0, 0, 192, 80,
        function()
            gamestate.switch(menu)
        end, lang.print("back"), {74, 35, 90}, {shape = "sharp", easing = "bounce", font = menuFont}
    )
end

function multiplayer_game:update(dt)
    client:update()
    update_hud(dt)
    back:update(dt)
end

function multiplayer_game:draw()
    notif_hud()
    local x, y = basicCamera(96, 40, function()
        back:draw()
    end)

    SetTranslation(x, y)
end

function multiplayer_game:mousepressed(x, y, button, isTouch)
    back:mousepressed(x, y, button)
end

function multiplayer_game:mousereleased(x, y, button)
    back:mousereleased(x, y, button)
end