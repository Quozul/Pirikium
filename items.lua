local I = {}
local items = {} -- all items will be stored in this table

local itemHitBox = 50
local pickupDist = 150

function I.drop(x, y, item)
    local i = {}

    i.item = item
    i.x = x
    i.y = y
    i.age = 5

    table.insert(items, i)
end

function I.interact(ent, x, y, px, py)
    for index, item in pairs(items) do
        print(x, y, item.x, item.y)
        local dist = sl(px, py, item.x, item.y)
        if inSquare(x, y, item.x, item.y, itemHitBox, itemHitBox) and dist <= pickupDist then
            local remove = ent:addItem(item.item)
            if remove then table.remove(items, index) end
        elseif dist > pickupDist then
            print("You're too far away")
        end
    end
end

function I.update(dt)
    for index, item in pairs(items) do
        item.age = math.max(item.age - dt, 0)

        if item.age == 0 then table.remove(items, index) end
    end
end

function I.draw()
    for index, item in pairs(items) do
        love.graphics.setColor(1, 1, 1, item.age) -- fade out the item for the last second
        if config.debug then love.graphics.rectangle("line", item.x, item.y, itemHitBox, itemHitBox) end -- debug, show hitbox
        love.graphics.print(item.item, item.x, item.y)
    end
end

function I.clear()
    for index, item in pairs(items) do
        table.remove(items, index)
        print("Cleared item " .. index)
    end
end

return I