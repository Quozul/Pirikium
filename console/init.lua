require "console/utility"
console_channel = love.thread.newChannel()

local console = {}

-- load config
console.config = love.filesystem.load("console/config.lua")()
local console_width, console_height = console.config.width, console.config.height
local window_width, window_height = love.window.getMode()
local console_x, console_y = window_width / 2 - console_width / 2, window_height / 2 - console_height / 2
local console_font = console.config.font or love.graphics.getFont()
local lineheight, timewidth = console_font:getHeight() + 4, console_font:getWidth("00:00:00")
local console_loglimit = console.config.limit

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
local console_readyforinput = true
console_show = false
local console_hidden = not console_show
local console_animation, console_animationtime, console_scale, console_alpha = console_show and "open", 0, 1, 1

-- load console cursor
local arrow = love.mouse.newCursor( love.image.newImageData("data/console/arrow.png"), 0, 0 )
local plus_arrow = love.mouse.newCursor( love.image.newImageData("data/console/plus_arrow.png"), 0, 0 )
local ibeam = love.mouse.newCursor( love.image.newImageData("data/console/ibeam.png"), 8, 8 )
local grab = love.mouse.newCursor( love.image.newImageData("data/console/grab.png"), 8, 8 )
local hand = love.mouse.newCursor( love.image.newImageData("data/console/hand.png"), 8, 8 )
local pointer = love.mouse.newCursor( love.image.newImageData("data/console/pointer.png"), 5, 1 )
local resize = love.mouse.newCursor( love.image.newImageData("data/console/size.png"), 8, 8 )
local cross = love.graphics.newImage("data/console/cross.png")
local corner = love.graphics.newImage("data/console/corner.png")
local return_arrow = love.graphics.newImage("data/console/return.png")

local logs, wrapped_logs = {}, {}
local command, waiting_input, lastcommand, waiting_type, historypos = "", "_", {}, "_", 1
local time = 0
local cursor_pos = 0
local repeated = {}
local historydisplayed, desiredhistorydisplayed = 0, lineheight
local tabpos, tabswitch = 0, true -- used when tabulation is pressed

function setCursor(cursor)
    love.mouse.setCursor(cursor)
end

local function wraplogs()
    wrapped_logs = {}
    for _, log in pairs(logs) do
        local width, text = console_font:getWrap(log.event, console_width - timewidth - 18)
        table.insert(wrapped_logs, text)
    end
end

function console.print(str, type)
    local traceback = ((debug.traceback(""):gsub("stack traceback:","")):split("\n")[2])
    local from_file = ("%s:%s"):format( -- this line is wtf
        (((traceback:split(":")[1]):gsub("\9","")):gsub(".lua","")),
        (((traceback:split(":")[2])))
    )

    str = tostring(str)

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

    local time = os.date("%H:%M:%S")

    print( ("%s %s [%s]: %s"):format(time, from_file, letter, str) )

    logs[#logs + 1] = {
        time = time,
        from = from_file,
        event = str,
        type = type,
        letter = letter,
    }

    if console_loglimit and #logs > console_loglimit then
        table.remove(logs, 1) -- removes the first element from the logs
    end

    wraplogs()
end

function console.getlogs() return logToString(logs) end

function console.update(dt)
    local thread_log = love.thread.getChannel("console_channel"):pop()
    if thread_log then
        logs[#logs + 1] = thread_log
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

    if not console_show then setCursor(arrow) return end

    local difference = desiredhistorydisplayed - historydisplayed
    if difference ~= 0 then
        local speed = (dt * lineheight * 1.5)
        historydisplayed = historydisplayed + difference * speed
    end

    if console_animation == "open" then
        console_animationtime = console_animationtime + dt
        console_scale = outElastic(console_animationtime, 0, 1, 1, 1, 1)

        if console_animationtime >= 1 then
            console_animation, console_animationtime, console_scale = false, 0, 1
        end
    elseif console_animation == "close" then
        console_animationtime = console_animationtime + dt
        console_alpha = console_alpha - dt / .25

        if console_animationtime >= .25 then
            console_animation, console_animationtime, console_scale, console_alpha = false, 0, 1, 1
            console_show = false
        end
    end

    if console.hasfocus() then love.keyboard.setKeyRepeat(true)
    else love.keyboard.setKeyRepeat(false) end

    time = time + dt
    if time >= .5 then
        if waiting_input == "" then waiting_input = waiting_type
        else waiting_input = "" end
        time = 0
    end
end

function console.addtomemory(instruction, name, value)
    if not name or not value then return end
    console_memory[instruction][name] = value
end

function console.remfrommemory(instruction, name)
    if not console_memory[instruction][name] then return end
    console_memory[instruction][name] = nil
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

    command = ""
    cursor_pos = 0
    tabpos = 1
    tabswitch = true
    historydisplayed = historydisplayed - lineheight
end

function console.keypressed(key)
    if key == "f1" then
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

    if not console.hasfocus() or not console_readyforinput then return end

    if key == "return" or key == "kpenter" then
        console.runcommand()
    elseif key == "backspace" then
        if cursor_pos ~= 0 then
            command = command:remove(cursor_pos) -- delete backward
            cursor_pos = math.max(cursor_pos - 1, 0)
            tabswitch = false
        end
    elseif key == "delete" then
        command = command:remove(cursor_pos, true) -- delete forward
        tabswitch = false
    elseif key == "up" then
        historypos = math.max(historypos - 1, 1)
        command = lastcommand[historypos] or ""
        cursor_pos = command:len() or 0
    elseif key == "down" then
        historypos = math.min(historypos + 1, #lastcommand + 1)
        command = lastcommand[historypos] or ""
        cursor_pos = command:len() or 0
    elseif key == "left" then
        cursor_pos = math.between(cursor_pos - 1, 0, command:len())
    elseif key == "right" then
        cursor_pos = math.between(cursor_pos + 1, 0, command:len())
    elseif key == "rctrl" then -- pasting commands
        command = command .. love.system.getClipboardText()
        cursor_pos = command:len()
    elseif key == "tab" then
        if #suggestedcommands > 0 then
            tabswitch = true
        else
            tabswitch = false
        end

        if tabswitch then
            if tabpos > #suggestedcommands then tabpos = 1 end
            command = suggestedcommands[tabpos]
            tabpos = tabpos + 1
        elseif not tabswitch then
            result = completeValue(command, commandlist)
            tabpos = 1
            if result[1] then command = result[1] end
        end

        cursor_pos = command:len() or 0
    end

    if cursor_pos < command:len() then waiting_type, waiting_input = "|", "|"
    else waiting_type, waiting_input = "_", "_" end

    if command:len() == 0 then suggestedcommands = commandlist end

    if command == "" then tabswitch = true end

    if key == "backspace" or key == "delete" then
        if #suggestedcommands <= 1 then
            tabpos = 1
            suggestedcommands = completeValue(command, commandlist)
        end
    end
end

local maxcmdlen = console_width - 127
function console.text(text)
    if not console.hasfocus() or not console_readyforinput then return end

    tabswitch = false
    command = command:insert(cursor_pos, text)
    cursor_pos = cursor_pos + 1

    suggestedcommands = completeValue(command, commandlist)
end

function console.hasfocus()
    local mx, my = love.mouse.getPosition()
    return inSquare(mx, my, console_x, console_y, console_width, console_height) and console_show
end

function console.mousewheel(x, y)
    if not console.hasfocus() then return end

    desiredhistorydisplayed = math.between(desiredhistorydisplayed + y * lineheight / 2, -#logs * lineheight + lineheight - padding, print_size)
end

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
            
            wraplogs()
        end
    elseif console_cornergrabbed then
        console_width = math.max(mx - console_x, 420)
        console_height = math.max(my - console_y, 210)
        wraplogs()
    elseif not console.hasfocus() then
        console_readyforinput = false
    end
end

function console.mousepressed(mx, my, button)
    if not console.hasfocus() then return end

    if button == 1 and (not console_grabbed or not console_scrollgrabbed) then
        if inSquare(mx, my, console_x + console_width - 123, console_y + console_height - 48, 119, 28) then
            console.runcommand() -- on execute button
        elseif inSquare(mx, my, console_x + console_width - 16, console_y + console_height - 16, 24, 24) then
            console_cornergrabbed, console_readyforinput = true, false -- on corner
        elseif inSquare(mx, my, console_x, console_y, console_width, 50) and not inSquare(mx, my, console_x + console_width - 32, console_y + 16, 16, 16) then
            console_grabbed, console_readyforinput = true, false -- on window top
            console_grabpoints = {x = mx - console_x, y = my - console_y}
        elseif inSquare(mx, my, console_x + 4, console_y + console_height - 48, console_width - 127, 28) then
            console_readyforinput = true -- on text input

            if console_readyforinput and command ~= "" then
                local remchars = 0
                local command_length = console_font:getWidth(command:sub(1, remchars))

                local mouseontext = mx - console_x - 8

                while remchars <= command:len() do
                    local prechar, nextchar = console_font:getWidth(command:sub(remchars, remchars)) / 2, console_font:getWidth(command:sub(remchars + 1, remchars + 1)) / 2
                    command_length = console_font:getWidth(command:sub(1, remchars))
                    remchars = remchars + 1

                    if isBetween(mouseontext, command_length - prechar, command_length + nextchar) then
                        cursor_pos = remchars - 1
                        waiting_type = "|"
                        waiting_input = waiting_type
                        break
                    elseif remchars == command:len() then
                        cursor_pos = command:len()
                        waiting_type = "_"
                        waiting_input = waiting_type
                        break
                    end
                end
            end
        elseif inSquare(mx, my, console_x + console_width - 32, console_y + 16, 16, 16) then
            console_grabbed = false
            console_hidden = true
            console_animation = "close"
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
    end

    console_grabbed = false
    console_scrollgrabbed = false
    console_cornergrabbed = false
end

function console.mousefocus(focus)
    drop_console()
end

function console.mousereleased(mx, my)
    drop_console(mx)
    wraplogs()
end

local function setconsolecolor(r, g, b, a)
    love.graphics.setColor(r / 255, g / 255, b / 255, a * console_alpha)
end

local console_magnetalpha = 0
local console_magnetx, console_magnety = 0, 0
local console_magnetwidth, console_magnetheight = 0, 0
local suggestionsfocus = false
function console.draw()
    if not console_show then return end

    local log_length = #logs

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
    elseif inSquare(mx, my, console_x + console_width - 16, console_y + console_height - 16, 24, 24) then
        setCursor(resize) -- bottom right corner
    elseif inSquare(mx, my, console_x + console_width - 32, console_y + 16, 16, 16) then
        setCursor(pointer) -- on cross button
    elseif inSquare(mx, my, console_x + 4, console_y + console_height - 48, console_width - 127, 28) then
        setCursor(ibeam) -- in text input
    elseif inSquare(mx, my, console_x, console_y, console_width, 50) then
        setCursor(hand) -- on console top
        if love.mouse.isDown(1) then console_readyforinput = false end
    elseif inSquare(mx, my, console_x + console_width - 123, console_y + console_height - 48, 119, 28) or suggestionsfocus then
        setCursor(pointer) -- on execute button
    else
        setCursor(arrow)
        if love.mouse.isDown(1) then console_readyforinput = false end
    end

    love.graphics.translate(console_x + round(console_width / 2, 0), console_y + round(console_height / 2, 0))
    love.graphics.scale(console_scale)

    local original_x, original_y = console_x, console_y
    local console_x, console_y = round(-console_width / 2, 0), round(-console_height / 2, 0)

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

            love.graphics.print(log.time, console_x + 4, round(log_y + log_height / 2 - console_font:getHeight(log.time) / 2, 0))
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
                local x, y = mx + 18 - original_x + console_x, my - original_y + console_y
                love.graphics.rectangle("fill", x, y - 8, console_font:getWidth(text) + 8, console_font:getHeight(text) + 8)
                setconsolecolor(255, 255, 255, 1)
                love.graphics.print(text, x + 4, y - 4)
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
    love.graphics.rectangle("fill", console_x + 4, console_y + console_height - 48, console_width - 127, 28) -- text input
    setconsolecolor(100, 106, 116, 1)
    love.graphics.rectangle("fill", console_x + console_width - 123, console_y + console_height - 48, 119, 28) -- execute command button
    setconsolecolor(255, 255, 255, 1)
    love.graphics.print("Execute", console_x + console_width - 115 + round(console_font:getWidth("Execute") / 2, 0), console_y + console_height - 42) -- execute button text

    -- draw command
    love.graphics.print(command, console_x + 8, console_y + console_height - 42)
    if console_readyforinput then
        local cursor_x = console_x + 8 + console_font:getWidth(command:sub(1, cursor_pos))
        if waiting_type == "|" then
            cursor_x = cursor_x - 2
        end
        love.graphics.print(waiting_input, cursor_x, console_y + console_height - 42)

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
                setconsolecolor(22, 25, 27, 1)
                local width, height = 0, #suggestedcommands * lineheight

                for _, name in pairs(suggestedcommands) do
                    local cmdsize = console_font:getWidth(name)
                    if cmdsize >= width then
                        width = cmdsize + 16
                    end
                end

                local x, y = console_x + 8 + console_font:getWidth(command:sub(1, cursor_pos)), console_y + console_height - 54 - height
                love.graphics.rectangle("fill", x, y, width, height)

                local x2, y2 = x + original_x + console_width / 2, y + original_y + console_height / 2
                if inSquare(mx, my, x2, y2, width, height) then
                    setconsolecolor(52, 55, 57, 1)
                    local hovering = trunc((my - y2 - 1) / lineheight)
                    love.graphics.rectangle("fill", x, y + hovering * lineheight, width, lineheight)
                    if love.mouse.isDown(1) then
                        command = suggestedcommands[hovering+1]
                        cursor_pos = command:len()
                    end
                    suggestionsfocus = true
                else
                    suggestionsfocus = false
                end

                setconsolecolor(255, 255, 255, 1)
                for index, name in pairs(suggestedcommands) do
                    love.graphics.print(name, x + 4, round(y + (index - 1) * lineheight + 2, 0))
                end
            end
        else
            love.graphics.print("Type a command...", console_x + 8, console_y + console_height - 16)
        end
    end

    -- bottom right corner
    setconsolecolor(55, 55, 55, 1)
    love.graphics.draw(corner, console_x + console_width - 16, console_y + console_height - 16)

    -- scroll bar
    love.graphics.translate(console_x + console_width - 8, -console_height / 2 + 50)
    setconsolecolor(22, 25, 27, 1)

    local container_h = print_size + lineheight
    local object_h = #logs * lineheight + padding - lineheight
    local object_y = historydisplayed

    local scrollbar_height  = math.between(container_h / (object_h / container_h), 4, container_h)
    local scrollbar_y       = -object_y / (object_h / (container_h - scrollbar_height))
    scrollbar_y             = math.between(scrollbar_y, 0, container_h)

    love.graphics.rectangle("fill", 0, scrollbar_y, 8, scrollbar_height)

    love.graphics.origin()
end

return console