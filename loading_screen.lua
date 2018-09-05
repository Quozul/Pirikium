local L = {}

local function rf(min, max, decimals) return math.random(min * 10^decimals, max * 10^decimals) / 10^decimals end
local function round(num, decimals) return math.floor(num * 10^(decimals or 0) + 0.5) / 10^(decimals or 0) end

bars = {}
for i = 1, 5 do
    bars[i] = {}
    bars[i].colors = {rf(0, 1, 2), rf(0, 1, 2), rf(0, 1, 2)}
    bars[i].s = i / 5 * 16
    bars[i].direction = false
    bars[i].changing = math.random(1, 3)
    bars[i].changing_direction = false
end

font = love.graphics.newFont(18)

function L.update(dt)
    for i = 1, 5 do
        local previous = i - 1
        if previous == 0 then previous = 5 end
        if bars[i].direction then
            bars[i].s = math.min(bars[i].s + dt * 100, 32)
            if bars[previous].s >= 32 then
                bars[i].direction = false
            end
        else
            bars[i].s = math.max(bars[i].s - dt * 100, 0)
            if bars[previous].s <= 0 then
                bars[i].direction = true
            end
        end

        local color = bars[i].colors[bars[i].changing]
        local color_dir = bars[i].changing_direction

        if color_dir then
            bars[i].colors[bars[i].changing] = color + rf(0, dt, 6)
            if color >= 0.8 then
                bars[i].changing_direction = not color_dir
                bars[i].changing = math.random(1, 3)
            end
        else
            bars[i].colors[bars[i].changing] = color - rf(0, dt, 6)
            if bars[i].colors[bars[i].changing] <= 0.2 then
                bars[i].changing_direction = not color_dir
                bars[i].changing = math.random(1, 3)
            end
        end
    end
end

function L.setText(new_text)
    text = new_text
end

function L.draw()
    for i = 1, 5 do
        love.graphics.setColor(unpack(bars[i].colors))
        love.graphics.rectangle("fill", (window_width / 2 + (5 * 24) / 2) - i * 24, window_height / 2 - (16 + bars[i].s) / 2, 16, 16 + bars[i].s)
    end

    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, round((window_width - font:getWidth(text)) / 2, 0), round((window_height - font:getHeight(text)) / 2 + 48, 0))
end

return L