loadTime = 0

loading = require "loading_screen"

window_width, window_height = love.window.getMode()

love.graphics.clear()
love.graphics.setBackgroundColor(29 / 255, 29 / 255, 29 / 255)

loading.setText("Loading modules...")
loading.draw()
love.graphics.present()

icon = love.image.newImageData("data/icon.png")
love.window.setIcon(icon)

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
lang = require "clib/lang"
require "clib/transition"
require "deathscreen"

lang.decrypt("data/langs/en.lang")

images = {}
images.weapons = {}
images.weapons.side = {}
images.weapons.hold = {}

weapons = json:decode( love.filesystem.read( "data/weapons.json" ) ) -- load game content
print(#weapons .. " weapons loaded")
for name, wep in pairs(weapons) do
    if wep.texture ~= nil then
        print("Loaded image for weapon " .. name)
        if wep.texture.side ~= nil then
            loader.newImage(images.weapons.side, name, wep.texture.side)
        end
        if wep.texture.hold ~= nil then
            loader.newImage(images.weapons.hold, name, wep.texture.hold)
        end
    end
end

loots = json:decode( love.filesystem.read( "data/loots.json" ) )
skills = json:decode( love.filesystem.read( "data/skills.json" ) )
classes = json:decode( love.filesystem.read( "data/classes.json" ) )

math.randomseed( os.time() )

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
            drop = "r",
            skill_tree = "c",
            sneak = "lctrl"
        },
        ai = {
            disable = false,
            debug = false,
            limit = 2
        },
        debug = false,
        lang = "en",
        warmup = 10,
        ratio = 1,
        play_music = true
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

if config.lang == nil then createConfig() end

function updateScreenSize()
    love.window.setMode(1280*config.ratio, 720*config.ratio)
    window_width, window_height = 1280*config.ratio, 720*config.ratio
end
if config.ratio ~= 1 then updateScreenSize() end

languages_list = love.filesystem.load( "data/languages_list.lua" )()
print(#languages_list .. " available")

lang.decrypt(("data/langs/%s.lang"):format(config.lang))

function love.load()
    finishedLoading = false

    hudFont = love.graphics.newFont("data/font/Iceland.ttf", 16)
    menuFont = love.graphics.newFont("data/font/Iceland.ttf", 32)
    titleFont = love.graphics.newFont("data/font/Iceland.ttf", 48)
    print("Loaded font")

    love.graphics.setDefaultFilter("nearest", "nearest")

    images.orbs = {}
    images.player = {}
    sounds = {}

    loader.newImage(images, "cursor", "data/ui/cursor.png")
    loader.newImage(images, "dot", "data/ui/cursor_small.png")
    loader.newImage(images, "slot", "data/ui/inv_slot.png")
    loader.newImage(images, "bar", "data/ui/bar.png")
    loader.newImage(images, "skull", "data/ui/death_icon.png")
    loader.newImage(images, "level", "data/ui/level_icon.png")
    loader.newImage(images, "exit", "data/ui/exit_icon.png")

    loader.newImage(images, "crate", "data/crate.png")
    loader.newImage(images.orbs, "health", "data/orbs/health.png")
    loader.newImage(images.orbs, "skill", "data/orbs/skill.png")
    loader.newImage(images.player, "stand", "data/player/bald/stand.png")
    loader.newImage(images.player, "walk", "data/player/bald/walking.png")
    loader.newImage(images, "exp_orb", "data/exp_orb.png")

    -- game sounds
    loader.newSource( sounds, "explosion", "data/sounds/explosion.mp3", "static")
    loader.newSource( sounds, "hit", "data/sounds/hit_ennemy.mp3", "static")
    loader.newSource( sounds, "exp", "data/sounds/pickup_exp.mp3", "static")
    loader.newSource( sounds, "pickup", "data/sounds/pickup.mp3", "static")
    loader.newSource( sounds, "fire", "data/sounds/shoot.mp3", "static")
    loader.newSource( sounds, "missed", "data/sounds/empty_hit.mp3", "static")
    loader.newSource( sounds, "door", "data/sounds/door_kick.mp3", "static")
    loader.newSource( sounds, "crate", "data/sounds/srehpog_crate_smash_2.mp3", "static")
    loader.newSource( sounds, "orb", "data/sounds/conarb13_pop.mp3", "static")
    
    -- gui sounds
    loader.newSource( sounds, "hover", "data/sounds/nenadsimic_menu_selection.mp3", "static")
    loader.newSource( sounds, "click", "data/sounds/radiy_click.mp3", "static")
    loader.newSource( sounds, "whoosh", "data/sounds/radiy_whooshtohit.mp3", "static")

    loader.newSource( sounds, "menu_theme", "data/sounds/menu_music.mp3", "stream")

    loader.start(function()
        finishedLoading = true
        crate_animation = newAnimation(images.crate, 48, 48, 0.8) -- crate animation
        player_animation = newAnimation(images.player.walk, 24, 24, 0.5) -- walking player animation
        print("Game loaded in " .. round(loadTime, 1) .. " seconds")

        SetSounds(sounds.hover, sounds.click) -- set the sounds for the buttons

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
        loadTime = loadTime + dt
        loader.update()
    end
end

function love.resize(w, h)
    window_width, window_height = w, h
end

function love.draw()
    if not finishedLoading then
        loading.draw()
        local percent = 0
        if loader.resourceCount ~= 0 then
            percent = loader.loadedCount / loader.resourceCount
            loading.setText("Loading .. " .. round(percent * 100, 0) .. "%")
        end
    end
end
