require "clib/utility"
local console = require "console.thread"

require "love"
require "love.physics"
require "love.system"
require "love.thread"
require "love.timer"
console.print("Love loaded")

sock = require "modules/sock"
bitser = require "modules/bitser"
console.print("Modules loaded") 

ip, port = ...
server = sock.newServer("*", port)
server:setSerialization(bitser.dumps, bitser.loads)
console.print(("Server openned on port %d"):format(port))

server:on("connect", function(data, client)
    console.print("New client connected!")
end)

local current_time = love.timer.getTime()
local previous_time = love.timer.getTime()

tickRate = 1/60
tick = 0

while true do
    -- DON'T EDIT THE FOLLOWING LINES
    current_time = love.timer.getTime()
    dt = current_time - previous_time
    previous_time = current_time
    -- DON'T EDIT THE ABOVE LINES

    server:update()

    tick = tick + dt

    if tick >= tickRate then
        tick = 0
    end

    local cmd = love.thread.getChannel("server_channel"):pop()
    if cmd == "stop" then
        break
    end
end

server = nil
console.print("Server stopped!")