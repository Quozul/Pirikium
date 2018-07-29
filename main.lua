gamestate = require "hump.gamestate"
camera = require "hump.camera"
timer = require "hump.timer"
bitser = require "modules/bitser"
uuid = require "modules/uuid"
json = require "modules/json"
ser = require "modules/ser"

sti = require "sti"
grid = require "jumper.grid"
pathfinder = require "jumper.pathfinder"

Shadows = require("shadows")
LightWorld = require("shadows.LightWorld")
Light = require("shadows.Light")
Body = require("shadows.Body")
print("Loaded modules")

require "clib/buttons"
require "clib/utility"
require "clib/players"
world_utility = require "clib/world"
menu = require "menu"
game = require "game"
require "attack"
ai = require "ai"

math.randomseed(os.time())

function love.load()
    menuFont = love.graphics.newFont("data/quicksand.ttf", 24)
    hudFont = love.graphics.newFont("data/quicksand.ttf", 12)
    print("Loaded font")

    gamestate.registerEvents()
    gamestate.switch(menu.main)
end

function love.update(dt)
    -- do stuff here
end