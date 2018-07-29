bullets = {}
local maxSpeed = love.physics.getMeter() * 8

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
    return rf(weapon.spread.min, weapon.spread.max, 4), rf(weapon.spread.min, weapon.spread.max, 4)
end

function attack(attacker, attacker_id)
    if attacker:getHealth() <= 0 then return end

    if attacker.cooldown.attack > 0 then return end

    local wep = attacker:getWeapon()

    attacker.cooldown.attack = wep.cooldown
    
    local ax, ay = attacker.bod:getPosition()
    local aa = attacker.bod:getAngle()

    attacker.bod:applyLinearImpulse(math.cos(aa) * wep.knockback.self * -10, math.sin(aa) * wep.knockback.self * -10)

    -- melee attack
    if wep.type == "melee" then
        print("Attacking with a melee weapon")
        for id, victim in pairs(entities.entities) do
            if victim:getHealth() > 0 and id ~= attacker_id then -- check if the players is not dead and if it's not the same
                local vx, vy = victim.bod:getPosition() -- victim pos
                local angleTo = math.atan2(vy - ay, vx - ax)
                local dist = sl(ax, ay, vx, vy) -- dist between victim and attacker

                if dist <= wep.range and -- if player is in range to be attacked
                between(angleTo, aa - wep.radius, aa + wep.radius) then
                    local damage, wasCritic = damageAmount(wep, dist)
                    print("Attacker dealt " .. damage .. " damage to victim")

                    victim:remHealth(damage) -- remove health from the victim
                    victim.bod:applyLinearImpulse(math.cos(angleTo) * wep.knockback.victim * 10, math.sin(angleTo) * wep.knockback.victim * 10)
                elseif dist > wep.range then
                    print("Victim out of range")
                elseif not between(angleTo, aa - wep.radius, aa + wep.radius) then
                    print("Victim out of radius")
                else
                    error("Unknown error, please report:\n\n" .. ser( wep ) .. "\n\n" .. angleTo .. "\n" .. dist )
                end
            end
        end
    elseif wep.type == "firearm" then
        print("Attacking with a firearm")

        local fire = wep.bullet.amount or 1

        for i=1, fire do
            local b = {}

            b.bod = love.physics.newBody(world, ax + math.cos(aa) * 20, ay + math.sin(aa) * 20, "dynamic")
            b.bod:setBullet(true)
            b.bod:setAngle(aa)
            b.bod:setLinearDamping(1)

            b.shape = love.physics.newCircleShape(2)

            b.fixture = love.physics.newFixture(b.bod, b.shape)
            b.fixture:setRestitution(.2)
            b.fixture:setUserData({"Bullet", weapon = wep})

            local spreadx, spready = spread(wep, attacker)
            local speed = wep.bullet.speed or 10
            b.bod:applyLinearImpulse(math.cos(aa + spreadx) * speed, math.sin(aa + spready) * speed)

            b.age = wep.bullet.life

            table.insert(bullets, b)
        end

        print(#bullets .. " bullets in the world")
    end
end

function bulletDamage(weapon, victim_id, angle)
    local victim = entities.entities[victim_id]
    
    if victim == nil then return end

    print("Bullet touched an ennemy")
    if victim:getHealth() > 0 then
        local damage, wasCritic = damageAmount(weapon, dist)

        victim:remHealth(damage)
        victim.bod:applyLinearImpulse(math.cos(angle) * weapon.knockback.victim * 10, math.sin(angle) * weapon.knockback.victim * 10)
        
        print("Attacker dealt " .. damage .. " damage to victim")
    end
end