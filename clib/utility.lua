function isBetween(value, min, max) return value >= min and value <= max end
function makeBetween(value, min, max) return math.max(math.min(value, max), min) end
function signe(num) if num >= 0 then return 1 elseif num < 0 then return 0 end end
function sl(x1, y1, x2, y2) return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 ) end -- segment lengh
function round(num, decimals) return math.floor(num * 10^(decimals or 0) + 0.5) / 10^(decimals or 0) end
function removeDecimal(num) num = tostring(num) return tonumber(num:split(".")[1]) end -- remove decimals
function rf(min, max, decimals) return math.random(min * 10^decimals, max * 10^decimals) / 10^decimals end -- random float
function percent(chance) return math.random(0, 100) <= chance end -- return true if value < chance
function isIn(value, table) for index, element in pairs(table) do if value == element then return true end end end -- check if the given value is in a table
function table.length(table) count = 0 for _ in pairs(table) do count = count + 1 end return count end
function inSquare(x1, y1, x2, y2, w2, h2) return x1 >= x2 and x1 <= x2 + w2 and y1 >= y2 and y1 <= y2 + h2 end
function upper(str) return str:gsub("^%l", string.upper) end
function printTable(table) for index, value in pairs(table) do console.print(index, value) end console.print("Done") end
function completeValue(value, table) for index, name in pairs(table) do if name:sub(1, value:len()) == value then return name end end return false end -- choose the closest value in the table
function string:insert(pos, char) return self:sub(1, pos) .. char .. self:sub(pos + 1, self:len()) end
function string:remove(pos, dir)
    if not dir then return self:sub(1, pos - 1) .. self:sub(pos + 1, self:len())
    else return self:sub(1, pos) .. self:sub(pos + 2, self:len()) end
end
function mergeTables(t1, t2)
    local overwritten = 0
    for k, v in pairs(t2) do
        if t2[k] and t1[k] then
            overwritten = overwritten + 1
        end
        t1[k] = v
    end
    return t1, overwritten
end
function mergeTables_noOverride(t1, t2)
    local lenght = #t1
    for index, value in pairs(t2) do
        t1[lenght + index] = value
    end
    return t1
end
function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end
function tableToString(table, sep)
    local string = ""
    for _, value in pairs(table) do string = string .. sep .. value end
    return string
end
function table.find(list, elem) for k,v in pairs(list) do if v == elem then return k end end return false end

 -- ultra simple camera
function basicCamera(centerx, centery, drawing)
    local w, h = love.window.getMode()
    local x, y = round(w / 2 - centerx, 0), round(h / 2 - centery, 0)
    love.graphics.push("transform")
    love.graphics.translate(x, y)
    drawing()
    love.graphics.pop()
    return x, y
end

-- watch a variable and returns true if it changed
local watchings = {}
function updateWatching(name, value) -- to remove a value, juste send nil as a value
    if not watchings[name] then
        watchings[name] = value
    elseif value ~= watchings[name] then
        console.print(("VARIABLE WATCHING: Value %q as changed to %g"):format(name, value))
        watchings[name] = value
        return true
    else
        watchings[name] = value
    end
    return false
end

function sharpRectangle(mode, x, y, width, height, maxWidth)
    local r, g, b = love.graphics.getColor()
    love.graphics.setColor(.25, .25, .25)
    love.graphics.rectangle("fill", x, y, maxWidth, height)
    love.graphics.setColor(r, g, b)
    love.graphics.polygon(mode,
        x, y + height,
        x, y,
        x + math.min(width + math.min(width, 20), maxWidth), y,
        x + width, y + height
    )
end

function verifyTable(base, verify)
    for value in pairs(base) do
        if verify[value] == nil then
            console.print(value .. " is missing from table to verify")
            return false
        end
    end
    console.print("Nothing is missing")
    return true
end

function queryPoint(world, x, y, blacklist)
    local bodies = world:getBodies()

    for id, body in pairs(bodies) do
        if body:isAwake() then
            local fixtures = body:getFixtures()
            for id, fixture in pairs(fixtures) do
                if not fixture:isSensor() and (blacklist ~= nil and not isIn(fixture:getUserData()[1], blacklist)) then
                    local isInside = fixture:testPoint(x, y)
                    if isInside then return true end
                end
            end
        end
    end
end

function getFormattedTime()
    local time = love.timer.getTime()

    local days = math.floor(time / 86400)
    local hours = math.floor( math.mod(time, 86400) / 3600 )
    local minutes = math.floor( math.mod(time, 3600) / 60 )
    local seconds = math.floor( math.mod(time, 60) )

    local millis = tostring(time):split(".")
    seconds = string.format("%02d", seconds) .. "." .. millis[2]

    return {
        string.format("%d:%02d:%02d:%.2f", days, hours, minutes, seconds),
        string.format("%02d%.2f", minutes, seconds),
    }
end