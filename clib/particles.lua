local P = {}
local parts = {}

function P.add(amount, x, y, color, size)
    for i=1, amount do
        local p = {}
        p.x, p.y = x, y
        p.color = color

        p.xs, p.ys = rf(-2, 2, 6), rf(-2, 2, 6)

        p.size = size

        table.insert(parts, p)
    end
end

function P.update(dt)
    for e, p in ipairs(parts) do
        p.x, p.y = p.x + p.xs, p.y + p.ys

        p.size = p.size / 1.01

        if p.size <= 0.1 then table.remove(parts, e) end
    end
end

function P.draw()
    for _, p in pairs(parts) do
        love.graphics.setColor(unpack(p.color))

        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end
end

return P