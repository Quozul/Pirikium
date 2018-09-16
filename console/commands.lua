--[[ You can add a memory to your commands by adding a "memory" variable,
    the value of this variable will be used when creating the memory.

    When the command is executed, "command", "args", "originalcommand" and "memory" are parsed.

    You can add a function for the command that will be executed in love.update with "dt" and "memory" are parsed.
]]

return {
    lua = {
        requiredarguments = 0, -- no arguments are required
        execution = function(command)
            loadstring(command)()
        end,
        usage = "lua [lua script]",
        description = "Execute a lua script"
    },

    print = {
        requiredarguments = 0, -- increasing this number let the console verify for arguments so they are required
        execution = function(command)
            local value = loadstring("return " .. command)()
            console.print( value )
        end,
        usage = "print [value|\"string\"]",
        description = "Prints a value from the game or a string"
    },

    loop = {
        arguments = 3,
        requiredarguments = 1,
        memory = true,
        execution = function(command, args, originalcommand, memory) -- "originalcommand" can be usefull in this case
            if command:match("loop") then -- loop add test 1 loop
                console.print("Error: You can't repeat this command", 2) -- prevent some cheat
                return false
            end

            local action = args[1]
            local name = args[2]
            local time = tonumber(args[3])

            if action == "add" then -- loop add test 1 print("Hello world!")
                if not name or not time or not command then
                    return true
                end
                console.print("Repeating command " .. name .. " every " .. time .. " seconds")

                console.addtomemory("loop", name, {
                    every = time,
                    time = 0,
                    command = loadstring(command),
                })
            elseif action == "rem" then -- loop rem test
                if args[2] == nil or args[2] == "" then
                    return true
                elseif not memory[args[2]] then
                    console.print("The command " .. args[2] .. " doesn't exists", 2)
                else
                    console.print("Command " .. args[2] .. " removed")
                    console.remfrommemory("loop", name)
                end
            elseif action == "list" then
                local list = ""
                for name in pairs(memory) do
                    list = list .. name .. " "
                end
                
                if list ~= "" then
                    console.print("Repeated commands: " .. list)
                else
                    console.print("There are no commands being repeated")
                end
            else
                return true
            end
        end,
        usage = "loop [add|rem|list] [name] [time] [lua script]",
        description = "Repeat a command every amount of time",
        update = function(dt, memory)
            for name, cmd in pairs(memory) do
                if cmd == nil then return end
                cmd.time = cmd.time + dt
                if cmd.time >= cmd.every then
                    cmd.command()
                    cmd.time = 0
                end
            end
        end,
    },

    give = {
        requiredarguments = 0,
        execution = function(command)
            if weapons[command] then
                ply:addItem(command)
            else
                console.print("Item " .. command .. " doesn't exists", 2)
            end
        end,
        usage = "give [item name]",
        description = "Give the specified item to the player"
    },
}