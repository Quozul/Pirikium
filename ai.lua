local ai = {}

local function getPath(start, goal)
    local ax, ay = start.bod:getPosition()
    local vx, vy = goal.bod:getPosition()

    local path = finder:getPath(math.floor(ax / 64 + 1), math.floor(ay / 64 + 1), math.floor(vx / 64 + 1), math.floor(vy / 64 + 1))

    return path
end

local function nodeToMap(node)
    return (node - 1) * 64
end

function ai.set(ent, ent_id) -- add a view fixture to the ent, usefull for ai as they can see if there is a wall or not
    ent.view = {}
    v = ent.view

    v.bod = love.physics.newBody(world, 100, 100, "dynamic")

    v.shape = love.physics.newEdgeShape(0, 0, 250, 0)

    v.fixture = love.physics.newFixture(v.bod, v.shape)
    v.fixture:setUserData({"View", id = ent_id})
    v.fixture:setSensor(true)
end

function ai.update(ent, target, ent_id) -- => attacker, victim
    if target:getHealth() <= 0 then return end

    local health = ent:getHealth()
    local doHealthChanged = updateWatching("health" .. ent_id, health)
    if doHealthChanged then forceFollow = true end

    local ax, ay = ent.bod:getPosition()
    local vx, vy = target.bod:getPosition()

    local angleToVictim = math.atan2(vy - ay, vx - ax)
    if target.sneaking and math.abs(angleToVictim) > math.pi / 2 and not forceFollow then return end
    -- if the player sneaks behind the enemy, the enemy doesn't notice him

    local currentAngle = ent.bod:getAngle()
    --ent.view.bod:setPosition(ax, ay)
    --ent.view.bod:setAngle(currentAngle)
    local avx, avy = ent.bod:getLinearVelocity()

    path = getPath(ent, target)
    if path == nil then return end -- simple verification

    local dist = sl(ax, ay, vx, vy)
    if ent:getWeapon().type == "melee" then
        inAttackRange = dist + ent:getWeapon().range / 10 < ent:getWeapon().range
        inAttackRadius = between(angleToVictim, currentAngle - ent:getWeapon().radius, currentAngle + ent:getWeapon().radius)
    else
        inAttackRange = dist < 250 -- 250 should be replaced using the spread to get the accuracy
        inAttackRadius = between(angleToVictim, currentAngle - ent:getWeapon().spread, currentAngle + ent:getWeapon().spread)
    end

    if path:getLength() > 10 then
        forceFollow = false
        return
    end

    for node, count in path:nodes() do
        if count == 2 and not inAttackRange then
            local currentX, currentY = nodeToMap(node:getX()) + 32, nodeToMap(node:getY()) + 32
            
            local angleTo = math.atan2(currentY - ay, currentX - ax)
            ent.bod:setAngle(angleTo)

            local speed = love.physics.getMeter() * (4 + ent.skills.speed)

            ent.bod:applyForce(speed * math.cos(currentAngle), speed * math.sin(currentAngle))
            
            break
        elseif inAttackRange and math.abs(angleToVictim) <= math.pi then
            attack(ent, ent_id)
        end
    end
end

function ai.draw(ent, target)
    local x, y = ent.view.bod:getPosition()
    local a = ent.view.bod:getAngle()
    love.graphics.line(x, y, x + math.cos(a) * 250, y + math.sin(a) * 250)

    path = getPath(ent, target)
    if path == nil then return end

    local ax, ay = ent.bod:getPosition()
    local avx, avy = ent.bod:getLinearVelocity()

    for node, count in path:nodes() do
        local currentX, currentY = nodeToMap(node:getX()), nodeToMap(node:getY())

        love.graphics.setColor(1, 0, 0, .5)
        love.graphics.rectangle("line", currentX, currentY, 64, 64)

        if count ~= 1 then
            love.graphics.setColor(0, 0, 0, .5)
            love.graphics.line(previousX + 32, previousY + 32, currentX + 32, currentY + 32)
        end

        previousX, previousY = nodeToMap(node:getX()), nodeToMap(node:getY())
    end
end

return ai