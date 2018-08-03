local player = {}
player.__index = player

local defaultWeapon = "fists"     -- default weapon to spawn with
local maxInventory = 2         -- maximum items the player can have

function newPlayer(x, y, id, weapon, level) -- creates a new player
    if x == nil or y == nil then error("You must give coordinates for the new player to spawn") return end

    if not level then level = 0 end

    print("The level of this entity is " .. level)

    local p = {}

    if weapon == nil then
        weapon = defaultWeapon
        print("Entity spawn with " .. weapon)
    end
    p.inventory = { weapon }
    p.selectedSlot = 1
    p.cooldown = {
        attack = 0,
        sprint = 0,
        special = 0,
        dodge = 0
    }

    p.skills = {}

    for name, value in pairs(skills.skills) do
        p.skills[name] = value.default + level
    end
    
    p.kills = 0
    p.lastAttacker = nil
    p.exp = 0 + level
    p.score = 0
    
    p.boostedSkills = {}

    if love.filesystem.getInfo( id ) then
        local l = bitser.loads(love.filesystem.read( id ))
        print("Player save found")

        if l.defaultWeapon == nil then error("No weapon found in the save!") end
        p.inventory = { l.defaultWeapon }
        p.defaultWeapon = l.defaultWeapon
        p.exp = l.exp
        for skill, value in pairs(l.skills) do
            if p.skills[skill] then
                p.skills[skill] = value
            end
        end

        if l.highScore then p.highScore = l.highScore end

        p.name = id

        print(l.defaultWeapon)
    else
        p.name = namegen.generate("human male")
    end

    p.health = p.skills.health

    p.bod = love.physics.newBody( world, x * 64, y * 64, "dynamic" ) -- creates a body for the player
    p.bod:setLinearDamping(16)
    p.bod:setAngularDamping(16)

    p.shape = love.physics.newRectangleShape(20, 20)
    
    p.fixture = love.physics.newFixture(p.bod, p.shape)
    p.fixture:setRestitution(.2)
    p.fixture:setUserData({"Player", id = id})

    --p.shadow = Body:new(lightWorld):InitFromPhysics(p.bod)

    p.defaultMass = p.bod:getMass()

    p.id = id

    print("New player created")
    return setmetatable(p, player)
end

function player:save()
    self:resetSkills()

    local s = {}
    s.defaultWeapon = self.defaultWeapon
    s.skills = self.skills
    s.health = self.health
    s.x, s.y = self.bod:getPosition()
    s.exp = self.exp
    if not self.highScore or self.score > self.highScore then
        s.highScore = self.score
    end

    love.filesystem.write( self.id, bitser.dumps( s ) )
end

-- health related functions
function player:getHealth() return self.health, self.skills.health end
function player:setHealth(newHealth) self.health = newHealth end                        -- set a new health value of the player
function player:addHealth(healthPoints) -- add health points to the player
    local newHealth = self.health + healthPoints
    if newHealth ~= self.skills.health then
        self.health = math.min(newHealth, self.skills.health)
        return true
    end
end

function player:getLevel()
    local level = 0
    for skill, value in pairs(self.skills) do
        level = level + value
    end

    return level
end

function player:updateWeight()
    local weightToAdd = self:getWeapon().weight or 0
    self.bod:setMass( self.defaultMass + weightToAdd )
end

-- inventory functions
function player:getWeapon(name)
    if name then return self.inventory[self.selectedSlot] end
    return weapons[self.inventory[self.selectedSlot]]
end

function player:setSlot(slot)
    self.selectedSlot = slot
    --self:updateWeight()
end

function player:addItem(item)
    print("Picking up " .. item)
    if #self.inventory <= maxInventory then
        table.insert(self.inventory, item)
        sounds.pickup:play()
        return true
    elseif #self.inventory > maxInventory then
        print("Inventory is full")
        return false
    end
end

function player:drop(item)
    print("Dropping " .. item)
    if #self.inventory <= 1 then print("Can't drop that") return end
    local a = self.bod:getAngle()
    items.drop(px, py, a, self.inventory[item])
    table.remove(self.inventory, item)
    if item > #self.inventory then self.selectedSlot = #self.inventory end
    --self:updateWeight()
end

function player:addKill(amount, victim)
    self.kills = self.kills + amount

    self.score = self.score + victim:getLevel()

    local xp = victim.exp

    self.exp = self.exp + xp
    sounds.exp:setPitch(rf(.8, 1.2, 2))
    sounds.exp:play()
    print("Gain " .. xp .. " exp")
end

function player:increaseSkill(name)
    local cost = math.max(ply.skills[name] * skills.skills[name].mult, skills.skills[name].mult)

    if self.exp < cost then
        print("Not enough exp")
        return
    end

    self.exp = self.exp - cost
    self.skills[name] = self.skills[name] + 0.1
end

function player:skillBoost(skill, amount)
    local currentSkill = self.skills[skill]
    local newSkill = self.skills[skill] + amount
    local delta = newSkill - currentSkill

    self.skills[skill] = newSkill

    local index = #self.boostedSkills + 1

    table.insert(self.boostedSkills, index, {name = skill, amount = delta})

    print(("Skill %s boosted by %g"):format(skill, amount))

    timer.after(math.random(10, 20), function()
        self.skills[skill] = self.skills[skill] - delta
        print(("Skill %s back to %g"):format(skill, self.skills[skill]))

        if skill == "health" and self.health > self.skills.health then
            self:setHealth(self.skills.health)
        end

        table.remove(self.boostedSkills, index)
    end)
end

function player:resetSkills()
    for index, skill in pairs(self.boostedSkills) do
        self.skills[skill.name] = self.skills[skill.name] - skill.amount
    end
end