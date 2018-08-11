local M = {}
unit = gspot.style.unit

local classes = json:decode( love.filesystem.read( "data/classes.json" ) )

local function resavePlayerList()
    print(tableToString(players, ";"))
    love.filesystem.write( "player_list", tableToString(players, ";") )
end

local function updatePlayerList()
    if not love.filesystem.getInfo("player_list") then return end

    local player_list = love.filesystem.read( "player_list" )
    players = player_list:split(";")

    if players ~= nil then
        for index, name in pairs(players) do
            local info = name:split(",")

            if load[index] then gspot:rem(load[index]) end

            load[index] = gspot:button(index .. ". " .. info[1], {0, unit * index + unit, unit*7, unit}, load)
            load[index].tip = lang.print(info[2])
            load[index].click = function(this)
                playerUUID = info[1]
                gamestate.switch(game)
            end
            load[index].rem = gspot:button("-", {unit*7, unit * index + unit, unit, unit}, load)
            load[index].rem.tip = lang.print("remove", {info[1]})
            load[index].rem.click = function(this)
                gspot:rem(load[index])
                gspot:rem(load[index].rem)
                love.filesystem.remove(info[1])
                players[index] = nil
                resavePlayerList()
            end
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
    new = gspot:group(lang.print("new"), {unit, unit, unit*8, unit*8})
    new.name = gspot:input("", {0, unit*2, unit*8, unit*2}, new, lang.print("name"), false)
    new.class = gspot:button(lang.print("class"), {0, unit*4, unit*8, unit*2}, new)
    new.class.click = function(this)
        if class.display then class:hide()
        else class:show() end
    end
    new.create = gspot:button(lang.print("create"), {0, unit*6, unit*8, unit*2}, new)
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
    end

    class = gspot:group(lang.print("class"), {0, unit * 9, unit*8, unit*6}, new)
    for index, name in pairs(classes.list) do
        local info = classes[name]
        class[name] = gspot:option(lang.print(name), {0, unit * tonumber(index) + unit, unit*8, unit}, class, name)
        class[name].tip = lang.print("default weapon") .. " " .. lang.print(info.weapon)
        if info.skills then
            for skill, value in pairs(info.skills) do
                class[name].tip = class[name].tip .. "\n" .. lang.print(skill) .. ": " .. value
            end
        end
    end
    class:hide()

    load = gspot:group(lang.print("load"), {unit*10, unit, unit*8, unit*15})
    updatePlayerList()

    settings = gspot:group(lang.print("settings"), {unit*19, unit, unit*8, unit*15})
    settings.shader = gspot:button("", {0, unit*2, unit*8, unit*2}, settings)
    settings.shader.click = function(this)
        config.shader = not config.shader
    end
    settings.config = gspot:button(lang.print("reset"), {0, unit*4, unit*8, unit*2}, settings)
    settings.config.click = function(this)
        createConfig()
    end
    settings.forward = gspot:input(lang.print("forward"), {unit*5, unit*6, unit*3, unit*1}, settings, config.controls.forward)
    settings.left = gspot:input(lang.print("left"), {unit*5, unit*7, unit*3, unit*1}, settings, config.controls.left)
    settings.back = gspot:input(lang.print("backward"), {unit*5, unit*8, unit*3, unit*1}, settings, config.controls.backward)
    settings.right = gspot:input(lang.print("right"), {unit*5, unit*9, unit*3, unit*1}, settings, config.controls.right)
    settings.use = gspot:input(lang.print("use"), {unit*5, unit*10, unit*3, unit*1}, settings, config.controls.use)
    settings.drop = gspot:input(lang.print("drop"), {unit*5, unit*11, unit*3, unit*1}, settings, config.controls.drop)
    settings.skills = gspot:input(lang.print("skill tree"), {unit*5, unit*12, unit*3, unit*1}, settings, config.controls.skill_tree)

    settings.save = gspot:button(lang.print("save controls"), {0, unit*13, unit*8, unit*2}, settings)
    settings.save.click = function(this)
        config.controls.forward = settings.forward.value
        config.controls.left = settings.left.value
        config.controls.backward = settings.back.value
        config.controls.right = settings.right.value
        config.controls.use = settings.use.value
        config.controls.drop = settings.drop.value
    end

    languages_group = gspot:group(lang.print("languages"), {unit*28, unit, unit*8, unit*15})
    local pos = 1
    for value, name in pairs(languages_list) do
        class[value] = gspot:option(upper(name), {0, unit * pos + unit, unit*8, unit}, languages_group)
        class[value].click = function(this)
            config.lang = value
            love.event.quit("restart")
        end
        pos = pos + 1
    end

    scale = gspot:group(lang.print("scale"), {unit*37, unit, unit*8, unit*15})
    scale[0] = gspot:option("853×480 (broken)", {0, unit*2, unit*8, unit}, scale, 0.5)
    scale[0].click = function(this)
        config.ratio = this.value
        updateScreenSize()
    end
    scale[1] = gspot:option("1280×720", {0, unit*3, unit*8, unit}, scale, 1)
    scale[1].click = function(this)
        config.ratio = this.value
        updateScreenSize()
    end
    scale[2] = gspot:option("1366×768 (broken)", {0, unit*4, unit*8, unit}, scale, 768/720)
    scale[2].click = function(this)
        config.ratio = this.value
        updateScreenSize()
    end
    scale[3] = gspot:option("1920×1080", {0, unit*5, unit*8, unit}, scale, 1.5)
    scale[3].click = function(this)
        config.ratio = this.value
        updateScreenSize()
    end
end

function M:enter()
    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
    print("Entered menu")

    if config.play_music then sounds.menu_theme:play() end
end

function M:leave()
    sounds.menu_theme:stop()
end

function M:update(dt)
    gspot:update(dt)

    if config.shader then
        settings.shader.label = lang.print("disable light")
    else
        settings.shader.label = lang.print("enable light")
    end
end
function M:draw() gspot:draw() end
function M:keypressed(key, code, isrepeat)
	if gspot.focus then
		gspot:keypress(key) -- only sending input to the gui if we're not using it for something else
	else
		if key == "return" then -- binding enter key to input focus
			input:focus()
		end
	end
end
function M:mousepressed(x, y, button, isTouch) gspot:mousepress(x, y, button) end
function M:textinput(key) gspot:textinput(key) end
function M:mousereleased(x, y, button) gspot:mouserelease(x, y, button) end
function M:wheelmoved(x, y) gspot:mousewheel(x, y) end

return M
