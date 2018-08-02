loading = require "loading_screen"

love.graphics.clear()
love.graphics.setBackgroundColor(29 / 255, 29 / 255, 29 / 255)

loading.setText("Loading modules...")
loading.draw()
love.graphics.present()

window_width, window_height = love.window.getMode()

gamestate = require "modules/hump.gamestate"
loader = require "modules/love-loader"
camera = require "modules/hump.camera"
timer = require "modules/hump.timer"
bitser = require "modules/bitser"
gspot = require "modules/gspot"
uuid = require "modules/uuid"
json = require "modules/json"
ser = require "modules/ser"
namegen = require "namegen.namegen"

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
require "clib/animation"
world_utility = require "clib/world"
particles = require "clib/particles"
items = require "items"
menu = require "menu"
game = require "game"
require "attack"
tree = require "skills"
ai = require "ai"

images = {}
images.weapons = {}
images.weapons.side = {}

weapons = json:decode( love.filesystem.read( "data/weapons.json" ) ) -- load game content
print(#weapons .. " weapons loaded")
for name, wep in pairs(weapons) do
    if wep.textures ~= nil then
        print("Loaded image for weapon " .. name)
        if wep.textures.side ~= nil then
            loader.newImage(images.weapons.side, name, wep.textures.side)
        end
    end
end

loots = json:decode( love.filesystem.read( "data/loots.json" ) )
skills = json:decode( love.filesystem.read( "data/skills.json" ) )

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
    finishedLoading = false

    hudFont = love.graphics.newFont(12)
    menuFont = love.graphics.newFont(24)
    print("Loaded font")

    love.graphics.setDefaultFilter("nearest", "nearest")

    icon = love.image.newImageData("data/icon.png")
    love.window.setIcon(icon)

    images.orbs = {}
    sounds = {}

    loader.newImage(images, "cursor", "data/cursor.png")
    loader.newImage(images, "dot", "data/cursor_small.png")
    loader.newImage(images, "slot", "data/inv_slot.png")
    loader.newImage(images, "bar", "data/bar.png")
    loader.newImage(images, "crate", "data/crate.png")
    loader.newImage(images.orbs, "health", "data/orbs/health.png")
    loader.newImage(images.orbs, "skill", "data/orbs/skill.png")

    loader.newSource( sounds, "explosion", "data/sounds/explosion.mp3", "static")
    loader.newSource( sounds, "hit", "data/sounds/hit_ennemy.mp3", "static")
    loader.newSource( sounds, "exp", "data/sounds/pickup_exp.mp3", "static")
    loader.newSource( sounds, "pickup", "data/sounds/pickup.mp3", "static")
    loader.newSource( sounds, "fire", "data/sounds/shoot.mp3", "static")
    loader.newSource( sounds, "missed", "data/sounds/empty_hit.mp3", "static")
    loader.newSource( sounds, "door", "data/sounds/door_kick.mp3", "static")

    loader.newSource( sounds, "melody", "data/sounds/melody.mp3", "stream") -- stream is for musics/long files

    loader.start(function()
        finishedLoading = true
        crate_animation = newAnimation(images.crate, 48, 48, 0.8)

        gamestate.registerEvents()
        gamestate.switch(menu)
    end)
end

function love.quit()
    love.filesystem.write(configFile, json:encode_pretty( config ))
end

function love.update(dt)
    loading.update(dt)

    if not finishedLoading then
        loader.update()
    end
end

function love.draw()
    if not finishedLoading then
        loading.draw()
        local percent = 0
        if loader.resourceCount ~= 0 then
            percent = loader.loadedCount / loader.resourceCount
            loading.setText("Loading .. " .. round(percent * 100, 0) .. "%")
            print(("Loading .. %d%%"):format(percent*100))
        end
    end
end