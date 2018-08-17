# Pirikium
**Pirikium** is a top-down adventure game, written in lua with the [Löve 2D](https://love2d.org/) (version 11.1) game engine. The game is currently in early stages.  

<div align="center">
    <a href="https://discord.gg/UZy8rCY"><img src="https://discordapp.com/api/guilds/472820911955902465/embed.png" alt="Discord server" title="Join our Discord server now!"/></a></br>
    E-mail me at <a href="mailto:quozul@outlook.com" alt="quozul@outlook.com" title="Send me an e-mail">quozul@outlook.com</a>
</div>

### Default controls
Some controls can be changed in the config file.
* **WASD** to move
* **Left-shift** to sprint
* **Left-control** to sneak
* **Left mouse** to shoot
* **Right mouse** for special attack (no special attacks added yet)
* **Space** to dash
* **Mouse wheel** to change weapon
* **E** to use/interact
* **R** drop weapon
* **C** to open skill menu
* **F3** toggle debug mode

## Run & compiling
You don't have to compile the game in order to play it.
* Download the game as zip
* Download [Löve 2D](https://love2d.org/) for your OS
* Extract them and drag the folder onto Löve's executable *love.exe*.  
For more informations about *compiling it* refer on the [Löve's wiki](https://love2d.org/wiki/Game_Distribution) or the [forum](https://love2d.org/forums/viewtopic.php?f=4&t=451).

---

## Team
* **Quôzul** <span title="Developer">:computer:</span>
* **Katrtlen** <span title="Artist">:pencil2:</span>

### Credits
* Some of the sounds used are from [Freesound.org](https://freesound.org/)
* [Iceland Font](https://fonts.google.com/specimen/Iceland) is from Google Fonts

---

### Modules
Here's a list of all used libraries (some of them may not be used, but they're in the game's code):

Use | Modules
---|---
JSON encoder/decoder | [JSON](http://regex.info/blog/lua/json)
Camara & more | [hump](https://github.com/vrld/hump/)
Serialisation | [Ser](https://github.com/gvx/Ser) & [Bitser](https://github.com/gvx/bitser)
GUI | [Gspöt](https://github.com/pgimeno/Gspot)
Physics | [Box2D](https://love2d.org/wiki/love.physics) (*included in Löve2D*)
Unique IDs generator | [UUID](https://github.com/Tieske/uuid)
Lighting & shadows | [Shädows](https://github.com/matiasah/shadows)
World generation | [Astray](https://github.com/SiENcE/astray) (not used yet)
STI | [STI](https://github.com/karai17/Simple-Tiled-Implementation)
Pathfinding | [Jumper](https://github.com/Yonaba/Jumper)
Random names | [lua-namegen](https://github.com/LukeMS/lua-namegen)
Threaded ressource loading | [love-loader](https://github.com/kikito/love-loader)