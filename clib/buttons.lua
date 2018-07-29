require "clib/rwrc"

local button = {}
button.__index = button
local sould_occur = true

function NewButton(type, x, y, w, h, clic, t) -- t should be {text, color r, color g, color b, font} -- clic is a function
    -- type can be "checkbox" or "button"
    local b = {}
    b.type = type
    if type == "checkbox" then b.checked = false end
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
            love.graphics.setColor((self.r - 50) / 255, (self.g - 50) / 255, (self.b - 50) / 255)
        else
            love.graphics.setColor(self.r / 255, self.g / 255, self.b / 255)
        end
        rwrc(self.x, self.y, self.w, self.h, 2)

        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.text, self.x + self.w / 2 - self.font:getWidth(self.text) / 2,  self.y + self.h / 2 - self.font:getHeight(self.text) / 2)
    elseif self.type == "checkbox" then
        love.graphics.setColor(1, 1, 1)
        if not self.checked then
            love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
        elseif self.checked then
            love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
        end
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
            end
        end
    end
end