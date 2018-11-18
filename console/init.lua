require "console/utils"
local multikeys = require "console/multi-key"
console_channel = love.thread.newChannel()

local console = {}

-- load config
local console_config = love.filesystem.load("console/config.lua")()
local console_width, console_height = console_config.width, console_config.height
local window_width, window_height = love.window.getMode()
local console_x, console_y = window_width / 2 - console_width / 2, window_height / 2 - console_height / 2
local console_font = console_config.font or love.graphics.getFont()
local lineheight, timewidth = console_font:getHeight() + 4, console_font:getWidth("00:00:00")
local console_loglimit, console_openkey = console_config.limit, console_config.openkey or "f1"
local console_cursors, console_enabledanimation = console_config.cursors, console_config.animations

local console_magnetized = false
local console_oldsize = {width = console_width, height = console_height}
local print_size, padding = 0, 0

-- load commands
local commands = love.filesystem.load("console/commands.lua")()
local commandlist, commandlist_text = {}, ""
local console_memory = {}
for name in pairs(commands) do
    commandlist[#commandlist + 1] = name -- create the command list
    commandlist_text = commandlist_text .. name .. " "

    local cmd = commands[name]
    if cmd.memory then
        console_memory[name] = {}
    end
end
local suggestedcommands = commandlist

-- load console states
local console_grabbed = false
local console_scrollgrabbed = false
local console_cornergrabbed = false
console_readyforinput = true
console_show = false
local console_hidden = not console_show
local console_animation, console_animationtime, console_scale, console_alpha = console_show and "open", 0, 1, 1
local console_textinputalpha = 0

-- load console cursor
local arrow = love.mouse.newCursor( love.image.newImageData("console/data/arrow.png"), 0, 0 )
local plus_arrow = love.mouse.newCursor( love.image.newImageData("console/data/plus_arrow.png"), 0, 0 )
local ibeam = love.mouse.newCursor( love.image.newImageData("console/data/ibeam.png"), 8, 8 )
local grab = love.mouse.newCursor( love.image.newImageData("console/data/grab.png"), 8, 8 )
local hand = love.mouse.newCursor( love.image.newImageData("console/data/hand.png"), 8, 8 )
local pointer = love.mouse.newCursor( love.image.newImageData("console/data/pointer.png"), 5, 1 )
local down_pointer = love.mouse.newCursor( love.image.newImageData("console/data/down_pointer.png"), 5, 1 )
local resize = love.mouse.newCursor( love.image.newImageData("console/data/size.png"), 8, 8 )
local cross = love.graphics.newImage("console/data/cross.png")
local corner = love.graphics.newImage("console/data/corner.png")
local return_arrow = love.graphics.newImage("console/data/return.png")

local logs, wrapped_logs = {}, {}
local command, lastcommand, historypos = "", {}, 0
local cursor_pos1, cursor_pos2, showcursor, largeselect = 0, 0, true, largeselect
local fake_cursor1, fake_cursor2, cursor_alpha, cursor_alphadir = cursor_pos1, cursor_pos2, 1, true
local time = 0
local historydisplayed, desiredhistorydisplayed = 0, lineheight
local tabpos = 1 -- used when tabulation is pressed

local scrollbar_height, scrollbar_y, scrollbar_grabbed = 0, 0, false

-- more usefull functions, but thoses are more specific to the project
local function setCursor(cursor) -- shortcut
    love.mouse.setCursor(cursor)
end

-- logs must be wrapped in order to display multi-line logs
local function wraplogs()
    wrapped_logs = {}
    for _, log in pairs(logs) do
        local width, text = console_font:getWrap(log.event, console_width - timewidth - 18)
        table.insert(wrapped_logs, text)
    end
end

-- convert the logs to string, you should use console.getlogs() function instead
local function logToString(logs)
    local str = ""
    for _, log in pairs(logs) do
        str = str .. ("%s %s [%s]: %s\n"):format(log.time, log.from, log.letter, log.event)
    end
    return str
end

-- look for the closests values
local function completeValue(value, t)
    local closests = {}
    for index, name in pairs(t) do
        if name:sub(1, value:len()) == value then
            table.insert(closests, name)
        end
    end

    if closests ~= {} then return closests end
    return false
end

function console.print(str, type)
    -- get the traceback
    local traceback = ((debug.traceback(""):gsub("stack traceback:","")):split("\n")[2])
    local from_file = ("%s:%s"):format(
        (((traceback:split(":")[1]):gsub("\9","")):gsub(".lua","")),
        (((traceback:split(":")[2])))
    )

    str = tostring(str)

    -- get the type of the log and sets its colour
    local letter = "i"
    if type == "debug" or type == 1 then
        type = {99, 57, 116}
        letter = "d"
    elseif type == "error" or type == 2 then
        type = {100, 30, 22}
        letter = "e"
    else
        type = {251, 219, 86}
    end

    local width, text = console_font:getWrap(str, console_width - timewidth - 12)
    desiredhistorydisplayed = desiredhistorydisplayed - lineheight * #text

    local time = os.date("%H:%M:%S") -- get a formatted time

    -- prints the log to the console
    print( ("%s %s [%s]: %s"):format(time, from_file, letter, str) )

    logs[#logs + 1] = {
        time = time,
        from = from_file,
        event = str,
        type = type,
        letter = letter,
    }

    -- if the limit of logs is reached
    if console_loglimit and #logs > console_loglimit then
        table.remove(logs, 1) -- removes the first element from the logs
    end

    wraplogs()
end

function console.getlogs() return logToString(logs) end

function console.update(dt)
    -- get the logs from threads
    local thread_log = love.thread.getChannel("console_channel"):pop()
    if thread_log then
        logs[#logs + 1] = thread_log -- add the logs to the history
        wraplogs()

        local width, text = console_font:getWrap(thread_log.event, console_width - timewidth - 12)
        desiredhistorydisplayed = desiredhistorydisplayed - lineheight * #text
    end

    for instruction, cmd in pairs(commands) do
        local update = cmd.update
        if update then
            update(dt, console_memory[instruction])
        end
    end

    if not console_show then return end
    -- everything bellow will not be executed if the console isn't shown

    if console_enabledanimation then
        local diff = desiredhistorydisplayed - historydisplayed
        if diff ~= 0 then
            local speed = (dt * lineheight * 1.5)
            historydisplayed = historydisplayed + diff * speed
        end

        local diff1 = console_font:getWidth( string.sub(command, 1, cursor_pos1) ) - fake_cursor1
        local diff2 = console_font:getWidth( string.sub(command, 1, cursor_pos2) ) - fake_cursor2
        if diff1 + diff2 ~= 0 then
            local speed = (dt * 20)
            fake_cursor1 = fake_cursor1 + diff1 * speed
            fake_cursor2 = fake_cursor2 + diff2 * speed
        end

        time = time + dt
        if largeselect or cursor_pos2 - cursor_pos1 ~= 0 then
            time = 0
            cursor_alpha = 1
        elseif cursor_alpha == 0 or cursor_alpha == 1 then
            time = 0
            cursor_alphadir = not cursor_alphadir
        end

        if cursor_alphadir then
            cursor_alpha = math.min(cursor_alpha + dt * 2, 1)
        else
            cursor_alpha = math.max(cursor_alpha - dt * 2, 0)
        end

        if console_readyforinput then
            console_textinputalpha = math.min(console_textinputalpha + dt * 10, 1)
        else
            console_textinputalpha = math.max(console_textinputalpha - dt * 10, 0)
        end
    else
        historydisplayed = desiredhistorydisplayed

        fake_cursor1 = console_font:getWidth( string.sub(command, 1, cursor_pos1) )
        fake_cursor2 = console_font:getWidth( string.sub(command, 1, cursor_pos2) )
        
        if console_readyforinput then
            console_textinputalpha = 1
        else
            console_textinputalpha = 0
        end
    end

    if console_enabledanimation then
        if console_animation == "open" then
            console_animationtime = console_animationtime + dt
            console_scale = outElastic(console_animationtime, 0, 1, 1, 1, 1)

            if console_animationtime >= 1 then
                console_animation, console_animationtime, console_scale, console_alpha = false, 0, 1, 1
            end
        elseif console_animation == "close" then
            console_animationtime = console_animationtime + dt
            console_alpha = console_alpha - dt / .25

            if console_animationtime >= .25 then
                console_animation, console_animationtime, console_scale, console_alpha = false, 0, 1, 1
                console_show = false
            end
        end
    elseif console_animation == "close" then
        console_animation, console_show = false, false
    end

    if console.hasfocus() then love.keyboard.setKeyRepeat(true)
    else love.keyboard.setKeyRepeat(false) end

    local container_h = print_size + lineheight
    local object_h    = #logs * lineheight + padding - lineheight

    scrollbar_height  = math.between(container_h / (object_h / container_h), 4, container_h)
    scrollbar_y       = math.between(-historydisplayed / (object_h / (container_h - scrollbar_height)), 0, container_h)
end

function console.addtomemory(instruction, name, value)
    if instruction == nil or name == nil then return false end
    console_memory[instruction][name] = value
    return true
end

function console.remfrommemory(instruction, name)
    if not console_memory[instruction][name] then return false end
    console_memory[instruction][name] = nil
    return true
end

function console.resize(width, height)
    window_width, window_height = width, height
end

function console.runcommand()
    if command:split(" ")[1] ~= nil then
        lastcommand[historypos] = command -- add command to history
        historypos = historypos + 1
    end

    command = command .. " "
    local instruction = command:split(" ")[1] or "" -- get instruction
    command = command:gsub(instruction .. " ", "") -- remove the instruction
    local args = command:split(" ") -- get arguments

    local cmd = commands[instruction]

    if cmd then
        local minimumarguments = cmd.requiredarguments or cmd.arguments or 0
        if #args >= minimumarguments and command ~= "" or cmd.requiredarguments == -1 then
            if minimumarguments > 0 then
                for arg = 1, math.min(cmd.arguments or cmd.requiredarguments, #args) do
                    command = command:gsub(args[arg] .. " ", "") -- remove arguments
                end
            end
            command = command:sub(1, -2) or "" -- remove the space at the end

            local memory = console_memory[instruction]
            local error = cmd.execution(command, args, memory)
            if error then console.print("Usage: " .. cmd.usage, 2) end
        else
            console.print("Usage: " .. cmd.usage, 2)
        end
    else
        console.print("List of valid commands: " .. commandlist_text, 2)
    end

    command, cursor_pos1, cursor_pos2 = "", 0, 0
    tabpos = 1 -- reset the position of the tab shortcut
    historydisplayed = historydisplayed - lineheight
end

function console.keypressed(key)
    if key == console_openkey then
        console_hidden = not console_hidden

        if not console_hidden then
            console_show = true
            console_animation = "open"
        else
            console_animation = "close"
        end
        console_animationtime = 0

        if love.keyboard.hasKeyRepeat() and not console_show then
            love.keyboard.setKeyRepeat(false)
        end
        return
    end

    if not console_show or not console_readyforinput then return end

    cursor_alphadir = true

    multikeys.keypressed(key)

    local ctrls = multikeys.isDown("lctrl") or multikeys.isDown("rctrl")
    local shifts = multikeys.isDown("lshift") or multikeys.isDown("rshift")

    if ctrls then
        if key == "a" then
            cursor_pos1, cursor_pos2 = 0, command:len()
        elseif key == "v" then
            if cursor_pos2 - cursor_pos1 ~= 0 then
                command, p = command:remove(cursor_pos1, cursor_pos2)
                if math.sign(p) then p = 0 end

                cursor_pos1 = cursor_pos1 + p
                cursor_pos2 = cursor_pos1
            end

            local content = love.system.getClipboardText()
            command = command:insert(cursor_pos1, content)
            local p = cursor_pos1 + content:len()
            cursor_pos1, cursor_pos2 = p, p
        elseif key == "c" then
            local from, to = cursor_pos1, cursor_pos2
            if from > to then -- from is greater
                local temp = from
                from = to
                to = temp
            end
            love.system.setClipboardText(command:sub(from + 1, to))
        end

        if key == "left" then
            cursor_pos1 = cursor_pos1 - 1
            cursor_pos2 = cursor_pos1
        elseif key == "right" then
            cursor_pos1 = cursor_pos1 + 1
            cursor_pos2 = cursor_pos1
        elseif key == "up" then
            cursor_pos1 = 0
            cursor_pos2 = cursor_pos1
        elseif key == "down" then
            cursor_pos1 = command:len()
            cursor_pos2 = cursor_pos1
        end
    elseif shifts then
        if key == "left" then
            cursor_pos2 = cursor_pos2 - 1
        elseif key == "right" then
            cursor_pos2 = cursor_pos2 + 1
        elseif key == "up" then
            cursor_pos2 = 0
        elseif key == "down" then
            cursor_pos2 = command:len()
        end
    elseif key == "return" or key == "kpenter" then
        console.runcommand() -- run the command
    elseif key == "backspace" then
        local p, pos2

        if cursor_pos2 - cursor_pos1 == 0 then pos2 = cursor_pos2 - 1
        else pos2 = cursor_pos2 end

        command, p = command:remove(cursor_pos1, pos2) -- delete backward
        if math.sign(p) then p = 0 end

        cursor_pos1 = cursor_pos1 + p
        cursor_pos2 = cursor_pos1
    elseif key == "delete" then
        local p

        command, p = command:remove(cursor_pos1, cursor_pos2) -- delete forward
        if math.sign(p) then p = 0 end
        
        cursor_pos1 = cursor_pos1 + p
        cursor_pos2 = cursor_pos1
    elseif key == "up" then
        historypos = math.max(historypos - 1, 1)
        command = lastcommand[historypos] or "" -- sets the command to the latest one
        local p = command:len() or 0
        cursor_pos1, cursor_pos2 = p, p
    elseif key == "down" then
        historypos = math.min(historypos + 1, #lastcommand + 1)
        command = lastcommand[historypos] or "" -- sets the command to the newest one
        local p = command:len() or 0
        cursor_pos1, cursor_pos2 = p, p
    elseif key == "left" then
        local p = cursor_pos1 - 1
        cursor_pos1, cursor_pos2 = p, p
    elseif key == "right" then
        local p = cursor_pos1 + 1
        cursor_pos1, cursor_pos2 = p, p
    elseif key == "tab" then
        if #suggestedcommands > 0 then -- go throught all the suggested commands
            if tabpos > #suggestedcommands then
                tabpos = 1
            end

            command = suggestedcommands[tabpos]

            tabpos = tabpos + 1
        else
            if suggestedcommands[1] then
                command = suggestedcommands[1]
            end
        end

        local p = command:len() or 0
        cursor_pos1, cursor_pos2 = p, p
    end

    if command:len() == 0 then suggestedcommands = commandlist end

    if command == "" then tabpos = 1 end

    cursor_pos1, cursor_pos2 = math.between(cursor_pos1, 0, command:len()), math.between(cursor_pos2, 0, command:len())

    if key == "backspace" or key == "delete" then
        if #suggestedcommands <= 1 then
            tabpos = 1
            suggestedcommands = completeValue(command, commandlist)
        end
    end
end

function console.keyreleased(key)
    multikeys.keyreleased(key)
end

local maxcmdlen = console_width - 127
function console.textinput(text)
    if not console_show or not console_readyforinput then return end

    if cursor_pos2 - cursor_pos1 ~= 0 then
        command, p = command:remove(cursor_pos1, cursor_pos2)
        if math.sign(p) then p = 0 end

        cursor_pos1 = cursor_pos1 + p
        cursor_pos2 = cursor_pos1
    end

    command = command:insert(cursor_pos1, text)
    cursor_pos1 = cursor_pos1 + 1
    cursor_pos2 = cursor_pos1

    cursor_alphadir = true

    suggestedcommands = completeValue(command, commandlist)
end

function console.hasfocus()
    local mx, my = love.mouse.getPosition()
    if console_show then
        if inSquare(mx, my, console_x, console_y, console_width, console_height) then
            return true
        end
    end
    return false
end

function console.wheelmoved(x, y)
    if not console.hasfocus() then return end

    desiredhistorydisplayed = math.between(desiredhistorydisplayed + y * lineheight, -#logs * lineheight + lineheight - padding, print_size)
end

-- sets the position of the cursor relative to the mouse, between chracters
local function getclickpos(mx)
    local remchars = 0
    local command_length = console_font:getWidth(command:sub(1, remchars))

    local mouseontext = mx - console_x - 8
    local position = nil

    while remchars <= command:len() do
        local prechar, nextchar = console_font:getWidth(command:sub(remchars, remchars)) / 2, console_font:getWidth(command:sub(remchars + 1, remchars + 1)) / 2
        command_length = console_font:getWidth(command:sub(1, remchars))
        remchars = remchars + 1

        if isBetween(mouseontext, command_length - prechar, command_length + nextchar) then
            position = remchars - 1
        elseif remchars == command:len() then
            position = command:len()
        end

        if position then
            return position
        end
    end

    time = 0
end

local suggestionsfocus = false
local console_grabpoints = {x = 0, y = 0}
function console.mousemoved(mx, my, dx, dy)
    if not console_show then console_grabbed = false return end

    if console_grabbed then
        console_x = math.between(mx - console_grabpoints.x, 0, window_width - console_width)
        console_y = math.between(my - console_grabpoints.y, 0, window_height - 50)

        if console_magnetized then
            console_magnetized = false
            console_width = console_oldsize.width
            console_height = console_oldsize.height
            console_x = mx - console_width / 2
            console_y = my - 25
        end

        wraplogs()
    elseif console_cornergrabbed then
        console_width = math.max(mx - console_x, 420)
        console_height = math.max(my - console_y, 210)

        wraplogs()
    elseif scrollbar_grabbed then -- this isn't very precise yet unfortunatly
        local nd = desiredhistorydisplayed - dy * (#logs * (lineheight * 2) / print_size)
        desiredhistorydisplayed = math.between(nd, -#logs * lineheight + lineheight - padding, print_size)
        
        love.mouse.setPosition(
            math.between(mx, console_x + console_width - 6, console_x + console_width - 1),
            math.between(my, console_y + 50, console_y + console_height - 69)
        )
    end

    -- if the cursors are enabled for the console, then change them
    if console_cursors then
        if scrollbar_grabbed then
            setCursor(down_pointer)
        elseif inSquare(mx, my, console_x + console_width - 8, scrollbar_y + console_y + 50, 8, scrollbar_height) then -- on scrollbar
            setCursor(pointer)
        elseif inSquare(mx, my, console_x + console_width - 16, console_y + console_height - 16, 24, 24) then
            setCursor(resize) -- bottom right corner
        elseif inSquare(mx, my, console_x + console_width - 32, console_y + 16, 16, 16) -- on cross button
        or inSquare(mx, my, console_x + console_width - 123, console_y + console_height - 48, 119, 28)
        or suggestionsfocus then
            setCursor(pointer)
        elseif inSquare(mx, my, console_x + 4, console_y + console_height - 48, console_width - 127, 28) then -- in text input
            setCursor(ibeam)

            if console_readyforinput and command ~= "" and largeselect then
                cursor_pos2 = getclickpos(mx)
            end
        elseif inSquare(mx, my, console_x, console_y, console_width, 50) then
            setCursor(hand) -- on console top
        else
            setCursor(arrow)
        end
    end
end

function console.mousepressed(mx, my, button)
    if console_show and not console.hasfocus() then
        console_readyforinput = false
        return
    elseif not console.hasfocus() then
        return
    end

    if button == 1 and (not console_grabbed or not console_scrollgrabbed) then
        if inSquare(mx, my, console_x + console_width - 8, scrollbar_y + console_y + 50, 8, scrollbar_height) then -- on scrollbar
            scrollbar_grabbed = true
        elseif inSquare(mx, my, console_x + console_width - 123, console_y + console_height - 48, 119, 28) then -- on execute button
            love.mouse.setCursor(down_pointer)
            console.runcommand()
        elseif inSquare(mx, my, console_x + console_width - 16, console_y + console_height - 16, 24, 24) then -- on bottom-right corner
            console_cornergrabbed, console_readyforinput = true, false
        elseif inSquare(mx, my, console_x, console_y, console_width, 50) and
        not inSquare(mx, my, console_x + console_width - 32, console_y + 16, 16, 16) then -- on window top
            console_grabbed, console_readyforinput = true, false
            console_grabpoints = {x = mx - console_x, y = my - console_y}
        elseif inSquare(mx, my, console_x + 4, console_y + console_height - 48, console_width - 127, 28) then -- on text input
            if console_readyforinput and command ~= "" then
                largeselect = true
                local p = getclickpos(mx)
                cursor_pos1, cursor_pos2 = p, p
                cursor_alphadir = true
            end

            console_readyforinput = true
        elseif inSquare(mx, my, console_x + console_width - 32, console_y + 16, 16, 16) then -- on close button
            love.mouse.setCursor(down_pointer)
            console_grabbed = false
            console_hidden = true
            console_animation = "close"
        elseif not suggestionsfocus then
            console_readyforinput = false
        end
    end
end

local function magnetize_console(pos)
    console_magnetized = true
    console_oldsize = {width = console_width, height = console_height, x = console_x, y = console_y}

    if pos == "top" then
        console_width = window_width
        console_height = window_height / 2.5
        console_x = 0
        console_y = 0
    elseif pos == "bottom" then
        console_width = window_width
        console_height = window_height / 2.5
        console_x = 0
        console_y = window_height - window_height / 2.5
    elseif pos == "left" then
        console_width = window_width / 2.5
        console_height = window_height
        console_x = 0
        console_y = 0
    elseif pos == "right" then
        console_width = window_width / 2.5
        console_height = window_height
        console_x = window_width - window_width / 2.5
        console_y = 0
    end
end

local function drop_console(mx)
    if not console_show then return end

    if console_grabbed then
        if console_y == 0 then
            magnetize_console("top")
        elseif console_y + 50 == window_height then
            magnetize_console("bottom")
        elseif mx and mx <= 50 and console_x == 0 then
            magnetize_console("left")
        elseif mx and mx >= window_width - 50 and console_x + console_width == window_width then
            magnetize_console("right")
        end

        setCursor(hand)
    end

    console_grabbed = false
    console_scrollgrabbed = false
    console_cornergrabbed = false
end

function console.mousereleased(mx, my)
    drop_console(mx)
    console_x, console_y = math.round(console_x, 0), math.round(console_y, 0)
    console_width, console_height = math.round(console_width, 0), math.round(console_height, 0)

    scrollbar_grabbed = false
    largeselect = false

    desiredhistorydisplayed = desiredhistorydisplayed + math.close(desiredhistorydisplayed, lineheight)

    wraplogs()

    if love.mouse.getCursor() == down_pointer then
        love.mouse.setCursor(pointer)
    end
end

function console.mousefocus(focus)
    drop_console()
end

local function setconsolecolor(r, g, b, a)
    love.graphics.setColor(r / 255, g / 255, b / 255, a * console_alpha)
end

local console_magnetalpha = 0
local console_magnetx, console_magnety = 0, 0
local console_magnetwidth, console_magnetheight = 0, 0
function console.draw()
    if not console_show then return end

    love.graphics.setFont(console_font)

    local mx, my = love.mouse.getPosition()
    if console_grabbed then
        setCursor(grab)

        setconsolecolor(54, 33, 34, console_magnetalpha)
        local speed = love.timer.getDelta() * 5
        if console_y == 0 then
            console_magnetalpha = math.min(console_magnetalpha + speed, 0.75)
            console_magnetx, console_magnety = 0, 0
            console_magnetwidth, console_magnetheight = window_width, window_height / 2.5
        elseif console_y + 50 == window_height then
            console_magnetalpha = math.min(console_magnetalpha + speed, 0.75)
            console_magnetx, console_magnety = 0, window_height - window_height / 2.5
            console_magnetwidth, console_magnetheight = window_width, window_height / 2.5
        elseif mx and mx <= 50 and console_x == 0 then
            console_magnetalpha = math.min(console_magnetalpha + speed, 0.75)
            console_magnetx, console_magnety = 0, 0
            console_magnetwidth, console_magnetheight = window_width / 2.5, window_height
        elseif mx and mx >= window_width - 50 and console_x + console_width == window_width then
            console_magnetalpha = math.min(console_magnetalpha + speed, 0.75)
            console_magnetx, console_magnety = window_width - window_width / 2.5, 0
            console_magnetwidth, console_magnetheight = window_width / 2.5, window_height
        else
            console_magnetalpha = math.max(console_magnetalpha - speed * 2, 0)
        end

        love.graphics.rectangle("fill", console_magnetx, console_magnety, console_magnetwidth, console_magnetheight)
    elseif not console_grabbed and console_magnetalpha ~= 0 then
        console_magnetalpha = 0
    end

    love.graphics.translate(console_x + console_width / 2, console_y + console_height / 2)
    love.graphics.scale(console_scale)

    local original_x, original_y = console_x, console_y
    local console_x, console_y = -console_width / 2, -console_height / 2

    -- draw console frame
    setconsolecolor(54, 62, 55, .75) -- frame
    love.graphics.rectangle("fill", console_x, console_y, console_width, console_height)

    padding = 0
    print_size = console_height - 137
    for i = 1, #wrapped_logs do
        local log = logs[i]
        local wrapped_log, previous_log = wrapped_logs[i], wrapped_logs[math.max(i-1, 1)]
        local log_y = historydisplayed + i * lineheight + -(console_height / 2) + 50 - lineheight

        padding = padding + (#previous_log - 1) * lineheight
        log_y = log_y + padding

        if isBetween(log_y, -console_height / 2, console_height / 2 - 68) then
            if i % 2 == 0 then
                setconsolecolor(54, 62, 55, .75)
                love.graphics.rectangle("fill", console_x, log_y - 1, console_width, lineheight * #wrapped_log)
            end

            setconsolecolor(log.type[1], log.type[2], log.type[3], 1) -- type
            local log_height = lineheight * #wrapped_log - 2
            love.graphics.rectangle("fill", console_x + 1, log_y, timewidth + 8, log_height, 2)

            setconsolecolor(255, 255, 255, 1) -- type
            for num, line in pairs(wrapped_log) do
                local y = log_y + (num - 1) * lineheight
                if isBetween(y, -console_height / 2, console_height / 2 - 68) then
                    love.graphics.print(line, console_x + timewidth + 12, y)
                end
            end

            love.graphics.print(log.time, console_x + 4, math.round(log_y + log_height / 2 - console_font:getHeight(log.time) / 2, 1))
        end
    end

    setconsolecolor(255, 255, 255, 1)

    -- draw traceback
    padding = 0
    for i = 1, #wrapped_logs do
        local log = logs[i]
        local wrapped_log, previous_log = wrapped_logs[i], wrapped_logs[math.max(i-1, 1)]
        local log_y = historydisplayed + i * lineheight + -(console_height / 2) + 50 - lineheight

        padding = padding + (#previous_log - 1) * lineheight
        log_y = log_y + padding

        if isBetween(log_y, -console_height / 2, console_height / 2 - 68) then
            local log_yy = log_y + original_y + console_height / 2
            local log_height = lineheight * #wrapped_log

            if inSquare(mx, my, original_x, log_yy, timewidth + 8, log_height) then
                setconsolecolor(22, 25, 27, 1)
                local text = "From: " .. log.from
                local x, y = mx + 18 - original_x + console_x, math.between(my - original_y + console_y, console_y + 50 + 8, console_height / 2 - 83)
                love.graphics.rectangle("fill", x, y - 8, console_font:getWidth(text) + 8, console_font:getHeight(text) + 8)
                setconsolecolor(255, 255, 255, 1)
                love.graphics.print(text, x + 4, y - 4)
            end

            if love.mouse.isDown(1) then
                if not console_grabbed and not scrollbar_grabbed then
                    if inSquare(mx, my, original_x, log_yy, console_width - 8, log_height) then
                        local text = ("%s %s [%s]: %s\n"):format(log.time, log.from, log.letter, log.event)
                        love.mouse.setCursor(plus_arrow)
                        love.system.setClipboardText(text)
                    end
                end
            end
        end
    end

    setconsolecolor(22, 25, 27, 1) -- top frame
    love.graphics.rectangle("fill", console_x, console_y, console_width, 50)
    love.graphics.rectangle("line", console_x, console_y, console_width, console_height)

    setconsolecolor(108, 124, 130, 1) -- frame title
    love.graphics.print("Console", console_x + 25, console_y + (50 - console_font:getHeight("Console")) / 2)
    love.graphics.draw(cross, console_x + console_width - 32, console_y + 16)

    setconsolecolor(68, 68, 68, 1) -- frame bottom
    love.graphics.rectangle("fill", console_x, console_y + console_height - 64, console_width, 64)
    setconsolecolor(55, 55, 55, 1)
    love.graphics.setLineWidth(10)
    love.graphics.line(console_x, console_y + console_height - 64, console_x + console_width, console_y + console_height - 64) -- bottom border
    love.graphics.setLineWidth(1)

    setconsolecolor(22, 25, 27, 1)
    love.graphics.rectangle("fill", console_x + 4, console_y + console_height - 48, console_width - 48, 28, 5) -- text input
    
    -- draw halo
    if console_textinputalpha > 0 then
        setconsolecolor(212, 172, 13, console_textinputalpha)
        love.graphics.rectangle("line", console_x + 4, console_y + console_height - 48, console_width - 125, 28, 5) -- text input
    end

    setconsolecolor(100, 106, 116, 1)
    love.graphics.rectangle("fill", console_x + console_width - 123, console_y + console_height - 48, 119, 28) -- execute command button

    setconsolecolor(255, 255, 255, 1)
    love.graphics.print("Execute", console_x + console_width - 115 + math.round(console_font:getWidth("Execute") / 2, 0), console_y + console_height - 42) -- execute button text

    -- draw command
    if console_textinputalpha > 0 then
        local cursor_x = console_x + 8 + fake_cursor1 - .5
        local cursor_width = console_x + 8 + (fake_cursor2 - cursor_x) + .5
        setconsolecolor(142, 145, 147, cursor_alpha)
        love.graphics.rectangle("fill", cursor_x, console_y + console_height - 42, cursor_width, 16)
        setconsolecolor(255, 255, 255, 1)

        if command ~= "" then
            local possiblecommands = completeValue(command, commandlist)
            local commandname = possiblecommands[1] or command:split(" ")[1]

            local closestcommand = commands[commandname]
            if closestcommand then
                love.graphics.print(("%s: %s. Usage: %s"):format(commandname, closestcommand.description or "", closestcommand.usage or ""), console_x + 8, console_y + console_height - 16)
            else
                love.graphics.print("Unknown command.", console_x + 8, console_y + console_height - 16)
            end

            if #suggestedcommands > 1 then
                setconsolecolor(22, 25, 27, console_textinputalpha)
                local width, height = 0, #suggestedcommands * lineheight

                for _, name in pairs(suggestedcommands) do
                    local cmdsize = console_font:getWidth(name)
                    if cmdsize >= width then
                        width = cmdsize + 16
                    end
                end

                local x, y = console_x + 8 + fake_cursor2, console_y + console_height - 54 - height
                love.graphics.rectangle("fill", x, y, width, height)

                local x2, y2 = x + original_x + console_width / 2, y + original_y + console_height / 2
                if inSquare(mx, my, x2, y2, width, height) then
                    setconsolecolor(52, 55, 57, console_textinputalpha)
                    local hovering = math.trunc((my - y2 - 1) / lineheight)
                    love.graphics.rectangle("fill", x, y + hovering * lineheight, width, lineheight)

                    if love.mouse.isDown(1) then
                        command = suggestedcommands[hovering+1]
                        local p = command:len()
                        cursor_pos1, cursor_pos2 = p, p
                    end

                    suggestionsfocus = true
                else
                    suggestionsfocus = false
                end

                setconsolecolor(255, 255, 255, console_textinputalpha)
                for index, name in pairs(suggestedcommands) do
                    love.graphics.print(name, x + 4, math.round(y + (index - 1) * lineheight + 2, 0))
                end
            else
                suggestionsfocus = false
            end
        else
            love.graphics.print("Type a command...", console_x + 8, console_y + console_height - 16)
        end
    else
        suggestionsfocus = false
    end

    setconsolecolor(255, 255, 255, 1)
    love.graphics.print(command, console_x + 8, console_y + console_height - 42)

    -- bottom right corner
    setconsolecolor(55, 55, 55, 1)
    love.graphics.draw(corner, console_x + console_width - 16, console_y + console_height - 16)

    -- scroll bar
    love.graphics.translate(console_x + console_width - 8, -console_height / 2 + 50)
    setconsolecolor(22, 25, 27, 1)
    love.graphics.rectangle("fill", 0, scrollbar_y, 8, scrollbar_height)

    love.graphics.origin()
end

local callbacks = {
    "update", "textinput", "keypressed", "keyreleased", "wheelmoved", "mousepressed",
    "mousereleased", "resize", "mousefocus", "draw", "mousemoved"
}
function console.registercallbacks()
	local registry = {}
    for _, f in ipairs(callbacks) do
        registry[f] = love[f] or function() end
        love[f] = function(...)
            registry[f](...)
			console[f](...)
		end
	end
end

return console