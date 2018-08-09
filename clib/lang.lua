local L = {}
words = {}
local strict = false

function L.decrypt(file)
    if not love.filesystem.getInfo(file) then error(("Lang file %q cannot found!"):format(file)) end

    local msgs = love.filesystem.read(file):split("\n")

    for index, msg in pairs( msgs ) do
        if not msg:match("=") then
            table.remove(msgs, index)
        end
    end

    print(("%d messages loaded"):format(#msgs))

    for index, msg in pairs( msgs ) do
        local word = msg:split("=")
        words[word[1]] = word[2]
    end
end

function L.print(word, values)
    if not words[word] and strict then error(("Word %q cannot be found!"):format(word))
    elseif not words[word] and not strict then return upper(word) end

    if values == nil then return upper( words[word] ) else return upper( words[word]:format( unpack(values) ) ) end
end

return L