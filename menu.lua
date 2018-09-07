menu = {}
connecting = {}

local buttons = {
    none = {},
    main = {},
    selection = {}
}
local menuState = "main"
local mainMenu = {}
settings = {}
selection = {}
load = {}
new = {}
local unit = gspot.style.unit

local function getAdress(adress)
    if adress == "" or not adress then
        return "localhost", 22122
    elseif not adress:match(":") then
        return adress, 22122
    end

    local adress = adress:split(":")
    return adress[1], adress[2]
end

local function updatePlayerList()
    if not love.filesystem.getInfo("saves") then error("Save directory not found! Try restarting the game.") end
    players = love.filesystem.getDirectoryItems("saves")
    console.print("Updating save list... " .. #players .. " saves found")

    if players ~= nil then
        for index, name in pairs(players) do
            if load[index] then
                gspot:rem(load[index].player)
                gspot:rem(load[index].rem)
            end
            load[index] = {}

            load[index].player = gspot:button(index .. ". " .. name, {unit, unit * index * 2 + unit, unit*8, unit*2}, selection.group)
            load[index].player.click = function(this)
                playerUUID = name
            end
            load[index].rem = gspot:button("-", {unit*9, unit * index * 2 + unit, unit*2, unit*2}, selection.group)
            load[index].rem.tip = lang.print("remove", {name})
            load[index].rem.click = function(this)
                console.print("Removing " .. name .. "'s save")
                local succes = love.filesystem.remove("saves/" .. name)
                gspot:rem(load[index].player) -- remove this save buttons
                gspot:rem(load[index].rem)
                load[index] = nil
                load.newCharacter.pos.y = unit * #load * 2 + unit*4 -- update new char button pos
            end
        end

        if load.newCharacter then
            gspot:rem(load.newCharacter)
            load.newCharacter = nil
        end
        load.newCharacter = gspot:button("+ " .. lang.print("new"), {unit, unit * #load * 2 + unit*4, unit*10, unit*2}, selection.group)
        load.newCharacter.click = function()
            new.group:show()
            selection.group:hide()
        end
    end
end

local function createPlayer(name)
    if not love.filesystem.getInfo("saves") then error("Save directory not found! Try restarting the game.") end

    console.print("Name of new player: " .. name)
    local s = {}
    s.defaultWeapon = classes[class.value].weapon
    s.kills = 0
    s.exp = 0
    s.skills = classes[class.value].skills
    s.highScore = 0

    love.filesystem.write( "saves/" .. tostring(name), bitser.dumps( s ) )
end

function menu:init()
    -- main buttons
    buttons.main.play = NewButton(
        "button", 0, 0, unit*12, unit*5,
        function()
            menuState = "none"
            selection.group:show()
        end,
        lang.print("play"), {241, 196, 15}, {shape = "sharp", easing = "bounce", font = menuFont}
    )
    buttons.main.settings = NewButton(
        "button", unit*13, 0, unit*12, unit*5,
        function()
            menuState = "none"
            settings.group:show()
        end,
        lang.print("settings"), {84, 153, 199}, {shape = "sharp", easing = "bounce", font = menuFont}
    )
    buttons.main.progress = NewButton(
        "button", unit*26, 0, unit*12, unit*5,
        function() end,
        lang.print("progress"), {136, 78, 160}, {shape = "sharp", easing = "bounce", font = menuFont}, false
    )
    
    buttons.main.update = NewButton(
        "button", 0, unit*6, unit*18, unit*2,
        function()
            console.print("Checking for updates...")
            buttons.main.update:setText(lang.print("update checking"))
            update_checking_thread:start(config.dev_version)
        end,
        lang.print("update"), {203, 67, 53}, {shape = "sharp", easing = "bounce", font = hudFont}
    )
    buttons.main.mods = NewButton(
        "button", unit*20, unit*6, unit*18, unit*2,
        function() end,
        lang.print("mods"), {74, 35, 90}, {shape = "sharp", easing = "bounce", font = hudFont}, false
    )

    -- all groups are childs of this group, used to keep everything centered on screen
    mainMenuGroup = gspot:group("", {0, 0, 0, 0})

    -- settings group
    settings.group = gspot:group(lang.print("settings"), {0, 0, unit*38, unit*22}, mainMenuGroup)
    settings.group.style.bg = {84 / 255, 153 / 255, 199 / 255}
    settings.close = gspot:button("×", {unit*37, 0, unit, unit}, settings.group)
    settings.close.style.bg = {1, 0, 0}
    settings.close.click = function(this)
        settings.group:hide()
        menuState = "main"
    end

    settings.shader = gspot:checkbox(lang.print("enable light"), {unit, unit*2}, settings.group, config.shader)
    settings.shader.click = function(this)
        this.value = not this.value
        config.shader = this.value
    end
    settings.particles = gspot:checkbox(lang.print("enable particles"), {unit, unit*4}, settings.group, config.particles)
    settings.particles.click = function(this)
        this.value = not this.value
        config.particles = this.value
    end
    settings.dev_updates = gspot:checkbox(lang.print("dev version"), {unit, unit*6}, settings.group, config.dev_version)
    settings.dev_updates.click = function(this)
        this.value = not this.value
        config.dev_version = this.value
    end
    settings.fullscreen = gspot:checkbox(lang.print("fullscreen"), {unit, unit*8}, settings.group, config.fullscreen)
    settings.fullscreen.click = function(this)
        this.value = not this.value
        config.fullscreen = this.value
        love.window.setFullscreen(this.value)
        window_width, window_height = love.window.getMode()
    end

    settings.reset = gspot:button(lang.print("reset"), {unit, unit*10, unit*8, unit*2}, settings.group)
    settings.reset.click = function()
        console.print("Resetting config")
        createConfig()
    end

    -- key inputs for controls
    local position = 1
    settings["movements"] = gspot:text(lang.print("movements"), {unit*32, unit*(position+1), unit*6, unit*1}, settings.group)
    position = position + 1

    local blacklist = {"fire", "special", "dash", "use", "sprint", "drop", "skill_tree", "sneak", "burst"}
    for control, key in pairs(config.controls) do
        if not table.find(blacklist, control) then
            settings[control] = gspot:input(lang.print(control), {unit*35, unit*(position+1), unit*3, unit*1}, settings.group, key)
            settings[control].keyinput = true
            settings[control].done = function(this)
                console.print("Control saved")
                config.controls[control] = this.value
            end
            position = position + 1
        end
    end
    position = position + 1

    settings["other"] = gspot:text(lang.print("other"), {unit*32, unit*(position+1), unit*6, unit*1}, settings.group)
    position = position + 1

    local blacklist = {"fire", "special", "forward", "left", "backward", "right"}
    for control, key in pairs(config.controls) do
        if not table.find(blacklist, control) then
            settings[control] = gspot:input(lang.print(control), {unit*35, unit*(position+1), unit*3, unit*1}, settings.group, key)
            settings[control].keyinput = true
            settings[control].done = function(this)
                console.print("Control saved")
                config.controls[control] = this.value
            end
            position = position + 1
        end
    end

    -- languages selection
    local position = 1
    languages = {}
    for index, name in pairs(languages_list) do
        name = string.gsub(name, ".lang", "")
        languages[index] = gspot:button(lang.print(name), {unit*20, unit*(position * 2), unit*5, unit*2}, settings.group)
        languages[index].click = function(this)
            console.print("Changing language to " .. name)
            config.lang = name
            love.event.quit("restart")
        end
        position = position + 1
    end

    settings.group:hide() -- hide settings group for the moment

    -- character selection group
    selection.group = gspot:group(lang.print("load"), {0, 0, unit*38, unit*22}, mainMenuGroup)
    selection.group.style.bg = {241 / 255, 196 / 255, 15 / 255}
    selection.close = gspot:button("×", {unit*37, 0, unit, unit}, selection.group)
    selection.close.style.bg = {1, 0, 0}
    selection.close.click = function(this)
        selection.group:hide()
        menuState = "main"
    end

    updatePlayerList()

    local maps = love.filesystem.getDirectoryItems("data/maps")
    selection.maps = {}
    local position = 1
    for index, name in pairs(maps) do
        if string.match(name, ".lua") then
            local mapName = string.gsub(name, ".lua", "")
            selection.maps[index] = gspot:button(lang.print(mapName), {unit*14, unit * position * 2 + unit, unit*10, unit*2}, selection.group)
            selection.maps[index].click = function(this)
                selectedMap = name
            end
            position = position + 1
        end
    end

    selection.solo = gspot:button(lang.print("singleplayer"), {unit*26, unit*3, unit*10, unit*2}, selection.group)
    selection.solo.click = function(this)
        if not selectedMap or not playerUUID then
            gspot:feedback("Please select a map and a player")
            return
        end

        gamestate.switch(game)
    end

    -- multiplayer & server
    selection.adress = gspot:input(lang.print("adress"), {unit*30, unit*7, unit*6, unit*2}, selection.group, config.multiplayer.adress)
    selection.adress.done = function(this)
        config.multiplayer.adress = this.value
        console.print(this.value)
    end

    selection.host = gspot:button(lang.print("host"), {unit*26, unit*9, unit*10, unit*2}, selection.group)
    selection.host.click = function(this)
        local adress, port = getAdress(config.multiplayer.adress)
        gspot:feedback(("Server openned on port %d"):format(port))

        server:start(adress, port)
    end

    selection.close_host = gspot:button(lang.print("close host"), {unit*26, unit*11, unit*10, unit*1}, selection.group)
    selection.close_host.click = function(this)
        local adress, port = getAdress(config.multiplayer.adress)
        gspot:feedback("Server closed")

        love.thread.getChannel("server_channel"):push("stop")
    end

    selection.multi = gspot:button(lang.print("join"), {unit*26, unit*13, unit*10, unit*2}, selection.group)
    selection.multi.click = function(this)
        local adress, port = getAdress(config.multiplayer.adress)
        gspot:feedback(("Connecting to server with IP %s:%d"):format(adress, port))

        client = sock.newClient(adress, port)
        client:connect()
        
        gamestate.switch(connecting)
    end

    selection.group:hide()

    -- character creation group
    new.group = gspot:group(lang.print("new"), {0, 0, unit*38, unit*22}, mainMenuGroup)
    new.group.style.bg = {108 / 255, 52 / 255, 131 / 255}
    new.close = gspot:button("×", {unit*37, 0, unit, unit}, new.group)
    new.close.style.bg = {1, 0, 0}
    new.close.click = function(this)
        new.group:hide()
        selection.group:show()
        menuState = "main"
    end
    new.name = gspot:input("", {unit, unit*2, unit*8, unit*2}, new.group, lang.print("name"), false)
    new.create = gspot:button(lang.print("create"), {unit, unit*6, unit*8, unit*2}, new.group)
    new.create.click = function(this)
        if not class.value then
            gspot:feedback("Please choose a class")
            return
        elseif new.name.value:match("\r") then
            gspot:feedback("This name is invalid")
            return
        end
        createPlayer(new.name.value)
        updatePlayerList()
        new.group:hide()
        selection.group:show()
    end

    class = gspot:scrollgroup(lang.print("class"), {unit*27, unit, unit*10, unit*20}, new.group, "horizontal")
    class.style.bg = {108 / 255, 52 / 255, 131 / 255}
    for index, name in pairs(classes.list) do
        local info = classes[name]
        class[name] = gspot:option(lang.print(name), {0, unit * tonumber(index) * 2 + unit, unit*10, unit*2}, class, name)
        class[name].tip = lang.print("default weapon") .. " " .. lang.print(info.weapon)
        if info.skills then
            for skill, value in pairs(info.skills) do
                class[name].tip = class[name].tip .. "\n" .. lang.print(skill) .. ": " .. value
            end
        end
    end
    class:hide()

    new.group:hide()
end

function menu:enter()
    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
    console.print("Entered menu")
    selectedMap = nil
    buttons.main.update:setText(lang.print("update"))

    client = nil

    if config.music then sounds.menu_theme:play() end
end

function menu:leave()
    sounds.menu_theme:stop()
end

function menu:update(dt)
    for index, element in pairs(buttons[menuState]) do
        element:update(dt)
    end
    gspot:update(dt)

    version = love.thread.getChannel( "update_channel" ):pop()
    if version then
        if version == "error" then
            buttons.main.update:setText(lang.print("error"))
            return
        end

        console.print(("Online version:  %s.\nCurrent version: %s."):format(version.online_ver, version.current_ver))

        if version.online_ver > version.current_ver then
            console.print("New version available!")

            buttons.main.update:setText(lang.print("update found"))
            local window_buttons = { "Yes", "No" }

            pressedbutton = love.window.showMessageBox(
                lang.print("update found"),
                lang.print("update download"),
                window_buttons
            )

            if pressedbutton == 1 then
                love.system.openURL("https://github.com/Quozul/Pirikium")
            end
        else
            buttons.main.update:setText(lang.print("update not found"))
        end
    end
end

local title = "Pirikium"
local center = {unit*19, unit*4}
function menu:draw()
    local paddingy = titleFont:getHeight(title)
    local cx, cy = basicCamera(center[1], center[2], function()
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(titleFont)
        love.graphics.print(title, unit*19 - titleFont:getWidth(title) / 2, -paddingy * 2)
        for index, element in pairs(buttons[menuState]) do
            element:draw()
        end
    end)
    gspot:draw()
    SetTranslation(cx, cy)
    mainMenuGroup.pos.x, mainMenuGroup.pos.y = cx, cy - unit*22 / 3

    love.graphics.draw(images.exit, window_width - 36, 4)
    if config.music then love.graphics.draw(images.music, music_on, window_width - 36, window_height - 36)
    else love.graphics.draw(images.music, music_off, window_width - 36, window_height - 36) end

    console.draw()
end

function menu:keypressed(key, code, isrepeat)
	if gspot.focus then
		gspot:keypress(key) -- only sending input to the gui if we're not using it for something else
	end
end

function menu:mousepressed(x, y, button, isTouch)
    for index, element in pairs(buttons[menuState]) do
        element:mousepressed(x, y, button)
    end
    gspot:mousepress(x, y, button)

    -- quit button
    if button == 1 then
        if isBetween(x, window_width - 36, window_width - 4) and isBetween(y, 4, 36) then
            love.event.quit()
        elseif isBetween(x, window_width - 36, window_width - 4) and isBetween(y, window_height - 36, window_height - 4) then
            config.music = not config.music
            if config.music then sounds.menu_theme:play()
            else sounds.menu_theme:stop()
            end
        end
    end
end

function menu:mousereleased(x, y, button)
    for index, element in pairs(buttons[menuState]) do
        element:mousereleased(x, y, button)
    end
    gspot:mouserelease(x, y, button)
end

function menu:textinput(key)
    gspot:textinput(key)
end

function menu:wheelmoved(x, y)
    gspot:mousewheel(x, y)
end

function connecting:init()
    cancel_connecting = NewButton(
        "button", 0, 0, unit*10, unit*4,
        function()
            gamestate.switch(menu)
        end,
        lang.print("cancel"), {175, 96, 26}, {shape = "sharp", easing = "bounce", font = menuFont}
    )
end

function connecting:enter()
    local adress, port = getAdress(config.multiplayer.adress)
    loading.setText( lang.print( "connecting", {adress, port} ) )
end

function connecting:update(dt)
    loading.update(dt)

    local state = client:getState()
    if state == "disconnected" then
        loading.setText( lang.print( "failed" ) )
        love.window.requestAttention()
    elseif state == "connected" then
        loading.setText( lang.print( "connected" ) )
        love.window.requestAttention()
        gamestate.switch(multiplayer_game)
    end
    
    client:update()
    cancel_connecting:update(dt)
end

function connecting:mousepressed(x, y, button)
    cancel_connecting:mousepressed(x, y, button)
end

function connecting:mousereleased(x, y, button)
    cancel_connecting:mousereleased(x, y, button)
end

function connecting:draw()
    loading.draw()

    local cx, cy = basicCamera(unit*5, unit*(-6), function()
        cancel_connecting:draw()
    end)
    SetTranslation(cx, cy)
end
