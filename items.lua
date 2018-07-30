local I = {}
local items = {} -- all items will be stored in this table

local itemHitBox = 50
local pickupDist = 150

function I.drop(x, y, item)
    local i = {}
    i.item = item
    i.x = x
    i.y = y
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

    end
end

function I.draw()
    for index, item in pairs(items) do
        if config.debug then love.graphics.rectangle("line", item.x, item.y, itemHitBox, itemHitBox) end -- debug, show hitbox
        love.graphics.print(item.item, item.x, item.y)
    end
end

function I.clear()
    print("ok")
    for index, item in pairs(items) do
        table.remove(items, index)
        print("Cleared item " .. index)
    end
end

return I