love.graphics.clear()
menuFont = love.graphics.newFont(24)
window_width, window_height = love.window.getMode()
love.graphics.setFont(menuFont)
love.graphics.print("Loading...", (window_width - menuFont:getWidth("Loading...")) / 2, (window_height - menuFont:getHeight("Loading...")) / 2)
love.graphics.present()

gamestate = require "modules/hump.gamestate"
camera = require "modules/hump.camera"
timer = require "modules/hump.timer"
bitser = require "modules/bitser"
gspot = require "modules/gspot"
uuid = require "modules/uuid"
json = require "modules/json"
ser = require "modules/ser"
namegen = require "modules/namegen.namegen"

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

images = {}

weapons = json:decode( love.filesystem.read( "data/weapons.json" ) ) -- load game content
print(#weapons .. " weapons loaded")
for name, wep in pairs(weapons) do
    if wep.texture ~= nil then
        print("Loaded image for weapon " .. name)
        images[name] = love.graphics.newImage(wep.texture)
    end
end

loots = json:decode( love.filesystem.read( "data/loots.json" ) )

math.randomseed(os.time())

local configFile = "config.json"
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
        drop = "r",
        skill_tree = "c"
    },
    ai = {
        disable = false,
        debug = false,
        limit = 2
    },
    debug = false
}
function createConfig()
    love.filesystem.write(configFile, json:encode_pretty( config )) -- create a config file
    print("Config file not found, creating it")
end

if not love.filesystem.getInfo( configFile ) then
    createConfig()
else
    config = json:decode( love.filesystem.read( configFile ) ) -- loads the existing config file
    print("Config file loaded")
end

function love.load()
    hudFont = love.graphics.newFont(12)
    print("Loaded font")

    love.graphics.setDefaultFilter("nearest", "nearest")

    cursor = love.graphics.newImage("data/cursor.png")
    dot = love.graphics.newImage("data/cursor_small.png")
    slot = love.graphics.newImage("data/inv_slot.png")
    bar = love.graphics.newImage("data/bar.png")

    sounds = {}
    sounds.explosion = love.audio.newSource("data/sounds/explosion.mp3", "stream")
    sounds.hit = love.audio.newSource("data/sounds/hit_ennemy.mp3", "stream")
    sounds.melody = love.audio.newSource("data/sounds/melody.mp3", "stream")
    sounds.exp = love.audio.newSource("data/sounds/pickup_exp.mp3", "stream")
    sounds.pickup = love.audio.newSource("data/sounds/pickup.mp3", "stream")
    sounds.fire = love.audio.newSource("data/sounds/shoot.mp3", "stream")
    sounds.missed = love.audio.newSource("data/sounds/empty_hit.mp3", "stream")
    sounds.door = love.audio.newSource("data/sounds/door_kick.mp3", "stream")
    print("Loaded sounds")

    gamestate.registerEvents()
    gamestate.switch(menu)
end

function love.quit()
    love.filesystem.write(configFile, json:encode_pretty( config ))
end

function love.update(dt)
    -- do stuff here
end