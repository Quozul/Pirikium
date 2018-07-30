gamestate = require "modules/hump.gamestate"
camera = require "modules/hump.camera"
timer = require "modules/hump.timer"
bitser = require "modules/bitser"
uuid = require "modules/uuid"
json = require "modules/json"
ser = require "modules/ser"

sti = require "modules/sti"
grid = require "modules/jumper.grid"
pathfinder = require "modules/jumper.pathfinder"

Shadows = require("shadows")
LightWorld = require("shadows.LightWorld")
Light = require("shadows.Light")
Body = require("shadows.Body")
print("Loaded modules")

require "clib/buttons"
require "clib/utility"
require "clib/players"
world_utility = require "clib/world"
particles = require "clib/particles"
items = require "items"
menu = require "menu"
game = require "game"
require "attack"
ai = require "ai"

math.randomseed(os.time())

local configFile = "config.json"
if not love.filesystem.getInfo( configFile ) then
    config = {
        shader = true,
        controls = {
            forward = "w",
            left = "a",
            backward = "s",
            right = "d",
            fire = "1",
            dodge = "space",
            use = "e",
            sprint = "lshift",
            drop = "r"
        },
        ai = {
            disable = false,
            debug = false
        },
        debug = true
    }
    love.filesystem.write(configFile, json:encode_pretty( config )) -- create a config file
    print("Config file not found, creating it")
else
    config = json:decode( love.filesystem.read( configFile ) ) -- loads the existing config file
    print("Config file loaded")
end

function love.load()
    menuFont = love.graphics.newFont(24)
    hudFont = love.graphics.newFont(12)
    print("Loaded font")

    gamestate.registerEvents()
    gamestate.switch(menu.main)
end

function love.quit()
    love.filesystem.write(configFile, json:encode_pretty( config ))
end

function love.update(dt)
    -- do stuff here
end