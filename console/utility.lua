function inSquare(x1, y1, x2, y2, w2, h2)
    return x1 >= x2 and x1 <= x2 + w2 and y1 >= y2 and y1 <= y2 + h2
end
function makeBetween(value, min, max)
    return math.max(math.min(value, max), min)
end
function round(num, decimals)
    return math.floor(num * 10^(decimals or 0) + 0.5) / 10^(decimals or 0)
end
function string:insert(pos, char)
    return self:sub(1, pos) .. char .. self:sub(pos + 1, self:len())
end
function string:remove(pos, dir)
    if not dir then
        return self:sub(1, pos - 1) .. self:sub(pos + 1, self:len())
    else
        return self:sub(1, pos) .. self:sub(pos + 2, self:len())
    end
end
function completeValue(value, t)
    local closests = {}
    for index, name in pairs(t) do
        if name:sub(1, value:len()) == value then
            table.insert(closests, name)
        end
    end

    if closests ~= {} then return closests end
    return false
end
function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end
-- https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua
function outElastic(t, b, c, d, a, p)
    if t == 0 then return b end
    t = t / d
    if t == 1 then return b + c end
    if not p then p = d * 0.3 end
    local s
    if not a or a < math.abs(c) then
        a = c
        s = p / 4
    else
        s = p / (2 * math.pi) * math.asin(c/a)
    end
    return a * math.pow(2, -10 * t) * math.sin((t * d - s) * (2 * math.pi) / p) + c + b
end
function inElastic(t, b, c, d, a, p)
    if t == 0 then return b end
    t = t / d
    if t == 1  then return b + c end
    if not p then p = d * 0.3 end
    local s
    if not a or a < math.abs(c) then
        a = c
        s = p / 4
    else
        s = p / (2 * math.pi) * math.asin(c/a)
    end
    t = t - 1
    return -(a * math.pow(2, 10 * t) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
end