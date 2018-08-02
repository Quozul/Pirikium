local I = {}
local items = {} -- all items will be stored in this table

local itemHitBox = 32
local pickupDist = 150
local dtCenter = itemHitBox / 2

function I.drop(x, y, angle, item)
    if table.find(loots.black_list, item) then return end

    local i = {}

    i.item = item
    i.x, i.y = x - dtCenter + math.cos(angle) * 10, y - dtCenter + math.sin(angle) * 10
    i.a = angle

    i.vx, i.vy = math.cos(angle) * 10, math.sin(angle) * 10
    i.age = 5

    table.insert(items, i)
end

function I.interact(ent, x, y, px, py)
    for index, item in pairs(items) do
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
        item.x = item.x + item.vx
        item.y = item.y + item.vy

        item.vx, item.vy = item.vx / 1.2, item.vy / 1.2

        if item.age == 0 then table.remove(items, index) end
    end
end

function I.draw()
    for index, item in pairs(items) do
        if inSquare(cmx, cmy, item.x, item.y, itemHitBox, itemHitBox) then
            dotCursor = true
        end

        love.graphics.setColor(1, 1, 1, item.age) -- fade out the item for the last second
        if images.weapons.side[item.item] then
            love.graphics.draw(images.weapons.side[item.item], item.x, item.y)
        else
            love.graphics.rectangle("fill", item.x, item.y, itemHitBox, itemHitBox)
            love.graphics.setColor(0, 0, 0, item.age)
            love.graphics.print(lang.print(item.item), item.x, item.y)
        end
        
        if config.debug then
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("line", item.x, item.y, itemHitBox, itemHitBox)
        end -- debug, show hitbox
    end
end

function I.clear()
    for index, item in pairs(items) do
        table.remove(items, index)
        print("Cleared item " .. index)
    end
end

return I