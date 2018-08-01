local G = {}
local spawns = {}
spawns.friendly = {}
spawns.hostile = {}
local key = love.keyboard.isDown
local cooldown = {
    attack = 0,
    special = 0,
    roll = 0,
    sprint = 0
}

function G:enter()
    love.mouse.setVisible(false)
    if not config.debug then love.mouse.setGrabbed(true) end

    love.physics.setMeter(64)

    -- Load a map exported to Lua from Tiled
    map = sti("data/maps/blank_lab.lua", { "box2d" })
    print(#map.layers["Collisions"].data .. " tiles")

    local map1d = map.layers["Walkable"].data
    local mapSize = map.layers["Walkable"].width * map.layers["Walkable"].height
    local map2d = {}

    for x=1, map.layers["Walkable"].width do
        map2d[x] = {}
        for y=1, map.layers["Walkable"].height do
            local t = map.layers["Walkable"].data[x][y]
            if t ~= nil then
                map2d[x][y] = t.id
            else
                map2d[x][y] = 0
            end
        end
    end

    local grid = grid( map2d )
    finder = pathfinder(grid, "JPS", 5)

    world = love.physics.newWorld()
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    map:box2d_init(world)
    print("World created")

    map:addCustomLayer("Entities Layer", 3)
    map.layers["Entities Layer"].entities = {}
    map.layers["Entities Layer"].doors = {}
    map.layers["Entities Layer"].chests = {}
    entities = map.layers["Entities Layer"]
    
    lightWorld = LightWorld:new()
    lightWorld:SetColor(50, 50, 50, 255)
    lightWorld:Resize(853, 480)
    print("Created light world")

    local function addDoor(x, y, r)
        local d = {}

        d.bod = love.physics.newBody( world, x * 64 - 32, y * 64 - 32, "dynamic" )
        d.bod:setLinearDamping(1)
        d.bod:setAngularDamping(1)
        d.bod:setAngle(r)
        d.bod:setBullet(true)
        d.shape = love.physics.newRectangleShape(48, 8)
        d.fixture = love.physics.newFixture(d.bod, d.shape)
        d.fixture:setRestitution(.5)
        d.fixture:setUserData({"Door"})

        d.hinge = love.physics.newBody(world, x * 64 - 32 + math.cos(r) * 32, y * 64 - 32 + math.sin(r) * 32, "static")
        d.hinge:setLinearDamping(16)
        d.hinge:setAngularDamping(16)
        d.hingeShape = love.physics.newRectangleShape(8, 8)
        d.hingeFixture = love.physics.newFixture(d.hinge, d.hingeShape)
        d.hingeFixture:setUserData({"Hinge"})
        d.hingeFixture:setSensor(true)

        d.joint = love.physics.newRevoluteJoint( d.bod, d.hinge,  x * 64 - 32 + math.cos(r) * 28, y * 64 - 32 + math.sin(r) * 28 )

        print("Added one door")

        table.insert(entities.doors, d)
    end

    local function addChest(x, y, r)
        local c = {}

        c.bod = love.physics.newBody( world, x * 64 - 32, y * 64 - 32, "dynamic" )
        c.bod:setLinearDamping(16)
        c.bod:setAngularDamping(16)
        c.bod:setAngle(r)
        c.shape = love.physics.newRectangleShape(48, 48)
        c.fixture = love.physics.newFixture(c.bod, c.shape)
        c.fixture:setRestitution(.1)
        c.fixture:setUserData({"Chest"})

        print("Added one chest")

        table.insert(entities.chests, c)
    end

    lights = {}

    for x=1, map.layers["Collisions"].width do
        for y=1, map.layers["Collisions"].height do
            local t = map.layers["Collisions"].data[x][y]
            local id = #lights+1
            if t ~= nil and t.id ~= 0 then
                if t.id == 2 then -- friendly spawn
                    table.insert(spawns.friendly, {y, x})
                elseif t.id == 3 then -- hostile spawn
                    table.insert(spawns.hostile, {y, x})
                --elseif t.id == 4 then print("One way")
                --elseif t.id == 5 then print("Hinge")
                elseif t.id == 6 then -- door
                    addDoor(y, x, t.r)
                elseif t.id == 7 then -- chest/weapon spawn
                    addChest(y, x, t.r)
                elseif t.id == 8 then -- lights
                    lights[id] = Light:new(lightWorld, 300)
                    lights[id]:SetColor(0, 0, 155)
                elseif t.id == 9 then
                    lights[id] = Light:new(lightWorld, 300)
                    lights[id]:SetColor(155, 0, 0)
                elseif t.id == 10 then
                    lights[id] = Light:new(lightWorld, 300)
                    lights[id]:SetColor(155, 155, 0)
                elseif t.id == 11 then
                    lights[id] = Light:new(lightWorld, 300)
                    lights[id]:SetColor(155, 155, 155)
                --elseif t.id == 12 then print("Health")
                --elseif t.id == 13 then print("Armor")
                --elseif t.id == 14 then print("Boss spawn")
                --elseif t.id == 15 then print("Cannon")
                end

                if lights[id] and config.shader then lights[id]:SetPosition(y * 64 - 32, x * 64 - 32) end
            end
        end
    end
    
    lightWorld:InitFromPhysics(world)
    print("Initialized light world")

    print(#spawns.friendly .. " player spawns found")
    print(#spawns.hostile .. " ennemy spawns found")
    local x, y = unpack( spawns.friendly[math.random(1, #spawns.friendly)] )

    entities.entities[playerUUID] = newPlayer(x, y, playerUUID)
    lights.player = Light:new(lightWorld, 200)
    lights.player:SetColor(155, 155, 155)
    print("Added player light")

    local function addEnnemy()
        local x, y = unpack( spawns.hostile[math.random(1, #spawns.hostile)] )
        local uid = uuid()
        local level = rf(0, ply.kills / 10, 1)
        local weapon = loots.ai[math.random(1, #loots.ai)]
        entities.entities[uid] = newPlayer(x, y, uid, weapon, level)
        ai.set(entities.entities[uid], uid)

        print("Added one ennemy")
    end

    function entities:update(dt)
        if table.length(entities.entities) <= config.ai.limit then addEnnemy() end

        for id, ent in pairs(self.entities) do
            local px, py = ent.bod:getPosition()

            ent.cooldown.attack = math.max(ent.cooldown.attack - dt * ent.skills.recoil, 0) -- cooldown for primary attack
            ent.cooldown.special = math.max(ent.cooldown.special - dt * ent.skills.recoil, 0) -- cooldown for special attack
            ent.cooldown.dodge = math.max(ent.cooldown.dodge - dt * ent.skills.recoil, 0) -- cooldown for rolling
            if not ent.sprinting then
                ent.cooldown.sprint = math.max(ent.cooldown.sprint - dt * ent.skills.recoil, 0)
            else
                ent.cooldown.sprint = math.min(ent.cooldown.sprint + dt, ent.skills.stamina)
            end

            if id == playerUUID then
                local pa = math.atan2(cmy - py, cmx - px) -- angle of the player
                ent.bod:setAngle( pa )
                cam:lockPosition( px + math.cos(pa) * 20, py + math.sin(pa) * 20, smoother )
            else
                if not config.ai.disable then ai.update(ent, self.entities[playerUUID], id) end

                if ent:getHealth() <= 0 then
                    print(ent.lastAttacker)
                    self.entities[ent.lastAttacker]:addKill(1, ent)
                    self.entities[id] = nil
                end
            end
        end

        for id, bullet in pairs(bullets) do
            if bullet.bod:isDestroyed() then
                table.remove(bullets, id)
            end
        end
    end

    function entities:draw()
        items.draw()

        for id, ent in pairs(self.entities) do
            love.graphics.push("transform")

            local x, y = ent.bod:getPosition()
            local a = ent.bod:getAngle()

            love.graphics.translate(x, y)
            if id ~= playerUUID then
                love.graphics.setColor(1, 1, 1, (255 - sl(cmx, cmy, x, y)) / 255)
                love.graphics.print(ent.name, -hudFont:getWidth(ent.name) / 2, -25)
            end

            love.graphics.setColor(1, 1, 1, 1)

            love.graphics.rotate(a)
            love.graphics.rectangle("fill", -20/2, -20/2, 20, 20)

            local img = images[ent.inventory[ent.selectedSlot]]
            love.graphics.rotate(1)
            love.graphics.scale(.25)
            if img ~= nil then
                love.graphics.draw(img, (-128/2) + 85, (-128/2) - 50)
            end

            love.graphics.pop()

            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.line(x, y, x + math.cos(a) * 20, y + math.sin(a) * 20)

            if id ~= playerUUID then
                if config.ai.debug then ai.draw(ent, self.entities[playerUUID]) end -- show the brain of the ai (debug)
            end
        end

        for id, bullet in pairs(bullets) do
            if not bullet.bod:isDestroyed() then
                local wep = bullet.fixture:getUserData().weapon
                local bx, by = bullet.bod:getPosition()
                local ba = bullet.bod:getAngle()
                local radius = wep.bullet.radius
                local type = wep.bullet.type

                if type == "arrow" then
                    love.graphics.line(bx, by, bx + math.cos(ba) * radius, by + math.sin(ba) * radius)
                else
                    love.graphics.circle("fill", bx, by, radius)
                end
            end
        end
    
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
        
        for index, chest in pairs(self.chests) do
            local isInside = chest.fixture:testPoint(cmx, cmy)
            if isInside then dotCursor = true end

            love.graphics.push("transform")

            local x, y = chest.bod:getPosition()
            local a = chest.bod:getAngle()

            love.graphics.setColor(1, 1, 1, 1)

            love.graphics.translate(x, y)
            love.graphics.rotate(a)
            love.graphics.rectangle("fill", -48/2, -48/2, 48, 48)

            love.graphics.pop()
        end

        particles.draw()
    end

    cam = camera(0, 0)
    smoother = cam.smooth.damped(5)
    love.graphics.setBackgroundColor(0, .25, .5)

    dotCursor = false
end

function G:resize(w, h)
    print("Window got resized")
	map:resize(w, h)
    lightWorld:Resize(w, h)
end

function G:keypressed(key, scancode, isrepeat)
    if isIn(key, {"1", "2", "3", "4", "5", "6", "7", "8", "9"}) then
        local slot = tonumber(key)
        if slot <= #ply.inventory then
            ply:setSlot(slot)
        end
    elseif key == config.controls.use then
        local x, y = cam:worldCoords(mx, my)
        for id, chest in pairs(entities.chests) do
            if love.physics.getDistance(chest.fixture, ply.fixture) <= 250 then
                local isInside = chest.fixture:testPoint(x, y)
                if isInside then
                    local remove = ply:addItem(loots.chest[math.random(1, #loots.chest)])
                    return
                end
            end
        end

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

        items.interact(ply, x, y, px, py)
    elseif key == config.controls.drop then
        ply:drop(ply.selectedSlot)
    elseif key == "escape" then
        gamestate.switch(menu)
    elseif key == "f3" then
        config.debug = not config.debug
        love.mouse.setGrabbed(not love.mouse.isGrabbed())
    end
end

function G:wheelmoved(x, y)
    local ply = entities.entities[playerUUID]
    local newSlot = ply.selectedSlot - y

    if newSlot < 1 then ply:setSlot(#ply.inventory)
    elseif newSlot > #ply.inventory then ply:setSlot(1)
    else ply:setSlot(newSlot) end
end

function controls(dt)
    local ply = entities.entities[playerUUID]
    local cooldown = ply.cooldown
    local pa = ply.bod:getAngle()
    local vx, vy = ply.bod:getLinearVelocity()

    local speed = love.physics.getMeter() * (4 + ply.skills.speed)

    if key(config.controls.sprint) and cooldown.sprint ~= ply.skills.stamina and math.abs(vx + vy) > 1 then
        speed = speed * 2
        ply.sprinting = true
    elseif not key(config.controls.sprint) or math.abs(vx + vy) <= 1 then
        ply.sprinting = false
    end

    if key(config.controls.forward) then
        ply.bod:applyForce(speed * math.cos(pa), speed * math.sin(pa))
    elseif key(config.controls.backward) then
        ply.bod:applyForce(-speed / 2 * math.cos(pa), -speed / 2 * math.sin(pa))
    end

    if key(config.controls.left) then
        ply.bod:applyForce(-speed * math.cos(pa + (math.pi / 2)), -speed * math.sin(pa + (math.pi / 2)))
    elseif key(config.controls.right) then
        ply.bod:applyForce(speed * math.cos(pa + (math.pi / 2)), speed * math.sin(pa + (math.pi / 2)))
    end

    if key(config.controls.dodge) and cooldown.dodge == 0 and cooldown.sprint < ply.skills.stamina then
        ply.bod:applyLinearImpulse(vx, vy)
        cooldown.dodge = 1
        cooldown.sprint = cooldown.sprint + dt * 10
    end

    if love.mouse.isDown(1) then
        if ply:getWeapon().firetype == "auto" then
            attack(entities.entities[playerUUID], playerUUID)
        elseif not attackIsDown then
            attack(entities.entities[playerUUID], playerUUID)
            attackIsDown = true
        end
    elseif not love.mouse.isDown(1) then
        attackIsDown = false
    end
end

function G:update(dt)
    -- get cam info
    cx, cy = cam:cameraCoords(0, 0)
    cpx, cpy = cam:position()
    cmx, cmy = cam:mousePosition() -- pos of the mouse in the world

    mx, my = love.mouse.getPosition()

    ply = entities.entities[playerUUID]
    px, py = ply.bod:getPosition()
    pcx, pcy = cam:cameraCoords(px, py)

    controls(dt)
    items.update(dt)

    map:update(dt)
    particles.update(dt)
    world:update(dt)
    if config.shader then
        lightWorld:Update()
        lightWorld:SetPosition(cpx - pcx + (px - cpx), cpy - pcy + (py - cpy))

        lights.player:SetPosition(px, py, 1)
    end

    for index, bullet in pairs(bullets) do
        -- remove bullets using age
        if not bullet.bod:isDestroyed() then
            bullet.age = math.max(bullet.age - dt, 0)
            if bullet.age == 0 then  removeBullet(bullet.bod, bullet.fixture:getUserData().weapon.bullet.type) end
        end
    end
    --[[for index, bullet in pairs(bullets) do
        -- remove bullets using speed
        if not bullet.bod:isDestroyed() then
            local vx, vy = bullet.bod:getLinearVelocity()
            local mass = bullet.bod:getMass()
            local speed = math.abs(vx + vy)
            local minSpeed = bullet.fixture:getUserData().weapon.bullet.speed / mass

            print(mass, speed, minSpeed / 2)

            if speed <= minSpeed / 2 then
                bullet.bod:destroy()
            end
        end
    end]]
    
    if ply == nil or ply:getHealth() <= 0 then gamestate.switch(menu) end
end

function G:draw()
    -- draw the map
    love.graphics.setColor(1, 1, 1)

    dotCursor = false
    map:draw(cx, cy)

    --cam:draw(function() end)

    -- draw collision map (debug)
    if config.debug then
        love.graphics.setColor(1, 0, 0)
        map:box2d_draw(cx, cy)
    end

    if config.shader then lightWorld:Draw() end

    love.graphics.setFont(hudFont)
    for index, item in pairs(entities.entities[playerUUID].inventory) do
        if item ~= nil then
            local x = 80 * (index - 1) - 80 * 1.5
            if entities.entities[playerUUID].selectedSlot == index then
                love.graphics.setColor(0, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
            local startx, starty = window_width / 2 + x / 2, window_height - 48

            love.graphics.draw(slot, startx, starty)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(item, startx, starty + 32)

            if inSquare(mx, my, startx, starty, 32, 32) then
                dotCursor = true
            end
        end
    end

    if config.debug then love.graphics.print("Framerate: " .. love.timer.getFPS(), 5, 28) end

    if ply:getWeapon() then maxCooldown = ply:getWeapon().cooldown
    else maxCooldown = 1 end
    local percentage =  ply.cooldown.attack / maxCooldown * 100

    love.graphics.line(mx - 20, my + 24, (mx - 20) + percentage / 100 * 40, my + 24)

    -- health bar
    local padding = 2

    love.graphics.setColor(1, 0, 0)
    local health, maxHealth = ply:getHealth()
    local percentage = health / maxHealth * 200
    love.graphics.polygon("fill", 5 + padding, 30 - padding, 5 + padding, 5 + padding, 5 - padding + math.min( 5 + percentage + math.min(percentage, 20), 200), 5, 5 + percentage, 30 - padding)
    love.graphics.draw(bar, 5, 5)

    love.graphics.setColor(0, 0, 1)
    percentage = (2 - ply.cooldown.sprint) / 2 * 200
    love.graphics.polygon("fill", 5 + padding, 57 - padding, 5 + padding, 32 + padding, 5 - padding + math.min(5 + percentage + math.min(percentage, 20), 200), 32, 5 + percentage, 57 - padding)
    love.graphics.draw(bar, 5, 32)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(ply.kills .. " kills", 5, 57)
    love.graphics.print(ply.exp .. " levels", 5, 66)

    if dotCursor then
        love.graphics.draw(dot, mx - 16, my - 16)
    else
        love.graphics.draw(cursor, mx - 16, my - 16)
    end
end

function G:leave()
    items.clear()
    entities.entities = {}
    lights = {}
    lightWorld = nil
    world = nil

    ply:save()
end

function G:quit()
    ply:save()
end

-- collision callback
function beginContact(a, b, coll)
    if a:getUserData()[1] == "Door" and b:getUserData()[1] == "Player" then
        sounds.door:play()
    end

    if b:getUserData()[1] == "Bullet" then
        if a:getUserData()[1] == "Bullet" or a:isSensor() then return end

        local wep = b:getUserData().weapon

        if a:getUserData()[1] == "Player" then
            bulletDamage(wep, a:getUserData().id, b:getBody():getAngle(), b:getUserData().owner_id)
        end

        removeBullet(b:getBody(), wep.bullet.type)
    end
end

function endContact(a, b, coll)
end
 
function preSolve(a, b, coll)
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end

return G
