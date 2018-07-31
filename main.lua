gamestate = require "modules/hump.gamestate"
camera = require "modules/hump.camera"
timer = require "modules/hump.timer"
bitser = require "modules/bitser"
gspot = require "modules/gspot"
uuid = require "modules/uuid"
json = require "modules/json"
ser = require "modules/ser"
--require "modules/simple-slider"

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
function createConfig()
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
            debug = false,
            limit = 2
        },
        debug = true
    }
    love.filesystem.write(configFile, json:encode_pretty( config )) -- create a config file
    print("Config file not found, creating it")
end

if not love.filesystem.getInfo( configFile ) then
    createConfig()
else
    config = json:decode( love.filesystem.read( configFile ) ) -- loads the existing config file
    print("Config file loaded")
end

print(rf(0, 1, 4), rf2(0, 1, 4))

function love.load()
    menuFont = love.graphics.newFont(24)
    hudFont = love.graphics.newFont(12)
    print("Loaded font")

    gamestate.registerEvents()
    gamestate.switch(menu)
end

function love.quit()
    love.filesystem.write(configFile, json:encode_pretty( config ))
end

function love.update(dt)
    -- do stuff here
end