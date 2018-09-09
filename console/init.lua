require "console/utility"

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
local max_lines = 0

-- load commands
local commands = love.filesystem.load("console/commands.lua")()
local commandlist, commandlist_text = {""}, ""
local console_memory = {}
for name in pairs(commands) do
    commandlist[#commandlist + 1] = name -- create the command list
    commandlist_text = commandlist_text .. name .. " "

    local cmd = commands[name]
    if cmd.memory then
        console_memory[name] = {}
    end
end

-- load console states
local console_grabbed = false
local console_scrollgrabbed = false
local console_cornergrabbed = false
local console_readyforinput = true
local console_show = false
local console_hidden = not console_show
local console_animation, console_animationtime, console_scale = console_show and "open", 0, 1

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

local logs = {}
local command, waiting_input, lastcommand, waiting_type, historypos = "", "_", {}, "_", 1
local time = 0
local cursor_pos = 0
local repeated = {}
local historydisplayed = 0
local tabpos, tabswitch = 1, true -- used when tabulation is pressed

function setCursor(cursor)
    love.mouse.setCursor(cursor)
end

function console.print(str, type)
    local traceback = ((debug.traceback(""):gsub("stack traceback:","")):split("\n")[2])
    local from_file = ("%s:%s"):format( -- this line is wtf
        (((traceback:split(":")[1]):gsub("\9","")):gsub(".lua","")),
        (((traceback:split(":")[2])))
    )
    if str == nil then str = "nil" end

    if type == "debug" or type == 1 then
        type = {99, 57, 116}
    elseif type == "error" or type == 2 then
        type = {100, 30, 22}
    else
        type = {251, 219, 86}
    end

    if traceback:match("string") then
        love.thread.getChannel("console_channel"):push(str)
        return
    end

    logs[#logs + 1] = {
        time = os.date("%H:%M:%S"),
        from = from_file,
        event = str,
        type = type,
    }

    if console_loglimit and #logs > console_loglimit then
        table.remove(logs, 1) -- removes the first element from the logs
    end
end

function console.getlogs() return tableToString(logs, "\n") end

function console.update(dt)
    local thread_log = love.thread.getChannel("console_channel"):pop()
    if thread_log then console.print(thread_log) end

    for instruction, cmd in pairs(commands) do
        local update = cmd.update
        if update then
            update(dt, console_memory[instruction])
        end
    end

    if not console_show then setCursor(arrow) return end

    if console_animation == "open" then
        console_animationtime = console_animationtime + dt
        console_scale = outElastic(console_animationtime, 0, 1, 1, 1, 1)

        if console_animationtime >= 1 then
            console_animation, console_animationtime, console_scale = false, 0, 1
        end
    elseif console_animation == "close" then
        console_animationtime = console_animationtime + dt
        console_scale = 1 - inElastic(console_animationtime, 0, 1, .5, 1, 1)

        if console_animationtime >= .5 then
            console_animation, console_animationtime, console_scale = false, 0, 1
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

    local originalcommand = command -- save the original command, just in case
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
            local error = cmd.execution(command, args, originalcommand, memory)
            if error then console.print("Usage: " .. cmd.usage) end
        else
            console.print("Usage: " .. cmd.usage)
        end
    else
        console.print("List of valid commands: " .. commandlist_text)
    end

    command = ""
    cursor_pos = 0
    tabpos = 1
    tabswitch = true
    historydisplayed = 0
end

function console.keypressed(key)
    if key == "f1" then
        console_hidden = not console_hidden
        console.print("Console visibility toggled")

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
        command = command:remove(cursor_pos) -- delete backward
        cursor_pos = math.max(cursor_pos - 1, 1)
        tabswitch = false
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
        cursor_pos = makeBetween(cursor_pos - 1, 0, command:len())
    elseif key == "right" then
        cursor_pos = makeBetween(cursor_pos + 1, 0, command:len())
    elseif key == "rctrl" then -- pasting commands
        command = command .. love.system.getClipboardText()
        cursor_pos = command:len()
    elseif key == "tab" then
        if tabswitch then
            tabpos = tabpos + 1
            if tabpos > #commandlist then tabpos = 1 end
            command = commandlist[tabpos]
        elseif not tabswitch then
            result = completeValue(command, commandlist)
            tabpos = 1
            if result[1] then command = result[1] end
        end

        cursor_pos = command:len() or 0
    end

    if cursor_pos < command:len() then waiting_type, waiting_input = "|", "|"
    else waiting_type, waiting_input = "_", "_" end

    if command == "" then tabswitch = true end
end

function console.text(text)
    if not console.hasfocus() or not console_readyforinput then return end

    tabswitch = false
    command = command:insert(cursor_pos, text)
    cursor_pos = cursor_pos + 1
end

function console.hasfocus()
    local mx, my = love.mouse.getPosition()
    return inSquare(mx, my, console_x, console_y, console_width, console_height) and console_show
end

function console.mousewheel(x, y)
    if not console.hasfocus() then return end

    historydisplayed = makeBetween(historydisplayed + y, 0, #logs - max_lines)
end

function console.mousemoved(mx, my, dx, dy)
    if not console_show then console_grabbed = false return end

    if console_grabbed then
        console_x = makeBetween(console_x + dx, 0, window_width - console_width)
        console_y = makeBetween(console_y + dy, 0, window_height - 50)

        if console_magnetized then
            console_magnetized = false
            console_width = console_oldsize.width
            console_height = console_oldsize.height
            console_x = mx - console_width / 2
            console_y = my - 25
        end
    elseif console_cornergrabbed then
        console_width = math.max(mx - console_x, 420)
        console_height = math.max(my - console_y, 210)
    elseif not console.hasfocus() then
        console_readyforinput = false
    end
end

function console.mousepressed(mx, my, button)
    if not console.hasfocus() then return end

    if button == 1 and (not console_grabbed or not console_scrollgrabbed) then
        local scrollbar_y = math.max(console_y + 50 + ((1 - (historydisplayed / (#logs - max_lines))) * (console_height - 115)) - 12, console_x + 50)
        if inSquare(mx, my, console_x + console_width - 123, console_y + console_height - 48, 119, 28) then
            console.runcommand() -- on execute button
        elseif inSquare(mx, my, console_x + console_width - 16, console_y + console_height - 16, 24, 24) then
            console_cornergrabbed, console_readyforinput = true, false -- on corner
        elseif inSquare(mx, my, console_x, console_y, console_width, 50) and not inSquare(mx, my, console_x + console_width - 32, console_y + 16, 16, 16) then
            console_grabbed, console_readyforinput = true, false -- on window top
        elseif inSquare(mx, my, console_x + console_width - 8, scrollbar_y, 8, 24) then
            console_scrollgrabbed = true -- on scrollbar
        elseif inSquare(mx, my, console_x + 4, console_y + console_height - 48, console_width - 127, 28) then
            console_readyforinput = true -- on text input
        end
    end
end

function console.mousereleased()
    if not console_show then return end

    if console_grabbed then
        if console_y == 0 then
            console_magnetized = true
            console_oldsize = {width = console_width, height = console_height, x = console_x, y = console_y}

            console_width = window_width
            console_height = window_height / 2.5
            console_x = 0
        elseif console_y + 50 == window_height then
            console_magnetized = true
            console_oldsize = {width = console_width, height = console_height, x = console_x, y = console_y}

            console_width = window_width
            console_height = window_height / 2.5
            console_y = window_height - window_height / 2.5
            console_x = 0
        end
    end
        

    console_grabbed = false
    console_scrollgrabbed = false
    console_cornergrabbed = false
end

function console.draw()
    if not console_show then return end

    love.graphics.translate(console_x + round(console_width / 2, 0), console_y + round(console_height / 2, 0))
    love.graphics.scale(console_scale)
    local log_length = #logs

    love.graphics.setFont(console_font)

    local mx, my = love.mouse.getPosition()
    if console_grabbed then
        setCursor(grab)
    elseif inSquare(mx, my, console_x + console_width - 16, console_y + console_height - 16, 24, 24) then
        setCursor(resize) -- bottom right corner
    elseif inSquare(mx, my, console_x + console_width - 32, console_y + 16, 16, 16) then
        setCursor(pointer) -- on cross button
        if love.mouse.isDown(1) then
            console_grabbed = false
            console_hidden = true
            console_animation = "close"
        end
    elseif inSquare(mx, my, console_x + 4, console_y + console_height - 48, console_width - 127, 28) then
        setCursor(ibeam) -- in text input
    elseif inSquare(mx, my, console_x, console_y, console_width, 50) then
        setCursor(hand) -- on console top
        if love.mouse.isDown(1) then console_readyforinput = false end
    elseif inSquare(mx, my, console_x + console_width - 123, console_y + console_height - 48, 119, 28) then
        setCursor(pointer) -- on execute button
    else
        setCursor(arrow)
        if love.mouse.isDown(1) then console_readyforinput = false end
    end

    local original_x, original_y = console_x, console_y
    local console_x, console_y = round(-console_width / 2, 0), round(-console_height / 2, 0)

    -- draw console frame
    love.graphics.setColor(54 / 255, 62 / 255, 55 / 255, .75) -- frame
    love.graphics.rectangle("fill", console_x, console_y, console_width, console_height)

    love.graphics.setColor(68 / 255, 68 / 255, 68 / 255, 1) -- frame bottom
    love.graphics.rectangle("fill", console_x, console_y + console_height - 64, console_width, 64)
    love.graphics.setColor(55 / 255, 55 / 255, 55 / 255, 1)
    love.graphics.setLineWidth(10)
    love.graphics.line(console_x, console_y + console_height - 64, console_x + console_width, console_y + console_height - 64) -- bottom border
    love.graphics.setLineWidth(1)

    love.graphics.setColor(22 / 255, 25 / 255, 27 / 255, 1)
    love.graphics.rectangle("fill", console_x + 4, console_y + console_height - 48, console_width - 127, 28) -- text input
    love.graphics.setColor(100 / 255, 106 / 255, 116 / 255, 1)
    love.graphics.rectangle("fill", console_x + console_width - 123, console_y + console_height - 48, 119, 28) -- execute command button

    -- draw log lines
    max_lines = round((console_height - 96) / lineheight, 0) - 2
    local min_log, max_log = math.max(log_length - max_lines + -historydisplayed, 1), log_length + -historydisplayed
    local printed_logs = (max_log - min_log) + 1
    local anchor = -console_y - lineheight - 50

    for i = min_log, max_log do
        local log = logs[i]
        if log then
            local log_pos = i - printed_logs
            local log_y = anchor - (min_log - log_pos) * lineheight

            if i % 2 == 0 then
                love.graphics.setColor(54 / 255, 62 / 255, 55 / 255, .75)
                love.graphics.rectangle("fill", console_x, log_y - 1, console_width, lineheight, 2)
            end

            love.graphics.setColor(log.type[1] / 255, log.type[2] / 255, log.type[3] / 255, 1) -- type
            love.graphics.rectangle("fill", console_x + 1, log_y, timewidth + 8, lineheight - 2, 2)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(log.time, console_x + 4, log_y)

            local text = log.event:split("\n")[1]
            love.graphics.printf(text, console_x + timewidth + 12, log_y, console_width - timewidth - 12)

            if log.event:match("\n") then
                love.graphics.draw(return_arrow, console_x + timewidth + 24 + console_font:getWidth(text), log_y)
            end
        end
    end

    love.graphics.setColor(22 / 255, 25 / 255, 27 / 255, 1) -- top frame
    love.graphics.rectangle("fill", console_x, console_y, console_width, 50)
    love.graphics.rectangle("line", console_x, console_y, console_width, console_height)

    love.graphics.setColor(108 / 255, 124 / 255, 130 / 255, 1) -- frame title
    love.graphics.print("Console", console_x + 25, console_y + (50 - console_font:getHeight("Console")) / 2)
    love.graphics.draw(cross, console_x + console_width - 32, console_y + 16)

    love.graphics.setColor(1, 1, 1, 1)

    -- draw traceback
    for i = min_log, max_log do
        local log = logs[i]
        local log_pos = i - printed_logs
        local log_y = (original_y + 42) + (i - (log_length - max_lines + -historydisplayed)) * lineheight
        local log_yy = anchor - (min_log - log_pos) * lineheight

        if inSquare(mx, my, original_x, log_y, timewidth + 8, 18) then
            love.graphics.setColor(22 / 255, 25 / 255, 27 / 255, 1)
            local text = "From: " .. log.from
            local x, y = mx + 18 - original_x + console_x, my - original_y + console_y
            love.graphics.rectangle("fill", x, y - 8, console_font:getWidth(text) + 8, console_font:getHeight(text) + 8)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(text, x + 4, y - 4)
        end

        if log.event:match("\n") then
            if inSquare(mx, my, original_x + timewidth + 8, log_y + 1, console_width - (timewidth + 8), lineheight - 1) then
                setCursor(plus_arrow)
                local x, y = console_x + timewidth + 12, log_yy
                local width, lines = console_width - timewidth - 24, #log.event:split("\n")
                love.graphics.setColor(22 / 255, 25 / 255, 27 / 255, 1)
                love.graphics.rectangle("fill", x, y - 2, width, lineheight * (lines - 1) + 12)
                love.graphics.setColor(1, 1, 1, 1)

                love.graphics.printf(log.event, x + 4, y, width)
            end
        end
    end

    -- draw command
    love.graphics.print(command, console_x + 8, console_y + console_height - 42)
    if console_readyforinput then
        love.graphics.print(waiting_input, console_x + 8 + console_font:getWidth(command:sub(1, cursor_pos)), console_y + console_height - 42)

        if command ~= "" then
            local possiblecommands = completeValue(command, commandlist)
            local commandname = possiblecommands[1] or command:split(" ")[1]

            local closestcommand = commands[commandname]
            if closestcommand then
                love.graphics.print(("%s: %s. Usage: %s"):format(commandname, closestcommand.description or "", closestcommand.usage or ""), console_x + 8, console_y + console_height - 16)
            else
                love.graphics.print("Unknown command.", console_x + 8, console_y + console_height - 16)
            end

            if #possiblecommands > 1 then
                love.graphics.setColor(22 / 255, 25 / 255, 27 / 255, 1)
                local height = #possiblecommands * lineheight
                local x, y = console_x + 8 + console_font:getWidth(command:sub(1, cursor_pos)), console_y + console_height - 54 - height
                love.graphics.rectangle("fill", x, y, 64, height)

                love.graphics.setColor(1, 1, 1, 1)
                for index, name in pairs(possiblecommands) do
                    love.graphics.print(name, x + 4, round(y + (index - 1) * lineheight + 2, 0))
                end
            end
        else
            love.graphics.print("Type a command...", console_x + 8, console_y + console_height - 16)
        end
    end

    -- execute button text
    love.graphics.print("Execute", console_x + console_width - 115 + round(console_font:getWidth("Execute") / 2, 0), console_y + console_height - 42)

    -- scroll bar
    love.graphics.setColor(22 / 255, 25 / 255, 27 / 255, 1)
    --local scrollbar_height = (console_height - 103) / 4 - #logs
    local scrollbar_height = 24
    local scrollbar_y = math.max(console_y + 50 + ((1 - (historydisplayed / (log_length - max_lines))) * (console_height - 119 - scrollbar_height / 2)) - scrollbar_height / 2, console_y + 50)
    love.graphics.rectangle("fill", console_x + console_width - 8, scrollbar_y, 8, scrollbar_height)

    -- bottom right corner
    love.graphics.setColor(55 / 255, 55 / 255, 55 / 255, 1)
    love.graphics.draw(corner, console_x + console_width - 16, console_y + console_height - 16)

    love.graphics.origin()
end

return console