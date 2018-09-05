local P = {}
local EMITS = {}
local PARTS = {}
local ENABLED = true
local WW, WH = 800, 600
local TX, TY = 0, 0
local check = 0

function P.enable(value) ENABLED = value end
function P.window(w, h) WW, WH = w, h end
function P.translation(x, y) TX, TY = x, y end

function P.emit(amount, x, y, r, speed, damping, size, life, vertices, color, fade_out)
    if not ENABLED then return end

    table.insert(EMITS, {emited = 0, amount = amount, x = x, y = y, r = r, speed = speed, damping = damping, size = size, life = life, vertices = vertices, color = color, fade_out = fade_out})
end

function P.update(dt)
    if not ENABLED then return end

    for index, options in pairs(EMITS) do
        local part = {}

        part.r = rf(options.r.min, options.r.max, 2)
        part.r_speed = rf(-1, 1, 2)

        part.x, part.y = options.x, options.y
        part.x_speed, part.y_speed = math.random(options.speed - 2, options.speed + 2) * math.cos(part.r), math.random(options.speed - 2, options.speed + 2) * math.sin(part.r)
        part.damping = options.damping

        part.size = options.size
        part.max_life, part.life = options.life, options.life

        part.color = {
            r = rf(options.color.r - .05, options.color.r + .05, 2),
            g = rf(options.color.g - .05, options.color.g + .05, 2),
            b = rf(options.color.b - .05, options.color.b + .05, 2)
        }

        if options.color.a then part.color.a = rf(options.color.a - .1, options.color.a + .1, 2)
        else part.color.a = 1 end

        part.fade_out = options.fade_out

        part.shape = {}

        for i=1, options.vertices * 2 do
            table.insert(part.shape, math.random(0, 1 * options.size))
        end

        table.insert(PARTS, part)

        EMITS[index].emited = EMITS[index].emited + 1

        if EMITS[index].emited >= EMITS[index].amount then
            table.remove(EMITS, index)
        end
    end

    check = check + dt

    for index, part in pairs(PARTS) do
        part.x, part.y = part.x + part.x_speed * dt, part.y + part.y_speed * dt
        part.x_speed, part.y_speed = part.x_speed / part.damping, part.y_speed / part.damping
        part.r = part.r + part.r_speed * dt
        part.r_speed = part.r_speed / part.damping
        part.life = part.life - dt
        if part.fade_out then part.color.a = part.life / part.max_life end
        if check >= 1 / 30 then
            if part.life <= 0 or queryPoint(world, part.x, part.y, {"Player", "Bullet", "Chest"}) or makeBetween(part.life / part.max_life, 0, 1) then
                PARTS[index] = nil
            end
            check = 0
        end
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
            love.graphics.scale(makeBetween(part.life / part.max_life, 0, 1))

            love.graphics.setColor(part.color.r, part.color.g, part.color.b, part.color.a)
            love.graphics.polygon("fill", unpack(part.shape))
            love.graphics.pop()
        end
    end
end

function P.clear() PARTS = {} end

return P