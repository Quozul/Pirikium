local button = {}
button.__index = button
local anim = .5

translation_x, translation_y = 0, 0

width, height = love.window.getMode()

function NewButton(type, x, y, w, h, click, text, color, style, value)
    if style == nil then style = {} end
    if value == nil then value = "" end

    local b = {}
    b.type = type
    b.x, b.y = x, y
    b.w, b.h = w, h
    b.click = click
    b.text = text
    if value == false then
        b.r, b.g, b.b = 66, 72, 75
    else
        b.r, b.g, b.b = unpack(color)
    end
    b.timeIn = 0
    b.style = style
    b.alpha = .5
    b.trans = NewTransition(0, 0, 0, style.easing)
    b.isDown = false
    b.border = 1
    b.value = value
    b.font = style.font or nil

    return setmetatable(b, button)
end

function SetSounds(hover, click)
    hover_sound = hover
    click_sound = click
end

function SetTranslation(x, y)
    translation_x, translation_y = x or 0, y or 0
end

function button:isIn()
    return isBetween(love.mouse.getX() - translation_x, self.x, self.x + self.w) and isBetween(love.mouse.getY() - translation_y, self.y, self.y + self.h)
end

function button:update(dt)
    if self:isIn() and self.trans:isDone() and self.alpha < anim then
        if self.style.easing then
            self.alpha = anim
            self.trans = NewTransition(0, self.w, anim, self.style.easing)
        
            hover_sound:stop()
            hover_sound:play()
        end
    elseif not self:isIn() and self.trans and self.trans:isDone() then
        self.alpha = self.alpha - dt
    end
    
    if self.trans then
        self.trans:update(dt)
    end
    
    if self.isDown then
        self.border = math.min(self.border + dt * 2, 2)
    else
        self.border = math.max(self.border - dt, 1)
    end
end

function button:draw()
    local font = self.font or love.graphics.getFont()
    if self.font then love.graphics.setFont(font) end
    
    love.graphics.setColor(self.r / 255, self.g / 255, self.b / 255, 1)
       
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 5)
    
    local time = self.trans:GetProgress()
        
    if time ~= 0 then
        love.graphics.setColor(self.r / 255 - self.alpha / 4, self.g / 255 - self.alpha / 4, self.b / 255 - self.alpha / 4, self.alpha)
        
        if self.style.shape == "sharp" then
            love.graphics.rectangle("fill", self.x, self.y, time, self.h, 5)
        else
            love.graphics.rectangle("fill", self.x, self.y, time, self.h)
        end
    end
    
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(self.border)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 5)
    love.graphics.print(self.text, self.x + (self.w - font:getWidth(self.text)) / 2, self.y + (self.h - font:getHeight(self.text)) / 2)
end

function button:mousepressed(x, y, button)
    if button == 1 then
        if self:isIn() then
            click_sound:play()
            
            self.isDown = true
        end
    end
end

function button:mousereleased(x, y, button)
    if button == 1 then
        self.isDown = false
        
        if self:isIn() then
            self.click()
        end
    end
end

function button:getPos() return self.x, self.y end
function button:setPos(x, y) self.x, self.y = x, y end
function button:setValue(value) self.value = value end
function button:getValue() return self.value end
function button:setText(value) self.text = value end
