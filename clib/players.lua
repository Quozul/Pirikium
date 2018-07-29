local player = {}
player.__index = player

local maxHealth = 10            -- health at start
local defaultWeapon = "fists"     -- default weapon to spawn with
local maxInventory = 10         -- maximum items the player can have

function table.find(list, elem)
    for k,v in pairs(list) do
        print(k .. " " .. v)
        if v == elem then return k end
    end
end

function newPlayer(x, y, id) -- creates a new player
    if x == nil or y == nil then error("You must give coordinates for the new player to spawn")
        return end

    local p = {}
    p.bod = love.physics.newBody( world, x * 64, y * 64, "dynamic" ) -- creates a body for the player
    p.bod:setLinearDamping(16)
    p.bod:setAngularDamping(16)
	p.shape = love.physics.newRectangleShape(20, 20)
    p.fixture = love.physics.newFixture(p.bod, p.shape)
    p.fixture:setRestitution(.2)
    p.fixture:setUserData({"Player", id = id})

    --p.lightBody = Body:new(lightWorld)
    --p.lightBody:TrackPhysics(p.bod)

    p.health = maxHealth
    p.inventory = { defaultWeapon, "gun", "shotgun" }
    p.selectedSlot = 1
    p.cooldown = {
        attack = 0,
        sprint = 0,
        special = 0,
        dodge = 0
    }
    p.username = "Anonymous"
    p.respawning = false

    print("New player created")
    return setmetatable(p, player)
end

function player:setUsername(name) self.username = name end
function player:getUsername() return self.username end

-- health related functions
function player:getHealth() return self.health, maxHealth end
function player:setHealth(newHealth) self.health = newHealth end                        -- set a new health value of the player
function player:addHealth(healthPoints) self.health = self.health + healthPoints end    -- add health points to the player
function player:remHealth(healthPoints) self.health = self.health - healthPoints end    -- remove health points from the player

function player:getWeapon() return weapons[self.inventory[self.selectedSlot]] end
function player:setSlot(slot) self.selectedSlot = slot end