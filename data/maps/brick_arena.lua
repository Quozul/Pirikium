return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "1.1.5",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 25,
  height = 25,
  tilewidth = 64,
  tileheight = 64,
  nextobjectid = 1,
  properties = {},
  tilesets = {
    {
      name = "entities",
      firstgid = 1,
      filename = "../../../../tiled/entities.tsx",
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      image = "../mapres/entities.png",
      imagewidth = 256,
      imageheight = 256,
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 64,
        height = 64
      },
      properties = {},
      terrains = {},
      tilecount = 16,
      tiles = {}
    },
    {
      name = "bricks",
      firstgid = 17,
      filename = "../../../../tiled/bricks.tsx",
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      image = "../mapres/bricks.png",
      imagewidth = 128,
      imageheight = 128,
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 64,
        height = 64
      },
      properties = {},
      terrains = {},
      tilecount = 4,
      tiles = {}
    },
    {
      name = "collision",
      firstgid = 21,
      filename = "../../../../tiled/collision.tsx",
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      image = "../mapres/collision.png",
      imagewidth = 128,
      imageheight = 64,
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 64,
        height = 64
      },
      properties = {},
      terrains = {},
      tilecount = 2,
      tiles = {
        {
          id = 1,
          properties = {
            ["collidable"] = true
          }
        }
      }
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "Bricks",
      x = 0,
      y = 0,
      width = 25,
      height = 25,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
        20, 20, 20, 20, 20, 18, 18, 18, 18, 20, 20, 20, 19, 19, 19, 20, 18, 18, 18, 18, 18, 18, 18, 20, 20,
        20, 20, 18, 18, 18, 18, 18, 18, 18, 20, 19, 19, 19, 19, 19, 20, 18, 18, 18, 18, 18, 18, 18, 20, 20,
        20, 18, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 20, 18, 18, 18, 18, 18, 18, 18, 18, 20,
        20, 18, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 18, 18, 18, 20,
        20, 18, 18, 18, 18, 18, 18, 18, 18, 20, 19, 19, 19, 19, 19, 20, 18, 18, 18, 18, 18, 18, 18, 18, 20,
        20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 19, 19, 19, 19, 19, 20, 18, 18, 18, 18, 18, 18, 18, 18, 20,
        20, 20, 20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 18, 18, 18, 18, 18, 18, 18, 18, 20,
        20, 20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 18, 18, 18, 18, 18, 18, 18, 18, 20,
        20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 18, 18, 18, 18, 18, 18, 18, 18, 18, 20,
        20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 18, 18, 18, 18, 18, 18, 18, 18, 20,
        20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 18, 18, 18, 18, 18, 20,
        20, 19, 19, 19, 19, 20, 20, 19, 20, 20, 20, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20,
        20, 19, 19, 19, 19, 20, 19, 19, 19, 19, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20,
        20, 19, 19, 19, 19, 20, 19, 19, 19, 19, 20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20,
        20, 19, 19, 19, 19, 20, 19, 19, 19, 19, 20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20,
        20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 20,
        20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 19, 19, 19, 19, 19, 19, 20,
        20, 19, 19, 19, 19, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 19, 19, 19, 19, 19, 19, 20,
        20, 19, 19, 19, 19, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 19, 19, 19, 19, 19, 19, 20,
        20, 19, 19, 19, 19, 20, 20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20,
        20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 19, 19, 19, 19, 19, 20, 20,
        20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 19, 19, 19, 19, 19, 20, 20,
        20, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20, 20, 19, 19, 19, 19, 20, 20, 20,
        20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20
      }
    },
    {
      type = "tilelayer",
      name = "Map Entities",
      x = 0,
      y = 0,
      width = 25,
      height = 25,
      visible = false,
      opacity = 0.25,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0,
        0, 0, 2, 2, 2, 0, 0, 0, 0, 2, 2, 2, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 0, 2, 0,
        0, 2, 0, 0, 0, 0, 0, 3, 0, 2, 0, 0, 0, 3, 0, 17, 0, 8, 0, 10, 0, 0, 0, 2, 1,
        2, 0, 0, 0, 0, 0, 0, 0, 0, 1610612743, 0, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        2, 0, 8, 0, 0, 0, 0, 0, 0, 2684354567, 0, 0, 0, 0, 0, 17, 2, 2, 2, 2, 2, 0, 0, 0, 2,
        2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 2, 0, 3, 0, 0, 0, 0, 0, 0, 2,
        0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        0, 0, 2, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 2684354567, 0, 0, 0, 0, 0, 9, 0, 0, 2,
        0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0, 2,
        2, 0, 3, 0, 0, 2, 2, 7, 2, 2, 2, 0, 0, 0, 0, 1, 1, 2, 2, 2, 2, 2, 2, 2, 1,
        2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 1,
        2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 2, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 2,
        2, 0, 0, 0, 0, 1610612743, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2,
        2, 0, 0, 0, 0, 2684354567, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 2,
        2, 0, 0, 0, 0, 2, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 2,
        2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 2, 0, 0, 0, 0, 0, 0, 2,
        2, 0, 3, 0, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1610612743, 0, 0, 0, 0, 0, 0, 2,
        2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 2, 0,
        0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 2, 0, 0, 3, 0, 0, 2, 0,
        0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 2, 0, 0,
        0, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 2, 2, 2, 2, 1, 0, 0
      }
    },
    {
      type = "tilelayer",
      name = "Collisions",
      x = 0,
      y = 0,
      width = 25,
      height = 25,
      visible = false,
      opacity = 0.25,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "lua",
      data = {
        2, 2, 2, 2, 2, 22, 22, 22, 22, 2, 2, 2, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 2, 2,
        2, 2, 22, 22, 22, 0, 0, 0, 0, 22, 22, 22, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 22, 2,
        2, 22, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 22, 2,
        22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 22, 22, 22, 22, 22, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        2, 22, 22, 22, 22, 22, 22, 22, 22, 22, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        2, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        2, 21, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        2, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        21, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 22, 22, 22, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 22, 22, 0, 22, 22, 22, 0, 0, 0, 0, 0, 0, 22, 22, 22, 22, 22, 22, 22, 21,
        22, 0, 0, 0, 0, 22, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 22, 22, 21,
        22, 0, 0, 0, 0, 22, 0, 0, 0, 0, 22, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 22, 0, 0, 0, 0, 22, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 22, 22, 22, 22, 22, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 22, 22, 22, 22, 22, 0, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 22, 22, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22,
        22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 22, 21,
        21, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 22, 2,
        2, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 22, 22, 22, 0, 0, 0, 0, 22, 2, 2,
        2, 21, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 2, 2, 2, 2, 22, 22, 22, 22, 2, 2, 2
      }
    }
  }
}
