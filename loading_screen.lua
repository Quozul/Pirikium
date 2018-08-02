local L = {}

local function rf(min, max, decimals) return math.random(min * 10^decimals, max * 10^decimals) / 10^decimals end
local function round(num, decimals) return math.floor(num * 10^(decimals or 0) + 0.5) / 10^(decimals or 0) end

local width, height = love.window.getMode()

colors = {}
for i = 1, 5 do
    colors[i] = {}
    colors[i].r = rf(0, 1, 2)
    colors[i].g = rf(0, 1, 2)
    colors[i].b = rf(0, 1, 2)
    colors[i].s = i / 5 * 16
    colors[i].d = false
end

font = love.graphics.newFont(18)

function L.update(dt)
    for i = 1, 5 do
        local previous = i - 1
        if previous == 0 then previous = 5 end
        if colors[i].d then
            colors[i].s = math.min(colors[i].s + dt * 100, 32)
            if colors[previous].s >= 32 then
                colors[i].d = false
            end
        else
            colors[i].s = math.max(colors[i].s - dt * 100, 0)
            if colors[previous].s <= 0 then
                colors[i].d = true
            end
        end
    end
end

function L.setText(new_text)
    text = new_text
end

function L.draw()
    for i = 1, 5 do
        love.graphics.setColor(colors[i].r, colors[i].g, colors[i].b)
        love.graphics.rectangle("fill", (width / 2 + (5 * 24) / 2) - i * 24, height / 2 - (16 + colors[i].s) / 2, 16, 16 + colors[i].s)
    end

    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, round((width - font:getWidth(text)) / 2, 0), round((height - font:getHeight(text)) / 2 + 48, 0))
end

return L