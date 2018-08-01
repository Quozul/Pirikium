require "clib/rwrc"

local button = {}
button.__index = button
local sould_occur = true

function NewButton(type, x, y, w, h, clic, t, value) -- t should be {text, color r, color g, color b, font} -- clic is a function -- value is for checkboxes
    -- type can be "checkbox" or "button"
    local b = {}
    b.type = type
    b.value = value
    if type == "checkbox" then b.checked = value end
    b.x, b.y = x, y
    b.w, b.h = w, h
    b.text, b.r, b.g, b.b, b.font = unpack(t)
    b.clic = clic

    return setmetatable(b, button)
end

function button:draw() -- also act as update
    if self.type == "button" then
        love.graphics.setFont(self.font)

        if between(love.mouse.getX(), self.x, self.x + self.w) and between(love.mouse.getY(), self.y, self.y + self.h) then
            love.graphics.setColor(self.r - .25, self.g - .25, self.b - .25)
        else
            love.graphics.setColor(self.r, self.g, self.b)
        end
        rwrc(self.x, self.y, self.w, self.h, 2)

        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.text, self.x + self.w / 2 - self.font:getWidth(self.text) / 2,  self.y + self.h / 2 - self.font:getHeight(self.text) / 2)
    elseif self.type == "checkbox" then
        love.graphics.setFont(self.font)

        love.graphics.setColor(1, 1, 1)
        if not self.checked then
            love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
        elseif self.checked then
            love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(self.text, self.x + self.w + 10, self.y)
    end
end

function button:mouse()
    if self.type == "button" then
        if between(love.mouse.getX(), self.x, self.x + self.w) and between(love.mouse.getY(), self.y, self.y + self.h) then
            if love.mouse.isDown(1) then
                self.clic()
            end
        end
    elseif self.type == "checkbox" then
        if between(love.mouse.getX(), self.x, self.x + self.w) and between(love.mouse.getY(), self.y, self.y + self.h) then
            if love.mouse.isDown(1) then
                self.checked = not self.checked
                self.clic()
            end
        end
    end
end

function button:getPos()
    return self.x, self.y
end