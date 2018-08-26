doors = {}
chest = {}
orb = {}
local key = love.keyboard.isDown

function doors.add(x, y, r)
    local d = {}

    d.bod = love.physics.newBody( world, x * 64 - 32, y * 64 - 30, "dynamic" )
    d.bod:setLinearDamping(4)
    d.bod:setAngularDamping(4)
    d.bod:setAngle(r)
    d.bod:setBullet(true)
    d.shape = love.physics.newRectangleShape(54, 8)
    d.fixture = love.physics.newFixture(d.bod, d.shape)
    d.fixture:setRestitution(.5)
    d.fixture:setUserData({"Door"})

    d.shadow = Body:new(lightWorld):InitFromPhysics(d.bod)

    d.hinge = love.physics.newBody(world, x * 64 - 32 + math.cos(r) * 32, y * 64 - 32 + math.sin(r) * 32, "static")
    d.hinge:setLinearDamping(16)
    d.hinge:setAngularDamping(16)
    d.hingeShape = love.physics.newRectangleShape(8, 8)
    d.hingeFixture = love.physics.newFixture(d.hinge, d.hingeShape)
    d.hingeFixture:setUserData({"Hinge"})
    d.hingeFixture:setSensor(true)

    d.joint = love.physics.newRevoluteJoint( d.bod, d.hinge,  x * 64 - 32 + math.cos(r) * 28, y * 64 - 32 + math.sin(r) * 26 )

    print("Added one door")

    table.insert(entities.doors, d)
end

function doors.draw(self)
    for index, door in pairs(self.doors) do
        local isInside = door.fixture:testPoint(cmx, cmy)
        if isInside then dotCursor = true end

        love.graphics.push("transform")

        local x, y = door.bod:getPosition()
        local a = door.bod:getAngle()

        love.graphics.setColor(1, 1, 1, 1)

        love.graphics.translate(x, y)
        love.graphics.rotate(a)
        love.graphics.rectangle("fill", -64/2, -8/2, 64, 8)

        love.graphics.pop()

        if config.debug then -- draw door's hinge
            love.graphics.push("transform")

            local x, y = door.hinge:getPosition()
            local a = door.hinge:getAngle()

            love.graphics.setColor(1, 0, 0, .5)

            love.graphics.translate(x, y)
            love.graphics.rotate(a)
            love.graphics.rectangle("fill", -8/2, -8/2, 8, 8)

            love.graphics.pop()
        end
    end
end

function doors.interact(x, y)
    for id, door in pairs(entities.doors) do
        if love.physics.getDistance(door.fixture, ply.fixture) <= 250 then
            local isInside = door.fixture:testPoint(x, y)
            if isInside then
                local dx, dy = door.bod:getPosition()
                local a = math.atan2(py - dy, px - dx)
                local speed = love.physics.getMeter() * -25
                door.bod:applyForce(math.cos(a) * speed, math.sin(a) * speed, cmx, cmy)
                sounds.door:play()
                return
            end
        end
    end
end



function chest.add(x, y)
    local c = {}

    c.time = math.random(10, 25)

    c.bod = love.physics.newBody( world, x * 64 - 32, y * 64 - 32, "dynamic" )
    c.bod:setLinearDamping(16)
    c.bod:setAngularDamping(16)
    c.bod:setAngle( rf(0, 2 * math.pi, 4) )
    c.shape = love.physics.newRectangleShape(48, 48)
    c.fixture = love.physics.newFixture(c.bod, c.shape)
    c.fixture:setRestitution(.1)
    c.fixture:setUserData({"Chest"})

    c.shadow = Body:new(lightWorld):InitFromPhysics(c.bod)

    c.light = Light:new(lightWorld, 150)
    c.light:SetColor(155, 155, 0, 155)

    print("GAME INFO: Added one chest")

    table.insert(entities.chests, c)
end

function chest.update(self, dt)
    for id, chest in pairs(self.chests) do
        if not chest.bod:isActive() then
            local r, g, b, a = chest.light:GetColor()
            a = math.max(a - dt * 155, 0)
            chest.light:SetColor(r, g, b, a)
        end
    end
end

function chest.draw(self)
    for index, chest in pairs(self.chests) do
        if chest.bod:isActive() then
            local isInside = chest.fixture:testPoint(cmx, cmy)
            if isInside then dotCursor = true end

            local x, y = chest.bod:getPosition()
            local a = chest.bod:getAngle()

            chest.light:SetPosition(x, y)
            love.graphics.setColor(1, 1, 1, 1)

            love.graphics.push("transform")

            love.graphics.translate(x, y)
            love.graphics.rotate(a)

            local spriteNum = math.floor(crate_animation.currentTime / crate_animation.duration * #crate_animation.quads) + 1
            love.graphics.draw(crate_animation.spriteSheet, crate_animation.quads[spriteNum], -24, -24)

            love.graphics.pop()
        end
    end
end

function chest.interact(x, y)
    for id, chest in pairs(entities.chests) do
        if chest.bod:isActive() then
            if love.physics.getDistance(chest.fixture, ply.fixture) <= 250 then
                local isInside = chest.fixture:testPoint(x, y)
                if isInside then
                    local cratex, cratey = chest.bod:getPosition()
                    local crateAngle = chest.bod:getAngle()
                    items.drop(cratex, cratey, crateAngle, loots.chest[math.random(1, #loots.chest)])
                    -- destroy crate
                    chest.bod:setActive(false)
                    chest.shadow:Remove()

                    sounds.crate:play()
                    for i=1, math.random( 4, 8 ) do
                        particles.emit(cratex, cratey, {min = 0, max = 2 * math.pi}, 200, 1.2, 15, 4, 5, {r = .6, g = .6, b = 0, a = .6})
                    end

                    timer.after(chest.time, function()
                        print("GAME INFO: Respawning chest")
                        chest.bod:setActive(true)
                        chest.shadow = Body:new(lightWorld):InitFromPhysics(chest.bod)
                        
                        chest.light:SetColor(155, 155, 0, 155)
                    end)
                    return
                end
            end
        end
    end
end



function orb.add(x, y, r, type)
    local o = {}

    o.bod = love.physics.newBody( world, x, y, "dynamic" )
    o.bod:setLinearDamping(1)
    o.bod:setAngularDamping(1)
    o.shape = love.physics.newCircleShape(16)
    o.fixture = love.physics.newFixture(o.bod, o.shape)
    o.fixture:setRestitution(.8)
    o.fixture:setUserData({"Orb"})
    o.fixture:setSensor(true)

    if type == "health" then
        o.type = "health"
        o.amount = rf(2, 6, 1)
    elseif type == "skill" then
        o.type = "skill"
        local choosenSkill = skills.orb_list[math.random(1, #skills.orb_list)]
        o.skill = choosenSkill
        o.amount = rf(skills.skills[choosenSkill].amount.min, skills.skills[choosenSkill].amount.max, 2)
    elseif type == "exp" then
        o.type = "exp"
        o.amount = rf(2, 6, 1)
    end

    o.age = 2

    print("GAME INFO: Added one " .. type .. " orb")

    table.insert(entities.orbs, o)
end

function orb.update(self, dt)
    for id, orb in pairs(self.orbs) do
        local isInside = orb.fixture:testPoint(cmx, cmy) and sl(cmx, cmy, px, py) <= 64
        local speed = 1
        if isInside then
            if orb.type == "health" then
                local health, maxHealth = ply:getHealth()
                if health < maxHealth then
                    ply:addHealth( rf(3, 6, 1) )

                    orb.shape:setRadius(8)
                    sounds.orb:play()
                end
            elseif orb.type == "skill" then
                if key(config.controls.use) then
                    ply:skillBoost(orb.skill, orb.amount)
                    orb.shape:setRadius(8)
                    sounds.orb:play()
                end
            end
        end

        orb.shape:setRadius( math.max(orb.shape:getRadius() - dt, 8) )

        if orb.shape:getRadius() <= 8 then
            orb.bod:destroy()
            entities.orbs[id] = nil
        end
    end
end

function orb.draw(self)
    for id, orb in pairs(self.orbs) do
        if orb.bod:isDestroyed() then return end

        local isInside = orb.fixture:testPoint(cmx, cmy)
        if isInside then dotCursor = true end

        local x, y = orb.bod:getPosition()
        local a = orb.bod:getAngle()

        love.graphics.push("transform")
        
        love.graphics.translate(x, y)
        love.graphics.rotate(a)

        if orb.type == "health" then
            love.graphics.draw(images.orbs.health, -orb.shape:getRadius(), -orb.shape:getRadius(), 0, orb.shape:getRadius() / 32)
        elseif orb.type == "skill" then
            love.graphics.draw(images.orbs.skill, -orb.shape:getRadius(), -orb.shape:getRadius(), 0, orb.shape:getRadius() / 32)
        elseif orb.type == "exp" then
            love.graphics.draw(images.orbs.exp, -orb.shape:getRadius(), -orb.shape:getRadius(), 0, orb.shape:getRadius() / 24)
        end

        love.graphics.pop()
    end
end