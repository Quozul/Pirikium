function between(value, min, max) return value >= min and value <= max end
function signe(num) if num >= 0 then return 1 elseif num < 0 then return 0 end end
function sl(x1, y1, x2, y2) return math.sqrt( (x2 - x1)^2 + (y2 - y1)^2 ) end -- segment lengh
function round(num, decimals) return math.floor(num * 10^(decimals or 0) + 0.5) / 10^(decimals or 0) end
function rf(min, max, decimals) return math.random(min * 10^decimals, max * 10^decimals) / 10^decimals end -- random float
function percent(chance) return math.random(0, 100) <= chance end -- return true if value < chance
function isIn(value, table) for index, element in pairs(table) do if value == element then return true end end end -- check if the given value is in a table
function table.length(table) count = 0 for _ in pairs(table) do count = count + 1 end return count end
function inSquare(x1, y1, x2, y2, w2, h2) return x1 >= x2 and x1 <= x2 + w2 and y1 >= y2 and y1 <= y2 + h2 end
function upper(str) return str:gsub("^%l", string.upper) end
function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end
function tableToString(table, sep)
    local string = ""
    for _, value in pairs(table) do
        string = string .. sep .. value
    end
    return string
end
function printTable(table) for index, value in pairs(table) do print(index, value) end end
function table.find(list, elem)
    for k,v in pairs(list) do
        print(k .. " " .. v)
        if v == elem then return k end
    end
    return false
end

-- rounded corner rectangle
local right = 0
local left = math.pi
local bottom = math.pi * 0.5
local top = math.pi * 1.5

function rwrc(type, x, y, w, h, r)
	r = r or 15
	love.graphics.rectangle(type, x, y+r, w, h-r*2)
	love.graphics.rectangle(type, x+r, y, w-r*2, r)
	love.graphics.rectangle(type, x+r, y+h-r, w-r*2, r)
	love.graphics.arc(type, x+r, y+r, r, left, top)
	love.graphics.arc(type, x + w-r, y+r, r, -bottom, right)
	love.graphics.arc(type, x + w-r, y + h-r, r, right, bottom)
	love.graphics.arc(type, x+r, y + h-r, r, bottom, left)
end

-- watch a variable and returns true if it changed
local watchings = {}
function updateWatching(name, value) -- to remove a value, juste send nil as a value
    if not watchings[name] then
        watchings[name] = value
    elseif value ~= watchings[name] then
        print(("Value %q as changed to %g"):format(name, value))
        watchings[name] = value
        return true
    else
        watchings[name] = value
    end
    
    return false
end