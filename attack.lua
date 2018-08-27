bullets = {}
local maxSpeed = love.physics.getMeter() * 8

local function bloodParticles(amount, x, y, a, v)
    if not v then v = 100 end
    for i=1, math.random( amount/4, amount ) do
        particles.emit(x, y, {min = a - .75, max = a + .75}, 100 * v, 1.1, 8, 12, 8, {r = .75, g = 0, b = 0}, true)
    end
end

local function damageAmount(weapon, dist) -- this function decide the damage the weapon will deal
    local d = rf(weapon.damage.min, weapon.damage.max, 1)
    if dist ~= nil then
        local dr = (dist / weapon.range)
        d = round(rf(weapon.damage.min, weapon.damage.max, 1) / dr, 1)
    end

    if percent(weapon.critic.chance) then
        return d * rf(weapon.critic.mult.min, weapon.critic.mult.max, 1), true
    end
    return d, false
end

local function spread(weapon, ent)
    -- must add spread based on ent's speed
    local minSpread = math.min(-weapon.spread + ent.skills.accuracy / 100, 0)
    local maxSpread = math.max(weapon.spread - ent.skills.accuracy / 100, 0)
    return rf(minSpread, maxSpread, 4), rf(minSpread, maxSpread, 4)
end

function attack(attacker, attacker_id)
    if attacker:getHealth() <= 0 then return false end
    if attacker.cooldown.attack > 0 then return false end

    local wep = attacker:getWeapon()

    if wep.firetype == "auto" and wep.type == "firearm" and attacker.enable_burst and attacker.burst < wep.bullet.burst then
        attacker.cooldown.attack = math.max(wep.cooldown / 4, 0.05) -- limit to 50 bullet on burst mode
        attacker.burst = attacker.burst + 1
    else
        attacker.cooldown.attack = (attacker.enable_burst and wep.firetype == "auto" and wep.type == "firearm" and wep.cooldown * 1.5) or wep.cooldown
        attacker.burst = 1
    end
    
    local ax, ay = attacker.bod:getPosition()
    local aa = attacker.bod:getAngle()

    attacker.bod:applyLinearImpulse(math.cos(aa) * wep.knockback.self * -10, math.sin(aa) * wep.knockback.self * -10)

    -- melee attack
    if wep.type == "melee" then
        if wep.fire then
            -- particles.emit(x, y, r, speed, damping, size, life, vertices, color, fade_out)
            particles.emit(ax + math.cos(aa) * 5, ay + math.sin(aa) * 5, {min = aa - rf(0, .2, 2), max = aa + rf(0, .2, 2)}, 50, 1, 5, 2, 3, {r = .85, g = .15, b = 0}) -- red
            particles.emit(ax + math.cos(aa) * 5, ay + math.sin(aa) * 5, {min = aa - rf(0, .1, 2), max = aa + rf(0, .1, 2)}, 100, 1, 5, 2, 3, {r = 1, g = .75, b = 0}, true) -- yellow
            particles.emit(ax + math.cos(aa) * 5, ay + math.sin(aa) * 5, {min = aa - rf(0, .1, 2), max = aa + rf(0, .1, 2)}, 100, 1, 10, 2, 5, {r = 1, g = .5, b = .15}) -- orange
            particles.emit(ax + math.cos(aa) * 5, ay + math.sin(aa) * 5, {min = aa - rf(0, .3, 2), max = aa + rf(0, .3, 2)}, 25, 1, 12, 1, 7, {r = .25, g = .25, b = .25, a = .75}, true) -- black
            sounds.flame:play()
        else
            sounds.sword_swing:stop()
            sounds.sword_swing:play()
        end

        for id, victim in pairs(entities.entities) do
            if victim:getHealth() > 0 and id ~= attacker_id then -- check if the players is not dead and if it's not the same
                local vx, vy = victim.bod:getPosition() -- victim pos
                local angleTo = math.atan2(vy - ay, vx - ax)
                local dist = sl(ax, ay, vx, vy) -- dist between victim and attacker

                if dist <= wep.range and -- if player is in range to be attacked
                between(angleTo, aa - wep.radius, aa + wep.radius) then
                    local damage, wasCritic = damageAmount(wep, dist - attacker.skills.accuracy)
                    damage = damage + attacker.skills.strength
                    print("Attacker dealt " .. damage .. " damage to victim")

                    victim:addHealth(math.min(-damage, 0)) -- remove health from the victim
                    victim.bod:applyLinearImpulse(math.cos(angleTo) * wep.knockback.victim * 10, math.sin(angleTo) * wep.knockback.victim * 10)

                    victim.lastAttacker = attacker_id
                    bloodParticles(damage * 2, vx, vy, angleTo)

                    sounds.sword_hit:play()
                end
            end
        end
    elseif wep.type == "firearm" then
        local fire = (ply:getWeapon().firetype ~= "burst" and wep.bullet.amount) or 1

        sounds.fire:stop()
        sounds.fire:play()

        for i=1, fire do
            local b = {}
            
            b.bod = love.physics.newBody(world, ax + math.cos(aa) * 20, ay + math.sin(aa) * 20, "dynamic")
            b.bod:setBullet(true)
            b.bod:setAngle(aa)

            local radius = wep.bullet.radius
            b.shape = love.physics.newCircleShape(radius)
            b.bod:setMass(0.001)
            
            b.fixture = love.physics.newFixture(b.bod, b.shape)
            b.fixture:setRestitution(.2)
            b.fixture:setUserData({"Bullet", weapon = wep, owner_id = attacker_id})

            local spreadx, spready = spread(wep, attacker)
            local speed = wep.bullet.speed or 10
            b.bod:applyLinearImpulse(
                math.cos(aa + (spreadx)) * speed,
                math.sin(aa + (spready)) * speed
            )

            for i=2, math.random( 2, 5 ) do
                -- shoot particles
                particles.emit(ax + math.cos(aa) * 5, ay + math.sin(aa) * 5, {min = aa - .3, max = aa + .3}, 20, 1, 7, 2, 5, {r = 1, g = .5, b = .15}, true) -- orange
                particles.emit(ax + math.cos(aa) * 5, ay + math.sin(aa) * 5, {min = aa - .3, max = aa + .3}, 20, 1, 15, 2, 6, {r = .75, g = .75, b = .75, a = .25}) -- white
            end

            b.age = wep.bullet.life

            table.insert(bullets, b)
        end

        print(#bullets .. " bullets in the world")
    end

    return true
end

function bulletDamage(weapon, victim_id, angle, owner_id, bx, by)
    local victim = entities.entities[victim_id]
    if victim == nil then return end

    if victim:getHealth() > 0 and owner_id ~= victim_id then
        print("Bullet touched an ennemy")
        local vx, vy = victim.bod:getPosition()
        local angleToVictim = math.atan2(vy - by, vx - bx)
        
        local damage, wasCritic = damageAmount(weapon, dist)

        victim:addHealth(math.min(-damage, 0))
        victim.bod:applyLinearImpulse(math.cos(angle) * weapon.knockback.victim * 10, math.sin(angle) * weapon.knockback.victim * 10)

        bloodParticles(damage * 2, vx, vy, angleToVictim)
        
        print("Attacker dealt " .. damage .. " damage to victim")

        victim.lastAttacker = owner_id

        sounds.hit:play()
    end
end

function removeBullet(body, wep, owner_id)
    local x, y = body:getPosition()
    local type = wep.bullet.type

    if type == "explosive" then
        local explode_radius = wep.bullet.explode_radius

        for i=1, math.random( 25, 35 ) do
            -- explosive particles
            particles.emit(x, y, {min = 0, max = 2 * math.pi}, 100, 1, 7, 1.5, 3, {r = .85, g = .15, b = 0}) -- red
            particles.emit(x, y, {min = 0, max = 2 * math.pi}, 100, 1, 7, 1.5, 5, {r = 1, g = .5, b = .15}) -- orange
            particles.emit(x, y, {min = 0, max = 2 * math.pi}, math.random( 45, 55 ), 1, 20, 3, 7, {r = .75, g = .75, b = .75, a = .25}, true) -- white
            particles.emit(x, y, {min = 0, max = 2 * math.pi}, math.random( 55, 65 ), 1, 20, 3, 7, {r = .75, g = .75, b = .75, a = .25}, true) -- white
            particles.emit(x, y, {min = 0, max = 2 * math.pi}, math.random( 65, 75 ), 1, 15, 3, 5, {r = .25, g = .25, b = .25, a = .75}) -- black
        end

        sounds.explosion:stop()
        sounds.explosion:play()

        for id, ent in pairs(entities.entities) do
            local ex, ey = ent.bod:getPosition()
            local dist = sl(ex, ey, x, y)
            if dist <= explode_radius then
                local damage, wasCritic = damageAmount(wep)
                ent:addHealth(math.min(-damage, 0))
                local angle = math.atan2(ey - y, ex - x)
                ent.bod:applyLinearImpulse(math.cos(angle) * wep.knockback.victim * 10, math.sin(angle) * wep.knockback.victim * 10)
                bloodParticles(damage * 4, ex, ey, angle, wep.knockback.victim * 10)
                ent.lastAttacker = owner_id
            end
        end
    else
        sounds.hit:play()
    end
    body:destroy()
end