local P = {}
local PARTS = {}
local ENABLED = true
local WW, WH = 800, 600
local TX, TY = 0, 0

function P.enable(value) ENABLED = value end

function P.window(w, h) WW, WH = w, h end
function P.translation(x, y) TX, TY = x, y end

function P.emit(x, y, r, speed, damping, size, life, vertices, color, fade_out)
    if not ENABLED then return end
    
    local part = {}

    part.r = rf(r.min, r.max, 2)
    part.r_speed = rf(-1, 1, 2)

    part.x, part.y = x, y
    part.x_speed, part.y_speed = math.random(speed - 2, speed + 2) * math.cos(part.r), math.random(speed - 2, speed + 2) * math.sin(part.r)
    part.damping = damping

    part.size = size
    part.max_life, part.life = life, life

    part.color = {
        r = rf(color.r - .05, color.r + .05, 2),
        g = rf(color.g - .05, color.g + .05, 2),
        b = rf(color.b - .05, color.b + .05, 2)
    }

    if color.a then part.color.a = rf(color.a - .1, color.a + .1, 2)
    else part.color.a = 1 end

    part.fade_out = fade_out

    part.shape = {}

    for i=1, vertices * 2 do
        table.insert(part.shape, math.random(0, 1 * size))
    end

    table.insert( PARTS, part )
end

function P.update(dt)
    if not ENABLED then return end

    for index, part in pairs(PARTS) do
        part.x, part.y = part.x + part.x_speed * dt, part.y + part.y_speed * dt
        part.x_speed, part.y_speed = part.x_speed / part.damping, part.y_speed / part.damping
        part.r = part.r + part.r_speed * dt
        part.r_speed = part.r_speed / part.damping
        part.life = part.life - dt
        if part.fade_out then part.color.a = part.life / part.max_life end
        if part.life <= 0 then table.remove(PARTS, index) end
    end
end

function P.draw()
    if not ENABLED then return end

    for index, part in pairs(PARTS) do
        if inSquare(part.x, part.y, TX, TY, WW, WH) then
            love.graphics.push()

            love.graphics.translate(part.x, part.y)
            love.graphics.rotate(part.r)
            love.graphics.translate(-part.size / 2, -part.size / 2)
            love.graphics.scale(math.min(part.life, 1))

            love.graphics.setColor(part.color.r, part.color.g, part.color.b, part.color.a)
            love.graphics.polygon("fill", unpack(part.shape))
            love.graphics.pop()
        end
    end
end

function P.clear()
    PARTS = {}
end

return P