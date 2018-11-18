require "console/utils"

local console = {}

function console.print(str, type)
    local traceback = ((debug.traceback(""):gsub("stack traceback:","")):split("\n")[2])
    local from_file = ("%s:%s"):format(
        (((traceback:split(":")[1]):gsub("\9","")):gsub(".lua","")),
        (((traceback:split(":")[2])))
    )
    if str == nil then str = "nil" end

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

    local time = os.date("%H:%M:%S")

    local log = {
        time = time,
        from = from_file,
        event = str,
        type = type,
        letter = letter,
    }

    print( ("%s %s [%s]: %s"):format(time, from_file, letter, str) )

    love.thread.getChannel("console_channel"):push(log)
    -- get the log with all of needed stuff and send it to the main thread
end

return console