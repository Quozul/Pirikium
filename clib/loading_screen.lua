local L = {}

local function rf(min, max, decimals) return math.random(min * 10^decimals, max * 10^decimals) / 10^decimals end
local function round(num, decimals) return math.floor(num * 10^(decimals or 0) + 0.5) / 10^(decimals or 0) end
local function inOutBack(t, b, c, d, s)
    if not s then s = 1.70158 end
    s = s * 1.525
    t = t / d * 2
    if t < 1 then
        return c / 2 * (t * t * ((s + 1) * t - s)) + b
    else
        t = t - 2
        return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
    end
end

local dots = {}
local window_width, window_height = 0, 0
local font = love.graphics.newFont(18)
local text, percentage, desiredpercentage = "", 0, 0
local alpha = 1
local maxsize = 32
local maxtime = .5

function L.init()
    dots = {}

    for i = 1, 5 do
        local dir = math.random(0, 1)
        if dir == 1 then dir = true else dir = false end

        dots[i] = {
            colors = {rf(0, 1, 2), rf(0, 1, 2), rf(0, 1, 2)},
            changing = math.random(1, 3),
            changing_direction = false,
            size = math.random(0, 1) * maxsize,
            dir = dir,
            time = rf(0, maxtime, 2),
            parent = math.random(1, 5),
        }
    end

    window_width, window_height = love.window.getMode()
end

function L.resize(w, h)
    window_width, window_height = w, h
end

function L.update(dt)
    if percentage >= 100 then
        alpha = alpha - dt
        return
    end

    local diff = desiredpercentage - percentage
    percentage = percentage + diff * dt * 10
    
    for i, dot in pairs(dots) do
        if dot.time >= maxtime * 2 and dots[dot.parent].time >= maxtime * 4 then
            dot.dir = not dot.dir
            dot.time = 0
            dot.parent = math.random(1, 5)
        elseif dot.time <= maxtime then
            if dot.dir then
                dot.size = inOutBack(dot.time, 0, maxsize, maxtime, 2)
            elseif not dot.dir then
                dot.size = inOutBack(dot.time, maxsize, -maxsize, maxtime, 2)
            end
        end

        dot.time = dot.time + dt * rf(1, 1.5, 2)

        local changing_color = dot.changing
        local color = dot.colors[changing_color]
        local color_dir = dot.changing_direction

        if color_dir then
            dot.colors[changing_color] = color + rf(0, dt, 6)
            if color >= 0.8 then
                dot.changing_direction = not color_dir
                dot.changing = math.random(1, 3)
            end
        else
            dot.colors[changing_color] = color - rf(0, dt, 6)
            if color <= 0.2 then
                dot.changing_direction = not color_dir
                dot.changing = math.random(1, 3)
            end
        end
    end
end

function L.setvalue(tex, per)
    per = math.min(per or percentage, 100)
    
    text, desiredpercentage = tex or text, per
end

function L.draw()
    love.graphics.push("transform")
    love.graphics.translate(round(window_width / 2 - (6 * 24) / 2), round(window_height / 2 - 24 / 2))
    
    for i, dot in pairs(dots) do
        local r, g, b = unpack(dot.colors)
        love.graphics.setColor(r, g, b, alpha)
        love.graphics.rectangle("fill", i * 24 - 4, 24 - (16 + dot.size) / 2, 8, 8 + dot.size)
    end

    love.graphics.pop()

    local text = text

    love.graphics.setColor(.25, .25, .25, alpha)
    love.graphics.rectangle("fill", window_width / 2 - 100, window_height / 2 + maxsize + 16, 201, 32)

    if percentage ~= 0 then
        love.graphics.line(window_width / 2 - 100, window_height / 2 + 48, window_width / 2 + 100, window_height / 2 + maxsize + 16)
        love.graphics.setColor(.75, .75, .75, alpha)
        love.graphics.line(window_width / 2 - 100, window_height / 2 + 48, window_width / 2 - 100 + percentage * 2, window_height / 2 + maxsize + 16)
    end

    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(text, round((window_width - font:getWidth(text)) / 2, 0), round((window_height - font:getHeight(text)) / 2 + maxsize + 32, 0))
end

return L