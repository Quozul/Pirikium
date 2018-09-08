console = {}
logs = {}
local command, waiting_input, lastcommand, waiting_type, historypos = "", "_", {}, "_", 1
local time = 0
local show = false
local cursor_pos = 0
local lineHeight = 18
local repeated = {}
local historydisplayed = 0
local commandlist, tabpos, tabswitch = {"", "lua", "print", "repeat", "stop_repeat", "list_repeat"}, 1, true -- used when tabulation is pressed

function console.print(...)
    local traceback = ((debug.traceback(""):gsub("stack traceback:","")):split("\n")[2])
    local from_file = ("%s:%s"):format( -- this line is wtf
        (((traceback:split(":")[1]):gsub("\9","")):gsub(".lua","")):upper(),
        (((traceback:split(":")[2])))
    )
    local str = ...
    if str == nil then str = "nil" end

    if traceback:match("string") then
        love.thread.getChannel("console_channel"):push(str)
        return
    end

    local log = ("[%s %.1f] %s"):format(from_file, getFormattedTime()[2], str)
    print(log)
    logs[#logs + 1] = log
end

function console.getLog() return tableToString(logs, "\n") end

function console.update(dt)
    local thread_log = love.thread.getChannel("console_channel"):pop()
    if thread_log then console.print(thread_log) end

    for name, cmd in pairs(repeated) do
        if cmd == nil then return end
        cmd.time = cmd.time + dt
        if cmd.time >= cmd.every then
            cmd.command()
            cmd.time = 0
        end
    end

    if not show then return end

    if console.hasFocus() then love.keyboard.setKeyRepeat(true)
    else love.keyboard.setKeyRepeat(false) end

    time = time + dt
    if time >= .5 then
        if waiting_input == "" then waiting_input = waiting_type
        else waiting_input = "" end
        time = 0
    end
end

function console.runcommand()
    if command:split(" ")[1] ~= nil then
        lastcommand[historypos] = command -- add command to history
        historypos = historypos + 1
    end

    command = command .. " "
    local instruction = command:split(" ")[1] or "" -- get instruction
    command = command:gsub(instruction .. " ", "")
    command = command:sub(1, -2) -- remove the space

    if instruction == "lua" then
        local code = loadstring(command)
        if code == nil then
            console.print("Usage: lua <lua script>")
        else
            console.print("Run command from console: " .. command)
            code()
        end
    elseif instruction == "print" then
        if command == "" then
            console.print("Usage: print <value>")
        else
            local value = loadstring("return " .. command)()
            console.print(value)
        end
    elseif instruction == "repeat" then -- repeat 0.2 test console.print("hi")
        local time = tonumber(command:split(" ")[1])
        local name = command:split(" ")[2]
        if time == nil or name == nil then
            console.print("Usage: repeat <time> <name> <command>")
        else
            console.print("New repeat command: " .. name .. " every " .. time .. " seconds")
            command = command:gsub(time .. " " .. name .. " ", "")
            console.print(command)
            repeated[name] = {
                every = time,
                time = 0,
                command = loadstring(command),
            }
        end
    elseif instruction == "stop_repeat" then -- stop_repeat test
        if command == nil then
            console.print("Usage: stop_repeat <name>")
        else
            if repeated[command] then
                console.print("Stop repeating command: " .. command)
                repeated[command] = nil
            elseif command == "" then
                console.print("Please enter a repeated command name")
            else
                console.print("The repeated command: '" .. command .. "' doesn't exist")
            end
        end
    elseif instruction == "list_repeat" then
        local list = ""
        for name in pairs(repeated) do list = list .. name .. " " end
        if list == "" then
            console.print("There are no commands being repeated")
        else
            console.print("Repeted commands: " .. list)
        end
    else
        console.print("Usage: <lua|print|repeat|stop_repeat|list_repeat> <args>")
    end

    command = ""
    cursor_pos = 0
    tabpos = 1
    tabswitch = true
    historydisplayed = 0
end

function console.keypressed(key)
    if key == "f1" then
        show = not show
        console.print("Console visibility toggled")
        if love.keyboard.hasKeyRepeat() and not show then
            love.keyboard.setKeyRepeat(false)
        end
        return
    end

    if not console.hasFocus() then return end

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
            if result then command = result end
        end

        cursor_pos = command:len() or 0
    end

    if cursor_pos < command:len() then waiting_type, waiting_input = "|", "|"
    else waiting_type, waiting_input = "_", "_" end

    if command == "" then tabswitch = true end
end

function console.text(text)
    if not console.hasFocus() then return end

    tabswitch = false
    command = command:insert(cursor_pos, text)
    cursor_pos = cursor_pos + 1
end

function console.hasFocus()
    local x, y = love.mouse.getPosition()
    return inSquare(x, y, 0, 0, window_width, window_height / 3 + 5) and show
end

function console.mousewheel(y)
    if not console.hasFocus() then return end

    historydisplayed = makeBetween(historydisplayed - y, 0, #logs - max_lines)
end

function console.draw()
    if not show then return end

    max_lines = round(window_height / 3 / lineHeight, 0) - 1
    local log_length = #logs
    love.graphics.setColor(.75, .75, 0, .5)
    love.graphics.rectangle("fill", 0, 0, window_width, window_height / 3)

    love.graphics.setLineWidth(10)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.line(0, window_height / 3 + 5, window_width, window_height / 3 + 5)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(consoleFont)

    for i = math.max(log_length - max_lines + -historydisplayed, 1), log_length + -historydisplayed do
        love.graphics.print("" .. logs[i], 5, (i - (log_length - max_lines + -historydisplayed)) * lineHeight - lineHeight)
    end

    love.graphics.print("> " .. command, 5, window_height / 3 - lineHeight)
    local padding = (cursor_pos < command:len() and -1) or 5
    love.graphics.print(waiting_input, padding + consoleFont:getWidth("> " .. command:sub(1, cursor_pos)), window_height / 3 - lineHeight)

    love.graphics.setLineWidth(2)
    local percentage = (1 - (historydisplayed / (log_length - max_lines))) * (window_height / 3)
    love.graphics.line(window_width - 2, percentage - 3, window_width - 2, math.min(percentage + 3, window_height / 3))
    love.graphics.setLineWidth(1)
end