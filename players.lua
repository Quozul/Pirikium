local player = {}
player.__index = player

local defaultWeapon = "fists"     -- default weapon to spawn with
local maxInventory = 2         -- maximum items the player can have

function newPlayer(x, y, id, class, level) -- creates a new player
    if x == nil or y == nil then error("You must give coordinates for the new player to spawn") return end

    if not level then level = 0 end

    console.print("The level of this entity is " .. level)

    local p = {}

    if class == nil then
        weapon = defaultWeapon
    else
        weapon = class.weapon
    end
    console.print("Entity spawn with " .. weapon)
    
    p.inventory = { weapon }
    p.selectedSlot = 1
    p.cooldown = {
        attack = 0,
        sprint = 0,
        special = 0,
        dash = 0
    }

    p.skills = {}

    for name, value in pairs(skills.skills) do
        p.skills[name] = value.default + level
        if class ~= nil and class.skills ~= nil and class.skills[name] then
            p.skills[name] = class.skills[name] + level
        end
    end
    
    p.kills = 0
    p.lastAttacker = nil
    p.exp = 0 + level
    p.score = 0
    
    p.boostedSkills = {}

    if love.filesystem.getInfo( "saves/" .. id ) then
        local l = bitser.loads(love.filesystem.read( "saves/" .. id ))
        console.print("Player save found")

        if l.defaultWeapon == nil then error("No weapon found in the save!") end
        p.inventory = { l.defaultWeapon }
        p.defaultWeapon = l.defaultWeapon
        p.exp = l.exp
        for skill, value in pairs(l.skills) do
            if p.skills[skill] then
                p.skills[skill] = value
            end
        end

        p.highScore = l.highScore

        p.name = id

        console.print("High score for this player is " .. l.highScore)
    else
        p.name = ""
    end

    console.print("Skill values:")
    for name, value in pairs(p.skills) do
        console.print(name .. ": " .. value)
    end

    p.health = p.skills.health
    p.previous_health = p.health
    p.burst = 0
    p.enable_burst = false

    p.bod = love.physics.newBody( world, x * 64 - 32, y * 64 - 32, "dynamic" ) -- creates a body for the player
    p.bod:setLinearDamping(16)
    p.bod:setAngularDamping(16)

    p.shape = love.physics.newRectangleShape(20, 20)
    
    p.fixture = love.physics.newFixture(p.bod, p.shape)
    p.fixture:setRestitution(.2)
    p.fixture:setUserData({"Player", id = id})

    --p.shadow = Body:new(lightWorld):InitFromPhysics(p.bod)

    p.defaultMass = p.bod:getMass()

    p.id = id

    console.print("New player created")
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
    else
        s.highScore = self.highScore
    end

    love.filesystem.write( "saves/" .. self.id, bitser.dumps( s ) )
end

-- health related functions
function player:getHealth() return self.health, self.skills.health, self.previous_health end
function player:setHealth(newHealth) self.health = newHealth end                        -- set a new health value of the player
function player:addHealth(healthPoints) -- add health points to the player
    self.previous_health = self.health
    self.health = math.min(self.health + healthPoints, self.skills.health)
    return true
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
    if self.cooldown.attack > self:getWeapon().cooldown then
        self.cooldown.attack = self:getWeapon().cooldown
    end
    --self:updateWeight()
end

function player:addItem(item)
    console.print("Picking up " .. item)
    if #self.inventory <= maxInventory then
        table.insert(self.inventory, item)
        sounds.pickup:play()
        return true
    elseif #self.inventory > maxInventory then
        console.print("Inventory is full")
        return false
    end
end

function player:drop(item)
    console.print("Dropping " .. item)
    if #self.inventory <= 1 then console.print("Can't drop that") return end
    local a = self.bod:getAngle()
    items.drop(px, py, a, self.inventory[item])
    table.remove(self.inventory, item)
    if item > #self.inventory then self.selectedSlot = #self.inventory end
    --self:updateWeight()
end

function player:addKill(amount, victim)
    self.kills = self.kills + amount

    self.score = self.score + victim:getLevel()

    local xp = math.max(victim.exp * 2, rf(1, 2.5, 1))

    self.exp = self.exp + xp
    sounds.exp:setPitch(rf(.8, 1.2, 2))
    sounds.exp:play()
    console.print("Gain " .. xp .. " exp")
end

function player:getSkillUpgradeCost(name)
    local defaultLevel = 0
    for index, skill in pairs(self.boostedSkills) do
        if skill.name == name then defaultLevel = defaultLevel + skill.amount end
    end

    return math.max((ply.skills[name] - defaultLevel) * skills.skills[name].mult + skills.skills[name].mult, skills.skills[name].mult)
end

function player:increaseSkill(name)
    local cost = self:getSkillUpgradeCost(name)

    console.print("Cost for upgrading " .. name .. " to level " .. ply.skills[name] + 1 .. " is " .. cost .. "exp")
    if self.exp < cost then
        console.print("Not enough exp")
        return
    end

    self.exp = self.exp - cost
    console.print("Current level: " .. self.skills[name])
    self.skills[name] = self.skills[name] + skills.skills[name].amount.upgrade
    console.print("New level: " .. self.skills[name])
end

function player:skillBoost(skill, amount)
    local currentSkill = self.skills[skill]
    local newSkill = self.skills[skill] + amount
    local delta = newSkill - currentSkill

    self.skills[skill] = newSkill

    local index = #self.boostedSkills + 1

    table.insert(self.boostedSkills, index, {name = skill, amount = delta})

    console.print(("Skill %s boosted by %g (previous value was: %g)"):format(skill, amount, currentSkill))

    timer.after(math.random(10, 20), function()
        self.skills[skill] = self.skills[skill] - delta
        console.print(("Skill %s back to %g"):format(skill, self.skills[skill]))

        if skill == "health" and self.health > self.skills.health then
            self:setHealth(self.skills.health)
        end

        table.remove(self.boostedSkills, index)
    end)
end

function player:resetSkills()
    console.print("Forcing skill reset...")
    for index, skill in pairs(self.boostedSkills) do
        self.skills[skill.name] = self.skills[skill.name] - skill.amount
        console.print(("PLAYER: Skill %s back to %g"):format(skill.name, self.skills[skill.name]))
        table.remove(self.boostedSkills, index)
    end

    if self.health > self.skills.health then
        self:setHealth(self.skills.health)
        console.print("Fixing health")
    end

    console.print(#self.boostedSkills .. " skills reset")
end