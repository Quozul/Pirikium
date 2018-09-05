game = {} -- gamestate
local spawns = {}
local teleporters = {}
local key = love.keyboard.isDown
local cooldown = {
    attack = 0,
    special = 0,
    roll = 0,
    sprint = 0
}

function game:enter()
    love.graphics.clear()

    loading.setText(lang.print("loading"))
    loading.draw()
    love.graphics.present()

    particles.enable(config.particles)
    love.mouse.setVisible(false)
    if not config.debug then love.mouse.setGrabbed(true) end

    love.physics.setMeter(64)

    -- Load a map exported to Lua from Tiled
    map = sti("data/maps/" .. selectedMap, { "box2d" })
    print("GAME INFO: " .. #map.layers["Map Entities"].data .. " tiles")

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

    window_width, window_height = love.window.getMode()
    particles.window(window_width, window_height)
    scalex, scaley = window_height / 480, window_width / 853
    
    lightWorld = LightWorld:new()
    lightWorld:SetColor(50, 50, 50, 255)
    lightWorld:Resize(window_width, window_height)
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

    lights = {}

    for x=1, map.layers["Map Entities"].width do
        for y=1, map.layers["Map Entities"].height do
            local t = map.layers["Map Entities"].data[x][y]
            local id = #lights+1
            if t ~= nil and t.id ~= 0 then
                if t.id == 2 then -- friendly spawn
                    table.insert(spawns, {y, x})
                --[[elseif t.id == 3 then -- teleporter
                    table.insert(teleporters, {y, x})
                    lights[id] = Light:new(lightWorld, 300)
                    lights[id]:SetColor(155, 0, 155)]]
                --elseif t.id == 4 then print("One way")
                --elseif t.id == 5 then print("Hinge")
                elseif t.id == 6 then -- door
                    if (t.sx and t.sy) == -1 then r = math.pi else r = t.r end -- fix a bug
                    doors.add(y, x, r)
                elseif t.id == 7 then -- chest/weapon spawn
                    chest.add(y, x)
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

    print("GAME INFO: " .. #teleporters .. " teleporters found")
    print("GAME INFO: " .. #spawns .. " spawns found")
    local x, y = unpack( spawns[math.random(1, #spawns)] )

    entities.entities[playerUUID] = newPlayer(x, y, playerUUID)

    ply = entities.entities[playerUUID]
    
    if (ply.skills.recoil and ply.skills.recoil < 1) or not ply.skills.recoil then error("This save is corrupted") end

    lights.player = Light:new(lightWorld, 200)
    lights.player:SetColor(155, 155, 155)
    print("GAME INFO: Added player light")

    function addEnemy()
        local x, y = unpack( spawns[math.random(1, #spawns)] )
        local dist = sl(x, y, px / 64, py / 64)
        if dist <= 10.5 then return end -- prevent the enemies from spawning to close

        local uid = uuid() -- choose a random unique id for the enemy
        local level = rf(0, ply:getLevel() / 100, 2)
        print("GAME INFO: Ennemy level is " .. level)
        local class = classes.list[math.random(1, #classes.list)]
        entities.entities[uid] = newPlayer(x, y, uid, classes[class], level)
        ai.set(entities.entities[uid], uid)

        print("GAME INFO: Added one ennemy")
    end

    maxAIs = 2 -- maximum amount of ai at start
    function entities:update(dt)
        if table.length(entities.entities) <= maxAIs and warmup <= 0 then addEnemy() end

        -- update entities
        for id, ent in pairs(self.entities) do
            -- cooldowns
            ent.cooldown.attack = math.max(ent.cooldown.attack - dt * ent.skills.recoil, 0) -- cooldown for primary attack
            ent.cooldown.special = math.max(ent.cooldown.special - dt * ent.skills.recoil, 0) -- cooldown for special attack
            ent.cooldown.dash = math.max(ent.cooldown.dash - dt * ent.skills.recoil, 0) -- cooldown for rolling
            if not ent.sprinting then
                ent.cooldown.sprint = math.max(ent.cooldown.sprint - dt * ent.skills.recoil, 0)
            else
                ent.cooldown.sprint = math.min(ent.cooldown.sprint + dt, ent.skills.stamina)
            end

            -- regen skill
            if ent.skills.regen ~= 0 then ent:addHealth(ent.skills.regen * dt) end

            -- ai
            if id ~= playerUUID then
                if not config.ai.disable then ai.update(ent, self.entities[playerUUID], id) end

                if ent:getHealth() <= 0 then
                    print("GAME INFO: " .. ent.lastAttacker .. " killed " .. id)

                    local ex, ey = ent.bod:getPosition() -- get the position of the current entity
                    local ea = ent.bod:getAngle()

                    if math.random(1, 4) == 1 then
                        orb.add(ex, ey, ea, "health")
                    elseif math.random(1, 4) == 1 then
                        orb.add(ex, ey, ea, "skill")
                    end
                    
                    if math.random(1, 6) == 1 then
                        items.drop(ex, ey, ea, ent:getWeapon(true))
                    end

                    ent.bod:destroy()
                    self.entities[ent.lastAttacker]:addKill(1, ent)
                    self.entities[id] = nil
                end
            end
        end

        -- update teleporters
        --[[for id, pos in pairs(teleporters) do
            local x, y = (pos[1] - 1) * 64, (pos[2] - 1) * 64
            local x, y = math.random(x, x + 64), math.random(y, y + 64)
            particles.emit(1, x, y, {min = 0, max = 2 * math.pi}, 2, 1, 7, 1, 3, {r = 1, g = 0, b = 1}, true)
            particles.emit(1, x, y, {min = 0, max = 2 * math.pi}, 2, 1, 7, 1, 3, {r = 1, g = 0, b = .5}, true)

            local x, y = (pos[1] - 1) * 64, (pos[2] - 1) * 64
            for id, ent in pairs(self.entities) do
                local ex, ey = ent.bod:getPosition()
                if inSquare(ex, ey, x + 8, y + 8, 48, 48) then
                    local randomTp = teleporters[math.random(1, #teleporters)]
                    print("GAME INFO: Teleporting entity")
                    local x, y = (randomTp[1] - 1) * 64, (randomTp[2] - 1) * 64
                    local ea = ent.bod:getAngle()
                    ent.bod:setPosition((x + 32) + math.cos(ea) * 48, (y + 32) + math.sin(ea) * 48)
                end
            end
        end]]

        -- update bullets
        for id, bullet in pairs(bullets) do
            if bullet.bod:isDestroyed() then
                table.remove(bullets, id)
            else
                local bx, by = bullet.bod:getPosition()
                particles.emit(1, bx, by, {min = 0, max = 2 * math.pi}, 5, 1.1, 7, 1, 3, {r = .75, g = .75, b = .75}, true)
            end
        end

        orb.update(self, dt)
        chest.update(self, dt)
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

        -- draw teleporters
        --[[for id, pos in pairs(teleporters) do
            love.graphics.setColor(.25, 0, .25)
            love.graphics.rectangle("fill", (pos[1] - 1) * 64 + 8, (pos[2] - 1) * 64 + 8, 48, 48, 5)
            love.graphics.setColor(0, 0, 0)
            love.graphics.setLineWidth(4)
            love.graphics.rectangle("line", (pos[1] - 1) * 64 + 8, (pos[2] - 1) * 64 + 8, 48, 48, 5)
            love.graphics.setLineWidth(1)
        end]]

        doors.draw(self)
        chest.draw(self)
        orb.draw(self)

        -- draw items & particles
        items.draw()
        particles.draw()

        -- draw entities
        for id, ent in pairs(self.entities) do
            love.graphics.push("transform")

            local x, y = ent.bod:getPosition()
            local vx, vy = ent.bod:getLinearVelocity()
            local a = ent.bod:getAngle()

            love.graphics.translate(x, y)
            if id ~= playerUUID then
                love.graphics.setColor(1, 1, 1, (255 - sl(cmx, cmy, x, y)) / 255)
                local tag = ""
                if ent.name ~= "" then
                    tag = ent.name .. " - " .. removeDecimal(ent:getLevel())
                else
                    tag = lang.print("level", {removeDecimal(ent:getLevel())})
                end
                love.graphics.print(tag, -hudFont:getWidth(tag) / 2, -25)
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

            local img = images.weapons.hold[ent:getWeapon(true)] -- true make the function return only the name of the weapon
            if img ~= nil then
                --love.graphics.rotate(math.pi/2)
                love.graphics.translate(0, -32)
                love.graphics.draw(img, -16, -6)
            end

            love.graphics.pop()

            if config.ai.debug and id ~= playerUUID then
                ai.draw(ent, self.entities[playerUUID]) -- show the brain of the ai (debug)
            end
        end
    end

    tree.init()

    cam = camera(0, 0)
    smoother = cam.smooth.damped(5)

    dotCursor = false
    skillTreeIsOpen = false

    warmup = config.warmup

    pause = false
    deathscreen.init()
    SetTranslation(0, 0) -- set translations for buttons

    -- create pause buttons
    button_resume = NewButton("button", 0, 0, 192, 80, function() pause = false end, lang.print("play"), {241, 196, 15}, {shape = "sharp", easing = "bounce", font = menuFont})
    button_menu = NewButton("button", 0, 96, 192, 80, function() gamestate.switch(menu) end, lang.print("menu"), {203, 67, 53}, {shape = "sharp", easing = "bounce", font = menuFont})
end

function game:resize(w, h)
    print("GAME INFO: Window got resized")
	map:resize(w, h)
    lightWorld:Resize(w, h)
    particles.window(w, h)
    scalex = h / 480
    scalex = w / 853
end

function game:keypressed(key, scancode, isrepeat)
    if isIn(key, {"1", "2", "3", "4", "5", "6", "7", "8", "9"}) and not pause then
        local slot = tonumber(key)
        if slot <= #ply.inventory then
            ply:setSlot(slot)
        end
    elseif key == config.controls.use and not pause then
        local x, y = cam:worldCoords(mx, my)
        local error = items.interact(ply, x, y, px, py)
        if error then set_notif({error}) end

        chest.interact(x, y)
        doors.interact(x, y)
        orb.interact(x, y)
    elseif key == config.controls.drop and not pause then
        ply:drop(ply.selectedSlot)
    elseif key == "escape" then
        if not pause and skillTreeIsOpen then
            skillTreeIsOpen = false
        else
            pause = not pause
        end
    elseif key == "f3" then
        config.debug = not config.debug
        love.mouse.setGrabbed(not love.mouse.isGrabbed())
        map.layers["Map Entities"].visible = not map.layers["Map Entities"].visible
    elseif key == config.controls.skill_tree and not pause then
        skillTreeIsOpen = not skillTreeIsOpen
    elseif key == config.controls.burst then
        ply.enable_burst = not ply.enable_burst -- toggle burst mode
        print("GAME INFO: Toggled burst mode for automatic weapons")
    end
end

function game:wheelmoved(x, y)
    if pause then return end

    local ply = entities.entities[playerUUID]
    local newSlot = ply.selectedSlot - y

    if newSlot < 1 then ply:setSlot(#ply.inventory)
    elseif newSlot > #ply.inventory then ply:setSlot(1)
    else ply:setSlot(newSlot) end
end

function game:mousepressed(x, y, button, isTouch)
    if skillTreeIsOpen then
        tree.mousepressed(x, y, button)
    elseif pause then
        button_resume:mousepressed(x, y, button)
        button_menu:mousepressed(x, y, button)
    end
end

function game:mousereleased(x, y, button, isTouch)
    if skillTreeIsOpen then
        tree.mousereleased(x, y, button)
    elseif pause then
        button_resume:mousereleased(x, y, button)
        button_menu:mousereleased(x, y, button)
    end
end

function controls(dt)
    local ply = entities.entities[playerUUID]
    local cooldown = ply.cooldown
    local pa = ply.bod:getAngle()
    local vx, vy = ply.bod:getLinearVelocity()

    local speed = love.physics.getMeter() * (4 + ply.skills.speed)

    if key(config.controls.sprint) and not key(config.controls.sneak) and cooldown.sprint ~= ply.skills.stamina and math.abs(vx + vy) > 1 then
        speed = speed * 2
        ply.sprinting = true
    elseif not key(config.controls.sprint) or math.abs(vx + vy) <= 1 then
        ply.sprinting = false
    end

    if key(config.controls.sneak) and not key(config.controls.sprint) then
        speed = speed / 2
        ply.sneaking = true
    elseif not key(config.controls.sneak) or math.abs(vx + vy) <= 1 then
        ply.sneaking = false
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

    if key(config.controls.dash) and cooldown.dash == 0 and cooldown.sprint < ply.skills.stamina then
        ply.bod:applyLinearImpulse(math.cos(pa) * 200, math.sin(pa) * 200)
        cooldown.dash = 1
        cooldown.sprint = cooldown.sprint + dt * 10
    end

    if love.mouse.isDown(1) and not skillTreeIsOpen and warmup <= 9 and not preventAttack then
        local wep = ply:getWeapon()
        local firetype = wep.firetype
        if firetype == "auto" or firetype == "burst" then -- full-auto weps
            attack(entities.entities[playerUUID], playerUUID)
        elseif not attackIsDown then -- semi-auto weps
            attack(entities.entities[playerUUID], playerUUID)
            attackIsDown = true
        end
    elseif not love.mouse.isDown(1) then
        attackIsDown = false
        if sounds.flame:isPlaying() then
            sounds.flame:stop()
        end
    end
end

function game:update(dt)
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

    if not pause and warmup ~= -1 then
        warmup = math.max(warmup - dt, 0)
        set_notif({"warmup", { string.format("%.1f", tostring(round(warmup, 1))) }}, false)
        if warmup == 0 then
            set_notif({"warmup", { string.format("%.1f", tostring(round(warmup, 1))) }})
            warmup = -1
        end
    end

    ply = entities.entities[playerUUID]
    px, py = ply.bod:getPosition()
    pcx, pcy = cam:cameraCoords(px, py)

    maxAIs = math.max(removeDecimal(ply.kills / 5), 2)

    if ply.inventory == nil or ply.inventory == {} or #ply.inventory == 0 then
        error("Inventory is empty!")
    elseif #ply.inventory < 0 then
        error("Inventory size is negative! " .. #ply.inventory)
    elseif ply:getWeapon() == nil and ply.selectedSlot ~= 1 then
        ply:setSlot(1)
    elseif ply:getWeapon() == nil then
        error("Weapon cannot be found!")
    end

    if not pause then
        controls(dt)
        particles.update(dt)
        timer.update(dt)
        items.update(dt)
    end

    map:update(dt)
    world:update(dt)
    update_hud(dt)

    local pa = math.atan2(cmy - py, cmx - px) -- angle of the player
    ply.bod:setAngle( pa )

    cam:lockPosition( px + math.cos(pa) * 20, py + math.sin(pa) * 20, smoother )
    cam:zoomTo(scalex)

    tx, ty = -(cx / cam.scale), -(cy / cam.scale)
    particles.translation(tx, ty)

    if config.shader then
        lights.player:SetPosition((-cx + pcx) / cam.scale, (-cy + pcy) / cam.scale, 1)

        lightWorld:SetPosition(-cx, -cy, cam.scale)
        lightWorld:Update(dt)
    end

    for index, bullet in pairs(bullets) do
        -- remove bullets using age
        if not bullet.bod:isDestroyed() then
            bullet.age = math.max(bullet.age - dt, 0)
            if bullet.age == 0 then
                local userData = bullet.fixture:getUserData()
                removeBullet(bullet.bod, userData.weapon, userData.owner_id)
            end
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
        skillTreeIsOpen = false -- close skill tree if pause mode is activated
    end

    if skillTreeIsOpen then
        tree.update(dt)
        SetTranslation(0, 0)
    end
    
    if ply:getHealth() <= 0 then
        pause = true
        deathscreen.update(dt)
    elseif pause then
        button_resume:update(dt)
        button_menu:update(dt)
    end
end

function game:draw()
    -- draw the map
    love.graphics.setColor(1, 1, 1)

    dotCursor = false -- reset cursor mode

    map:draw(-tx, -ty, cam.scale, cam.scale) -- draw map

    --cam:draw(function() end) -- unused

    if config.shader then lightWorld:Draw() end -- draw light world if enabled

    draw_hud()

    -- skill tree (if opened)
    if skillTreeIsOpen then
        tree.draw()
        love.graphics.setLineWidth(1)
    end

    if ply:getHealth() <= 0 then
        deathscreen.draw() -- draw death screen
    elseif pause then
        local pause_button_x, pause_button_y = basicCamera(96, 88, function()
            button_resume:draw()
            button_menu:draw()
        end)

        SetTranslation(pause_button_x, pause_button_y)
    end

    if config.debug then
        love.graphics.setColor(1, 0, 0)
        -- draw collision map (debug)
        map:box2d_draw(-tx, -ty, cam.scale, cam.scale) -- draw debug map if enabled

        local stats = love.graphics.getStats()

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(hudFont)
        local position = 1
        for index, value in pairs(stats) do
            love.graphics.print(index .. ": " .. value, 5, position * 12 + 100)
            position = position + 1
        end
    end

    -- draw cursor
    love.graphics.setColor(1, 1, 1)
    if dotCursor then
        love.graphics.draw(images.dot, mx - 16, my - 16)
    else
        love.graphics.draw(images.cursor, mx - 16, my - 16)
    end
end

function game:leave()
    ply:save()
    timer.clear()

    items.clear()
    entities.entities = {}
    lights = {}
    lightWorld = nil
    world = nil
    spawns = {}
    teleporters = {}

    particles.clear()
    love.audio.stop()
end

function game:quit()
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
        local bx, by = b:getBody():getPosition()

        if a:getUserData()[1] == "Player" and wep.bullet.type ~= "explosive" then
            bulletDamage(wep, a:getUserData().id, b:getBody():getAngle(), b:getUserData().owner_id, bx, by)
        end

        removeBullet(b:getBody(), wep, b:getUserData().owner_id)
    end
end

function endContact(a, b, coll)
end
 
function preSolve(a, b, coll)
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end

return game