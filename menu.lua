local M = {}

local buttons = {
    none = {},
    main = {},
    selection = {}
}
local menu = "main"
local mainMenu = {}
settings = {}
selection = {}
load = {}
new = {}
local unit = gspot.style.unit

local function resavePlayerList()
    print(tableToString(players, ";"))
    love.filesystem.write( "player_list", tableToString(players, ";") )
end

local function updatePlayerList()
    if not love.filesystem.getInfo("player_list") then return end

    local player_list = love.filesystem.read( "player_list" )
    players = player_list:split(";")
    print(#players .. " saves")

    if players ~= nil then
        for index, name in pairs(players) do
            local info = name:split(",")

            if load[index] then
                gspot:rem(load[index].player)
                gspot:rem(load[index].rem)
            end
            load[index] = {}

            load[index].player = gspot:button(index .. ". " .. info[1], {unit, unit * index * 2 + unit, unit*8, unit*2}, selection.group)
            load[index].player.tip = lang.print(info[2])
            load[index].player.click = function(this)
                playerUUID = info[1]
                gamestate.switch(game)
            end
            load[index].rem = gspot:button("-", {unit*9, unit * index * 2 + unit, unit*2, unit*2}, selection.group)
            load[index].rem.tip = lang.print("remove", {info[1]})
            load[index].rem.click = function(this)
                love.filesystem.remove(info[1])
                players[index] = nil
                resavePlayerList()
                updatePlayerList()
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
    print("Name of new player: " .. name)
    local s = {}
    s.defaultWeapon = classes[class.value].weapon
    s.kills = 0
    s.exp = 0
    s.skills = classes[class.value].skills
    s.highScore = 0

    local succes, error = love.filesystem.write( tostring(name), bitser.dumps( s ) )
    print(succes, error)
end

function M:init()
    -- main buttons
    buttons.main.play = NewButton(
        "button", 0, 0, unit*12, unit*5,
        function()
            menu = "none"
            selection.group:show()
        end,
        "Play", {241, 196, 15}, {shape = "sharp", easing = "bounce", font = menuFont}
    )
    buttons.main.settings = NewButton(
        "button", unit*13, 0, unit*12, unit*5,
        function()
            menu = "none"
            settings.group:show()
        end,
        "Settings", {84, 153, 199}, {shape = "sharp", easing = "bounce", font = menuFont}
    )
    buttons.main.progress = NewButton(
        "button", unit*26, 0, unit*12, unit*5,
        function() end,
        "Progress", {136, 78, 160}, {shape = "sharp", easing = "bounce", font = menuFont}, false
    )
    
    buttons.main.update = NewButton(
        "button", 0, unit*6, unit*18, unit*2,
        function() end,
        "Update", {203, 67, 53}, {shape = "sharp", easing = "bounce", font = hudFont}, false
    )
    buttons.main.mods = NewButton(
        "button", unit*20, unit*6, unit*18, unit*2,
        function() end,
        "Mod workshop", {74, 35, 90}, {shape = "sharp", easing = "bounce", font = hudFont}, false
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
        menu = "main"
    end

    settings.shader = gspot:checkbox(lang.print("enable light"), {unit, unit*2}, settings.group, config.shader)
    settings.shader.click = function(this)
        this.value = not this.value
        config.shader = this.value
    end
    settings.reset = gspot:button(lang.print("reset"), {unit, unit*4, unit*8, unit*2}, settings.group)
    settings.reset.click = function()
        print("Resetting config")
        createConfig()
    end

    -- key inputs for controls
    local position = 1
    for control, key in pairs(config.controls) do
        if control ~= "fire" and control ~= "special" then
            settings[control] = gspot:input(lang.print(control), {unit*35, unit*(position+1), unit*3, unit*1}, settings.group, key)
            settings[control].keyinput = true
            settings[control].done = function(this)
                config[control] = this.value
            end
            position = position + 1
        end
    end

    -- languages selection
    local position = 1
    languages = {}
    for value, name in pairs(languages_list) do
        languages[value] = gspot:button(upper(name), {unit*20, unit*(position * 2), unit*5, unit*2}, settings.group)
        languages[value].click = function(this)
            print("Changing language to " .. name)
            config.lang = value
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
        menu = "main"
    end

    updatePlayerList()
    selection.group:hide()

    -- character creation group
    new.group = gspot:group(lang.print("new"), {0, 0, unit*38, unit*22}, mainMenuGroup)
    new.close = gspot:button("×", {unit*37, 0, unit, unit}, new.group)
    new.close.style.bg = {1, 0, 0}
    new.close.click = function(this)
        new.group:hide()
        menu = "main"
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
        love.filesystem.append( "player_list", ";" .. new.name.value .. "," .. class.value )
        createPlayer(new.name.value)
        updatePlayerList()
        new.group:hide()
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

function M:enter()
    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
    print("Entered menu")
    menu = "main"

    if config.play_music then sounds.menu_theme:play() end
end
function M:leave() sounds.menu_theme:stop() end

function M:update(dt)
    for index, element in pairs(buttons[menu]) do
        element:update(dt)
    end
    gspot:update(dt)
end

local title = "Pirikium"
local center = {unit*19, unit*4}
function M:draw()
    local paddingy = titleFont:getHeight(title)
    local cx, cy = basicCamera(center[1], center[2], function()
        love.graphics.setFont(titleFont)
        love.graphics.print(title, unit*19 - titleFont:getWidth(title) / 2, -paddingy * 2)
        for index, element in pairs(buttons[menu]) do
            element:draw()
        end
    end)
    gspot:draw()
    SetTranslation(cx, cy)
    mainMenuGroup.pos.x, mainMenuGroup.pos.y = cx, cy - paddingy

    love.graphics.draw(images.exit, window_width - 36, 4)
end
function M:keypressed(key, code, isrepeat)
	if gspot.focus then
		gspot:keypress(key) -- only sending input to the gui if we're not using it for something else
	else
		if key == "return" then -- binding enter key to input focus
			input:focus()
		end
	end
end
function M:mousepressed(x, y, button, isTouch)
    for index, element in pairs(buttons[menu]) do
        element:mousepressed(x, y, button)
    end
    gspot:mousepress(x, y, button)

    -- quit button
    if button == 1 and between(x, window_width - 36, window_width - 4) and between(y, 4, 36) then
        love.event.quit()
    end
end
function M:mousereleased(x, y, button)
    for index, element in pairs(buttons[menu]) do
        element:mousereleased(x, y, button)
    end
    gspot:mouserelease(x, y, button)
end
function M:textinput(key) gspot:textinput(key) end
function M:wheelmoved(x, y) gspot:mousewheel(x, y) end

return M
