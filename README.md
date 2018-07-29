# Pirikium
**Pirikium** top-down adventure game, written in lua with the Löve 2D game engine. The game is currently in early stages.

## Compiling
You don't have to compile the game in order to play it, just download the game as zip, extract it and drag the folder onto Löve's executable *love.exe*.  
For more informations about *compiling it* refer on the [Löve's wiki](https://love2d.org/wiki/Game_Distribution).

### Modules
Here's a list of all used libraries (some of them may not be used, but they're in the game's code):

Use | Modules
---|---
JSON encoder/decoder | [JSON](http://regex.info/blog/lua/json)
Camara & more | [hump](https://github.com/vrld/hump/)
Serialisation | [Ser](https://github.com/gvx/Ser) (may be removed) & [Bitser](https://github.com/gvx/bitser)
GUI | [Gspöt](https://github.com/pgimeno/Gspot) (not used & may be removed)
Physics | [Box2D](https://love2d.org/wiki/love.physics) (*included in Löve2D*)
Unique IDs generator | [UUID](https://github.com/Tieske/uuid)
Lighting & shadows | [Shädows](https://github.com/matiasah/shadows)
World generation | [Astray](https://github.com/SiENcE/astray) (not used yet)
STI | [STI](https://github.com/karai17/Simple-Tiled-Implementation)
Pathfinding | [Jumper](https://github.com/Yonaba/Jumper)