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
            load[index].tip = info[2]
            load[index].click = function(this)
                playerUUID = info[1]
                gamestate.switch(game)
            end
            load[index].rem = gspot:button("-", {unit*7, unit * index + unit, unit, unit}, load)
            load[index].rem.tip = "Remove " .. info[1]
            load[index].rem.click = function(this)
                gspot:rem(load[index])
                gspot:rem(load[index].rem)
                love.filesystem.remove(info[1] .. ".sav")
                players[index] = nil
                resavePlayerList()
            end
        end
    end
end

local function createPlayer(name)
    local s = {}
    s.inventory = { classes[class.value].weapon }
    s.kills = 0
    s.exp = 0
    s.skills = classes[class.value].skills

    love.filesystem.write( name .. ".sav", bitser.dumps( s ) )
end

function M:init()
    main = gspot:group("Main menu", {unit, unit, unit*8, unit*8})
    main.drag = true

    main.new = gspot:button("New character", {0, unit*2, unit*8, unit*2}, main)
    main.new.click = function(this)
        if new.display then new:hide()
        else new:show() end
    end
    main.load = gspot:button("Load character", {0, unit*4, unit*8, unit*2}, main)

    new = gspot:group("New character", {unit, unit*10, unit*8, unit*8})
    new.name = gspot:input("", {0, unit*2, unit*8, unit*2}, new, "Name")
    new.class = gspot:button("Class", {0, unit*4, unit*8, unit*2}, new)
    new.class.click = function(this)
        if class.display then class:hide()
        else class:show() end
    end
    new.create = gspot:button("Create", {0, unit*6, unit*8, unit*2}, new)
    new.create.click = function(this)
        if not class.value then
            gspot:feedback("Please choose a class")
            return
        end
        love.filesystem.append( "player_list", new.name.value .. "," .. class.value .. ";" )
        createPlayer(new.name.value)
        updatePlayerList()
    end

    class = gspot:group("Character class", {unit*9, 0, unit*8, unit*8}, new)
    for name, info in pairs(classes) do
        if info.pos == nil then error("You must give a position for the class " .. name) end
        class[name] = gspot:option(name, {0, unit * tonumber(info.pos) + unit, unit*8, unit}, class, name)
        class[name].tip = "Default weapon: " .. info.weapon
        if info.skills then
            for skill, value in pairs(info.skills) do
                class[name].tip = class[name].tip .. "\n" .. skill .. ": " .. value
            end
        end
    end
    class:hide()

    load = gspot:group("Load character", {unit*10, unit, unit*8, unit*8})
    updatePlayerList()

    settings = gspot:group("Settings", {unit*19, unit, unit*8, unit*14})
    settings.shader = gspot:button("", {0, unit*2, unit*8, unit*2}, settings)
    settings.shader.click = function(this)
        config.shader = not config.shader
    end
    settings.config = gspot:button("Reset config", {0, unit*4, unit*8, unit*2}, settings)
    settings.config.click = function(this)
        createConfig()
    end
    settings.forward = gspot:input("Forward", {unit*5, unit*6, unit*3, unit*1}, settings, config.controls.forward)
    settings.left = gspot:input("Left", {unit*5, unit*7, unit*3, unit*1}, settings, config.controls.left)
    settings.back = gspot:input("Backward", {unit*5, unit*8, unit*3, unit*1}, settings, config.controls.backward)
    settings.right = gspot:input("Right", {unit*5, unit*9, unit*3, unit*1}, settings, config.controls.right)
    settings.use = gspot:input("Use", {unit*5, unit*10, unit*3, unit*1}, settings, config.controls.use)
    settings.drop = gspot:input("Drop", {unit*5, unit*11, unit*3, unit*1}, settings, config.controls.drop)
    settings.skills = gspot:input("Skills tree", {unit*5, unit*11, unit*3, unit*1}, settings, config.controls.skill_tree)

    settings.save = gspot:button("Save controls", {0, unit*13, unit*8, unit*2}, settings)
    settings.save.click = function(this)
        config.controls.forward = settings.forward.value
        config.controls.left = settings.left.value
        config.controls.backward = settings.back.value
        config.controls.right = settings.right.value
        config.controls.use = settings.use.value
        config.controls.drop = settings.drop.value
    end
end

function M:enter()
    love.mouse.setVisible(true)
    love.graphics.setBackgroundColor(0, 0, 0)
    print("Entered menu")
end

function M:update(dt)
    gspot:update(dt)

    if config.shader then
        settings.shader.label = "Disable lighting"
    else
        settings.shader.label = "Enable lighting"
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
