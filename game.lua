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
    love.graphics.setDefaultFilter("nearest", "nearest")

    cursor = love.graphics.newImage("data/cursor.png")
    love.mouse.setVisible(false)

    images = {}

    weapons = json:decode( love.filesystem.read( "data/weapons.json" ) ) -- load game content
    print(#weapons .. " weapons loaded")
    for name, wep in pairs(weapons) do
        if wep.texture ~= nil then
            print("Loaded image for weapon " .. name)
            images[name] = love.graphics.newImage(wep.texture)
        end
    end

    loots = json:decode( love.filesystem.read( "data/loots.json" ) )

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
        d.bod:setLinearDamping(16)
        d.bod:setAngularDamping(16)
        d.bod:setAngle(r)
        d.shape = love.physics.newRectangleShape(48, 16)
        d.fixture = love.physics.newFixture(d.bod, d.shape)
        d.fixture:setRestitution(.2)
        d.fixture:setUserData({"Door"})

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
        local level = rf2(0, ply.kills / 10, 1)
        local weapon = loots.ai[math.random(1, #loots.ai)]
        entities.entities[uid] = newPlayer(x, y, uid, weapon, level)
        ai.set(entities.entities[uid], uid)

        print("Added one ennemy")
    end

    function entities:update(dt)
        if table.length(entities.entities) <= config.ai.limit then addEnnemy() end

        for id, ent in pairs(self.entities) do
            local px, py = ent.bod:getPosition()

            ent.cooldown.attack = math.max(ent.cooldown.attack - dt, 0) -- cooldown for primary attack
            ent.cooldown.special = math.max(ent.cooldown.special - dt, 0) -- cooldown for special attack
            ent.cooldown.dodge = math.max(ent.cooldown.dodge - dt, 0) -- cooldown for rolling
            if not ent.sprinting then ent.cooldown.sprint = math.max(ent.cooldown.sprint - dt, 0) end -- cooldown for sprinting

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
            love.graphics.push("transform")

            local x, y = door.bod:getPosition()
            local a = door.bod:getAngle()

            love.graphics.setColor(1, 1, 1, 1)

            love.graphics.translate(x, y)
            love.graphics.rotate(a)
            love.graphics.rectangle("fill", -48/2, -16/2, 48, 16)

            love.graphics.pop()
        end
        
        for index, chest in pairs(self.chests) do
            love.graphics.push("transform")

            local x, y = chest.bod:getPosition()
            local a = chest.bod:getAngle()

            love.graphics.setColor(1, 1, 1, 1)

            love.graphics.translate(x, y)
            love.graphics.rotate(a)
            love.graphics.rectangle("fill", -48/2, -48/2, 48, 48)

            love.graphics.pop()
        end
    end

    cam = camera(0, 0)
    smoother = cam.smooth.damped(5)
    love.graphics.setBackgroundColor(0, .25, .5)
end

function G:resize(w, h)
    print("Window got resized")
	map:resize(w, h)
    lightWorld:Resize(w, h)
end

function G:mousepressed(x, y, button, istouch, presses)
    attack(entities.entities[playerUUID], playerUUID)
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

        items.interact(ply, x, y, px, py)
    elseif key == config.controls.drop then
        ply:drop(ply.selectedSlot)
    elseif key == "escape" then
        gamestate.switch(menu)
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

    if key(config.controls.sprint) and cooldown.sprint ~= 2 then
        speed = speed * 2
        cooldown.sprint = math.min(cooldown.sprint + dt, 2)
        ply.sprinting = true
    elseif not key(config.controls.sprint) then
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

    if key(config.controls.dodge) and cooldown.dodge == 0 and cooldown.sprint < 2 then
        ply.bod:applyLinearImpulse(vx, vy)
        cooldown.dodge = 1
        cooldown.sprint = cooldown.sprint + dt * 10
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
    map:draw(cx, cy)

    cam:draw(function()
        -- draw collision map (debug)
        --love.graphics.setColor(1, 0, 0, .5)
        --map:box2d_draw()

        particles.draw()
        items.draw()
    end)

    if config.shader then lightWorld:Draw() end

    love.graphics.setFont(hudFont)

    for index, item in pairs(entities.entities[playerUUID].inventory) do
        if item ~= nil then
            local x = 50 * (index - 1) + 5
            if entities.entities[playerUUID].selectedSlot == index then
                love.graphics.setColor(0, 1, 0)
                love.graphics.rectangle("fill", x, 5, 50, 16)
            else
                love.graphics.rectangle("line", x, 5, 50, 16)
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(item, x, 5)
        end
    end

    love.graphics.print("Framerate: " .. love.timer.getFPS(), 5, 20)

    if ply:getWeapon() then maxCooldown = ply:getWeapon().cooldown
    else maxCooldown = 1 end
    local percentage =  ply.cooldown.attack / maxCooldown * 100

    love.graphics.line(mx - 20, my + 24, (mx - 20) + percentage / 100 * 40, my + 24)

    love.graphics.setColor(1, 0, 0)
    local health, maxHealth = ply:getHealth()
    love.graphics.rectangle("fill", 5, 34, health / maxHealth * 100, 10)

    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", 5, 44, (2 - ply.cooldown.sprint) / 2 * 100, 10)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(ply.kills .. " kills", 5, 54)
    love.graphics.print(ply.exp .. " level", 5, 66)

    love.graphics.draw(cursor, mx - 16, my - 16)
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
    if a:isSensor() or a:getUserData()[1] == "Bullet" then return end

    if b:getUserData()[1] == "Bullet" then
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
