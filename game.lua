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

    weapons = json:decode( love.filesystem.read( "data/weapons.json" ) ) -- Load game content

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

    map:addCustomLayer("Doors Layer", 3)
    map.layers["Doors Layer"].doors = {}
    doors = map.layers["Doors Layer"]
    
    lightWorld = LightWorld:new()
    lightWorld:SetColor(10, 10, 10, 255)
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

        table.insert(doors.doors, d)
    end

    function doors:draw()
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
    end

    lights = {}

    for x=1, map.layers["Collisions"].width do
        for y=1, map.layers["Collisions"].height do
            local t = map.layers["Collisions"].data[x][y]
            local id = #lights+1
            if t ~= nil and t.id ~= 0 then
                if t.id == 1 then --[[ print("Collision") ]]
                elseif t.id == 2 then
                    table.insert(spawns.friendly, {y, x})
                elseif t.id == 3 then
                    table.insert(spawns.hostile, {y, x})
                --elseif t.id == 4 then print("One way")
                --elseif t.id == 5 then print("Hinge")
                elseif t.id == 6 then
                    addDoor(y, x, t.r)
                --elseif t.id == 7 then print("Weapon spawn")
                elseif t.id == 8 then print("Blue light")
                    lights[id] = Light:new(lightWorld, 300)
                    lights[id]:SetColor(0, 0, 155)
                elseif t.id == 9 then print("Red light")
                    lights[id] = Light:new(lightWorld, 300)
                    lights[id]:SetColor(155, 0, 0)
                elseif t.id == 10 then print("Yellow light")
                    lights[id] = Light:new(lightWorld, 300)
                    lights[id]:SetColor(155, 155, 0)
                elseif t.id == 11 then print("White light")
                    lights[id] = Light:new(lightWorld, 300)
                    lights[id]:SetColor(155, 155, 155)
                --elseif t.id == 12 then print("Health")
                --elseif t.id == 13 then print("Armor")
                --elseif t.id == 14 then print("Boss spawn")
                --elseif t.id == 15 then print("Cannon")
                end

                if lights[id] then lights[id]:SetPosition(y * 64 - 32, x * 64 - 32) end
            end
        end
    end
    
    lightWorld:InitFromPhysics(world)
    print("Initialized light world")

    print(#spawns.friendly .. " player spawns found")
    print(#spawns.hostile .. " ennemy spawns found")
    local x, y = unpack( spawns.friendly[math.random(1, #spawns.friendly)] )

    playerUUID = uuid()

    map:addCustomLayer("Entities Layer", 3)
    map.layers["Entities Layer"].entities = {}
    entities = map.layers["Entities Layer"]

    entities.entities[playerUUID] = newPlayer(x, y, playerUUID)
    lights.player = Light:new(lightWorld, 200)
    lights.player:SetColor(155, 155, 155)
    lights.mouse = Light:new(lightWorld, 100)
    lights.mouse:SetColor(155, 155, 155)
    print("Added player's and mouse's light")

    local function addEnnemy()
        local x, y = unpack( spawns.hostile[math.random(1, #spawns.hostile)] )
        local uid = uuid()
        entities.entities[uid] = newPlayer(x, y, uid)
        ai.set(entities.entities[uid], uid)
    end
    addEnnemy()

    function entities:update(dt)
        for id, ent in pairs(self.entities) do
            local px, py = ent.bod:getPosition()

            ent.cooldown.attack = math.max(ent.cooldown.attack - dt, 0) -- cooldown for primary attack
            ent.cooldown.special = math.max(ent.cooldown.special - dt, 0) -- cooldown for special attack
            ent.cooldown.dodge = math.max(ent.cooldown.dodge - dt, 0) -- cooldown for rolling

            if id == playerUUID then
                local pa = math.atan2(cmy - py, cmx - px) -- angle of the player
                ent.bod:setAngle( pa )
                cam:lockPosition( px + math.cos(pa) * 20, py + math.sin(pa) * 20, smoother )
            else
                --ai.update(ent, self.entities[playerUUID], id)

                if ent:getHealth() <= 0 then
                    self.entities[id] = nil
                    addEnnemy()
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

            love.graphics.setColor(1, 1, 1, 1)

            love.graphics.translate(x, y)
            love.graphics.rotate(a)
            love.graphics.rectangle("fill", -20/2, -20/2, 20, 20)

            love.graphics.pop()

            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.line(x, y, x + math.cos(a) * 20, y + math.sin(a) * 20)

            if id ~= playerUUID then
                --ai.draw(ent, self.entities[playerUUID]) -- show the brain of the ai (debug)
            end
        end

        for id, bullet in pairs(bullets) do
            if not bullet.bod:isDestroyed() then
                local bx, by = bullet.bod:getPosition()
                love.graphics.circle("fill", bx, by, 2)
            end
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

function G:wheelmoved(x, y)
    local ply = entities.entities[playerUUID]
    ply:setSlot(ply.selectedSlot - y)
    if ply.selectedSlot <= 0 then ply:setSlot(#ply.inventory)
    elseif ply.selectedSlot > #ply.inventory then ply:setSlot(1) end
end

function controls(dt)
    local ply = entities.entities[playerUUID]
    local cooldown = ply.cooldown
    local pa = ply.bod:getAngle()
    local vx, vy = ply.bod:getLinearVelocity()

    local speed = love.physics.getMeter() * 4

    if key("lshift") and cooldown.sprint ~= 2 then
        speed = speed * 2
        cooldown.sprint = math.min(cooldown.sprint + dt, 2)
    elseif not key("lshift") then
        cooldown.sprint = math.max(cooldown.sprint - dt, 0) -- cooldown for sprinting
    end

    if key("z") then
        ply.bod:applyForce(speed * math.cos(pa), speed * math.sin(pa))
    elseif key("s") then
        ply.bod:applyForce(-speed / 2 * math.cos(pa), -speed / 2 * math.sin(pa))
    end

    if key("q") then
        ply.bod:applyForce(-speed * math.cos(pa + (math.pi / 2)), -speed * math.sin(pa + (math.pi / 2)))
    elseif key("d") then
        ply.bod:applyForce(speed * math.cos(pa + (math.pi / 2)), speed * math.sin(pa + (math.pi / 2)))
    end

    if key("space") and cooldown.dodge == 0 and cooldown.sprint < 2 then
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

    ply = entities.entities[playerUUID]
    px, py = ply.bod:getPosition()
    pcx, pcy = cam:cameraCoords(px, py)

    controls(dt)

    map:update(dt)
    world:update(dt)
    lightWorld:Update()
    lightWorld:SetPosition(cpx - pcx + (px - cpx), cpy - pcy + (py - cpy))

    lights.player:SetPosition(px, py, 1)
    lights.mouse:SetPosition(cmx, cmy, 1)

    for index, bullet in pairs(bullets) do
        -- remove bullets using age
        if not bullet.bod:isDestroyed() then
            bullet.age = math.max(bullet.age - dt, 0)
            if bullet.age == 0 then bullet.bod:destroy() end
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
    
    if ply == nil or ply:getHealth() <= 0 then gamestate.switch(menu.main) end
end

function G:draw()
    cam:draw(function()
        -- draw the map
        love.graphics.setColor(1, 1, 1)
        map:draw(cx, cy)

        -- draw collision map (debug)
        --love.graphics.setColor(1, 0, 0, .5)
        --map:box2d_draw()
    end)

    lightWorld:Draw()

    love.graphics.setFont(hudFont)

    for index, item in pairs(entities.entities[playerUUID].inventory) do
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

    love.graphics.print("Framerate: " .. love.timer.getFPS(), 5, 20)

    mx, my = love.mouse.getPosition()
    love.graphics.draw(cursor, mx - 16, my - 16)

    local percentage =  ply.cooldown.attack / ply:getWeapon().cooldown * 100

    love.graphics.line(mx - 20, my + 18, (mx - 20) + percentage / 100 * 40, my + 18)
end

function G:exit()
    entities.entities = {}
    lights.player:remove()
    lightWorld, world = nil, nil
end

-- collision callback
function beginContact(a, b, coll)
    if a:isSensor() or a:getUserData()[1] == "Bullet" then return end

    if b:getUserData()[1] == "Bullet" then
        if a:getUserData()[1] == "Player" then
            bulletDamage(b:getUserData().weapon, a:getUserData().id, b:getBody():getAngle())
        end

        b:getBody():destroy()
    end
end

function endContact(a, b, coll)
end
 
function preSolve(a, b, coll)
end
 
function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end

return G
