console = {}
logs = {}
local command, waiting_input, lastcommand, waiting_type = "", "_", "", "_"
local time = 0
local show = false
local cursor_pos = 0
local lineHeight = 18

function console.print(...)
    local traceback = ((debug.traceback(""):gsub("stack traceback:","")):split("\n")[2])
    local from_file = ("%s:%s"):format( -- this line is wtf
        (((traceback:split(":")[1]):gsub("\9","")):gsub(".lua","")):upper(),
        (((traceback:split(":")[2])))
    )
    local str = ...

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

    if key == "return" then
        console.print("Run command from console: " .. command)
        loadstring(command)()
        lastcommand = command
        command = ""
        cursor_pos = 0
    elseif key == "backspace" then
        command = command:remove(cursor_pos) -- delete backward
        cursor_pos = math.max(cursor_pos - 1, 1)
    elseif key == "delete" then
        command = command:remove(cursor_pos, true) -- delete forward
    elseif key == "up" then
        command = lastcommand
        cursor_pos = command:len()
    elseif key == "left" then
        cursor_pos = makeBetween(cursor_pos - 1, 0, command:len())
    elseif key == "right" then
        cursor_pos = makeBetween(cursor_pos + 1, 0, command:len())
    end

    if cursor_pos < command:len() then waiting_type, waiting_input = "|", "|"
    else waiting_type, waiting_input = "_", "_" end

    return
end

function console.text(text)
    if not console.hasFocus() then return end

    command = command:insert(cursor_pos, text)
    cursor_pos = cursor_pos + 1

    return
end

function console.hasFocus()
    local x, y = love.mouse.getPosition()
    return inSquare(x, y, 0, 0, window_width, window_height / 3 + 5) and show
end

function console.draw()
    if not show then return end

    local max_lines = round(window_height / 3 / lineHeight, 0) - 1
    local log_length = #logs
    love.graphics.setColor(.75, .75, 0, .5)
    love.graphics.rectangle("fill", 0, 0, window_width, window_height / 3)

    love.graphics.setLineWidth(10)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.line(0, window_height / 3 + 5, window_width, window_height / 3 + 5)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(consoleFont)

    for i = log_length - max_lines, log_length do
        love.graphics.print("" .. logs[i], 5, (i - (log_length - max_lines)) * lineHeight - lineHeight)
    end

    love.graphics.print("> " .. command, 5, window_height / 3 - lineHeight)
    local padding = (cursor_pos < command:len() and -1) or 5
    love.graphics.print(waiting_input, padding + consoleFont:getWidth("> " .. command:sub(1, cursor_pos)), window_height / 3 - lineHeight)
end