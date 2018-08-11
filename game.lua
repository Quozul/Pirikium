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
    map = sti("data/maps/brick_arena.lua", { "box2d" })
    print(#map.layers["Map Entities"].data .. " tiles")

    if config.debug then map.layers["Map Entities"].visible = true end

    local map1d = map.layers["Collisions"].data
    local mapSize = map.layers["Collisions"].width * map.layers["Collisions"].height
    local map2d = {}

    for x=1, map.layers["Collisions"].width do
        map2d[x] = {}
        for y=1, map.layers["Collisions"].height do
            local t = map.layers["Collisions"].data[x][y]
            if t ~= nil then
                map2d[x][y] = t.id
            else
                map2d[x][y] = 0
            end
        end
    end

    local grid = grid( map2d )
    finder = pathfinder(grid, "JPS", 0)

    world = love.physics.newWorld()
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    map:box2d_init(world)
    print("World created")
    
    lightWorld = LightWorld:new()
    lightWorld:SetColor(50, 50, 50, 255)
    lightWorld:Resize(1280 * config.ratio, 720 * config.ratio)
    print("Created light world")
    
    lightWorld:InitFromPhysics(world)
    print("Initialized light world")

    map:addCustomLayer("Entities Layer", 3)
    map.layers["Entities Layer"].entities = {}
    map.layers["Entities Layer"].doors = {}
    map.layers["Entities Layer"].chests = {}
    map.layers["Entities Layer"].health = {}
    map.layers["Entities Layer"].orbs = {}
    entities = map.layers["Entities Layer"]

    local function addDoor(x, y, r)
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

    local function addChest(x, y, r)
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

        print("Added one chest")

        table.insert(entities.chests, c)
    end

    local function addOrb(x, y, r, type)
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
        end

        o.age = 2

        print("Added one " .. type .. " orb")

        table.insert(entities.orbs, o)
    end

    lights = {}

    for x=1, map.layers["Map Entities"].width do
        for y=1, map.layers["Map Entities"].height do
            local t = map.layers["Map Entities"].data[x][y]
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
        print("Ennemy level is " .. level)
        local weapon = loots.ai[math.random(1, #loots.ai)]
        entities.entities[uid] = newPlayer(x, y, uid, weapon, level)
        ai.set(entities.entities[uid], uid)

        print("Added one ennemy")
    end

    function entities:update(dt)
        if table.length(entities.entities) <= config.ai.limit and warmup == 0 then addEnnemy() end

        -- update entities
        for id, ent in pairs(self.entities) do
            local px, py = ent.bod:getPosition()

            -- cooldowns
            ent.cooldown.attack = math.max(ent.cooldown.attack - dt * ent.skills.recoil, 0) -- cooldown for primary attack
            ent.cooldown.special = math.max(ent.cooldown.special - dt * ent.skills.recoil, 0) -- cooldown for special attack
            ent.cooldown.dodge = math.max(ent.cooldown.dodge - dt * ent.skills.recoil, 0) -- cooldown for rolling
            if not ent.sprinting then
                ent.cooldown.sprint = math.max(ent.cooldown.sprint - dt * ent.skills.recoil, 0)
            else
                ent.cooldown.sprint = math.min(ent.cooldown.sprint + dt, ent.skills.stamina)
            end

            -- regen skill
            if ent.skills.regen ~= 0 then
                ent:addHealth(ent.skills.regen * dt)
            end
            if ent.skills.recoil < 1 then
                error([[Recoil skill is too low, please report this bug with the console's output\n
                To copy the console output, press CTRL+A to select everything, right-click to copy.\n
                (Or screenshot :p)]])
                --ent.skills.recoil = 0.1
            end

            -- ai
            if id ~= playerUUID then
                if not config.ai.disable then ai.update(ent, self.entities[playerUUID], id) end

                if ent:getHealth() <= 0 then
                    print(ent.lastAttacker .. " killed " .. id)

                    local pa = ent.bod:getAngle()

                    if math.random(1, 4) == 1 then
                        addOrb(px, py, pa, "health")
                    elseif math.random(1, 4) == 1 then
                        addOrb(px, py, pa, "skill")
                    end
                    
                    if math.random(1, 6) == 1 then
                        items.drop(px, py, pa, ent:getWeapon(true))
                    end

                    ent.bod:destroy()
                    self.entities[ent.lastAttacker]:addKill(1, ent)
                    self.entities[id] = nil
                end
            end
        end

        -- update bullets
        for id, bullet in pairs(bullets) do
            if bullet.bod:isDestroyed() then
                table.remove(bullets, id)
            end
        end

        -- update orbs
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

        for id, chest in pairs(self.chests) do
            if not chest.bod:isActive() then
                local r, g, b, a = chest.light:GetColor()
                a = math.max(a - dt * 155, 0)
                chest.light:SetColor(r, g, b, a)
            end
        end
    end

    function entities:draw()
        love.graphics.setFont(hudFont)

        love.graphics.setColor(0, 0, 0, 1)

        -- draw bullets
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
    
        -- draw doors
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
        
        -- draw crates
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

        -- draw orbs
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
            end

            love.graphics.pop()
        end

        -- draw items
        items.draw()

        -- draw entities
        for id, ent in pairs(self.entities) do
            love.graphics.push("transform")

            local x, y = ent.bod:getPosition()
            local vx, vy = ent.bod:getLinearVelocity()
            local a = ent.bod:getAngle()

            love.graphics.translate(x, y)
            if id ~= playerUUID then
                love.graphics.setColor(1, 1, 1, (255 - sl(cmx, cmy, x, y)) / 255)
                love.graphics.print(ent.name .. " - " .. ent:getLevel(), -hudFont:getWidth(ent.name) / 2, -25)
            end

            love.graphics.setColor(1, 1, 1, 1)

            love.graphics.rotate(a + math.pi / 2)
            love.graphics.scale(1.5, 1.5)

            if math.abs(vx + vy) > 1 then
                local spriteNum = math.floor(player_animation.currentTime / player_animation.duration * #player_animation.quads) + 1
                love.graphics.draw(player_animation.spriteSheet, player_animation.quads[spriteNum], -12, -12)
            else
                love.graphics.draw(images.player.stand, -12, -12)
            end

            local img = images.weapons.hold[ent:getWeapon(true)]
            if img ~= nil then
                --love.graphics.rotate(math.pi/2)
                love.graphics.translate(0, -32)
                love.graphics.draw(img, -16, -6)
            end

            love.graphics.pop()

            if id ~= playerUUID then
                if config.ai.debug then ai.draw(ent, self.entities[playerUUID]) end -- show the brain of the ai (debug)
            end
        end

        --particles.draw() -- particles are not used yet
    end

    tree.init()

    cam = camera(0, 0)
    smoother = cam.smooth.damped(5)
    love.graphics.setBackgroundColor(0, .25, .5)

    dotCursor = false
    skillTreeIsOpen = false

    warmup = config.warmup

    ratio = 1
    pause = false
    deathscreen.init()
end

function G:resize(w, h)
    print("Window got resized")
	map:resize(w, h)
    --lightWorld:Resize(w, h)

    window_width, window_height = w, h
end

function G:keypressed(key, scancode, isrepeat)
    if isIn(key, {"1", "2", "3", "4", "5", "6", "7", "8", "9"}) and not pause then
        local slot = tonumber(key)
        if slot <= #ply.inventory then
            ply:setSlot(slot)
        end
    elseif key == config.controls.use and not pause then
        local x, y = cam:worldCoords(mx, my)

        -- interact with crates
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

                        timer.after(chest.time, function()
                            print("Respawning chest")
                            chest.bod:setActive(true)
                            chest.shadow = Body:new(lightWorld):InitFromPhysics(chest.bod)
                            
                            chest.light:SetColor(155, 155, 0, 155)
                        end)
                        return
                    end
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
    elseif key == config.controls.drop and not pause then
        ply:drop(ply.selectedSlot)
    elseif key == "escape" then
        gamestate.switch(menu)
    elseif key == "f3" then
        config.debug = not config.debug
        love.mouse.setGrabbed(not love.mouse.isGrabbed())
        map.layers["Map Entities"].visible = not map.layers["Map Entities"].visible
    elseif key == config.controls.skill_tree and not pause then
        skillTreeIsOpen = not skillTreeIsOpen
    end
end

function G:wheelmoved(x, y)
    if pause then return end

    local ply = entities.entities[playerUUID]
    local newSlot = ply.selectedSlot - y

    if newSlot < 1 then ply:setSlot(#ply.inventory)
    elseif newSlot > #ply.inventory then ply:setSlot(1)
    else ply:setSlot(newSlot) end
end

function G:mousepressed(x, y, button, isTouch)
    if skillTreeIsOpen then tree.mousepressed(x, y, button) end
end

function G:mousereleased(x, y, button, isTouch)
    if skillTreeIsOpen then tree.mousereleased(x, y, button) end
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

    if love.mouse.isDown(1) and not skillTreeIsOpen and warmup <= 9 then
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

    crate_animation.currentTime = crate_animation.currentTime + dt
    if crate_animation.currentTime >= crate_animation.duration then
        crate_animation.currentTime = crate_animation.currentTime - crate_animation.duration
    end

    player_animation.currentTime = player_animation.currentTime + dt
    if player_animation.currentTime >= player_animation.duration then
        player_animation.currentTime = player_animation.currentTime - player_animation.duration
    end

    warmup = math.max(warmup - dt, 0)

    ply = entities.entities[playerUUID]
    px, py = ply.bod:getPosition()
    pcx, pcy = cam:cameraCoords(px, py)

    if ply.inventory == nil or ply.inventory == {} or #ply.inventory == 0 then
        error("Inventory is empty!")
    elseif #ply.inventory < 0 then
        error("Inventory size is negative! " .. #ply.inventory)
    elseif ply:getWeapon() == nil and ply.selectedSlot ~= 1 then
        ply:setSlot(1)
    elseif ply:getWeapon() == nil then
        error("Weapon cannot be found!")
    end

    if not pause then controls(dt) end
    items.update(dt)

    map:update(dt)
    --particles.update(dt)
    timer.update(dt)
    world:update(dt)
    cam:zoomTo(config.ratio)

    local pa = math.atan2(cmy - py, cmx - px) -- angle of the player
    ply.bod:setAngle( pa )
    cam:lockPosition( px + math.cos(pa) * 20, py + math.sin(pa) * 20, smoother )

    if config.shader then
        lightWorld:Update(dt)
        lightWorld:SetPosition((cpx - pcx + (px - cpx)) / config.ratio, (cpy - pcy + (py - cpy)) / config.ratio, config.ratio)

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

    if pause and skillTreeIsOpen then
        skillTreeIsOpen = false
    end

    if skillTreeIsOpen then tree.update(dt) end
    
    if ply:getHealth() <= 0 then
        pause = true
        deathscreen.update(dt)
    end
end

function G:draw()
    -- draw the map
    love.graphics.setColor(1, 1, 1)

    dotCursor = false
    map:draw(cx / config.ratio, cy / config.ratio, config.ratio, config.ratio)

    --cam:draw(function() end)

    -- draw collision map (debug)
    if config.debug then
        love.graphics.setColor(1, 0, 0)
        map:box2d_draw(cx / config.ratio, cy / config.ratio, config.ratio, config.ratio)
    end

    if config.shader then lightWorld:Draw() end

    love.graphics.setFont(hudFont)
    for index, item in pairs(entities.entities[playerUUID].inventory) do
        if item ~= nil then
            local x = (index - ((#ply.inventory + 1) / 2)) * 64 + window_width / 2
            if entities.entities[playerUUID].selectedSlot == index then
                love.graphics.setColor(0, 1, 0)
            else
                love.graphics.setColor(1, 1, 1)
            end
            local startx, starty = x - 24, window_height - 64

            love.graphics.draw(images.slot, startx, starty)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(lang.print(item), startx, starty + 48)

            if images.weapons.side[item] then love.graphics.draw(images.weapons.side[item], startx + 8, starty + 8) end

            if inSquare(mx, my, startx, starty, 48, 48) then
                dotCursor = true
                attackIsDown = true
                if love.mouse.isDown(1) then
                    ply:setSlot(index)
                end
            end
        end
    end

    for index, skill in pairs(ply.boostedSkills) do
        local x = window_width - index * 64
        love.graphics.draw(images.slot, x, 16)

        love.graphics.print(lang.print(skill.name), x, 16)
        love.graphics.print("+" .. skill.amount, x, 32)
    end

    if config.debug then love.graphics.print("Framerate: " .. love.timer.getFPS(), 5, 59) end

    if ply:getWeapon() then maxCooldown = ply:getWeapon().cooldown
    else maxCooldown = 1 end
    local percentage = math.min(ply.cooldown.attack / maxCooldown * 100, 100)

    love.graphics.line(mx - 20, my + 24, (mx - 20) + percentage / 100 * 40, my + 24)

    -- health bar
    local padding = 2

    love.graphics.setColor(1, 0, 0)
    local health, maxHealth = ply:getHealth()

    local percentage = health / maxHealth * 200
    love.graphics.polygon("fill",
        5 + padding, 30 - padding,
        5 + padding, 5 + padding,
        5 - padding + math.min( 5 + percentage + math.min(percentage, 20), 200), 5,
        5 + percentage, 30 - padding
    )

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(images.bar, 5, 5)
    local text = math.max(round(health, 1), 0) .. " hp"
    love.graphics.print(text, (5 + 200 - padding - hudFont:getWidth(text)) / 2, 25 - padding - hudFont:getHeight(text))

    -- stamina bar
    love.graphics.setColor(0, 0, 1)
    percentage = (ply.skills.stamina - ply.cooldown.sprint) / ply.skills.stamina * 200
    love.graphics.polygon("fill",
        5 + padding, 57 - padding,
        5 + padding, 32 + padding,
        5 - padding + math.min(5 + percentage + math.min(percentage, 20), 200), 32,
        5 + percentage, 57 - padding
    )
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(images.bar, 5, 32)
    local percentage = round(percentage / 2, 0) .. "%"
    love.graphics.print(percentage, (5 + 200 - padding - hudFont:getWidth(percentage)) / 2, 30 + round((25 - padding - hudFont:getHeight(percentage) / 1.5) / 2, 0))

    -- kills and level
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(images.skull, 5, 64)
    love.graphics.print(ply.kills, 32, 68)
    love.graphics.draw(images.level, 64, 64)
    love.graphics.print(round(ply:getLevel(), 1), 96, 68)

    -- skill tree (if opened)
    if skillTreeIsOpen then
        tree.draw()
        love.graphics.setLineWidth(1)
    end

    -- warmup message
    if warmup ~= 0 then
        text = lang.print("warmup", {round(warmup, 1)})
        love.graphics.setFont(menuFont)
        love.graphics.setColor(1, 1, 1, warmup / 5)
        love.graphics.print(text, window_width / 2 - round(menuFont:getWidth(text) / 2, 0), window_height / 2 + window_height / 4, 0)
    end

    if ply:getHealth() <= 0 then deathscreen.draw() end

    love.graphics.setColor(1, 1, 1)
    if dotCursor then
        love.graphics.draw(images.dot, mx - 16, my - 16)
    else
        love.graphics.draw(images.cursor, mx - 16, my - 16)
    end
end

function G:leave()
    ply:save()
    timer.clear()

    items.clear()
    entities.entities = {}
    lights = {}
    lightWorld = nil
    world = nil
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
