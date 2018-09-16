loadTime = 0
default = love.graphics.getFont()

loading = require "loading_screen"

window_width, window_height = love.window.getMode()

math.randomseed(os.time())

love.graphics.clear()
love.graphics.setBackgroundColor(29 / 255, 29 / 255, 29 / 255)

loading.setText("Loading modules...")
loading.draw()
love.graphics.present()

require "errorhandler"

require "clib/utility"
console_channel = love.thread.newChannel()
love.graphics.setFont(default)
console = require "console"

pathfinder = require "modules/jumper.pathfinder"
gamestate = require "modules/hump.gamestate"
loader = require "modules/love-loader"
camera = require "modules/hump.camera"
timer = require "modules/hump.timer"
grid = require "modules/jumper.grid"
bitser = require "modules/bitser"
gspot = require "modules/gspot"
uuid = require "modules/uuid"
json = require "modules/json"
sock = require "modules/sock"
ser = require "modules/ser"
sti = require "modules/sti"
--namegen = require "namegen.namegen"

Shadows = require("shadows")
LightWorld = require("shadows.LightWorld")
Light = require("shadows.Light")
Body = require("shadows.Body")
console.print("Loaded modules")

require "clib/buttons"
require "players"
require "clib/animation"
particles = require "clib/particles"
items = require "items"
require "menu"
require "game"
require "multiplayer"
require "entities"
require "hud"
require "attack"
tree = require "skills"
ai = require "ai"
lang = require "clib/lang"
require "clib/transition"
require "deathscreen"

update_checking_thread = love.thread.newThread( love.filesystem.read("update_check.lua") )
update_channel = love.thread.newChannel()

server = love.thread.newThread(love.filesystem.read("server.lua"))
server_channel = love.thread.newChannel()

lang.decrypt("data/langs/en.lang")

images = {}
images.weapons = {}
images.weapons.side = {}
images.weapons.hold = {}

-- create config
local configFile = "config.json"
local default_config = {
    shader = true, -- enable shader
    controls = {
        forward = "w",
        left = "a",
        backward = "s",
        right = "d",
        fire = "1",
        dash = "space",
        use = "e",
        sprint = "lshift",
        drop = "r",
        skill_tree = "c",
        sneak = "lctrl",
        burst = "q",
    },
    ai = {
        disable = false, -- disable the ai's brain
        debug = false, -- display ai path and more
    },
    debug = false, -- display extra informations to screen
    lang = "en", -- selected language of the game
    warmup = 10, -- time before enemies spawns
    ratio = 1, -- zomm in-game
    music = true, -- play background music in main-menu
    dev = false, -- check for developement versions
    fullscreen = false, -- toggle fullscreen mode
    content = {
        Pirikium = "folder", -- load the default content
    },
    particles = true, -- toggle particles
    multiplayer = {
        adress = "localhost:22122",
    },
}

function createConfig()
    config = default_config

    love.filesystem.write(configFile, json:encode_pretty( config )) -- create a config file
end

if not love.filesystem.getInfo( configFile ) then
    createConfig()
    console.print("Config file not found, creating it")
else
    config = json:decode( love.filesystem.read( configFile ) ) -- loads the existing config file
    local integrity = verifyTable(default_config, config)
    if not integrity then
        console.print("Recreating config file")
        createConfig()
    end
    console.print("Config file loaded")
end

loading.setText("Loading content...")
loading.draw()
love.graphics.present()

weapons, loots, classes = {}, {}, {}
skills = json:decode( love.filesystem.read( "data/skills.json" ) ) -- skills can't be customized by players

for name, type in pairs(config.content) do
    console.print("Loading " .. name .. " content pack...")

    if type == "folder" then
        local file = "content/" .. name .. "/loots.json"
        if love.filesystem.getInfo(file) then
            loots, overwritten = mergeTables(
                loots,
                json:decode( love.filesystem.read(file) )
            )
            console.print(("Overwritten %d loots"):format(overwritten))
        end

        local file = "content/" .. name .. "/classes.json"
        if love.filesystem.getInfo(file) then
            classes, overwritten = mergeTables(
                classes,
                json:decode( love.filesystem.read(file) )
            )
            console.print(("Overwritten %d classes"):format(overwritten))
        end

        local file = "content/" .. name .. "/weapons.json"
        if love.filesystem.getInfo(file) then
            weapons, overwritten = mergeTables(
                weapons,
                json:decode( love.filesystem.read(file) )
            )
            console.print(("Overwritten %d weapons"):format(overwritten))
        end
    end
end

console.print(#weapons .. " weapons loaded")
for name, wep in pairs(weapons) do
    if wep.texture ~= nil then
        console.print("Loaded image for weapon " .. name)
        if wep.texture.side ~= nil then
            loader.newImage(images.weapons.side, name, wep.texture.side)
        end
        if wep.texture.hold ~= nil then
            loader.newImage(images.weapons.hold, name, wep.texture.hold)
        end
    end
end

-- create folder for player saves if not existing
local save_folder = love.filesystem.getInfo("saves")
if not save_folder or save_folder.type ~= "directory" then
    love.filesystem.createDirectory("saves")
    console.print("Save directory created")
end

function updateScreenSize() -- the screen size scaling must be reworked
    love.window.setMode(1280*config.ratio, 720*config.ratio)
    window_width, window_height = 1280*config.ratio, 720*config.ratio
end
if config.ratio ~= 1 then updateScreenSize() end

-- load language
languages_list = love.filesystem.getDirectoryItems( "data/langs" )
console.print(#languages_list .. " available")

local selectedLanguage = string.gsub(config.lang, ".lang", "")
lang.decrypt( ("data/langs/%s.lang"):format(selectedLanguage) )

function love.load()
    finishedLoading = false

    local logical_processors = love.system.getProcessorCount()
    if logical_processors < 2 then love.window.showMessageBox("Processors count too low", "You don't have enough logical processors in your computer, the game may struggle sometimes.", "warning") end

    hudFont = love.graphics.newFont("data/fonts/Iceland.ttf", 16)
    menuFont = love.graphics.newFont("data/fonts/Iceland.ttf", 32)
    titleFont = love.graphics.newFont("data/fonts/Iceland.ttf", 48)
    consoleFont = love.graphics.newFont("data/fonts/Cutive.ttf", 16)
    console.print("Loaded fonts")

    --love.graphics.setDefaultFilter("nearest", "nearest")

    images.orbs = {}
    images.player = {}
    sounds = {}

    -- cursors
    crosshair = love.mouse.newCursor( love.image.newImageData("data/ui/cursor.png"), 16, 16 )
    dot_crosshair = love.mouse.newCursor( love.image.newImageData("data/ui/cursor_small.png"), 16, 16 )
    arrow = love.mouse.newCursor( love.image.newImageData("data/console/arrow.png"), 0, 0 )
    love.mouse.setCursor(arrow)

    loader.newImage(images, "skull", "data/ui/death_icon.png")
    loader.newImage(images, "level", "data/ui/level_icon.png")
    loader.newImage(images, "exit", "data/ui/exit_icon.png")
    loader.newImage(images, "volume", "data/ui/volume.png")
    loader.newImage(images, "music", "data/ui/music.png")

    loader.newImage(images, "crate", "data/crate.png")
    loader.newImage(images.orbs, "health", "data/orbs/health.png")
    loader.newImage(images.orbs, "skill", "data/orbs/skill.png")
    loader.newImage(images.orbs, "exp", "data/exp_orb.png")
    loader.newImage(images.player, "stand", "data/player/bald/stand.png")
    loader.newImage(images.player, "walk", "data/player/bald/walking.png")

    -- game sounds
    loader.newSource( sounds, "explosion", "data/sounds/qubodup_explosion.mp3", "static")
    loader.newSource( sounds, "flame", "data/sounds/fire.mp3", "static")
    loader.newSource( sounds, "hit", "data/sounds/hit_ennemy.mp3", "static")
    loader.newSource( sounds, "exp", "data/sounds/pickup_exp.mp3", "static")
    loader.newSource( sounds, "pickup", "data/sounds/pickup.mp3", "static")
    loader.newSource( sounds, "fire", "data/sounds/bird-man_gun_shot.mp3", "static")
    loader.newSource( sounds, "missed", "data/sounds/empty_hit.mp3", "static")
    loader.newSource( sounds, "door", "data/sounds/door_kick.mp3", "static")
    loader.newSource( sounds, "crate", "data/sounds/srehpog_crate_smash_2.mp3", "static")
    loader.newSource( sounds, "orb", "data/sounds/conarb13_pop.mp3", "static")
    -- melee weapons
    loader.newSource( sounds, "sword_swing", "data/sounds/xxchr0nosxx_sword_swing.mp3", "static")
    loader.newSource( sounds, "sword_hit", "data/sounds/black-snow_sword_slice.mp3", "static")
    
    -- gui sounds
    loader.newSource( sounds, "hover", "data/sounds/nenadsimic_menu_selection.mp3", "static")
    loader.newSource( sounds, "click", "data/sounds/radiy_click.mp3", "static")
    loader.newSource( sounds, "whoosh", "data/sounds/radiy_whooshtohit.mp3", "static")

    loader.newSource( sounds, "menu_theme", "data/sounds/menu_music.mp3", "stream")

    loader.start(function() -- this function is executed when the loading is done
        finishedLoading = true
        crate_animation = newAnimation(images.crate, 48, 48, 0.8) -- crate animation
        player_animation = newAnimation(images.player.walk, 24, 24, 0.5) -- walking player animation
        music_on = love.graphics.newQuad( 0, 0, 24, 24, images.music:getDimensions() )
        music_off = love.graphics.newQuad( 24, 0, 24, 24, images.music:getDimensions() )

        sounds.flame:setLooping(true)

        SetSounds(sounds.hover, sounds.click) -- set the sounds for the buttons

        console.print("Game loaded in " .. round(loadTime, 1) .. " seconds")
        love.window.requestAttention()

        gamestate.registerEvents()
        gamestate.switch(menu)
    end)

    if config.fullscreen then 
        love.window.setFullscreen(config.fullscreen)
        window_width, window_height = love.window.getMode()
    end
end

function love.quit()
    love.filesystem.write(configFile, json:encode_pretty( config ))
end

function love.update(dt)
    if not finishedLoading then
        loadTime = loadTime + dt
        loader.update()
        loading.update(dt)
    end

    console.update(dt)
end

function love.textinput(text)
    console.text(text)
end

function love.keypressed(key)
    console.keypressed(key)
end

function love.wheelmoved(x, y)
    console.mousewheel(x, y)
end

function love.mousemoved(x, y, dx, dy)
    console.mousemoved(x, y, dx, dy)
end

function love.mousepressed(x, y, button)
    console.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    console.mousereleased()
end

function love.resize(w, h)
    window_width, window_height = w, h
    console.resize(w, h)
end

function love.draw()
    if not finishedLoading then
        loading.draw()
        local percent = 0
        if loader.resourceCount ~= 0 then
            percent = loader.loadedCount / loader.resourceCount
            loading.setText(lang.print("loading") .. " " .. round(percent * 100, 0) .. "%")
        end
    end
end
